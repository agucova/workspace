# NixOS with GNOME Desktop

A NixOS configuration with a clean, optimized GNOME Desktop environment located in the `nixos/` subdirectory of this repository.

## Quick Setup Guide

Since this is your personal repository with multiple projects, and NixOS configuration lives in the `nixos/` subdirectory:

1. **Clone the repository (if not already done)**:
   ```bash
   git clone https://github.com/yourusername/workspace.git ~/repos/workspace
   cd ~/repos/workspace
   ```

2. **Copy your hardware configuration**:
   ```bash
   sudo cp /etc/nixos/hardware-configuration.nix ~/repos/workspace/nixos/hosts/gnome/
   ```

3. **Apply the configuration**:
   ```bash
   cd ~/repos/workspace/nixos
   sudo nixos-rebuild switch --flake .#gnome-nixos --experimental-features 'nix-command flakes'
   ```

That's it! Your system will rebuild with the customized GNOME configuration.

## Customization

To modify your NixOS setup:

- System settings: `~/repos/workspace/nixos/hosts/gnome/configuration.nix`
- GNOME-specific settings: `~/repos/workspace/nixos/modules/gnome.nix`

## Updating Your System

```bash
cd ~/repos/workspace/nixos
nix flake update
sudo nixos-rebuild switch --flake .#gnome-nixos --experimental-features 'nix-command flakes'
```

## Enabling Flakes Permanently

Add this to your configuration.nix:
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Then rebuild your system.

## Hardware Optimizations

This configuration includes optimizations for:

- **NVIDIA RTX 4090** - Proprietary drivers with proper Wayland support
- **AMD Ryzen 7 7800X3D** - Performance governor and microcode updates
- **Ultrawide monitors** - Default scaling that works well with 2K/3K ultrawides

## GNOME Features

This configuration includes:
- Clean GNOME desktop with minimal customization
- GNOME Tweaks, dconf-editor, and Shell Extensions
- Ghostty terminal with GPU acceleration
- Flatpak support for additional applications