# Home Manager configuration for agucova
{ config, pkgs, lib, ... }:

{
  # Set Home Manager user
  home-manager.users.agucova = { pkgs, ... }: {
    # Home Manager version
    home.stateVersion = "24.11";

    # Let Home Manager install and manage itself
    programs.home-manager.enable = true;

    # Packages to install for this user
    home.packages = with pkgs; [
      # Development tools
      vscode

      # Media and entertainment
      vlc

      # Utilities
      gnome.gnome-disk-utility
      gnome.gnome-system-monitor
    ];

    # Configure git
    programs.git = {
      enable = true;
      userName = "Agustin Covarrubias";
      userEmail = "gh@agucova.dev";
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };
}
