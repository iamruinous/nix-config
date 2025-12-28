.PHONY: update-flake bootstrap-mac install-nix install-nix-darwin darwin-rebuild remote-rebuild remote-dry-build refresh-readme restore-readme pi-sdimage pi-flash

update-flake:
	@echo "Updating flake..."
	@nix flake update
	@echo "Nix flake update complete."

install-nix:
	@echo "Installing Nix..."
	@sudo curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
	@echo "Nix installation complete."

install-nix-darwin:
	@echo "Installing nix-darwin..."
	@nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake .#$(hostname)
	@echo "nix-darwin installation complete."

darwin-rebuild:
	@echo "Rebuilding darwin configuration..."
	@darwin-rebuild switch --flake .#$(hostname)
	@echo "Darwin rebuild complete."

remote-rebuild:
	@echo "Rebuilding remote configuration for $(remotehost)..."
	@nixos-rebuild --sudo --target-host $(remotehost).meskill.farm switch --flake .#$(remotehost) --accept-flake-config
	@echo "Remote rebuild complete."

remote-dry-build:
	@echo "Dry-building configuration for $(remotehost)..."
	@nixos-rebuild dry-build --flake .#$(remotehost)
	@echo "Dry-build complete."

refresh-readme:
	@echo "Pulling latest README.md from remote..."
	@git fetch origin
	@git checkout origin/main -- README.md
	@echo "README.md refreshed from remote repository."

restore-readme:
	@echo "Restoring README.md from current commit (discarding local changes)..."
	@git restore README.md
	@echo "README.md restored from current commit."

bootstrap-mac: install-nix install-nix-darwin

pi-sdimage:
	@echo "Building SD image for $(pihost) on armistice..."
	@nix build .#nixosConfigurations.$(pihost).config.system.build.sdImage \
		--builders "ssh://armistice.meskill.farm aarch64-linux" \
		--max-jobs 0 \
		-o result-$(pihost)-sdimage
	@echo "SD image built: result-$(pihost)-sdimage/"
	@echo ""
	@echo "To flash to SD card:"
	@echo "  make pi-flash pihost=$(pihost) device=/dev/sdX"

pi-flash:
	@if [ -z "$(pihost)" ]; then echo "Error: pihost is required (e.g., make pi-flash pihost=rpc-5-1 device=/dev/sda)"; exit 1; fi
	@if [ -z "$(device)" ]; then echo "Error: device is required (e.g., make pi-flash pihost=rpc-5-1 device=/dev/sda)"; exit 1; fi
	@if [ ! -d "result-$(pihost)-sdimage" ]; then echo "Error: result-$(pihost)-sdimage not found. Run 'make pi-sdimage pihost=$(pihost)' first."; exit 1; fi
	@if [ ! -b "$(device)" ]; then echo "Error: $(device) is not a block device"; exit 1; fi
	@echo "WARNING: This will erase all data on $(device)!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read _
	@echo "Decompressing image..."
	@zstd -d -f result-$(pihost)-sdimage/sd-image/*.img.zst -o /tmp/$(pihost).img
	@echo "Flashing to $(device)..."
	@sudo dd if=/tmp/$(pihost).img of=$(device) bs=4M status=progress conv=fsync
	@sync
	@rm /tmp/$(pihost).img
	@echo "Flash complete! You can now safely remove $(device)."
