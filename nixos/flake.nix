{
  description = "NixOS configuration with COSMIC Desktop";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # COSMIC Desktop
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Optional: Home Manager for user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Ghostty terminal
    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-cosmic, home-manager, ghostty, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      
      # Common NixOS module imports
      commonModules = [
        # Add nixos-cosmic module
        nixos-cosmic.nixosModules.default
        
        # Add COSMIC binary cache
        {
          nix.settings = {
            substituters = [ "https://cosmic.cachix.org/" ];
            trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
          };
        }
        
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
        # Replace "hostname" with your actual hostname after NixOS installation
        # You'll use this with: nixos-rebuild switch --flake .#hostname
        hostname = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/cosmic/configuration.nix
          ];
        };
      };
    };
}