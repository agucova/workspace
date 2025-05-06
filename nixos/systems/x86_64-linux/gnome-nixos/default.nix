# Main NixOS configuration file for 7800X3D + RTX 4090 Workstation
{ 
  lib, 
  pkgs, 
  config, 
  inputs, 
  namespace, 
  system, 
  target, 
  format, 
  virtual, 
  systems, 
  ...
}:

{
  imports = [
    # Import hardware configuration if available, otherwise use minimal config
    (if builtins.pathExists /etc/nixos/hardware-configuration.nix 
     then /etc/nixos/hardware-configuration.nix 
     else ({ lib, ... }: {
       # Fallback minimal hardware configuration for testing
       fileSystems."/" = lib.mkDefault {
         device = "/dev/disk/by-label/nixos";
         fsType = "ext4";
       };
       fileSystems."/boot" = lib.mkDefault {
         device = "/dev/disk/by-label/boot";
         fsType = "vfat";
       };
     }))
    
    # Import Snowfall modules with relative paths
    ../../../modules/nixos/base
    ../../../modules/nixos/hardware
    ../../../modules/nixos/gnome
    ../../../modules/nixos/gui-apps
    ../../../modules/nixos/dotfiles
    ../../../modules/nixos/ssh
    ../../../modules/nixos/mineral
    ../../../modules/nixos/macos-remap
  ];

  # Set hostname
  networking.hostName = "gnome-nixos";

  # User account - your account
  users.users.agucova = {
    isNormalUser = true;
    description = "Agustin Covarrubias";
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "audio" "input" "podman" ];
    shell = pkgs.fish;  # Set Fish as default shell
    # Using a plain text password is fine for initial setup, but consider
    # changing it after installation or using hashedPassword instead
    initialPassword = "nixos";
  };

  # Enable Docker and NvCT
  virtualisation = {
    docker = {
      enable = true;
    };
  };
  hardware.nvidia-container-toolkit.enable = true;

  # Additional host-specific packages
  environment.systemPackages = with pkgs; [
    # Container tools
    docker
    docker-compose
    podman
  ];

  # This value determines the NixOS release to base packages on
  # Don't change this unless you know what you're doing
  system.stateVersion = "24.11"; # This should match your initial install version

  # Enable macOS-like keyboard remapping with xremap
  services.macos-remap.enable = true;

  # Configure xremap
  services.xremap = {
    userName = "agucova"; # Use the default user
  };

  # Configure home-manager for this user
  home-manager.users.agucova = { ... }: {
    imports = [ 
      ../../../modules/home/base
    ];

    home.username = "agucova";
    home.homeDirectory = "/home/agucova";
  };
}