# Disko BTRFS + LUKS Configuration

This module implements a declarative disk configuration using [disko](https://github.com/nix-community/disko) for NixOS. It creates a BTRFS filesystem with LUKS encryption and subvolumes for different mount points.

## Features

- UEFI boot partition
- LUKS encryption for all non-boot partitions
- BTRFS filesystem with zstd compression
- Separate subvolumes for:
  - `/` (root)
  - `/home`
  - `/nix`
  - `/persist` (for impermanence setup)
  - `/var/log`
  - `/swap` (for swapfile)
- Support for FIDO2/YubiKey for unlocking the LUKS partition
- Hibernation support via swapfile

## Usage

Enable the module in your NixOS configuration:

```nix
{
  myDisko = {
    enable = true;
    device = "/dev/nvme1n1";  # Change to your device
    swapSize = "32G";         # Adjust based on your needs
  };
}
```

## Initial Installation

When installing NixOS from scratch using disko, follow these steps:

1. Boot from a NixOS installation media
2. Clone your flake repository
3. Partition the disk with disko:

```bash
sudo nix run github:nix-community/disko -- --mode disko /path/to/workspace/nixos/modules/nixos/disk/default.nix --arg device '"/dev/nvme1n1"'
```

4. Generate the hardware configuration:

```bash
nixos-generate-config --root /mnt
```

5. Install NixOS using your flake:

```bash
nixos-install --flake /path/to/workspace/nixos#hackstation --impure
```

6. Reboot and enter your LUKS password when prompted

## FIDO2/YubiKey Setup

To configure a YubiKey for LUKS decryption:

1. Boot into your system
2. Enroll your YubiKey:

```bash
sudo -E -s systemd-cryptenroll --fido2-device=auto /dev/nvme1n1p2
```

3. During enrollment, you'll need to press the button on your YubiKey
4. On next boot, you can use your YubiKey for decryption

## Hibernation

The module sets up hibernation support with a swapfile. The resume_offset is configured for a typical 2TB drive. If you have a different drive size or configuration, you may need to adjust the offset:

1. After installation, boot into your system
2. Find the offset with:

```bash
sudo filefrag -v /swap/swapfile | head -n4 | tail -n1 | awk '{print $4}' | tr -d '..'
```

3. Update the `resume_offset` value in the disk module if needed

## Impermanence

This disk layout supports impermanence setups with the `/persist` subvolume. Refer to the impermanence module documentation for setting up a stateless system with persistent data.