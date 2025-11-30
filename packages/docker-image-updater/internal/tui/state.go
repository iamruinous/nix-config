// Package tui provides the Bubbletea-based terminal user interface.
package tui

// State represents the current state of the application.
type State int

const (
	StateInitial State = iota
	StateScanning
	StateChecking
	StateShowDryRun
	StateShowUpdates
	StateMainMenu
	StateHostSelect
	StateIndividualSelect
	StateConfirming
	StateApplying
	StateShowCommands
	StateDone
	StateError
)

// String returns a human-readable name for the state.
func (s State) String() string {
	switch s {
	case StateInitial:
		return "Initial"
	case StateScanning:
		return "Scanning"
	case StateChecking:
		return "Checking"
	case StateShowDryRun:
		return "ShowDryRun"
	case StateShowUpdates:
		return "ShowUpdates"
	case StateMainMenu:
		return "MainMenu"
	case StateHostSelect:
		return "HostSelect"
	case StateIndividualSelect:
		return "IndividualSelect"
	case StateConfirming:
		return "Confirming"
	case StateApplying:
		return "Applying"
	case StateShowCommands:
		return "ShowCommands"
	case StateDone:
		return "Done"
	case StateError:
		return "Error"
	default:
		return "Unknown"
	}
}

// MenuChoice represents a choice in the main menu.
type MenuChoice int

const (
	MenuChoiceAll MenuChoice = iota
	MenuChoiceByHost
	MenuChoiceIndividual
	MenuChoiceShowCommands
	MenuChoiceExit
)

// String returns the display text for a menu choice.
func (c MenuChoice) String() string {
	switch c {
	case MenuChoiceAll:
		return "All images"
	case MenuChoiceByHost:
		return "All images for a specific host"
	case MenuChoiceIndividual:
		return "Individual images"
	case MenuChoiceShowCommands:
		return "Show update commands only"
	case MenuChoiceExit:
		return "Exit"
	default:
		return "Unknown"
	}
}

// AllMenuChoices returns all available menu choices.
func AllMenuChoices() []MenuChoice {
	return []MenuChoice{
		MenuChoiceAll,
		MenuChoiceByHost,
		MenuChoiceIndividual,
		MenuChoiceShowCommands,
		MenuChoiceExit,
	}
}
