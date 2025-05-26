# Main NixOS configuration file for 7800X3D + RTX 4090 Workstation
{ lib
, pkgs
, config
, inputs
, ...
}:

{
  imports = [];

  # Set hostname with higher priority
  networking.hostName = "hackstation";

  # User account - your account
  users.users.agucova = {
    description = "Agustín Covarrubias";
    isNormalUser = true; # Regular user account
    group = "agucova"; # Primary group with same name
    extraGroups = [ "wheel" "networkmanager" "docker" ]; # Add common groups
    shell = pkgs.fish; # Set Fish as default shell
    initialPassword = "nixos";
  };

  # Create the user's group
  users.groups.agucova = {};

  # Base and desktop modules are directly imported in flake.nix

  # Enable hardware configuration with AMD CPU and NVIDIA GPU
  myHardware = {
    cpu.amd.enable = true;
    gpu.nvidia.enable = true;
  };

  # Load nvidia driver for Xorg
  services.xserver.videoDrivers = ["nvidia"];

  # GUI applications and 1Password modules are imported but use xremap-specific options

  # Enable BTRFS with LUKS disk configuration
  myDisko = {
    enable = true;
    device = "/dev/nvme1n1"; # Primary NVMe device
    swapSize = "64G"; # Adjust based on your needs (should be at least equal to RAM for hibernation)
  };

  # Disable macOS-style keyboard remapping
  myMacosRemap.enable = false;

  # When myMacosRemap is disabled, we still need to provide empty values
  # for xremap to prevent type errors during the build
  services.xremap = {
    enable = false;
    yamlConfig = "";  # Empty string to satisfy type requirements
    config = {};      # Empty config object
  };

  # Home Manager configuration
  home-manager.users.agucova = { pkgs, lib, ... }: {
    imports = [
      # Import all home modules first to provide options
      ../../../modules/home/core-shell
      ../../../modules/home/dev-shell
      ../../../modules/home/desktop-settings
      ../../../modules/home/dotfiles
      ../../../modules/home/macos-remap
      ../../../modules/home/1password

      # Import user configuration last
      ../../../homes/x86_64-linux/agucova
    ];
  };

  # Enable Docker and NvCT
  virtualisation = {
    docker = {
      enable = true;
    };
  };
  hardware.nvidia-container-toolkit.enable = true;

  # # Additional host-specific packages
  environment.systemPackages = with pkgs; [
    # Container tools
    docker
    docker-compose
  ];

  # This value determines the NixOS release to base packages on
  # Don't change this unless you know what you're doing
  system.stateVersion = "24.11"; # This should match your initial install version
}
