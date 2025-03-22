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
          "C-LEFT" = "HOME";
          "C-RIGHT" = "END";
          "Shift-C-LEFT" = "Shift-HOME";
          "Shift-C-RIGHT" = "Shift-END";
        };
      }
      {
        name = "Delete word";
        remap = {
          "Alt-BACKSPACE" = "C-BACKSPACE";
        };
      }
      {
        name = "Delete complete line";
        application.not = [ "org.gnome.Terminal" ];
        remap = {
          "C-K" = "C-D";
        };
      }
      {
        name = "Nautilus (Files) shortcuts";
        application.only = [ "org.gnome.Nautilus" ];
        remap = {
          "C-UP" = "Alt-UP";         # Go Up
          "C-DOWN" = "ENTER";        # Go Down
          "C-BACKSPACE" = "DELETE";  # Move to Trash
          "Shift-C-DOT" = "C-H";     # Show/Hide Hidden Files
          "Shift-C-G" = "C-L";       # Enter Location
        };
      }
      {
        name = "Terminal copy and paste and window management";
        application.only = [ "org.gnome.Terminal" ];
        remap = {
          "C-C" = "Shift-Super-C";
          "C-V" = "Shift-Super-V";
          "C-T" = "Shift-Super-T";
          "C-N" = "Shift-Super-N";
          "C-W" = "Shift-Super-W";
          "C-Q" = "Shift-Super-Q";
          "C-F" = "Shift-Super-F";
        };
      }
      {
        name = "Terminal and Console interrupt";
        application.only = [ "org.gnome.Terminal" "org.gnome.Console" "org.gnome.Ptyxis" ];
        remap = {
          "Super-C" = "C-C";
        };
      }
      {
        name = "Terminal and Console - make Ctrl work in nano editor";
        application.only = [ "org.gnome.Terminal" "org.gnome.Console" "org.gnome.Ptyxis" ];
        remap = {
          "Super-Q" = "C-Q";
          "Super-W" = "C-W";
          "Super-E" = "C-E";
          "Super-R" = "C-R";
          "Super-T" = "C-T";
          "Super-Y" = "C-Y";
          "Super-U" = "C-U";
          "Super-O" = "C-O";
          "Super-P" = "C-P";
          "Super-KEY_RIGHTBRACE" = "C-KEY_RIGHTBRACE";
          "Super-A" = "C-A";
          "Super-S" = "C-S";
          "Super-D" = "C-D";
          "Super-F" = "C-F";
          "Super-G" = "C-G";
          "Super-H" = "C-H";
          "Super-J" = "C-J";
          "Super-K" = "C-K";
          "Super-L" = "C-L";
          "Super-Z" = "C-Z";
          "Super-X" = "C-X";
          "Super-V" = "C-V";
          "Super-B" = "C-B";
          "Super-N" = "C-N";
          "Super-KEY_SLASH" = "C-KEY_SLASH";
          "Super-KEY_BACKSPACE" = "C-KEY_BACKSPACE";
        };
      }
      {
        name = "Console and Ptyxis shortcuts";
        application.only = [ "org.gnome.Console" "org.gnome.Ptyxis" ];
        remap = {
          "C-C" = "C-Shift-C"; # Copy text
          "C-V" = "C-Shift-V"; # Paste text
          "C-N" = "C-Shift-N"; # New window
          "C-Q" = "C-Shift-Q"; # Close window
          "C-T" = "C-Shift-T"; # New tab
          "C-W" = "C-Shift-W"; # Close tab
          "C-F" = "Shift-C-F"; # Find
        };
      }
      {
        name = "Eclipse context assist and switch header/source";
        application.only = [ "Eclipse" ];
        remap = {
          "Super-KEY_SPACE" = "Alt-KEY_SPACE";
          "Super-KEY_TAB" = "Alt-KEY_TAB";
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
    
    # Set up packages and tools
    environment.systemPackages = with pkgs; [
      # GNOME xremap extension
      gnomeExtensions.xremap
      
      # Toggle script for enabling/disabling macOS keybindings
      (writeShellScriptBin "toggle-macos-keybindings" ''
        #!/usr/bin/env bash
        
        XREMAP_SERVICE="xremap"
        
        if systemctl --user is-active ''${XREMAP_SERVICE} >/dev/null 2>&1; then
          echo "Disabling macOS-like keybindings..."
          systemctl --user stop ''${XREMAP_SERVICE}
          systemctl --user disable ''${XREMAP_SERVICE}
          
          # Reset GNOME settings
          dconf reset -f /org/gnome/mutter/overlay-key
          dconf reset -f /org/gnome/desktop/wm/keybindings/
          dconf reset -f /org/gnome/mutter/keybindings/
          dconf reset -f /org/gnome/shell/keybindings/
          dconf reset -f /org/gnome/settings-daemon/plugins/media-keys/screensaver
          dconf reset -f /org/gnome/terminal/legacy/keybindings/
          
          echo "macOS-like keybindings disabled. Restart GNOME Shell with Alt+F2, r, Enter for full effect."
        else
          echo "Enabling macOS-like keybindings..."
          
          # Start service
          systemctl --user daemon-reload
          systemctl --user enable ''${XREMAP_SERVICE}
          systemctl --user start ''${XREMAP_SERVICE}
          
          echo "macOS-like keybindings enabled! ⌘ now acts as Ctrl and vice versa."
          echo "Try ⌘C to copy, ⌘V to paste, ⌘Tab to switch applications."
          echo "To disable, run this command again."
        fi
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

    # Enable dconf for GNOME settings
    programs.dconf.enable = true;
    
    # Configure macOS-like dconf settings for all users
    home-manager.users = let
      usernames = if config ? "users" && config.users ? "defaultUserName" 
                 then [ config.users.defaultUserName ] 
                 else [ "agucova" "nixos" ];
      
      # Define macOS dconf settings for any user
      macOSdconfSettings = {
        dconf.settings = {
          # GNOME Mutter settings
          "org.gnome.mutter" = {
            overlay-key = "";
          };
          
          # Window Manager keybindings
          "org.gnome.desktop.wm.keybindings" = {
            minimize = [];
            show-desktop = ["<Control>d"];
            switch-applications = ["<Control>Tab"];
            switch-applications-backward = ["<Shift><Control>Tab"];
            switch-group = ["<Control>grave"];
            switch-group-backward = ["<Shift><Control>grave"];
            switch-input-source = [];
            switch-input-source-backward = [];
            switch-to-workspace-left = ["<Super>Left"];
            switch-to-workspace-right = ["<Super>Right"];
          };
          
          # Mutter keybindings
          "org.gnome.mutter.keybindings" = {
            toggle-tiled-left = [];
            toggle-tiled-right = [];
          };
          
          # Shell keybindings
          "org.gnome.shell.keybindings" = {
            toggle-message-tray = [];
            screenshot = ["<Shift><Control>3"];
            show-screenshot-ui = ["<Shift><Control>4"];
            screenshot-window = ["<Shift><Control>5"];
            toggle-overview = ["LaunchA"];
            toggle-application-view = ["<Primary>space" "LaunchB"];
          };
          
          # Media keys
          "org.gnome.settings-daemon.plugins.media-keys" = {
            screensaver = [];
          };
          
          # Terminal keybindings
          "org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/" = {
            copy = "<Shift><Super>c";
            paste = "<Shift><Super>v";
            new-tab = "<Shift><Super>t";
            new-window = "<Shift><Super>n";
            close-tab = "<Shift><Super>w";
            close-window = "<Shift><Super>q";
            find = "<Shift><Super>f";
          };
        };
      };
      
      # Create a set of username → configuration pairs
      userConfigs = builtins.listToAttrs (map (username: {
        name = username;
        value = macOSdconfSettings;
      }) usernames);
      
    in userConfigs;
  };
}