# NixOS Module Documentation

This directory contains modular configurations for NixOS, designed to be composable and reusable across different configurations.

## Available Modules

### System-level modules (nixos/)

- `base/` - Core system configuration with AMD 7800X3D optimizations
- `desktop/` - GNOME desktop environment setup with optimizations
- `gui-apps/` - Common GUI applications and 1Password integration
- `hardware/` - RTX 4090 GPU configuration with proprietary drivers
- `disk/` - BTRFS with LUKS disk configuration
- `vm/` - VM-specific configuration (used instead of hardware.nix)
- `ssh/` - SSH server configuration
- `hardening/` - System hardening with gaming optimizations
- `macos-remap/` - macOS-like keyboard remapping with xremap

### User-level modules (home/)

- `core-shell/` - Basic shell configuration
- `dev-shell/` - Development environment setup
- `desktop-settings/` - User-specific desktop settings
- `dotfiles/` - User configuration files
- `macos-remap/` - User-specific keyboard remapping
- `1password/` - 1Password CLI, SSH and Git integration

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

To enable or disable the macOS-like keyboard remapping:

```nix
# In your system configuration
myMacosRemap.enable = true;  # or false to disable
```

The home-manager module is automatically enabled when imported and provides additional VS Code and GNOME settings.

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