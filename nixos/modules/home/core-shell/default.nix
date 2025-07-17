# modules/home/core-shell/default.nix
# Core shell with Fish, Starship, and common CLI tools
{
  lib,
  config,
  pkgs,
  ...
}:

{
  # No need for an enable option since this module is explicitly imported
  config = {
    home.packages = with pkgs; [
      # Dev / CLI basics
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
    ];

    programs = {
      fish = {
        enable = true;
        shellInit = ''
          # Editor configuration and Unicode support
          set -gx EDITOR "micro"
          set -gx LANG en_US.UTF-8
          set -gx CLAUDE_CONFIG_DIR ~/.config/claude-code/

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

              # Add uv-created venvs to PATH
              fish_add_path "$HOME/.venv/bin"
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
        '';
        shellAliases = {
          ls = "lsd";
          ll = "lsd -l";
          la = "lsd -la";
          lt = "lsd --tree";
          cat = "bat";
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
        };
      };

      bash = {
        enable = true;
        initExtra = ''eval "$(starship init bash)"'';
      };

      starship = {
        enable = true;
      };

      git = {
        enable = true;
        userName = "Agustin Covarrubias";
        userEmail = "gh@agucova.dev";
        signing.signByDefault = true;
        signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhdO9i6GAtDT+iyfkqUFoOzPaKmuP1aCQ1zXtaKYqA5";
        extraConfig = {
          init.defaultBranch = "main";
        };
      };
    };
  };
}
