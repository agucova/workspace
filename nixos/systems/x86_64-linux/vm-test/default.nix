# VM testing configuration for NixOS
{ lib, pkgs, config, inputs, ... }:

{
  # User account - same as hardware setup
  users.users.agucova = {
    isNormalUser = true;
    description = "Agustin Covarrubias";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    initialPassword = "nixos";
  };

  # Enable layered modules
  myVm.enable = true;
  myGnome.enable = true;
  myGuiApps.enable = true;

  # Enable macOS-like keyboard remapping with xremap
  macos-remap.enable = true;
  snowfallorg.users.agucova.home.config.macos-remap.keybindings = true;

  # Enable automatic login for testing
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "agucova";

  # Disable some hardware-specific optimizations that don't make sense in VM
  boot.kernelParams = lib.mkForce [
    "preempt=full"
  ];

  # Simplify boot configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = lib.mkForce 0;
  };

  # Filesystem
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos"; # Standard label used by many NixOS VM tools
    fsType = "ext4"; # Common filesystem type for VMs
  };

  # Boot partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
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

  # Fix for nixos user in VM builds
  users.users.nixos = {
    isNormalUser = true;
    group = "nixos";
  };
  users.groups.nixos = { };

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
