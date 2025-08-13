# Cross-platform shell configuration
# Works on both NixOS and Darwin via Home Manager
{
  lib,
  config,
  pkgs,
  ...
}:

{
  config = {
    # Global environment variables (available across all shells)
    home.sessionVariables = {
      EDITOR = "micro";
      LANG = "en_US.UTF-8";
      CLAUDE_CONFIG_DIR = "$HOME/.config/claude-code/";
    };

    # Global PATH additions (available across all shells)
    home.sessionPath = [
      "$HOME/.bin"
      "$HOME/.bun/bin"
      "$HOME/.venv/bin"
    ];

    # Shell packages
    home.packages = with pkgs; [
      # Core CLI tools
      gh
      bat
      ripgrep
      fd
      fzf
      jq
      httpie
      shellcheck
      delta
      hyperfine
      glow
      chezmoi
      fastfetch
      lsd
      navi
      btop
      whois
      iperf
      aria2
      tree
      unrar
      p7zip
      starship
      _1password-cli
      micro
      uv
      git
      delta
      difftastic
      nh
      prettyping
    ];

    programs = {
      # Fish shell configuration
      fish = {
        enable = true;
        shellInit = ''
          # fzf configuration using fd as a backend
          # Shows hidden files but excludes .git directories
          set -gx FZF_DEFAULT_COMMAND 'fd --type file --hidden --exclude .git'
          set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
          set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'

          # Pretty man pages if bat exists
          if command -v bat >/dev/null
            set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
          end

          # Disable default MOTD
          set fish_greeting ""

          # uv completions
          if command -q uv
              # Enable shell completions for uv
              uvx --generate-shell-completion fish | source
          end

          # Configure pip to use uv as the backend
          set -gx PIP_REQUIRE_VIRTUALENV true
          set -gx PIP_USE_UV true
        '';
        interactiveShellInit = ''
          # Fastfetch motd
          if command -v fastfetch >/dev/null
            # Shell is running interactively

            # Display system info with fastfetch (minimal setup)
            fastfetch --gpu-hide-type integrated --gpu-detection-method auto -s Title:OS:Host:CPU:GPU:Memory:Disk:Kernel:DE:Shell:Terminal
          end

          # Starship prompt
          starship init fish | source

          # Enable colour hints in VCS prompt:
          set __fish_git_prompt_showcolorhints yes
          set __fish_git_prompt_color_prefix purple
          set __fish_git_prompt_color_suffix purple

          # Darwin-specific integrations
          ${lib.optionalString pkgs.stdenv.isDarwin ''
            # iTerm2 shell integration
            if test -e "$HOME/.iterm2_shell_integration.fish"
              source "$HOME/.iterm2_shell_integration.fish"
            end

            # Orbstack shell integration
            if test -d "$HOME/.orbstack"
              source "$HOME/.orbstack/shell/init2.fish" 2>/dev/null || :
            end
          ''}
        '';
        shellAliases = {
          # Dotfiles setup
          setup-dotfiles = "mkdir -p ~/repos && cd ~/repos && \
              git clone https://github.com/agucova/workspace && \
              cd workspace/pyinfra && uv run dotfiles_setup.py";
        };
      };

      # Bash configuration (minimal, as fallback)
      bash = {
        enable = true;
        initExtra = ''eval "$(starship init bash)"'';
      };

      # Starship prompt
      starship = {
        enable = true;
      };

      # Git configuration
      git = {
        enable = true;
        userName = "Agustin Covarrubias";
        userEmail = "gh@agucova.dev";
        signing.signByDefault = true;
        signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhdO9i6GAtDT+iyfkqUFoOzPaKmuP1aCQ1zXtaKYqA5";
        extraConfig = {
          init.defaultBranch = "main";
          color.ui = "auto";
          rebase.stat = true;
          pull.rebase = false;

          # Comfort settings (based on Julia Evan's recs)
          # https://jvns.ca/blog/2024/02/16/popular-git-config-options
          merge.conflictstyle = "zdiff3";
          push.autoSetupRemote = true;
          rerere.enabled = true;
          help.autocorrect = "prompt";
          diff.algorithm = "histogram";
          transfer.fsckobjects = true;
          fetch.fsckobjects = true;
          receive.fsckobjects = true;
          status.submoduleSummary = true;
          diff.submodule = "log";
          submodule.recurse = true;
          rebase.missingCommitsCheck = "error";
          branch.sort = "committerdate";

          # Difftastic
          diff.external = "difft";
        };
      };
    };
  };
}
