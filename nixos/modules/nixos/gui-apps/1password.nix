# 1Password module for NixOS
# This module includes 1Password GUI app and CLI with proper integration
{ config, pkgs, lib, ... }:

{
  # Option to set the users that should have 1Password polkit permissions
  options.my1Password = {
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ config.users.defaultUserName or "agucova" ];
      description = "List of users that should have 1Password polkit permissions";
    };
    
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable auto-start of 1Password on boot";
    };
  };

  # Apply configuration directly when module is imported
  config = {
    # Enable 1Password CLI
    programs._1password = {
      enable = true;
    };

    # Enable 1Password GUI with polkit integration
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = config.my1Password.users;
    };

    # Add 1Password to system packages to make it available in menus
    environment.systemPackages = with pkgs; [
      _1password-gui
    ];
    
    # Auto-start 1Password on boot using systemd
    systemd.user.services."1password" = lib.mkIf config.my1Password.autoStart {
      description = "1Password Password Manager";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "exec";
        ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
