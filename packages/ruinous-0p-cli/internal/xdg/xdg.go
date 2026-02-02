package xdg

import (
	"fmt"
	"os"
	"path/filepath"
)

// XDGPaths holds the XDG directory paths for an Op
type XDGPaths struct {
	ConfigHome string
	DataHome   string
	StateHome  string
	CacheHome  string
}

// Setup creates XDG directories for the given Op and symlinks auth tokens.
func Setup(opID string) (*XDGPaths, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("failed to get home directory: %w", err)
	}

	prefix := fmt.Sprintf("opencode-%s", opID)

	paths := &XDGPaths{
		ConfigHome: filepath.Join(home, ".config", prefix),
		DataHome:   filepath.Join(home, ".local", "share", prefix),
		StateHome:  filepath.Join(home, ".local", "state", prefix),
		CacheHome:  filepath.Join(home, ".cache", prefix),
	}

	// Create directories
	for _, dir := range []string{paths.ConfigHome, paths.DataHome, paths.StateHome, paths.CacheHome} {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return nil, fmt.Errorf("failed to create directory %s: %w", dir, err)
		}
	}

	// Symlink auth token from main opencode
	mainAuthPath := filepath.Join(home, ".local", "share", "opencode", "auth.json")
	opAuthPath := filepath.Join(paths.DataHome, "auth.json")

	if _, err := os.Stat(mainAuthPath); err == nil {
		// Main auth exists, create symlink
		if err := os.Symlink(mainAuthPath, opAuthPath); err != nil {
			// If symlink already exists, that's ok
			if !os.IsExist(err) {
				return nil, fmt.Errorf("failed to symlink auth: %w", err)
			}
		}
	}

	return paths, nil
}

// Cleanup removes XDG directories for the given Op.
func Cleanup(opID string) error {
	home, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get home directory: %w", err)
	}

	prefix := fmt.Sprintf("opencode-%s", opID)

	paths := []string{
		filepath.Join(home, ".config", prefix),
		filepath.Join(home, ".local", "share", prefix),
		filepath.Join(home, ".local", "state", prefix),
		filepath.Join(home, ".cache", prefix),
	}

	for _, dir := range paths {
		if err := os.RemoveAll(dir); err != nil {
			return fmt.Errorf("failed to remove directory %s: %w", dir, err)
		}
	}

	return nil
}

// GetPaths returns the XDG paths for an Op without creating them.
func GetPaths(opID string) *XDGPaths {
	home, _ := os.UserHomeDir()
	prefix := fmt.Sprintf("opencode-%s", opID)

	return &XDGPaths{
		ConfigHome: filepath.Join(home, ".config", prefix),
		DataHome:   filepath.Join(home, ".local", "share", prefix),
		StateHome:  filepath.Join(home, ".local", "state", prefix),
		CacheHome:  filepath.Join(home, ".cache", prefix),
	}
}
