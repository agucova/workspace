# NixOS with GNOME Desktop

A Nix Flake-based NixOS configuration with GNOME Desktop environment optimized for AMD Ryzen 7800X3D + NVIDIA RTX 4090 hardware.

This configuration follows the Snowfall Lib conventions for organized, discoverable, and maintainable Nix configurations.

## Snowfall Lib Structure

This repository fully implements the Snowfall Lib structure to provide automatic module discovery and organization:

### Directory Structure
- `flake.nix` - Main entry point defining inputs and outputs with Snowfall configuration
- `modules/` - Modular NixOS and Home Manager configurations (auto-discovered)
  - `nixos/` - NixOS-specific modules for system configuration
    - Each directory here becomes an available module
  - `home/` - Home Manager modules for user environment
    - Each directory here becomes an available module
- `systems/` - System-specific configurations (auto-discovered)
  - `x86_64-linux/` - Linux systems for x86_64 architecture
    - `gnome-nixos/` - Main workstation configuration 
    - `vm-test/` - VM testing configuration
- `homes/` - Home Manager configurations (auto-discovered)
  - `x86_64-linux/` - Linux home configurations
    - `agucova/` - User-specific home configuration
- `packages/` - Custom package definitions (auto-discovered)
- `overlays/` - Custom overlays (auto-discovered)
- `lib/` - Custom library functions (auto-discovered)

The primary advantage of using Snowfall Lib is automatic discovery of modules, packages, and more based on directory structure, removing the need for manual importing and reducing configuration complexity.

## Implementation Notes

The configuration uses a direct approach with standard Nix flake outputs while maintaining the Snowfall directory structure. This provides several benefits:

1. **Clean Organization**: All configurations are organized in a logical, consistent structure
2. **Modular Design**: Each aspect of the system is separated into its own module
3. **Explicit Control**: Direct definition of outputs allows fine-grained control
4. **Easy Path Resolution**: Relative paths between components simplify maintenance
5. **VM Testing Support**: Built-in configuration for testing in a virtual machine

## Repository Structure

This repository follows a structured approach based on Snowfall Lib conventions:

### Current Working Structure
- `flake.nix` - Main entry point defining inputs and outputs for the configuration
- `modules/` - Modular NixOS configuration files with namespaces
  - `nixos/` - NixOS-specific modules
    - `base/` - Core system configuration
    - `gnome/` - GNOME desktop environment
    - `hardware/` - RTX 4090 specific configuration
    - `gui-apps/` - GUI application configurations
    - `virtualization/` - VM-specific configuration
    - `dotfiles/` - Chezmoi and dotfiles integration
    - `ssh/` - SSH configuration
    - `mineral/` - System hardening settings
    - `macos-remap/` - macOS keyboard remapping
  - `home/` - Home Manager modules
    - `base/` - Core home configuration
- `systems/` - System-specific configurations
  - `x86_64-linux/` - Linux systems for x86_64 architecture
    - `gnome-nixos/` - Main workstation configuration
    - `vm-test/` - VM testing configuration
- `homes/` - Home Manager configurations
  - `x86_64-linux/` - Linux home configurations
    - `agucova/` - User-specific home configuration
- `packages/` - Custom package definitions
  - `run-vm/` - VM runner script
  - `vm-image/` - VM image generator
  - `iso-gnome/` - ISO installer for GNOME
  - `iso-vm/` - ISO installer for VM test

The configuration now follows a pure Snowfall structure, with all legacy paths removed.

## Quick Setup Guide

1. **Clone the repository**:
   ```bash
   git clone https://github.com/agucova/workspace.git ~/repos/workspace
   cd ~/repos/workspace/nixos
   ```

2. **Hardware Configuration**:
   The setup intelligently imports your system's hardware configuration from `/etc/nixos/hardware-configuration.nix` when available, and falls back to a minimal configuration for testing when it's not present.

3. **Apply the configuration**:
   ```bash
   sudo nixos-rebuild switch --flake /path/to/workspace/nixos#gnome-nixos --experimental-features 'nix-command flakes'
   ```

   > You can also use the `--impure` flag for more flexible evaluation.

## Module Design

This configuration is built with modularity in mind, now organized with Snowfall Lib's structure:

### Core System (`modules/nixos/base`)
- Optimized kernel and CPU settings for AMD Ryzen 7800X3D
- Enhanced memory and swap configuration with zram and backup swapfile
- PipeWire audio with low-latency settings
- Automatic Nix garbage collection
- Core CLI tools and shell setup
- Optimized system-wide build settings to leverage 7800X3D performance

### Hardware Configuration (`modules/nixos/hardware`)
- NVIDIA RTX 4090 drivers with Wayland support
- Open-source NVIDIA drivers with proper Wayland configuration
- Hardware acceleration for video decoding/encoding
- Power management optimizations
- TPM and secure boot integration
- Multi-monitor support optimized for ultrawide displays

### GNOME Desktop (`modules/nixos/gnome`)
- Clean, minimal GNOME desktop environment
- Performance tuning for GNOME on Wayland
- Optimized compositor settings for gaming
- Dark theme and consistent font rendering
- Selective GNOME extensions for productivity
- Ghostty terminal with GPU acceleration
- Carefully tuned desktop experience with minimal customization

### Virtualization (`modules/nixos/virtualization`)
- VM-specific configuration for testing
- QEMU optimization with 12 CPU cores and 8GB RAM
- CPU host passthrough for better VM performance
- Auto-login for faster testing workflows
- Simplified boot configuration for VM environments
- Debugging tools for diagnosing configuration issues

### macOS-like Keyboard Remapping (`modules/nixos/macos-remap`)
- Swaps Ctrl and Command keys for familiar macOS feel
- Implements macOS keyboard shortcuts (⌘C, ⌘V, etc.)
- Terminal and application-specific remappings
- Works with both Wayland and X11
- Based on xremap with GNOME integration
- Designed to make transition between macOS and Linux seamless

### System Hardening (`modules/nixos/mineral`)
- Security hardening with nix-mineral
- Firewall configuration with gaming compatibility
- Hardened mount options and sysctl settings
- Enhanced privacy with MAC address randomization
- Security features tuned to minimize gaming performance impact
- System hardening that doesn't interfere with GPU drivers or anti-cheat systems

### Dotfiles Integration (`modules/nixos/dotfiles`)
- Chezmoi and 1Password integration
- GitHub CLI and authentication setup
- Convenience aliases for dotfiles management
- Automatic dotfiles application through Home Manager
- Integration with your existing dotfiles setup

### SSH Configuration (`modules/nixos/ssh`)
- Secure SSH server configuration
- Key-based authentication only
- Optimized cipher selection
- Rate limiting and hardening
- Proper service setup with firewall rules

### GUI Applications (`modules/nixos/gui-apps`)
- Curated set of GUI applications
- Flatpak support with proper font/icon integration
- Development tools and productivity software
- Multimedia applications with hardware acceleration
- Gaming-related tools and compatibility layers

## VM Testing Workflow

Test configuration changes in a VM before applying to your main system:

```bash
# Build and run the VM with our simple helper script
./run-vm.sh

# Or build and run directly using nix
nix build .#nixosConfigurations.vm-test.config.system.build.vm --impure
result/bin/run-nixos-vm
```

The VM configuration:
- Uses 12 CPU cores and 8GB RAM for better performance
- Includes CPU host passthrough for optimal performance
- Features virtio-keyboard-pci and virtio-serial-pci for better input support
- Automatically logs in with the same user config as your main system
- Has the same GNOME setup and macOS-like keyboard remapping

## Creating a Bootable ISO

Create a bootable ISO with your configuration to install on new machines:

```bash
# Build the GNOME hardware ISO
nix build .#iso-gnome --impure

# Build the VM test ISO (for testing the VM config in a live environment)
nix build .#iso-vm --impure

# Write to USB drive (replace sdX with your USB device, be careful!)
sudo dd if=./result/iso/nixos-gnome-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## Design Philosophy

This configuration embodies several core design principles:

1. **Modularity**: Using Snowfall Lib's organizational structure makes each aspect of the system easier to understand and maintain.

2. **Hardware Optimization**: Specifically tuned for AMD Ryzen 7800X3D + NVIDIA RTX 4090 hardware, with fallbacks for VM testing.

3. **Ergonomics**: User experience enhancements like macOS-like keyboard remapping and GNOME optimizations make daily use comfortable.

4. **Security with Performance**: System hardening is applied without sacrificing gaming performance or compatibility.

5. **Testing Workflow**: VM-based testing and ISO generation allow easy validation of changes before applying to the main system.

6. **Flake-based Reproducibility**: Using Nix Flakes ensures the system can be consistently reproduced across machines.

7. **Dotfiles Integration**: Seamless connection with your existing dotfiles setup for complete configuration management.

## Home Manager Integration

The configuration uses Home Manager for user-specific settings, now structured using Snowfall Lib:

- Shell configuration (Fish shell) with aliases and utilities
- Development tools and programming languages (Go, Rust, Python, Node.js, Julia)
- Git, GitHub CLI, and SSH configuration
- Modern CLI tools (lsd, starship, bat, fastfetch)
- Custom command-not-found handler with nix-index-database and comma
- Editor configuration with Helix, NvChad, and VS Code
- Consistent environment across user accounts

Home Manager can also be used standalone:

```bash
# Apply home configuration without changing system
nix run home-manager/master -- switch --flake .#agucova
```

## Updating Your System

```bash
# Update flake inputs
nix flake update

# Apply the updated configuration
sudo nixos-rebuild switch --flake .#gnome-nixos --experimental-features 'nix-command flakes' --impure

# Or only update a specific input
nix flake lock --update-input nixpkgs
```

## Nix Code Linting

Use statix to lint and fix common anti-patterns in Nix code:

```bash
# Run statix linter on all Nix files
nix run nixpkgs#statix -- check nixos/

# See proposed fixes without changing files
nix run nixpkgs#statix -- fix --dry-run nixos/

# Apply fixes (be careful!)
nix run nixpkgs#statix -- fix nixos/

# List all available lints
nix run nixpkgs#statix -- list

# Get explanation for a specific warning code
nix run nixpkgs#statix -- explain W20
```

Key lints include:
- W20: Repeated attribute keys
- W03/W04: Manual inherit patterns
- W07: Eta reductions
- W08: Useless parentheses

## Performance Tuning

The configuration includes several performance optimizations:

- CPU-specific kernel parameters for AMD 7800X3D
- Memory management with zram and optimized swap
- GPU acceleration for NVIDIA RTX 4090
- Build performance enhancements for Nix
- Low-latency audio configuration
- Wayland optimization for reduced input lag
- Game-friendly security settings