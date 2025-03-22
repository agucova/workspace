# NixOS Module Documentation

This directory contains modular configurations for NixOS, designed to be composable and reusable across different configurations.

## Available Modules

- `base.nix` - Core system configuration with AMD 7800X3D optimizations
- `gnome.nix` - GNOME desktop environment setup with optimizations
- `gui-apps.nix` - Common GUI applications
- `hardware.nix` - RTX 4090 GPU configuration with proprietary drivers
- `virtualization.nix` - VM-specific configuration (used instead of hardware.nix)
- `dotfiles.nix` - Chezmoi dotfiles integration
- `ssh.nix` - SSH server configuration
- `mineral.nix` - System hardening with gaming optimizations
- `macos-remap.nix` - macOS-like keyboard remapping with xremap

## macOS-like Keyboard Remapping

The `macos-remap.nix` module provides macOS-like keyboard behavior in GNOME, making the transition between macOS and Linux more seamless. It's based on the implementation from [petrstepanov/gnome-macos-remap-wayland](https://github.com/petrstepanov/gnome-macos-remap-wayland).

### Features

- Swaps Ctrl and Command (⌘) keys
- Makes ⌘+C, ⌘+V, ⌘+X work for copy, paste, cut
- Provides ⌘+Tab for app switching
- Configures ⌘+Left/Right as Home/End
- Alt+Backspace for deleting words
- macOS-like screenshot shortcuts
- Terminal-specific key bindings
- Nautilus file manager shortcuts
- Many more macOS-familiar key combinations

### Usage

The macOS-like keyboard remapping is enabled by default in all configurations. If you need to disable it:

```nix
# In your configuration.nix
services.macos-remap.enable = false;
```

To re-enable it after disabling:

```nix
services.macos-remap.enable = true;
```

### Implementation Details

The module uses the official xremap Nix flake and automatically handles all dependencies:

- Integrates with the xremap-flake to provide the most stable and up-to-date implementation
- Sets up xremap as a user service with GNOME support
- Installs the required GNOME Shell extension
- Configures udev rules for permissions
- Applies GNOME and terminal-specific settings

### Note for VM and Live ISO users

For VM testing and Live ISO environments, the module is included and enabled by default.

In the Live ISO, you can toggle the macOS-like keybindings on/off by running:

```bash
toggle-macos-keybindings
```

This script will disable the remapping if it's active, or enable it if it's been disabled.