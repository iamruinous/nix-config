.PHONY: update-flake bootstrap-mac install-nix install-nix-darwin darwin-rebuild remote-rebuild remote-dry-build refresh-readme restore-readme

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
