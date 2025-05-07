# GUI Applications module for NixOS
# This module includes GUI applications that can be included in hosts that need them
{ config, pkgs, lib, ... }:

let
  cfg = config.myGuiApps;
in
{
  # Define options to enable/disable this module
  options.myGuiApps = {
    enable = lib.mkEnableOption "graphical applications";
  };

  # Apply configuration only when enabled
  config = lib.mkIf cfg.enable {
    # Enable GUI applications
    environment.systemPackages = with pkgs; [
      # Office and Productivity
      libreoffice-qt
      vscode
      ghostty  # From flake overlay
      zed-editor.fhs  # Modern code editor with FHS env for better compatibility
      # Only include Claude Desktop if we're not in a live ISO environment
      (lib.mkIf (!config.isoImage.enable or false) claude-desktop-with-fhs)  # Claude AI desktop app with FHS env for MCP
      firefox-devedition-bin
      gitkraken  # Migrated from Flatpak

      # Media and Entertainment
      vlc
      spotify
      discord
      signal-desktop
      telegram-desktop
      slack

      # Productivity
      insync
      obsidian  # Already native
      zotero    # Already native
      calibre

      # GNOME-specific utilities
      gnome-disk-utility
      gnome-system-monitor

      # Gaming tools
      steam
      lutris
    ];

    # Enable Firefox (using the cleaner program approach)
    programs.firefox.enable = true;

    # Configure Flatpak
    services.flatpak = {
      enable = true;
    };

    # Flatpak post-installation script to install common apps
    system.activationScripts.flatpakApps = ''
      # Add Flathub repo
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

      # Install common Flatpak apps that don't have good Nix packages
      FLATPAK_APPS=(
        "com.stremio.Stremio"
        "org.jamovi.jamovi"
        "org.zulip.Zulip"
      )

      for app in "''${FLATPAK_APPS[@]}"; do
        flatpak install -y flathub "$app" || true
      done
    '';
  };
}
