# GNOME Desktop configuration
{ config, pkgs, lib, ... }:
{
  # Configure programs and services
  programs = {
    # Enable XWayland for X11 application compatibility
    xwayland.enable = true;

    # Enable dconf (required for GNOME settings)
    dconf.enable = true;
  };

  # Configure services
  services = {
    # Enable X server and GNOME Desktop
    xserver = {
      enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;  # Prefer Wayland - moved from below
      };
      desktopManager.gnome.enable = true;
    };

    # Enable udev for GNOME
    udev.packages = with pkgs; [ gnome-settings-daemon ];

    # Enable flatpak for extra applications
    flatpak.enable = true;

    # Enable sysprof service for system profiling - moved from below
    sysprof.enable = true;
  };

  # Enable XDG Portal (required for Flatpak)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "gtk";
  };

  # Fonts configuration with improved Flatpak compatibility
  fonts = {
    fontDir.enable = true;  # Enable font directory for improved Flatpak support
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      inter
      roboto
      dejavu_fonts
      ubuntu_font_family
      source-code-pro
      jetbrains-mono
      hack-font
      font-awesome
    ];

    # Font configuration settings
    fontconfig = {
      defaultFonts = {
        serif = [ "DejaVu Serif" "Noto Serif" ];
        sansSerif = [ "Inter" "Roboto" "DejaVu Sans" ];
        monospace = [ "JetBrains Mono" "Fira Code" "Hack" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Configure environment
  environment = {
    # Add GNOME-related packages
    systemPackages = with pkgs; [
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
      gnome-boxes             # Virtual machine manager
      celluloid               # Video player
      transmission_4-gtk        # Torrent client
      flameshot               # Screenshot tool
      sushi                   # File previewer

      # Graphics tools
      inkscape
      imagemagick

      # System profiling
      sysprof           # For system performance profiling
    ];

    # Enable Ozone Wayland support for Chromium/Electron apps
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    # Set environment variable for better GNOME compatibility
    variables = {
      # Only set NVIDIA-specific variable when not in a VM
      MUTTER_DEBUG_ENABLE_EGL_KMSMODE = lib.mkIf (!(config.virtualisation.vmware.guest.enable or config.virtualisation.virtualbox.guest.enable or config.virtualisation.qemu.guest.enable or false)) "1";
    };
  };

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
}
