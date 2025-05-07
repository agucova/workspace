# Server NixOS configuration file
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

  # Set hostname
  networking.hostName = "server";

  # User account - your account
  users.users.agucova = {
    isNormalUser = true;
    description = "Agustin Covarrubias";
    extraGroups = [ "wheel" ];
    shell = pkgs.fish; # Set Fish as default shell
    # Using a plain text password is fine for initial setup, but consider
    # changing it after installation or using hashedPassword instead
    initialPassword = "nixos";
  };

  # Enable base module (required)
  modules.base.enable = true;
  
  # Enable minimal hardware configuration
  # This enables just firmware and generic hardware support,
  # but doesn't enable specific CPU/GPU optimizations
  modules.hardware = {
    enable = true;
    
    # Enable performance optimizations but not hardware-specific ones
    performance = {
      enable = true;
      build.parallel = true;
    };
    
    # If server has specific hardware, can be enabled like:
    # cpu.intel.enable = true;
    # or
    # cpu.amd.enable = true; 
  };
  
  # Server-specific SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Additional server-specific packages
  environment.systemPackages = with pkgs; [
    # Server tools
    tmux
    htop
    iotop
    iftop
    jq
    ripgrep
    fd
  ];

  # Disable sound system completely
  sound.enable = false;
  hardware.pulseaudio.enable = false;

  # This value determines the NixOS release to base packages on
  # Don't change this unless you know what you're doing
  system.stateVersion = "24.11"; # This should match your initial install version
}