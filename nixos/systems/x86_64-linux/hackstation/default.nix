# Main NixOS configuration file for 7800X3D + RTX 4090 Workstation
{ lib
, pkgs
, config
, inputs
, ...
}:

{
  imports = [];

  # Set hostname with higher priority
  networking.hostName = "hackstation";

  # User account - your account
  users.users.agucova = {
    description = "Agustín Covarrubias";
    isNormalUser = true; # Regular user account
    group = "agucova"; # Primary group with same name
    extraGroups = [ "wheel" "networkmanager" "docker" ]; # Add common groups
    shell = pkgs.fish; # Set Fish as default shell
    initialPassword = "nixos";
  };
  
  # Create the user's group
  users.groups.agucova = {};

  # Enable base module (required)
  myBase.enable = true;

  # Enable desktop features (for workstation with GNOME)
  myDesktop.enable = true;

  # Enable hardware configuration and optimizations
  myHardware = {
    enable = true; # Enable hardware module
  };

  # Enable OpenGL and NVIDIA configuration through the hardware module
  hardware = {
    graphics = {
      enable = true;
    };
    
    # Load nvidia driver for Xorg and Wayland
    nvidia = {
      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
      # of just the bare essentials.
      powerManagement.enable = false;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of
      # supported GPUs is at:
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      # Only available from driver 515.43.04+
      open = false;

      # Enable the Nvidia settings menu, accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
  
  # Load nvidia driver for Xorg
  services.xserver.videoDrivers = ["nvidia"];

  # Enable GUI applications module
  myGuiApps.enable = false;

  # Enable 1Password with SSH/CLI integration
  my1Password.enable = false;

  # Enable BTRFS with LUKS disk configuration
  myDisko = {
    enable = true;
    device = "/dev/nvme1n1"; # Primary NVMe device
    swapSize = "64G"; # Adjust based on your needs (should be at least equal to RAM for hibernation)
  };

  # Temporarily disable macOS-like keyboard remapping (for troubleshooting)
  myMacosRemap.enable = lib.mkForce false;
  
  # Home Manager configuration
  home-manager.users.agucova = { pkgs, lib, ... }: {
    imports = [
      # Import all home modules first to provide options
      ../../../modules/home/core-shell
      ../../../modules/home/dev-shell
      ../../../modules/home/desktop-settings
      ../../../modules/home/dotfiles
      ../../../modules/home/macos-remap
      ../../../modules/home/1password
      
      # Import user configuration last
      ../../../homes/x86_64-linux/agucova
    ];
    
    # Override specific settings for this system
    myMacosRemap.enable = lib.mkForce false;
    my1Password.enable = lib.mkForce false;
  };

  # Enable Docker and NvCT
  # virtualisation = {
  #   docker = {
  #     enable = true;
  #   };
  # };
  # hardware.nvidia-container-toolkit.enable = true;

  # # Additional host-specific packages
  # environment.systemPackages = with pkgs; [
  #   # Container tools
  #   docker
  #   docker-compose
  # ];

  # This value determines the NixOS release to base packages on
  # Don't change this unless you know what you're doing
  system.stateVersion = "24.11"; # This should match your initial install version
}
