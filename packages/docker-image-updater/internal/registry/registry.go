package registry

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"sort"
	"strings"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/name"
	"github.com/google/go-containerregistry/pkg/v1/remote/transport"
	"github.com/iamruinous/docker-image-updater/internal/cache"
	"github.com/iamruinous/docker-image-updater/internal/scanner"
)

// DefaultMaxTags is the default maximum number of tags to fetch per image.
// This provides an order of magnitude speedup over fetching all tags.
// Most registries return tags in reverse chronological order, so we get the most recent.
const DefaultMaxTags = 50

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
	cache    *cache.Cache
	useCache bool
	maxTags  int
}

// NewChecker creates a new registry Checker.
func NewChecker(skopeoPath string) *Checker {
	return &Checker{
		maxTags: DefaultMaxTags,
	}
}

// NewCheckerWithCache creates a new registry Checker with caching enabled.
func NewCheckerWithCache(skopeoPath string, c *cache.Cache) *Checker {
	checker := NewChecker(skopeoPath)
	checker.cache = c
	checker.useCache = true
	return checker
}

// SetMaxTags sets the maximum number of tags to fetch per image.
func (c *Checker) SetMaxTags(n int) {
	if n > 0 {
		c.maxTags = n
	}
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

// tagsResponse represents the JSON response from registry tags/list endpoint.
type tagsResponse struct {
	Name string   `json:"name"`
	Tags []string `json:"tags"`
}

// ListTags returns available tags for an image, limited to maxTags most recent.
// Most registries return tags in reverse chronological order (newest first).
func (c *Checker) ListTags(image string) ([]string, error) {
	return c.ListTagsWithLimit(image, c.maxTags)
}

// ListTagsWithLimit returns available tags for an image, limited to n tags.
// Uses the OCI Distribution API with pagination for efficiency.
func (c *Checker) ListTagsWithLimit(image string, limit int) ([]string, error) {
	return c.ListTagsWithLimitAndStart(image, limit, "")
}

// ListTagsWithLimitAndStart returns available tags for an image, limited to n tags,
// starting after the specified tag (lexicographically). This is useful for images
// with many tags where we want to skip to a specific major version.
// Uses the OCI Distribution API with pagination for efficiency.
func (c *Checker) ListTagsWithLimitAndStart(image string, limit int, startAfter string) ([]string, error) {
	// Normalize the image to full form
	normalized := scanner.NormalizeImage(image)
	imageBase := extractImageBase(normalized)

	// Parse the repository reference
	repo, err := name.NewRepository(imageBase)
	if err != nil {
		return nil, fmt.Errorf("failed to parse repository %s: %w", imageBase, err)
	}

	// Get authentication
	auth, err := authn.DefaultKeychain.Resolve(repo.Registry)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve auth for %s: %w", repo.Registry.Name(), err)
	}

	// Create authenticated transport
	scopes := []string{repo.Scope(transport.PullScope)}
	t, err := transport.New(repo.Registry, auth, http.DefaultTransport, scopes)
	if err != nil {
		return nil, fmt.Errorf("failed to create transport for %s: %w", repo.Registry.Name(), err)
	}

	client := &http.Client{Transport: t}

	// Build the tags list URL with pagination
	// The n parameter limits the number of tags returned
	// The last parameter starts listing after the specified tag (lexicographic order)
	var url string
	if startAfter != "" {
		url = fmt.Sprintf("https://%s/v2/%s/tags/list?n=%d&last=%s", repo.Registry.Name(), repo.RepositoryStr(), limit, startAfter)
	} else {
		url = fmt.Sprintf("https://%s/v2/%s/tags/list?n=%d", repo.Registry.Name(), repo.RepositoryStr(), limit)
	}

	req, err := http.NewRequestWithContext(context.Background(), "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to list tags for %s: %w", imageBase, err)
	}
	defer resp.Body.Close()

	if err := transport.CheckError(resp, http.StatusOK); err != nil {
		return nil, fmt.Errorf("registry error for %s: %w", imageBase, err)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var tagsResp tagsResponse
	if err := json.Unmarshal(body, &tagsResp); err != nil {
		return nil, fmt.Errorf("failed to parse tags response: %w", err)
	}

	return tagsResp.Tags, nil
}

// ListTagsForVersion returns available tags for an image, using smart pagination
// to start from the major version of the current tag. This handles repositories
// with many tags (like n8n with 2400+ tags) where the OCI API returns tags
// lexicographically and simple pagination would miss newer major versions.
//
// The function fetches pages of tags starting from the current major version
// and continues paginating until it has seen tags beyond the current version.
func (c *Checker) ListTagsForVersion(image string, currentTag string, limit int) ([]string, error) {
	major, minor, patch, ok := ParseVersion(currentTag)
	if !ok || major == 0 {
		return c.ListTagsWithLimit(image, limit)
	}

	// Use current major as startAfter - lexicographically "2" > "1.999.999"
	// so this skips all previous major version tags
	startAfter := fmt.Sprintf("%d", major)

	// Collect tags across multiple pages until we've covered past current version
	var allTags []string
	pageSize := limit
	if pageSize < 100 {
		pageSize = 100 // Use larger pages for efficiency
	}

	// Keep fetching until we see tags that are lexicographically past our version
	// or until we get an empty/small response (no more tags)
	for i := 0; i < 10; i++ { // Safety limit of 10 pages
		tags, err := c.ListTagsWithLimitAndStart(image, pageSize, startAfter)
		if err != nil {
			return nil, err
		}

		if len(tags) == 0 {
			break
		}

		allTags = append(allTags, tags...)

		// Check if we've gone past our current version
		// The last tag in the response tells us where we are lexicographically
		lastTag := tags[len(tags)-1]

		// Parse the last tag to see if we've covered enough
		lastMajor, lastMinor, lastPatch, lastOk := ParseVersion(lastTag)
		if lastOk {
			// We've found tags beyond current version - good enough
			if lastMajor > major ||
				(lastMajor == major && lastMinor > minor) ||
				(lastMajor == major && lastMinor == minor && lastPatch > patch) {
				break
			}
		}

		// If we got fewer tags than requested, there are no more
		if len(tags) < pageSize {
			break
		}

		// Continue from the last tag
		startAfter = lastTag
	}

	return allTags, nil
}

// GetDigest returns the digest for a specific image:tag using go-containerregistry.
func (c *Checker) GetDigest(imageRef string) (string, error) {
	// Normalize the image
	normalized := scanner.NormalizeImage(imageRef)

	// Parse the reference
	ref, err := name.ParseReference(normalized)
	if err != nil {
		return "", fmt.Errorf("failed to parse reference %s: %w", normalized, err)
	}

	// Get authentication
	auth, err := authn.DefaultKeychain.Resolve(ref.Context().Registry)
	if err != nil {
		return "", fmt.Errorf("failed to resolve auth: %w", err)
	}

	// Create authenticated transport
	scopes := []string{ref.Scope(transport.PullScope)}
	t, err := transport.New(ref.Context().Registry, auth, http.DefaultTransport, scopes)
	if err != nil {
		return "", fmt.Errorf("failed to create transport: %w", err)
	}

	client := &http.Client{Transport: t}

	// Use HEAD request to get digest from manifest
	url := fmt.Sprintf("https://%s/v2/%s/manifests/%s",
		ref.Context().Registry.Name(),
		ref.Context().RepositoryStr(),
		ref.Identifier())

	req, err := http.NewRequestWithContext(context.Background(), "HEAD", url, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	// Accept multiple manifest types
	req.Header.Set("Accept", strings.Join([]string{
		"application/vnd.docker.distribution.manifest.v2+json",
		"application/vnd.docker.distribution.manifest.list.v2+json",
		"application/vnd.oci.image.manifest.v1+json",
		"application/vnd.oci.image.index.v1+json",
	}, ", "))

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to get manifest for %s: %w", imageRef, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("failed to get manifest: status %d", resp.StatusCode)
	}

	digest := resp.Header.Get("Docker-Content-Digest")
	if digest == "" {
		return "", fmt.Errorf("no digest in response for %s", imageRef)
	}

	return digest, nil
}

// CheckForUpdate checks if an update is available for a container.
func (c *Checker) CheckForUpdate(container scanner.Container) *UpdateResult {
	result := &UpdateResult{
		Container: container,
		LatestTag: container.Tag,
	}

	cacheKey := container.Image
	if container.PinConstraint != "" {
		cacheKey = container.Image + "@" + container.PinConstraint
	}

	if c.useCache && c.cache != nil {
		if entry, ok := c.cache.Get(cacheKey); ok {
			result.LatestTag = entry.LatestTag
			result.HasUpdate = entry.HasUpdate
			result.IsDigestOnly = entry.IsDigestOnly
			return result
		}
	}

	currentTag := container.Tag

	var constraint *Constraint
	if container.PinConstraint != "" {
		var err error
		constraint, err = ParseConstraint(container.PinConstraint)
		if err != nil {
			result.Error = err
			return result
		}
	}

	if IsSemverTag(currentTag) {
		tags, err := c.ListTagsForVersion(container.Image, currentTag, c.maxTags)
		if err != nil {
			result.Error = err
			return result
		}

		latestTag := FindLatestVersionWithConstraint(tags, currentTag, constraint)
		if latestTag != "" {
			result.LatestTag = latestTag
			if IsNewerVersion(currentTag, latestTag) {
				result.HasUpdate = true
			}
		}
		c.cacheResultWithKey(cacheKey, result)
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

// FindLatestFromTags finds the latest version tag from a list, respecting constraints.
// This is useful when you need more control over how tags are sorted/filtered.
func (c *Checker) FindLatestFromTags(tags []string, currentTag string, constraint *Constraint) string {
	if len(tags) == 0 {
		return ""
	}

	// Filter to matching semver tags
	var filtered []string
	if constraint != nil {
		filtered = FilterTagsWithConstraint(tags, constraint, currentTag)
	} else {
		filtered = FilterSemverTagsMatching(tags, currentTag)
	}

	if len(filtered) == 0 {
		return ""
	}

	// Filter out date-based versions if needed
	if currentTag != "" && constraint == nil {
		filtered = filterOutDateBasedVersions(filtered, currentTag)
	}

	if len(filtered) == 0 {
		return ""
	}

	// Sort and return the highest
	sort.Slice(filtered, func(i, j int) bool {
		return CompareVersions(filtered[i], filtered[j]) < 0
	})

	return filtered[len(filtered)-1]
}

func (c *Checker) cacheResult(imageRef string, result *UpdateResult) {
	c.cacheResultWithKey(imageRef, result)
}

func (c *Checker) cacheResultWithKey(key string, result *UpdateResult) {
	if c.useCache && c.cache != nil && result.Error == nil {
		c.cache.Set(key, result.LatestTag, result.HasUpdate, result.IsDigestOnly)
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
