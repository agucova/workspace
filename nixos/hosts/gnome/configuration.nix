# Main NixOS configuration file for 7800X3D + RTX 4090 Workstation
{ config, pkgs, lib, ... }:

{
  imports = [
    # Import hardware configuration from system directory
    /etc/nixos/hardware-configuration.nix

    # Import our modular configurations
    ../../modules/base.nix
    ../../modules/hardware.nix  # RTX 4090 specific configuration
    ../../modules/gnome.nix     # GNOME desktop environment
  ];

  # Set hostname
  networking.hostName = "gnome-nixos";

  # User account - your account
  users.users.agucova = {
    isNormalUser = true;
    description = "Agustin Covarrubias";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;  # Set Fish as default shell
    # Using a plain text password is fine for initial setup, but consider
    # changing it after installation or using hashedPassword instead
    initialPassword = "nixos";
  };

  # Enable automatic login if desired
  # services.xserver.displayManager.autoLogin.enable = true;
  # services.xserver.displayManager.autoLogin.user = "agucova";

  # Add additional user packages
  environment.systemPackages = with pkgs; [
    # Desktop applications
    libreoffice-qt
    vscode
    ghostty  # From your flake overlay
  ];

  # This value determines the NixOS release to base packages on
  # Don't change this unless you know what you're doing
  system.stateVersion = "24.11"; # This should match your initial install version
}
