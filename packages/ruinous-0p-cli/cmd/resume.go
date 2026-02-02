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

var resumeCmd = &cobra.Command{
	Use:   "resume [op-id]",
	Short: "Resume a suspended Op",
	Long: `Resume a suspended Op by updating state and attaching to its tmux session.

This is similar to '0p attach' but specifically for suspended Ops.`,
	Args: cobra.ExactArgs(1),
	RunE: runResume,
}

func init() {
	rootCmd.AddCommand(resumeCmd)
}

func runResume(cmd *cobra.Command, args []string) error {
	opID := args[0]

	dataDir := viper.GetString("data_dir")
	if dataDir == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("failed to get home directory: %w", err)
		}
		dataDir = filepath.Join(home, ".local", "share", "0p")
	}

	database, err := db.New(dataDir)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}
	defer database.Close()

	ctx := context.Background()

	op, repos, _, err := database.GetOp(ctx, opID)
	if err != nil {
		return fmt.Errorf("op '%s' not found", opID)
	}

	if op.State != "suspended" {
		return fmt.Errorf("op '%s' is not suspended (current state: %s)", opID, op.State)
	}

	// Update state to active
	op.State = "active"
	if err := database.UpdateOp(ctx, op); err != nil {
		return fmt.Errorf("failed to update op state: %w", err)
	}

	// Ensure session exists
	if !session.Exists(opID) {
		if len(repos) == 0 || repos[0].WorktreePath == "" {
			return fmt.Errorf("op '%s' has no worktree path", opID)
		}
		xdgPaths := xdg.GetPaths(opID)
		sessionJSON, err := session.Generate(opID, repos[0].WorktreePath, xdgPaths)
		if err != nil {
			return fmt.Errorf("failed to generate session: %w", err)
		}
		if err := session.Save(opID, sessionJSON); err != nil {
			return fmt.Errorf("failed to save session: %w", err)
		}
	}

	// Attach to session
	tmuxpCmd := exec.Command("tmuxp", "load", opID)
	tmuxpCmd.Stdin = os.Stdin
	tmuxpCmd.Stdout = os.Stdout
	tmuxpCmd.Stderr = os.Stderr

	if err := tmuxpCmd.Run(); err != nil {
		return fmt.Errorf("failed to load tmux session: %w", err)
	}

	return nil
}
