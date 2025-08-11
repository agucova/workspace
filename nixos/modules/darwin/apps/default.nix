# Darwin Homebrew module for GUI applications
{ config, lib, pkgs, ... }:

let
  cfg = config.myDarwinHomebrew;
in
{
  options.myDarwinHomebrew = {
    enable = lib.mkEnableOption "Homebrew integration for GUI apps";
  };

  config = lib.mkIf cfg.enable {
    # Homebrew integration for GUI apps
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = false;
        cleanup = "zap";  # Uninstall anything not listed here
        upgrade = true;
      };
      
      # GUI Applications via Homebrew Casks
      casks = [
        # Browsers
        "firefox"
        "google-chrome"
        
        # Development
        "visual-studio-code"
        "cursor"
        "zed"
        "ghostty"
        "iterm2"
        "orbstack"
        "figma"
        
        # Productivity
        "raycast"
        "notion-calendar"
        "superhuman"
        "asana"
        "granola"
        
        # Communication
        "slack"
        "discord"
        "whatsapp"
        "signal"
        "telegram"
        
        # Utilities
        "1password"
        "bartender"
        
        # Media
        "vlc"
        "spotify"
        "iina"
        "stremio"
      ];
    };
  };
}