.PHONY: update-flake bootstrap-mac install-nix install-nix-darwin darwin-rebuild remote-rebuild remote-dry-build refresh-readme restore-readme pi-sdimage pi-flash check

# Colors and styles
HEADER = gum style --foreground 212 --bold
INFO = gum log --level info
WARN = gum log --level warn
ERROR = gum log --level error
SUCCESS = gum log --level info --prefix "✓"

update-flake:
	@$(HEADER) "🔄 Update Flake"
	@gum spin --spinner dot --title "Updating flake inputs..." -- nix flake update
	@$(SUCCESS) "Flake update complete"

install-nix:
	@$(HEADER) "📦 Install Nix"
	@$(INFO) "Installing Nix package manager..."
	@sudo curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
	@$(SUCCESS) "Nix installation complete"

install-nix-darwin:
	@$(HEADER) "🍎 Install nix-darwin"
	@$(INFO) "Installing nix-darwin for $$(hostname)..."
	@nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake .#$$(hostname)
	@$(SUCCESS) "nix-darwin installation complete"

darwin-rebuild:
	@$(HEADER) "🍎 Darwin Rebuild"
	@$(INFO) "Rebuilding darwin configuration for $$(hostname)..."
	@darwin-rebuild switch --flake .#$$(hostname)
	@$(SUCCESS) "Darwin rebuild complete"

remote-rebuild:
	@if [ -z "$(remotehost)" ]; then $(ERROR) "remotehost is required (e.g., make remote-rebuild remotehost=monolith)"; exit 1; fi
	@$(HEADER) "🖥️  Remote Rebuild"
	@$(INFO) "Rebuilding $(remotehost).meskill.farm..."
	@nixos-rebuild --sudo --target-host $(remotehost).meskill.farm switch --flake .#$(remotehost) --accept-flake-config
	@$(SUCCESS) "Remote rebuild complete for $(remotehost)"

remote-dry-build:
	@if [ -z "$(remotehost)" ]; then $(ERROR) "remotehost is required (e.g., make remote-dry-build remotehost=monolith)"; exit 1; fi
	@$(HEADER) "🧪 Remote Dry Build"
	@$(INFO) "Dry-building configuration for $(remotehost)..."
	@nixos-rebuild dry-build --flake .#$(remotehost)
	@$(SUCCESS) "Dry-build complete for $(remotehost)"

refresh-readme:
	@$(HEADER) "📄 Refresh README"
	@$(INFO) "Pulling latest README.md from remote..."
	@gum spin --spinner dot --title "Fetching from origin..." -- git fetch origin
	@git checkout origin/main -- README.md
	@$(SUCCESS) "README.md refreshed from remote repository"

restore-readme:
	@$(HEADER) "📄 Restore README"
	@$(INFO) "Restoring README.md from current commit..."
	@git restore README.md
	@$(SUCCESS) "README.md restored from current commit"

bootstrap-mac: install-nix install-nix-darwin

pi-sdimage:
	@if [ -z "$(pihost)" ]; then $(ERROR) "pihost is required (e.g., make pi-sdimage pihost=rpc-5-alpha)"; exit 1; fi
	@$(HEADER) "🥧 Build Raspberry Pi SD Image"
	@$(INFO) "Building SD image for $(pihost) on armistice..."
	@nix build .#nixosConfigurations.$(pihost).config.system.build.sdImage \
		--builders "ssh://armistice.meskill.farm aarch64-linux - 12 1 benchmark,big-parallel,kvm" \
		--max-jobs 0 \
		--cores 0 \
		--log-format bar-with-logs \
		-o result-$(pihost)-sdimage
	@$(SUCCESS) "SD image built: result-$(pihost)-sdimage/"
	@echo ""
	@gum style --foreground 229 "To flash to SD card:"
	@gum style --foreground 245 "  make pi-flash pihost=$(pihost) device=/dev/sdX"

pi-flash:
	@if [ -z "$(pihost)" ]; then $(ERROR) "pihost is required (e.g., make pi-flash pihost=rpc-5-alpha device=/dev/sda)"; exit 1; fi
	@if [ -z "$(device)" ]; then $(ERROR) "device is required (e.g., make pi-flash pihost=rpc-5-alpha device=/dev/sda)"; exit 1; fi
	@if [ ! -d "result-$(pihost)-sdimage" ]; then $(ERROR) "result-$(pihost)-sdimage not found. Run 'make pi-sdimage pihost=$(pihost)' first."; exit 1; fi
	@if [ ! -b "$(device)" ]; then $(ERROR) "$(device) is not a block device"; exit 1; fi
	@$(HEADER) "🥧 Flash Raspberry Pi SD Card"
	@$(WARN) "This will erase all data on $(device)!"
	@gum confirm "Flash $(pihost) image to $(device)?" || exit 1
	@$(INFO) "Decompressing image..."
	@gum spin --spinner dot --title "Decompressing $(pihost) image..." -- zstd -d -f result-$(pihost)-sdimage/sd-image/*.img.zst -o /tmp/$(pihost).img
	@$(INFO) "Flashing to $(device)..."
	@sudo bmaptool copy --nobmap /tmp/$(pihost).img $(device)
	@sync
	@rm -f /tmp/$(pihost).img
	@$(SUCCESS) "Flash complete! You can safely remove $(device)."


# Sanity check - dry-build representative hosts from each category
# Tests: NixOS desktop, NixOS server, Darwin, and Raspberry Pi
check:
	@$(HEADER) "🧪 Sanity Check - Dry Build Representative Hosts"
	@$(INFO) "Testing NixOS desktop (chassis)..."
	@nix build .#nixosConfigurations.chassis.config.system.build.toplevel --dry-run 2>/dev/null
	@$(INFO) "Testing NixOS laptop (framework)..."
	@nix build .#nixosConfigurations.framework.config.system.build.toplevel --dry-run 2>/dev/null
	@$(SUCCESS) "framework (NixOS desktop) OK"
	@$(INFO) "Testing NixOS server (monolith)..."
	@nix build .#nixosConfigurations.monolith.config.system.build.toplevel --dry-run 2>/dev/null
	@$(SUCCESS) "monolith (NixOS server) OK"
	@$(INFO) "Testing Darwin (jbookpro)..."
	@nix build .#darwinConfigurations.jbookpro.system --dry-run 2>/dev/null
	@$(SUCCESS) "jbookpro (Darwin) OK"
	@$(INFO) "Testing Raspberry Pi 5 (rp500)..."
	@nix build .#nixosConfigurations.rp500.config.system.build.toplevel --dry-run 2>/dev/null
	@$(SUCCESS) "rp500 (Raspberry Pi 5) OK"
	@$(INFO) "Testing Raspberry Pi 4 (rpc-4-echo)..."
	@nix build .#nixosConfigurations.rpc-4-echo.config.system.build.toplevel --dry-run 2>/dev/null
	@$(SUCCESS) "rpc-4-echo (Raspberry Pi 4) OK"
	@echo ""
	@gum style --foreground 82 --bold "✓ All sanity checks passed!"
