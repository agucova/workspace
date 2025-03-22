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
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  # Enable XDG Portal (required for Flatpak)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "gtk";
  };

  # Enable flatpak for extra applications
  services.flatpak.enable = true;

  # Fonts configuration with improved Flatpak compatibility
  fonts = {
    fontDir.enable = true;  # Enable font directory for improved Flatpak support
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
    ];
  };

  # Graphics hardware setup
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # Support for 32-bit applications (mainly for steam)
  };

  # NVIDIA configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;  # Proprietary drivers work better for RTX 4090
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    forceFullCompositionPipeline = true;
    nvidiaPersistenced = true;  # Keeps the NVIDIA driver persistent, improving performance
    nvidiaSettings = true;  # Enable nvidia-settings utility
  };

  # Enable NVIDIA driver
  services.xserver.videoDrivers = [ "nvidia" ];

  # Add GNOME-related packages
  environment.systemPackages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    xdg-utils
    xdg-desktop-portal

    # GNOME packages
    gnome.adwaita-icon-theme
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnome.gnome-shell-extensions
    gnome.baobab            # Disk usage analyzer
    gnome.console          # Terminal
    gnome.gnome-characters  # Character map
    gnome.gnome-system-monitor
    gnome.nautilus          # File manager

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

  # Enable Ozone Wayland support for Chromium/Electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Fix for Flatpak to access system fonts and icons
  system.fsPackages = [ pkgs.bindfs ];
  fileSystems = let
    mkRoSymBind = path: {
      device = path;
      fsType = "fuse.bindfs";
      options = [ "ro" "resolve-symlinks" "x-gvfs-hide" ];
    };
    aggregatedIcons = pkgs.buildEnv {
      name = "system-icons";
      paths = with pkgs; [
        gnome.adwaita-icon-theme
        gnome.gnome-themes-extra
      ];
      pathsToLink = [ "/share/icons" ];
    };
    aggregatedFonts = pkgs.buildEnv {
      name = "system-fonts";
      paths = config.fonts.packages;
      pathsToLink = [ "/share/fonts" ];
    };
  in {
    "/usr/share/icons" = mkRoSymBind "${aggregatedIcons}/share/icons";
    "/usr/local/share/fonts" = mkRoSymBind "${aggregatedFonts}/share/fonts";
  };
}
