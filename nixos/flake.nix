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
      url = "github:cynicsketch/nix-mineral";  # Use the main branch
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
    
    # We no longer need nyx as Zed already has FHS support in nixpkgs
  };

  outputs = { self, nixpkgs, home-manager, ghostty, nixos-generators, nix-index-database, nix-mineral, claude-desktop, xremap-flake, ... }:
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
              home-manager.users.agucova = import ./hosts/gnome/home.nix;
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
              # User-specific Home Manager configuration (reuse the same home.nix)
              home-manager.users.agucova = import ./hosts/gnome/home.nix;
            }
          ];
          specialArgs = { inherit pkgs nix-mineral claude-desktop; };
        };
        
        # ISO image configuration - simplified
        "iso" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            # Include Home Manager module
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
              };
            }
            
            # Include xremap module
            xremap-flake.nixosModules.default
            
            # Base modules
            ./modules/base.nix
            ./modules/gnome.nix
            ./modules/gui-apps.nix
            ./modules/hardware.nix
            ./modules/macos-remap.nix
            
            # ISO-specific configuration - contains all ISO customizations
            ./iso/iso-image.nix
            
            # Standard NixOS ISO module
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
            
            # Simple config for ISO compatibility
            {
              nixpkgs.config.allowUnfree = true;
              hardware.enableAllFirmware = true;
            }
          ];
          specialArgs = { 
            inherit pkgs claude-desktop; 
          };
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
          specialArgs = { inherit pkgs nix-mineral claude-desktop; };
        };
        
        # ISO image build target
        iso = self.nixosConfigurations.iso.config.system.build.isoImage;
        
        # Script to test the ISO in a VM with advanced options
        test-iso = pkgs.writeShellScriptBin "test-iso" ''
          #!/usr/bin/env bash
          set -e
          
          # Define variables
          PERSISTENT_SIZE="8G"
          PERSISTENT_FILE="nixos-live-persistence.qcow2"
          USE_PERSISTENCE=0
          
          # Define variables
          DIAGNOSTIC_MODE=0
          
          # Parse command line arguments
          while [[ $# -gt 0 ]]; do
            case $1 in
              --persistent)
                USE_PERSISTENCE=1
                shift
                ;;
              --persistent-size=*)
                PERSISTENT_SIZE="''${1#*=}"
                USE_PERSISTENCE=1
                shift
                ;;
              --diagnostic)
                DIAGNOSTIC_MODE=1
                shift
                ;;
              --help)
                echo "Usage: test-iso [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --persistent         Create a persistent storage disk for the live environment"
                echo "  --persistent-size=X  Set the size of the persistent storage (default: 8G)"
                echo "  --diagnostic         Run in diagnostic mode with minimal QEMU options"
                echo "  --help               Display this help message"
                exit 0
                ;;
              *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            esac
          done
          
          echo "Building NixOS ISO..."
          nix build .#iso --impure
          
          ISO_PATH=$(find ./result/iso -name "*.iso" | head -n 1)
          
          if [ -z "$ISO_PATH" ]; then
            echo "Error: ISO not found in ./result/iso/"
            exit 1
          fi
          
          echo "Found ISO at: $ISO_PATH"
          
          # Detect system memory and use 1/4 for the VM, with min 2GB and max 8GB
          TOTAL_MEM=$(free -m | grep Mem | awk '{print $2}')
          VM_MEM=$(($TOTAL_MEM / 4))
          VM_MEM=$(($VM_MEM < 2048 ? 2048 : $VM_MEM))
          VM_MEM=$(($VM_MEM > 8192 ? 8192 : $VM_MEM))
          
          # Detect CPU cores and use half for the VM, with min 2 and max 8
          TOTAL_CORES=$(nproc)
          VM_CORES=$(($TOTAL_CORES / 2))
          VM_CORES=$(($VM_CORES < 2 ? 2 : $VM_CORES))
          VM_CORES=$(($VM_CORES > 8 ? 8 : $VM_CORES))
          
          # Create a persistent storage if requested
          PERSISTENCE_ARGS=""
          if [ $USE_PERSISTENCE -eq 1 ]; then
            if [ ! -f "$PERSISTENT_FILE" ]; then
              echo "Creating persistent storage ($PERSISTENT_SIZE)..."
              qemu-img create -f qcow2 "$PERSISTENT_FILE" "$PERSISTENT_SIZE"
            else
              echo "Using existing persistent storage: $PERSISTENT_FILE"
            fi
            PERSISTENCE_ARGS="-drive file=$PERSISTENT_FILE,format=qcow2,if=virtio,discard=unmap"
          fi
          
          echo "Starting VM with $VM_MEM MB RAM and $VM_CORES CPU cores..."
          
          if [ $DIAGNOSTIC_MODE -eq 1 ]; then
            echo "Running in diagnostic mode with minimal options..."
            # Super simple QEMU command for maximum compatibility
            qemu-system-x86_64 \
              -enable-kvm \
              -m $VM_MEM \
              -cdrom "$ISO_PATH" \
              -boot d \
              -serial stdio
          else
            # Launch QEMU with simpler settings for better compatibility
            qemu-system-x86_64 \
              -enable-kvm \
              -m $VM_MEM \
              -smp $VM_CORES \
              -cpu host \
              -vga std \
              -display gtk,grab-on-hover=on \
              -cdrom "$ISO_PATH" \
              -boot d \
              -serial stdio \
              -usb \
              -device usb-tablet \
              -device virtio-net-pci,netdev=net0 \
              -netdev user,id=net0,hostfwd=tcp::2222-:22 \
              $PERSISTENCE_ARGS
          fi
            
          echo ""
          if [ $USE_PERSISTENCE -eq 1 ]; then
            echo "Note: If you want to use persistent storage in the ISO,"
            echo "you need to mount it manually inside the live environment:"
            echo ""
            echo "1. Open a terminal in the live environment"
            echo "2. Run: sudo fdisk -l"
            echo "3. Find the virtio disk (usually /dev/vda)"
            echo "4. Create a partition: sudo fdisk /dev/vda"
            echo "5. Format it: sudo mkfs.ext4 /dev/vda1"
            echo "6. Mount it: sudo mount /dev/vda1 /mnt"
            echo ""
          fi
        '';

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
