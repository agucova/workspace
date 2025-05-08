#!/usr/bin/env bash
set -e

# Simple NixOS Recovery Mount Script

# Default values
DISK="/dev/nvme0n1"
MOUNT_POINT="/mnt"
ENTER=0

# Basic argument parsing
if [ "$1" = "--enter" ]; then
  ENTER=1
fi

if [ "$1" = "--disk" ] && [ -n "$2" ]; then
  DISK="$2"
  shift 2
  if [ "$1" = "--enter" ]; then
    ENTER=1
  fi
fi

# Determine partition names based on disk name
if [[ $DISK == *"nvme"* ]] || [[ $DISK == *"mmcblk"* ]]; then
  BOOT_PART="${DISK}p1"
  LUKS_PART="${DISK}p2"
else
  BOOT_PART="${DISK}1"
  LUKS_PART="${DISK}2"
fi

echo "Mounting NixOS from $DISK to $MOUNT_POINT"

# Open LUKS container if not already open
if [ ! -e /dev/mapper/cryptroot ]; then
  echo "Opening LUKS container..."
  cryptsetup open $LUKS_PART cryptroot
fi

# Create mount point
mkdir -p $MOUNT_POINT

# Temporarily mount BTRFS root to create subvolumes mount points
echo "Creating mount points..."
mount -t btrfs /dev/mapper/cryptroot $MOUNT_POINT
mkdir -p $MOUNT_POINT/boot
mkdir -p $MOUNT_POINT/home
mkdir -p $MOUNT_POINT/nix
mkdir -p $MOUNT_POINT/persist
mkdir -p $MOUNT_POINT/var/log
mkdir -p $MOUNT_POINT/swap
umount $MOUNT_POINT

# Mount all subvolumes with their proper options
echo "Mounting subvolumes..."
mount -o subvol=root,compress=zstd,noatime /dev/mapper/cryptroot $MOUNT_POINT
mount -o subvol=home,compress=zstd,noatime /dev/mapper/cryptroot $MOUNT_POINT/home
mount -o subvol=nix,compress=zstd,noatime /dev/mapper/cryptroot $MOUNT_POINT/nix
mount -o subvol=persist,compress=zstd,noatime /dev/mapper/cryptroot $MOUNT_POINT/persist
mount -o subvol=log,compress=zstd,noatime /dev/mapper/cryptroot $MOUNT_POINT/var/log

# Mount the boot partition
mount $BOOT_PART $MOUNT_POINT/boot

echo "System mounted at $MOUNT_POINT"

# Enter the system if requested
if [ $ENTER -eq 1 ]; then
  echo "Entering system with nix-enter..."
  exec nix-enter --root $MOUNT_POINT
else
  echo "Done. To enter the system, run:"
  echo "nix-enter --root $MOUNT_POINT"
fi
