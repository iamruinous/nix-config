package tui

import (
	"testing"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/iamruinous/docker-image-updater/internal/registry"
	"github.com/iamruinous/docker-image-updater/internal/scanner"
)

func TestNewModel(t *testing.T) {
	config := Config{
		ConfigPath: "/test/path",
		HostFilter: "testhost",
		Limit:      10,
		DryRun:     false,
	}

	model := NewModel(config)

	if model.config.ConfigPath != "/test/path" {
		t.Errorf("ConfigPath = %q, expected %q", model.config.ConfigPath, "/test/path")
	}
	if model.config.HostFilter != "testhost" {
		t.Errorf("HostFilter = %q, expected %q", model.config.HostFilter, "testhost")
	}
	if model.config.Limit != 10 {
		t.Errorf("Limit = %d, expected %d", model.config.Limit, 10)
	}
	if model.state != StateInitial {
		t.Errorf("Initial state = %v, expected %v", model.state, StateInitial)
	}
	if model.selected == nil {
		t.Error("selected map should be initialized")
	}
}

func TestModelUpdateScanComplete(t *testing.T) {
	config := Config{ConfigPath: "/test/path"}
	model := NewModel(config)

	// Simulate scan complete with containers
	containers := []scanner.Container{
		{Host: "host1", Name: "app1", Image: "app:1.0", Tag: "1.0"},
		{Host: "host1", Name: "app2", Image: "app:2.0", Tag: "2.0"},
	}

	msg := scanCompleteMsg{containers: containers}
	newModel, cmd := model.Update(msg)
	m := newModel.(Model)

	if m.state != StateChecking {
		t.Errorf("State after scan complete = %v, expected %v", m.state, StateChecking)
	}
	if len(m.containers) != 2 {
		t.Errorf("Containers count = %d, expected %d", len(m.containers), 2)
	}
	if m.checkTotal != 2 {
		t.Errorf("checkTotal = %d, expected %d", m.checkTotal, 2)
	}
	if cmd == nil {
		t.Error("Expected a command to be returned for checking")
	}

	// Verify check results were initialized
	if len(m.checkResults) != 2 {
		t.Errorf("checkResults count = %d, expected %d", len(m.checkResults), 2)
	}
	// First one should be checking, rest pending
	if m.checkResults[0].Status != CheckStatusChecking {
		t.Errorf("First check status = %v, expected %v", m.checkResults[0].Status, CheckStatusChecking)
	}
	if m.checkResults[1].Status != CheckStatusPending {
		t.Errorf("Second check status = %v, expected %v", m.checkResults[1].Status, CheckStatusPending)
	}
}

func TestModelUpdateScanCompleteWithLimit(t *testing.T) {
	config := Config{ConfigPath: "/test/path", Limit: 1}
	model := NewModel(config)

	containers := []scanner.Container{
		{Host: "host1", Name: "app1", Image: "app:1.0", Tag: "1.0"},
		{Host: "host1", Name: "app2", Image: "app:2.0", Tag: "2.0"},
	}

	msg := scanCompleteMsg{containers: containers}
	newModel, _ := model.Update(msg)
	m := newModel.(Model)

	if m.checkTotal != 1 {
		t.Errorf("checkTotal with limit = %d, expected %d", m.checkTotal, 1)
	}
}

func TestModelUpdateScanCompleteEmpty(t *testing.T) {
	config := Config{ConfigPath: "/test/path"}
	model := NewModel(config)

	msg := scanCompleteMsg{containers: []scanner.Container{}}
	newModel, _ := model.Update(msg)
	m := newModel.(Model)

	if m.state != StateDone {
		t.Errorf("State with empty containers = %v, expected %v", m.state, StateDone)
	}
	if m.errorMsg != "No containers found" {
		t.Errorf("errorMsg = %q, expected %q", m.errorMsg, "No containers found")
	}
}

func TestModelUpdateScanCompleteError(t *testing.T) {
	config := Config{ConfigPath: "/test/path"}
	model := NewModel(config)

	msg := scanCompleteMsg{err: errTest}
	newModel, _ := model.Update(msg)
	m := newModel.(Model)

	if m.state != StateError {
		t.Errorf("State with error = %v, expected %v", m.state, StateError)
	}
}

func TestModelUpdateScanCompleteDryRun(t *testing.T) {
	config := Config{ConfigPath: "/test/path", DryRun: true}
	model := NewModel(config)

	containers := []scanner.Container{
		{Host: "host1", Name: "app1", Image: "app:1.0", Tag: "1.0"},
	}

	msg := scanCompleteMsg{containers: containers}
	newModel, _ := model.Update(msg)
	m := newModel.(Model)

	if m.state != StateShowDryRun {
		t.Errorf("State in dry-run = %v, expected %v", m.state, StateShowDryRun)
	}
}

func TestModelUpdateCheckResult(t *testing.T) {
	config := Config{ConfigPath: "/test/path"}
	model := NewModel(config)

	// Setup model state
	model.state = StateChecking
	model.containers = []scanner.Container{
		{Host: "host1", Name: "app1", Image: "app:1.0", Tag: "1.0"},
		{Host: "host1", Name: "app2", Image: "app:2.0", Tag: "2.0"},
	}
	model.checkTotal = 2
	model.checkResults = []ContainerCheckResult{
		{Container: model.containers[0], Status: CheckStatusChecking},
		{Container: model.containers[1], Status: CheckStatusPending},
	}

	// Simulate first check result with update
	updateResult := &registry.UpdateResult{
		Container: model.containers[0],
		LatestTag: "1.1",
		HasUpdate: true,
	}

	msg := checkResultMsg{index: 0, result: updateResult}
	newModel, cmd := model.Update(msg)
	m := newModel.(Model)

	if len(m.updateResults) != 1 {
		t.Errorf("updateResults count = %d, expected %d", len(m.updateResults), 1)
	}
	if m.checkProgress != 1 {
		t.Errorf("checkProgress = %d, expected %d", m.checkProgress, 1)
	}
	if m.currentlyChecking != "app2" {
		t.Errorf("currentlyChecking = %q, expected %q", m.currentlyChecking, "app2")
	}
	if cmd == nil {
		t.Error("Expected a command to continue checking")
	}

	// Verify check results were updated
	if m.checkResults[0].Status != CheckStatusDone {
		t.Errorf("First check status = %v, expected %v", m.checkResults[0].Status, CheckStatusDone)
	}
	if m.checkResults[0].LatestTag != "1.1" {
		t.Errorf("First check latestTag = %q, expected %q", m.checkResults[0].LatestTag, "1.1")
	}
	if !m.checkResults[0].HasUpdate {
		t.Error("First check should have HasUpdate = true")
	}
	if m.checkResults[1].Status != CheckStatusChecking {
		t.Errorf("Second check status = %v, expected %v", m.checkResults[1].Status, CheckStatusChecking)
	}
}

func TestModelUpdateCheckResultNoUpdate(t *testing.T) {
	config := Config{ConfigPath: "/test/path"}
	model := NewModel(config)

	model.state = StateChecking
	model.containers = []scanner.Container{
		{Host: "host1", Name: "app1", Image: "app:1.0", Tag: "1.0"},
		{Host: "host1", Name: "app2", Image: "app:2.0", Tag: "2.0"},
	}
	model.checkTotal = 2
	model.checkResults = []ContainerCheckResult{
		{Container: model.containers[0], Status: CheckStatusChecking},
		{Container: model.containers[1], Status: CheckStatusPending},
	}

	// Result without update
	updateResult := &registry.UpdateResult{
		Container: model.containers[0],
		LatestTag: "1.0",
		HasUpdate: false,
	}

	msg := checkResultMsg{index: 0, result: updateResult}
	newModel, _ := model.Update(msg)
	m := newModel.(Model)

	if len(m.updateResults) != 0 {
		t.Errorf("updateResults should be empty when no update, got %d", len(m.updateResults))
	}

	// Check results should still be updated
	if m.checkResults[0].Status != CheckStatusDone {
		t.Errorf("Check status = %v, expected %v", m.checkResults[0].Status, CheckStatusDone)
	}
	if m.checkResults[0].HasUpdate {
		t.Error("Check should have HasUpdate = false")
	}
}

func TestModelUpdateCheckResultLastOne(t *testing.T) {
	config := Config{ConfigPath: "/test/path"}
	model := NewModel(config)

	model.state = StateChecking
	model.containers = []scanner.Container{
		{Host: "host1", Name: "app1", Image: "app:1.0", Tag: "1.0"},
	}
	model.checkTotal = 1
	model.checkResults = []ContainerCheckResult{
		{Container: model.containers[0], Status: CheckStatusChecking},
	}

	updateResult := &registry.UpdateResult{
		Container: model.containers[0],
		LatestTag: "1.0",
		HasUpdate: false,
	}

	msg := checkResultMsg{index: 0, result: updateResult}
	newModel, cmd := model.Update(msg)
	m := newModel.(Model)

	if m.checkProgress != 1 {
		t.Errorf("checkProgress = %d, expected %d", m.checkProgress, 1)
	}
	// Command should return checkCompleteMsg
	if cmd == nil {
		t.Error("Expected a command to signal completion")
	}

	// Check result should be marked done
	if m.checkResults[0].Status != CheckStatusDone {
		t.Errorf("Check status = %v, expected %v", m.checkResults[0].Status, CheckStatusDone)
	}
}

func TestModelUpdateCheckComplete(t *testing.T) {
	config := Config{ConfigPath: "/test/path"}
	model := NewModel(config)

	model.state = StateChecking
	model.updateResults = []registry.UpdateResult{
		{
			Container: scanner.Container{Host: "host1", Name: "app1"},
			LatestTag: "1.1",
			HasUpdate: true,
		},
	}

	msg := checkCompleteMsg{}
	newModel, _ := model.Update(msg)
	m := newModel.(Model)

	if m.state != StateShowUpdates {
		t.Errorf("State after check complete = %v, expected %v", m.state, StateShowUpdates)
	}
	if len(m.hosts) != 1 {
		t.Errorf("hosts count = %d, expected %d", len(m.hosts), 1)
	}
}

func TestModelUpdateCheckCompleteNoUpdates(t *testing.T) {
	config := Config{ConfigPath: "/test/path"}
	model := NewModel(config)

	model.state = StateChecking
	model.updateResults = []registry.UpdateResult{}

	msg := checkCompleteMsg{}
	newModel, _ := model.Update(msg)
	m := newModel.(Model)

	if m.state != StateDone {
		t.Errorf("State with no updates = %v, expected %v", m.state, StateDone)
	}
}

func TestModelBuildHostsList(t *testing.T) {
	model := Model{
		updateResults: []registry.UpdateResult{
			{Container: scanner.Container{Host: "host1", Name: "app1"}},
			{Container: scanner.Container{Host: "host1", Name: "app2"}},
			{Container: scanner.Container{Host: "host2", Name: "app3"}},
		},
	}

	model.buildHostsList()

	if len(model.hosts) != 2 {
		t.Errorf("hosts count = %d, expected %d", len(model.hosts), 2)
	}
}

func TestModelHandleMainMenuKey(t *testing.T) {
	model := Model{state: StateMainMenu, menuCursor: 0}

	// Test down navigation
	msg := tea.KeyMsg{Type: tea.KeyDown}
	newModel, _ := model.handleMainMenuKey(msg)
	m := newModel.(Model)
	if m.menuCursor != 1 {
		t.Errorf("menuCursor after down = %d, expected %d", m.menuCursor, 1)
	}

	// Test up navigation
	msg = tea.KeyMsg{Type: tea.KeyUp}
	newModel, _ = m.handleMainMenuKey(msg)
	m = newModel.(Model)
	if m.menuCursor != 0 {
		t.Errorf("menuCursor after up = %d, expected %d", m.menuCursor, 0)
	}
}

func TestModelHandleQuit(t *testing.T) {
	model := Model{state: StateMainMenu}

	msg := tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'q'}}
	_, cmd := model.handleMainMenuKey(msg)

	// Should return tea.Quit
	if cmd == nil {
		t.Error("Expected quit command")
	}
}

func TestModelWindowSizeMsg(t *testing.T) {
	model := NewModel(Config{ConfigPath: "/test"})

	msg := tea.WindowSizeMsg{Width: 120, Height: 40}
	newModel, _ := model.Update(msg)
	m := newModel.(Model)

	if m.width != 120 {
		t.Errorf("width = %d, expected %d", m.width, 120)
	}
	if m.height != 40 {
		t.Errorf("height = %d, expected %d", m.height, 40)
	}
}

// Test error type for tests
type testError struct{}

func (e testError) Error() string { return "test error" }

var errTest = testError{}

func TestCheckStatusConstants(t *testing.T) {
	// Ensure constants have expected values
	if CheckStatusPending != 0 {
		t.Errorf("CheckStatusPending = %d, expected 0", CheckStatusPending)
	}
	if CheckStatusChecking != 1 {
		t.Errorf("CheckStatusChecking = %d, expected 1", CheckStatusChecking)
	}
	if CheckStatusDone != 2 {
		t.Errorf("CheckStatusDone = %d, expected 2", CheckStatusDone)
	}
	if CheckStatusError != 3 {
		t.Errorf("CheckStatusError = %d, expected 3", CheckStatusError)
	}
}

func TestContainerCheckResult(t *testing.T) {
	container := scanner.Container{
		Host: "host1",
		Name: "app1",
		Tag:  "1.0",
	}

	result := ContainerCheckResult{
		Container: container,
		Status:    CheckStatusDone,
		LatestTag: "1.1",
		HasUpdate: true,
	}

	if result.Container.Host != "host1" {
		t.Errorf("Container.Host = %q, expected %q", result.Container.Host, "host1")
	}
	if result.Status != CheckStatusDone {
		t.Errorf("Status = %v, expected %v", result.Status, CheckStatusDone)
	}
	if result.LatestTag != "1.1" {
		t.Errorf("LatestTag = %q, expected %q", result.LatestTag, "1.1")
	}
	if !result.HasUpdate {
		t.Error("HasUpdate should be true")
	}
}

func TestModelCheckResultError(t *testing.T) {
	config := Config{ConfigPath: "/test/path"}
	model := NewModel(config)

	model.state = StateChecking
	model.containers = []scanner.Container{
		{Host: "host1", Name: "app1", Image: "app:1.0", Tag: "1.0"},
	}
	model.checkTotal = 1
	model.checkResults = []ContainerCheckResult{
		{Container: model.containers[0], Status: CheckStatusChecking},
	}

	// Simulate error in check
	msg := checkResultMsg{index: 0, err: errTest}
	newModel, _ := model.Update(msg)
	m := newModel.(Model)

	if m.checkResults[0].Status != CheckStatusError {
		t.Errorf("Check status = %v, expected %v", m.checkResults[0].Status, CheckStatusError)
	}
	if m.checkResults[0].Error == nil {
		t.Error("Check error should not be nil")
	}
}
