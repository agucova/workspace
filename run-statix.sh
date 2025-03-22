#!/usr/bin/env bash
# Wrapper script to run statix via nix-shell

nix-shell -p statix --run "statix $@"
