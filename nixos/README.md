# NixOS with GNOME Desktop

A Nix Flake-based NixOS configuration with GNOME Desktop environment optimized for AMD Ryzen 7800X3D + NVIDIA RTX 4090 hardware.

## Repository Structure

- `flake.nix` - Main entry point defining inputs and outputs for the configuration
- `modules/` - Modular NixOS configuration files (described in detail below)
- `hosts/` - Host-specific configurations:
  - `gnome/` - Main workstation configuration with full hardware support
  - `vm-test/` - VM testing configuration for development
  - `common/` - Shared configuration files like minimal-hardware.nix

## Quick Setup Guide

1. **Clone the repository**:
   ```bash
   git clone https://github.com/agucova/workspace.git ~/repos/workspace
   cd ~/repos/workspace/nixos
   ```

2. **The configuration uses your system's hardware configuration**:
   No need to copy hardware-configuration.nix files, as the setup imports `/etc/nixos/hardware-configuration.nix` directly.

3. **Apply the configuration**:
   ```bash
   sudo nixos-rebuild switch --flake .#gnome-nixos --experimental-features 'nix-command flakes' --impure
   ```

   > The `--impure` flag is required because the configuration imports `/etc/nixos/hardware-configuration.nix`.

## Module Design

This configuration is built with modularity in mind, separating functionality into distinct Nix modules:

### Core System (`base.nix`)
- Optimized kernel and CPU settings for AMD Ryzen 7800X3D
- Enhanced memory and swap configuration with zram and backup swapfile
- PipeWire audio with low-latency settings
- Automatic Nix garbage collection
- Core CLI tools and shell setup
- Optimized system-wide build settings to leverage 7800X3D performance

### Hardware Configuration (`hardware.nix`)
- NVIDIA RTX 4090 drivers with Wayland support
- Open-source NVIDIA drivers with proper Wayland configuration
- Hardware acceleration for video decoding/encoding
- Power management optimizations
- TPM and secure boot integration
- Multi-monitor support optimized for ultrawide displays

### GNOME Desktop (`gnome.nix`)
- Clean, minimal GNOME desktop environment
- Performance tuning for GNOME on Wayland
- Optimized compositor settings for gaming
- Dark theme and consistent font rendering
- Selective GNOME extensions for productivity
- Ghostty terminal with GPU acceleration
- Carefully tuned desktop experience with minimal customization

### Virtualization (`virtualization.nix`)
- VM-specific configuration for testing
- QEMU optimization with 12 CPU cores and 8GB RAM
- CPU host passthrough for better VM performance
- Auto-login for faster testing workflows
- Simplified boot configuration for VM environments
- Debugging tools for diagnosing configuration issues

### macOS-like Keyboard Remapping (`macos-remap.nix`)
- Swaps Ctrl and Command keys for familiar macOS feel
- Implements macOS keyboard shortcuts (⌘C, ⌘V, etc.)
- Terminal and application-specific remappings
- Works with both Wayland and X11
- Based on xremap with GNOME integration
- Designed to make transition between macOS and Linux seamless

### System Hardening (`mineral.nix`)
- Security hardening with nix-mineral
- Firewall configuration with gaming compatibility
- Hardened mount options and sysctl settings
- Enhanced privacy with MAC address randomization
- Security features tuned to minimize gaming performance impact
- System hardening that doesn't interfere with GPU drivers or anti-cheat systems

### Dotfiles Integration (`dotfiles.nix`)
- Chezmoi and 1Password integration
- GitHub CLI and authentication setup
- Convenience aliases for dotfiles management
- Automatic dotfiles application through Home Manager
- Integration with your existing dotfiles setup

### SSH Configuration (`ssh.nix`)
- Secure SSH server configuration
- Key-based authentication only
- Optimized cipher selection
- Rate limiting and hardening
- Proper service setup with firewall rules

### GUI Applications (`gui-apps.nix`)
- Curated set of GUI applications
- Flatpak support with proper font/icon integration
- Development tools and productivity software
- Multimedia applications with hardware acceleration
- Gaming-related tools and compatibility layers

## VM Testing Workflow

Test configuration changes in a VM before applying to your main system:

```bash
# Build and run the VM with all optimizations (recommended approach)
nix run .#run-vm --impure

# Alternative: Standard build and run
cd /path/to/workspace/nixos
nix build .#vm-image --impure
./result/bin/run-*-vm
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

1. **Modularity**: Each aspect of the system is in its own module, making changes easier to understand and maintain.

2. **Hardware Optimization**: Specifically tuned for AMD Ryzen 7800X3D + NVIDIA RTX 4090 hardware, with fallbacks for VM testing.

3. **Ergonomics**: User experience enhancements like macOS-like keyboard remapping and GNOME optimizations make daily use comfortable.

4. **Security with Performance**: System hardening is applied without sacrificing gaming performance or compatibility.

5. **Testing Workflow**: VM-based testing and ISO generation allow easy validation of changes before applying to the main system.

6. **Flake-based Reproducibility**: Using Nix Flakes ensures the system can be consistently reproduced across machines.

7. **Dotfiles Integration**: Seamless connection with your existing dotfiles setup for complete configuration management.

## Home Manager Integration

The configuration uses Home Manager for user-specific settings:

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

For more detailed commands and usage examples, see [COMMANDS.md](COMMANDS.md).
