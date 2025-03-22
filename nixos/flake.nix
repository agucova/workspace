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
      url = "github:cynicsketch/nix-mineral";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, ghostty, nixos-generators, nix-index-database, nix-mineral, ... }:
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
              home-manager.users.agucova = import ./hosts/gnome/home.nix;
            }
          ];
          specialArgs = { inherit pkgs nix-mineral; };
        };

        # VM test configuration
        "vm-test" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/vm-test/configuration.nix
            {
              # User-specific Home Manager configuration (reuse the same home.nix)
              home-manager.users.agucova = import ./hosts/gnome/home.nix;
            }
          ];
          specialArgs = { inherit pkgs nix-mineral; };
        };
        
        # ISO image configuration
        "iso" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            # Base modules
            ./modules/base.nix
            ./modules/gnome.nix
            # ISO-specific configuration
            ./iso/iso-image.nix
          ];
        };
      };

      # VM image that can be built from non-NixOS systems
      packages.${system} = {
        # Create a QEMU VM image for testing
        vm = nixos-generators.nixosGenerate {
          inherit system;
          format = "vm";
          modules = commonModules ++ [
            ./hosts/vm-test/configuration.nix
            {
              virtualisation = {
                cores = 12;
                memorySize = 8192;
                diskSize = 40960;   # 40GB in MB
                qemu.options = [
                  "-vga virtio"
                  "-display gtk,grab-on-hover=on"
                  "-cpu host"
                ];
              };
            }
          ];
          specialArgs = { inherit pkgs nix-mineral; };
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
          # Check for the specifically named script we know exists
          if [ -f ./result/bin/run-nixos-vm-test-vm ]; then
            ./result/bin/run-nixos-vm-test-vm
          elif [ -f ./result/bin/run-nixos-vm ]; then
            ./result/bin/run-nixos-vm
          else
            echo "Listing available VM scripts:"
            ls -la ./result/bin/
            
            # Use first available VM script
            VM_SCRIPT=$(find ./result/bin -name "run-*-vm" | head -n 1)
            if [ -n "$VM_SCRIPT" ]; then
              echo "Found VM script at: $VM_SCRIPT"
              $VM_SCRIPT
            else
              echo "Error: Could not find VM execution script."
            fi
          fi
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
