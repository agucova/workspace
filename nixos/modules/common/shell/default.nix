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
      jj-starship
      _1password-cli
      micro
      uv
      git
      delta
      difftastic
      nh
      prettyping

      # Media and content tools
      yt-dlp
      zbar
      tldr

      # Network tools
      nmap
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
            fastfetch -s Title:OS:Host:CPU:GPU:Memory:Disk:Kernel:DE:Shell:Terminal
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
        settings = {
          # General prompt setup
          # Note: $custom includes jj-starship which handles both git and jj repos
          format = "$username$hostname$directory$custom$direnv$nix_shell$cmd_duration$line_break$python$character";

          # Command execution time
          cmd_duration = {
            min_time = 1000;
            format = "took [$duration]($style)";
            style = "yellow";
          };

          # Prompt character
          character = {
            success_symbol = "[➜](bold green)";
            error_symbol = "[✗](bold red)";
            vimcmd_symbol = "[V](bold green)";
          };

          # Directory
          directory = {
            truncation_length = 3;
            truncate_to_repo = true;
            style = "blue bold";
          };

          # Git modules disabled - jj-starship handles both git and jj repos
          git_branch.disabled = true;
          git_status.disabled = true;
          git_state.disabled = true;

          # Development environments
          python = {
            symbol = "🐍 ";
            python_binary = "python3";
            style = "green bold";
          };

          bun = {
            format = "via [$symbol]($style)";
            symbol = "🥟 ";
            style = "bold red";
          };

          golang = {
            format = "via [$symbol]($style)";
            symbol = "🦫 ";
            style = "bold blue";
          };

          julia = {
            format = "via [$symbol]($style)";
            symbol = "ஃ ";
            style = "bold purple";
          };

          # Battery
          battery = {
            full_symbol = "🔋";
            charging_symbol = "⚡";
            discharging_symbol = "💀";
            display = [{ threshold = 25; style = "bold red"; }];
          };

          # Disabled modules
          aws.disabled = true;
          docker_context.disabled = true;
          package.disabled = true;

          # Direnv status indicator
          direnv = {
            disabled = false;
            format = "[$symbol$loaded]($style) ";
            symbol = "";
            style = "bold yellow";
            loaded_msg = "✓";
            unloaded_msg = "";
            allowed_msg = "";
            not_allowed_msg = "!";
            denied_msg = "✗";
          };

          # Nix shell indicator
          nix_shell = {
            disabled = false;
            format = "via [$symbol$state]($style) ";
            symbol = "❄️ ";
            style = "bold blue";
            impure_msg = "";
            pure_msg = "pure";
            unknown_msg = "";
            heuristic = true;
          };

          # Custom jujutsu (jj) module using jj-starship
          # Uses sh to avoid loading fish rc files (~5x faster)
          # See: https://github.com/dmmulroy/jj-starship
          custom.jj = {
            command = "jj-starship";
            format = "$output ";
            detect_folders = [ ".jj" ".git" ];
            shell = [ "sh" ];
          };
        };
      };

      # Direnv with devenv integration
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        stdlib = ''
          # devenv integration (v1.4+)
          # This provides the use_devenv function for .envrc files
          eval "$(devenv direnvrc)"
        '';
        config = {
          global.hide_env_diff = true;
        };
      };

      # Git configuration
      git = {
        enable = true;
        signing.signByDefault = true;
        signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhdO9i6GAtDT+iyfkqUFoOzPaKmuP1aCQ1zXtaKYqA5";
        settings = {
          user.name = "Agustin Covarrubias";
          user.email = "gh@agucova.dev";
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
