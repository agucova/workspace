# 1Password module for NixOS
# This module includes 1Password GUI app and CLI with proper integration
{ config, pkgs, lib, ... }:

let
  cfg = config.my1Password;
in
{
  # Define options to enable/disable this module
  options.my1Password = {
    enable = lib.mkEnableOption "1Password password manager with CLI/SSH integration";

    # Option to set the users that should have 1Password polkit permissions
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ config.users.defaultUserName or "agucova" ];
      description = "List of users that should have 1Password polkit permissions";
    };
  };

  # Apply configuration only when enabled
  config = lib.mkIf cfg.enable {
    # Enable 1Password CLI
    programs._1password = {
      enable = true;
    };

    # Enable 1Password GUI with polkit integration
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = cfg.users;
    };

    # Add 1Password to system packages to make it available in menus
    environment.systemPackages = with pkgs; [
      _1password-gui
    ];

  };
}
