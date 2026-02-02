package session

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"forge.meskill.farm/ruinous/0p-cli/internal/xdg"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestGenerate(t *testing.T) {
	opID := "test-op"
	worktreePath := "/tmp/test-worktree"
	xdgPaths := &xdg.XDGPaths{
		ConfigHome: "/tmp/test-config",
		DataHome:   "/tmp/test-data",
		StateHome:  "/tmp/test-state",
		CacheHome:  "/tmp/test-cache",
	}

	jsonStr, err := Generate(opID, worktreePath, xdgPaths)
	require.NoError(t, err)
	require.NotEmpty(t, jsonStr)

	// Verify it's valid JSON
	var session Session
	err = json.Unmarshal([]byte(jsonStr), &session)
	require.NoError(t, err)

	// Verify session properties
	assert.Equal(t, opID, session.SessionName)
	assert.Equal(t, worktreePath, session.StartDir)
	assert.Equal(t, xdgPaths.ConfigHome, session.Environment["XDG_CONFIG_HOME"])
	assert.Equal(t, xdgPaths.DataHome, session.Environment["XDG_DATA_HOME"])
	assert.Equal(t, xdgPaths.StateHome, session.Environment["XDG_STATE_HOME"])
	assert.Equal(t, opID, session.Environment["OP_ID"])

	// Verify windows
	assert.Len(t, session.Windows, 5)
	assert.Equal(t, "logs", session.Windows[0].WindowName)
	assert.Equal(t, "agent", session.Windows[1].WindowName)
	assert.True(t, session.Windows[1].Focus)
	assert.Equal(t, "editor", session.Windows[2].WindowName)
	assert.Equal(t, "files", session.Windows[3].WindowName)
	assert.Equal(t, "shell", session.Windows[4].WindowName)
}

func TestSave(t *testing.T) {
	tmpDir := t.TempDir()

	// Override home directory for test
	originalHome := os.Getenv("HOME")
	os.Setenv("HOME", tmpDir)
	defer os.Setenv("HOME", originalHome)

	opID := "test-op"
	sessionJSON := `{"session_name": "test-op"}`

	err := Save(opID, sessionJSON)
	require.NoError(t, err)

	// Verify file was created
	sessionPath := filepath.Join(tmpDir, ".config", "tmuxp", "test-op.json")
	content, err := os.ReadFile(sessionPath)
	require.NoError(t, err)
	assert.Equal(t, sessionJSON, string(content))
}

func TestRemove(t *testing.T) {
	tmpDir := t.TempDir()

	// Override home directory for test
	originalHome := os.Getenv("HOME")
	os.Setenv("HOME", tmpDir)
	defer os.Setenv("HOME", originalHome)

	opID := "test-op"

	// Create the file first
	tmuxpDir := filepath.Join(tmpDir, ".config", "tmuxp")
	os.MkdirAll(tmuxpDir, 0755)
	sessionPath := filepath.Join(tmuxpDir, "test-op.json")
	os.WriteFile(sessionPath, []byte("{}"), 0644)

	// Verify it exists
	assert.FileExists(t, sessionPath)

	// Remove it
	err := Remove(opID)
	require.NoError(t, err)

	// Verify it's gone
	assert.NoFileExists(t, sessionPath)
}

func TestRemove_NotExists(t *testing.T) {
	tmpDir := t.TempDir()

	// Override home directory for test
	originalHome := os.Getenv("HOME")
	os.Setenv("HOME", tmpDir)
	defer os.Setenv("HOME", originalHome)

	opID := "nonexistent-op"

	// Should not error if file doesn't exist
	err := Remove(opID)
	require.NoError(t, err)
}

func TestExists(t *testing.T) {
	tmpDir := t.TempDir()

	// Override home directory for test
	originalHome := os.Getenv("HOME")
	os.Setenv("HOME", tmpDir)
	defer os.Setenv("HOME", originalHome)

	opID := "test-op"

	// Initially should not exist
	assert.False(t, Exists(opID))

	// Create the file
	tmuxpDir := filepath.Join(tmpDir, ".config", "tmuxp")
	os.MkdirAll(tmuxpDir, 0755)
	sessionPath := filepath.Join(tmuxpDir, "test-op.json")
	os.WriteFile(sessionPath, []byte("{}"), 0644)

	// Now should exist
	assert.True(t, Exists(opID))
}
