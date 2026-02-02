package xdg

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSetup(t *testing.T) {
	opID := "test-op"

	paths, err := Setup(opID)
	require.NoError(t, err)
	require.NotNil(t, paths)

	// Verify directories were created
	assert.DirExists(t, paths.ConfigHome)
	assert.DirExists(t, paths.DataHome)
	assert.DirExists(t, paths.StateHome)
	assert.DirExists(t, paths.CacheHome)

	// Cleanup
	Cleanup(opID)
}

func TestSetup_CreatesAuthSymlink(t *testing.T) {
	home, _ := os.UserHomeDir()
	opID := "test-op"

	// Create main opencode auth file
	mainAuthDir := filepath.Join(home, ".local", "share", "opencode")
	os.MkdirAll(mainAuthDir, 0755)
	mainAuthPath := filepath.Join(mainAuthDir, "auth.json")
	os.WriteFile(mainAuthPath, []byte("test"), 0644)

	paths, err := Setup(opID)
	require.NoError(t, err)

	// Verify symlink was created
	opAuthPath := filepath.Join(paths.DataHome, "auth.json")
	info, err := os.Lstat(opAuthPath)
	require.NoError(t, err)
	assert.Equal(t, os.ModeSymlink, info.Mode()&os.ModeSymlink)

	// Cleanup
	Cleanup(opID)
	os.RemoveAll(mainAuthDir)
}

func TestCleanup(t *testing.T) {
	opID := "test-op"

	// Setup first
	_, err := Setup(opID)
	require.NoError(t, err)

	// Verify directories exist
	paths := GetPaths(opID)
	assert.DirExists(t, paths.ConfigHome)

	// Cleanup
	err = Cleanup(opID)
	require.NoError(t, err)

	// Verify directories are gone
	assert.NoDirExists(t, paths.ConfigHome)
	assert.NoDirExists(t, paths.DataHome)
	assert.NoDirExists(t, paths.StateHome)
	assert.NoDirExists(t, paths.CacheHome)
}

func TestGetPaths(t *testing.T) {
	opID := "test-op"
	paths := GetPaths(opID)

	require.NotNil(t, paths)
	assert.Contains(t, paths.ConfigHome, opID)
	assert.Contains(t, paths.DataHome, opID)
	assert.Contains(t, paths.StateHome, opID)
	assert.Contains(t, paths.CacheHome, opID)
}
