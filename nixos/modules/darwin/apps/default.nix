# Darwin Homebrew module for GUI applications
{
  config,
  inputs,
  ...
}:
{
  config = {
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
        autoUpdate = true;
        cleanup = "zap"; # Uninstall anything not listed here
        upgrade = true;
      };

      # Align taps with nix-homebrew configuration
      taps = builtins.attrNames config.nix-homebrew.taps;

      # GUI Applications via Homebrew Casks
      # Note: Tailscale requires a manual install
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
        "proxyman"

        # Productivity
        "raycast"
        "notion-calendar"
        "superhuman"
        "asana"
        "granola"
        "claude"
        "anki"

        # Communication
        "slack"
        "discord"
        "whatsapp"
        "signal"
        "telegram"
        "zoom"
        "microsoft-teams"

        # Utilities
        "1password"
        "bartender"
        "transmission"
        "cryptomator"
        "google-drive"
        "cleanshot"

        # Media
        "vlc"
        "spotify"
        "iina"
        "stremio"
        "handbrake-app"

        # Basty
        "arduino-ide"

        # Other
        "altserver"
        "antigravity"
      ];
    };
  };
}
