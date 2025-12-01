package registry

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"

	"github.com/iamruinous/docker-image-updater/internal/cache"
	"github.com/iamruinous/docker-image-updater/internal/scanner"
)

// UpdateResult holds the result of checking a container for updates.
type UpdateResult struct {
	Container    scanner.Container
	LatestTag    string
	HasUpdate    bool
	IsDigestOnly bool // True for floating tags with new digest
	Error        error
}

// Checker provides methods to check container registries for updates.
type Checker struct {
	skopeoPath string
	cache      *cache.Cache
	useCache   bool
}

// NewChecker creates a new registry Checker.
// If skopeoPath is empty, it will look for skopeo in PATH.
func NewChecker(skopeoPath string) *Checker {
	if skopeoPath == "" {
		skopeoPath = "skopeo"
	}
	return &Checker{skopeoPath: skopeoPath}
}

// NewCheckerWithCache creates a new registry Checker with caching enabled.
func NewCheckerWithCache(skopeoPath string, c *cache.Cache) *Checker {
	checker := NewChecker(skopeoPath)
	checker.cache = c
	checker.useCache = true
	return checker
}

// SetCache sets the cache for the checker.
func (c *Checker) SetCache(cache *cache.Cache) {
	c.cache = cache
	c.useCache = cache != nil
}

// Cache returns the checker's cache.
func (c *Checker) Cache() *cache.Cache {
	return c.cache
}

// SaveCache saves the cache to disk if caching is enabled.
func (c *Checker) SaveCache() error {
	if c.cache != nil {
		return c.cache.Save()
	}
	return nil
}

// tagsResponse represents the JSON response from skopeo list-tags.
type tagsResponse struct {
	Tags []string `json:"Tags"`
}

// inspectResponse represents the JSON response from skopeo inspect.
type inspectResponse struct {
	Digest string `json:"Digest"`
}

// ListTags returns all available tags for an image.
func (c *Checker) ListTags(image string) ([]string, error) {
	// Normalize the image to full form
	normalized := scanner.NormalizeImage(image)
	imageBase := extractImageBase(normalized)

	cmd := exec.Command(c.skopeoPath, "list-tags", "docker://"+imageBase)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("skopeo list-tags failed for %s: %w", imageBase, err)
	}

	var resp tagsResponse
	if err := json.Unmarshal(output, &resp); err != nil {
		return nil, fmt.Errorf("failed to parse skopeo output: %w", err)
	}

	return resp.Tags, nil
}

// GetDigest returns the digest for a specific image:tag.
func (c *Checker) GetDigest(imageRef string) (string, error) {
	// Normalize the image
	normalized := scanner.NormalizeImage(imageRef)

	cmd := exec.Command(c.skopeoPath, "inspect", "docker://"+normalized)
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("skopeo inspect failed for %s: %w", normalized, err)
	}

	var resp inspectResponse
	if err := json.Unmarshal(output, &resp); err != nil {
		return "", fmt.Errorf("failed to parse skopeo output: %w", err)
	}

	return resp.Digest, nil
}

// CheckForUpdate checks if an update is available for a container.
func (c *Checker) CheckForUpdate(container scanner.Container) *UpdateResult {
	result := &UpdateResult{
		Container: container,
		LatestTag: container.Tag, // Default to current tag
	}

	// Check cache first
	if c.useCache && c.cache != nil {
		if entry, ok := c.cache.Get(container.Image); ok {
			result.LatestTag = entry.LatestTag
			result.HasUpdate = entry.HasUpdate
			result.IsDigestOnly = entry.IsDigestOnly
			return result
		}
	}

	currentTag := container.Tag

	// For images with version-like tags, try to find newer versions
	if IsSemverTag(currentTag) {
		tags, err := c.ListTags(container.Image)
		if err != nil {
			result.Error = err
			return result
		}

		latestTag := FindLatestVersion(tags)
		if latestTag != "" {
			result.LatestTag = latestTag
			if IsNewerVersion(currentTag, latestTag) {
				result.HasUpdate = true
			}
		}
		// Cache the result
		c.cacheResult(container.Image, result)
		return result
	}

	// For floating tags, check if the digest has changed
	if !IsFloatingTag(currentTag) {
		// Non-floating, non-semver tag - we can't determine updates
		// Cache it anyway
		c.cacheResult(container.Image, result)
		return result
	}

	// Get current image digest
	currentDigest, err := c.GetDigest(container.Image)
	if err != nil {
		result.Error = err
		return result
	}

	// Get latest tag digest
	imageBase := container.ImageBase
	if imageBase == "" {
		imageBase = extractImageBase(container.Image)
	}
	latestRef := imageBase + ":latest"
	latestDigest, err := c.GetDigest(latestRef)
	if err != nil {
		// Can't get latest digest, not an error condition
		// Cache the result
		c.cacheResult(container.Image, result)
		return result
	}

	if currentDigest != "" && latestDigest != "" && currentDigest != latestDigest {
		result.HasUpdate = true
		result.LatestTag = "latest (new digest)"
		result.IsDigestOnly = true
	}

	// Cache the result
	c.cacheResult(container.Image, result)

	return result
}

// cacheResult stores the result in the cache if caching is enabled.
func (c *Checker) cacheResult(imageRef string, result *UpdateResult) {
	if c.useCache && c.cache != nil && result.Error == nil {
		c.cache.Set(imageRef, result.LatestTag, result.HasUpdate, result.IsDigestOnly)
	}
}

// extractImageBase extracts the image reference without the tag.
func extractImageBase(image string) string {
	// Handle images with digest (@sha256:...)
	if idx := strings.Index(image, "@"); idx != -1 {
		image = image[:idx]
	}

	if idx := strings.LastIndex(image, ":"); idx != -1 {
		// Make sure it's not part of a port number
		remainder := image[idx+1:]
		if !strings.Contains(remainder, "/") {
			return image[:idx]
		}
	}
	return image
}
