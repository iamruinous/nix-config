package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	Version string
	Commit  string
	Date    string
)

var rootCmd = &cobra.Command{
	Use:   "0p",
	Short: "0p - Op management CLI for isolated development sessions",
	Long: `0p is a CLI tool for managing Ops - isolated development sessions
with worktree isolation, XDG directory separation, and tmux session management.

Ops are units of work that can be created, attached to, suspended, and completed.
Each Op gets its own worktree, isolated agent configuration, and tmux session.`,
}

func Execute() error {
	return rootCmd.Execute()
}

func init() {
	cobra.OnInitialize(initConfig)

	rootCmd.PersistentFlags().StringP("config", "c", "", "config file (default is $HOME/.config/0p/config.yaml)")
	rootCmd.PersistentFlags().StringP("data-dir", "D", "", "data directory for op state (default is $HOME/.local/share/0p)")

	viper.BindPFlag("config", rootCmd.PersistentFlags().Lookup("config"))
	viper.BindPFlag("data_dir", rootCmd.PersistentFlags().Lookup("data-dir"))
}

func initConfig() {
	configFile := viper.GetString("config")

	if configFile != "" {
		viper.SetConfigFile(configFile)
	} else {
		home, err := os.UserHomeDir()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error getting home directory: %v\n", err)
			os.Exit(1)
		}

		viper.AddConfigPath(home + "/.config/0p")
		viper.SetConfigName("config")
		viper.SetConfigType("yaml")
	}

	viper.AutomaticEnv()
	viper.SetEnvPrefix("OP")

	if err := viper.ReadInConfig(); err == nil {
		fmt.Fprintf(os.Stderr, "Using config file: %s\n", viper.ConfigFileUsed())
	}
}
