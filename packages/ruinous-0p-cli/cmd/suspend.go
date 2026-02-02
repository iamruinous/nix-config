package cmd

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"forge.meskill.farm/ruinous/0p-cli/internal/db"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var suspendCmd = &cobra.Command{
	Use:   "suspend [op-id]",
	Short: "Suspend an active Op",
	Long: `Suspend an active Op by detaching from its tmux session and updating state.

The Op can be resumed later with '0p resume'.`,
	Args: cobra.ExactArgs(1),
	RunE: runSuspend,
}

func init() {
	rootCmd.AddCommand(suspendCmd)
}

func runSuspend(cmd *cobra.Command, args []string) error {
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

	op, _, _, err := database.GetOp(ctx, opID)
	if err != nil {
		return fmt.Errorf("op '%s' not found", opID)
	}

	if op.State != "active" {
		return fmt.Errorf("op '%s' is not active (current state: %s)", opID, op.State)
	}

	// Detach from tmux session if attached
	tmuxCmd := exec.Command("tmux", "detach-client", "-s", opID)
	tmuxCmd.Stderr = os.Stderr
	// Ignore error - may not be attached
	tmuxCmd.Run()

	// Update state to suspended
	op.State = "suspended"
	if err := database.UpdateOp(ctx, op); err != nil {
		return fmt.Errorf("failed to update op state: %w", err)
	}

	fmt.Printf("Op '%s' suspended.\n", opID)
	return nil
}
