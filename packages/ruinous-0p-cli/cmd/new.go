package cmd

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"forge.meskill.farm/ruinous/0p-cli/internal/db"
	"forge.meskill.farm/ruinous/0p-cli/internal/worktree"
	"forge.meskill.farm/ruinous/0p-cli/internal/xdg"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var newCmd = &cobra.Command{
	Use:   "new [op-id]",
	Short: "Create a new Op",
	Long: `Create a new Op with the specified ID.

An Op represents an isolated development session with its own worktree,
configuration, and tmux session.`,
	Args: cobra.ExactArgs(1),
	RunE: runNew,
}

func init() {
	rootCmd.AddCommand(newCmd)

	newCmd.Flags().StringP("repo", "r", "", "Repository name (required)")
	newCmd.Flags().StringP("deck", "d", "", "Deck name (required)")
	newCmd.Flags().StringP("mode", "m", "interactive", "Op mode: interactive, autonomous, or exception")

	newCmd.MarkFlagRequired("repo")
	newCmd.MarkFlagRequired("deck")
}

func runNew(cmd *cobra.Command, args []string) error {
	opID := args[0]
	repo, _ := cmd.Flags().GetString("repo")
	deck, _ := cmd.Flags().GetString("deck")
	mode, _ := cmd.Flags().GetString("mode")

	// Validate op-id
	if err := validateOpID(opID); err != nil {
		return err
	}

	// Validate mode
	if err := validateMode(mode); err != nil {
		return err
	}

	// Validate repo exists
	repoPath, err := findRepoPath(repo)
	if err != nil {
		return err
	}

	// Get data directory
	dataDir := viper.GetString("data_dir")
	if dataDir == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("failed to get home directory: %w", err)
		}
		dataDir = filepath.Join(home, ".local", "share", "0p")
	}

	// Ensure data directory exists
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return fmt.Errorf("failed to create data directory: %w", err)
	}

	// Open database
	database, err := db.New(dataDir)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}
	defer database.Close()

	ctx := context.Background()

	// Check if op already exists
	_, _, _, err = database.GetOp(ctx, opID)
	if err == nil {
		return fmt.Errorf("op '%s' already exists", opID)
	}

	// Create op
	now := time.Now()
	op := &db.Op{
		ID:        opID,
		State:     "active",
		Mode:      mode,
		CreatedAt: now,
		UpdatedAt: now,
	}

	repos := []db.OpRepo{
		{
			OpID:         opID,
			RepoName:     repo,
			Branch:       fmt.Sprintf("op/%s", opID),
			WorktreePath: "", // Will be set after worktree creation
		},
	}

	decks := []db.OpDeck{
		{
			OpID:      opID,
			DeckName:  deck,
			IsPrimary: true,
		},
	}

	if err := database.CreateOp(ctx, op, repos, decks); err != nil {
		return fmt.Errorf("failed to create op: %w", err)
	}

	// Create worktree
	fmt.Printf("Creating worktree for op '%s'...\n", opID)
	worktreePath, err := worktree.Create(repoPath, opID)
	if err != nil {
		// Rollback: delete database record
		database.DeleteOp(ctx, opID)
		return fmt.Errorf("failed to create worktree: %w", err)
	}

	// Setup XDG directories
	fmt.Printf("Setting up XDG isolation...\n")
	_, err = xdg.Setup(opID)
	if err != nil {
		// Rollback: remove worktree and delete database record
		worktree.Remove(worktreePath)
		database.DeleteOp(ctx, opID)
		return fmt.Errorf("failed to setup XDG directories: %w", err)
	}

	// Update database with worktree path
	repos[0].WorktreePath = worktreePath
	op.UpdatedAt = time.Now()
	if err := database.UpdateOp(ctx, op); err != nil {
		// Rollback on error
		worktree.Remove(worktreePath)
		xdg.Cleanup(opID)
		database.DeleteOp(ctx, opID)
		return fmt.Errorf("failed to update op with worktree path: %w", err)
	}

	fmt.Printf("Op '%s' created. State: %s, Mode: %s\n", opID, op.State, op.Mode)
	fmt.Printf("Repository: %s (at %s)\n", repo, repoPath)
	fmt.Printf("Worktree: %s\n", worktreePath)
	fmt.Printf("Deck: %s\n", deck)
	fmt.Printf("Run `0p attach %s` to start working.\n", opID)

	return nil
}

func validateOpID(id string) error {
	if id == "" {
		return fmt.Errorf("op-id cannot be empty")
	}

	// Allow alphanumeric, hyphens, and underscores
	valid := regexp.MustCompile(`^[a-zA-Z0-9-_]+$`).MatchString(id)
	if !valid {
		return fmt.Errorf("op-id must contain only alphanumeric characters, hyphens, and underscores")
	}

	return nil
}

func validateMode(mode string) error {
	validModes := []string{"interactive", "autonomous", "exception"}
	for _, m := range validModes {
		if mode == m {
			return nil
		}
	}
	return fmt.Errorf("invalid mode '%s'. Must be one of: %s", mode, strings.Join(validModes, ", "))
}

func findRepoPath(repo string) (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}

	// Check common locations
	locations := []string{
		filepath.Join(home, "Projects", "ruinage", repo),
		filepath.Join(home, "Projects", repo),
		filepath.Join(home, "src", repo),
		filepath.Join(home, repo),
	}

	for _, loc := range locations {
		if _, err := os.Stat(filepath.Join(loc, ".git")); err == nil {
			return loc, nil
		}
	}

	return "", fmt.Errorf("repository '%s' not found in standard locations", repo)
}
