package cmd

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	"forge.meskill.farm/ruinous/0p-cli/internal/db"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var statusCmd = &cobra.Command{
	Use:   "status [op-id]",
	Short: "Show detailed status of an Op",
	Long:  `Display detailed information about a specific Op including its state, mode, repository, and deck.`,
	Args:  cobra.ExactArgs(1),
	RunE:  runStatus,
}

func init() {
	rootCmd.AddCommand(statusCmd)
}

func runStatus(cmd *cobra.Command, args []string) error {
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
	op, repos, decks, err := database.GetOp(ctx, opID)
	if err != nil {
		return fmt.Errorf("op '%s' not found", opID)
	}

	// Display status
	fmt.Printf("Op: %s\n", op.ID)
	fmt.Printf("State: %s\n", op.State)
	fmt.Printf("Mode: %s\n", op.Mode)
	fmt.Printf("Created: %s\n", op.CreatedAt.Format("2006-01-02 15:04:05"))
	fmt.Printf("Updated: %s\n", op.UpdatedAt.Format("2006-01-02 15:04:05"))

	if len(repos) > 0 {
		fmt.Printf("\nRepositories:\n")
		for _, repo := range repos {
			fmt.Printf("  - %s (branch: %s)\n", repo.RepoName, repo.Branch)
			if repo.WorktreePath != "" {
				fmt.Printf("    Worktree: %s\n", repo.WorktreePath)
			}
		}
	}

	if len(decks) > 0 {
		fmt.Printf("\nDecks:\n")
		for _, deck := range decks {
			primary := ""
			if deck.IsPrimary {
				primary = " (primary)"
			}
			fmt.Printf("  - %s%s\n", deck.DeckName, primary)
		}
	}

	return nil
}
