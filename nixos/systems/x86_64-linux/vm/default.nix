# VM testing configuration for NixOS
{ lib, pkgs, ... }:

{
  # Modules are now directly imported in flake.nix:
  # - Base module provides core system configuration
  # - Desktop module enables GNOME desktop environment
  # - VM module provides virtualization optimizations
  # - GUI applications are directly imported

  # Enable hardware configuration for VM with basic Intel CPU settings
  myHardware = {
    cpu.intel.enable = true;
    # No specific GPU is enabled as we're using QEMU's virtio
  };

  # Home Manager user configuration
  home-manager.users.agucova = {
    home.stateVersion = "24.11";
    my1Password = {
      enableSSH = true;
      enableGit = true;
    };
  };

  # User configurations
  users = {
    users = {
      # User account - same as hardware setup
      agucova = {
        description = "Agustín Covarrubias";
        isNormalUser = true; # Regular user account
        group = "agucova"; # Primary group with same name
        extraGroups = [
          "wheel"
          "networkmanager"
        ]; # Add common groups
        shell = pkgs.fish;
        initialPassword = "nixos";
      };
    };

    # Create the user's group
    groups.agucova = { };
  };

  # Enable automatic login for testing
  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "agucova";
    };
  };

  # Simplify boot configuration
  boot.loader = {
    limine.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = lib.mkForce 0;
  };

  # Filesystem configuration
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos"; # Standard label used by many NixOS VM tools
      fsType = "ext4"; # Common filesystem type for VMs
    };

    # Boot partition
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
  };

  # Add minimal GUI packages for VM testing
  environment.systemPackages = with pkgs; [
    # Basic GUI applications for testing
    firefox
    gnome-terminal

    # Debug tools
    strace
    lsof
    file
  ];

  # VM configuration
  virtualisation.vmVariant.virtualisation = {
    cores = 12;
    memorySize = 8192; # 8GB RAM
    diskSize = 40 * 1024; # 40960 MiB

    qemu.options = [
      "-vga virtio"
      "-display gtk,grab-on-hover=on"
      # Use -cpu max for better cross-architecture compatibility
      # The run-vm-cross script will override this with TCG-specific options
      "-cpu max"
      "-device virtio-keyboard-pci"
      "-usb"
      "-device usb-tablet"
      "-device virtio-serial-pci"
    ];
  };

  # Set hostname
  networking.hostName = "vm";

  # State version
  system.stateVersion = "24.11";
}
