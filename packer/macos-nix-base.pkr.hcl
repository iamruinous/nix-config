# macos-nix-base.pkr.hcl
#
# Packer template for creating a macOS VM with Nix pre-installed.
# Uses Cirrus Labs Tart plugin to build on top of their base images.
#
# Prerequisites:
#   - macOS host with Apple Silicon
#   - Tart installed: brew install cirruslabs/cli/tart
#   - Packer installed: brew install packer
#   - Packer Tart plugin: packer plugins install github.com/cirruslabs/tart
#
# Usage:
#   # Pull base image first
#   tart pull ghcr.io/cirruslabs/macos-sequoia-base:latest
#
#   # Build the image
#   packer init macos-nix-base.pkr.hcl
#   packer build macos-nix-base.pkr.hcl
#
#   # Push to registry (optional)
#   tart push macos-sequoia-nix ghcr.io/iamruinous/macos-sequoia-nix:latest
#
# Variables can be overridden:
#   packer build -var "base_image=macos-tahoe-base" -var "vm_name=macos-tahoe-nix" .

packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

variable "base_image" {
  type        = string
  default     = "macos-sequoia-base"
  description = "Name of the local Tart VM to use as base (must be pulled first)"
}

variable "vm_name" {
  type        = string
  default     = "macos-sequoia-nix"
  description = "Name for the output VM"
}

variable "cpu_count" {
  type        = number
  default     = 4
  description = "Number of CPU cores"
}

variable "memory_gb" {
  type        = number
  default     = 8
  description = "Memory in GB"
}

variable "disk_size_gb" {
  type        = number
  default     = 80
  description = "Disk size in GB (base images are ~50GB, need room for Nix store)"
}

variable "ssh_username" {
  type        = string
  default     = "admin"
  description = "SSH username (Cirrus Labs images use 'admin')"
}

variable "ssh_password" {
  type        = string
  default     = "admin"
  description = "SSH password (Cirrus Labs images use 'admin')"
  sensitive   = true
}

variable "nix_config_repo" {
  type        = string
  default     = ""
  description = "Git repository URL for nix-darwin flake (optional, e.g., github:iamruinous/nix-config)"
}

variable "nix_config_host" {
  type        = string
  default     = ""
  description = "Hostname to use for nix-darwin configuration (optional)"
}

variable "install_nix_darwin" {
  type        = bool
  default     = false
  description = "Whether to bootstrap nix-darwin (requires nix_config_repo and nix_config_host)"
}

# ------------------------------------------------------------------------------
# Source: Tart VM Builder
# ------------------------------------------------------------------------------

source "tart-cli" "macos-nix" {
  vm_base_name = var.base_image
  vm_name      = var.vm_name
  
  cpu_count    = var.cpu_count
  memory_gb    = var.memory_gb
  disk_size_gb = var.disk_size_gb
  
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  
  # Timeout for SSH to become available (macOS boot can be slow)
  ssh_timeout = "10m"
  
  # Run headless during build
  headless = true
}

# ------------------------------------------------------------------------------
# Build Configuration
# ------------------------------------------------------------------------------

build {
  sources = ["source.tart-cli.macos-nix"]

  # Step 1: Upload scripts
  provisioner "file" {
    source      = "scripts/install-nix.sh"
    destination = "/tmp/install-nix.sh"
  }

  provisioner "file" {
    source      = "scripts/bootstrap-nix-darwin.sh"
    destination = "/tmp/bootstrap-nix-darwin.sh"
  }

  # Step 2: Install Nix using Determinate Systems installer
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install-nix.sh",
      "/tmp/install-nix.sh"
    ]
    # Increase timeout for Nix installation (downloads can be slow)
    timeout = "30m"
  }

  # Step 3: Verify Nix installation
  provisioner "shell" {
    inline = [
      "echo '=== Verifying Nix installation ==='",
      "source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh",
      "nix --version",
      "nix-store --version",
      "echo '=== Nix store location ==='",
      "ls -la /nix/store | head -20",
      "echo '=== Nix installation complete ==='"
    ]
  }

  # Step 4: Bootstrap nix-darwin (conditional)
  # Only runs if install_nix_darwin is true
  provisioner "shell" {
    inline = [
      "if [ '${var.install_nix_darwin}' = 'true' ] && [ -n '${var.nix_config_repo}' ] && [ -n '${var.nix_config_host}' ]; then",
      "  chmod +x /tmp/bootstrap-nix-darwin.sh",
      "  /tmp/bootstrap-nix-darwin.sh '${var.nix_config_repo}' '${var.nix_config_host}'",
      "else",
      "  echo 'Skipping nix-darwin bootstrap (install_nix_darwin=${var.install_nix_darwin})'",
      "fi"
    ]
    timeout = "60m"
  }

  # Step 5: Cleanup
  provisioner "shell" {
    inline = [
      "echo '=== Cleanup ==='",
      "rm -f /tmp/install-nix.sh /tmp/bootstrap-nix-darwin.sh",
      "# Garbage collect to reduce image size",
      "source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh",
      "nix-collect-garbage -d || true",
      "echo '=== Build complete ==='"
    ]
  }

  # Post-processor: Display summary
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
