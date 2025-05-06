{
  description = "NixOS / Home-Manager mono-repo for my 7800X3D + RTX 4090 workstation fleet";

  ############################################################################
  ## 1  Inputs                                                              ##
  ############################################################################
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty.url            = "github:ghostty-org/ghostty";
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardening rules (plain Nix files, not a flake)
    nix-mineral = {
      url   = "github:cynicsketch/nix-mineral";
      flake = false;
    };
  };

  ############################################################################
  ## 2  Outputs                                                             ##
  ############################################################################
  outputs = inputs:
  let
    # Build an extended lib that knows about every input + Snowfall helpers
    lib = inputs.snowfall-lib.mkLib {
      inherit inputs;
      src = ./.;

      snowfall = {
        namespace = "workstation";
        meta = {
          name  = "workstation";
          title = "Workstation NixOS configuration";
        };
      };
    };
  in
  lib.mkFlake {

    ##########################################################################
    ## 2.1  Global nixpkgs configuration                                    ##
    ##########################################################################
    channels-config = {
      allowUnfree              = true;
      permittedInsecurePackages = [ "electron-25.9.0" ];
    };

    ##########################################################################
    ## 2.2  Overlays (extra packages shared by every build)                 ##
    ##########################################################################
    overlays = [
      (final: prev: {
        ghostty = inputs.ghostty.packages.${prev.system}.default;

        # Claude desktop arrives already wrapped inside an FHS env
        claude-desktop-with-fhs =
          inputs.claude-desktop.packages.${prev.system}.claude-desktop-with-fhs;
      })
    ];

    ##########################################################################
    ## 2.3  Modules applied to *every* NixOS host                           ##
    ##########################################################################
    systems.modules.nixos = with inputs; [
      home-manager.nixosModules.home-manager
      xremap-flake.nixosModules.default
      nix-index-database.nixosModules.nix-index
    ];

    # Make the Home-Manager wrapper available to every user that
    # imports modules from your `homes/**` tree.
    homes.modules = [
      inputs.nix-index-database.hmModules.nix-index
    ];
    
    # Enable Home Manager for the vm-test host
    systems.hosts.vm-test.specialArgs = {
      inherit inputs;
    };
  };
}
