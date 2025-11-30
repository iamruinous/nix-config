package updater

import (
	"strings"
	"testing"

	"github.com/iamruinous/docker-image-updater/internal/registry"
	"github.com/iamruinous/docker-image-updater/internal/scanner"
)

func TestExtractImageBase(t *testing.T) {
	tests := []struct {
		image    string
		expected string
	}{
		{"nginx", "nginx"},
		{"nginx:1.0", "nginx"},
		{"nginx:latest", "nginx"},
		{"docker.io/library/nginx:1.0", "docker.io/library/nginx"},
		{"ghcr.io/org/repo:v1.2.3", "ghcr.io/org/repo"},
		{"registry.example.com:5000/repo:tag", "registry.example.com:5000/repo"},
	}

	for _, tc := range tests {
		t.Run(tc.image, func(t *testing.T) {
			result := extractImageBase(tc.image)
			if result != tc.expected {
				t.Errorf("extractImageBase(%q) = %q, expected %q", tc.image, result, tc.expected)
			}
		})
	}
}

func TestGenerateCommand(t *testing.T) {
	u := NewUpdater("/path/to/config")

	container := scanner.Container{
		Host:      "testhost",
		Name:      "postgres",
		Image:     "postgres:17",
		Tag:       "17",
		ImageBase: "postgres",
		FilePath:  "/path/to/config/hosts/testhost/containers.nix",
	}

	result := registry.UpdateResult{
		Container: container,
		LatestTag: "18",
		HasUpdate: true,
	}

	cmd := u.GenerateCommand(result)

	// Check that the command contains the expected parts
	if !strings.Contains(cmd, "sed -i") {
		t.Errorf("Command should contain 'sed -i': %s", cmd)
	}
	if !strings.Contains(cmd, "postgres:17") {
		t.Errorf("Command should contain old image 'postgres:17': %s", cmd)
	}
	if !strings.Contains(cmd, "postgres:18") {
		t.Errorf("Command should contain new image 'postgres:18': %s", cmd)
	}
	if !strings.Contains(cmd, container.FilePath) {
		t.Errorf("Command should contain file path: %s", cmd)
	}
}

func TestGenerateCommandDigestOnly(t *testing.T) {
	u := NewUpdater("/path/to/config")

	container := scanner.Container{
		Host:      "testhost",
		Name:      "app",
		Image:     "app:latest",
		Tag:       "latest",
		ImageBase: "app",
		FilePath:  "/path/to/config/hosts/testhost/containers.nix",
	}

	result := registry.UpdateResult{
		Container:    container,
		LatestTag:    "latest (new digest)",
		HasUpdate:    true,
		IsDigestOnly: true,
	}

	cmd := u.GenerateCommand(result)

	// For digest-only updates, the command should be empty since we can't change the file
	if cmd != "" {
		t.Errorf("Expected empty command for digest-only update, got: %s", cmd)
	}
}

func TestGenerateUpdateInfo(t *testing.T) {
	u := NewUpdater("/path/to/config")

	container := scanner.Container{
		Host:      "testhost",
		Name:      "postgres",
		Image:     "postgres:17",
		Tag:       "17",
		ImageBase: "postgres",
		FilePath:  "/path/to/config/hosts/testhost/containers.nix",
	}

	result := registry.UpdateResult{
		Container: container,
		LatestTag: "18",
		HasUpdate: true,
	}

	info := u.GenerateUpdateInfo(result)

	// Check that the info contains expected parts
	if !strings.Contains(info, "Host: testhost") {
		t.Errorf("Info should contain host: %s", info)
	}
	if !strings.Contains(info, "Container: postgres") {
		t.Errorf("Info should contain container name: %s", info)
	}
	if !strings.Contains(info, "Current: postgres:17") {
		t.Errorf("Info should contain current image: %s", info)
	}
	if !strings.Contains(info, "New: postgres:18") {
		t.Errorf("Info should contain new image: %s", info)
	}
}

func TestEscapeSedPattern(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"simple", "simple"},
		{"with.dot", `with\.dot`},
		{"with*star", `with\*star`},
		{"docker.io/library/nginx", `docker\.io/library/nginx`},
	}

	for _, tc := range tests {
		t.Run(tc.input, func(t *testing.T) {
			result := escapeSedPattern(tc.input)
			if result != tc.expected {
				t.Errorf("escapeSedPattern(%q) = %q, expected %q", tc.input, result, tc.expected)
			}
		})
	}
}

func TestEscapeSedReplacement(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"simple", "simple"},
		{"with&ampersand", `with\&ampersand`},
		{"with/slash", `with\/slash`},
		{`with\backslash`, `with\\backslash`},
	}

	for _, tc := range tests {
		t.Run(tc.input, func(t *testing.T) {
			result := escapeSedReplacement(tc.input)
			if result != tc.expected {
				t.Errorf("escapeSedReplacement(%q) = %q, expected %q", tc.input, result, tc.expected)
			}
		})
	}
}

func TestApplyDigestOnly(t *testing.T) {
	u := NewUpdater("/path/to/config")

	container := scanner.Container{
		Host:      "testhost",
		Name:      "app",
		Image:     "app:latest",
		Tag:       "latest",
		ImageBase: "app",
		FilePath:  "/path/to/config/hosts/testhost/containers.nix",
	}

	result := registry.UpdateResult{
		Container:    container,
		LatestTag:    "latest (new digest)",
		HasUpdate:    true,
		IsDigestOnly: true,
	}

	applyResult := u.Apply(result)

	if !applyResult.Skipped {
		t.Error("Expected digest-only update to be skipped")
	}
	if applyResult.Success {
		t.Error("Skipped updates should not be marked as success")
	}
}
