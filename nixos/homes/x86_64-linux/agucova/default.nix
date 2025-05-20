# Home configuration for agucova user
{ config, lib, pkgs, ... }:

{
  # Enable home modules with consistent camelCase names
  # All modules now use the "my" prefix with camelCase
  myCoreShell.enable = false;
  myDevShell.enable = false;
  myDesktopSettings.enable = false;
  myDotfiles.enable = false;
  my1Password.enable = false;
  myMacosRemap.enable = false;

  # Home Manager configuration
  home = {
    stateVersion = "24.11"; # Only set stateVersion
  };
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
