# Base Darwin configuration module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myDarwinBase;
in
{
  options.myDarwinBase = {
    enable = lib.mkEnableOption "base Darwin configuration";
    primaryUser = lib.mkOption {
      type = lib.types.str;
      default = "agucova";
      description = "Primary user for system defaults";
    };
  };

  config = lib.mkIf cfg.enable {
    # Nix management disabled - using Determinate Nix
    nix.enable = false;

    # Set primary user for system defaults
    system.primaryUser = cfg.primaryUser;
    users.users.${cfg.primaryUser} = {
      home = "/Users/${cfg.primaryUser}";
      shell = pkgs.fish;
    };
    # Apply changes in settings immediately
    system.activationScripts.activateSettings.text = ''
      # Following line should allow us to avoid a logout/login cycle
         /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    # Add fish to /etc/shells
    programs.fish.enable = true;

    # Touch ID for sudo (super convenient!)
    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true; # or watchIdAuth if you prefer Apple Watch
    };

    # Firewall
    networking.applicationFirewall = {
      enable = true;
      enableStealthMode = true; # Don't respond to ping/port scans
      allowSigned = true; # Allow signed apps
      allowSignedApp = true; # Allow downloaded signed apps
      blockAllIncoming = false; # Set true for max security
    };

    # Quarantine for downloads
    system.defaults.LaunchServices.LSQuarantine = true;

    # Screensaver security
    system.defaults.screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0; # Immediate password requirement
    };

    system.defaults.finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false; # Show hidden files
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv"; # Column view
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    system.defaults.CustomUserPreferences."com.apple.finder" = {
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = true;
      ShowMountedServersOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;
      _FXSortFoldersFirst = true;
      # When performing a search, search the current folder by default
      FXDefaultSearchScope = "SCcf";
    };

    system.defaults.NSGlobalDomain = {
      AppleInterfaceStyle = "Dark"; # Dark mode
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSDocumentSaveNewDocumentsToCloud = false; # Don't default to iCloud
      "com.apple.swipescrolldirection" = true; # Natural scroll
    };

    # Dock
    system.defaults.CustomUserPreferences."com.apple.AdLib" = {
      allowApplePersonalizedAdvertising = false;
    };
    system.defaults.CustomUserPreferences."com.apple.print.PrintingPrefs" = {
      # Automatically quit printer app once the print jobs complete
      "Quit When Finished" = true;
    };
    system.defaults.CustomUserPreferences."com.apple.SoftwareUpdate" = {
      AutomaticCheckEnabled = true;
      # Check for software updates daily, not just once per week
      ScheduleFrequency = 1;
      # Download newly available updates in background
      AutomaticDownload = 1;
      # Install System data files & security updates
      CriticalUpdateInstall = 1;
    };
    system.defaults.CustomUserPreferences."com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
    # Prevent Photos from opening automatically when devices are plugged in
    system.defaults.CustomUserPreferences."com.apple.ImageCapture".disableHotPlug = true;
    # Turn on app auto-update
    system.defaults.CustomUserPreferences."com.apple.commerce".AutoUpdate = true;

    system.defaults.CustomUserPreferences."com.apple.desktopservices" = {
      # Avoid creating .DS_Store files on network or USB volumes
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

    # System packages that should always be available
    environment.systemPackages = with pkgs; [
      coreutils
      findutils
      gnugrep
      gnused
      gnutar
      gawk
      curl
      wget
      vim
      git
    ];

    # Environment variables
    environment.variables = {
      EDITOR = "micro";
      LANG = "en_US.UTF-8";
      NH_FLAKE = "/Users/${cfg.primaryUser}/Repos/workspace/nixos/";
    };

    # Shell configuration
    environment.shells = with pkgs; [
      bashInteractive
      fish
      zsh
    ];

    # Path configuration
    environment.systemPath = [
      "/opt/homebrew/bin" # For Apple Silicon Homebrew
      "/usr/local/bin"
    ];

    # System activation scripts
    system.activationScripts.userDirs = {
      text = ''
        # Create common directories for the primary user
        PRIMARY_USER="${cfg.primaryUser}"
        if [ -n "$PRIMARY_USER" ]; then
          USER_HOME="/Users/$PRIMARY_USER"
          if [ -d "$USER_HOME" ]; then
            # Create directories
            sudo -u "$PRIMARY_USER" mkdir -p "$USER_HOME/Repos"
            sudo -u "$PRIMARY_USER" mkdir -p "$USER_HOME/Screenshots"
          fi
        fi
      '';
    };
    system.activationScripts.extraActivation.text = ''
      softwareupdate --install-rosetta --agree-to-license
    '';

    system.defaults.screencapture.location = "/Users/${cfg.primaryUser}/Screenshots";

    # Documentation
    documentation = {
      enable = true;
      man.enable = true;
    };

    # Fonts
    fonts = {
      packages = with pkgs; [
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.hack
        fira-code
        jetbrains-mono
        source-code-pro
        julia-mono
        ibm-plex
      ];
    };
  };
}
