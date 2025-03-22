# Home Manager configuration for agucova
{ config, pkgs, lib, nix-index-database, ... }:

{
  # Home Manager version
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Import the nix-index-database module
  imports = [
    nix-index-database.hmModules.nix-index
  ];

  # Configure programs and tools
  programs = {
    # Enable nix-index with comprehensive shell integration
    nix-index = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      enableZshIntegration = true;  # Enable for all shells to be safe
    };
    
    # Enable comma functionality from nix-index-database
    # This also ensures the nix-index database is properly linked
    nix-index-database.comma.enable = true;
    
    # Configure shells
    fish = {
      enable = true;
    };
    
    bash = {
      enable = true;
    };

    # Configure git
    git = {
      enable = true;
      userName = "Agustin Covarrubias";
      userEmail = "gh@agucova.dev";
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };

  # Packages to install for this user
  home.packages = with pkgs; [
    # Development tools
    vscode

    # Media and entertainment
    vlc

    # Utilities
    gnome-disk-utility  # Moved to top-level packages
    gnome-system-monitor  # Moved to top-level packages
  ];
}
