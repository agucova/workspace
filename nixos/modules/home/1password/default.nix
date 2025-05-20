# 1Password Home Manager module
{ config, pkgs, lib, ... }:

let
  sshSignPath = "${pkgs._1password-gui}/share/1password/op-ssh-sign";
  agentSocketPath = "~/.1password/agent.sock";
in
{
  options.my1Password = {
    enableSSH = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable 1Password SSH agent integration";
    };
    
    enableGit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable 1Password Git signing integration";
    };
  };

  config = {
    # SSH configuration for 1Password identity agent
    programs.ssh = lib.mkIf config.my1Password.enableSSH {
      enable = true;  # Enable SSH config management
      extraConfig = ''
        # 1Password SSH agent configuration
        IdentityAgent "${agentSocketPath}"
      '';
    };

    # Git configuration for 1Password signing
    programs.git = lib.mkIf config.my1Password.enableGit {
      enable = true;  # Enable Git config management
      extraConfig = {
        gpg = {
          format = "ssh";
          ssh.program = sshSignPath;
        };
      };
    };
    
    # Configure Fish shell integration if Fish is enabled
    programs.fish = lib.mkIf (config.programs.fish.enable or false) {
      loginShellInit = ''
        # Source 1Password shell plugins if available
        if test -f ~/.config/op/plugins.sh
          source ~/.config/op/plugins.sh
        end
      '';
    };
    
    # Configure Bash shell integration
    programs.bash = lib.mkIf (config.programs.bash.enable or false) {
      initExtra = ''
        # Source 1Password shell plugins if available
        if [ -f ~/.config/op/plugins.sh ]; then
          source ~/.config/op/plugins.sh
        fi
      '';
    };
  };
}