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

  # Enable nix-index with comprehensive shell integration
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;  # Enable for all shells to be safe
  };
  
  # Enable comma functionality from nix-index-database
  # This also ensures the nix-index database is properly linked
  programs.nix-index-database.comma.enable = true;
  
  # Configure shells
  programs.fish = {
    enable = true;
  };
  
  programs.bash = {
    enable = true;
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

  # Configure git
  programs.git = {
    enable = true;
    userName = "Agustin Covarrubias";
    userEmail = "gh@agucova.dev";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
