# Base Darwin configuration module
{ config, lib, pkgs, ... }:

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

    # Add fish to /etc/shells
    programs.fish.enable = true;

    # Touch ID for sudo (super convenient!)
    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;  # or watchIdAuth if you prefer Apple Watch
    };

    # Firewall
    networking.applicationFirewall = {
      enable = true;
      enableStealthMode = true;  # Don't respond to ping/port scans
      allowSigned = true;       # Allow signed apps
      allowSignedApp = true;    # Allow downloaded signed apps
      blockAllIncoming = false; # Set true for max security
    };

    # Quarantine for downloads
    system.defaults.LaunchServices.LSQuarantine = true;

    # Screensaver security
    system.defaults.screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;  # Immediate password requirement
    };

    system.defaults.finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;  # Show hidden files
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv";  # Column view
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    system.defaults.NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";  # Dark mode
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSDocumentSaveNewDocumentsToCloud = false;  # Don't default to iCloud
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
    };

    # Shell configuration
    environment.shells = with pkgs; [
      bashInteractive
      fish
      zsh
    ];

    # System-wide shell aliases
    environment.shellAliases = {
      # Nix aliases
      nrs = "darwin-rebuild switch --flake ~/Repos/workspace/nixos#hackbookv5";
      nrb = "darwin-rebuild build --flake ~/Repos/workspace/nixos#hackbookv5";
      nfu = "nix flake update";
      nfc = "nix flake check";
      nfs = "nix flake show";

      # Git aliases
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
      gd = "git diff";
    };

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
            sudo -u "$PRIMARY_USER" mkdir -p "$USER_HOME/Development"
            sudo -u "$PRIMARY_USER" mkdir -p "$USER_HOME/Repos"
            sudo -u "$PRIMARY_USER" mkdir -p "$USER_HOME/Screenshots"
          fi
        fi
      '';
    };

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
      ];
    };
  };
}
