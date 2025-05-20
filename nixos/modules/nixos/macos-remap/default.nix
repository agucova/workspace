{ lib, pkgs, config, inputs, ... }:

let
  cfg = config.myMacosRemap;
  baseCfg = import ./xremap-config.nix;
in
{
  # Declare our feature options
  options.myMacosRemap = {
    enable = lib.mkEnableOption "Run xremap with mac-style bindings";

    extraXremapConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra bindings merged into the default xremap config.";
    };
  };

  # Configure based on the enable option
  config = {
    # Base services configuration
    services = {
      # Configure xremap with conditional elements
      xremap = {
        # Always provide placeholder yamlConfig to avoid errors when disabled
        yamlConfig = if cfg.enable then ''
          # macOS-style key remapping
          keymap:
            - name: Global macOS keybindings
              application:
                not: [terminals]
              remap:
                Ctrl-c: Alt-c  # Copy
                Ctrl-v: Alt-v  # Paste
                Ctrl-x: Alt-x  # Cut
                Ctrl-z: Alt-z  # Undo
                Ctrl-a: Alt-a  # Select All
                Ctrl-f: Alt-f  # Find
                Ctrl-s: Alt-s  # Save
                Ctrl-q: Alt-F4 # Quit
                Ctrl-w: Alt-w  # Close Tab/Window
                Ctrl-n: Alt-n  # New Window
                Ctrl-t: Alt-t  # New Tab
                Ctrl-o: Alt-o  # Open
                Ctrl-p: Alt-p  # Print
        '' else "";
        
        # Only apply these settings when enabled
        enable = lib.mkIf cfg.enable true;
        serviceMode = lib.mkIf cfg.enable "user";
        userName = lib.mkIf cfg.enable (config.users.defaultUserName or "agucova");
        withGnome = lib.mkIf cfg.enable true;
      };

      # GNOME settings only when enabled
      xserver.desktopManager.gnome.extraGSettingsOverrides = lib.mkIf cfg.enable ''
        [org.gnome.shell]
        enabled-extensions=['xremap@k0kubun.com']
      '';

      # udev rules only when enabled
      udev.extraRules = lib.mkIf cfg.enable ''
        KERNEL=="uinput", GROUP="input", TAG+="uaccess"
      '';
    };

    # Other configs that only apply when enabled
    environment.systemPackages = lib.mkIf cfg.enable (with pkgs; [ 
      gnomeExtensions.xremap 
    ]);

    users.groups.input.members = lib.mkIf cfg.enable
      (lib.optionals (config.users ? defaultUserName)
        [ config.users.defaultUserName ]);
  };
}