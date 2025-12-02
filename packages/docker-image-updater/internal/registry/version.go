// Package registry provides container registry operations using skopeo.
package registry

import (
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// floatingTags is a list of tags that are considered "floating" (not pinned to a version).
var floatingTags = map[string]bool{
	"latest":  true,
	"stable":  true,
	"release": true,
	"main":    true,
	"master":  true,
	"develop": true,
	"dev":     true,
}

// majorOnlyVersionRe matches tags that are just a major version like "v2" or "2".
var majorOnlyVersionRe = regexp.MustCompile(`^v?[0-9]+$`)

// semverRe matches semantic version tags like "1.2.3", "v1.2.3", "1.2", "v1.2".
var semverRe = regexp.MustCompile(`^v?[0-9]+\.[0-9]+(\.[0-9]+)?$`)

// IsFloatingTag returns true if the tag is considered floating (not pinned).
func IsFloatingTag(tag string) bool {
	if floatingTags[tag] {
		return true
	}
	// Major-only versions like "v2" or "2" are floating
	return majorOnlyVersionRe.MatchString(tag)
}

// IsSemverTag returns true if the tag looks like a semantic version.
func IsSemverTag(tag string) bool {
	return semverRe.MatchString(tag)
}

// FilterSemverTags filters a list of tags to only include semantic version tags.
// If currentTag is provided, it will only match tags with the same prefix pattern (v vs no-v).
func FilterSemverTags(tags []string) []string {
	var result []string
	for _, tag := range tags {
		if IsSemverTag(tag) {
			result = append(result, tag)
		}
	}
	return result
}

// FilterSemverTagsMatching filters tags to only include semantic version tags
// that match the same prefix pattern as the current tag (v-prefixed or not).
// This is more efficient when there are many non-matching tags.
func FilterSemverTagsMatching(tags []string, currentTag string) []string {
	hasVPrefix := strings.HasPrefix(currentTag, "v")
	var result []string
	for _, tag := range tags {
		// Quick check: skip tags that don't start with digit or 'v'
		if len(tag) == 0 {
			continue
		}
		firstChar := tag[0]
		if firstChar != 'v' && (firstChar < '0' || firstChar > '9') {
			continue
		}
		// Match v-prefix pattern
		tagHasV := strings.HasPrefix(tag, "v")
		if hasVPrefix != tagHasV {
			continue
		}
		if IsSemverTag(tag) {
			result = append(result, tag)
		}
	}
	return result
}

// ParseVersion parses a version string into comparable parts.
// Returns major, minor, patch as integers and whether parsing succeeded.
func ParseVersion(version string) (major, minor, patch int, ok bool) {
	// Remove 'v' prefix if present
	v := strings.TrimPrefix(version, "v")

	parts := strings.Split(v, ".")
	if len(parts) < 2 || len(parts) > 3 {
		return 0, 0, 0, false
	}

	var err error
	major, err = strconv.Atoi(parts[0])
	if err != nil {
		return 0, 0, 0, false
	}

	minor, err = strconv.Atoi(parts[1])
	if err != nil {
		return 0, 0, 0, false
	}

	if len(parts) == 3 {
		patch, err = strconv.Atoi(parts[2])
		if err != nil {
			return 0, 0, 0, false
		}
	}

	return major, minor, patch, true
}

// CompareVersions compares two version strings.
// Returns -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2.
func CompareVersions(v1, v2 string) int {
	maj1, min1, pat1, ok1 := ParseVersion(v1)
	maj2, min2, pat2, ok2 := ParseVersion(v2)

	if !ok1 || !ok2 {
		// Fall back to string comparison
		if v1 < v2 {
			return -1
		} else if v1 > v2 {
			return 1
		}
		return 0
	}

	if maj1 != maj2 {
		if maj1 < maj2 {
			return -1
		}
		return 1
	}

	if min1 != min2 {
		if min1 < min2 {
			return -1
		}
		return 1
	}

	if pat1 != pat2 {
		if pat1 < pat2 {
			return -1
		}
		return 1
	}

	return 0
}

// SortVersions sorts a slice of version strings in ascending order.
func SortVersions(versions []string) {
	sort.Slice(versions, func(i, j int) bool {
		return CompareVersions(versions[i], versions[j]) < 0
	})
}

// FindLatestVersion finds the latest version from a list of version tags.
// Returns empty string if no valid versions found.
func FindLatestVersion(tags []string) string {
	return FindLatestVersionMatching(tags, "")
}

// FindLatestVersionMatching finds the latest version from a list of version tags,
// filtering to match the same prefix pattern as the current tag.
// Returns empty string if no valid versions found.
func FindLatestVersionMatching(tags []string, currentTag string) string {
	var semverTags []string
	if currentTag != "" {
		semverTags = FilterSemverTagsMatching(tags, currentTag)
	} else {
		semverTags = FilterSemverTags(tags)
	}

	if len(semverTags) == 0 {
		return ""
	}

	SortVersions(semverTags)
	return semverTags[len(semverTags)-1]
}

// IsNewerVersion returns true if newVersion is newer than currentVersion.
func IsNewerVersion(currentVersion, newVersion string) bool {
	return CompareVersions(currentVersion, newVersion) < 0
}
