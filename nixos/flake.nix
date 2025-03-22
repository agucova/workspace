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
  };

  outputs = { self, nixpkgs, home-manager, ghostty, nixos-generators, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # Make ghostty available as a regular package
          (final: prev: {
            ghostty = ghostty.packages.${system}.default;
          })
        ];
      };

      # Common NixOS module imports
      commonModules = [
        # Home Manager as a NixOS module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.agucova = import ./hosts/gnome/home.nix;
        }
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
          ];
          specialArgs = { inherit pkgs; };
        };

        # VM test configuration
        "vm-test" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/vm-test/configuration.nix
          ];
          specialArgs = { inherit pkgs; };
        };
      };

      # Additional configurations for special builds (e.g., ISO)
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Base modules
          ./modules/base.nix
          ./modules/gnome.nix
          # ISO-specific configuration
          ./iso/iso-image.nix
        ];
      };

      # VM image that can be built from non-NixOS systems
      packages.${system} = {
        # Create a QEMU VM image for testing
        vm = nixos-generators.nixosGenerate {
          inherit system;
          format = "vm";
          modules = [
            ./hosts/vm-test/configuration.nix
            # Simplify for VM usage
            {
              virtualisation = {
                cores = 4;
                memorySize = 4096;
                diskSize = 40960;  # 40GB in MB
                qemu.options = [
                  "-vga virtio"
                  "-display gtk,grab-on-hover=on"
                ];
              };
            }
          ];
        };

        # Script to build and run the VM
        run-vm = pkgs.writeShellScriptBin "run-vm" ''
          #!/usr/bin/env bash
          set -e

          echo "Building NixOS VM..."
          nix build .#vm --impure

          echo "Starting VM..."
          ./result/bin/run-nixos-vm
        '';
      };
    };
}
