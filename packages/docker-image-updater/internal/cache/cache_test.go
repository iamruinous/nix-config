package cache

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestNew(t *testing.T) {
	// Test with empty path (should use default)
	c := New("", DefaultTTL)
	if c.path == "" {
		t.Error("Expected non-empty path")
	}
	if c.TTL != DefaultTTL {
		t.Errorf("TTL = %v, expected %v", c.TTL, DefaultTTL)
	}
	if c.Entries == nil {
		t.Error("Entries map should be initialized")
	}

	// Test with custom path
	customPath := "/tmp/test-cache.json"
	c2 := New(customPath, time.Hour)
	if c2.path != customPath {
		t.Errorf("path = %q, expected %q", c2.path, customPath)
	}
	if c2.TTL != time.Hour {
		t.Errorf("TTL = %v, expected %v", c2.TTL, time.Hour)
	}
}

func TestNewWithZeroTTL(t *testing.T) {
	c := New("/tmp/test.json", 0)
	if c.TTL != DefaultTTL {
		t.Errorf("TTL with 0 = %v, expected default %v", c.TTL, DefaultTTL)
	}
}

func TestSetAndGet(t *testing.T) {
	c := New("/tmp/test-cache.json", DefaultTTL)

	// Set an entry
	c.Set("test-image:1.0", "1.1", true, false)

	// Get the entry
	entry, ok := c.Get("test-image:1.0")
	if !ok {
		t.Fatal("Expected to find entry")
	}
	if entry.LatestTag != "1.1" {
		t.Errorf("LatestTag = %q, expected %q", entry.LatestTag, "1.1")
	}
	if !entry.HasUpdate {
		t.Error("HasUpdate should be true")
	}
	if entry.IsDigestOnly {
		t.Error("IsDigestOnly should be false")
	}

	// Get non-existent entry
	_, ok = c.Get("non-existent:tag")
	if ok {
		t.Error("Should not find non-existent entry")
	}
}

func TestGetExpired(t *testing.T) {
	c := New("/tmp/test-cache.json", time.Millisecond)

	// Set an entry
	c.Set("test-image:1.0", "1.1", true, false)

	// Wait for it to expire
	time.Sleep(10 * time.Millisecond)

	// Should not be found (expired)
	_, ok := c.Get("test-image:1.0")
	if ok {
		t.Error("Expired entry should not be returned")
	}
}

func TestSaveAndLoad(t *testing.T) {
	// Create temp directory
	tmpDir, err := os.MkdirTemp("", "cache-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cachePath := filepath.Join(tmpDir, "test-cache.json")

	// Create and populate cache
	c1 := New(cachePath, DefaultTTL)
	c1.Set("image1:1.0", "1.1", true, false)
	c1.Set("image2:latest", "latest (new digest)", true, true)

	// Save cache
	if err := c1.Save(); err != nil {
		t.Fatalf("Failed to save cache: %v", err)
	}

	// Verify file exists
	if _, err := os.Stat(cachePath); os.IsNotExist(err) {
		t.Fatal("Cache file should exist after save")
	}

	// Create new cache and load
	c2 := New(cachePath, DefaultTTL)
	if err := c2.Load(); err != nil {
		t.Fatalf("Failed to load cache: %v", err)
	}

	// Verify entries
	entry1, ok := c2.Get("image1:1.0")
	if !ok {
		t.Error("Should find image1:1.0 after load")
	}
	if entry1.LatestTag != "1.1" {
		t.Errorf("image1 LatestTag = %q, expected %q", entry1.LatestTag, "1.1")
	}

	entry2, ok := c2.Get("image2:latest")
	if !ok {
		t.Error("Should find image2:latest after load")
	}
	if !entry2.IsDigestOnly {
		t.Error("image2 IsDigestOnly should be true")
	}
}

func TestLoadNonExistent(t *testing.T) {
	c := New("/tmp/non-existent-cache-12345.json", DefaultTTL)
	// Should not error on non-existent file
	if err := c.Load(); err != nil {
		t.Errorf("Load on non-existent file should not error, got: %v", err)
	}
}

func TestClear(t *testing.T) {
	// Create temp directory
	tmpDir, err := os.MkdirTemp("", "cache-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cachePath := filepath.Join(tmpDir, "test-cache.json")

	// Create, populate, and save cache
	c := New(cachePath, DefaultTTL)
	c.Set("image:1.0", "1.1", true, false)
	if err := c.Save(); err != nil {
		t.Fatalf("Failed to save cache: %v", err)
	}

	// Clear cache
	if err := c.Clear(); err != nil {
		t.Fatalf("Failed to clear cache: %v", err)
	}

	// Entries should be empty
	if len(c.Entries) != 0 {
		t.Errorf("Entries should be empty after clear, got %d", len(c.Entries))
	}

	// File should be deleted
	if _, err := os.Stat(cachePath); !os.IsNotExist(err) {
		t.Error("Cache file should be deleted after clear")
	}
}

func TestClearNonExistent(t *testing.T) {
	c := New("/tmp/non-existent-cache-12345.json", DefaultTTL)
	// Should not error when clearing non-existent file
	if err := c.Clear(); err != nil {
		t.Errorf("Clear on non-existent file should not error, got: %v", err)
	}
}

func TestPrune(t *testing.T) {
	c := New("/tmp/test-cache.json", time.Millisecond)

	// Set entries
	c.Set("old-image:1.0", "1.1", true, false)

	// Wait for it to expire
	time.Sleep(10 * time.Millisecond)

	// Add a new entry
	c.Set("new-image:1.0", "1.1", true, false)

	// Prune expired entries
	c.Prune()

	// Old entry should be gone
	if _, ok := c.Entries["old-image:1.0"]; ok {
		t.Error("Old entry should be pruned")
	}

	// New entry should still exist
	if _, ok := c.Entries["new-image:1.0"]; !ok {
		t.Error("New entry should still exist")
	}
}

func TestSize(t *testing.T) {
	c := New("/tmp/test-cache.json", DefaultTTL)

	if c.Size() != 0 {
		t.Errorf("Initial size = %d, expected 0", c.Size())
	}

	c.Set("image1:1.0", "1.1", true, false)
	c.Set("image2:1.0", "1.1", true, false)

	if c.Size() != 2 {
		t.Errorf("Size after 2 sets = %d, expected 2", c.Size())
	}
}

func TestPath(t *testing.T) {
	customPath := "/tmp/custom-cache.json"
	c := New(customPath, DefaultTTL)

	if c.Path() != customPath {
		t.Errorf("Path() = %q, expected %q", c.Path(), customPath)
	}
}

func TestDefaultCachePath(t *testing.T) {
	path := defaultCachePath()

	// Should end with the cache filename
	if filepath.Base(path) != CacheFileName {
		t.Errorf("Cache path should end with %q, got %q", CacheFileName, filepath.Base(path))
	}

	// Should contain docker-image-updater directory
	if filepath.Base(filepath.Dir(path)) != "docker-image-updater" {
		t.Errorf("Cache should be in docker-image-updater directory, got %q", filepath.Dir(path))
	}

	// Should be under .local/state or XDG_STATE_HOME
	// The parent of docker-image-updater should be "state" (from ~/.local/state)
	// unless XDG_STATE_HOME is set
	stateDir := filepath.Dir(filepath.Dir(path))
	if filepath.Base(stateDir) != "state" {
		// Could be a custom XDG_STATE_HOME, just check it contains "state" somewhere
		// or accept any valid path
		t.Logf("State directory: %s (may be custom XDG_STATE_HOME)", stateDir)
	}
}
