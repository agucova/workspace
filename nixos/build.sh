#!/usr/bin/env bash
# Helper script for building NixOS COSMIC

set -e

# Check for command
if [ $# -lt 1 ]; then
  echo "Usage: $0 <command>"
  echo "Commands:"
  echo "  vm-build   - Build the VM configuration"
  echo "  vm-run     - Run the VM (after building)"
  echo "  iso-build  - Build the ISO image"
  echo "  clean      - Clean build artifacts"
  exit 1
fi

# Process command
case "$1" in
  vm-build)
    echo "Building VM configuration..."
    nix build .#nixosConfigurations.cosmic-vm.config.system.build.vm
    echo "VM built successfully. Run with './build.sh vm-run'"
    ;;
  vm-run)
    if [ ! -f "./result/bin/run-cosmic-vm-vm" ]; then
      echo "VM not built yet. Building first..."
      nix build .#nixosConfigurations.cosmic-vm.config.system.build.vm
    fi
    echo "Running VM..."
    ./result/bin/run-cosmic-vm-vm
    ;;
  iso-build)
    echo "Building ISO image (this may take a while)..."
    nix build .#nixosConfigurations.cosmic-iso.config.system.build.isoImage
    echo "ISO built successfully. Available at: $(readlink -f result)/iso/"
    ls -lh "$(readlink -f result)/iso/"
    ;;
  clean)
    echo "Cleaning build artifacts..."
    rm -f result
    ;;
  *)
    echo "Unknown command: $1"
    echo "Valid commands: vm-build, vm-run, iso-build, clean"
    exit 1
    ;;
esac