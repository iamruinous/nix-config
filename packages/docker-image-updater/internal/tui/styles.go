package tui

import "github.com/charmbracelet/lipgloss"

// Color constants
var (
	ColorPrimary   = lipgloss.Color("212") // Pink
	ColorSecondary = lipgloss.Color("4")   // Blue
	ColorSuccess   = lipgloss.Color("2")   // Green
	ColorWarning   = lipgloss.Color("3")   // Yellow
	ColorError     = lipgloss.Color("1")   // Red
	ColorMuted     = lipgloss.Color("8")   // Gray
)

// Styles for various UI elements
var (
	// TitleStyle is used for the main title banner
	TitleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(ColorPrimary).
			Border(lipgloss.DoubleBorder()).
			BorderForeground(ColorPrimary).
			Padding(1, 2).
			Align(lipgloss.Center).
			Width(50)

	// HeaderStyle is used for section headers
	HeaderStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(ColorSecondary).
			Border(lipgloss.NormalBorder()).
			BorderForeground(ColorSecondary).
			Padding(0, 1)

	// SuccessStyle is used for success messages
	SuccessStyle = lipgloss.NewStyle().
			Foreground(ColorSuccess)

	// WarningStyle is used for warning messages
	WarningStyle = lipgloss.NewStyle().
			Foreground(ColorWarning)

	// ErrorStyle is used for error messages
	ErrorStyle = lipgloss.NewStyle().
			Foreground(ColorError)

	// MutedStyle is used for less important text
	MutedStyle = lipgloss.NewStyle().
			Foreground(ColorMuted)

	// BoldStyle is used for emphasized text
	BoldStyle = lipgloss.NewStyle().
			Bold(true)

	// TableHeaderStyle is used for table headers
	TableHeaderStyle = lipgloss.NewStyle().
				Bold(true).
				Foreground(ColorSecondary).
				Padding(0, 1)

	// TableCellStyle is used for table cells
	TableCellStyle = lipgloss.NewStyle().
			Padding(0, 1)

	// SelectedStyle is used for selected items
	SelectedStyle = lipgloss.NewStyle().
			Background(ColorSecondary).
			Foreground(lipgloss.Color("15"))

	// CursorStyle is used for the cursor indicator
	CursorStyle = lipgloss.NewStyle().
			Foreground(ColorPrimary).
			Bold(true)

	// HelpStyle is used for help text
	HelpStyle = lipgloss.NewStyle().
			Foreground(ColorMuted).
			MarginTop(1)

	// SpinnerStyle is used for the spinner
	SpinnerStyle = lipgloss.NewStyle().
			Foreground(ColorPrimary)
)
