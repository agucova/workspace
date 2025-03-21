# Main NixOS configuration file
{ config, pkgs, lib, ... }:

{
  imports = [
    # Import hardware configuration (will be auto-generated during install)
    # Replace this comment with ./hardware-configuration.nix after install
    
    # Import our modular configurations
    ../../modules/cosmic.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # AMD Ryzen 7 7800X3D optimizations
  boot.kernelModules = [ "kvm-amd" ];  # Enable AMD virtualization
  
  # CPU power management
  powerManagement.cpuFreqGovernor = "performance";
  
  # Enable AMD microcode updates
  hardware.cpu.amd.updateMicrocode = true;
  
  # Enable firmware
  hardware.enableRedistributableFirmware = true;

  # Hostname - change this to your preferred name
  networking.hostName = "cosmic-nixos";
  
  # Enable NetworkManager
  networking.networkmanager.enable = true;

  # Set your time zone
  time.timeZone = "America/Santiago";

  # Localization
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure console keymap
  console.keyMap = "us";

  # Enable sound with pipewire
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  # Enable printing
  services.printing.enable = true;

  # User account - customize with your details
  users.users.myuser = {
    isNormalUser = true;
    description = "My User";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;  # Set Fish as default shell
    # For security, set initial password with:
    # passwd myuser
    # Or uncomment and set an initial password hash below:
    # hashedPassword = "...";
  };
  
  # Enable Fish Shell
  programs.fish.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # Command line tools
    wget
    curl
    git
    vim
    micro
    htop
    # Use ghostty from the direct flake reference for the latest version
    ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default

    # GUI applications
    firefox
    libreoffice-qt
  ];

  # Enable flakes and nix commands
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Optimize store - auto garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # This value determines the NixOS release to base packages on
  # Don't change this unless you know what you're doing
  system.stateVersion = "24.05"; # Replace with current NixOS version
}