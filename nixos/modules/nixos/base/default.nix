# Base NixOS Configuration
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myBase;
in {
  options.myBase = {
    enable = mkEnableOption "Base system configuration";
  };

  config = mkIf cfg.enable {
    # Boot configuration (generic)
    boot = {
      # Use latest kernel for better hardware support
      kernelPackages = mkDefault pkgs.linuxPackages_latest;

      # Bootloader configuration
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        timeout = 5; # Sensible default, overridden by desktop module
      };
    };

    # Enable firmware
    hardware.enableRedistributableFirmware = true;

    # Networking configuration
    # networking = {
    #   # Enable firewall with default settings (allow SSH)
    #   firewall = {
    #     enable = mkDefault true;
    #     allowedTCPPorts = mkDefault [ 22 ];
    #     allowedUDPPorts = mkDefault [ ];
    #   };
    # };

    # Set your time zone
    time.timeZone = mkDefault "America/Santiago";

    # Select internationalisation properties
    i18n.defaultLocale = mkDefault "en_US.UTF-8";

    # Add more detailed locale settings
    i18n.extraLocaleSettings = mkDefault {
      LC_ADDRESS = "es_CL.UTF-8";
      LC_IDENTIFICATION = "es_CL.UTF-8";
      LC_MEASUREMENT = "es_CL.UTF-8";
      LC_MONETARY = "es_CL.UTF-8";
      LC_NAME = "es_CL.UTF-8";
      LC_NUMERIC = "es_CL.UTF-8";
      LC_PAPER = "es_CL.UTF-8";
      LC_TELEPHONE = "es_CL.UTF-8";
      LC_TIME = "es_CL.UTF-8";
    };

    # Configure console keymap
    console.keyMap = mkDefault "us";

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Base system packages
    environment.systemPackages = with pkgs; [
      # Essential tools
      wget
      curl
      git
      htop
      micro
      vim
      nano
      fish

      # Security tools
      gnupg
      keepassxc

      # System utilities
      pciutils
      usbutils
      inxi
      lm_sensors
      dnsutils
      iperf
      whois
      tree
      sqlite

      # Compression tools
      zip
      unzip
      p7zip
      gzip
      xz

      # Fun tools
      cowsay
      lolcat

      # Development tools
      gcc
      cmake
      autoconf
      automake
      libtool
      pkg-config
      gnumake
      clang

      # File transfer
      aria2

      # Network tools
      nmap
      traceroute
      netcat
      openvpn
    ];

    # Enable fish shell
    programs.fish.enable = true;

    # Enable nix flakes
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # Enable garbage collection and optimizations
      auto-optimise-store = true;
      # Add binary caches
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };

    # Support dynamic libraries
    programs.nix-ld.enable = true;

    # Automatically optimize the Nix store
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Swap configuration
    # When not using disko, use a simple swapfile
    swapDevices = mkIf (!config.myDisko.enable) (mkDefault [{
      device = "/swapfile";
      size = 8 * 1024; # 8GB swapfile
      priority = 10; # Lower priority than zram
    }]);

    # Enable zram swap as primary swap
    zramSwap = mkIf (!config.myDisko.enable) (mkDefault {
      enable = mkDefault true;
      algorithm = mkDefault "zstd"; # Best compression/performance ratio
      memoryPercent = mkDefault 100; # Increased to account for compression ratio
      priority = mkDefault 100; # Higher priority than disk-based swap
    };

    # Security hardening options
    security = {
      # Sudo timeout
      sudo.extraConfig = mkDefault ''
        Defaults timestamp_timeout=300
      '';

      protectKernelImage = mkDefault true;
    };

    # Network security
    boot.kernel.sysctl = mkDefault {
      # Improve network security
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    };
  };
}
