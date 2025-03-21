# Base NixOS configuration
{ config, pkgs, lib, ... }:

{
  # Enable networking
  networking.networkmanager.enable = true;
  
  # Set your time zone
  time.timeZone = "America/Santiago";
  
  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Configure console keymap
  console.keyMap = "us";
  
  # Enable CUPS to print documents
  services.printing.enable = true;
  
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
  
  # User account
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS User";
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "nixos";
  };
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # System packages
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    micro
    htop
    firefox
    libreoffice-qt
  ];
  
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Enable nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Swapfile
  swapDevices = [{
    device = "/swapfile";
    size = 4*1024; # 4GB
  }];
}