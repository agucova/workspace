# Home configuration for agucova user in vm-test
{ config, lib, pkgs, ... }:

{
  imports = [
    # Import the base home configuration
    ../../../modules/home/base
  ];

  # User-specific overrides for vm-test
  home = {
    username = "agucova";
    homeDirectory = "/home/agucova";
  };

  # Additional VM-specific configurations
  programs.git = {
    extraConfig = {
      # Simplified configuration for VM
      credential.helper = "store";
    };
  };
}