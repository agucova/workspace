# Home configuration for agucova user
{ config, lib, pkgs, ... }:

{
  # Home Manager configuration
  home = {
    stateVersion = "24.11"; # Only set stateVersion
  };
  
  # 1Password integration options
  my1Password = {
    enableSSH = true;
    enableGit = true;
  };
}
