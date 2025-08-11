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
    # Nix configuration
    nix = {
      # Enable nix
      enable = true;
      
      # Storage optimization
      optimise.automatic = true;
      
      # Garbage collection
      gc = {
        automatic = true;
        interval = {
          Hour = 3;
          Minute = 0;
          Weekday = 7; # Sunday
        };
        options = "--delete-older-than 30d";
      };

      # Nix settings
      settings = {
        # Substituters
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
        
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];

        # Build settings
        keep-outputs = true;
        keep-derivations = true;
        
        # Sandboxing
        sandbox = true;
        
        # Warn about dirty git trees
        warn-dirty = false;
      };

      # Extra config
      extraOptions = ''
        # Free up to 10GiB when there's less than 5GiB free
        min-free = ${toString (5 * 1024 * 1024 * 1024)}
        max-free = ${toString (10 * 1024 * 1024 * 1024)}
        
        # Fallback if flakes aren't explicitly enabled
        experimental-features = nix-command flakes
      '';
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
    ];

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

    # LaunchDaemons
    launchd.user.agents = {
      # Example: could add user services here
    };

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