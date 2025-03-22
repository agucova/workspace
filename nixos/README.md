# NixOS with GNOME Desktop

A NixOS configuration with a clean, optimized GNOME Desktop environment located in the `nixos/` subdirectory of this repository.

## Quick Setup Guide

Since this is your personal repository with multiple projects, and NixOS configuration lives in the `nixos/` subdirectory:

1. **Clone the repository (if not already done)**:
   ```bash
   git clone https://github.com/yourusername/workspace.git ~/repos/workspace
   cd ~/repos/workspace
   ```

2. **The configuration directly uses your system's hardware configuration**:
   No need to copy hardware-configuration.nix files, as the setup imports `/etc/nixos/hardware-configuration.nix` directly.

3. **Apply the configuration**:
   ```bash
   cd ~/repos/workspace/nixos
   sudo nixos-rebuild switch --flake .#gnome-nixos --experimental-features 'nix-command flakes' --impure
   ```
   
   > **Note**: The `--impure` flag is required because the configuration imports `/etc/nixos/hardware-configuration.nix`, which is outside the flake. This approach simplifies hardware management by using the system's existing hardware configuration.

That's it! Your system will rebuild with the customized GNOME configuration.

## Customization

To modify your NixOS setup:

- System settings: `~/repos/workspace/nixos/hosts/gnome/configuration.nix`
- GNOME-specific settings: `~/repos/workspace/nixos/modules/gnome.nix`

## Updating Your System

```bash
cd ~/repos/workspace/nixos
nix flake update
sudo nixos-rebuild switch --flake .#gnome-nixos --experimental-features 'nix-command flakes' --impure
```

## Enabling Flakes Permanently

Add this to your configuration.nix:
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Then rebuild your system.

## Hardware Configuration

This configuration directly references `/etc/nixos/hardware-configuration.nix` instead of including a hardware configuration file in the repository. This approach has several benefits:

1. Avoids storing machine-specific hardware details (disk UUIDs, partition layouts) in your Git repository
2. No need to regenerate hardware configuration files when hardware changes
3. Works automatically with the hardware configuration generated during NixOS installation

This design requires using the `--impure` flag with nixos-rebuild because the configuration references a file outside the flake. The `--impure` flag tells Nix it's okay to access files that aren't part of the flake's inputs.

### Hardware Optimizations

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
- SSH server with secure defaults (key-based authentication only)

## Dotfiles Integration

This configuration integrates with your private dotfiles repository using chezmoi and 1Password:

- Installs all needed tools (chezmoi, 1Password CLI, GitHub CLI, uv)
- Provides convenience aliases for common operations
- Uses your existing `dotfiles_setup.py` script for full setup

To set up your dotfiles:
```bash
setup-dotfiles
```

This will run your existing setup script that handles GitHub authentication, 1Password integration, cloning your private repository, and applying configurations.

For regular dotfiles updates:
```bash
chezmoi apply --no-tty
# Or use the alias
cza
```

To add new dotfiles to the repository:
```bash
chezmoi add --no-tty ~/.config/some-file
# Or use the alias
czadd ~/.config/some-file
```

## Nix Code Linting (statix)

To lint and improve your Nix code, you can use statix without installation:

```bash
# Run statix linter on all Nix files
nix run nixpkgs#statix -- check .

# See proposed fixes without changing files
nix run nixpkgs#statix -- fix --dry-run .

# Apply fixes
nix run nixpkgs#statix -- fix .

# List all available lints
nix run nixpkgs#statix -- list

# Get detailed explanation for a specific warning
nix run nixpkgs#statix -- explain W20  # Replace W20 with warning code

# Generate configuration file (to disable specific lints)
nix run nixpkgs#statix -- dump > statix.toml
```