{
  description = "NixOS configuration for 7800X3D + RTX 4090 Workstation";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager for user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Snowfall Lib for structured flake management
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ghostty terminal
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    # For VM generation from non-NixOS systems
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-index-database for command-not-found functionality
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-mineral for system hardening
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral"; # Use the main branch
      flake = false;
    };

    # Claude Desktop for Linux
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # xremap for keyboard remapping
    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      # System packages for x86_64-linux
      systemPkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-25.9.0" ];
        };
      };
      
      # Common Home Manager configuration for all systems
      hmCommonConfig = { lib, ... }: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = { inherit (inputs) nix-index-database; };
          sharedModules = [
            {
              home = {
                stateVersion = "24.11";
                enableDebugInfo = true;
                sessionVariables = {
                  HM_DEBUG = "1";
                };
              };
            }
          ];
        };
      };

    in {
      # NixOS configurations
      nixosConfigurations = {
        "gnome-nixos" = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # Import Home Manager
            inputs.home-manager.nixosModules.home-manager
            inputs.xremap-flake.nixosModules.default
            
            # Import common home manager config
            hmCommonConfig
            
            # Import our system configuration
            ./systems/x86_64-linux/gnome-nixos/default.nix
          ];
          specialArgs = { 
            pkgs = systemPkgs;
            inherit inputs;
          };
        };
        
        "vm-test" = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # Import Home Manager
            inputs.home-manager.nixosModules.home-manager
            inputs.xremap-flake.nixosModules.default
            
            # Import common home manager config
            hmCommonConfig
            
            # Import our system configuration
            ./systems/x86_64-linux/vm-test/default.nix
          ];
          specialArgs = { 
            pkgs = systemPkgs;
            inherit inputs;
          };
        };
      };
      
      # Define channel config
      nixConfig = {
        extra-substituters = [
          "https://xremap.cachix.org"
        ];
        extra-trusted-public-keys = [
          "xremap.cachix.org-1:Vz8Xjjai+6Wc0JJaJLEWu7QveZV3hQzVL5GnqQ7rlmo="
        ];
      };
      
      # Define overlays
      overlays.default = final: prev: {
        ghostty = inputs.ghostty.packages.${prev.system}.default;
        claude-desktop-with-fhs = inputs.claude-desktop.packages.${prev.system}.claude-desktop-with-fhs;
      };
      
      # Package definitions
      packages.x86_64-linux = {
        # Simple run-vm script
        run-vm = systemPkgs.writeShellScriptBin "run-vm" ''
          #!/usr/bin/env bash
          set -e
          
          # Build the VM image
          VM_PATH=$(nix build --no-link --print-out-paths .#vm-image --impure)
          VM_RUN_SCRIPT=$(find "$VM_PATH/bin" -name "run-*-vm" | head -n 1)
          
          if [ -z "$VM_RUN_SCRIPT" ]; then
            echo "Error: Could not find the VM run script in $VM_PATH/bin" >&2
            exit 1
          fi
          
          echo "Starting NixOS VM using script: $VM_RUN_SCRIPT"
          exec "$VM_RUN_SCRIPT" "$@"
        '';
        
        # VM image generation
        vm-image = inputs.nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "vm";
          modules = [
            # Import Home Manager
            inputs.home-manager.nixosModules.home-manager
            inputs.xremap-flake.nixosModules.default
            
            # Import common home manager config
            hmCommonConfig
            
            # Allow unfree packages
            { nixpkgs.config.allowUnfree = true; }
            
            # Direct inline configuration for VM to avoid module resolution issues
            ({ lib, pkgs, ... }: {
              # Set hostname for VM
              networking.hostName = "nixos-vm-test";
            
              # User account for VM
              users.users.agucova = {
                isNormalUser = true;
                description = "Agustin Covarrubias";
                extraGroups = [ "networkmanager" "wheel" ];
                shell = pkgs.fish;
                initialPassword = "nixos";
              };
              
              # Enable fish shell
              programs.fish.enable = true;
              
              # Enable automatic login for testing
              services.displayManager.autoLogin.enable = true;
              services.displayManager.autoLogin.user = "agucova";
              
              # Disable some hardware-specific optimizations
              boot.kernelParams = lib.mkForce [ "preempt=full" ];
              
              # Simplify boot configuration
              boot.loader = {
                systemd-boot.enable = true;
                efi.canTouchEfiVariables = true;
                timeout = lib.mkForce 0;
              };
              
              # Command not found
              programs.command-not-found.enable = false;
              programs.nix-index.enable = false;
              
              # Filesystems for VM
              fileSystems."/" = {
                device = "/dev/disk/by-label/nixos";
                fsType = "ext4";
              };
              
              fileSystems."/boot" = {
                device = "/dev/disk/by-label/boot";
                fsType = "vfat";
              };
              
              # Include packages from gui-apps module
              environment.systemPackages = with pkgs; [
                # Office and Productivity
                libreoffice-qt
                vscode
                ghostty  # From flake overlay
                zed-editor.fhs  # Modern code editor with FHS env for better compatibility
                # Only include Claude Desktop if we're not in a live ISO environment
                (lib.mkIf (!config.isoImage.enable or false) inputs.claude-desktop.packages.${system}.claude-desktop-with-fhs)  # Claude AI desktop app with FHS env for MCP
                firefox-devedition-bin
                gitkraken  # Migrated from Flatpak

                # Media and Entertainment
                vlc
                spotify
                discord
                signal-desktop
                telegram-desktop
                slack

                # Productivity
                insync
                obsidian  # Already native
                zotero    # Already native
                calibre

                # GNOME-specific utilities
                gnome-disk-utility
                gnome-system-monitor

                # Gaming tools
                steam
                lutris
                
                # Basic tools
                firefox
                gnome-terminal
                strace
                lsof
                file
              ];
              
              # GNOME desktop
              services.xserver.enable = true;
              services.xserver.displayManager.gdm.enable = true;
              services.xserver.desktopManager.gnome.enable = true;
              
              # Enable Firefox
              programs.firefox.enable = true;
              
              # Configure Flatpak
              services.flatpak = {
                enable = true;
              };
              
              # Flatpak post-installation script to install common apps
              system.activationScripts.flatpakApps = ''
                # Add Flathub repo
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

                # Install common Flatpak apps that don't have good Nix packages
                FLATPAK_APPS=(
                  "com.stremio.Stremio"
                  "org.jamovi.jamovi"
                  "org.zulip.Zulip"
                )

                for app in "''${FLATPAK_APPS[@]}"; do
                  flatpak install -y flathub "$app" || true
                done
              '';
              
              # xremap for keyboard remapping
              services.xremap = {
                enable = true;
                userName = "agucova";
                watch = true;
                withGnome = true;
                config = {
                  modmap = [
                    {
                      name = "MacOS-like Alt/Cmd swapping";
                      remap = {
                        Alt_L = "Super_L";
                        Super_L = "Alt_L";
                      };
                    }
                  ];
                  keymap = [
                    {
                      name = "MacOS-style shortcuts";
                      remap = {
                        "Super-c" = "C-c";  # Cmd+C -> Ctrl+C (Copy)
                        "Super-v" = "C-v";  # Cmd+V -> Ctrl+V (Paste)
                        "Super-x" = "C-x";  # Cmd+X -> Ctrl+X (Cut)
                        "Super-z" = "C-z";  # Cmd+Z -> Ctrl+Z (Undo)
                        "Super-a" = "C-a";  # Cmd+A -> Ctrl+A (Select All)
                        "Super-f" = "C-f";  # Cmd+F -> Ctrl+F (Find)
                        "Super-s" = "C-s";  # Cmd+S -> Ctrl+S (Save)
                        "Super-w" = "C-w";  # Cmd+W -> Ctrl+W (Close)
                      };
                    }
                  ];
                };
              };
              
              # Home manager config 
              home-manager.users.agucova = { lib, ... }: {
                home.username = "agucova";
                home.homeDirectory = "/home/agucova";
                home.stateVersion = "24.11";
              };
            
              # Settings for VM tests
              system.stateVersion = "24.11";
              
              # VM performance settings
              virtualisation = {
                cores = 12;
                memorySize = 8192;
                diskSize = 40960;
                qemu.options = [
                  "-vga virtio"
                  "-display gtk,grab-on-hover=on"
                  "-cpu host"
                  "-device virtio-keyboard-pci"
                  "-usb"
                  "-device usb-tablet"
                  "-device virtio-serial-pci"
                ];
              };
            })
          ];
          specialArgs = { 
            pkgs = systemPkgs;
            inherit inputs;
          };
        };
        
        # ISO images
        iso-gnome = inputs.nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "iso";
          modules = [
            ./systems/x86_64-linux/gnome-nixos/default.nix
            ({ pkgs, ... }: {
              imports = [ "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix" ];
              isoImage.isoName = "nixos-gnome-hardware-x86_64-linux.iso";
              isoImage.volumeID = "NIXOS_GNOME_HW";
              boot.loader.timeout = 10;
              users.users.nixos = {
                isNormalUser = true;
                extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
                initialPassword = "nixos";
                initialHashedPassword = null;
              };
              services.displayManager.autoLogin = {
                enable = true;
                user = "nixos";
              };
              security.sudo.wheelNeedsPassword = false;
              environment.systemPackages = with pkgs; [ gparted ];
              hardware.enableAllFirmware = true;
              services.macos-remap.enable = true;
              services.xremap.userName = "nixos";
            })
          ];
          specialArgs = { 
            pkgs = systemPkgs;
            inherit inputs;
          };
        };
        
        iso-vm = inputs.nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "iso";
          modules = [
            ./systems/x86_64-linux/vm-test/default.nix
            ({ pkgs, ... }: {
              imports = [ "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix" ];
              isoImage.isoName = "nixos-vm-test-x86_64-linux.iso";
              isoImage.volumeID = "NIXOS_VM_TEST";
              boot.loader.timeout = 5;
              users.users.nixos = {
                isNormalUser = true;
                extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
                initialPassword = "nixos";
                initialHashedPassword = null;
              };
              services.displayManager.autoLogin = {
                enable = true;
                user = "nixos";
              };
              security.sudo.wheelNeedsPassword = false;
              hardware.enableAllFirmware = true;
              services.macos-remap.enable = true;
              services.xremap.userName = "nixos";
            })
          ];
          specialArgs = { 
            pkgs = systemPkgs;
            inherit inputs;
          };
        };
      };
    };
}