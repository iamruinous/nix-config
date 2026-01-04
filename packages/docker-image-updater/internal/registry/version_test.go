package registry

import (
	"testing"
)

func TestIsFloatingTag(t *testing.T) {
	tests := []struct {
		tag      string
		expected bool
	}{
		{"latest", true},
		{"stable", true},
		{"release", true},
		{"main", true},
		{"master", true},
		{"develop", true},
		{"dev", true},
		{"2", true},
		{"v2", true},
		{"1.0", false},
		{"1.0.0", false},
		{"v1.0", false},
		{"v1.0.0", false},
		{"17.1", false},
		{"2025.1.2", false},
	}

	for _, tc := range tests {
		t.Run(tc.tag, func(t *testing.T) {
			result := IsFloatingTag(tc.tag)
			if result != tc.expected {
				t.Errorf("IsFloatingTag(%q) = %v, expected %v", tc.tag, result, tc.expected)
			}
		})
	}
}

func TestIsSemverTag(t *testing.T) {
	tests := []struct {
		tag      string
		expected bool
	}{
		{"1.0", true},
		{"1.0.0", true},
		{"v1.0", true},
		{"v1.0.0", true},
		{"17.1", true},
		{"0.12.5", true},
		{"latest", false},
		{"stable", false},
		{"v2", false},
		{"2", false},
		{"1.2.3.4", false},
		{"abc", false},
		{"1.0-beta", false},
	}

	for _, tc := range tests {
		t.Run(tc.tag, func(t *testing.T) {
			result := IsSemverTag(tc.tag)
			if result != tc.expected {
				t.Errorf("IsSemverTag(%q) = %v, expected %v", tc.tag, result, tc.expected)
			}
		})
	}
}

func TestParseVersion(t *testing.T) {
	tests := []struct {
		version       string
		major         int
		minor         int
		patch         int
		shouldSucceed bool
	}{
		{"1.0.0", 1, 0, 0, true},
		{"1.2.3", 1, 2, 3, true},
		{"v1.0.0", 1, 0, 0, true},
		{"v1.2.3", 1, 2, 3, true},
		{"1.0", 1, 0, 0, true},
		{"17.1", 17, 1, 0, true},
		{"0.12.5", 0, 12, 5, true},
		{"latest", 0, 0, 0, false},
		{"1", 0, 0, 0, false},
		{"1.2.3.4", 0, 0, 0, false},
	}

	for _, tc := range tests {
		t.Run(tc.version, func(t *testing.T) {
			major, minor, patch, ok := ParseVersion(tc.version)
			if ok != tc.shouldSucceed {
				t.Errorf("ParseVersion(%q) ok = %v, expected %v", tc.version, ok, tc.shouldSucceed)
				return
			}
			if tc.shouldSucceed {
				if major != tc.major || minor != tc.minor || patch != tc.patch {
					t.Errorf("ParseVersion(%q) = (%d, %d, %d), expected (%d, %d, %d)",
						tc.version, major, minor, patch, tc.major, tc.minor, tc.patch)
				}
			}
		})
	}
}

func TestCompareVersions(t *testing.T) {
	tests := []struct {
		v1       string
		v2       string
		expected int
	}{
		{"1.0.0", "1.0.0", 0},
		{"1.0.0", "1.0.1", -1},
		{"1.0.1", "1.0.0", 1},
		{"1.0.0", "2.0.0", -1},
		{"2.0.0", "1.0.0", 1},
		{"1.0.0", "1.1.0", -1},
		{"1.1.0", "1.0.0", 1},
		{"v1.0.0", "1.0.0", 0},
		{"v1.0.0", "v1.0.1", -1},
		{"17", "18", -1},
		{"0.12.5", "0.12.6", -1},
		{"1.0", "1.0.0", 0},
		{"1.0", "1.0.1", -1},
	}

	for _, tc := range tests {
		t.Run(tc.v1+"_vs_"+tc.v2, func(t *testing.T) {
			result := CompareVersions(tc.v1, tc.v2)
			if result != tc.expected {
				t.Errorf("CompareVersions(%q, %q) = %d, expected %d", tc.v1, tc.v2, result, tc.expected)
			}
		})
	}
}

func TestIsNewerVersion(t *testing.T) {
	tests := []struct {
		current  string
		new      string
		expected bool
	}{
		{"1.0.0", "1.0.1", true},
		{"1.0.0", "2.0.0", true},
		{"1.0.0", "1.0.0", false},
		{"1.0.1", "1.0.0", false},
		{"v1.0.0", "v1.0.1", true},
		{"17", "18", true},
		{"0.12.5", "0.12.6", true},
	}

	for _, tc := range tests {
		t.Run(tc.current+"_to_"+tc.new, func(t *testing.T) {
			result := IsNewerVersion(tc.current, tc.new)
			if result != tc.expected {
				t.Errorf("IsNewerVersion(%q, %q) = %v, expected %v", tc.current, tc.new, result, tc.expected)
			}
		})
	}
}

func TestFilterSemverTags(t *testing.T) {
	tags := []string{"1.0.0", "latest", "v1.2.3", "stable", "2.0", "dev", "main"}
	expected := []string{"1.0.0", "v1.2.3", "2.0"}

	result := FilterSemverTags(tags)

	if len(result) != len(expected) {
		t.Errorf("FilterSemverTags returned %d tags, expected %d", len(result), len(expected))
		return
	}

	for i, tag := range result {
		if tag != expected[i] {
			t.Errorf("FilterSemverTags[%d] = %q, expected %q", i, tag, expected[i])
		}
	}
}

func TestFindLatestVersion(t *testing.T) {
	tests := []struct {
		tags     []string
		expected string
	}{
		{[]string{"1.0.0", "1.0.1", "1.0.2"}, "1.0.2"},
		{[]string{"1.0.0", "2.0.0", "1.5.0"}, "2.0.0"},
		{[]string{"v1.0.0", "v1.0.1", "v2.0.0"}, "v2.0.0"},
		{[]string{"latest", "stable"}, ""},
		{[]string{"1.0", "1.1", "2.0"}, "2.0"},
		{[]string{"0.12.5", "0.12.6", "0.12.4"}, "0.12.6"},
	}

	for _, tc := range tests {
		t.Run(tc.expected, func(t *testing.T) {
			result := FindLatestVersion(tc.tags)
			if result != tc.expected {
				t.Errorf("FindLatestVersion(%v) = %q, expected %q", tc.tags, result, tc.expected)
			}
		})
	}
}

func TestSortVersions(t *testing.T) {
	versions := []string{"2.0.0", "1.0.0", "1.5.0", "1.0.1", "10.0.0"}
	expected := []string{"1.0.0", "1.0.1", "1.5.0", "2.0.0", "10.0.0"}

	SortVersions(versions)

	for i, v := range versions {
		if v != expected[i] {
			t.Errorf("SortVersions[%d] = %q, expected %q", i, v, expected[i])
		}
	}
}

func TestFilterSemverTagsMatching(t *testing.T) {
	// Simulate open-webui with many git-* tags
	tags := []string{
		"main", "latest", "git-abc123", "git-def456",
		"v0.6.30", "v0.6.31", "v0.6.32", "v0.6.33",
		"1.0.0", "1.0.1", "2.0.0",
	}

	// When current tag is v-prefixed, should only return v-prefixed semver tags
	result := FilterSemverTagsMatching(tags, "v0.6.30")
	expected := []string{"v0.6.30", "v0.6.31", "v0.6.32", "v0.6.33"}
	if len(result) != len(expected) {
		t.Errorf("FilterSemverTagsMatching(v-prefix) returned %d tags, expected %d: %v", len(result), len(expected), result)
	}

	// When current tag is not v-prefixed, should only return non-v-prefixed semver tags
	result = FilterSemverTagsMatching(tags, "1.0.0")
	expected = []string{"1.0.0", "1.0.1", "2.0.0"}
	if len(result) != len(expected) {
		t.Errorf("FilterSemverTagsMatching(no-v-prefix) returned %d tags, expected %d: %v", len(result), len(expected), result)
	}
}

func TestFindLatestVersionMatching(t *testing.T) {
	// Simulate open-webui tags
	tags := []string{
		"main", "latest", "git-abc123", "git-def456",
		"v0.6.30", "v0.6.31", "v0.6.32", "v0.6.33",
		"1.0.0", "1.0.1", "2.0.0",
	}

	// Should find latest v-prefixed version when current is v-prefixed
	result := FindLatestVersionMatching(tags, "v0.6.30")
	if result != "v0.6.33" {
		t.Errorf("FindLatestVersionMatching(v0.6.30) = %q, expected v0.6.33", result)
	}

	// Should find latest non-v-prefixed version when current is not v-prefixed
	result = FindLatestVersionMatching(tags, "1.0.0")
	if result != "2.0.0" {
		t.Errorf("FindLatestVersionMatching(1.0.0) = %q, expected 2.0.0", result)
	}
}

func TestFilterOutDateBasedVersions(t *testing.T) {
	tests := []struct {
		name       string
		tags       []string
		currentTag string
		expected   []string
	}{
		{
			name:       "linuxserver deluge with Ubuntu-style version",
			tags:       []string{"2.0.5", "2.1.1", "2.2.0", "18.04.1"},
			currentTag: "2.2.0",
			expected:   []string{"2.0.5", "2.1.1", "2.2.0"},
		},
		{
			name:       "multiple Ubuntu-style versions",
			tags:       []string{"1.0.0", "2.0.0", "18.04.1", "20.04.1", "22.04.1"},
			currentTag: "1.0.0",
			expected:   []string{"1.0.0", "2.0.0"},
		},
		{
			name:       "high major version should not be filtered when current is also high",
			tags:       []string{"18.0.0", "18.1.0", "19.0.0"},
			currentTag: "18.0.0",
			expected:   []string{"18.0.0", "18.1.0", "19.0.0"},
		},
		{
			name:       "version with month-like minor (not .04 or .10)",
			tags:       []string{"1.0.0", "2.0.0", "18.5.0"},
			currentTag: "1.0.0",
			expected:   []string{"1.0.0", "2.0.0"},
		},
		{
			name:       "preserve non-Ubuntu style high versions",
			tags:       []string{"1.0.0", "2.0.0", "18.15.0"},
			currentTag: "1.0.0",
			expected:   []string{"1.0.0", "2.0.0", "18.15.0"},
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			result := filterOutDateBasedVersions(tc.tags, tc.currentTag)
			if len(result) != len(tc.expected) {
				t.Errorf("filterOutDateBasedVersions(%v, %q) returned %d tags, expected %d: got %v",
					tc.tags, tc.currentTag, len(result), len(tc.expected), result)
				return
			}
			for i, tag := range result {
				if tag != tc.expected[i] {
					t.Errorf("filterOutDateBasedVersions[%d] = %q, expected %q", i, tag, tc.expected[i])
				}
			}
		})
	}
}

func TestFindLatestVersionMatchingWithDateBasedVersions(t *testing.T) {
	tags := []string{
		"2.0.5", "2.1.1", "2.2.0", "18.04.1",
		"latest", "stable",
	}

	result := FindLatestVersionMatching(tags, "2.2.0")
	if result != "2.2.0" {
		t.Errorf("FindLatestVersionMatching with Ubuntu-style version = %q, expected 2.2.0", result)
	}

	result = FindLatestVersionMatching(tags, "2.0.5")
	if result != "2.2.0" {
		t.Errorf("FindLatestVersionMatching(2.0.5) = %q, expected 2.2.0", result)
	}
}

func TestParseConstraint(t *testing.T) {
	tests := []struct {
		input       string
		shouldParse bool
	}{
		{"~4", true},
		{"~4.0", true},
		{"~4.0.16", true},
		{"^1.2.3", true},
		{"^0.2.3", true},
		{">=1.0.0", true},
		{">1.0.0", true},
		{"<2.0.0", true},
		{"<=2.0.0", true},
		{"=1.2.3", true},
		{"1.2.3", true},
		{"*", true},
		{"1.*", true},
		{"1.2.*", true},
		{">=1.0,<2.0", true},
		{"", false},
	}

	for _, tc := range tests {
		t.Run(tc.input, func(t *testing.T) {
			c, err := ParseConstraint(tc.input)
			if tc.shouldParse {
				if err != nil {
					t.Errorf("ParseConstraint(%q) returned error: %v", tc.input, err)
				}
				if tc.input != "" && c == nil {
					t.Errorf("ParseConstraint(%q) returned nil", tc.input)
				}
			} else {
				if c != nil {
					t.Errorf("ParseConstraint(%q) should return nil", tc.input)
				}
			}
		})
	}
}

func TestTildeConstraint(t *testing.T) {
	tests := []struct {
		constraint string
		version    string
		expected   bool
	}{
		{"~4", "4.0.0", true},
		{"~4", "4.0.16", true},
		{"~4", "4.5.0", true},
		{"~4", "4.99.99", true},
		{"~4", "3.9.9", false},
		{"~4", "5.0.0", false},
		{"~4.0", "4.0.0", true},
		{"~4.0", "4.0.16", true},
		{"~4.0", "4.1.0", false},
		{"~4.0", "3.0.0", false},
		{"~4.0.16", "4.0.16", true},
		{"~4.0.16", "4.0.17", true},
		{"~4.0.16", "4.0.15", false},
		{"~4.0.16", "4.1.0", false},
		{"~1.2.3", "1.2.3", true},
		{"~1.2.3", "1.2.4", true},
		{"~1.2.3", "1.2.99", true},
		{"~1.2.3", "1.3.0", false},
		{"~1.2.3", "2.0.0", false},
	}

	for _, tc := range tests {
		t.Run(tc.constraint+"_"+tc.version, func(t *testing.T) {
			c, err := ParseConstraint(tc.constraint)
			if err != nil {
				t.Fatalf("ParseConstraint(%q) error: %v", tc.constraint, err)
			}
			result := c.Satisfies(tc.version)
			if result != tc.expected {
				t.Errorf("Constraint(%q).Satisfies(%q) = %v, expected %v",
					tc.constraint, tc.version, result, tc.expected)
			}
		})
	}
}

func TestCaretConstraint(t *testing.T) {
	tests := []struct {
		constraint string
		version    string
		expected   bool
	}{
		{"^1.2.3", "1.2.3", true},
		{"^1.2.3", "1.2.4", true},
		{"^1.2.3", "1.3.0", true},
		{"^1.2.3", "1.99.99", true},
		{"^1.2.3", "2.0.0", false},
		{"^1.2.3", "1.2.2", false},
		{"^0.2.3", "0.2.3", true},
		{"^0.2.3", "0.2.4", true},
		{"^0.2.3", "0.3.0", false},
		{"^0.0.3", "0.0.3", true},
		{"^0.0.3", "0.0.4", false},
		{"17", "17.0.0", true},
		{"17", "17.5.0", true},
		{"17", "18.0.0", false},
		{"^17", "17.0.0", true},
		{"^17", "17.1.0", true},
		{"^17", "18.0.0", false},
	}

	for _, tc := range tests {
		t.Run(tc.constraint+"_"+tc.version, func(t *testing.T) {
			c, err := ParseConstraint(tc.constraint)
			if err != nil {
				t.Fatalf("ParseConstraint(%q) error: %v", tc.constraint, err)
			}
			result := c.Satisfies(tc.version)
			if result != tc.expected {
				t.Errorf("Constraint(%q).Satisfies(%q) = %v, expected %v",
					tc.constraint, tc.version, result, tc.expected)
			}
		})
	}
}

func TestWildcardConstraint(t *testing.T) {
	tests := []struct {
		constraint string
		version    string
		expected   bool
	}{
		{"*", "1.0.0", true},
		{"*", "99.0.0", true},
		{"1.*", "1.0.0", true},
		{"1.*", "1.5.0", true},
		{"1.*", "1.99.99", true},
		{"1.*", "2.0.0", false},
		{"1.2.*", "1.2.0", true},
		{"1.2.*", "1.2.99", true},
		{"1.2.*", "1.3.0", false},
	}

	for _, tc := range tests {
		t.Run(tc.constraint+"_"+tc.version, func(t *testing.T) {
			c, err := ParseConstraint(tc.constraint)
			if err != nil {
				t.Fatalf("ParseConstraint(%q) error: %v", tc.constraint, err)
			}
			result := c.Satisfies(tc.version)
			if result != tc.expected {
				t.Errorf("Constraint(%q).Satisfies(%q) = %v, expected %v",
					tc.constraint, tc.version, result, tc.expected)
			}
		})
	}
}

func TestComparisonConstraints(t *testing.T) {
	tests := []struct {
		constraint string
		version    string
		expected   bool
	}{
		{">=1.0.0", "1.0.0", true},
		{">=1.0.0", "1.0.1", true},
		{">=1.0.0", "2.0.0", true},
		{">=1.0.0", "0.9.9", false},
		{">1.0.0", "1.0.1", true},
		{">1.0.0", "1.0.0", false},
		{"<2.0.0", "1.9.9", true},
		{"<2.0.0", "2.0.0", false},
		{"<=2.0.0", "2.0.0", true},
		{"<=2.0.0", "1.9.9", true},
		{"<=2.0.0", "2.0.1", false},
		{"=1.2.3", "1.2.3", true},
		{"=1.2.3", "1.2.4", false},
	}

	for _, tc := range tests {
		t.Run(tc.constraint+"_"+tc.version, func(t *testing.T) {
			c, err := ParseConstraint(tc.constraint)
			if err != nil {
				t.Fatalf("ParseConstraint(%q) error: %v", tc.constraint, err)
			}
			result := c.Satisfies(tc.version)
			if result != tc.expected {
				t.Errorf("Constraint(%q).Satisfies(%q) = %v, expected %v",
					tc.constraint, tc.version, result, tc.expected)
			}
		})
	}
}

func TestMultipleConstraints(t *testing.T) {
	tests := []struct {
		constraint string
		version    string
		expected   bool
	}{
		{">=1.0.0,<2.0.0", "1.0.0", true},
		{">=1.0.0,<2.0.0", "1.5.0", true},
		{">=1.0.0,<2.0.0", "1.9.9", true},
		{">=1.0.0,<2.0.0", "2.0.0", false},
		{">=1.0.0,<2.0.0", "0.9.9", false},
		{">=1.0,<1.5", "1.0.0", true},
		{">=1.0,<1.5", "1.4.99", true},
		{">=1.0,<1.5", "1.5.0", false},
	}

	for _, tc := range tests {
		t.Run(tc.constraint+"_"+tc.version, func(t *testing.T) {
			c, err := ParseConstraint(tc.constraint)
			if err != nil {
				t.Fatalf("ParseConstraint(%q) error: %v", tc.constraint, err)
			}
			result := c.Satisfies(tc.version)
			if result != tc.expected {
				t.Errorf("Constraint(%q).Satisfies(%q) = %v, expected %v",
					tc.constraint, tc.version, result, tc.expected)
			}
		})
	}
}

func TestFindLatestVersionWithConstraint(t *testing.T) {
	tests := []struct {
		name       string
		tags       []string
		currentTag string
		constraint string
		expected   string
	}{
		{
			name:       "tilde major only - sonarr case",
			tags:       []string{"3.0.0", "4.0.0", "4.0.16", "4.1.0", "5.0.0"},
			currentTag: "4.0.16",
			constraint: "~4",
			expected:   "4.1.0",
		},
		{
			name:       "tilde minor - stay in patch",
			tags:       []string{"4.0.0", "4.0.16", "4.0.17", "4.1.0"},
			currentTag: "4.0.16",
			constraint: "~4.0",
			expected:   "4.0.17",
		},
		{
			name:       "caret - allow minor updates",
			tags:       []string{"1.0.0", "1.2.0", "1.3.0", "2.0.0"},
			currentTag: "1.2.0",
			constraint: "^1.2",
			expected:   "1.3.0",
		},
		{
			name:       "wildcard major",
			tags:       []string{"1.0.0", "1.5.0", "2.0.0"},
			currentTag: "1.0.0",
			constraint: "1.*",
			expected:   "1.5.0",
		},
		{
			name:       "range constraint",
			tags:       []string{"1.0.0", "1.5.0", "1.9.0", "2.0.0"},
			currentTag: "1.0.0",
			constraint: ">=1.0,<2.0",
			expected:   "1.9.0",
		},
		{
			name:       "no constraint - uses semver matching",
			tags:       []string{"1.0.0", "2.0.0", "3.0.0"},
			currentTag: "1.0.0",
			constraint: "",
			expected:   "3.0.0",
		},
		{
			name:       "v-prefixed tags with constraint",
			tags:       []string{"v1.0.0", "v1.5.0", "v2.0.0"},
			currentTag: "v1.0.0",
			constraint: "~1",
			expected:   "v1.5.0",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			var constraint *Constraint
			if tc.constraint != "" {
				var err error
				constraint, err = ParseConstraint(tc.constraint)
				if err != nil {
					t.Fatalf("ParseConstraint(%q) error: %v", tc.constraint, err)
				}
			}

			result := FindLatestVersionWithConstraint(tc.tags, tc.currentTag, constraint)
			if result != tc.expected {
				t.Errorf("FindLatestVersionWithConstraint(%v, %q, %q) = %q, expected %q",
					tc.tags, tc.currentTag, tc.constraint, result, tc.expected)
			}
		})
	}
}
