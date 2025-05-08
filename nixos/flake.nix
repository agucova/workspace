{
  description = "NixOS / Home-Manager mono-repo for my 7800X3D + RTX 4090 workstation fleet";

  ############################################################################
  #  Inputs                                                                  #
  ############################################################################
  inputs = {
    # Core dependencies
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    flake-utils.url = "github:numtide/flake-utils";
    
    # Tools and generators
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Application dependencies
    ghostty.url = "github:ghostty-org/ghostty";
    
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    
    # System enhancements
    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Security
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral";
      flake = false; # Plain Nix files, not a flake
    };
  };

  ############################################################################
  #  Outputs                                                                 #
  ############################################################################
  outputs = inputs:
    let
      # Build an extended lib with Snowfall helpers
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        snowfall = {
          namespace = "workstation";
          meta = {
            name = "workstation";
            title = "Workstation NixOS configuration";
          };
        };
      };
    in
    lib.mkFlake {
      # Global nixpkgs configuration
      channels-config = {
        allowUnfree = true;
      };

      # Overlays (extra packages shared by every build)
      overlays = [
        (_: prev: {
          # Terminal emulator with GPU acceleration
          ghostty = inputs.ghostty.packages.${prev.system}.default;

          # Claude desktop wrapped inside an FHS env
          inherit (inputs.claude-desktop.packages.${prev.system}) claude-desktop-with-fhs;
        })
      ];

      # Modules applied to all NixOS hosts
      systems.modules.nixos = with inputs; [
        # Home-manager integration
        home-manager.nixosModules.home-manager
        {
          home-manager.useUserPackages = true;
        }
        
        # System enhancements
        xremap-flake.nixosModules.default # macOS-style keyboard remapping (disabled by default)
        disko.nixosModules.disko # Declarative disk management
        
        # Tools
        nix-index-database.nixosModules.nix-index # Command-not-found replacement
      ];

      # Modules applied to all home-manager configurations
      homes.modules = with inputs; [
        nix-index-database.hmModules.nix-index # Command-not-found replacement for home-manager
      ];
    };
}
