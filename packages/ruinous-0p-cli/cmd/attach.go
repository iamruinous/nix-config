package cmd

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"forge.meskill.farm/ruinous/0p-cli/internal/db"
	"forge.meskill.farm/ruinous/0p-cli/internal/session"
	"forge.meskill.farm/ruinous/0p-cli/internal/xdg"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var attachCmd = &cobra.Command{
	Use:   "attach [op-id]",
	Short: "Attach to an Op's tmux session",
	Long: `Attach to an Op's tmux session, creating it if necessary.

This command will:
1. Generate a tmuxp session configuration if it doesn't exist
2. Load the session with tmuxp
3. Update the Op state to "active"

The current process will be replaced by the tmux session.`,
	Args: cobra.ExactArgs(1),
	RunE: runAttach,
}

func init() {
	rootCmd.AddCommand(attachCmd)
}

func runAttach(cmd *cobra.Command, args []string) error {
	opID := args[0]

	// Get data directory
	dataDir := viper.GetString("data_dir")
	if dataDir == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("failed to get home directory: %w", err)
		}
		dataDir = filepath.Join(home, ".local", "share", "0p")
	}

	// Open database
	database, err := db.New(dataDir)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}
	defer database.Close()

	ctx := context.Background()

	// Get op
	op, repos, _, err := database.GetOp(ctx, opID)
	if err != nil {
		return fmt.Errorf("op '%s' not found", opID)
	}

	// Check if op is in a valid state
	if op.State == "completed" {
		return fmt.Errorf("op '%s' is completed and cannot be attached", opID)
	}

	// Get worktree path
	if len(repos) == 0 {
		return fmt.Errorf("op '%s' has no associated repository", opID)
	}
	worktreePath := repos[0].WorktreePath
	if worktreePath == "" {
		return fmt.Errorf("op '%s' has no worktree path", opID)
	}

	// Generate session if it doesn't exist
	if !session.Exists(opID) {
		xdgPaths := xdg.GetPaths(opID)
		sessionJSON, err := session.Generate(opID, worktreePath, xdgPaths)
		if err != nil {
			return fmt.Errorf("failed to generate session: %w", err)
		}
		if err := session.Save(opID, sessionJSON); err != nil {
			return fmt.Errorf("failed to save session: %w", err)
		}
	}

	// Update op state to active
	if op.State != "active" {
		op.State = "active"
		if err := database.UpdateOp(ctx, op); err != nil {
			return fmt.Errorf("failed to update op state: %w", err)
		}
	}

	// Exec tmuxp load (replaces current process)
	tmuxpCmd := exec.Command("tmuxp", "load", opID)
	tmuxpCmd.Stdin = os.Stdin
	tmuxpCmd.Stdout = os.Stdout
	tmuxpCmd.Stderr = os.Stderr

	if err := tmuxpCmd.Run(); err != nil {
		return fmt.Errorf("failed to load tmux session: %w", err)
	}

	return nil
}
