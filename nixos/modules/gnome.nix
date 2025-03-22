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

  # Add GNOME-related packages
  environment.systemPackages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    xdg-utils
    xdg-desktop-portal

    # GNOME packages
    adwaita-icon-theme
    gnome-tweaks
    dconf-editor
    gnome-shell-extensions
    baobab                  # Disk usage analyzer
    gnome-console           # Terminal
    gnome-characters        # Character map
    gnome-system-monitor
    nautilus                # File manager

    # GNOME Shell Extensions
    gnomeExtensions.appindicator  # System tray icons support

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
        adwaita-icon-theme
        gnome-themes-extra
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

  # GNOME specific tweaks for better performance/experience
  services.xserver.displayManager.gdm.wayland = true;  # Prefer Wayland
  services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.desktop.interface]
    enable-animations=true
    gtk-theme='Adwaita-dark'
    color-scheme='prefer-dark'

    [org.gnome.desktop.wm.preferences]
    button-layout=':minimize,maximize,close'

    [org.gnome.shell]
    favorite-apps=['org.gnome.Nautilus.desktop', 'firefox.desktop', 'code.desktop', 'ghostty.desktop']
  '';

  # NVIDIA-specific settings (only applied if not in a VM)
  hardware.nvidia.powerManagement.finegrained = lib.mkIf (!(config.virtualisation.vmware.guest.enable or config.virtualisation.virtualbox.guest.enable or config.virtualisation.qemu.guest.enable or false)) false;

  # Set environment variable for better GNOME compatibility
  environment.variables = {
    # Only set NVIDIA-specific variable when not in a VM
    MUTTER_DEBUG_ENABLE_EGL_KMSMODE = lib.mkIf (!(config.virtualisation.vmware.guest.enable or config.virtualisation.virtualbox.guest.enable or config.virtualisation.qemu.guest.enable or false)) "1";
  };
}
