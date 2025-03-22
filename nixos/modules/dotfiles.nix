# Dotfiles integration with chezmoi
{ config, pkgs, lib, ... }:

let 
  dotfilesRepo = "/home/agucova/repos/dotfiles";
in
{
  # Home Manager configuration for chezmoi
  home-manager.users.agucova = { pkgs, lib, ... }: {
    # Install chezmoi via home-manager
    home.packages = with pkgs; [
      chezmoi
    ];

    # Activate chezmoi dotfiles after Home Manager has installed packages
    home.activation.chezmoi = lib.hm.dag.entryAfter [ "installPackages" ] ''
      $DRY_RUN_CMD ${pkgs.chezmoi}/bin/chezmoi init --source=${dotfilesRepo} --no-tty --force --apply
    '';

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
    };
  };
}