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

    # Tools and generators
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  ############################################################################
  #  Outputs                                                                 #
  ############################################################################
  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [];

      # Define perSystem outputs (packages, devShells, etc.)
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Packages available in this flake
        packages = {
          # Terminal emulator with GPU acceleration
          ghostty = inputs'.ghostty.packages.default;
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

              # Import all NixOS modules
              ./modules/nixos/base
              ./modules/nixos/desktop
              ./modules/nixos/disk
              ./modules/nixos/gui-apps
              ./modules/nixos/hardware
              ./modules/nixos/macos-remap
              ./modules/nixos/ssh

              # Required modules
              inputs.home-manager.nixosModules.home-manager
              inputs.disko.nixosModules.disko
              inputs.nix-index-database.nixosModules.nix-index
              { programs.nix-index-database.comma.enable = true; }
              inputs.xremap-flake.nixosModules.default

              # Home Manager settings
              {
                home-manager.useUserPackages = true;
                home-manager.useGlobalPkgs = true;
                nixpkgs.config.allowUnfree = true;
              }

              # Import hardware configuration if available (with fallback)
              ({ lib, ... }: {
                imports = if builtins.pathExists /etc/nixos/hardware-configuration.nix
                  then [ /etc/nixos/hardware-configuration.nix ]
                  else if builtins.pathExists /mnt/etc/nixos/hardware-configuration.nix
                  then [ /mnt/etc/nixos/hardware-configuration.nix ]
                  else [];
              })
            ];
          };

          # VM configuration
          vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              # System configuration
              ./systems/x86_64-linux/vm

              # Import all NixOS modules
              ./modules/nixos/base
              ./modules/nixos/desktop
              ./modules/nixos/disk
              ./modules/nixos/gui-apps
              ./modules/nixos/hardening
              ./modules/nixos/hardware
              ./modules/nixos/macos-remap
              ./modules/nixos/ssh
              ./modules/nixos/vm

              # Required modules
              inputs.home-manager.nixosModules.home-manager
              inputs.disko.nixosModules.disko
              inputs.nix-index-database.nixosModules.nix-index
              inputs.xremap-flake.nixosModules.default

              # Home Manager settings
              {
                home-manager.useUserPackages = true;
                home-manager.useGlobalPkgs = true;
                nixpkgs.config.allowUnfree = true;
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

              # Import all NixOS modules
              ./modules/nixos/base
              ./modules/nixos/disk
              ./modules/nixos/hardening
              ./modules/nixos/hardware
              ./modules/nixos/ssh
              ./modules/nixos/macos-remap

              # Required modules
              inputs.home-manager.nixosModules.home-manager
              inputs.disko.nixosModules.disko
              inputs.nix-index-database.nixosModules.nix-index

              # Home Manager settings
              {
                home-manager.useUserPackages = true;
                home-manager.useGlobalPkgs = true;
                nixpkgs.config.allowUnfree = true;
              }

              # Import hardware configuration if available (with fallback)
              ({ lib, ... }: {
                imports = if builtins.pathExists /etc/nixos/hardware-configuration.nix
                  then [ /etc/nixos/hardware-configuration.nix ]
                  else if builtins.pathExists /mnt/etc/nixos/hardware-configuration.nix
                  then [ /mnt/etc/nixos/hardware-configuration.nix ]
                  else [];
              })
            ];
          };
        };

        # Removed standalone homeConfigurations as nixos-rebuild is preferred

        # Create helper run-vm command
        apps.x86_64-linux.run-vm = {
          type = "app";
          program = let
            vm = inputs.self.nixosConfigurations.vm.config.system.build.vm;
          in "${vm}/bin/run-nixos-vm";
        };

        # Create ISO targets
        packages.x86_64-linux = {
          # Hackstation ISO
          iso-hackstation = (inputs.nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            format = "iso";
            modules = [
              ({ ... }: {
                imports = [
                  ./systems/x86_64-linux/hackstation
                  ./modules/nixos/base
                  ./modules/nixos/desktop
                  ./modules/nixos/disk
                  ./modules/nixos/gui-apps
                  ./modules/nixos/hardening
                  ./modules/nixos/hardware
                  ./modules/nixos/macos-remap
                  ./modules/nixos/ssh
                  ./modules/nixos/vm
                ];
                # Override impure paths
                networking.hostName = "hackstation";
              })
            ];
          });

          # VM ISO
          iso-vm = (inputs.nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            format = "iso";
            modules = [
              ({ ... }: {
                imports = [
                  ./systems/x86_64-linux/vm
                  ./modules/nixos/base
                  ./modules/nixos/desktop
                  ./modules/nixos/disk
                  ./modules/nixos/gui-apps
                  ./modules/nixos/hardening
                  ./modules/nixos/hardware
                  ./modules/nixos/macos-remap
                  ./modules/nixos/ssh
                  ./modules/nixos/vm
                ];
                # Override impure paths
                networking.hostName = "vm";
              })
            ];
          });
        };
      };
    };
}
