# Home-manager standalone configuration for agucova
{ config, pkgs, lib, inputs, ... }:

{
  imports = [ 
    "${inputs.self}/modules/home/base"
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