# Home Manager configuration
{ config, pkgs, lib, ... }:

{
  # Set Home Manager user
  home-manager.users.myuser = { pkgs, ... }: {
    # Home Manager version
    home.stateVersion = "24.05";
    
    # Let Home Manager install and manage itself
    programs.home-manager.enable = true;
    
    # Packages to install for this user
    home.packages = with pkgs; [
      # Development tools
      vscode
      
      # Communication tools
      thunderbird
      
      # Media and entertainment
      vlc
      
      # Utilities
      gnome.gnome-disk-utility
      gnome.gnome-system-monitor
    ];
    
    # Configure git
    programs.git = {
      enable = true;
      userName = "Your Name";
      userEmail = "your.email@example.com";
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
    
    # Configure terminal - Ghostty (primary) and Alacritty (backup)
    programs.ghostty = {
      enable = true;
      settings = {
        window.padding = "15";
        window.opacity = 0.95;
        font.size = 11;
        
        # Theme settings
        background = "#282c34";
        foreground = "#abb2bf";
      };
    };
    
    # Keep Alacritty as a backup terminal
    programs.alacritty = {
      enable = true;
      settings = {
        font.size = 11;
        window.opacity = 0.95;
      };
    };
    
    # Configure shell (fish)
    programs.fish = {
      enable = true;
      shellAliases = {
        ls = "ls --color=auto";
        ll = "ls -l";
        rebuild = "sudo nixos-rebuild switch --flake ~/.nixos#hostname";
      };
    };
    
    # Configure VS Code
    programs.vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
        ms-python.python
      ];
    };
    
    # Configure COSMIC desktop-specific settings
    dconf.settings = {
      # Example GNOME settings (will need to be adjusted for COSMIC)
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        enable-animations = true;
        gtk-theme = "Adwaita-dark";
      };
    };
  };
}