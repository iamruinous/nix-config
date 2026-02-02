package session

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"forge.meskill.farm/ruinous/0p-cli/internal/xdg"
)

// Session represents a tmuxp session configuration
type Session struct {
	SessionName string            `json:"session_name"`
	StartDir    string            `json:"start_directory"`
	Environment map[string]string `json:"environment"`
	Windows     []Window          `json:"windows"`
}

// Window represents a tmux window configuration
type Window struct {
	WindowName string `json:"window_name"`
	Focus      bool   `json:"focus,omitempty"`
	Panes      []Pane `json:"panes"`
}

// Pane represents a tmux pane configuration
type Pane struct {
	ShellCommand string `json:"shell_command"`
}

// Generate creates a tmuxp session configuration for an Op
func Generate(opID, worktreePath string, xdgPaths *xdg.XDGPaths) (string, error) {
	session := &Session{
		SessionName: opID,
		StartDir:    worktreePath,
		Environment: map[string]string{
			"XDG_CONFIG_HOME": xdgPaths.ConfigHome,
			"XDG_DATA_HOME":   xdgPaths.DataHome,
			"XDG_STATE_HOME":  xdgPaths.StateHome,
			"OP_ID":           opID,
		},
		Windows: []Window{
			{
				WindowName: "logs",
				Panes: []Pane{
					{ShellCommand: fmt.Sprintf("journalctl -fu opencode@%s 2>/dev/null || echo 'No service logs for %s'", opID, opID)},
				},
			},
			{
				WindowName: "agent",
				Focus:      true,
				Panes: []Pane{
					{ShellCommand: "opencode"},
				},
			},
			{
				WindowName: "editor",
				Panes: []Pane{
					{ShellCommand: "nvim ."},
				},
			},
			{
				WindowName: "files",
				Panes: []Pane{
					{ShellCommand: "xplr"},
				},
			},
			{
				WindowName: "shell",
				Panes: []Pane{
					{ShellCommand: "fish"},
				},
			},
		},
	}

	jsonBytes, err := json.MarshalIndent(session, "", "  ")
	if err != nil {
		return "", fmt.Errorf("failed to marshal session to JSON: %w", err)
	}

	return string(jsonBytes), nil
}

// Save writes the session configuration to the tmuxp directory
func Save(opID, sessionJSON string) error {
	home, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get home directory: %w", err)
	}

	tmuxpDir := filepath.Join(home, ".config", "tmuxp")
	if err := os.MkdirAll(tmuxpDir, 0755); err != nil {
		return fmt.Errorf("failed to create tmuxp directory: %w", err)
	}

	sessionPath := filepath.Join(tmuxpDir, fmt.Sprintf("%s.json", opID))
	if err := os.WriteFile(sessionPath, []byte(sessionJSON), 0644); err != nil {
		return fmt.Errorf("failed to write session file: %w", err)
	}

	return nil
}

// Remove deletes the session configuration for an Op
func Remove(opID string) error {
	home, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get home directory: %w", err)
	}

	sessionPath := filepath.Join(home, ".config", "tmuxp", fmt.Sprintf("%s.json", opID))
	if err := os.Remove(sessionPath); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to remove session file: %w", err)
	}

	return nil
}

// Exists checks if a session configuration exists for an Op
func Exists(opID string) bool {
	home, err := os.UserHomeDir()
	if err != nil {
		return false
	}

	sessionPath := filepath.Join(home, ".config", "tmuxp", fmt.Sprintf("%s.json", opID))
	_, err = os.Stat(sessionPath)
	return err == nil
}
