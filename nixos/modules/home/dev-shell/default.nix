# Development packages and settings for the shell
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
      julia-bin
      # Note, this is a fallback for `uv`.
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
