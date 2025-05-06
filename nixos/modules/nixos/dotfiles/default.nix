# Dotfiles integration with chezmoi and 1Password
{ config, pkgs, lib, ... }:

{
  # Install required tools system-wide
  environment.systemPackages = with pkgs; [
    # Core tools needed for dotfiles
    chezmoi
    _1password-cli
    _1password-gui  # 1Password desktop application
    git
    gh  # GitHub CLI
    uv   # Modern Python package installer
  ];

  # Home Manager configuration for chezmoi
  home-manager.users.agucova = { pkgs, lib, ... }: {
    # Add shell integration for chezmoi
    programs.fish.shellAliases = {
      # Dotfiles setup using uv
      setup-dotfiles = "mkdir repos && cd repos && git clone https://github.com/agucova/workspace && cd workspace/pyinfra/ && uv run dotfiles_setup.py";
    };
  };
}