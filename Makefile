.PHONY: update-flake bootstrap-mac install-nix install-nix-darwin darwin-rebuild

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
	@echo "Rebuilding remote configuration..."
  @nixos-rebuild --sudo --target-host $(remotehost).manage.farmhouse.meskill.network switch --flake .#$(remotehost) --accept-flake-config 
	@echo "Remote rebuild complete."

bootstrap-mac: install-nix install-nix-darwin
