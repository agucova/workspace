# Base Darwin configuration module
{ config, lib, pkgs, ... }:

let
  cfg = config.myDarwinBase;
in
{
  options.myDarwinBase = {
    enable = lib.mkEnableOption "base Darwin configuration";
  };

  config = lib.mkIf cfg.enable {
    # Nix configuration
    nix = {
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
    system.activationScripts.postActivation.text = ''
      # Create common directories
      mkdir -p ~/Development
      mkdir -p ~/Repos
      
      # Set shell to fish if not already set
      if [ "$SHELL" != "${pkgs.fish}/bin/fish" ]; then
        echo "Setting default shell to fish..."
        chsh -s ${pkgs.fish}/bin/fish || true
      fi
    '';

    # Documentation
    documentation = {
      enable = true;
      man.enable = true;
    };

    # Fonts
    fonts = {
      packages = with pkgs; [
        (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "Hack" ]; })
        fira-code
        jetbrains-mono
        source-code-pro
      ];
    };
  };
}