# Base NixOS Configuration for 7800X3D + RTX 4090 Workstation
{ config, pkgs, lib, ... }:

{
  # Boot configuration
  boot = {
    # Use latest kernel for better hardware support
    kernelPackages = pkgs.linuxPackages_latest;

    # Performance optimizations for AMD 7800X3D
    kernelParams = [
      # Better desktop responsiveness
      "clocksource=tsc"
      "tsc=reliable"
      "preempt=full"
      # AMD-specific optimizations
      "amd_pstate=active"
      "processor.max_cstate=5"
      # Uncomment for maximum performance (reduces security)
      # "mitigations=off"
    ];

    # Enable AMD virtualization
    kernelModules = [ "kvm-amd" ];
  };

  # Bootloader with faster timeout
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Enable CPU microcode updates
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # CPU Power Management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };

  # Networking configuration
  networking = {
    networkmanager.enable = true;
    # Enable firewall with default settings (allow SSH)
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [];
    };
  };

  # Set your time zone
  time.timeZone = "America/Santiago";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  # Add more detailed locale settings
  i18n.extraLocaleSettings = {
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
  console.keyMap = "us";

  # Configure keyboard in X11 - US international as requested
  services.xserver.xkb = {
    layout = "us";
    variant = "alt-intl";
  };

  # Enable sound with pipewire and low-latency settings
  # sound.enable = true; # This option is now deprecated
  services.pulseaudio.enable = false; # Renamed from hardware.pulseaudio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # Low-latency settings for better audio experience
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 32;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 32;
      };
    };
  };

  # Enable CUPS to print documents
  services.printing.enable = true;

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

    # Security tools
    gnupg
    keepassxc

    # System utilities
    pciutils
    usbutils
    inxi
    lm_sensors

    # Compression tools
    zip
    unzip
    p7zip
  ];

  # Enable fish shell
  programs.fish.enable = true;

  # Firefox (using the cleaner program approach)
  programs.firefox.enable = true;

  # Enable nix flakes
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Enable garbage collection and optimizations
    auto-optimise-store = true;
    # Allow greater parallelism for builds
    max-jobs = "auto";
    cores = 0;
  };

  # Automatically optimize the Nix store
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Swap configuration using zram and a backup swapfile
  swapDevices = [{
    device = "/swapfile";
    size = 8*1024;    # 8GB swapfile
    priority = 10;    # Lower priority than zram
  }];

  # Enable zram swap as primary swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";     # Best compression/performance ratio
    memoryPercent = 60;     # Increased to account for compression ratio
    priority = 100;         # Higher priority than disk-based swap
  };

  # Security hardening options
  security = {
    # Sudo timeout
    sudo.extraConfig = ''
      Defaults timestamp_timeout=300
    '';

    # Process hardening
    lockKernelModules = false; # Set to true for higher security, may cause compatibility issues
    protectKernelImage = true;
  };

  # System-level security options
  boot.kernel.sysctl = {
    # Reduce swap tendency
    "vm.swappiness" = 10;

    # Improve network security
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;

    # Increase file handle limits for high performance
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
  };
}
