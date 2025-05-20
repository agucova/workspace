# macOS keyboard remapping for GNOME & VS Code
# This module is automatically enabled when imported (no enable option needed)
{ lib, config, ... }:

{
  # Home configuration for macOS-style keybindings
  config = {
    # Import dconf settings from separate file
    dconf.settings = import ./dconf.nix;

    # Import VS Code keybindings from separate file
    programs.vscode.profiles.default.keybindings = import ./vscode-keybindings.nix;
  };
}
