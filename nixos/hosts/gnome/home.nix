# Home Manager configuration for agucova
{ config, pkgs, lib, nix-index-database, ... }:

{
  # Home Manager version
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Import the nix-index-database module
  imports = [
    nix-index-database.hmModules.nix-index
  ];

  # Configure programs and tools
  programs = {
    # Enable nix-index with comprehensive shell integration
    nix-index = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      enableZshIntegration = true;  # Enable for all shells to be safe
    };
    
    # Enable comma functionality from nix-index-database
    # This also ensures the nix-index database is properly linked
    nix-index-database.comma.enable = true;
    
    # Configure shells
    fish = {
      enable = true;
      
      # Initialize starship prompt
      interactiveShellInit = ''
        # Use starship prompt
        starship init fish | source
        
        # Set batcat as man pager if available
        if command -v bat > /dev/null
          set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
        end
      '';
      
      # Shell aliases
      shellAliases = {
        # Better ls using lsd
        ls = "lsd";
        ll = "lsd -l";
        la = "lsd -la";
        lt = "lsd --tree";
        
        # Git shortcuts
        g = "git";
        gc = "git commit";
        gs = "git status";
        gp = "git push";
        gpl = "git pull";
        
        # Use bat instead of cat
        cat = "bat";
        
        # Better directory navigation
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
      };
    };
    
    bash = {
      enable = true;
      
      # Initialize starship prompt
      initExtra = ''
        # Use starship prompt
        eval "$(starship init bash)"
      '';
    };

    # Configure git
    git = {
      enable = true;
      userName = "Agustin Covarrubias";
      userEmail = "gh@agucova.dev";
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };

  # Packages to install for this user
  home.packages = with pkgs; [
    # Development tools (CLI)
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
    
    # Shell enhancements (CLI)
    lsd
    starship
    btop
    fastfetch
    gdu
    navi
    
    # Programming languages and tools (CLI)
    rustup
    go_1_22
    bun
    (julia.withPackages [
      "Plots"
      "DifferentialEquations"
      "Revise"
      "OhMyREPL"
      "Literate"
      "Pluto"
      "BenchmarkTools"
    ])
    (python3.withPackages(ps: with ps; [
      pip
      ipython
      numpy
      pandas
      matplotlib
      seaborn
      scikit-learn
      black
      flake8
      mypy
    ]))
    
    # Network utilities (CLI)
    nmap
    whois
    iperf
    aria2
    
    # CLI utilities
    tree
    unrar
    p7zip
  ];
}
