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
                cores = 12;         # Increased from 4 to utilize your 7800X3D better
                memorySize = 8192;  # Increased from 4GB to 8GB for better performance
                diskSize = 40960;   # 40GB in MB
                qemu.options = [
                  "-vga virtio"
                  "-display gtk,grab-on-hover=on"
                  "-cpu host" # Pass through CPU features for best performance
                ];
              };
            }
          ];
        };

        # Script to build and run the VM with performance optimizations
        run-vm = pkgs.writeShellScriptBin "run-vm" ''
          #!/usr/bin/env bash
          set -e

          CORES=$(nproc)

          echo "Building NixOS VM with optimized settings..."
          # Increase build parallelism for faster builds
          nix build .#vm --impure --max-jobs auto --cores $CORES 

          echo "Starting VM..."
          ./result/bin/run-nixos-vm
        '';
        
        # Fast build script that uses all CPU cores for maximum build performance
        fast-build = pkgs.writeShellScriptBin "fast-build" ''
          #!/usr/bin/env bash
          set -e
          
          CORES=$(nproc)
          JOBS=$((CORES + 2)) # Slightly more jobs than cores for optimal CPU utilization
          
          echo "Building $1 with optimized settings (jobs: $JOBS)..."
          nix build .#$1 --impure \
            --log-format bar-with-logs \
            --max-jobs $JOBS \
            --cores $CORES \
            --option keep-going true
        '';
        
      };
    };
}
