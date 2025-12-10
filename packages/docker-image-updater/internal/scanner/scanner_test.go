package scanner

import (
	"os"
	"path/filepath"
	"testing"
)

func TestExtractTag(t *testing.T) {
	tests := []struct {
		image    string
		expected string
	}{
		{"nginx", "latest"},
		{"nginx:1.0", "1.0"},
		{"nginx:latest", "latest"},
		{"docker.io/library/nginx:1.0", "1.0"},
		{"ghcr.io/org/repo:v1.2.3", "v1.2.3"},
		{"registry.example.com:5000/repo:tag", "tag"},
		{"postgres:17", "17"},
		{"postgres:17.1", "17.1"},
	}

	for _, tc := range tests {
		t.Run(tc.image, func(t *testing.T) {
			result := extractTag(tc.image)
			if result != tc.expected {
				t.Errorf("extractTag(%q) = %q, expected %q", tc.image, result, tc.expected)
			}
		})
	}
}

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

func TestNormalizeImage(t *testing.T) {
	tests := []struct {
		image    string
		expected string
	}{
		{"nginx", "docker.io/library/nginx"},
		{"nginx:1.0", "docker.io/library/nginx:1.0"},
		{"nginx:latest", "docker.io/library/nginx:latest"},
		{"user/repo", "docker.io/user/repo"},
		{"user/repo:v1", "docker.io/user/repo:v1"},
		{"ghcr.io/org/repo:v1.2.3", "ghcr.io/org/repo:v1.2.3"},
		{"docker.io/library/postgres:17", "docker.io/library/postgres:17"},
		{"registry.example.com/repo:tag", "registry.example.com/repo:tag"},
	}

	for _, tc := range tests {
		t.Run(tc.image, func(t *testing.T) {
			result := NormalizeImage(tc.image)
			if result != tc.expected {
				t.Errorf("NormalizeImage(%q) = %q, expected %q", tc.image, result, tc.expected)
			}
		})
	}
}

func TestParseContainerFile(t *testing.T) {
	// Create a temporary directory with a test containers.nix file
	tmpDir, err := os.MkdirTemp("", "scanner-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create host directory structure
	hostDir := filepath.Join(tmpDir, "hosts", "testhost")
	if err := os.MkdirAll(hostDir, 0755); err != nil {
		t.Fatalf("Failed to create host dir: %v", err)
	}

	// Create test containers.nix content
	testContent := `{ config, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      postgres = {
        image = "postgres:17";
        environment = {
          POSTGRES_DB = "test";
        };
      };

      nginx = {
        image = "nginx:1.27.0";
        ports = [ "80:80" ];
      };

      "web-app" = {
        image = "ghcr.io/org/web-app:v2.1.0";
      };
    };
  };
}`

	containerFile := filepath.Join(hostDir, "containers.nix")
	if err := os.WriteFile(containerFile, []byte(testContent), 0644); err != nil {
		t.Fatalf("Failed to write containers.nix: %v", err)
	}

	// Test parsing
	s := NewScanner(tmpDir)
	containers, err := s.Scan("")
	if err != nil {
		t.Fatalf("Scan failed: %v", err)
	}

	if len(containers) != 3 {
		t.Errorf("Expected 3 containers, got %d", len(containers))
	}

	// Verify container data
	containerMap := make(map[string]Container)
	for _, c := range containers {
		containerMap[c.Name] = c
	}

	if c, ok := containerMap["postgres"]; ok {
		if c.Image != "postgres:17" {
			t.Errorf("postgres image = %q, expected %q", c.Image, "postgres:17")
		}
		if c.Tag != "17" {
			t.Errorf("postgres tag = %q, expected %q", c.Tag, "17")
		}
	} else {
		t.Error("postgres container not found")
	}

	if c, ok := containerMap["nginx"]; ok {
		if c.Image != "nginx:1.27.0" {
			t.Errorf("nginx image = %q, expected %q", c.Image, "nginx:1.27.0")
		}
	} else {
		t.Error("nginx container not found")
	}

	if c, ok := containerMap["web-app"]; ok {
		if c.Image != "ghcr.io/org/web-app:v2.1.0" {
			t.Errorf("web-app image = %q, expected %q", c.Image, "ghcr.io/org/web-app:v2.1.0")
		}
		if c.Host != "testhost" {
			t.Errorf("web-app host = %q, expected %q", c.Host, "testhost")
		}
	} else {
		t.Error("web-app container not found")
	}
}

func TestScanWithHostFilter(t *testing.T) {
	// Create a temporary directory with multiple hosts
	tmpDir, err := os.MkdirTemp("", "scanner-filter-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create two host directories
	for _, host := range []string{"host1", "host2"} {
		hostDir := filepath.Join(tmpDir, "hosts", host)
		if err := os.MkdirAll(hostDir, 0755); err != nil {
			t.Fatalf("Failed to create host dir: %v", err)
		}

		content := `{ config, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      app = {
        image = "app:1.0";
      };
    };
  };
}`
		containerFile := filepath.Join(hostDir, "containers.nix")
		if err := os.WriteFile(containerFile, []byte(content), 0644); err != nil {
			t.Fatalf("Failed to write containers.nix: %v", err)
		}
	}

	s := NewScanner(tmpDir)

	// Test without filter
	containers, err := s.Scan("")
	if err != nil {
		t.Fatalf("Scan failed: %v", err)
	}
	if len(containers) != 2 {
		t.Errorf("Expected 2 containers without filter, got %d", len(containers))
	}

	// Test with filter
	containers, err = s.Scan("host1")
	if err != nil {
		t.Fatalf("Scan with filter failed: %v", err)
	}
	if len(containers) != 1 {
		t.Errorf("Expected 1 container with filter, got %d", len(containers))
	}
	if len(containers) > 0 && containers[0].Host != "host1" {
		t.Errorf("Expected host1, got %s", containers[0].Host)
	}
}

func TestContainerKey(t *testing.T) {
	c := Container{
		Host: "myhost",
		Name: "mycontainer",
	}

	expected := "myhost:mycontainer"
	if c.Key() != expected {
		t.Errorf("Key() = %q, expected %q", c.Key(), expected)
	}
}

func TestIsImageCheckDisabled(t *testing.T) {
	tests := []struct {
		name         string
		currentLine  string
		previousLine string
		expected     bool
	}{
		{
			name:         "disabled on same line",
			currentLine:  `image = "nginx:1.0"; # IMAGECHECK: disabled`,
			previousLine: "",
			expected:     true,
		},
		{
			name:         "disabled on previous line",
			currentLine:  `image = "nginx:1.0";`,
			previousLine: `# IMAGECHECK: disabled`,
			expected:     true,
		},
		{
			name:         "disabled with no space",
			currentLine:  `image = "nginx:1.0"; # IMAGECHECK:disabled`,
			previousLine: "",
			expected:     true,
		},
		{
			name:         "disabled lowercase",
			currentLine:  `image = "nginx:1.0"; # imagecheck: disabled`,
			previousLine: "",
			expected:     true,
		},
		{
			name:         "not disabled",
			currentLine:  `image = "nginx:1.0";`,
			previousLine: `# some other comment`,
			expected:     false,
		},
		{
			name:         "empty lines",
			currentLine:  `image = "nginx:1.0";`,
			previousLine: "",
			expected:     false,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			result := isImageCheckDisabled(tc.currentLine, tc.previousLine)
			if result != tc.expected {
				t.Errorf("isImageCheckDisabled(%q, %q) = %v, expected %v",
					tc.currentLine, tc.previousLine, result, tc.expected)
			}
		})
	}
}

func TestParseContainerFileWithImageCheckDisabled(t *testing.T) {
	// Create a temporary directory with a test containers.nix file
	tmpDir, err := os.MkdirTemp("", "scanner-disabled-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create host directory structure
	hostDir := filepath.Join(tmpDir, "hosts", "testhost")
	if err := os.MkdirAll(hostDir, 0755); err != nil {
		t.Fatalf("Failed to create host dir: %v", err)
	}

	// Create test containers.nix content with IMAGECHECK: disabled
	// Note: The directive must be on the same line as the image definition,
	// or on the immediately preceding line (no blank lines in between)
	testContent := `{ config, ... }: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      # This one should be checked
      postgres = {
        image = "postgres:17";
      };

      legacy-app = {
        # IMAGECHECK: disabled
        image = "legacy:1.0";
      };

      nginx = {
        image = "nginx:1.27.0"; # IMAGECHECK: disabled
      };

      # This one should also be checked
      redis = {
        image = "redis:7";
      };
    };
  };
}`

	containerFile := filepath.Join(hostDir, "containers.nix")
	if err := os.WriteFile(containerFile, []byte(testContent), 0644); err != nil {
		t.Fatalf("Failed to write containers.nix: %v", err)
	}

	// Test parsing
	s := NewScanner(tmpDir)
	containers, err := s.Scan("")
	if err != nil {
		t.Fatalf("Scan failed: %v", err)
	}

	// Should only have 2 containers (postgres and redis), not legacy-app or nginx
	if len(containers) != 2 {
		t.Errorf("Expected 2 containers (disabled ones filtered), got %d", len(containers))
		for _, c := range containers {
			t.Logf("  Found: %s", c.Name)
		}
	}

	// Verify the correct containers were parsed
	containerMap := make(map[string]Container)
	for _, c := range containers {
		containerMap[c.Name] = c
	}

	if _, ok := containerMap["postgres"]; !ok {
		t.Error("postgres container should be present")
	}
	if _, ok := containerMap["redis"]; !ok {
		t.Error("redis container should be present")
	}
	if _, ok := containerMap["legacy-app"]; ok {
		t.Error("legacy-app container should be filtered out (IMAGECHECK: disabled on previous line)")
	}
	if _, ok := containerMap["nginx"]; ok {
		t.Error("nginx container should be filtered out (IMAGECHECK: disabled on same line)")
	}
}
