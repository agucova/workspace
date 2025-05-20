# macOS keyboard remapping for GNOME & VS Code
{ lib, config, ... }:

{
  # No need for an enable option since this module is explicitly imported
  config = {
    dconf.settings =
      import ./dconf.nix;

    programs.vscode.profiles.default.keybindings =
      import ./vscode-keybindings.nix;
  };
}
