{ lib, pkgs, config, ... }:

{
  options.dev-shell.enable =
    lib.mkEnableOption "Development packages and settings for the shell";

  config = lib.mkIf config.dev-shell.enable {
    home.packages = with pkgs; [
      # Nix tooling
      nil nixd statix

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
    ];
  };
}
