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

  # User account - your account
  users.users.agucova = {
    description = "Agustín Covarrubias";
    shell = pkgs.fish; # Set Fish as default shell
    initialPassword = "nixos";
  };
  
  # Add minimal boot configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Enable base module (required)
  myBase.enable = true;
  
  # Explicitly disable macOS remapping (not needed on server)
  macos-remap.enable = false;

  # Enable minimal hardware configuration
  # This enables just firmware and generic hardware support,
  # but doesn't enable specific CPU/GPU optimizations
  myHardware = {
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
  services.pulseaudio.enable = false;

  # This value determines the NixOS release to base packages on
  # Don't change this unless you know what you're doing
  system.stateVersion = "24.11"; # This should match your initial install version
}
