# Troubleshooting NixOS with COSMIC and RTX 4090

This guide covers common issues you might encounter with COSMIC Desktop on NixOS, especially when using an NVIDIA RTX 4090 GPU.

## NVIDIA-Related Issues

### Wayland Session Crashes or Black Screen

If your Wayland session crashes or shows a black screen:

1. At the login screen, select the X11 session instead of Wayland
2. Once logged in, try the following fixes:

```bash
# Edit your configuration
cd ~/.nixos
nano modules/cosmic.nix

# Try adding these kernel parameters (already included but might need adjusting)
boot.kernelParams = [ "nvidia_drm.fbdev=1" "nvidia_drm.modeset=1" ];

# Apply changes
sudo nixos-rebuild switch --flake .#hostname
```

### Screen Tearing

If you experience screen tearing:

1. Ensure ForceFullCompositionPipeline is enabled (already included in config)
2. If still experiencing issues, try:

```bash
# Edit the cosmic.nix module
cd ~/.nixos
nano modules/cosmic.nix

# Modify the NVIDIA configuration to add:
hardware.nvidia = {
  # ... existing config ...
  forceFullCompositionPipeline = true;
  # Try adding this for enhanced sync:
  powerManagement.finegrained = false;
};
```

### Performance Issues

If you're experiencing poor performance:

1. Check if the NVIDIA driver is loaded:
```bash
lsmod | grep nvidia
```

2. Verify you're using the correct driver:
```bash
nixos-rebuild dry-build --flake .#hostname | grep nvidia
```

3. Make sure you're using the performance governor:
```bash
# Edit cosmic.nix
hardware.nvidia.powerManagement.finegrained = false;
```

## COSMIC Desktop Issues

### COSMIC Compositor Crashes

If the COSMIC compositor crashes:

1. Switch to a TTY (Ctrl+Alt+F3)
2. Log in
3. Try restarting the session:
```bash
systemctl --user restart cosmic-comp
```

4. If still failing, try disabling variable refresh rate:
```bash
# Edit your home configuration
cd ~/.nixos
nano hosts/cosmic/home.nix

# Add dconf settings
dconf.settings = {
  "org/gnome/mutter" = {
    experimental-features = [];
    variable-refresh-rate = false;
  };
};
```

### App Scaling Issues

If applications have scaling issues:

```bash
# Edit your home configuration
cd ~/.nixos
nano hosts/cosmic/home.nix

# Add environment variables for scaling
home.sessionVariables = {
  GDK_SCALE = "1";
  GDK_DPI_SCALE = "1";
  QT_AUTO_SCREEN_SCALE_FACTOR = "1";
};
```

### Flatpak App Integration

If Flatpak apps don't integrate well with COSMIC:

```bash
# Install Flatpak themes
flatpak install flathub org.gtk.Gtk3theme.adw-gtk3
flatpak install flathub org.gtk.Gtk3theme.adw-gtk3-dark

# Force theme for all Flatpak apps
flatpak override --user --env=GTK_THEME=adw-gtk3-dark
```

## System Management

### Rolling Back to Previous Configuration

If a configuration change breaks your system:

1. At boot, select the previous generation from the boot menu
2. Once booted, roll back:
```bash
sudo nixos-rebuild switch --rollback
```

### Updating Drivers

To update to the latest NVIDIA drivers:

```bash
# Edit cosmic.nix
hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;  # Or "stable" for stable drivers

# Update flake inputs
cd ~/.nixos
nix flake update

# Apply updates
sudo nixos-rebuild switch --flake .#hostname
```

## Testing Graphics Support

Run these commands to verify your graphics setup:

```bash
# Check OpenGL
glxinfo | grep "OpenGL renderer"

# Check Vulkan
vulkaninfo --summary

# Check NVIDIA driver
nvidia-smi

# Check if using Wayland
echo $XDG_SESSION_TYPE
```

If you encounter issues not covered here, check the nixos-cosmic repository issues or the NixOS wiki for NVIDIA troubleshooting.