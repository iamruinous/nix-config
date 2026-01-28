# Tart VM configuration for jpex
#
# jpex: Mac mini M4 - 10 cores, 24GB RAM, macOS
# Purpose: Test Tart VMs for clawdbot deployment (Issue #314)
#
# VM Setup Steps:
#   1. Clone base macOS image: tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest clawdbot
#   2. Configure VM resources: tart set clawdbot --cpu 4 --memory 8192
#   3. Start VM for initial setup: tart run clawdbot
#   4. Complete macOS setup wizard, sign into Apple ID
#   5. Test iMessage functionality (critical blocker for Issue #314)
#
{
  ruinous.tart-vm = {
    enable = true;

    vms.clawdbot = {
      enable = true;
      cpu = 4;
      memory = 8192; # 8GB RAM for clawdbot VM
      display = "1920x1080";
      autostart = false; # Don't autostart until iMessage is validated
      headless = false; # Need GUI for initial setup and iMessage testing
      sharedDirs = [
        "/Users/jmeskill/shared/clawdbot" # Shared data directory
      ];
    };
  };
}
