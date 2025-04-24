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

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ghostty,
      nixos-generators,
      nix-index-database,
      nix-mineral,
      claude-desktop,
      xremap-flake,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
        overlays = [
          # Make packages available from flakes
          (final: prev: {
            ghostty = ghostty.packages.${system}.default;
            claude-desktop-with-fhs = claude-desktop.packages.${system}.claude-desktop-with-fhs;
          })
        ];
      };

      # Common NixOS module imports
      commonModules = [
        # Home Manager as a NixOS module
        home-manager.nixosModules.home-manager

        # xremap module for keyboard remapping
        xremap-flake.nixosModules.default

        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            # Pass additional arguments to home-manager modules if needed
            extraSpecialArgs = { inherit nix-index-database; };

            # Make Home Manager activate properly with debug settings
            sharedModules = [
              {
                # Enable a consistent state version and debugging
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
        }

        # IMPORTANT: We're now using Home Manager for nix-index-database,
        # so we don't include the NixOS module to avoid conflicts
        # nix-index-database.nixosModules.nix-index
      ];
    in
    {
      # NixOS Configurations
      nixosConfigurations = {
        # Main workstation configuration
        "gnome-nixos" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/gnome/configuration.nix
            {
              # User-specific Home Manager configuration
              home-manager.users.agucova = import ./hosts/common/home.nix;
            }
          ];
          specialArgs = { inherit pkgs nix-mineral claude-desktop; };
        };

        # VM test configuration
        "vm-test" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/vm-test/configuration.nix
            {
              home-manager.users.agucova = import ./hosts/common/home.nix;
            }
          ];
          specialArgs = { inherit pkgs nix-mineral claude-desktop; };
        };
      };

      # Build artifacts and helper scripts
      packages.${system} = {
        # --- Build Targets ---

        # Build a QEMU VM image (.qcow2) based on the vm-test configuration
        # This is efficient for directly running the VM.
        vm-image = nixos-generators.nixosGenerate {
          inherit system;
          format = "vm";
          modules = commonModules ++ [
            ./hosts/vm-test/configuration.nix
            (
              { lib, ... }:
              {
                virtualisation = {
                  cores = lib.mkDefault 12;
                  memorySize = lib.mkDefault 8192;
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
              }
            )
          ];
          specialArgs = { inherit pkgs nix-mineral claude-desktop; };
        };

        # Build an ISO image based on the gnome-nixos (hardware) configuration
        # Useful for installing on real hardware.
        iso-gnome = nixos-generators.nixosGenerate {
          inherit system;
          format = "iso";
          modules = commonModules ++ [
            ./hosts/gnome/configuration.nix
            (
              { lib, pkgs, ... }:
              {
                imports = [ "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix" ];
                isoImage.isoName = "nixos-gnome-hardware-${pkgs.stdenv.hostPlatform.system}.iso";
                isoImage.volumeID = "NIXOS_GNOME_HW";
                boot.loader.timeout = 10;
                users.users.nixos = {
                  isNormalUser = true;
                  extraGroups = [
                    "wheel"
                    "networkmanager"
                    "video"
                    "audio"
                    "input"
                  ];
                  initialPassword = "nixos";
                  initialHashedPassword = lib.mkForce null;
                };
                services.displayManager.autoLogin = {
                  enable = true;
                  user = "nixos";
                };
                security.sudo.wheelNeedsPassword = false;
                environment.systemPackages = with pkgs; [ gparted ];
                hardware.enableAllFirmware = true;
                services.macos-remap.enable = lib.mkDefault true; # Now lib is available
                services.xremap.userName = lib.mkDefault "nixos"; # Now lib is available
              }
            )
          ];
          specialArgs = { inherit pkgs nix-mineral claude-desktop; };
        };

        # Build an ISO image based on the vm-test configuration
        # Useful for testing the VM setup in an ISO/live environment.
        iso-vm = nixos-generators.nixosGenerate {
          inherit system;
          format = "iso";
          modules = commonModules ++ [
            ./hosts/vm-test/configuration.nix
            (
              { lib, pkgs, ... }:
              {
                # <--- Added function wrapper
                imports = [ "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix" ];
                isoImage.isoName = "nixos-vm-test-${pkgs.stdenv.hostPlatform.system}.iso";
                isoImage.volumeID = "NIXOS_VM_TEST";
                boot.loader.timeout = 5;
                users.users.nixos = {
                  isNormalUser = true;
                  extraGroups = [
                    "wheel"
                    "networkmanager"
                    "video"
                    "audio"
                    "input"
                  ];
                  initialPassword = "nixos";
                  initialHashedPassword = lib.mkForce null;
                };
                services.displayManager.autoLogin = {
                  enable = true;
                  user = "nixos";
                };
                security.sudo.wheelNeedsPassword = false;
                hardware.enableAllFirmware = true;
                services.macos-remap.enable = lib.mkDefault true;
                services.xremap.userName = lib.mkDefault "nixos";
              }
            ) # <--- Close the function wrapper
          ];
          specialArgs = { inherit pkgs nix-mineral claude-desktop; };
        };

        # --- Runner Script ---

        # Script to run the VM defined by `vm-image`
        # `nix run .#run-vm` will build vm-image if needed, then execute this.
        # flake.nix (inside packages.run-vm definition)
        run-vm = pkgs.writeShellScriptBin "run-vm" ''
          #!/usr/bin/env bash
          set -e
          # set -x # You can remove or keep this now
          VM_IMAGE_PATH="${self.packages.${system}.vm-image}"

          # Remove the "-type f" argument from find:
          VM_RUN_SCRIPT=$(find "$VM_IMAGE_PATH/bin" -name "run-*-vm" | head -n 1)

          # You can remove the extra debug lines now if you want
          # echo "DEBUG: Checking contents of $VM_IMAGE_PATH/bin/"
          # ls -l "$VM_IMAGE_PATH/bin/"
          # echo "DEBUG: Find command returned: '$VM_RUN_SCRIPT'"

          if [ -z "$VM_RUN_SCRIPT" ]; then
            echo "Error: Could not find the VM run script in $VM_IMAGE_PATH/bin" >&2
            exit 1
          fi

          echo "Starting NixOS VM using script: $VM_RUN_SCRIPT"
          exec "$VM_RUN_SCRIPT" "$@"
        '';
      };
    };
}
