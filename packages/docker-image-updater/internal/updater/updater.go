// Package updater handles applying image updates to NixOS configuration files.
package updater

import (
	"fmt"
	"os/exec"
	"regexp"
	"strings"

	"github.com/iamruinous/docker-image-updater/internal/registry"
	"github.com/iamruinous/docker-image-updater/internal/scanner"
)

// ApplyResult represents the result of applying an update.
type ApplyResult struct {
	Container scanner.Container
	Success   bool
	Message   string
	Skipped   bool // True if skipped (e.g., floating tag)
}

// Updater handles applying updates to NixOS configuration files.
type Updater struct {
	configPath string
}

// NewUpdater creates a new Updater.
func NewUpdater(configPath string) *Updater {
	return &Updater{configPath: configPath}
}

// GenerateCommand returns the sed command to apply an update.
func (u *Updater) GenerateCommand(result registry.UpdateResult) string {
	container := result.Container
	newImage := u.buildNewImageRef(result)

	if newImage == container.Image {
		return ""
	}

	// Escape special regex characters for sed
	escapedCurrent := escapeSedPattern(container.Image)
	escapedNew := escapeSedReplacement(newImage)

	return fmt.Sprintf("sed -i 's|%s|%s|g' %s", escapedCurrent, escapedNew, container.FilePath)
}

// GenerateUpdateInfo returns a formatted string with update information.
func (u *Updater) GenerateUpdateInfo(result registry.UpdateResult) string {
	container := result.Container
	newImage := u.buildNewImageRef(result)

	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Host: %s\n", container.Host))
	sb.WriteString(fmt.Sprintf("Container: %s\n", container.Name))
	sb.WriteString(fmt.Sprintf("Current: %s\n", container.Image))
	sb.WriteString(fmt.Sprintf("New: %s\n", newImage))
	sb.WriteString(fmt.Sprintf("File: %s\n", container.FilePath))
	sb.WriteString("\n")
	sb.WriteString("To update manually:\n")
	sb.WriteString(fmt.Sprintf("  %s\n", u.GenerateCommand(result)))

	return sb.String()
}

// Apply applies an update to a container's configuration file.
func (u *Updater) Apply(result registry.UpdateResult) ApplyResult {
	container := result.Container

	// Can't update file for digest-only changes
	if result.IsDigestOnly {
		return ApplyResult{
			Container: container,
			Success:   false,
			Skipped:   true,
			Message:   "floating tag, pull to update",
		}
	}

	newImage := u.buildNewImageRef(result)
	if newImage == container.Image {
		return ApplyResult{
			Container: container,
			Success:   false,
			Skipped:   true,
			Message:   "no change needed",
		}
	}

	// Use sed to replace the image in the file
	cmd := exec.Command("sed", "-i", fmt.Sprintf("s|%s|%s|g", container.Image, newImage), container.FilePath)
	if err := cmd.Run(); err != nil {
		return ApplyResult{
			Container: container,
			Success:   false,
			Message:   fmt.Sprintf("sed failed: %v", err),
		}
	}

	return ApplyResult{
		Container: container,
		Success:   true,
		Message:   fmt.Sprintf("%s -> %s", container.Tag, result.LatestTag),
	}
}

// buildNewImageRef constructs the new image reference with the updated tag.
func (u *Updater) buildNewImageRef(result registry.UpdateResult) string {
	container := result.Container

	if result.IsDigestOnly {
		// Keep same tag for digest-only updates
		return container.Image
	}

	imageBase := container.ImageBase
	if imageBase == "" {
		imageBase = extractImageBase(container.Image)
	}

	return imageBase + ":" + result.LatestTag
}

// extractImageBase extracts the image reference without the tag.
func extractImageBase(image string) string {
	// Handle images with digest (@sha256:...)
	if idx := strings.Index(image, "@"); idx != -1 {
		image = image[:idx]
	}

	if idx := strings.LastIndex(image, ":"); idx != -1 {
		// Make sure it's not part of a port number
		remainder := image[idx+1:]
		if !strings.Contains(remainder, "/") {
			return image[:idx]
		}
	}
	return image
}

// escapeSedPattern escapes special characters for use in sed pattern.
func escapeSedPattern(s string) string {
	// Characters that need escaping in sed basic regex: . * ^ $ [ ] \
	special := regexp.MustCompile(`([.*^$\[\]\\])`)
	return special.ReplaceAllString(s, `\$1`)
}

// escapeSedReplacement escapes special characters for use in sed replacement.
func escapeSedReplacement(s string) string {
	// Characters that need escaping in sed replacement: & \ /
	s = strings.ReplaceAll(s, `\`, `\\`)
	s = strings.ReplaceAll(s, `&`, `\&`)
	s = strings.ReplaceAll(s, `/`, `\/`)
	return s
}
