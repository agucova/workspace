# nix-mineral configuration with minimal gaming-friendly overrides
{ config, lib, pkgs, nix-mineral, ... }:

{
  imports = [
    # Import the main nix-mineral module
    "${nix-mineral}/nix-mineral.nix"
  ];

  # Enable nix-mineral
  nix-mineral.enable = true;

  # Fix source conflicts
  environment.etc.issue.source = lib.mkForce (pkgs.writeText "issue" "\\n \\l");
  environment.etc.gitconfig.source = lib.mkForce (pkgs.writeText "empty-gitconfig" ""); # <-- ADD FIX HERE

  # Minimal required overrides for gaming compatibility
  nix-mineral.overrides = {
    # Gaming requires execution capabilities
    desktop = {
      # Allow execution in home directory (required for most games)
      home-exec = true;
      # Allow execution in /tmp (needed by launchers and installers)
      tmp-exec = true;
      # Allow multilib for Steam and 32-bit games
      allow-multilib = true;
      # Allow unprivileged user namespaces for Flatpak and browser sandboxing
      allow-unprivileged-userns = true;
    };

    # Performance is critical for gaming
    performance = {
      # Enable SMT for better multi-threaded performance
      allow-smt = true;
    };
  };
}
