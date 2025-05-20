{ lib, config, ... }:

let
  cfg = config.myMacosRemap;
in
{
  options.myMacosRemap = {
    enable = lib.mkEnableOption "macOS keyboard remapping for GNOME & VS Code";
  };

  config = lib.mkIf cfg.enable {
    dconf.settings =
      import ./dconf.nix;

    programs.vscode.profiles.default.keybindings =
      import ./vscode-keybindings.nix;
  };
}
