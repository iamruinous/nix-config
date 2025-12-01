package registry

import (
	"testing"
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

func TestNewChecker(t *testing.T) {
	// Test with default path
	c := NewChecker("")
	if c.skopeoPath != "skopeo" {
		t.Errorf("NewChecker(\"\").skopeoPath = %q, expected %q", c.skopeoPath, "skopeo")
	}

	// Test with custom path
	c = NewChecker("/usr/bin/skopeo")
	if c.skopeoPath != "/usr/bin/skopeo" {
		t.Errorf("NewChecker(\"/usr/bin/skopeo\").skopeoPath = %q, expected %q", c.skopeoPath, "/usr/bin/skopeo")
	}
}

// Note: Integration tests that actually call skopeo would go here,
// but they require network access and a running registry.
// For CI/CD, we would mock the skopeo calls.
