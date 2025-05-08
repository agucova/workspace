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
    # Import hardware configuration with fallback for installation environment
    (if builtins.pathExists /etc/nixos/hardware-configuration.nix
     then /etc/nixos/hardware-configuration.nix
     else if builtins.pathExists /mnt/etc/nixos/hardware-configuration.nix
     then /mnt/etc/nixos/hardware-configuration.nix
     else /etc/nixos/hardware-configuration.nix) # Fallback to default even if it doesn't exist yet
  ];
  # Set hostname with higher priority
  networking.hostName = "hackstation";

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
      open = lib.mkForce false; # Use proprietary drivers for now
      wayland = lib.mkForce false; # Use X11 for now
    };

    # Enable performance optimizations
    performance = {
      enable = true;
      build.parallel = true;
    };
  };

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
  macos-remap.enable = lib.mkForce false;
  snowfallorg.users.agucova.home.config = {
    macos-remap.keybindings = lib.mkForce false;
    my1Password.enable = true;
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
