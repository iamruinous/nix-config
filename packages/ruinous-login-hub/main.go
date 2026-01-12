package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"syscall"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type actionType int

const (
	actionHubSession actionType = iota
	actionTmuxpSession
	actionPlainShell
)

type menuItem struct {
	title       string
	description string
	action      actionType
	sessionName string
}

func (i menuItem) Title() string       { return i.title }
func (i menuItem) Description() string { return i.description }
func (i menuItem) FilterValue() string { return i.title }

type model struct {
	list   list.Model
	banner string
	width  int
	height int
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.list.SetSize(msg.Width, msg.Height-strings.Count(m.banner, "\n")-4)
		return m, nil

	case tea.KeyMsg:
		// Handle quit
		if msg.String() == "ctrl+c" {
			return m, tea.Quit
		}

		// Handle selection
		if msg.String() == "enter" {
			selected := m.list.SelectedItem()
			if item, ok := selected.(menuItem); ok {
				return m, executeAction(item)
			}
		}
	}

	// Let the list handle all updates (navigation and filtering)
	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m model) View() string {
	helpStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		MarginTop(1)

	instructions := "ctrl+j/k: navigate • /: filter • enter: select • ctrl+c: quit"

	// Don't apply styling to banner - it has its own colors from toilet
	return fmt.Sprintf(
		"%s\n%s\n%s",
		m.banner,
		m.list.View(),
		helpStyle.Render(instructions),
	)
}

func generateBanner() string {
	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown"
	}

	toiletPath, err := exec.LookPath("toilet")
	if err != nil {
		// Fallback if toilet somehow isn't available
		return fmt.Sprintf(`
╔═══════════════════════════════════╗
║  %s
╚═══════════════════════════════════╝`, hostname)
	}

	// Use toilet with smblock font and metal filter for gradient colors
	cmd := exec.Command(toiletPath, "-f", "smblock", "-F", "metal", hostname)
	output, err := cmd.Output()
	if err == nil && len(output) > 0 {
		return string(output)
	}

	// Fallback to toilet without filter if metal fails
	cmd = exec.Command(toiletPath, "-f", "smblock", hostname)
	output, err = cmd.Output()
	if err == nil && len(output) > 0 {
		return string(output)
	}

	// Final fallback
	return fmt.Sprintf(`
╔═══════════════════════════════════╗
║  %s
╚═══════════════════════════════════╝`, hostname)
}

func discoverTmuxpSessions() []string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return []string{}
	}

	tmuxpDir := filepath.Join(homeDir, ".config", "tmuxp")

	if _, err := os.Stat(tmuxpDir); os.IsNotExist(err) {
		return []string{}
	}

	files, err := filepath.Glob(filepath.Join(tmuxpDir, "*.json"))
	if err != nil {
		return []string{}
	}

	sessions := make([]string, 0, len(files))
	for _, file := range files {
		base := filepath.Base(file)
		name := strings.TrimSuffix(base, ".json")

		// Skip "hub" since we have a dedicated Hub Session option
		if name == "hub" {
			continue
		}

		sessions = append(sessions, name)
	}

	sort.Strings(sessions)

	return sessions
}

func buildMenuItems() []list.Item {
	items := []list.Item{}

	items = append(items, menuItem{
		title:       "Hub Session",
		description: "Attach to or create the main hub tmux session",
		action:      actionHubSession,
	})

	sessions := discoverTmuxpSessions()
	for _, session := range sessions {
		items = append(items, menuItem{
			title:       fmt.Sprintf("tmuxp: %s", session),
			description: fmt.Sprintf("Load tmuxp session: %s", session),
			action:      actionTmuxpSession,
			sessionName: session,
		})
	}

	items = append(items, menuItem{
		title:       "Plain Shell",
		description: "Exit to a plain shell",
		action:      actionPlainShell,
	})

	return items
}

func executeAction(item menuItem) tea.Cmd {
	return func() tea.Msg {
		switch item.action {
		case actionHubSession:
			execTmuxHub()
		case actionTmuxpSession:
			execTmuxp(item.sessionName)
		case actionPlainShell:
			os.Exit(0)
		}
		return nil
	}
}

func execTmuxHub() {
	tmuxPath, err := exec.LookPath("tmux")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: tmux not found: %v\n", err)
		os.Exit(1)
	}

	args := []string{"tmux", "new-session", "-A", "-s", "hub"}
	env := os.Environ()

	err = syscall.Exec(tmuxPath, args, env)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error executing tmux: %v\n", err)
		os.Exit(1)
	}
}

func execTmuxp(sessionName string) {
	tmuxpPath, err := exec.LookPath("tmuxp")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: tmuxp not found: %v\n", err)
		os.Exit(1)
	}

	args := []string{"tmuxp", "load", "--yes", sessionName}
	env := os.Environ()

	err = syscall.Exec(tmuxpPath, args, env)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error executing tmuxp: %v\n", err)
		os.Exit(1)
	}
}

func main() {
	banner := generateBanner()
	items := buildMenuItems()

	delegate := list.NewDefaultDelegate()
	delegate.Styles.SelectedTitle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("170")).
		Bold(true)
	delegate.Styles.SelectedDesc = lipgloss.NewStyle().
		Foreground(lipgloss.Color("241"))

	l := list.New(items, delegate, 0, 0)
	l.Title = ""
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.SetShowHelp(false)

	// Customize key bindings to use Ctrl+J/K for navigation
	l.KeyMap.CursorUp = key.NewBinding(
		key.WithKeys("ctrl+k"),
		key.WithHelp("ctrl+k", "up"),
	)
	l.KeyMap.CursorDown = key.NewBinding(
		key.WithKeys("ctrl+j"),
		key.WithHelp("ctrl+j", "down"),
	)

	// Disable vim-style navigation keys so they can be typed for filtering
	l.KeyMap.NextPage = key.NewBinding(key.WithKeys())
	l.KeyMap.PrevPage = key.NewBinding(key.WithKeys())
	l.KeyMap.GoToStart = key.NewBinding(key.WithKeys())
	l.KeyMap.GoToEnd = key.NewBinding(key.WithKeys())

	m := model{
		list:   l,
		banner: banner,
	}

	p := tea.NewProgram(m, tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
