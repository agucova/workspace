# Main NixOS configuration file for 7800X3D + RTX 4090 Workstation
{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/minimal-hardware.nix
    ../../modules/base.nix
    ../../modules/hardware.nix  # RTX 4090 specific configuration
    ../../modules/gnome.nix     # GNOME desktop environment
    ../../modules/gui-apps.nix  # GUI applications
    ../../modules/dotfiles.nix  # Chezmoi dotfiles integration
    ../../modules/ssh.nix       # SSH server configuration
    ../../modules/mineral.nix   # System hardening with gaming optimizations
    ../../modules/macos-remap.nix # macOS-like keyboard remapping with xremap
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

  # Enable automatic login if desired
  # services.xserver.displayManager.autoLogin.enable = true;
  # services.xserver.displayManager.autoLogin.user = "agucova";

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

  # Julia packages are now managed declaratively through home-manager in home.nix
}
