# Development packages and settings for the shell
{ lib, pkgs, config, ... }:

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
      (julia.withPackages [
        "Plots"
        "Revise"
        "OhMyREPL"
        "BenchmarkTools"
      ])
      (python3.withPackages (ps: with ps; [
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
      ruff
      pyright
    ];
  };
}
