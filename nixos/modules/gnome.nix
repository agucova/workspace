# GNOME Desktop configuration
{ config, pkgs, lib, ... }:

{
  # Enable XWayland for X11 application compatibility
  programs.xwayland.enable = true;
  
  # Enable GNOME Desktop
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
  # Enable required services for GNOME
  programs.dconf.enable = true;
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];
  
  # Enable flatpak for extra applications
  services.flatpak.enable = true;
  
  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
  ];
  
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;  # Proprietary drivers work better for RTX 4090
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    forceFullCompositionPipeline = true;
    nvidiaPersistenced = true;  # Keeps the NVIDIA driver persistent, improving performance
  };

  # Enable NVIDIA driver
  services.xserver.videoDrivers = [ "nvidia" ];
  
  # Add additional GNOME-related packages
  environment.systemPackages = with pkgs; [
    wl-clipboard
    xdg-utils
    xdg-desktop-portal
    
    # GNOME packages - all moved to top-level
    adwaita-icon-theme
    gnome-tweaks
    dconf-editor
    gnome-shell-extensions
    baobab            # Disk usage analyzer
    gnome-console     # Terminal
    gnome-characters  # Character map
    gnome-system-monitor
    nautilus          # File manager
    
    # GNOME Shell Extensions
    gnomeExtensions.appindicator  # System tray icons support
    
    # Graphics utilities
    vulkan-tools      # For Vulkan support checking
    glxinfo           # For checking OpenGL
    
    # System profiling
    sysprof           # For system performance profiling
  ];
  
  # Enable sysprof service for system profiling
  services.sysprof.enable = true;
}