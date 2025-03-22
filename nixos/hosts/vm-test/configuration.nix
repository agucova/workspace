# VM testing configuration for NixOS
{ config, pkgs, lib, ... }:

{
  imports = [
    # Import base and generic modules
    ../../modules/base.nix
    ../../modules/gnome.nix
    # Import VM-specific configuration INSTEAD OF hardware.nix
    ../../modules/virtualization.nix
  ];

  # Set hostname for VM
  networking.hostName = "nixos-vm-test";

  # User account - same as hardware setup
  users.users.agucova = {
    isNormalUser = true;
    description = "Agustin Covarrubias";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    initialPassword = "nixos";
  };

  # Enable automatic login for testing
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "agucova";

  # Disable some hardware-specific optimizations that don't make sense in VM
  boot.kernelParams = lib.mkForce [
    # Only keep basic responsiveness parameters
    "preempt=full"
  ];

  # Simplify boot configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 0;  # Fast boot for testing
  };

  # Add minimal set of packages for testing
  environment.systemPackages = with pkgs; [
    firefox
    gnome.gnome-terminal
  ];

  # State version
  system.stateVersion = "23.11";
}
