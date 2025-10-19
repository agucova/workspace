# Cross-platform development tools
# Works on both NixOS and Darwin via Home Manager
{ pkgs, ... }:

{
  config = {
    # Julia environment variables
    home.sessionVariables = {
      JULIA_COPY_STACKS = "1"; # Enable stack copying for better diagnostics
      JULIA_NUM_THREADS = "12"; # Use multiple threads for parallel computing
    };

    home.packages = with pkgs; [
      # Nix tooling
      nil
      nixd
      statix
      claude-code

      # Languages
      rustup
      bun
      (julia-bin.overrideAttrs (oldAttrs: {
        doCheck = false;
        doInstallCheck = false;
      }))

      # Python environment (fallback for uv)
      (python3.withPackages (
        ps: with ps; [
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
        ]
      ))
      ruff
      pyright

      postgresql
    ];
  };
}
