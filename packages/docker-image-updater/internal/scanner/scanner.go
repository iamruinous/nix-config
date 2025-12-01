// Package scanner discovers and parses container definitions from NixOS configuration files.
package scanner

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// Container represents a discovered container definition from a NixOS configuration.
type Container struct {
	Host      string // Host directory name (e.g., "monolith")
	Name      string // Container name from Nix config
	Image     string // Full image reference (e.g., "docker.io/postgres:17")
	Tag       string // Extracted tag
	ImageBase string // Image without tag
	FilePath  string // Path to containers.nix file
}

// Key returns a unique identifier for this container in the format "host:container".
func (c Container) Key() string {
	return c.Host + ":" + c.Name
}

// Scanner discovers and parses container definitions from NixOS configuration files.
type Scanner struct {
	configPath string
}

// NewScanner creates a new Scanner for the given nix-config directory.
func NewScanner(configPath string) *Scanner {
	return &Scanner{configPath: configPath}
}

// Scan discovers all containers, optionally filtering by host.
// Returns a slice of Container structs or an error.
func (s *Scanner) Scan(hostFilter string) ([]Container, error) {
	var containerFiles []string

	if hostFilter != "" {
		// Only scan the specified host
		hostFile := filepath.Join(s.configPath, "hosts", hostFilter, "containers.nix")
		if _, err := os.Stat(hostFile); os.IsNotExist(err) {
			// List available hosts for error message
			hosts, _ := s.listAvailableHosts()
			return nil, fmt.Errorf("no containers.nix found for host: %s\nAvailable hosts: %s", hostFilter, strings.Join(hosts, ", "))
		}
		containerFiles = []string{hostFile}
	} else {
		// Find all containers.nix files under hosts/
		hostsDir := filepath.Join(s.configPath, "hosts")
		entries, err := os.ReadDir(hostsDir)
		if err != nil {
			return nil, fmt.Errorf("failed to read hosts directory: %w", err)
		}

		for _, entry := range entries {
			if entry.IsDir() {
				containerFile := filepath.Join(hostsDir, entry.Name(), "containers.nix")
				if _, err := os.Stat(containerFile); err == nil {
					containerFiles = append(containerFiles, containerFile)
				}
			}
		}
	}

	if len(containerFiles) == 0 {
		return nil, nil
	}

	var containers []Container
	for _, file := range containerFiles {
		parsed, err := s.parseContainerFile(file)
		if err != nil {
			// Log warning but continue with other files
			fmt.Fprintf(os.Stderr, "Warning: failed to parse %s: %v\n", file, err)
			continue
		}
		containers = append(containers, parsed...)
	}

	return containers, nil
}

// listAvailableHosts returns a list of hosts that have containers.nix files.
func (s *Scanner) listAvailableHosts() ([]string, error) {
	hostsDir := filepath.Join(s.configPath, "hosts")
	entries, err := os.ReadDir(hostsDir)
	if err != nil {
		return nil, err
	}

	var hosts []string
	for _, entry := range entries {
		if entry.IsDir() {
			containerFile := filepath.Join(hostsDir, entry.Name(), "containers.nix")
			if _, err := os.Stat(containerFile); err == nil {
				hosts = append(hosts, entry.Name())
			}
		}
	}
	return hosts, nil
}

// parseContainerFile parses a single containers.nix file and extracts container definitions.
// This implements a state machine similar to the AWK logic in the shell script.
func (s *Scanner) parseContainerFile(filePath string) ([]Container, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// Extract host name from file path
	hostName := filepath.Base(filepath.Dir(filePath))

	var containers []Container
	scanner := bufio.NewScanner(file)

	// State machine variables
	inContainers := false
	depth := 0
	currentContainer := ""
	containerDepth := 0

	// Regex patterns
	containersStartRe := regexp.MustCompile(`^\s*containers\s*=\s*\{`)
	containersEndRe := regexp.MustCompile(`^\s*\};\s*$`)
	containerDefRe := regexp.MustCompile(`^\s*(["]?[a-zA-Z0-9_-]+["]?)\s*=\s*\{`)
	imageDefRe := regexp.MustCompile(`image\s*=\s*"([^"]+)"`)

	for scanner.Scan() {
		line := scanner.Text()

		// Check for containers block start
		if !inContainers && containersStartRe.MatchString(line) {
			inContainers = true
			depth = 1 // We're inside the containers block
			continue
		}

		if !inContainers {
			continue
		}

		// Count braces to track depth
		openBraces := strings.Count(line, "{")
		closeBraces := strings.Count(line, "}")
		depth += openBraces - closeBraces

		// Check for end of containers block
		if depth <= 0 && containersEndRe.MatchString(line) {
			inContainers = false
			continue
		}

		// Look for container definition start: name = {
		if matches := containerDefRe.FindStringSubmatch(line); matches != nil {
			currentContainer = strings.Trim(matches[1], "\"")
			containerDepth = depth
		}

		// Look for image definition within a container block
		if currentContainer != "" {
			if matches := imageDefRe.FindStringSubmatch(line); matches != nil {
				image := matches[1]
				tag := extractTag(image)
				imageBase := extractImageBase(image)

				containers = append(containers, Container{
					Host:      hostName,
					Name:      currentContainer,
					Image:     image,
					Tag:       tag,
					ImageBase: imageBase,
					FilePath:  filePath,
				})
				currentContainer = ""
			}
		}

		// Reset container context when we exit the container's block
		if currentContainer != "" && depth < containerDepth {
			currentContainer = ""
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return containers, nil
}

// extractTag extracts the tag from an image reference.
// If no tag is specified, returns "latest".
func extractTag(image string) string {
	// Handle images with digest (@sha256:...)
	if idx := strings.Index(image, "@"); idx != -1 {
		image = image[:idx]
	}

	if idx := strings.LastIndex(image, ":"); idx != -1 {
		// Make sure it's not part of a port number (check if there's a / after the :)
		remainder := image[idx+1:]
		if !strings.Contains(remainder, "/") {
			return remainder
		}
	}
	return "latest"
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

// NormalizeImage converts an image reference to its fully qualified form.
// - "nginx" -> "docker.io/library/nginx"
// - "user/repo" -> "docker.io/user/repo"
// - "ghcr.io/org/repo" -> "ghcr.io/org/repo" (unchanged)
func NormalizeImage(image string) string {
	// Strip tag for analysis
	imageBase := extractImageBase(image)
	tag := extractTag(image)

	// Already has registry (contains dots before first slash, or has multiple slashes)
	if strings.Contains(imageBase, "/") {
		parts := strings.SplitN(imageBase, "/", 2)
		// If first part contains a dot or colon, it's a registry
		if strings.Contains(parts[0], ".") || strings.Contains(parts[0], ":") {
			return image
		}
		// Docker Hub user image
		result := "docker.io/" + imageBase
		if tag != "latest" {
			result += ":" + tag
		} else if strings.Contains(image, ":") {
			result += ":" + tag
		}
		return result
	}

	// Docker Hub official image (no slash)
	result := "docker.io/library/" + imageBase
	if tag != "latest" {
		result += ":" + tag
	} else if strings.Contains(image, ":") {
		result += ":" + tag
	}
	return result
}
