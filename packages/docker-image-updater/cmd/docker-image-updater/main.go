// Package main is the entry point for docker-image-updater.
package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	flag "github.com/spf13/pflag"
	"golang.org/x/term"

	"github.com/iamruinous/docker-image-updater/internal/cache"
	"github.com/iamruinous/docker-image-updater/internal/registry"
	"github.com/iamruinous/docker-image-updater/internal/scanner"
	"github.com/iamruinous/docker-image-updater/internal/tui"
	"github.com/iamruinous/docker-image-updater/internal/updater"
)

var version = "2.1.0"

func main() {
	// Command line flags
	var (
		configPath     string
		hostFilter     string
		limit          int
		nonInteractive bool
		dryRun         bool
		clearCache     bool
		noCache        bool
		showVersion    bool
		showHelp       bool
	)

	flag.StringVarP(&configPath, "path", "p", "", "Path to nix-config directory (default: current directory)")
	flag.StringVarP(&hostFilter, "host", "H", "", "Only check containers for a specific host")
	flag.IntVarP(&limit, "limit", "l", 0, "Limit the number of containers to check")
	flag.BoolVar(&nonInteractive, "non-interactive", false, "Run in non-interactive mode (just show updates)")
	flag.BoolVar(&dryRun, "dry-run", false, "Only scan containers, skip checking for updates")
	flag.BoolVar(&clearCache, "clear-cache", false, "Clear the cache before running")
	flag.BoolVar(&noCache, "no-cache", false, "Disable caching for this run")
	flag.BoolVarP(&showVersion, "version", "v", false, "Show version")
	flag.BoolVarP(&showHelp, "help", "h", false, "Show help")

	flag.Parse()

	if showHelp {
		printHelp()
		os.Exit(0)
	}

	if showVersion {
		fmt.Printf("docker-image-updater v%s\n", version)
		os.Exit(0)
	}

	// Handle cache clearing
	if clearCache {
		c := cache.New("", cache.DefaultTTL)
		if err := c.Clear(); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: Failed to clear cache: %v\n", err)
		} else {
			fmt.Println("Cache cleared")
		}
	}

	// Determine config path
	if configPath == "" {
		configPath = os.Getenv("NIX_CONFIG_PATH")
	}
	if configPath == "" {
		var err error
		configPath, err = os.Getwd()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	}

	// Verify config path exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "Error: Config path does not exist: %s\n", configPath)
		os.Exit(1)
	}

	// Check if we should run in interactive mode
	isTerminal := term.IsTerminal(int(os.Stdin.Fd()))

	if nonInteractive || !isTerminal {
		// Run in batch/non-interactive mode
		runBatch(configPath, hostFilter, limit, dryRun, noCache)
	} else {
		// Run interactive TUI
		runInteractive(configPath, hostFilter, limit, dryRun, noCache)
	}
}

func printHelp() {
	fmt.Println(`docker-image-updater - Check for Docker image updates in NixOS configurations

Usage: docker-image-updater [OPTIONS]

Options:
    -p, --path PATH     Path to nix-config directory (default: current directory)
    -H, --host HOST     Only check containers for a specific host
    -l, --limit N       Limit the number of containers to check
    -h, --help          Show this help message
    -v, --version       Show version
    --non-interactive   Run in non-interactive mode (just show updates)
    --dry-run           Only scan containers, skip checking for updates
    --clear-cache       Clear the cache before running
    --no-cache          Disable caching for this run

Cache:
    Results are cached for 24 hours to speed up repeated checks.
    Cache location: ~/.local/state/docker-image-updater/

Environment Variables:
    NIX_CONFIG_PATH     Alternative way to set the config path

Examples:
    docker-image-updater
    docker-image-updater --path /path/to/nix-config
    docker-image-updater --host monolith
    docker-image-updater --limit 10
    docker-image-updater --host monolith --limit 5
    docker-image-updater --non-interactive
    docker-image-updater --dry-run
    docker-image-updater --clear-cache
    docker-image-updater --no-cache`)
}

func runInteractive(configPath, hostFilter string, limit int, dryRun bool, noCache bool) {
	config := tui.Config{
		ConfigPath: configPath,
		HostFilter: hostFilter,
		Limit:      limit,
		DryRun:     dryRun,
		NoCache:    noCache,
	}

	model := tui.NewModel(config)
	p := tea.NewProgram(model)

	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func runBatch(configPath, hostFilter string, limit int, dryRun bool, noCache bool) {
	// Print title
	fmt.Println("=== Docker Image Updater ===")
	fmt.Println("    for NixOS Configurations")
	fmt.Println()

	// Scan containers
	s := scanner.NewScanner(configPath)
	containers, err := s.Scan(hostFilter)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	if len(containers) == 0 {
		fmt.Println("No containers found")
		return
	}

	hostMsg := ""
	if hostFilter != "" {
		hostMsg = fmt.Sprintf(" for host '%s'", hostFilter)
	} else {
		hosts := make(map[string]bool)
		for _, c := range containers {
			hosts[c.Host] = true
		}
		hostMsg = fmt.Sprintf(" across %d hosts", len(hosts))
	}
	fmt.Printf("Found %d containers%s\n", len(containers), hostMsg)

	// Dry run mode - just show containers
	if dryRun {
		fmt.Println()
		fmt.Println("=== Discovered Containers ===")
		fmt.Println()
		fmt.Printf("%-15s %-20s %-40s %-15s\n", "HOST", "CONTAINER", "IMAGE", "TAG")
		fmt.Printf("%-15s %-20s %-40s %-15s\n", "----", "---------", "-----", "---")

		for _, c := range containers {
			fmt.Printf("%-15s %-20s %-40s %-15s\n",
				truncate(c.Host, 15),
				truncate(c.Name, 20),
				truncate(c.ImageBase, 40),
				truncate(c.Tag, 15),
			)
		}
		return
	}

	// Check for updates
	fmt.Println()
	fmt.Println("Checking for updates...")

	// Setup checker with cache
	var checker *registry.Checker
	if noCache {
		checker = registry.NewChecker("")
	} else {
		c := cache.New("", cache.DefaultTTL)
		if err := c.Load(); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: Failed to load cache: %v\n", err)
		}
		checker = registry.NewCheckerWithCache("", c)
	}

	var updateResults []registry.UpdateResult
	cacheHits := 0

	total := len(containers)
	if limit > 0 && limit < total {
		total = limit
		fmt.Printf("Limiting check to %d of %d containers\n", limit, len(containers))
	}

	for i, container := range containers {
		if limit > 0 && i >= limit {
			break
		}

		fmt.Printf("\r[%d/%d] Checking %s/%s...                    ", i+1, total, container.Host, container.Name)

		// Check if result was from cache
		wasCached := false
		if checker.Cache() != nil {
			_, wasCached = checker.Cache().Get(container.Image)
		}

		result := checker.CheckForUpdate(container)
		if wasCached {
			cacheHits++
		}
		if result.HasUpdate {
			updateResults = append(updateResults, *result)
		}
	}

	// Save cache
	if err := checker.SaveCache(); err != nil {
		fmt.Fprintf(os.Stderr, "\nWarning: Failed to save cache: %v\n", err)
	}

	fmt.Printf("\r%-80s\r", "") // Clear line

	if len(updateResults) == 0 {
		fmt.Printf("All %d checked images are up to date!", total)
		if cacheHits > 0 {
			fmt.Printf(" (%d from cache)", cacheHits)
		}
		fmt.Println()
		return
	}

	fmt.Printf("Found %d available updates (checked %d containers", len(updateResults), total)
	if cacheHits > 0 {
		fmt.Printf(", %d from cache", cacheHits)
	}
	fmt.Println(")")
	fmt.Println()

	// Display updates table
	fmt.Println("=== Available Updates ===")
	fmt.Println()
	fmt.Printf("%-15s %-20s %-15s %-15s\n", "HOST", "CONTAINER", "CURRENT", "LATEST")
	fmt.Printf("%-15s %-20s %-15s %-15s\n", "----", "---------", "-------", "------")

	for _, r := range updateResults {
		fmt.Printf("%-15s %-20s %-15s %-15s\n",
			truncate(r.Container.Host, 15),
			truncate(r.Container.Name, 20),
			truncate(r.Container.Tag, 15),
			truncate(r.LatestTag, 15),
		)
	}

	// Show commands
	fmt.Println()
	fmt.Println("=== Update Commands ===")
	fmt.Println()

	u := updater.NewUpdater(configPath)
	for _, r := range updateResults {
		info := u.GenerateUpdateInfo(r)
		fmt.Println(info)
		fmt.Println("---")
		fmt.Println()
	}
}

func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen-3] + "..."
}
