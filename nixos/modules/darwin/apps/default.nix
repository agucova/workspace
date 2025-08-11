# Darwin Homebrew module for GUI applications
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.myDarwinHomebrew;
in
{
  options.myDarwinHomebrew = {
    enable = lib.mkEnableOption "Homebrew integration for GUI apps";
  };

  config = lib.mkIf cfg.enable {
    # Configure nix-homebrew for declarative Homebrew management
    nix-homebrew = {
      # Install Homebrew under the default prefix
      enable = true;

      # Also install Homebrew under the default Intel prefix for Rosetta 2
      enableRosetta = true;

      # User owning the Homebrew prefix
      user = "agucova";

      # Declarative tap management
      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
      };

      # Disable imperative tap management - taps can no longer be added with `brew tap`
      mutableTaps = false;
    };
    # Homebrew integration for GUI apps
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = false;
        cleanup = "zap"; # Uninstall anything not listed here
        upgrade = true;
      };

      # Align taps with nix-homebrew configuration
      taps = builtins.attrNames config.nix-homebrew.taps;

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
        "tailscale"

        # Media
        "vlc"
        "spotify"
        "iina"
        "stremio"
      ];
    };
  };
}
