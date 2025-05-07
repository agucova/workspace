# Main NixOS configuration file for 7800X3D + RTX 4090 Workstation
{ lib
, pkgs
, config
, inputs
, namespace
, system
, target
, format
, virtual
, systems
, ...
}:

{
  imports = [
    # Import hardware configuration if available, otherwise use minimal config
    # We'll replace this on first deploy.
    (if builtins.pathExists /etc/nixos/hardware-configuration.nix
    then /etc/nixos/hardware-configuration.nix
    else
      ({ lib, ... }: {
        # Fallback minimal hardware configuration for testing
        fileSystems."/" = lib.mkDefault {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        fileSystems."/boot" = lib.mkDefault {
          device = "/dev/disk/by-label/boot";
          fsType = "vfat";
        };
      }))
  ];

  # Set hostname with higher priority
  networking.hostName = lib.mkForce "hackstation";

  # User account - your account
  users.users.agucova = {
    isNormalUser = true;
    description = "Agustin Covarrubias";
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "audio" "input" "podman" ];
    shell = pkgs.fish; # Set Fish as default shell
    # Using a plain text password is fine for initial setup, but consider
    # changing it after installation or using hashedPassword instead
    initialPassword = "nixos";
  };

  # Enable base module (required)
  myBase.enable = true;
  
  # Enable desktop features (for workstation)
  myDesktop.enable = true;
  
  # Enable hardware configuration and optimizations
  myHardware = {
    enable = true;
    
    # CPU configuration for AMD 7800X3D
    cpu.amd = {
      enable = true;
      model = "7800X3D";
      optimizations = true;
    };
    
    # GPU configuration for NVIDIA RTX 4090
    gpu.nvidia = {
      enable = true;
      model = "RTX 4090";
      open = true;
      wayland = true;
    };
    
    # Enable performance optimizations
    performance = {
      enable = true;
      build.parallel = true;
    };
  };

  # Enable layered modules
  myGnome.enable = true;
  myGuiApps.enable = true;

  # Enable macOS-like keyboard remapping with xremap
  macos-remap.enable = true;
  snowfallorg.users.agucova.home.config.macos-remap.keybindings = true;

  # Enable Docker and NvCT
  virtualisation = {
    docker = {
      enable = true;
    };
  };
  hardware.nvidia-container-toolkit.enable = true;

  # Additional host-specific packages
  environment.systemPackages = with pkgs; [
    # Container tools
    docker
    docker-compose
    podman
  ];

  # This value determines the NixOS release to base packages on
  # Don't change this unless you know what you're doing
  system.stateVersion = "24.11"; # This should match your initial install version
}