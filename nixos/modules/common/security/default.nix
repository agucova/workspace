# 1Password Home Manager module
{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Platform-specific agent socket paths
  agentSocketPath =
    if pkgs.stdenv.isDarwin
    then "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else "~/.1password/agent.sock";
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
      enable = true; # Enable SSH config management
      enableDefaultConfig = false; # Opt out of deprecated default config
      matchBlocks."*" = {
        extraOptions = {
          IdentityAgent = "\"${agentSocketPath}\"";
        };
      };
    };

    # Git configuration for 1Password signing
    programs.git = lib.mkIf config.my1Password.enableGit {
      enable = true; # Enable Git config management
      settings = {
        gpg = {
          format = "ssh";
          ssh.program =
            if pkgs.stdenv.isDarwin
            then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
            else lib.getExe' pkgs._1password-gui "op-ssh-sign";
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
