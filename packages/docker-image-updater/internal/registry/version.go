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

	// Filter out tags that look like date-based versions (e.g., 18.04.1, 20.04.1)
	// when the current tag has a small major version (< 15).
	// This handles LinuxServer images that have Ubuntu-derived version tags.
	if currentTag != "" {
		semverTags = filterOutDateBasedVersions(semverTags, currentTag)
	}

	if len(semverTags) == 0 {
		return ""
	}

	SortVersions(semverTags)
	return semverTags[len(semverTags)-1]
}

// filterOutDateBasedVersions removes tags that appear to be date-based versions
// (like Ubuntu versions 18.04.1, 20.04.1, etc.) when the current version
// suggests a normal semver scheme with a small major version.
func filterOutDateBasedVersions(tags []string, currentTag string) []string {
	currentMajor, _, _, ok := ParseVersion(currentTag)
	if !ok {
		return tags
	}

	// If current major version is already high (>= 15), don't filter
	// This threshold is chosen because:
	// - Most software has major versions < 15
	// - Ubuntu date-based versions start at 18.xx
	if currentMajor >= 15 {
		return tags
	}

	var result []string
	for _, tag := range tags {
		tagMajor, tagMinor, _, ok := ParseVersion(tag)
		if !ok {
			result = append(result, tag)
			continue
		}

		// Filter out tags where:
		// 1. Major version is >= 15 (likely a date-based version like 18.xx, 20.xx)
		// 2. Minor version looks like a month (1-12) or Ubuntu-style (.04, .10)
		// This catches Ubuntu-style versions like 18.04.1, 20.04.1, 22.04.1
		if tagMajor >= 15 && (tagMinor == 4 || tagMinor == 10 || tagMinor <= 12) {
			// Skip this tag - it's likely a date-based version
			continue
		}

		result = append(result, tag)
	}

	return result
}

// IsNewerVersion returns true if newVersion is newer than currentVersion.
func IsNewerVersion(currentVersion, newVersion string) bool {
	return CompareVersions(currentVersion, newVersion) < 0
}

type ConstraintOp int

const (
	OpNone ConstraintOp = iota
	OpEq
	OpGt
	OpGte
	OpLt
	OpLte
	OpTilde
	OpCaret
	OpWildcard
)

type VersionConstraint struct {
	Op          ConstraintOp
	Major       int
	Minor       int
	Patch       int
	HasMinor    bool
	HasPatch    bool
	WildcardPos int
}

type Constraint struct {
	Parts []VersionConstraint
}

func ParseConstraint(s string) (*Constraint, error) {
	if s == "" {
		return nil, nil
	}

	s = strings.TrimSpace(s)
	if s == "*" {
		return &Constraint{Parts: []VersionConstraint{{Op: OpWildcard, WildcardPos: 0}}}, nil
	}

	parts := strings.Split(s, ",")
	var constraints []VersionConstraint

	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}

		vc, err := parseConstraintPart(part)
		if err != nil {
			return nil, err
		}
		constraints = append(constraints, vc)
	}

	if len(constraints) == 0 {
		return nil, nil
	}

	return &Constraint{Parts: constraints}, nil
}

func parseConstraintPart(s string) (VersionConstraint, error) {
	s = strings.TrimSpace(s)
	vc := VersionConstraint{}

	switch {
	case strings.HasPrefix(s, "~"):
		vc.Op = OpTilde
		s = strings.TrimPrefix(s, "~")
	case strings.HasPrefix(s, "^"):
		vc.Op = OpCaret
		s = strings.TrimPrefix(s, "^")
	case strings.HasPrefix(s, ">="):
		vc.Op = OpGte
		s = strings.TrimPrefix(s, ">=")
	case strings.HasPrefix(s, ">"):
		vc.Op = OpGt
		s = strings.TrimPrefix(s, ">")
	case strings.HasPrefix(s, "<="):
		vc.Op = OpLte
		s = strings.TrimPrefix(s, "<=")
	case strings.HasPrefix(s, "<"):
		vc.Op = OpLt
		s = strings.TrimPrefix(s, "<")
	case strings.HasPrefix(s, "="):
		vc.Op = OpEq
		s = strings.TrimPrefix(s, "=")
	default:
		vc.Op = OpCaret
	}

	s = strings.TrimSpace(s)
	s = strings.TrimPrefix(s, "v")

	if strings.Contains(s, "*") {
		return parseWildcard(s)
	}

	return parseVersionParts(s, vc)
}

func parseWildcard(s string) (VersionConstraint, error) {
	vc := VersionConstraint{Op: OpWildcard}
	parts := strings.Split(s, ".")

	for i, p := range parts {
		if p == "*" {
			vc.WildcardPos = i
			break
		}
		val, err := strconv.Atoi(p)
		if err != nil {
			return vc, err
		}
		switch i {
		case 0:
			vc.Major = val
		case 1:
			vc.Minor = val
			vc.HasMinor = true
		}
	}
	return vc, nil
}

func parseVersionParts(s string, vc VersionConstraint) (VersionConstraint, error) {
	parts := strings.Split(s, ".")

	if len(parts) >= 1 && parts[0] != "" {
		val, err := strconv.Atoi(parts[0])
		if err != nil {
			return vc, err
		}
		vc.Major = val
	}

	if len(parts) >= 2 && parts[1] != "" {
		val, err := strconv.Atoi(parts[1])
		if err != nil {
			return vc, err
		}
		vc.Minor = val
		vc.HasMinor = true
	}

	if len(parts) >= 3 && parts[2] != "" {
		val, err := strconv.Atoi(parts[2])
		if err != nil {
			return vc, err
		}
		vc.Patch = val
		vc.HasPatch = true
	}

	return vc, nil
}

func (c *Constraint) Satisfies(version string) bool {
	if c == nil || len(c.Parts) == 0 {
		return true
	}

	major, minor, patch, ok := ParseVersion(version)
	if !ok {
		return false
	}

	for _, vc := range c.Parts {
		if !vc.satisfies(major, minor, patch) {
			return false
		}
	}
	return true
}

func (vc VersionConstraint) satisfies(major, minor, patch int) bool {
	switch vc.Op {
	case OpEq:
		return vc.equals(major, minor, patch)
	case OpGt:
		return vc.lessThan(major, minor, patch)
	case OpGte:
		return vc.lessThanOrEqual(major, minor, patch)
	case OpLt:
		return vc.greaterThan(major, minor, patch)
	case OpLte:
		return vc.greaterThanOrEqual(major, minor, patch)
	case OpTilde:
		return vc.satisfiesTilde(major, minor, patch)
	case OpCaret:
		return vc.satisfiesCaret(major, minor, patch)
	case OpWildcard:
		return vc.satisfiesWildcard(major, minor)
	default:
		return true
	}
}

func (vc VersionConstraint) equals(major, minor, patch int) bool {
	if major != vc.Major {
		return false
	}
	if vc.HasMinor && minor != vc.Minor {
		return false
	}
	if vc.HasPatch && patch != vc.Patch {
		return false
	}
	return true
}

func (vc VersionConstraint) lessThan(major, minor, patch int) bool {
	if major < vc.Major {
		return false
	}
	if major > vc.Major {
		return true
	}
	if !vc.HasMinor {
		return false
	}
	if minor < vc.Minor {
		return false
	}
	if minor > vc.Minor {
		return true
	}
	if !vc.HasPatch {
		return false
	}
	return patch > vc.Patch
}

func (vc VersionConstraint) lessThanOrEqual(major, minor, patch int) bool {
	if major < vc.Major {
		return false
	}
	if major > vc.Major {
		return true
	}
	if !vc.HasMinor {
		return true
	}
	if minor < vc.Minor {
		return false
	}
	if minor > vc.Minor {
		return true
	}
	if !vc.HasPatch {
		return true
	}
	return patch >= vc.Patch
}

func (vc VersionConstraint) greaterThan(major, minor, patch int) bool {
	if major > vc.Major {
		return false
	}
	if major < vc.Major {
		return true
	}
	if !vc.HasMinor {
		return false
	}
	if minor > vc.Minor {
		return false
	}
	if minor < vc.Minor {
		return true
	}
	if !vc.HasPatch {
		return false
	}
	return patch < vc.Patch
}

func (vc VersionConstraint) greaterThanOrEqual(major, minor, patch int) bool {
	if major > vc.Major {
		return false
	}
	if major < vc.Major {
		return true
	}
	if !vc.HasMinor {
		return true
	}
	if minor > vc.Minor {
		return false
	}
	if minor < vc.Minor {
		return true
	}
	if !vc.HasPatch {
		return true
	}
	return patch <= vc.Patch
}

func (vc VersionConstraint) satisfiesTilde(major, minor, patch int) bool {
	if major != vc.Major {
		return false
	}
	if !vc.HasMinor {
		return true
	}
	if minor < vc.Minor {
		return false
	}
	if minor > vc.Minor {
		return false
	}
	if !vc.HasPatch {
		return true
	}
	return patch >= vc.Patch
}

func (vc VersionConstraint) satisfiesCaret(major, minor, patch int) bool {
	if major != vc.Major {
		return false
	}

	if vc.Major == 0 {
		if !vc.HasMinor {
			return true
		}
		if minor != vc.Minor {
			return false
		}
		if vc.Minor == 0 {
			if !vc.HasPatch {
				return true
			}
			return patch == vc.Patch
		}
		if !vc.HasPatch {
			return true
		}
		return patch >= vc.Patch
	}

	if !vc.HasMinor {
		return true
	}
	if minor < vc.Minor {
		return false
	}
	if minor > vc.Minor {
		return true
	}
	if !vc.HasPatch {
		return true
	}
	return patch >= vc.Patch
}

func (vc VersionConstraint) satisfiesWildcard(major, minor int) bool {
	switch vc.WildcardPos {
	case 0:
		return true
	case 1:
		return major == vc.Major
	case 2:
		return major == vc.Major && minor == vc.Minor
	default:
		return true
	}
}

func FilterTagsWithConstraint(tags []string, constraint *Constraint, currentTag string) []string {
	if constraint == nil {
		if currentTag != "" {
			return FilterSemverTagsMatching(tags, currentTag)
		}
		return FilterSemverTags(tags)
	}

	var result []string
	hasVPrefix := strings.HasPrefix(currentTag, "v")

	for _, tag := range tags {
		if !IsSemverTag(tag) {
			continue
		}
		tagHasV := strings.HasPrefix(tag, "v")
		if currentTag != "" && hasVPrefix != tagHasV {
			continue
		}
		if constraint.Satisfies(tag) {
			result = append(result, tag)
		}
	}
	return result
}

func FindLatestVersionWithConstraint(tags []string, currentTag string, constraint *Constraint) string {
	var filtered []string
	if constraint != nil {
		filtered = FilterTagsWithConstraint(tags, constraint, currentTag)
	} else {
		filtered = FilterSemverTagsMatching(tags, currentTag)
	}

	if len(filtered) == 0 {
		return ""
	}

	if currentTag != "" && constraint == nil {
		filtered = filterOutDateBasedVersions(filtered, currentTag)
	}

	if len(filtered) == 0 {
		return ""
	}

	SortVersions(filtered)
	return filtered[len(filtered)-1]
}
