{ lib, pkgs, config, ... }:

{
  options.dotfiles.enable =
    lib.mkEnableOption "Dotfiles deployment with Chezmoi";

  config = lib.mkIf config.dotfiles.enable {
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
