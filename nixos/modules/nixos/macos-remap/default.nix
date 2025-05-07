{ lib, pkgs, config, inputs, ... }:

let
  baseCfg = import ./xremap-config.nix;
in
{
  # Declare our feature options
  options = {
    macos-remap.enable = lib.mkEnableOption "Run xremap with mac-style bindings";

    macos-remap.extraXremapConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra bindings merged into the default xremap config.";
    };
  };

  # Configure based on the enable option
  config = {
    # Base services configuration regardless of whether enabled or not
    services = {
      # Always provide minimum xremap config to avoid errors
      xremap = if config.macos-remap.enable then {
        # When enabled - full config
        serviceMode = "user";
        userName = config.users.defaultUserName or "agucova";
        withGnome = true;
        # debug = true;
        config = lib.recursiveUpdate baseCfg config.macos-remap.extraXremapConfig;
        yamlConfig = ""; # Empty string as fallback to fix the "no config" error
      } else {
        # When disabled - minimal config to avoid errors
        enable = false;
        yamlConfig = "";
      };

      # GNOME settings only when enabled
      xserver.desktopManager.gnome.extraGSettingsOverrides = lib.mkIf config.macos-remap.enable ''
        [org.gnome.shell]
        enabled-extensions=['xremap@k0kubun.com']
      '';

      # udev rules only when enabled
      udev.extraRules = lib.mkIf config.macos-remap.enable ''
        KERNEL=="uinput", GROUP="input", TAG+="uaccess"
      '';
    };

    # Other configs only when enabled
    environment.systemPackages = lib.mkIf config.macos-remap.enable (with pkgs; [ 
      gnomeExtensions.xremap 
    ]);

    users.groups.input.members = lib.mkIf config.macos-remap.enable
      (lib.optionals (config.users ? defaultUserName)
        [ config.users.defaultUserName ]);
  };
}