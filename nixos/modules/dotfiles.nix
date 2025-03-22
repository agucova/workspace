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
      # Common chezmoi commands with --no-tty for safety
      cz = "chezmoi";
      czs = "chezmoi status --no-tty";
      czd = "chezmoi diff --no-tty";
      cza = "chezmoi apply --no-tty";
      cze = "chezmoi edit";
      czadd = "chezmoi add --no-tty";
      czupdate = "chezmoi update --no-tty";
      
      # Dotfiles setup using uv
      setup-dotfiles = "uv run /home/agucova/repos/workspace/dotfiles_setup.py";
    };
  };
}