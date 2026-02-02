package worktree

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCreate(t *testing.T) {
	tmpDir := t.TempDir()
	initGitRepo(t, tmpDir)

	opID := "test-op"
	opsDir := t.TempDir()
	worktreePath, err := CreateWithBase(tmpDir, opID, opsDir)
	require.NoError(t, err)

	assert.DirExists(t, worktreePath)
	assert.Contains(t, worktreePath, opID)

	gitFile := filepath.Join(worktreePath, ".git")
	_, err = os.Stat(gitFile)
	assert.NoError(t, err)
}

func TestCreate_AlreadyExists(t *testing.T) {
	tmpDir := t.TempDir()
	initGitRepo(t, tmpDir)

	opID := "test-op"
	opsDir := t.TempDir()
	_, err := CreateWithBase(tmpDir, opID, opsDir)
	require.NoError(t, err)

	_, err = CreateWithBase(tmpDir, opID, opsDir)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "already exists")
}

func TestRemove(t *testing.T) {
	tmpDir := t.TempDir()
	initGitRepo(t, tmpDir)

	opID := "test-op"
	opsDir := t.TempDir()
	worktreePath, err := CreateWithBase(tmpDir, opID, opsDir)
	require.NoError(t, err)

	assert.DirExists(t, worktreePath)

	err = Remove(worktreePath)
	require.NoError(t, err)

	assert.NoDirExists(t, worktreePath)
}

func TestRemove_NotExists(t *testing.T) {
	err := Remove("/nonexistent/path")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "does not exist")
}

func TestExists(t *testing.T) {
	tmpDir := t.TempDir()
	initGitRepo(t, tmpDir)

	opID := "test-op"
	opsDir := t.TempDir()
	worktreePath, err := CreateWithBase(tmpDir, opID, opsDir)
	require.NoError(t, err)

	assert.True(t, Exists(worktreePath))
	assert.False(t, Exists("/nonexistent/path"))
}

// initGitRepo initializes a git repository for testing
func initGitRepo(t *testing.T, path string) {
	t.Helper()

	// Initialize git repo
	cmd := exec.Command("git", "init")
	cmd.Dir = path
	output, err := cmd.CombinedOutput()
	require.NoError(t, err, "git init failed: %s", output)

	// Configure git user for commits
	cmd = exec.Command("git", "config", "user.email", "test@example.com")
	cmd.Dir = path
	output, err = cmd.CombinedOutput()
	require.NoError(t, err, "git config failed: %s", output)

	cmd = exec.Command("git", "config", "user.name", "Test User")
	cmd.Dir = path
	output, err = cmd.CombinedOutput()
	require.NoError(t, err, "git config failed: %s", output)

	// Create initial commit
	testFile := filepath.Join(path, "README.md")
	err = os.WriteFile(testFile, []byte("# Test"), 0644)
	require.NoError(t, err)

	cmd = exec.Command("git", "add", ".")
	cmd.Dir = path
	output, err = cmd.CombinedOutput()
	require.NoError(t, err, "git add failed: %s", output)

	cmd = exec.Command("git", "commit", "-m", "Initial commit")
	cmd.Dir = path
	output, err = cmd.CombinedOutput()
	require.NoError(t, err, "git commit failed: %s", output)
}
