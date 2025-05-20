#!/usr/bin/env bash
# NixOS installation script for hackstation configuration
# Run this after booting from NixOS live ISO and cloning the repository

set -euo pipefail # Exit on error, undefined vars, and pipeline failures

# Enable Nix features
export NIX_CONFIG="experimental-features = nix-command flakes"

# Check if we're running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# 1. Verify internet connection
echo "=== Checking internet connection ==="
if ! ping -c 1 github.com > /dev/null 2>&1; then
  echo "WARNING: Cannot verify internet connection."
  echo "The installation requires internet access to download packages."
  echo "For WiFi: nmcli device wifi connect \"SSID\" password \"password\""
  echo "Press Enter to continue anyway or Ctrl+C to abort..."
  read
fi

# Pre-validation step to check if the NixOS configuration builds correctly
echo "=== Pre-validation: Testing NixOS configuration build ==="
echo "This will check if the configuration builds correctly before any disk changes."
echo "This can take a few minutes but will save time if there are configuration errors."

if ! nix build --no-link --impure '.#nixosConfigurations.hackstation.config.system.build.toplevel'; then
  echo "ERROR: NixOS configuration failed to build."
  echo "Please fix the configuration errors before running the installation script."
  exit 1
fi
echo "Pre-validation successful! The NixOS configuration builds correctly."

# Show available disks and select one
echo "=== Available disks ==="
lsblk -d -o NAME,SIZE,MODEL | grep -v loop
echo

# Default disk or first argument
DEFAULT_DISK="/dev/nvme0n1"
DISK=${1:-""}

# If no disk specified, prompt for selection
if [ -z "$DISK" ]; then
  echo "Enter disk to install to (e.g., /dev/nvme0n1, /dev/nvme1n1, /dev/sda):"
  read -r DISK
  
  # If still empty, use default
  if [ -z "$DISK" ]; then
    DISK="$DEFAULT_DISK"
    echo "Using default disk: $DISK"
  fi
fi

# Ensure disk path has /dev/ prefix
if [[ "$DISK" != /dev/* ]]; then
  DISK="/dev/$DISK"
fi

echo "=== NixOS Hackstation Installation ==="
echo "This script will install NixOS on $DISK"
echo "WARNING: This will erase all data on $DISK"
echo "The configuration has been pre-validated and should install correctly."
echo "Press Enter to continue or Ctrl+C to abort..."
read

# 2. Verify the disk exists
echo "=== Verifying disk $DISK ==="
if ! lsblk "$DISK" > /dev/null 2>&1; then
  echo "Disk $DISK not found. Available disks:"
  lsblk -d -o NAME,SIZE,MODEL
  exit 1
fi

# 3. Setup disk with disko
echo "=== Setting up disk with disko ==="
sed -i "s|/dev/nvme1n1|$DISK|g" ./modules/nixos/disk/disko-config.nix
echo "Disk configuration updated. Continuing with partitioning..."

nix run github:nix-community/disko -- \
  --mode disko \
  ./modules/nixos/disk/disko-config.nix

# 4. Generate hardware configuration without filesystems
echo "=== Generating hardware configuration ==="
nixos-generate-config --no-filesystems --root /mnt

# 5. Install NixOS with the flake
echo "=== Installing NixOS ==="
nixos-install --flake '.#hackstation' --impure

# 6. Set password for the user
echo "=== Setting user password ==="
echo "Please set a password for user 'agucova':"
nixos-enter --root /mnt -c 'passwd agucova'

echo "=== Installation complete ==="
echo "You can now reboot into your new system:"
echo "sudo reboot"