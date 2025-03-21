# NixOS + COSMIC Command Reference

A quick reference for common commands you'll use with your NixOS + COSMIC setup.

## System Management

```bash
# Apply system configuration changes
sudo nixos-rebuild switch --flake ~/.nixos#hostname

# Test changes without making them permanent
sudo nixos-rebuild test --flake ~/.nixos#hostname

# Build but don't apply (check for errors)
sudo nixos-rebuild dry-build --flake ~/.nixos#hostname

# Update all packages (pulls latest from nixpkgs)
cd ~/.nixos && nix flake update

# Roll back to previous generation
sudo nixos-rebuild switch --rollback

# See system generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Clean up old generations (keep last 5)
sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system
sudo nix-collect-garbage -d
```

## Package Management

```bash
# Install a package for your user only
nix-env -iA nixos.package-name

# Install a package temporarily in a shell
nix-shell -p package-name

# Search for packages
nix search nixpkgs package-name

# Show package information
nix-env -qa --description package-name
```

## Flatpak Management (for COSMIC Store)

```bash
# Add Flathub repository
flatpak remote-add --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install a Flatpak app
flatpak install flathub org.application.Name

# Run a Flatpak app
flatpak run org.application.Name

# Update all Flatpak apps
flatpak update
```

## NixOS Configuration

```bash
# Edit main system configuration
nano ~/.nixos/hosts/cosmic/configuration.nix

# Edit COSMIC desktop settings
nano ~/.nixos/modules/cosmic.nix

# Edit user-specific settings
nano ~/.nixos/hosts/cosmic/home.nix

# Show current hardware configuration
nixos-generate-config --show-hardware-config
```

## NVIDIA-Specific Commands

```bash
# Check NVIDIA driver status
nvidia-smi

# Check OpenGL renderer
glxinfo | grep "OpenGL renderer"

# Check Vulkan support
vulkaninfo --summary

# Check if using Wayland or X11
echo $XDG_SESSION_TYPE
```

## Troubleshooting

```bash
# View system logs
journalctl -b

# View user session logs
journalctl --user -b

# Check X11/Wayland logs
nano ~/.local/share/xorg/Xorg.0.log
journalctl -b | grep cosmic-comp

# Check if services are running
systemctl status display-manager
systemctl --user status cosmic-comp
```

## Working with Nix Flakes

```bash
# View flake inputs
nix flake metadata ~/.nixos

# Update a specific input
nix flake lock --update-input nixos-cosmic ~/.nixos

# Show flake outputs
nix flake show ~/.nixos
```

Remember to replace `hostname` with your actual system hostname in the commands above.