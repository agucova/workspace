# COSMIC Desktop configuration
{ config, pkgs, lib, ... }:

{
  # Enable XWayland for X11 application compatibility
  programs.xwayland.enable = true;
  # Enable COSMIC Desktop
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  
  # Ensure display manager is properly configured for COSMIC
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  
  # Enable flatpak for COSMIC Store
  services.flatpak.enable = true;
  
  # Enable clipboard manager
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = "1";
  
  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
  ];
  
  # RTX 4090 GPU Configuration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;  # For 32-bit application support (e.g., Steam)
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;  # Proprietary drivers work better for RTX 4090
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    forceFullCompositionPipeline = true;
    nvidiaPersistenced = true;  # Keeps the NVIDIA driver persistent, improving performance
  };

  # Add kernel parameter for COSMIC compatibility with NVIDIA
  boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

  # Enable NVIDIA driver
  services.xserver.videoDrivers = [ "nvidia" ];
  
  # Add additional COSMIC-related packages
  environment.systemPackages = with pkgs; [
    wl-clipboard
    xdg-utils
    xdg-desktop-portal
    gnome.adwaita-icon-theme
    libsForQt5.qtstyleplugins
    libsForQt5.qt5ct
    vulkan-tools  # For Vulkan support checking
    glxinfo       # For checking OpenGL
  ];
  
  # Fallback X11 session option (if Wayland has issues)
  services.xserver.enable = true;
  services.xserver.displayManager.defaultSession = "cosmic-wayland";
  
  # Optional: Create a fallback X11 session for COSMIC
  services.xserver.displayManager.sessionPackages = [ pkgs.cosmic-session ];
}