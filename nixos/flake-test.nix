{
  description = "Minimal test flake for xremap";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    xremap-flake.url = "github:xremap/nix-flake";
    xremap-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, xremap-flake, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          xremap-flake.nixosModules.default
          {
            # Basic system configuration
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            
            # Enable xremap with GNOME support
            services.xremap = {
              serviceMode = "user";
              withGnome = true;
              userName = "test-user";
              config = {
                keypress_delay_ms = 10;
                modmap = [
                  {
                    name = "Make Super act as Ctrl";
                    remap = {
                      "LeftCtrl" = "LeftMeta";
                      "LeftMeta" = "LeftCtrl";
                    };
                  }
                ];
              };
            };

            # Create test user
            users.users.test-user = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
            };

            # Add user to input group
            users.groups.input.members = [ "test-user" ];

            # Configure udev rules
            services.udev.extraRules = ''
              KERNEL=="uinput", GROUP="input", TAG+="uaccess"
            '';

            # GNOME settings
            services.xserver = {
              enable = true;
              desktopManager.gnome.enable = true;
              displayManager.gdm.enable = true;
            };

            # Add GNOME extensions
            services.gnome.extensions = with pkgs.gnomeExtensions; [
              xremap
            ];

            # For build testing
            system.stateVersion = "24.11";
          }
        ];
      };
    };
}