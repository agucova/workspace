# Desktop Environment Configuration with GNOME
{ config, lib, pkgs, ... }:

{
  config = {
    # Desktop-specific networking
    networking = {
      networkmanager.enable = lib.mkDefault true;
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

        displayManager.gdm.enable = true;
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
        # Low-latency settings for better audio experience
        extraConfig.pipewire."92-low-latency" = lib.mkDefault {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 32;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 512;
          };
        };
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

    # Fonts configuration with improved Flatpak compatibility
    # fonts = {
    #   fontDir.enable = true; # Enable font directory for improved Flatpak support
    #   packages = with pkgs; [
    #     noto-fonts
    #     noto-fonts-emoji
    #     liberation_ttf
    #     fira-code
    #     fira-code-symbols
    #     inter
    #     roboto
    #     dejavu_fonts
    #     ubuntu_font_family
    #     source-code-pro
    #     jetbrains-mono
    #     hack-font
    #     font-awesome
    #   ];

    #   # Font configuration settings
    #   fontconfig = {
    #     defaultFonts = {
    #       serif = [ "DejaVu Serif" "Noto Serif" ];
    #       sansSerif = [ "Inter" "Roboto" "DejaVu Sans" ];
    #       monospace = [ "JetBrains Mono" "Fira Code" "Hack" ];
    #       emoji = [ "Noto Color Emoji" ];
    #     };
    #   };
    # };

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

        # System profiling
        # sysprof # For system performance profiling
      ];

      # # Set environment variables based on display server
      # sessionVariables = lib.mkIf config.services.xserver.displayManager.gdm.wayland {
      #   # Only enable Ozone Wayland support when using Wayland
      #   NIXOS_OZONE_WL = "1";
      # };
    };

    # GNOME specific tweaks for better performance/experience
    services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.desktop.interface]
      color-scheme='prefer-dark'

      [org.gnome.shell]
      favorite-apps=['org.gnome.Nautilus.desktop', 'firefox.desktop', 'code.desktop', 'ghostty.desktop']
    '';

    # Basic NVIDIA settings for better compatibility
    # hardware.nvidia = {
    #   # Enable basic modesetting for NVIDIA
    #   modesetting.enable = lib.mkDefault true;
    # };

    # Ensure GDM user has proper permissions
    # users.users.gdm.extraGroups = [ "video" "audio" "input" ];

    # Boot parameters for better desktop responsiveness
    boot.kernelParams = lib.mkDefault [
      # Better desktop responsiveness
      "clocksource=tsc"
      "tsc=reliable"
      "preempt=full"
    ];

    # Set a faster bootloader timeout for desktop use
    boot.loader.timeout = lib.mkDefault 3;
  };
}
