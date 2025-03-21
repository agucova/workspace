# NixOS with COSMIC Desktop

A NixOS configuration for running Pop!_OS's COSMIC Desktop environment, based on [lilyinstarlight's nixos-cosmic](https://github.com/lilyinstarlight/nixos-cosmic).

## Optimized for Your Hardware

This configuration is specifically optimized for:

- **GPU**: NVIDIA RTX 4090
- **CPU**: AMD Ryzen 7 7800X3D
- **Display**: Ultrawide 2K monitor

## Standard NixOS Installation Workflow

This configuration follows the typical NixOS workflow where you:
1. Install NixOS from the official installation media
2. Clone and apply this configuration afterward

### Step 1: Install NixOS

1. Download the official NixOS ISO from [nixos.org](https://nixos.org/download.html)
2. Create a bootable USB with the ISO
3. Boot from the USB and follow the installation steps:
   - Partition your disk
   - Run the installer to set up a basic NixOS system
   - Reboot into your new NixOS installation

### Step 2: Set Up Your Configuration

1. Install Git:
   ```bash
   sudo nix-env -iA nixos.git
   ```

2. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/nixos-config.git ~/.nixos
   cd ~/.nixos
   ```

3. Generate hardware configuration:
   ```bash
   # Generate hardware config for your machine
   sudo nixos-generate-config --show-hardware-config > hosts/cosmic/hardware-configuration.nix
   ```

4. Update the hostname in the flake.nix file:
   ```bash
   # Replace "hostname" with your actual hostname
   # Find your hostname with:
   hostname
   
   # Edit flake.nix to match your hostname
   sed -i 's/hostname/your-actual-hostname/g' flake.nix
   ```

5. Customize the configuration:
   - Edit `hosts/cosmic/configuration.nix` to set your username, timezone, etc.
   - Edit `hosts/cosmic/home.nix` to configure user-specific settings

### Step 3: Apply Your Configuration

Enable flakes functionality:
```bash
# Create nix config directory if it doesn't exist
mkdir -p ~/.config/nix

# Enable experimental features
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
```

Apply the configuration:
```bash
# Build and switch to the new configuration
sudo nixos-rebuild switch --flake ~/.nixos#hostname
```

## Customizing Your Configuration

### System Configuration

- `hosts/cosmic/configuration.nix` contains system-wide settings
- `modules/cosmic.nix` contains COSMIC desktop-specific settings
- Create additional modules in the `modules/` directory for other components

### User Configuration

- `hosts/cosmic/home.nix` contains user-specific configurations managed by Home Manager
- Customize this file to set up your preferred applications and settings

### Terminal Configuration

This setup comes with Ghostty as the primary terminal:

- Ghostty is a fast, feature-rich GPU-accelerated terminal
- Configured via Home Manager in `hosts/cosmic/home.nix`
- Latest version from the upstream Ghostty repository
- Alacritty is included as a backup terminal

## Updating Your System

To update your packages and configurations:

```bash
# Update the flake inputs
cd ~/.nixos
nix flake update

# Apply the updated configuration
sudo nixos-rebuild switch --flake .#hostname
```

## Hardware-Specific Optimizations

### RTX 4090 Support

This configuration includes optimized settings for NVIDIA RTX 4090 GPUs:

- Uses the latest stable NVIDIA driver
- Enables proper Wayland support via GBM
- Configures power management
- Sets up proper kernel parameters for COSMIC compatibility
- Includes a fallback X11 session option if needed

If you encounter issues with Wayland, you can select the X11 session at login.

### AMD Ryzen 7 7800X3D

CPU optimizations include:

- Performance governor for maximum CPU performance
- AMD microcode updates for stability and security
- KVM virtualization support for AMD processors
- Zen 4 architecture optimizations

### Ultrawide Monitor

The configuration uses default scaling, which should work well with:
- Ultrawide monitors at 2K/3K resolution
- Standard DPI settings (no scaling applied)

If you need to adjust scaling after testing, you can easily add those settings later.

## COSMIC-Specific Notes

- Support for COSMIC on NixOS is still in development
- For issues related to COSMIC itself, refer to the [nixos-cosmic repository](https://github.com/lilyinstarlight/nixos-cosmic)
- For Flatpak support with COSMIC Store, run this after installation:
  ```bash
  flatpak remote-add --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  ```

## Additional Resources

- `COMMANDS.md` - Quick reference for common NixOS commands
- `troubleshooting.md` - Solutions for common issues with this setup

## Directory Structure

- `flake.nix`: Main entry point for the Nix flake
- `hosts/`: Machine-specific configurations
  - `cosmic/`: COSMIC desktop configuration
    - `configuration.nix`: Main system configuration
    - `home.nix`: Home Manager user configuration
    - `hardware-configuration.nix`: Auto-generated hardware configuration
- `modules/`: Reusable NixOS modules
  - `cosmic.nix`: COSMIC desktop module