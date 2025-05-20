# Helper library for flake-parts 
{ lib, ... }:

rec {
  # Import all .nix files from a directory, excluding dirs with another nix file inside
  # Returns attrset of paths to evaluated modules
  importDirModules = dir: 
    let
      files = lib.filterAttrs (n: v: 
        v == "regular" && n != "default.nix" && lib.strings.hasSuffix ".nix" n
      ) (builtins.readDir dir);
      
      dirs = lib.filterAttrs (n: v: 
        v == "directory" && builtins.pathExists (dir + "/${n}/default.nix")
      ) (builtins.readDir dir);
      
      # Import regular .nix files
      fileModules = lib.mapAttrs (n: _: import (dir + "/${n}")) files;
      
      # Import directories with default.nix
      dirModules = lib.mapAttrs (n: _: import (dir + "/${n}")) dirs;
    in
      fileModules // dirModules;

  # Import all NixOS modules
  importNixosModules = path: 
    let
      isDirectory = v: v == "directory";
      moduleDir = path + "/modules/nixos";
      moduleNames = lib.filter (n: isDirectory (builtins.readDir moduleDir)."${n}") 
        (lib.attrNames (builtins.readDir moduleDir));
    in
      map (name: moduleDir + "/${name}") moduleNames;

  # Import all Home Manager modules
  importHomeModules = path:
    let
      isDirectory = v: v == "directory";
      moduleDir = path + "/modules/home";
      moduleNames = lib.filter (n: isDirectory (builtins.readDir moduleDir)."${n}") 
        (lib.attrNames (builtins.readDir moduleDir));
    in
      map (name: moduleDir + "/${name}") moduleNames;

  # Check if NixOS hardware configuration exists
  getHardwareConfig = {
    # Try to find hardware configuration file
    # First in /etc/nixos, then in /mnt/etc/nixos, fallback to builtin
    hardwareConfig = 
      if builtins.pathExists /etc/nixos/hardware-configuration.nix then
        /etc/nixos/hardware-configuration.nix
      else if builtins.pathExists /mnt/etc/nixos/hardware-configuration.nix then
        /mnt/etc/nixos/hardware-configuration.nix
      else 
        null;
  };

  # Create a NixOS system configuration
  mkNixosConfiguration = { 
    inputs,
    hostname,
    system ? "x86_64-linux",
    extraModules ? [],
    extraArgs ? {},
    basePath ? ../.,
  }: 
  let
    inherit (inputs) nixpkgs home-manager;
    hostPath = basePath + "/systems/${system}/${hostname}";
    hardware = getHardwareConfig;
    baseModules = [
      # Required modules
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index
      inputs.xremap-flake.nixosModules.default
      
      # Home Manager settings
      {
        home-manager.useUserPackages = true;
        home-manager.useGlobalPkgs = true;
      }
      
      # Host configuration
      hostPath
    ];
    
    # Add hardware config if it exists
    modulesWithHardware = baseModules ++ (
      if hardware.hardwareConfig != null then [ hardware.hardwareConfig ] else []
    ) ++ extraModules;
    
  in nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { 
      inherit inputs hostname;
    } // extraArgs;
    modules = modulesWithHardware;
  };

  # Create a Home Manager configuration  
  mkHomeConfiguration = {
    inputs,
    username,
    hostname ? "hackstation",
    system ? "x86_64-linux",
    extraModules ? [],
    extraArgs ? {},
    basePath ? ../.,
  }:
  let
    inherit (inputs) nixpkgs home-manager;
    userPath = basePath + "/homes/${system}/${username}";
    baseModules = [
      # User configuration
      userPath
      
      # Required modules
      inputs.nix-index-database.hmModules.nix-index
    ] ++ extraModules;
    
  in home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.${system};
    extraSpecialArgs = { 
      inherit inputs username hostname;
    } // extraArgs;
    modules = baseModules;
  };

  # Dynamically import all NixOS configurations
  importAllNixosConfigurations = { 
    inputs,
    basePath ? ../.,
    system ? "x86_64-linux",
    extraModules ? [],
    extraArgs ? {},
  }:
  let
    hostsDir = basePath + "/systems/${system}";
    hostNames = lib.filter (n: ((builtins.readDir hostsDir)."${n}" == "directory"))
      (lib.attrNames (builtins.readDir hostsDir));
      
    mkHost = hostname: {
      name = hostname;
      value = mkNixosConfiguration {
        inherit inputs hostname system extraModules extraArgs basePath;
      };
    };
  in
    lib.listToAttrs (map mkHost hostNames);

  # Dynamically import all Home Manager configurations
  importAllHomeConfigurations = {
    inputs,
    basePath ? ../.,
    system ? "x86_64-linux",
    extraModules ? [],
    extraArgs ? {},
  }:
  let
    usersDir = basePath + "/homes/${system}";
    userNames = lib.filter (n: (builtins.readDir usersDir)."${n}" == "directory")
      (lib.attrNames (builtins.readDir usersDir));
      
    mkHome = username: {
      name = "${username}@hackstation"; # Default hostname
      value = mkHomeConfiguration {
        inherit inputs username system extraModules extraArgs basePath;
      };
    };
  in
    lib.listToAttrs (map mkHome userNames);
}