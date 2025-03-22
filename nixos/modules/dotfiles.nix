# Dotfiles integration with chezmoi and 1Password
{ config, pkgs, lib, ... }:

let 
  dotfilesRepo = "https://github.com/agucova/dotfiles.git";
  dotfilesPath = "/home/agucova/repos/dotfiles";
in
{
  # Install 1Password CLI system-wide
  environment.systemPackages = with pkgs; [
    _1password-cli
  ];

  # Home Manager configuration for chezmoi
  home-manager.users.agucova = { pkgs, lib, ... }: {
    # Install chezmoi via home-manager
    home.packages = with pkgs; [
      chezmoi
    ];

    # Clone the dotfiles repo but don't apply (requires 1Password login first)
    home.activation.cloneDotfiles = lib.hm.dag.entryAfter [ "installPackages" ] ''
      if [ ! -d "${dotfilesPath}/.git" ]; then
        echo "Cloning dotfiles repository..."
        $DRY_RUN_CMD rm -rf "${dotfilesPath}" # Remove dir if exists but isn't a git repo
        $DRY_RUN_CMD mkdir -p "$(dirname ${dotfilesPath})"
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone ${dotfilesRepo} ${dotfilesPath}
        
        if [ -d "${dotfilesPath}/.git" ]; then
          echo "Dotfiles successfully cloned with $(find ${dotfilesPath} -type f | wc -l) files."
          echo "To apply, first login to 1Password with 'op signin' then run 'chezmoi init --source=${dotfilesPath} --apply --no-tty'"
        else
          echo "Error: Failed to clone dotfiles properly. Please check manually."
        fi
      else
        echo "Checking dotfiles repository at ${dotfilesPath}..."
        cd ${dotfilesPath} && $DRY_RUN_CMD ${pkgs.git}/bin/git pull
        echo "Dotfiles repository updated. $(find ${dotfilesPath} -type f | wc -l) files present."
        echo "To apply, first login to 1Password with 'op signin' then run 'chezmoi apply --no-tty'"
      fi
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
      
      # 1Password and chezmoi initialization alias
      czinit = "op signin && chezmoi init --source=${dotfilesPath} --apply --no-tty";
    };
  };
}