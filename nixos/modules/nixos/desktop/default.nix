# Desktop-specific NixOS configuration
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myDesktop;
in {
  options.myDesktop = {
    enable = mkEnableOption "Desktop configuration";
  };

  config = mkIf cfg.enable {
    # Desktop-specific networking
    networking = {
      networkmanager.enable = mkDefault true;
    };

    # Audio configuration
    services = {
      # X11 keyboard settings
      xserver.xkb = {
        layout = mkDefault "us";
        variant = mkDefault "alt-intl";
      };

      # Disable PulseAudio in favor of PipeWire
      pulseaudio.enable = false;

      # Enable PipeWire with low-latency settings
      pipewire = {
        enable = mkDefault true;
        alsa.enable = mkDefault true;
        alsa.support32Bit = mkDefault true;
        pulse.enable = mkDefault true;
        # Low-latency settings for better audio experience
        extraConfig.pipewire."92-low-latency" = mkDefault {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 32;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 512;
          };
        };
      };

      # Enable CUPS to print documents
      printing.enable = mkDefault true;
      
      # Use preload for faster application launching
      preload.enable = mkDefault true;
    };

    # Enable RTKIT for PipeWire
    security.rtkit.enable = true;

    # Boot parameters for better desktop responsiveness
    boot.kernelParams = mkDefault [
      # Better desktop responsiveness
      "clocksource=tsc"
      "tsc=reliable"
      "preempt=full"
    ];

    # Set a faster bootloader timeout for desktop use
    boot.loader.timeout = mkDefault 3;
  };
}