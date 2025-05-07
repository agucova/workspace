# VM testing configuration for NixOS
{ lib, pkgs, config, inputs, ... }:

{
  # Enable modules with the 'my' prefix
  myBase.enable = true;
  myDesktop.enable = true; # Desktop now includes GNOME

  # Hardware module is not enabled for VM testing
  # This avoids hardware-specific optimizations that don't make sense in a VM

  # Enable VM-specific configurations
  myVm.enable = true;

  # Enable GUI applications
  myGuiApps.enable = true;

  # Enable macOS-like keyboard remapping with xremap
  macos-remap.enable = true;
  snowfallorg.users.agucova.home.config.macos-remap.keybindings = true;

  # User configurations
  users = {
    users = {
      # User account - same as hardware setup
      agucova = {
        description = "Agustín Covarrubias";
        shell = pkgs.fish;
        initialPassword = "nixos";
      };
    };
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
    systemd-boot.enable = true;
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
      "-cpu host"
      "-device virtio-keyboard-pci"
      "-usb"
      "-device usb-tablet"
      "-device virtio-serial-pci"
    ];
  };

  # State version
  system.stateVersion = "24.11";
}
