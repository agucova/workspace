# NixOS + GNOME Command Reference

A quick reference for common commands you'll use with your NixOS + GNOME setup.

## System Management

```bash
# Apply system configuration changes
sudo nixos-rebuild switch --flake ~/repos/workspace/nixos#gnome-nixos --impure

# Test changes without making them permanent
sudo nixos-rebuild test --flake ~/repos/workspace/nixos#gnome-nixos --impure

# Build but don't apply (check for errors)
sudo nixos-rebuild dry-build --flake ~/repos/workspace/nixos#gnome-nixos --impure

# Update all packages (pulls latest from nixpkgs)
cd ~/repos/workspace/nixos && nix flake update

# Roll back to previous generation
sudo nixos-rebuild switch --rollback

# See system generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Clean up old generations (keep last 5)
sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system
sudo nix-collect-garbage -d

# Build VM for testing
cd ~/repos/workspace/nixos && nix run .#run-vm --impure

# Build ISO image (takes time)
cd ~/repos/workspace/nixos && nix run .#fast-build -- iso
# The ISO will be available at: ./result/iso/nixos-gnome-*.iso

# Write ISO to USB drive with dd (replace sdX with your USB device, be careful!)
sudo dd if=./result/iso/nixos-gnome-*.iso of=/dev/sdX bs=4M status=progress conv=fsync

# Alternative: Write ISO using a safer tool like Popsicle (if installed)
popsicle ./result/iso/nixos-gnome-*.iso
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
nano ~/repos/workspace/nixos/hosts/gnome/configuration.nix

# Edit GNOME desktop settings
nano ~/repos/workspace/nixos/modules/gnome.nix

# Edit user-specific settings
nano ~/repos/workspace/nixos/hosts/gnome/home.nix

# Edit dotfiles integration
nano ~/repos/workspace/nixos/modules/dotfiles.nix

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

## Dotfiles Management

```bash
# Set up dotfiles from scratch (handles GitHub auth, 1Password and repo cloning)
setup-dotfiles

# Apply dotfiles after setup
chezmoi apply --no-tty
# Or use the alias
cza

# Check status of dotfiles
chezmoi status --no-tty
# Or use the alias
czs

# View differences
chezmoi diff --no-tty
# Or use the alias
czd

# Add a file to dotfiles
chezmoi add --no-tty ~/.config/some-file
# Or use the alias
czadd ~/.config/some-file

# Edit a file in dotfiles
chezmoi edit ~/.config/some-file
# Or use the alias
cze ~/.config/some-file

# Update dotfiles repository from remote
chezmoi update --no-tty
# Or use the alias
czupdate

# Check 1Password status
op whoami
```

## Troubleshooting

```bash
# View system logs
journalctl -b

# View user session logs
journalctl --user -b

# Check X11/Wayland logs
nano ~/.local/share/xorg/Xorg.0.log
journalctl -b | grep gnome-shell

# Check if services are running
systemctl status display-manager
systemctl --user status gnome-shell

# Check nix-mineral security settings
cat /proc/cmdline  # View kernel parameters set by nix-mineral
sysctl -a | grep kernel  # Check hardened kernel settings
systemctl status apparmor # Check AppArmor status
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