{ lib, pkgs, config, inputs, ... }:

let
  baseCfg = import ./xremap-config.nix;
in
{
  # 2.  Declare our feature options
  options = {
    macos-remap.enable = lib.mkEnableOption "Run xremap with mac-style bindings";

    macos-remap.extraXremapConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra bindings merged into the default xremap config.";
    };
  };

  # 3.  Gate all concrete settings behind the boolean
  config = lib.mkIf config.macos-remap.enable {
    services = {
      xremap = {
        serviceMode = "user";
        userName = config.users.defaultUserName or "agucova";
        withGnome = true;
        # debug = true;
        config = lib.recursiveUpdate baseCfg
          config.macos-remap.extraXremapConfig;
      };

      xserver.desktopManager.gnome.extraGSettingsOverrides = ''
        [org.gnome.shell]
        enabled-extensions=['xremap@k0kubun.com']
      '';

      udev.extraRules = ''
        KERNEL=="uinput", GROUP="input", TAG+="uaccess"
      '';
    };

    environment.systemPackages = with pkgs; [ gnomeExtensions.xremap ];

    users.groups.input.members =
      lib.optionals (config.users ? defaultUserName)
        [ config.users.defaultUserName ];
  };
}
