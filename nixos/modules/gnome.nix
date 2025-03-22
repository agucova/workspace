# GNOME Desktop configuration
{ config, pkgs, lib, ... }:

{
  # Enable XWayland for X11 application compatibility
  programs.xwayland.enable = true;
  
  # Enable GNOME Desktop
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
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
    adwaita-icon-theme  # Moved to top-level package
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnome.gnome-shell-extensions
    vulkan-tools  # For Vulkan support checking
    glxinfo       # For checking OpenGL
  ];
}