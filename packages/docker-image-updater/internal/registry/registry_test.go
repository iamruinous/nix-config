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
	c := NewChecker("")
	if c.maxTags != DefaultMaxTags {
		t.Errorf("NewChecker(\"\").maxTags = %d, expected %d", c.maxTags, DefaultMaxTags)
	}
}

func TestSetMaxTags(t *testing.T) {
	c := NewChecker("")
	c.SetMaxTags(100)
	if c.maxTags != 100 {
		t.Errorf("SetMaxTags(100) resulted in maxTags = %d, expected 100", c.maxTags)
	}

	c.SetMaxTags(0)
	if c.maxTags != 100 {
		t.Errorf("SetMaxTags(0) should not change maxTags, got %d", c.maxTags)
	}
}
