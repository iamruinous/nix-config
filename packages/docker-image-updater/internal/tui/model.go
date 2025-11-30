package tui

import (
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"

	"github.com/iamruinous/docker-image-updater/internal/registry"
	"github.com/iamruinous/docker-image-updater/internal/scanner"
	"github.com/iamruinous/docker-image-updater/internal/updater"
)

// Config holds configuration for the TUI.
type Config struct {
	ConfigPath string
	HostFilter string
	Limit      int
	DryRun     bool
}

// Model is the main Bubbletea model.
type Model struct {
	// Configuration
	config Config

	// Components
	scanner  *scanner.Scanner
	checker  *registry.Checker
	updater  *updater.Updater
	spinner  spinner.Model
	keys     KeyMap

	// Current state
	state State

	// Data
	containers    []scanner.Container
	updateResults []registry.UpdateResult
	applyResults  []updater.ApplyResult
	selected      map[string]bool // Map of selected container keys for multi-select

	// Menu/selection state
	menuCursor    int
	cursor        int
	hosts         []string      // Unique hosts with updates
	selectedHost  string        // Currently selected host for by-host update

	// Progress tracking
	checkProgress int
	checkTotal    int

	// Results
	errorMsg string

	// Terminal dimensions
	width  int
	height int
}

// NewModel creates a new Model with the given configuration.
func NewModel(config Config) Model {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = SpinnerStyle

	return Model{
		config:   config,
		scanner:  scanner.NewScanner(config.ConfigPath),
		checker:  registry.NewChecker(""),
		updater:  updater.NewUpdater(config.ConfigPath),
		spinner:  s,
		keys:     DefaultKeyMap(),
		state:    StateInitial,
		selected: make(map[string]bool),
	}
}

// Init initializes the model.
func (m Model) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		m.startScanning(),
	)
}

// Messages

type (
	// scanCompleteMsg indicates scanning is done.
	scanCompleteMsg struct {
		containers []scanner.Container
		err        error
	}

	// checkProgressMsg indicates progress in checking.
	checkProgressMsg struct {
		current int
		total   int
	}

	// checkResultMsg indicates a single check result.
	checkResultMsg struct {
		result registry.UpdateResult
	}

	// checkCompleteMsg indicates all checks are done.
	checkCompleteMsg struct{}

	// applyResultMsg indicates an update was applied.
	applyResultMsg struct {
		result updater.ApplyResult
	}

	// applyCompleteMsg indicates all updates are applied.
	applyCompleteMsg struct{}
)

// Commands

func (m Model) startScanning() tea.Cmd {
	return func() tea.Msg {
		containers, err := m.scanner.Scan(m.config.HostFilter)
		return scanCompleteMsg{containers: containers, err: err}
	}
}

func (m Model) startChecking() tea.Cmd {
	return func() tea.Msg {
		// This is a synchronous check for simplicity
		// In a real app, you might want to use channels for progress updates
		return checkCompleteMsg{}
	}
}

func (m *Model) checkAllUpdates() tea.Cmd {
	return func() tea.Msg {
		total := len(m.containers)
		if m.config.Limit > 0 && m.config.Limit < total {
			total = m.config.Limit
		}

		for i, container := range m.containers {
			if m.config.Limit > 0 && i >= m.config.Limit {
				break
			}

			result := m.checker.CheckForUpdate(container)
			if result.HasUpdate {
				m.updateResults = append(m.updateResults, *result)
			}
		}

		return checkCompleteMsg{}
	}
}

// Update handles messages and updates the model.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tea.KeyMsg:
		switch m.state {
		case StateMainMenu:
			return m.handleMainMenuKey(msg)
		case StateHostSelect:
			return m.handleHostSelectKey(msg)
		case StateIndividualSelect:
			return m.handleIndividualSelectKey(msg)
		case StateConfirming:
			return m.handleConfirmKey(msg)
		case StateShowCommands, StateShowDryRun, StateDone, StateError:
			return m.handleViewKey(msg)
		}

		// Global key handling
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		}

	case spinner.TickMsg:
		if m.state == StateScanning || m.state == StateChecking || m.state == StateApplying {
			m.spinner, cmd = m.spinner.Update(msg)
			return m, cmd
		}

	case scanCompleteMsg:
		if msg.err != nil {
			m.state = StateError
			m.errorMsg = msg.err.Error()
			return m, nil
		}
		m.containers = msg.containers

		if len(m.containers) == 0 {
			m.state = StateDone
			m.errorMsg = "No containers found"
			return m, nil
		}

		if m.config.DryRun {
			m.state = StateShowDryRun
			return m, nil
		}

		m.state = StateChecking
		m.checkTotal = len(m.containers)
		if m.config.Limit > 0 && m.config.Limit < m.checkTotal {
			m.checkTotal = m.config.Limit
		}
		return m, m.doCheckUpdates()

	case checkProgressMsg:
		m.checkProgress = msg.current
		m.checkTotal = msg.total
		return m, nil

	case checkResultMsg:
		if msg.result.HasUpdate {
			m.updateResults = append(m.updateResults, msg.result)
		}
		return m, nil

	case checkCompleteMsg:
		if len(m.updateResults) == 0 {
			m.state = StateDone
			return m, nil
		}
		m.state = StateShowUpdates
		m.buildHostsList()
		return m, nil

	case applyResultMsg:
		m.applyResults = append(m.applyResults, msg.result)
		return m, nil

	case applyCompleteMsg:
		m.state = StateDone
		return m, nil
	}

	return m, cmd
}

// doCheckUpdates performs the actual update checking.
func (m *Model) doCheckUpdates() tea.Cmd {
	return func() tea.Msg {
		total := len(m.containers)
		if m.config.Limit > 0 && m.config.Limit < total {
			total = m.config.Limit
		}

		for i, container := range m.containers {
			if m.config.Limit > 0 && i >= m.config.Limit {
				break
			}

			result := m.checker.CheckForUpdate(container)
			if result.HasUpdate {
				m.updateResults = append(m.updateResults, *result)
			}
			m.checkProgress = i + 1
		}

		return checkCompleteMsg{}
	}
}

// buildHostsList builds the list of unique hosts with updates.
func (m *Model) buildHostsList() {
	hostMap := make(map[string]bool)
	for _, result := range m.updateResults {
		hostMap[result.Container.Host] = true
	}

	m.hosts = make([]string, 0, len(hostMap))
	for host := range hostMap {
		m.hosts = append(m.hosts, host)
	}
}

// Key handlers

func (m Model) handleMainMenuKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	choices := AllMenuChoices()

	switch msg.String() {
	case "up", "k":
		if m.menuCursor > 0 {
			m.menuCursor--
		}
	case "down", "j":
		if m.menuCursor < len(choices)-1 {
			m.menuCursor++
		}
	case "enter":
		choice := choices[m.menuCursor]
		switch choice {
		case MenuChoiceAll:
			m.state = StateConfirming
			return m, nil
		case MenuChoiceByHost:
			m.state = StateHostSelect
			m.cursor = 0
			return m, nil
		case MenuChoiceIndividual:
			m.state = StateIndividualSelect
			m.cursor = 0
			// Initialize all as unselected
			m.selected = make(map[string]bool)
			return m, nil
		case MenuChoiceShowCommands:
			m.state = StateShowCommands
			return m, nil
		case MenuChoiceExit:
			return m, tea.Quit
		}
	case "q":
		return m, tea.Quit
	}

	return m, nil
}

func (m Model) handleHostSelectKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < len(m.hosts)-1 {
			m.cursor++
		}
	case "enter":
		m.selectedHost = m.hosts[m.cursor]
		m.state = StateConfirming
		return m, nil
	case "esc", "q":
		m.state = StateMainMenu
		return m, nil
	}

	return m, nil
}

func (m Model) handleIndividualSelectKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < len(m.updateResults)-1 {
			m.cursor++
		}
	case " ": // Space to toggle
		key := m.updateResults[m.cursor].Container.Key()
		m.selected[key] = !m.selected[key]
	case "enter":
		// Apply selected updates
		m.state = StateApplying
		return m, m.applySelectedUpdates()
	case "esc", "q":
		m.state = StateMainMenu
		return m, nil
	}

	return m, nil
}

func (m Model) handleConfirmKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "y", "Y":
		m.state = StateApplying
		if m.selectedHost != "" {
			return m, m.applyHostUpdates()
		}
		return m, m.applyAllUpdates()
	case "n", "N", "esc":
		m.state = StateMainMenu
		m.selectedHost = ""
		return m, nil
	}

	return m, nil
}

func (m Model) handleViewKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "enter", "q", "esc":
		if m.state == StateShowCommands {
			m.state = StateMainMenu
			return m, nil
		}
		return m, tea.Quit
	}

	return m, nil
}

// Apply commands

func (m *Model) applyAllUpdates() tea.Cmd {
	return func() tea.Msg {
		for _, result := range m.updateResults {
			applyResult := m.updater.Apply(result)
			m.applyResults = append(m.applyResults, applyResult)
		}
		return applyCompleteMsg{}
	}
}

func (m *Model) applyHostUpdates() tea.Cmd {
	return func() tea.Msg {
		for _, result := range m.updateResults {
			if result.Container.Host == m.selectedHost {
				applyResult := m.updater.Apply(result)
				m.applyResults = append(m.applyResults, applyResult)
			}
		}
		return applyCompleteMsg{}
	}
}

func (m *Model) applySelectedUpdates() tea.Cmd {
	return func() tea.Msg {
		for _, result := range m.updateResults {
			if m.selected[result.Container.Key()] {
				applyResult := m.updater.Apply(result)
				m.applyResults = append(m.applyResults, applyResult)
			}
		}
		return applyCompleteMsg{}
	}
}

// TransitionToMenu transitions to the main menu after showing updates.
func (m *Model) TransitionToMenu() {
	m.state = StateMainMenu
	m.menuCursor = 0
}
