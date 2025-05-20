# Home configuration for agucova user
{ config, lib, pkgs, ... }:

{
  # Home Manager configuration
  home = {
    stateVersion = "24.11"; # Only set stateVersion
  };
  
  # 1Password integration options
  onePassword = {
    enableSSH = true;
    enableGit = true;
  };
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
