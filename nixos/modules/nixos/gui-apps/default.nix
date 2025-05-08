# GUI Applications module for NixOS
# This module includes GUI applications that can be included in hosts that need them
{ config, pkgs, lib, ... }:

let
  cfg = config.myGuiApps;
in
{
  # Import submodules
  imports = [
    # ./claude-desktop-icons.nix
    ./1password.nix
  ];

  # Define options to enable/disable this module
  options.myGuiApps = {
    enable = lib.mkEnableOption "graphical applications";
  };

  # Apply configuration only when enabled
  config = lib.mkIf cfg.enable {
    # Enable GUI applications
    environment.systemPackages = with pkgs; [
      # Basics
      google-chrome

      # Office and Productivity
      libreoffice-qt
      vscode
      ghostty # From flake overlay
      zed-editor.fhs # Modern code editor with FHS env for better compatibility
      # Only include Claude Desktop if we're not in a live ISO environment
      # claude-desktop-with-fhs
      gitkraken # Migrated from Flatpak

      # Media and Entertainment
      vlc
      spotify
      discord
      signal-desktop
      telegram-desktop
      slack
      zoom-us

      # Productivity
      insync
      obsidian # Already native
      zotero # Already native
      calibre

      # GNOME-specific utilities
      gnome-disk-utility
      gnome-system-monitor

      # Gaming tools
      steam
      lutris

      # Cryptography
      cryptomator
      stremio
    ];

    # Enable Firefox
    programs.firefox.enable = true;
  };
}
