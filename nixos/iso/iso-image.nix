# ISO image specific configuration
{ config, lib, pkgs, ... }:

{
  # Set ISO image configuration
  isoImage.isoName = "nixos-cosmic-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.volumeID = "NIXOS_COSMIC";
  
  # Include calamares for installation
  environment.systemPackages = with pkgs; [
    calamares-nixos-extensions
  ];
  
  # Set up auto-login for the live system
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };
  
  # Disable hibernation (doesn't work on live systems)
  powerManagement.enable = false;
  
  # Networking settings for the live image
  networking = {
    hostName = "nixos-cosmic-live";
    wireless.enable = false;
    networkmanager.enable = true;
  };
  
  # Enable SSH server (optional, can be removed for security)
  services.openssh.enable = true;
  
  # Make the installer more visually appealing
  environment.variables = {
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1";
  };
}