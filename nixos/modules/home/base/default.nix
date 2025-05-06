# modules/home/base/default.nix
#
# Base Home-Manager profile shared by every user in the Snowfall repo.
{ config, pkgs, lib, inputs ? {}, ... }:

{
  ## Home-Manager version pin (don’t touch once the machine is installed)
  home.stateVersion = "24.11";

  ## Let Home-Manager manage itself
  programs.home-manager.enable = true;

  ## ───────────────────────── Programs & CLI helpers ─────────────────────────
  programs = {
    # nix-index with the pre-built database provided by
    # inputs.nix-index-database.hmModules.nix-index
    nix-index = {
      enable                 = true;
      enableFishIntegration  = true;
      enableBashIntegration  = true;
      enableZshIntegration   = true;
    };

    # “, pkg …” helper from nix-index-database
    nix-index-database.comma.enable = true;

    # Fish shell configuration
    fish = {
      enable = true;

      interactiveShellInit = ''
        # Starship prompt
        starship init fish | source

        # Pretty man pages if bat exists
        if command -v bat >/dev/null
          set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
        end
      '';

      shellAliases = {
        # Better ls
        ls  = "lsd";
        ll  = "lsd -l";
        la  = "lsd -la";
        lt  = "lsd --tree";

        # cat → bat
        cat = "bat";

        # Quick directory jumps
        ".."   = "cd ..";
        "..."  = "cd ../..";
        "...." = "cd ../../..";
      };
    };

    # Bash configuration (keep minimal; most users will use Fish)
    bash = {
      enable    = true;
      initExtra = ''eval "$(starship init bash)"'';
    };

    # Git defaults
    git = {
      enable   = true;
      userName = "Agustin Covarrubias";
      userEmail = "gh@agucova.dev";
      extraConfig.init.defaultBranch = "main";
    };
  };
  home.packages = with pkgs; [
    # Dev / CLI basics
    gh bat ripgrep fd fzf jq httpie shellcheck delta hyperfine glow chezmoi

    # Nix tooling
    nil nixd statix

    # Shell & monitoring
    lsd starship btop fastfetch gdu navi

    # Languages
    rustup go_1_22 bun
    (julia.withPackages [
      "Plots" "DifferentialEquations" "Revise" "OhMyREPL" "Literate"
      "Pluto" "BenchmarkTools"
    ])
    (python3.withPackages (ps: with ps; [
      pip ipython numpy pandas matplotlib seaborn scikit-learn
      black flake8 mypy
    ]))
    ruff pyright

    # Networking & files
    nmap whois iperf aria2 tree unrar p7zip
  ];
}
