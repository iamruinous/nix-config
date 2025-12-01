package tui

import (
	"fmt"
	"strings"
)

// View renders the current state of the model.
func (m Model) View() string {
	var b strings.Builder

	// Title banner
	b.WriteString(m.renderTitle())
	b.WriteString("\n\n")

	// State-specific content
	switch m.state {
	case StateInitial, StateScanning:
		b.WriteString(m.renderScanning())
	case StateChecking:
		b.WriteString(m.renderChecking())
	case StateShowDryRun:
		b.WriteString(m.renderDryRun())
	case StateShowUpdates:
		b.WriteString(m.renderUpdates())
		b.WriteString("\n")
		b.WriteString(m.renderMainMenu())
	case StateMainMenu:
		b.WriteString(m.renderUpdates())
		b.WriteString("\n")
		b.WriteString(m.renderMainMenu())
	case StateHostSelect:
		b.WriteString(m.renderUpdates())
		b.WriteString("\n")
		b.WriteString(m.renderHostSelect())
	case StateIndividualSelect:
		b.WriteString(m.renderIndividualSelect())
	case StateConfirming:
		b.WriteString(m.renderUpdates())
		b.WriteString("\n")
		b.WriteString(m.renderConfirm())
	case StateApplying:
		b.WriteString(m.renderApplying())
	case StateShowCommands:
		b.WriteString(m.renderCommands())
	case StateDone:
		b.WriteString(m.renderDone())
	case StateError:
		b.WriteString(m.renderError())
	}

	return b.String()
}

func (m Model) renderTitle() string {
	return TitleStyle.Render("Docker Image Updater\nfor NixOS Configurations")
}

func (m Model) renderScanning() string {
	return fmt.Sprintf("%s Scanning container configurations...", m.spinner.View())
}

func (m Model) renderChecking() string {
	progress := ""
	if m.checkTotal > 0 {
		progress = fmt.Sprintf(" [%d/%d]", m.checkProgress, m.checkTotal)
	}
	return fmt.Sprintf("%s Checking for updates...%s", m.spinner.View(), progress)
}

func (m Model) renderDryRun() string {
	var b strings.Builder

	b.WriteString(HeaderStyle.Render("Discovered Containers"))
	b.WriteString("\n\n")

	b.WriteString(m.renderContainersTable())
	b.WriteString("\n")

	hostMsg := ""
	if m.config.HostFilter != "" {
		hostMsg = fmt.Sprintf(" for host '%s'", m.config.HostFilter)
	} else {
		hostMsg = fmt.Sprintf(" across %d hosts", m.countUniqueHosts())
	}

	b.WriteString(SuccessStyle.Render(fmt.Sprintf("Found %d containers%s", len(m.containers), hostMsg)))
	b.WriteString("\n\n")
	b.WriteString(MutedStyle.Render("Press enter or q to exit"))

	return b.String()
}

func (m Model) renderUpdates() string {
	var b strings.Builder

	b.WriteString(HeaderStyle.Render("Available Updates"))
	b.WriteString("\n\n")

	b.WriteString(m.renderUpdatesTable())
	b.WriteString("\n")

	b.WriteString(WarningStyle.Render(fmt.Sprintf("Found %d available updates", len(m.updateResults))))

	return b.String()
}

func (m Model) renderContainersTable() string {
	var b strings.Builder

	// Header
	b.WriteString(TableHeaderStyle.Render(fmt.Sprintf("%-15s %-20s %-40s %-15s", "HOST", "CONTAINER", "IMAGE", "TAG")))
	b.WriteString("\n")
	b.WriteString(MutedStyle.Render(fmt.Sprintf("%-15s %-20s %-40s %-15s", "----", "---------", "-----", "---")))
	b.WriteString("\n")

	// Rows
	for _, c := range m.containers {
		b.WriteString(TableCellStyle.Render(fmt.Sprintf("%-15s %-20s %-40s %-15s",
			truncate(c.Host, 15),
			truncate(c.Name, 20),
			truncate(c.ImageBase, 40),
			truncate(c.Tag, 15),
		)))
		b.WriteString("\n")
	}

	return b.String()
}

func (m Model) renderUpdatesTable() string {
	var b strings.Builder

	// Header
	b.WriteString(TableHeaderStyle.Render(fmt.Sprintf("%-15s %-20s %-15s %-15s", "HOST", "CONTAINER", "CURRENT", "LATEST")))
	b.WriteString("\n")
	b.WriteString(MutedStyle.Render(fmt.Sprintf("%-15s %-20s %-15s %-15s", "----", "---------", "-------", "------")))
	b.WriteString("\n")

	// Rows
	for _, r := range m.updateResults {
		b.WriteString(TableCellStyle.Render(fmt.Sprintf("%-15s %-20s %-15s %-15s",
			truncate(r.Container.Host, 15),
			truncate(r.Container.Name, 20),
			truncate(r.Container.Tag, 15),
			truncate(r.LatestTag, 15),
		)))
		b.WriteString("\n")
	}

	return b.String()
}

func (m Model) renderMainMenu() string {
	var b strings.Builder

	b.WriteString("\nWhat would you like to update?\n\n")

	choices := AllMenuChoices()
	for i, choice := range choices {
		cursor := "  "
		if i == m.menuCursor {
			cursor = CursorStyle.Render("> ")
		}
		b.WriteString(fmt.Sprintf("%s%s\n", cursor, choice.String()))
	}

	b.WriteString("\n")
	b.WriteString(HelpStyle.Render("↑/↓: navigate • enter: select • q: quit"))

	return b.String()
}

func (m Model) renderHostSelect() string {
	var b strings.Builder

	b.WriteString("\nSelect a host:\n\n")

	for i, host := range m.hosts {
		cursor := "  "
		if i == m.cursor {
			cursor = CursorStyle.Render("> ")
		}
		// Count updates for this host
		count := 0
		for _, r := range m.updateResults {
			if r.Container.Host == host {
				count++
			}
		}
		b.WriteString(fmt.Sprintf("%s%s (%d updates)\n", cursor, host, count))
	}

	b.WriteString("\n")
	b.WriteString(HelpStyle.Render("↑/↓: navigate • enter: select • esc: back • q: quit"))

	return b.String()
}

func (m Model) renderIndividualSelect() string {
	var b strings.Builder

	b.WriteString(HeaderStyle.Render("Select images to update"))
	b.WriteString("\n\n")

	for i, r := range m.updateResults {
		cursor := "  "
		if i == m.cursor {
			cursor = CursorStyle.Render("> ")
		}

		checkbox := "[ ]"
		if m.selected[r.Container.Key()] {
			checkbox = SuccessStyle.Render("[✓]")
		}

		line := fmt.Sprintf("%s/%s: %s → %s",
			r.Container.Host,
			r.Container.Name,
			r.Container.Tag,
			r.LatestTag,
		)

		b.WriteString(fmt.Sprintf("%s%s %s\n", cursor, checkbox, line))
	}

	// Count selected
	selectedCount := 0
	for _, v := range m.selected {
		if v {
			selectedCount++
		}
	}

	b.WriteString("\n")
	if selectedCount > 0 {
		b.WriteString(SuccessStyle.Render(fmt.Sprintf("%d selected", selectedCount)))
		b.WriteString("\n")
	}
	b.WriteString(HelpStyle.Render("↑/↓: navigate • space: toggle • enter: apply • esc: back"))

	return b.String()
}

func (m Model) renderConfirm() string {
	var b strings.Builder

	if m.selectedHost != "" {
		// Confirm for specific host
		count := 0
		for _, r := range m.updateResults {
			if r.Container.Host == m.selectedHost {
				count++
			}
		}
		b.WriteString(fmt.Sprintf("\nUpdate all %d images for %s? ", count, m.selectedHost))
	} else {
		// Confirm for all
		b.WriteString(fmt.Sprintf("\nUpdate all %d images? ", len(m.updateResults)))
	}

	b.WriteString(WarningStyle.Render("[y/n]"))

	return b.String()
}

func (m Model) renderApplying() string {
	return fmt.Sprintf("%s Applying updates...", m.spinner.View())
}

func (m Model) renderCommands() string {
	var b strings.Builder

	b.WriteString(HeaderStyle.Render("Update Commands"))
	b.WriteString("\n\n")

	for _, r := range m.updateResults {
		info := m.updater.GenerateUpdateInfo(r)
		b.WriteString(info)
		b.WriteString("\n---\n\n")
	}

	b.WriteString(HelpStyle.Render("Press enter or esc to go back"))

	return b.String()
}

func (m Model) renderDone() string {
	var b strings.Builder

	if len(m.applyResults) == 0 {
		if m.errorMsg != "" {
			b.WriteString(WarningStyle.Render(m.errorMsg))
		} else {
			b.WriteString(SuccessStyle.Render("All images are up to date!"))
		}
		b.WriteString("\n\n")
		b.WriteString(MutedStyle.Render("Press any key to exit"))
		return b.String()
	}

	// Count successes, failures, and skipped
	var success, failed, skipped int
	for _, r := range m.applyResults {
		if r.Skipped {
			skipped++
		} else if r.Success {
			success++
		} else {
			failed++
		}
	}

	b.WriteString(HeaderStyle.Render("Update Results"))
	b.WriteString("\n\n")

	for _, r := range m.applyResults {
		status := SuccessStyle.Render("✓")
		if r.Skipped {
			status = WarningStyle.Render("⊘")
		} else if !r.Success {
			status = ErrorStyle.Render("✗")
		}
		b.WriteString(fmt.Sprintf("%s %s/%s: %s\n", status, r.Container.Host, r.Container.Name, r.Message))
	}

	b.WriteString("\n")
	b.WriteString(BoldStyle.Render(fmt.Sprintf("Updated: %d", success)))
	if skipped > 0 {
		b.WriteString(WarningStyle.Render(fmt.Sprintf("  Skipped: %d", skipped)))
	}
	if failed > 0 {
		b.WriteString(ErrorStyle.Render(fmt.Sprintf("  Failed: %d", failed)))
	}
	b.WriteString("\n\n")
	b.WriteString(MutedStyle.Render("Press any key to exit"))

	return b.String()
}

func (m Model) renderError() string {
	return ErrorStyle.Render(fmt.Sprintf("Error: %s\n\nPress any key to exit", m.errorMsg))
}

// Helper functions

func (m Model) countUniqueHosts() int {
	hosts := make(map[string]bool)
	for _, c := range m.containers {
		hosts[c.Host] = true
	}
	return len(hosts)
}

func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen-3] + "..."
}
