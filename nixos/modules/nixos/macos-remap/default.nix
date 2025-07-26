# MacOS-style keyboard remapping for NixOS using xremap
# NOTE: Unlike other modules, this one requires an enable option since it affects system behavior
{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

let
  cfg = config.myMacosRemap;
  baseCfg = import ./xremap-config.nix;
in
{
  # Declare our feature options
  options.myMacosRemap = {
    enable = lib.mkEnableOption "Run xremap with macOS-style bindings";

    extraXremapConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra bindings merged into the default xremap config.";
    };
  };

  # Configure based on the enable option
  config = lib.mkIf cfg.enable {
    # Base services configuration
    services = {
      # Configure xremap with conditional elements
      xremap = {
        enable = true;
        serviceMode = "user";
        userName = config.users.defaultUserName or "agucova";
        withGnome = true;

        # Full xremap config
        yamlConfig = ''
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
        '';
      };

      # GNOME settings
      desktopManager.gnome.extraGSettingsOverrides = ''
        [org.gnome.shell]
        enabled-extensions=['xremap@k0kubun.com']
      '';

      # udev rules
      udev.extraRules = ''
        KERNEL=="uinput", GROUP="input", TAG+="uaccess"
      '';
    };

    # Other configs
    environment.systemPackages = with pkgs; [
      gnomeExtensions.xremap
    ];

    users.groups.input.members = lib.optionals (config.users ? defaultUserName) [
      config.users.defaultUserName
    ];
  };
}
