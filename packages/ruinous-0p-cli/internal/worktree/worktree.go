package worktree

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

// Create creates a new worktree for the given op in the specified repository.
// It creates the worktree at <baseDir>/<opID>/<repoName>/
// and creates a new branch op/<opID> based on the current branch.
func Create(repoPath, opID string) (string, error) {
	return CreateWithBase(repoPath, opID, "")
}

// CreateWithBase creates a worktree with a custom base directory.
// If baseDir is empty, it defaults to ~/Projects/.ops/
func CreateWithBase(repoPath, opID, baseDir string) (string, error) {
	if baseDir == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("failed to get home directory: %w", err)
		}
		baseDir = filepath.Join(home, "Projects", ".ops")
	}

	// Get repo name from path
	repoName := filepath.Base(repoPath)

	// Construct worktree path
	worktreePath := filepath.Join(baseDir, opID, repoName)

	// Ensure parent directory exists
	if err := os.MkdirAll(filepath.Dir(worktreePath), 0755); err != nil {
		return "", fmt.Errorf("failed to create parent directories: %w", err)
	}

	// Check if worktree already exists
	if _, err := os.Stat(worktreePath); err == nil {
		return "", fmt.Errorf("worktree already exists at %s", worktreePath)
	}

	// Create branch name
	branchName := fmt.Sprintf("op/%s", opID)

	// Create worktree with new branch
	cmd := exec.Command("git", "worktree", "add", "-b", branchName, worktreePath)
	cmd.Dir = repoPath
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("failed to create worktree: %w", err)
	}

	return worktreePath, nil
}

// Remove removes a worktree at the specified path.
func Remove(worktreePath string) error {
	// Check if worktree exists
	if _, err := os.Stat(worktreePath); os.IsNotExist(err) {
		return fmt.Errorf("worktree does not exist at %s", worktreePath)
	}

	// Find the main repository path from the worktree
	repoPath, err := findMainRepo(worktreePath)
	if err != nil {
		return fmt.Errorf("failed to find main repository: %w", err)
	}

	// Remove worktree using git
	cmd := exec.Command("git", "worktree", "remove", worktreePath)
	cmd.Dir = repoPath
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		// Try force remove if regular remove fails
		cmd = exec.Command("git", "worktree", "remove", "-f", worktreePath)
		cmd.Dir = repoPath
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to remove worktree: %w", err)
		}
	}

	return nil
}

// findMainRepo finds the main repository path from a worktree path
func findMainRepo(worktreePath string) (string, error) {
	// Get the git directory for this worktree
	cmd := exec.Command("git", "rev-parse", "--git-common-dir")
	cmd.Dir = worktreePath
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to find git common dir: %w", err)
	}

	gitDir := string(output)
	gitDir = gitDir[:len(gitDir)-1] // Remove trailing newline

	// If it's a .git directory, the repo is the parent
	if filepath.Base(gitDir) == ".git" {
		return filepath.Dir(gitDir), nil
	}

	// For bare repos or worktrees, we need to find the main worktree
	// The common dir is usually .git or .git/worktrees/<name>
	if filepath.Base(filepath.Dir(gitDir)) == "worktrees" {
		// Go up to the .git directory
		gitDir = filepath.Dir(filepath.Dir(gitDir))
		// The main worktree is the parent of .git
		return filepath.Dir(gitDir), nil
	}

	return gitDir, nil
}

// Exists checks if a worktree exists at the given path
func Exists(worktreePath string) bool {
	_, err := os.Stat(worktreePath)
	return err == nil
}
