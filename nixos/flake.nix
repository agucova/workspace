{
  description = "NixOS configuration with GNOME Desktop";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Optional: Home Manager for user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Ghostty terminal
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
  };

  outputs = { self, nixpkgs, home-manager, ghostty, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # Make ghostty available as a regular package
          (final: prev: {
            ghostty = ghostty.packages.${system}.default;
          })
        ];
      };
      
      # Common NixOS module imports
      commonModules = [
        # Optional: Add home-manager as a NixOS module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ];
    in
    {
      # NixOS Configurations
      nixosConfigurations = {
        # Configuration for GNOME setup
        "gnome-nixos" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/gnome/configuration.nix
          ];
        };
      };
    };
}