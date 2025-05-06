# Home-manager standalone configuration for agucova
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # With Snowfall Lib, we can now use the auto-discovery
    # for our home modules
  ];

  # Set username and home directory
  home.username = "agucova";
  home.homeDirectory = "/home/agucova";
  
  # Additional configuration specific to standalone (not NixOS) use
  programs.git = {
    extraConfig = {
      credential.helper = "store";
    };
  };
}