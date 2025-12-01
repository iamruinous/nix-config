package tui

import "github.com/charmbracelet/bubbles/key"

// KeyMap defines the key bindings for the application.
type KeyMap struct {
	Up       key.Binding
	Down     key.Binding
	Select   key.Binding
	Toggle   key.Binding
	Confirm  key.Binding
	Cancel   key.Binding
	Quit     key.Binding
	Help     key.Binding
	PageUp   key.Binding
	PageDown key.Binding
}

// DefaultKeyMap returns the default key bindings.
func DefaultKeyMap() KeyMap {
	return KeyMap{
		Up: key.NewBinding(
			key.WithKeys("up", "k"),
			key.WithHelp("↑/k", "up"),
		),
		Down: key.NewBinding(
			key.WithKeys("down", "j"),
			key.WithHelp("↓/j", "down"),
		),
		Select: key.NewBinding(
			key.WithKeys("enter"),
			key.WithHelp("enter", "select"),
		),
		Toggle: key.NewBinding(
			key.WithKeys(" "),
			key.WithHelp("space", "toggle"),
		),
		Confirm: key.NewBinding(
			key.WithKeys("y"),
			key.WithHelp("y", "yes"),
		),
		Cancel: key.NewBinding(
			key.WithKeys("n", "esc"),
			key.WithHelp("n/esc", "no/back"),
		),
		Quit: key.NewBinding(
			key.WithKeys("q", "ctrl+c"),
			key.WithHelp("q", "quit"),
		),
		Help: key.NewBinding(
			key.WithKeys("?"),
			key.WithHelp("?", "help"),
		),
		PageUp: key.NewBinding(
			key.WithKeys("pgup"),
			key.WithHelp("pgup", "page up"),
		),
		PageDown: key.NewBinding(
			key.WithKeys("pgdown"),
			key.WithHelp("pgdown", "page down"),
		),
	}
}

// ShortHelp returns keybindings to be shown in the mini help view.
func (k KeyMap) ShortHelp() []key.Binding {
	return []key.Binding{k.Up, k.Down, k.Select, k.Quit}
}

// FullHelp returns keybindings for the expanded help view.
func (k KeyMap) FullHelp() [][]key.Binding {
	return [][]key.Binding{
		{k.Up, k.Down, k.PageUp, k.PageDown},
		{k.Select, k.Toggle, k.Confirm, k.Cancel},
		{k.Quit, k.Help},
	}
}
