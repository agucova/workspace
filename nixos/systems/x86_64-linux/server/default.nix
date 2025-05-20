# Server NixOS configuration file
{ lib
, pkgs
, config
, inputs
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

  # Set hostname
  networking.hostName = "server";

  # User account - your account
  users.users.agucova = {
    description = "Agustín Covarrubias";
    isNormalUser = true; # Regular user account
    group = "agucova"; # Primary group with same name
    extraGroups = [ "wheel" "networkmanager" ]; # Add common groups
    shell = pkgs.fish; # Set Fish as default shell
    initialPassword = "nixos";
  };
  
  # Create the user's group
  users.groups.agucova = {};
  
  # Add minimal boot configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Base module is directly imported in flake.nix
  # Disable macOS remapping on server
  myMacosRemap.enable = false;

  # Server hardware configuration
  # Commented out since we can't determine the actual hardware without deploying
  # Uncomment and set the appropriate CPU type when deploying
  # myHardware = {
  #   cpu.amd.enable = true;  # For AMD-based server
  #   # cpu.intel.enable = true;  # For Intel-based server
  # };

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

  # Home Manager configuration
  home-manager.users.agucova = { pkgs, lib, ... }: {
    imports = [
      # Import only server-relevant modules
      ../../../modules/home/core-shell
      ../../../modules/home/dev-shell
      ../../../modules/home/dotfiles
      
      # Import user configuration last
      ../../../homes/x86_64-linux/agucova
    ];
    
    # Override to disable desktop-related settings
    my1Password = {
      enableSSH = false;
      enableGit = false;
    };
  };

  # This value determines the NixOS release to base packages on
  # Don't change this unless you know what you're doing
  system.stateVersion = "24.11"; # This should match your initial install version
}
