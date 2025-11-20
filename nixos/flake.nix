{
  description = "NixOS / Home-Manager mono-repo for my 7800X3D + RTX 4090 workstation fleet";

  ############################################################################
  #  Inputs                                                                  #
  ############################################################################
  inputs = {
    # Core dependencies
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Replace snowfall-lib with flake-parts
    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Darwin support
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homebrew management through Nix
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Application dependencies
    ghostty.url = "github:ghostty-org/ghostty";

    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System enhancements
    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Security
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral/e5aa5126d433fe57fe151146e9b688f079709233";
      flake = false;
    };

    # For the CachyOS kernel
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    };
  };

  ############################################################################
  #  Outputs                                                                 #
  ############################################################################
  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [ ];

      # Define perSystem outputs (packages, devShells, etc.)
      perSystem =
        {
          inputs',
          pkgs,
          system,
          lib,
          ...
        }:
        {
          # Packages available in this flake
          packages = lib.optionalAttrs (system == "x86_64-linux") {
            # Terminal emulator with GPU acceleration (Linux only)
            ghostty = inputs'.ghostty.packages.default;
            # Slack CLI for building Slack apps
            slack-cli = pkgs.callPackage ./packages/slack-cli { };
          } // lib.optionalAttrs (system == "aarch64-darwin") {
            # Slack CLI for building Slack apps (macOS)
            slack-cli = pkgs.callPackage ./packages/slack-cli { };
          };

          # Development shell
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixpkgs-fmt
              statix
            ];
          };
        };

      # System-wide flake outputs
      flake = {
        # NixOS configurations
        nixosConfigurations = {
          # Hackstation configuration
          hackstation = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              # System configuration
              ./systems/x86_64-linux/hackstation

              # Import Linux modules
              ./modules/linux/system/base
              ./modules/linux/system/ssh
              ./modules/linux/system/disk
              ./modules/linux/desktop/gnome
              ./modules/linux/desktop/apps
              ./modules/linux/desktop/keybindings
              ./modules/linux/hardware
              ./modules/linux/hardware/printing

              # Required modules
              inputs.home-manager.nixosModules.home-manager
              inputs.disko.nixosModules.disko
              inputs.nix-index-database.nixosModules.nix-index
              inputs.xremap-flake.nixosModules.default
              inputs.chaotic.nixosModules.default

              # Home Manager settings
              {
                home-manager.useUserPackages = true;
                home-manager.useGlobalPkgs = true;
                nixpkgs.config.allowUnfree = true;

                # Home Manager configuration for hackstation
                home-manager.users.agucova =
                  { ... }:
                  {
                    imports = [
                      # Import common modules
                      ./modules/common/shell
                      ./modules/common/dev
                      ./modules/common/security
                      # Linux-specific user settings
                      ./modules/linux/desktop/user
                    ];
                  };
              }
            ];
          };

          # VM configuration
          vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              # System configuration
              ./systems/x86_64-linux/vm

              # Import Linux modules
              ./modules/linux/system/base
              ./modules/linux/system/ssh
              ./modules/linux/system/disk
              ./modules/linux/system/hardening
              ./modules/linux/desktop/gnome
              ./modules/linux/desktop/apps
              ./modules/linux/hardware
              ./modules/linux/vm

              # Required modules
              inputs.home-manager.nixosModules.home-manager
              inputs.disko.nixosModules.disko
              inputs.nix-index-database.nixosModules.nix-index
              inputs.chaotic.nixosModules.default

              # Home Manager settings
              {
                home-manager.useUserPackages = true;
                home-manager.useGlobalPkgs = true;
                nixpkgs.config.allowUnfree = true;

                # Home Manager configuration for VM
                home-manager.users.agucova =
                  { ... }:
                  {
                    imports = [
                      # Import common modules
                      ./modules/common/shell
                      ./modules/common/dev
                      ./modules/common/security
                      # Linux-specific user settings
                      ./modules/linux/desktop/user
                    ];

                  };
              }
            ];
          };

          # Server configuration
          server = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              # System configuration
              ./systems/x86_64-linux/server

              # Import Linux modules
              ./modules/linux/system/base
              ./modules/linux/system/ssh
              ./modules/linux/system/disk
              ./modules/linux/system/hardening
              ./modules/linux/hardware

              # Required modules
              inputs.home-manager.nixosModules.home-manager
              inputs.disko.nixosModules.disko
              inputs.nix-index-database.nixosModules.nix-index
              inputs.chaotic.nixosModules.default

              # Import hardware configuration if available (with fallback)
              (
                { ... }:
                {
                  imports =
                    if builtins.pathExists /etc/nixos/hardware-configuration.nix then
                      [ /etc/nixos/hardware-configuration.nix ]
                    else if builtins.pathExists /mnt/etc/nixos/hardware-configuration.nix then
                      [ /mnt/etc/nixos/hardware-configuration.nix ]
                    else
                      [ ];
                }
              )

              # Home Manager settings
              {
                home-manager.useUserPackages = true;
                home-manager.useGlobalPkgs = true;
                nixpkgs.config.allowUnfree = true;

                # Home Manager configuration for server
                home-manager.users.agucova =
                  { ... }:
                  {
                    imports = [
                      # Import common modules (no desktop/GUI)
                      ./modules/common/shell
                      ./modules/common/dev
                      ./modules/common/security
                    ];

                  };
              }
            ];
          };
        };

        # Darwin configurations
        darwinConfigurations = {
          hackbookv5 = inputs.nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = { inherit inputs; };
            modules = [
              # System configuration
              ./systems/aarch64-darwin/hackbookv5

              # Import Darwin modules
              ./modules/darwin/system
              ./modules/darwin/apps

              inputs.nix-homebrew.darwinModules.nix-homebrew
              inputs.nix-index-database.darwinModules.nix-index

              # Home Manager integration
              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.useUserPackages = true;
                home-manager.useGlobalPkgs = true;
                nixpkgs.config.allowUnfree = true;

                # Home Manager configuration for Darwin
                home-manager.users.agucova =
                  { ... }:
                  {
                    imports = [
                      # Import common modules
                      ./modules/common/shell
                      ./modules/common/dev
                      ./modules/common/security
                    ];

                    # Required for home-manager
                    home.stateVersion = "24.05";
                  };
              }
            ];
          };
        };

        # Create helper run-vm command
        apps.x86_64-linux.run-vm = {
          type = "app";
          program =
            let
              vm = inputs.self.nixosConfigurations.vm.config.system.build.vm;
            in
            "${vm}/bin/run-nixos-vm";
        };

        # Cross-architecture VM runner for aarch64-darwin (ARM macOS)
        apps.aarch64-darwin.run-vm-cross = {
          type = "app";
          program =
            let
              # Use aarch64-darwin's nixpkgs for the runner script
              pkgs = nixpkgs.legacyPackages.aarch64-darwin;
              runner = pkgs.writeShellScriptBin "run-vm-cross" ''
                #!/usr/bin/env bash
                set -euo pipefail

                echo "====================================="
                echo "Cross-Architecture VM Runner for macOS"
                echo "====================================="
                echo ""
                echo "This script runs x86_64 NixOS VMs on ARM macOS using QEMU TCG emulation."
                echo ""
                
                # First, we need to set up a Linux builder since macOS can't build Linux packages natively
                echo "Step 1: Checking for Linux builder configuration..."
                
                # Check for Linux builder in various ways
                if ps aux | grep -q "[q]emu.*linux.*31022"; then
                  echo "✓ Linux builder VM is running (QEMU process detected)"
                elif nix show-config 2>/dev/null | grep -q "builders.*x86_64-linux"; then
                  echo "✓ Found x86_64-linux builder in Nix configuration"
                elif ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p 31022 builder@localhost echo "test" 2>/dev/null >/dev/null; then
                  echo "✓ Linux builder VM is reachable via SSH on port 31022"
                elif ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no linux-builder echo "test" 2>/dev/null >/dev/null; then
                  echo "✓ Linux builder VM is reachable via SSH alias"
                elif [ -f "$HOME/linux-builder/keys/id_ed25519" ] || [ -f "$HOME/.ssh/nix-linux-builder" ]; then
                  echo "✓ Linux builder keys found, builder may be configured"
                  echo "  Note: VM may need to be started. Try: nix run nixpkgs#darwin.linux-builder"
                else
                  echo "⚠ No Linux builder detected"
                  echo ""
                  echo "To build x86_64 packages on ARM macOS, you need a Linux builder."
                  echo ""
                  echo "Setting up the Darwin Linux Builder VM:"
                  echo ""
                  echo "1. Create the builder (one-time setup):"
                  echo "   nix run nixpkgs#darwin.linux-builder"
                  echo ""
                  echo "2. The builder will create SSH keys and configuration"
                  echo "3. It runs as a background VM when needed"
                  echo ""
                  echo "After setup, you can verify with:"
                  echo "   ssh linux-builder echo 'builder working'"
                  echo ""
                  read -p "Would you like to set up the Linux builder now? (y/n) " -n 1 -r
                  echo
                  if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo ""
                    echo "Creating Linux builder VM..."
                    echo "This will set up a minimal Linux VM for building x86_64 packages."
                    echo ""
                    if nix run nixpkgs#darwin.linux-builder; then
                      echo ""
                      echo "✓ Linux builder created successfully!"
                      echo "  The builder is now available for x86_64-linux builds."
                      echo ""
                      echo "Please run this script again to build the VM."
                      exit 0
                    else
                      echo "Failed to create Linux builder."
                      echo "Please try running manually: nix run nixpkgs#darwin.linux-builder"
                      exit 1
                    fi
                  else
                    echo ""
                    echo "Continuing without confirmed builder..."
                    echo "Build may fail if no builder is available."
                  fi
                fi
                
                echo ""
                echo "Step 2: Building the x86_64 VM..."
                echo "This may take a while on first run..."
                
                # Determine builder arguments based on what we detected
                BUILDER_ARGS=""
                if ps aux | grep -q "[q]emu.*linux.*31022"; then
                  echo "Using Linux builder VM on port 31022..."
                  BUILDER_ARGS="--builders 'ssh://builder@localhost:31022 x86_64-linux' --builders-use-substitutes"
                elif [ -n "$(nix show-config 2>/dev/null | grep 'builders =')" ]; then
                  echo "Using configured builders from nix.conf..."
                  BUILDER_ARGS=""
                else
                  echo "Attempting build with default settings..."
                  echo "If this fails, you may need to configure the builder manually."
                  BUILDER_ARGS="--builders 'ssh://builder@localhost:31022 x86_64-linux' --builders-use-substitutes"
                fi
                
                # Try to build the VM
                echo "Running: nix build .#nixosConfigurations.vm.config.system.build.vm --impure $BUILDER_ARGS"
                if ! VM_PATH=$(nix build ".#nixosConfigurations.vm.config.system.build.vm" --no-link --print-out-paths --impure $BUILDER_ARGS 2>&1); then
                  echo "Failed to build VM. Error output:"
                  echo "$VM_PATH"
                  echo ""
                  echo "Troubleshooting:"
                  echo "1. Make sure the Linux builder VM is running"
                  echo "2. You may need to set up SSH access:"
                  echo "   ssh-copy-id -p 31022 builder@localhost"
                  echo "3. Or configure the builder in /etc/nix/nix.conf:"
                  echo "   builders = ssh://builder@localhost:31022 x86_64-linux"
                  echo ""
                  echo "For more info: https://nixos.wiki/wiki/Distributed_build"
                  exit 1
                fi
                
                echo "✓ VM built successfully at: $VM_PATH"
                echo ""
                echo "Step 3: Starting VM with QEMU TCG emulation..."
                echo "Note: This will be 10-50x slower than native execution!"
                echo "====================================="
                echo ""
                
                # Find and run the VM script
                VM_SCRIPT="$VM_PATH/bin/run-nixos-vm"
                if [ ! -f "$VM_SCRIPT" ]; then
                  echo "Error: VM script not found at $VM_SCRIPT"
                  exit 1
                fi
                
                # Run with TCG emulation
                exec "$VM_SCRIPT" -accel tcg -cpu max "$@"
              '';
            in
            "${runner}/bin/run-vm-cross";
        };

      };
    };
}
