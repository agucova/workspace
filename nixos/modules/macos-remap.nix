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
          "Shift-C-DOT" = "C-h";     # Show/Hide Hidden Files (DOT instead of period)
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