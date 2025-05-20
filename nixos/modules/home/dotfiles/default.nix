# Dotfiles deployment with Chezmoi
{ lib, pkgs, config, ... }:

{
  # No need for an enable option since this module is explicitly imported
  config = {
    home.packages = with pkgs; [
      chezmoi
      uv
      git
      gh
    ];
    programs.fish.shellAliases.setup-dotfiles = "mkdir -p ~/repos && cd ~/repos && \
        git clone https://github.com/agucova/workspace && \
        cd workspace/pyinfra && uv run dotfiles_setup.py";
  };
}
