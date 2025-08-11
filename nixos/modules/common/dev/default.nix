# Cross-platform development tools
# Works on both NixOS and Darwin via Home Manager
{ pkgs, ... }:

{
  config = {
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
    ];
  };
}