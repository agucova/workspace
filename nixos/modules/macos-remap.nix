# macOS-like keyboard remapping using xremap with flake support
# Based on https://github.com/petrstepanov/gnome-macos-remap-wayland
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.macos-remap;

  xremapConfig = {
    keypress_delay_ms = 10;

    # `modmap` section - key-to-key remapping
    modmap = [
      {
        name = "Make ⌘ act as Ctrl";
        remap = {
          "LeftCtrl" = "LeftMeta";
          "LeftMeta" = "LeftCtrl";
          "RightCtrl" = "RightMeta";
          "RightMeta" = "RightCtrl";
        };
      }
    ];

    # `keymap` section - key combination remapping
    keymap = [
      {
        name = "Make ⌘← and ⌘→ work as Home and End";
        remap = {
          "C-Left" = "Home";
          "C-Right" = "End";
          "Shift-C-Left" = "Shift-Home";
          "Shift-C-Right" = "Shift-End";
        };
      }
      {
        name = "Delete word";
        remap = {
          "Alt-BackSpace" = "C-BackSpace";
        };
      }
      {
        name = "Delete complete line";
        application.not = [ "org.gnome.Terminal" ];
        remap = {
          "C-k" = "C-d";
        };
      }
      {
        name = "Nautilus (Files) shortcuts";
        application.only = [ "org.gnome.Nautilus" ];
        remap = {
          "C-Up" = "Alt-Up";         # Go Up
          "C-Down" = "Enter";        # Go Down
          "C-BackSpace" = "Delete";  # Move to Trash
          "Shift-C-period" = "C-h";  # Show/Hide Hidden Files
          "Shift-C-g" = "C-l";       # Enter Location
        };
      }
      {
        name = "Terminal copy and paste and window management";
        application.only = [ "org.gnome.Terminal" ];
        remap = {
          "C-c" = "Shift-Super-c";
          "C-v" = "Shift-Super-v";
          "C-t" = "Shift-Super-t";
          "C-n" = "Shift-Super-n";
          "C-w" = "Shift-Super-w";
          "C-q" = "Shift-Super-q";
          "C-f" = "Shift-Super-f";
        };
      }
      {
        name = "Terminal and Console interrupt";
        application.only = [ "org.gnome.Terminal" "org.gnome.Console" "org.gnome.Ptyxis" ];
        remap = {
          "Super-c" = "C-c";
        };
      }
      {
        name = "Terminal and Console - make Ctrl work in nano editor";
        application.only = [ "org.gnome.Terminal" "org.gnome.Console" "org.gnome.Ptyxis" ];
        remap = {
          "Super-q" = "C-q";
          "Super-w" = "C-w";
          "Super-e" = "C-e";
          "Super-r" = "C-r";
          "Super-t" = "C-t";
          "Super-y" = "C-y";
          "Super-u" = "C-u";
          "Super-o" = "C-o";
          "Super-p" = "C-p";
          "Super-bracketright" = "C-bracketright";
          "Super-a" = "C-a";
          "Super-s" = "C-s";
          "Super-d" = "C-d";
          "Super-f" = "C-f";
          "Super-g" = "C-g";
          "Super-h" = "C-h";
          "Super-j" = "C-j";
          "Super-k" = "C-k";
          "Super-l" = "C-l";
          "Super-z" = "C-z";
          "Super-x" = "C-x";
          "Super-v" = "C-v";
          "Super-b" = "C-b";
          "Super-n" = "C-n";
          "Super-slash" = "C-slash";
        };
      }
      {
        name = "Console and Ptyxis shortcuts";
        application.only = [ "org.gnome.Console" "org.gnome.Ptyxis" ];
        remap = {
          "C-c" = "C-Shift-c"; # Copy text
          "C-v" = "C-Shift-v"; # Paste text
          "C-n" = "C-Shift-n"; # New window
          "C-q" = "C-Shift-q"; # Close window
          "C-t" = "C-Shift-t"; # New tab
          "C-w" = "C-Shift-w"; # Close tab
          "C-f" = "Shift-C-f"; # Find
        };
      }
      {
        name = "Eclipse context assist and switch header/source";
        application.only = [ "Eclipse" ];
        remap = {
          "Super-space" = "Alt-space";
          "Super-Tab" = "Alt-Tab";
        };
      }
    ];
  };
in {
  options.services.macos-remap = {
    enable = mkEnableOption "macOS-like keyboard remapping with xremap";
    
    additionalConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional xremap configuration to be merged";
    };
  };

  config = mkIf cfg.enable {
    # Add xremap flake as an input
    nix.settings = {
      trusted-substituters = ["https://xremap.cachix.org"];
      trusted-public-keys = ["xremap.cachix.org-1:Vz8Xjjai+6Wc0JJaJLEWu7QveZV3hQzVL5GnqQ7rlmo="];
    };

    # Set up xremap service in user mode with GNOME support
    services.xremap = {
      serviceMode = "user";
      withGnome = true;
      config = lib.recursiveUpdate xremapConfig cfg.additionalConfig;
      debug = false; # Set to true to enable debug logging
    };
    
    # Enable the GNOME Shell extension for xremap and add helper script
    environment.systemPackages = with pkgs; [
      # GNOME xremap extension
      gnomeExtensions.xremap
      
      # Script to apply all macOS-like keybindings
      (writeShellScriptBin "apply-macos-keybindings" ''
        #!/usr/bin/env bash
        
        # Apply all macOS-like keybindings via gsettings
        
        # GNOME Mutter settings
        gsettings set org.gnome.mutter overlay-key ""
        
        # WM keybindings
        gsettings set org.gnome.desktop.wm.keybindings minimize "[]"
        gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Control>d']"
        gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Control>Tab']"
        gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Control>Tab']"
        gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Control>grave']"
        gsettings set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Control>grave']"
        gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"
        gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>Left']"
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>Right']"
        
        # Mutter keybindings
        gsettings set org.gnome.mutter.keybindings toggle-tiled-left "[]"
        gsettings set org.gnome.mutter.keybindings toggle-tiled-right "[]"
        
        # Shell keybindings
        gsettings set org.gnome.shell.keybindings toggle-message-tray "[]"
        gsettings set org.gnome.shell.keybindings screenshot "['<Shift><Control>3']"
        gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Control>4']"
        gsettings set org.gnome.shell.keybindings screenshot-window "['<Shift><Control>5']"
        gsettings set org.gnome.shell.keybindings toggle-overview "['LaunchA']"
        gsettings set org.gnome.shell.keybindings toggle-application-view "['<Primary>space', 'LaunchB']"
        
        # Media keys
        gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "[]"
        
        # Terminal keybindings
        gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ copy "<Shift><Super>c"
        gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ paste "<Shift><Super>v"
        gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ new-tab "<Shift><Super>t"
        gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ new-window "<Shift><Super>n"
        gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ close-tab "<Shift><Super>w"
        gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ close-window "<Shift><Super>q"
        gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ find "<Shift><Super>f"
      '')
    ];

    # Add user to input group to allow xremap to run without sudo
    users.groups.input.members = [ 
      (if config ? "users" && config.users ? "defaultUserName" then config.users.defaultUserName else "agucova") 
    ];
    
    # Configure udev rules
    services.udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", TAG+="uaccess"
    '';

    # GNOME settings tweaks to enable macOS-like behavior - use Nix dconf
    services.xserver.desktopManager.gnome = {
      # We don't need to set any overrides here, all done via dconf
      enable = true;
    };
    
    # Enable dconf to store GNOME settings
    programs.dconf.enable = true;
  };
}