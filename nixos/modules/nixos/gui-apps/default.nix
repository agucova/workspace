# GUI Applications module for NixOS
# This module includes GUI applications that can be included in hosts that need them
# NOTE: This module is automatically enabled when imported (no enable option required)
{ pkgs, ... }:

{
  # Import submodules - all are automatically enabled when imported
  imports = [
    ./1password.nix
    # ./claude-desktop-icons.nix
  ];

  # Apply configuration directly
  config = {
    # GUI applications
    environment.systemPackages = with pkgs; [
      # Basics
      google-chrome

      # Office and Productivity
      libreoffice-qt
      vscode
      ghostty # From flake overlay
      zed-editor.fhs
      gitkraken

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

      # Entertainment
      lutris
      stremio
      cavalier

      # Cryptography
      cryptomator
    ];

    # Enable Firefox
    programs.firefox.enable = true;
    programs.steam.enable = true;
  };
}
