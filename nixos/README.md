# NixOS with GNOME Desktop

A NixOS configuration for running a clean, optimized GNOME Desktop environment.

## Quick Setup Guide

**Starting with a fresh NixOS install (either from graphical installer or minimal):**

1. **Install git and clone this repo**:
   ```bash
   nix-shell -p git
   git clone https://github.com/yourusername/nixos-config.git ~/.nixos
   cd ~/.nixos
   ```

2. **Copy your hardware configuration**:
   ```bash
   sudo cp /etc/nixos/hardware-configuration.nix nixos/hosts/cosmic/
   ```

3. **Apply the configuration**:
   ```bash
   sudo nixos-rebuild switch --flake .#gnome-nixos --experimental-features 'nix-command flakes'
   ```

That's it! Your system will rebuild with the customized GNOME configuration.

## Hardware Optimizations

This configuration includes optimizations for:

- **NVIDIA RTX 4090** - Proprietary drivers with proper Wayland support
- **AMD Ryzen 7 7800X3D** - Performance governor and microcode updates
- **Ultrawide monitors** - Default scaling that works well with 2K/3K ultrawides

## Customization

- Edit `hosts/cosmic/configuration.nix` for system-wide settings
- Edit `modules/gnome.nix` for GNOME-specific settings

## Updating Your System

```bash
cd ~/.nixos
nix flake update
sudo nixos-rebuild switch --flake .#gnome-nixos --experimental-features 'nix-command flakes'
```

## Enabling Flakes Permanently

Add this to your configuration.nix:
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

## GNOME Features

This configuration includes:
- Clean GNOME desktop with minimal customization
- GNOME Tweaks, dconf-editor, and Shell Extensions
- Ghostty terminal with GPU acceleration
- Flatpak support for additional applications

## Advanced Installation (Manual Method)

For installation from a live USB environment:

1. Boot from NixOS installation media and prepare partitions
2. Mount your target partitions to /mnt
3. Clone this repo: `git clone https://github.com/yourusername/nixos-config.git /tmp/config`
4. Generate hardware config: `nixos-generate-config --root /mnt`
5. Copy hardware config: `cp /mnt/etc/nixos/hardware-configuration.nix /tmp/config/nixos/hosts/cosmic/`
6. Install NixOS: `nixos-install --flake /tmp/config#gnome-nixos --experimental-features 'nix-command flakes'`
7. Reboot and enjoy!