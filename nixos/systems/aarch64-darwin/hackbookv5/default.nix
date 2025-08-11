# Darwin system configuration for hackbookv5
{ config, pkgs, lib, inputs, ... }:

{
  # Enable Darwin modules
  myDarwinBase.enable = true;
  myDarwinGuiApps.enable = true;
  
  # Customize GUI apps if needed
  myDarwinGuiApps.apps = [
    # Browsers
    "firefox"
    # "google-chrome"  # Not available in NixCasks
    
    # Development
    "visual-studio-code"
    "cursor"
    "zed"
    "ghostty"
    "iterm2"
    "orbstack"  # Docker Desktop alternative
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
    "bartender"  # Menu bar manager
    
    # Media
    "vlc"
    # "spotify"  # Not available in NixCasks
    "iina"
    "stremio"
  ];
  # Set the hostname
  networking.hostName = "hackbookv5";
  networking.computerName = "hackbookv5";
  networking.localHostName = "hackbookv5";

  # System version
  system.stateVersion = 5;

  # Enable experimental features
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@admin" "agucova" ];
    max-jobs = "auto";
    cores = 0; # Use all available cores
  };
  
  # Use the new optimise option instead of auto-optimise-store
  nix.optimise.automatic = true;

  # nix-daemon is now managed automatically when nix.enable is true
  nix.enable = true;

  # User configuration
  users.users.agucova = {
    home = "/Users/agucova";
    shell = pkgs.fish;
  };

  # Add fish to /etc/shells
  programs.fish.enable = true;

  # Basic macOS system preferences
  system.defaults = {
    # Finder
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      CreateDesktop = false; # Disable desktop icons
      FXDefaultSearchScope = "SCcf"; # Search current folder by default
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv"; # Column view
      QuitMenuItem = true; # Allow quitting Finder
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXSortFoldersFirst = true;
    };

    # Dock
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.5;
      expose-animation-duration = 0.1;
      launchanim = false;
      minimize-to-application = true;
      mru-spaces = false; # Don't rearrange spaces
      show-recents = false;
      static-only = true; # Only show open applications
      tilesize = 48;
    };

    # Global macOS settings
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark"; # Dark mode
      AppleKeyboardUIMode = 3; # Full keyboard control
      ApplePressAndHoldEnabled = false; # Key repeat instead of accent menu
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "WhenScrolling";
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      _HIHideMenuBar = false; # Show menu bar
      "com.apple.mouse.tapBehavior" = 1; # Tap to click
      "com.apple.sound.beep.feedback" = 0; # Disable feedback sound
      "com.apple.swipescrolldirection" = false; # Traditional scroll direction
      "com.apple.trackpad.enableSecondaryClick" = true;
      "com.apple.trackpad.trackpadCornerClickBehavior" = null;
    };

    # Screenshots
    screencapture = {
      disable-shadow = true;
      location = "~/Screenshots";
      type = "png";
    };

    # Trackpad
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };
  };

  # Security settings
  security = {
    pam.services.sudo_local.touchIdAuth = true;
  };

  # Set primary user for system defaults to apply correctly
  system.primaryUser = "agucova";

  # Homebrew integration (if needed for some GUI apps)
  homebrew = {
    enable = false; # Disabled for now, enable if needed
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };
  };

  # Environment variables
  environment = {
    systemPackages = with pkgs; [
      vim
      git
    ];
    
    variables = {
      EDITOR = "vim";
      LANG = "en_US.UTF-8";
    };
  };
}