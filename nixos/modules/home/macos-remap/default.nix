{ lib, config, ... }:

{
  options.macos-remap.keybindings =
    lib.mkEnableOption "mac-style GNOME & VS Code bindings";

  config = lib.mkIf config.macos-remap.keybindings {
    dconf.settings =
      import ./dconf.nix;

    programs.vscode.profiles.default.keybindings =
      import ./vscode-keybindings.nix;
  };
}
