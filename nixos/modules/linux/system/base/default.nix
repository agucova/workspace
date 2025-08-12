# Base NixOS Configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  config = {
    # Boot configuration (generic)
    boot = {
      kernelPackages = mkDefault pkgs.linuxPackages_latest;

      # Taken from CachyOS settings
      # See https://github.com/CachyOS/CachyOS-Settings/blob/master/usr/lib/sysctl.d/99-cachyos-settings.conf
      kernel.sysctl = {
        # The sysctl swappiness parameter determines the kernel's preference for pushing anonymous pages or page cache to disk in memory-starved situations.
        # A low value causes the kernel to prefer freeing up open files (page cache), a high value causes the kernel to try to use swap space,
        # and a value of 100 means IO cost is assumed to be equal.
        "vm.swappiness" = 100;

        # The value controls the tendency of the kernel to reclaim the memory which is used for caching of directory and inode objects (VFS cache).
        # Lowering it from the default value of 100 makes the kernel less inclined to reclaim VFS cache (do not set it to 0, this may produce out-of-memory conditions)
        "vm.vfs_cache_pressure" = 50;

        # Contains, as bytes, the number of pages at which a process which is
        # generating disk writes will itself start writing out dirty data.
        "vm.dirty_bytes" = 268435456;

        # Contains, as bytes, the number of pages at which the background kernel
        # flusher threads will start writing out dirty data.
        "vm.dirty_background_bytes" = 67108864;

        # The kernel flusher threads will periodically wake up and write old data out to disk.  This
        # tunable expresses the interval between those wakeups, in 100'ths of a second (Default is 500).
        "vm.dirty_writeback_centisecs" = 1500;

        # This action will speed up your boot and shutdown, because one less module is loaded. Additionally disabling watchdog timers increases performance and lowers power consumption
        # Disable NMI watchdog
        "kernel.nmi_watchdog" = 0;

        # Enable the sysctl setting kernel.unprivileged_userns_clone to allow normal users to run unprivileged containers.
        "kernel.unprivileged_userns_clone" = 1;

        # To hide any kernel messages from the console
        "kernel.printk" = "3 3 3 3";

        # Restricting access to kernel pointers in the proc filesystem
        "kernel.kptr_restrict" = 2;

        # Disable Kexec, which allows replacing the current running kernel.
        "kernel.kexec_load_disabled" = 1;

        # Increase netdev receive queue
        # May help prevent losing packets
        "net.core.netdev_max_backlog" = 4096;

        # Improve network security
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;

        # Allow tracking more files using inotify
        "fs.inotify.max_user_watches" = 524288;
      };

      # Bootloader configuration
      loader = {
        limine.enable = true;
        limine.secureBoot.enable = true;
        efi.canTouchEfiVariables = true;
        timeout = 5;
      };
    };

    # Enable firmware
    hardware.enableRedistributableFirmware = true;

    # Networking configuration
    networking = {
      # Enable firewall with default settings (allow SSH)
      firewall = {
        enable = mkDefault true;
        allowedTCPPorts = mkDefault [ 22 ];
        allowedUDPPorts = mkDefault [ ];
      };
    };

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

    # Auto-upgrade
    system.autoUpgrade = {
      enable = true;
      flake = "/home/agucova/repos/workspace/nixos";
      flags = [
        "--update-input"
        "nixpkgs"
        "--commit-lock-file"
      ];
    };

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
      fuse3

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
      experimental-features = [
        "nix-command"
        "flakes"
      ];
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
    # Enable local binaries in PATH (used for e.g. uv)
    environment.localBinInPath = true;

    # Nix-index (for command-not-found) and comma helper
    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;

    # Use the nh CLI tool
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 15d --keep 3";
      flake = "/home/agucova/repos/workspace/nixos";
    };

    # Swap configuration
    # When not using disko, use a simple swapfile
    swapDevices = mkIf (!config.myDisko.enable) (mkDefault [
      {
        device = "/swapfile";
        size = 8 * 1024; # 8GB swapfile
        priority = 10; # Lower priority than zram
      }
    ]);

    # Enable zram swap as primary swap
    zramSwap = {
      # Use mkForce to explicitly set the value with highest priority
      enable = true;
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

      sudo-rs.enable = true;
    };

    # DNS
    networking.nameservers = [
      "1.1.1.1#one.one.one.one"
      "1.0.0.1#one.one.one.one"
    ];

    services.resolved = {
      enable = true;
      dnssec = "true";
      domains = [ "~." ];
      fallbackDns = [
        "1.1.1.1#one.one.one.one"
        "1.0.0.1#one.one.one.one"
      ];
      dnsovertls = "true";
    };

    services.tailscale.enable = true;
    services.tailscale.useRoutingFeatures = "both";
    # Set IP forwarding
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

    # Nix build optimizations
    nix.settings = {
      # Allow greater parallelism for builds
      max-jobs = "auto";
      cores = 0;
    };
  };
}
