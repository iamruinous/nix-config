// Package cache provides caching for registry check results.
package cache

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"
)

const (
	// DefaultTTL is the default cache time-to-live (24 hours).
	DefaultTTL = 24 * time.Hour

	// CacheFileName is the name of the cache file.
	CacheFileName = "docker-image-updater-cache.json"
)

// Entry represents a cached check result.
type Entry struct {
	LatestTag    string    `json:"latest_tag"`
	HasUpdate    bool      `json:"has_update"`
	IsDigestOnly bool      `json:"is_digest_only"`
	CheckedAt    time.Time `json:"checked_at"`
}

// Cache manages cached registry check results.
type Cache struct {
	// Entries maps image references to their cached results.
	// Key format: "image:tag" (e.g., "docker.io/library/nginx:1.27.0")
	Entries map[string]Entry `json:"entries"`

	// TTL is how long cache entries are valid.
	TTL time.Duration `json:"-"`

	// Path to the cache file.
	path string
}

// New creates a new cache with the given TTL.
// If path is empty, uses the default cache location.
func New(path string, ttl time.Duration) *Cache {
	if path == "" {
		path = defaultCachePath()
	}
	if ttl == 0 {
		ttl = DefaultTTL
	}
	return &Cache{
		Entries: make(map[string]Entry),
		TTL:     ttl,
		path:    path,
	}
}

// defaultCachePath returns the default cache file path.
// Uses XDG_STATE_HOME (~/.local/state) for state data per XDG Base Directory spec.
func defaultCachePath() string {
	// Try XDG_STATE_HOME first (preferred for state data)
	stateDir := os.Getenv("XDG_STATE_HOME")
	if stateDir == "" {
		// Fall back to ~/.local/state
		home, err := os.UserHomeDir()
		if err != nil {
			// Fall back to current directory
			return CacheFileName
		}
		stateDir = filepath.Join(home, ".local", "state")
	}

	// Create the state directory if it doesn't exist
	appStateDir := filepath.Join(stateDir, "docker-image-updater")
	_ = os.MkdirAll(appStateDir, 0755)

	return filepath.Join(appStateDir, CacheFileName)
}

// Load reads the cache from disk.
func (c *Cache) Load() error {
	data, err := os.ReadFile(c.path)
	if err != nil {
		if os.IsNotExist(err) {
			// No cache file yet, that's fine
			return nil
		}
		return err
	}

	return json.Unmarshal(data, c)
}

// Save writes the cache to disk.
func (c *Cache) Save() error {
	// Ensure directory exists
	dir := filepath.Dir(c.path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	data, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(c.path, data, 0644)
}

// Get retrieves a cached entry if it exists and is not expired.
func (c *Cache) Get(imageRef string) (Entry, bool) {
	entry, ok := c.Entries[imageRef]
	if !ok {
		return Entry{}, false
	}

	// Check if expired
	if time.Since(entry.CheckedAt) > c.TTL {
		return Entry{}, false
	}

	return entry, true
}

// Set stores a cache entry.
func (c *Cache) Set(imageRef string, latestTag string, hasUpdate bool, isDigestOnly bool) {
	c.Entries[imageRef] = Entry{
		LatestTag:    latestTag,
		HasUpdate:    hasUpdate,
		IsDigestOnly: isDigestOnly,
		CheckedAt:    time.Now(),
	}
}

// Clear removes all cache entries.
func (c *Cache) Clear() error {
	c.Entries = make(map[string]Entry)
	// Also remove the file
	if err := os.Remove(c.path); err != nil && !os.IsNotExist(err) {
		return err
	}
	return nil
}

// Prune removes expired entries from the cache.
func (c *Cache) Prune() {
	now := time.Now()
	for key, entry := range c.Entries {
		if now.Sub(entry.CheckedAt) > c.TTL {
			delete(c.Entries, key)
		}
	}
}

// Size returns the number of entries in the cache.
func (c *Cache) Size() int {
	return len(c.Entries)
}

// Path returns the cache file path.
func (c *Cache) Path() string {
	return c.path
}
