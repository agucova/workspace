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
      ({ lib, modulesPath, ... }: {
        # Import the qemu-guest module for testing
        imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

        # Fallback minimal hardware configuration for testing
        boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_blk" ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ "kvm-amd" ];
        boot.extraModulePackages = [ ];

        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };

        fileSystems."/boot" = {
          device = "/dev/disk/by-label/boot";
          fsType = "vfat";
        };

        swapDevices = [ ];
      }))
  ];

  # Set hostname with higher priority
  networking.hostName = lib.mkForce "hackstation";

  # User account - your account
  users.users.agucova = {
    description = "Agustín Covarrubias";
    extraGroups = [ "docker" ];
    shell = pkgs.fish; # Set Fish as default shell
    initialPassword = "nixos";
  };

  # Enable base module (required)
  myBase.enable = true;

  # Enable desktop features (for workstation with GNOME)
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

  # Enable GUI applications module
  myGuiApps.enable = true;
  
  # Enable 1Password with SSH/CLI integration
  my1Password.enable = true;

  # Enable macOS-like keyboard remapping with xremap
  macos-remap.enable = true;
  snowfallorg.users.agucova.home.config = {
    macos-remap.keybindings = true;
    my1Password.enable = true;
  };

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
