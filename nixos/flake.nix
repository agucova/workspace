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
  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      imports = [];

      # Define perSystem outputs (packages, devShells, etc.)
      perSystem = { config, self', inputs', pkgs, system, lib, ... }: {
        # Packages available in this flake
        packages = lib.optionalAttrs (system == "x86_64-linux") {
          # Terminal emulator with GPU acceleration (Linux only)
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

              # Import Linux modules
              ./modules/linux/system/base
              ./modules/linux/system/ssh
              ./modules/linux/system/disk
              ./modules/linux/desktop/gnome
              ./modules/linux/desktop/apps
              ./modules/linux/desktop/keybindings
              ./modules/linux/hardware

              # Required modules
              inputs.home-manager.nixosModules.home-manager
              inputs.disko.nixosModules.disko
              inputs.nix-index-database.nixosModules.nix-index
              { programs.nix-index-database.comma.enable = true; }
              inputs.xremap-flake.nixosModules.default
              inputs.chaotic.nixosModules.default

              # Home Manager settings
              {
                home-manager.useUserPackages = true;
                home-manager.useGlobalPkgs = true;
                nixpkgs.config.allowUnfree = true;

                # Home Manager configuration for hackstation
                home-manager.users.agucova = { pkgs, lib, ... }: {
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
              ./modules/linux/desktop/keybindings
              ./modules/linux/hardware
              ./modules/linux/vm

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

                # Home Manager configuration for VM
                home-manager.users.agucova = { pkgs, lib, ... }: {
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
              ({ lib, ... }: {
                imports = if builtins.pathExists /etc/nixos/hardware-configuration.nix
                  then [ /etc/nixos/hardware-configuration.nix ]
                  else if builtins.pathExists /mnt/etc/nixos/hardware-configuration.nix
                  then [ /mnt/etc/nixos/hardware-configuration.nix ]
                  else [];
              })

              # Home Manager settings
              {
                home-manager.useUserPackages = true;
                home-manager.useGlobalPkgs = true;
                nixpkgs.config.allowUnfree = true;

                # Home Manager configuration for server
                home-manager.users.agucova = { pkgs, lib, ... }: {
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

              # nix-homebrew integration
              inputs.nix-homebrew.darwinModules.nix-homebrew

              # Home Manager integration
              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.useUserPackages = true;
                home-manager.useGlobalPkgs = true;
                nixpkgs.config.allowUnfree = true;

                # Home Manager configuration for Darwin
                home-manager.users.agucova = { pkgs, lib, ... }: {
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
          program = let
            vm = inputs.self.nixosConfigurations.vm.config.system.build.vm;
          in "${vm}/bin/run-nixos-vm";
        };

      };
    };
}
