# ISO image specific configuration - centralized all ISO customizations here
{ config, lib, pkgs, ... }:

{
  # Set ISO image configuration
  isoImage = {
    isoName = "nixos-gnome-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    makeEfiBootable = true;
    makeUsbBootable = true;
    volumeID = "NIXOS_GNOME";
    # Include our configuration in the ISO
    contents = [
      { source = ./..;
        target = "/nixos-config";
      }
    ];
  };
  
  # Override boot loader timeout for the ISO (longer for better usability)
  boot.loader.timeout = lib.mkForce 30;

  # Enable kernel modules and filesystems needed for live environments
  boot.supportedFilesystems = [ "ntfs" "btrfs" "ext4" "vfat" "f2fs" ];
  boot.kernelModules = [ "uas" "usbcore" "usb_storage" "nls_cp437" "nls_iso8859_1" ];
  
  # Conflict resolution for security settings in live media
  security = {
    # Disable AppArmor in the live environment
    apparmor.enable = false;
    lockKernelModules = false;
    protectKernelImage = lib.mkForce false;
  };
  
  # Fix for gitconfig conflict
  environment.etc.gitconfig.source = lib.mkForce (pkgs.writeText "gitconfig" "");
  
  # Keep your NVIDIA drivers, but make them more compatible for live media
  hardware.nvidia = {
    # Keep the driver setup, but add some safer defaults for live media
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = lib.mkForce true;
    
    # These are safer for live media to avoid boot issues
    powerManagement.enable = lib.mkForce false;
    nvidiaPersistenced = lib.mkForce false;
    
    # Better compatibility for live environment
    forceFullCompositionPipeline = lib.mkForce true;
  };
  
  # Support both NVIDIA and non-NVIDIA systems
  services.xserver.videoDrivers = [ "nvidia" "nouveau" "modesetting" "fbdev" ];
  
  # Set up auto-login for the live system with GNOME
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };
  
  # Create nixos user for the live system
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "nixos";
    # Ensure no initialHashedPassword is set to avoid conflicts
    initialHashedPassword = lib.mkForce null;
  };
  
  # Allow passwordless sudo for the live user
  security.sudo.wheelNeedsPassword = false;
  
  # Disable hibernation (doesn't work on live systems)
  powerManagement.enable = lib.mkForce false;
  
  # Enable macOS-like keyboard remapping by default
  services.macos-remap.enable = true;
  
  # Configure xremap for the live ISO user
  services.xremap = {
    userName = "nixos"; # Use the live ISO username
  };
  
  # Home Manager configuration for the live user
  home-manager.users.nixos = {
    # Home Manager specific settings here if needed
    home.stateVersion = "24.11";
  };
  
  # Networking settings for the live image
  networking = {
    hostName = "nixos-gnome-live";
    wireless.enable = false;
    networkmanager.enable = true;
  };
  
  # Enable SSH server with root login for live installation
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = lib.mkForce "yes";
  };
  
  # Add fallback boot parameters for better hardware compatibility
  boot.kernelParams = lib.mkForce [
    # Generic options for better compatibility
    "nomodeset" # Use nomodeset for better compatibility with QEMU
    "preempt=full"
    "console=ttyS0" # Add serial console for debugging
  ];
  
  # GNOME-specific optimizations for live environment
  environment.variables = {
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1";
  };
  
  # Include installer tools and useful applications for the live system
  environment.systemPackages = with pkgs; [
    # Installation tools
    calamares-nixos-extensions
    gparted
    nixos-install-tools
    
    # GNOME utilities
    gnome-disk-utility
    
    # Web and networking
    firefox
    wget
    curl
    
    # Development
    git
    vim
    
    # Tools for the MacOS-like keybinding toggle script
    xdotool
    
    # Already defined in the macos-remap.nix module, so we don't need to duplicate it here
  ];
  
  environment.etc."issue".text = lib.mkForce ''
    
    Welcome to NixOS Live! This system is configured with:
    
    - AMD 7800X3D optimizations (base configuration)
    - NVIDIA RTX 4090 support
    - Full GNOME Desktop Environment
    - macOS-like keyboard remapping (enabled by default, run 'toggle-macos-keybindings' to disable/enable)
    
    Login with user: nixos, password: nixos
    
    The system configuration is available at /nixos-config
    
    \n \l
  '';
}