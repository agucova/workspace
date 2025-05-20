# Development packages and settings for the shell
{ lib, pkgs, config, ... }:

{
  # No need for an enable option since this module is explicitly imported
  config = {
    home.packages = with pkgs; [
      # Nix tooling
      nil
      nixd
      statix

      # Languages
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
