# NixOS & Darwin Configuration

A unified Nix Flake-based configuration for both NixOS (Linux) and macOS (Darwin) systems using flake-parts for modular organization.

- **NixOS**: GNOME Desktop environment optimized for AMD Ryzen 7800X3D + NVIDIA RTX 4090 hardware
- **Darwin**: Minimal development environment for MacBook Pro (Apple Silicon)

This configuration uses flake-parts to organize modules, systems and Home Manager configurations in a maintainable structure across both platforms.

## Directory Structure

- `flake.nix` - Main entry point defining inputs and outputs using flake-parts
- `modules/` - Modular system and Home Manager configurations
  - `nixos/` - NixOS-specific modules for Linux systems
  - `darwin/` - Darwin-specific modules for macOS systems
    - `base/` - Core system configuration
    - `desktop/` - GNOME desktop environment
    - `hardware/` - RTX 4090 specific configuration
    - `gui-apps/` - GUI application configurations
    - `vm/` - VM-specific configuration
    - `hardening/` - System hardening settings
    - `macos-remap/` - macOS keyboard remapping
      - `default.nix` - Main configuration
      - `xremap-config.nix` - xremap configuration
    - `ssh/` - SSH configuration
  - `home/` - Home Manager modules
    - `core-shell/` - Core shell configuration
    - `dev-shell/` - Development shell tools
    - `dotfiles/` - Chezmoi and dotfiles integration
    - `macos-remap/` - macOS keyboard remapping for Home Manager
      - `default.nix` - Main configuration
      - `dconf.nix` - GNOME dconf settings
      - `vscode-keybindings.nix` - VS Code keybindings
- `systems/` - System-specific configurations
  - `x86_64-linux/` - Linux systems for x86_64 architecture
    - `hackstation/` - Main workstation configuration
    - `vm/` - VM testing configuration
    - `server/` - Server configuration
  - `aarch64-darwin/` - macOS systems for Apple Silicon
    - `hackbookv5/` - MacBook Pro configuration
- `homes/` - Home Manager configurations
  - `x86_64-linux/` - Linux home configurations
    - `agucova/` - User-specific home configuration

## Implementation Notes

The configuration uses flake-parts to organize outputs and simplify the structure:

1. **Clean Architecture**: All configurations are organized in a logical, consistent structure
2. **Modular Design**: Each aspect of the system is separated into its own module
3. **Per-System Outputs**: Support for different architectures with the perSystem attribute
4. **Typed Outputs**: Strong typing for all flake outputs
5. **Simplified Flake**: Clear separation between per-system and top-level outputs

## Quick Setup Guide

### NixOS (Linux)

1. **Clone the repository**:
   ```bash
   git clone https://github.com/agucova/workspace.git ~/repos/workspace
   cd ~/repos/workspace/nixos
   ```

2. **Hardware Configuration**:
   The setup intelligently imports your system's hardware configuration from `/etc/nixos/hardware-configuration.nix` when available, and falls back to a minimal configuration for testing when it's not present.

3. **Apply the configuration**:
   ```bash
   sudo nixos-rebuild switch --flake .#hackstation --experimental-features 'nix-command flakes' --impure
   ```

   > The `--impure` flag is required to import hardware configurations from outside the flake.

### macOS (Darwin)

1. **Install Nix**:
   ```bash
   curl -L https://nixos.org/nix/install | sh
   ```

2. **Enable flakes**:
   Add to `~/.config/nix/nix.conf`:
   ```
   experimental-features = nix-command flakes
   ```

3. **Clone the repository**:
   ```bash
   git clone git@github.com:agucova/workspace.git ~/Repos/workspace
   cd ~/Repos/workspace/nixos
   ```

4. **Bootstrap nix-darwin**:
   ```bash
   # First time setup (installs nix-darwin)
   nix run nix-darwin -- switch --flake .#hackbookv5
   
   # After initial setup, use:
   darwin-rebuild switch --flake .#hackbookv5
   ```

   The Darwin configuration includes:
   - Core shell tools (Fish, starship, ripgrep, fd, fzf, bat)
   - Development environment (Git, Claude Code, Python with uv, Rust, Nix tooling)
   - System optimizations (dark mode, keyboard settings, Touch ID for sudo)
   - Home Manager integration for user configuration

## Module Design

This configuration is built with modularity in mind, with each module focused on a specific aspect of the system.

### NixOS Modules

#### Core System (`modules/nixos/base`)
- Optimized kernel and CPU settings for AMD Ryzen 7800X3D
- Enhanced memory and swap configuration with zram and backup swapfile
- PipeWire audio with low-latency settings
- Automatic Nix garbage collection
- Core CLI tools and shell setup
- Optimized system-wide build settings to leverage 7800X3D performance

#### Desktop Environment (`modules/nixos/desktop`)
- Clean, minimal GNOME desktop environment
- Performance tuning for GNOME on Wayland
- Optimized compositor settings for gaming
- Dark theme and consistent font rendering
- Selective GNOME extensions for productivity
- Ghostty terminal with GPU acceleration
- Carefully tuned desktop experience with minimal customization

#### Hardware Configuration (`modules/nixos/hardware`)
- NVIDIA RTX 4090 drivers with Wayland support
- Open-source NVIDIA drivers with proper Wayland configuration
- Hardware acceleration for video decoding/encoding
- Power management optimizations
- TPM and secure boot integration
- Multi-monitor support optimized for ultrawide displays

#### VM Configuration (`modules/nixos/vm`)
- VM-specific configuration for testing
- QEMU optimization with 12 CPU cores and 8GB RAM
- CPU host passthrough for better VM performance
- Auto-login for faster testing workflows
- Simplified boot configuration for VM environments
- Debugging tools for diagnosing configuration issues

#### macOS-like Keyboard Remapping (`modules/nixos/macos-remap`)
- Swaps Ctrl and Command keys for familiar macOS feel
- Implements macOS keyboard shortcuts (⌘C, ⌘V, etc.)
- Terminal and application-specific remappings
- Works with both Wayland and X11
- Based on xremap with GNOME integration
- Designed to make transition between macOS and Linux seamless

### Darwin Modules

#### Base Configuration (`modules/darwin/base`)
- Nix configuration with garbage collection
- Core system packages and shell configuration
- Font installation for development
- System-wide shell aliases
- Homebrew integration (optional)

### Cross-Platform Home Modules

#### Core Shell (`modules/home/core-shell`)
- Fish shell with starship prompt
- Modern CLI tools (bat, ripgrep, fd, fzf, lsd)
- Git configuration
- Shell aliases and environment setup

#### Development Shell (`modules/home/dev-shell`)
- Nix tooling (nil, nixd, statix, claude-code)
- Programming languages (Python with uv, Rust, Julia)
- Development utilities

## VM Testing Workflow

Test configuration changes in a VM before applying to your main system:

```bash
# Use the app defined in the flake
nix run .#run-vm --impure

# Or build and run directly using nix
nix build .#nixosConfigurations.vm.config.system.build.vm --impure
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
# Build the hackstation ISO
nix build .#packages.x86_64-linux.iso-hackstation --impure

# Build the VM test ISO
nix build .#packages.x86_64-linux.iso-vm --impure

# Write to USB drive (replace sdX with your USB device, be careful!)
sudo dd if=./result/iso/nixos-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## Bootstrapping Hackstation from NixOS Live Boot

To install the hackstation system from a NixOS live boot environment, you can use the automated script or follow the manual steps.

### Automated Installation

```bash
# 1. Boot from NixOS live media
# 2. Connect to the internet (for WiFi: nmcli device wifi connect "SSID" password "password")
# 3. Enable flakes and install git
export NIX_CONFIG="experimental-features = nix-command flakes"
nix-shell -p git

# 4. Clone the repository
git clone https://github.com/agucova/workspace.git /tmp/workspace
cd /tmp/workspace/nixos

# 5. Run the installation script
sudo ./install.sh
# The script will show available disks and let you choose one
# Alternatively, you can specify the disk directly: sudo ./install.sh /dev/nvme1n1

# 6. After installation completes, reboot
sudo reboot
```

The `install.sh` script will:
- Check internet connectivity
- Verify the disk exists
- Setup disk partitioning with disko (BTRFS + LUKS encryption)
- Generate hardware configuration
- Install NixOS with the hackstation flake
- Set user password

### Manual Installation Steps

If you prefer to perform the installation manually, follow these steps:

#### 1. Boot from NixOS Live Media

Boot your system using a NixOS minimal installation media:
- Download the minimal NixOS ISO from [nixos.org](https://nixos.org/download.html#nixos-iso)
- Create a bootable USB drive following the [instructions here](https://nixos.org/manual/nixos/stable/index.html#sec-booting-from-usb)

#### 2. Connect to the Internet

Ensure you have an internet connection. For wired connections, this should work automatically. For wireless:

```bash
# List available networks
nmcli device wifi list

# Connect to your network
nmcli device wifi connect "SSID" password "password"
```

#### 3. Identify Your Disk

Use `lsblk` to identify the disk you want to install NixOS on:

```bash
lsblk
```

In our case, we'll be using `/dev/nvme1n1`.

#### 4. Clone Your Repository

```bash
# Enable nix commands and flakes
export NIX_CONFIG="experimental-features = nix-command flakes"

# Install git
nix-shell -p git

# Clone your repository
git clone https://github.com/agucova/workspace.git /tmp/workspace
cd /tmp/workspace/nixos
```

#### 5. Partition the Disk with Disko

The configuration includes a disko module for BTRFS with LUKS encryption:

```bash
# Run disko to partition the disk
# Edit the disko-config.nix file first to set your device if needed
sudo vi ./modules/nixos/disk/disko-config.nix

# Then run disko
sudo nix run github:nix-community/disko -- \
  --mode disko \
  ./modules/nixos/disk/disko-config.nix

# Enter your LUKS encryption password when prompted
```

#### 6. Generate Hardware Configuration

Disko will automatically mount the partitions under `/mnt`. Generate the hardware configuration:

```bash
# Generate hardware configuration without filesystems
sudo nixos-generate-config --no-filesystems --root /mnt
```

#### 7. Install NixOS with Your Flake

```bash
# Install NixOS using your flake
sudo nixos-install --flake '.#hackstation' --impure

# Set the root password when prompted
sudo nixos-enter --root /mnt -c 'passwd agucova'
```

#### 8. Reboot into Your New System

```bash
sudo reboot
```

After rebooting, you'll be prompted for your LUKS encryption password, and then your system will boot into your configured NixOS environment. On first boot:

1. Login with the root password you set
2. Set up your user password: `passwd agucova`
3. Clone your repository to a permanent location

## Home Manager Integration

The configuration uses Home Manager for user-specific settings:

- Shell configuration (Fish shell) with aliases and utilities
- Development tools and programming languages
- Git, GitHub CLI, and SSH configuration
- Modern CLI tools (lsd, starship, bat, fastfetch)
- Custom command-not-found handler with nix-index-database
- Editor configuration with Helix, NvChad, and VS Code

Home Manager can also be used standalone:

```bash
# Apply home configuration without changing system
home-manager switch --flake .#agucova@hackstation
```

## Updating Your System

### NixOS

```bash
# Update flake inputs
nix flake update

# Apply the updated configuration
sudo nixos-rebuild switch --flake .#hackstation --impure

# Or only update a specific input
nix flake lock --update-input nixpkgs
```

### macOS

```bash
# Update flake inputs
nix flake update

# Apply the updated configuration
darwin-rebuild switch --flake .#hackbookv5

# Or use the alias from the base module
nrs  # Short for: darwin-rebuild switch --flake ~/Repos/workspace/nixos#hackbookv5
```

## Development Environment

The flake includes a development shell with useful Nix development tools:

```bash
# Enter dev environment
nix develop

# Check Nix code formatting
nixpkgs-fmt --check .

# Lint Nix code
statix check .
```

## flake-parts Usage

This configuration uses flake-parts to organize the flake structure:

1. **perSystem attributes**: All per-system outputs (packages, devShells) are defined in the perSystem section
2. **flake attributes**: System-wide outputs (nixosConfigurations, homeConfigurations) are defined in the flake section
3. **systems**: Defines the list of supported systems (x86_64-linux and aarch64-darwin)

Learn more about flake-parts at [flake.parts](https://flake.parts/)