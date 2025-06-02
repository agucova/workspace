# Desktop Environment Configuration with GNOME
{ config, lib, pkgs, ... }:

{
  config = {
    # Desktop-specific networking
    networking = {
      networkmanager.enable = lib.mkDefault true;
    };

    # Display manager autologin
    services.displayManager.autoLogin = {
      enable = true;
      user = "agucova";
    };

    # Audio configuration
    services = {
      # X11 keyboard settings
      xserver = {
        enable = true;
        xkb = {
          layout = lib.mkDefault "us";
          variant = lib.mkDefault "altgr-intl";
        };

        displayManager.gdm = {
          enable = true;
          autoSuspend = false;
        };
        desktopManager.gnome.enable = true;
      };

      # Disable PulseAudio in favor of PipeWire
      pulseaudio.enable = false;

      # Enable PipeWire with low-latency settings
      pipewire = {
        enable = lib.mkDefault true;
        alsa.enable = lib.mkDefault true;
        alsa.support32Bit = lib.mkDefault true;
        pulse.enable = lib.mkDefault true;
      };

      # Enable CUPS to print documents
      printing.enable = lib.mkDefault true;

      # Use preload for faster application launching
      preload.enable = lib.mkDefault true;

      # Enable udev for GNOME
      udev.packages = with pkgs; [ gnome-settings-daemon ];

      # Enable sysprof service for system profiling
      sysprof.enable = true;
    };

    # Enable RTKIT for PipeWire
    security.rtkit.enable = true;

    # Enable XWayland for X11 application compatibility
    programs = {
      xwayland.enable = true;
      dconf.enable = true;
    };

    # Add this to your main configuration
    environment.variables = {
      # Prevent screen tearing in X11 sessions with NVIDIA
      __GL_SYNC_TO_VBLANK = "1";
    };

    # Make sure GDM has correct permissions
    users.users.gdm.extraGroups = [ "video" "audio" "input" ];

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
        gnomeExtensions.appindicator # System tray icons extension
        baobab # Disk usage analyzer
        gnome-console # Terminal
        gnome-characters # Character map
        gnome-system-monitor
        nautilus # File manager
        gnome-boxes # Virtual machine manager
        celluloid # Video player
        transmission_4-gtk # Torrent client
        flameshot # Screenshot tool
        sushi # File previewer

        # Graphics tools
        inkscape
        imagemagick

        # Audio
        easyeffects
        lsp-plugins
      ];
    };

    # GNOME specific tweaks for better performance/experience
    services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.desktop.interface]
      color-scheme='prefer-dark'

      [org.gnome.shell]
      favorite-apps=['org.gnome.Nautilus.desktop', 'firefox.desktop', 'code.desktop', 'ghostty.desktop']
    '';


    # Boot parameters for better desktop responsiveness
    boot.kernelParams = lib.mkDefault [
      # Better desktop responsiveness
      "clocksource=tsc"
      "tsc=reliable"
      "preempt=full"
    ];

    # CachyOS settings
    boot.kernelPackages = pkgs.linuxPackages_cachyos;
    services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
   };

    # Set a faster bootloader timeout for desktop use
    boot.loader.timeout = lib.mkDefault 3;
  };
}
