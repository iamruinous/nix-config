package cmd

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"text/tabwriter"

	"forge.meskill.farm/ruinous/0p-cli/internal/db"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all Ops",
	Long:  `List all Ops with their current state, repository, deck, and mode.`,
	RunE:  runList,
}

func init() {
	rootCmd.AddCommand(listCmd)
}

func runList(cmd *cobra.Command, args []string) error {
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

	// List ops
	ops, err := database.ListOps(ctx)
	if err != nil {
		return fmt.Errorf("failed to list ops: %w", err)
	}

	if len(ops) == 0 {
		fmt.Println("No ops found")
		return nil
	}

	// Print table
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "ID\tSTATE\tREPO\tDECK\tMODE")
	fmt.Fprintln(w, "----\t-----\t----\t----\t----")

	for _, op := range ops {
		// Get repo and deck info
		repo, err := database.GetOpRepo(ctx, op.ID)
		repoName := "-"
		if err == nil && repo != nil {
			repoName = repo.RepoName
		}

		deck, err := database.GetOpDeck(ctx, op.ID)
		deckName := "-"
		if err == nil && deck != nil {
			deckName = deck.DeckName
		}

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n", op.ID, op.State, repoName, deckName, op.Mode)
	}

	w.Flush()
	return nil
}
