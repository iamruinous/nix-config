package cmd

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"forge.meskill.farm/ruinous/0p-cli/internal/db"
	"forge.meskill.farm/ruinous/0p-cli/internal/session"
	"forge.meskill.farm/ruinous/0p-cli/internal/worktree"
	"forge.meskill.farm/ruinous/0p-cli/internal/xdg"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var completeCmd = &cobra.Command{
	Use:   "complete [op-id]",
	Short: "Complete an Op and clean up",
	Long: `Complete an Op by cleaning up resources and marking it as completed.

This will:
1. Prompt for confirmation
2. Optionally merge the branch to main
3. Kill the tmux session
4. Remove the worktree
5. Clean up XDG directories
6. Remove the tmuxp session config
7. Mark the Op as completed`,
	Args: cobra.ExactArgs(1),
	RunE: runComplete,
}

func init() {
	rootCmd.AddCommand(completeCmd)
}

func runComplete(cmd *cobra.Command, args []string) error {
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

	if op.State == "completed" {
		return fmt.Errorf("op '%s' is already completed", opID)
	}

	// Confirmation
	fmt.Printf("Complete op '%s'? This will clean up all resources. [y/N]: ", opID)
	reader := bufio.NewReader(os.Stdin)
	response, _ := reader.ReadString('\n')
	response = strings.TrimSpace(strings.ToLower(response))
	if response != "y" && response != "yes" {
		fmt.Println("Cancelled.")
		return nil
	}

	worktreePath := ""
	if len(repos) > 0 {
		worktreePath = repos[0].WorktreePath
	}

	// Check for unmerged changes and offer to merge
	if worktreePath != "" {
		// Check if there are commits not in main
		mainRepo := filepath.Dir(worktreePath) // Parent of worktree is the main repo
		gitCmd := exec.Command("git", "log", "main..op/"+opID, "--oneline")
		gitCmd.Dir = mainRepo
		output, _ := gitCmd.Output()
		if len(output) > 0 {
			fmt.Printf("Branch 'op/%s' has unmerged commits:\n%s\n", opID, string(output))
			fmt.Printf("Merge to main? [y/N]: ")
			response, _ := reader.ReadString('\n')
			response = strings.TrimSpace(strings.ToLower(response))
			if response == "y" || response == "yes" {
				// Merge
				mergeCmd := exec.Command("git", "merge", "--no-ff", "-m", fmt.Sprintf("Merge op/%s", opID), "op/"+opID)
				mergeCmd.Dir = mainRepo
				mergeCmd.Stderr = os.Stderr
				if err := mergeCmd.Run(); err != nil {
					fmt.Printf("Warning: merge failed: %v\n", err)
				} else {
					fmt.Println("Merged successfully.")
				}
			}
		}
	}

	// Kill tmux session
	tmuxCmd := exec.Command("tmux", "kill-session", "-t", opID)
	tmuxCmd.Stderr = os.Stderr
	// Ignore error - session may not exist
	tmuxCmd.Run()

	// Remove worktree
	if worktreePath != "" {
		fmt.Printf("Removing worktree at %s...\n", worktreePath)
		if err := worktree.Remove(worktreePath); err != nil {
			fmt.Printf("Warning: failed to remove worktree: %v\n", err)
		}
	}

	// Cleanup XDG directories
	fmt.Printf("Cleaning up XDG directories...\n")
	if err := xdg.Cleanup(opID); err != nil {
		fmt.Printf("Warning: failed to cleanup XDG directories: %v\n", err)
	}

	// Remove tmuxp session config
	fmt.Printf("Removing tmuxp session config...\n")
	if err := session.Remove(opID); err != nil {
		fmt.Printf("Warning: failed to remove session config: %v\n", err)
	}

	// Update op state to completed
	op.State = "completed"
	if err := database.UpdateOp(ctx, op); err != nil {
		return fmt.Errorf("failed to update op state: %w", err)
	}

	fmt.Printf("Op '%s' completed.\n", opID)
	return nil
}
