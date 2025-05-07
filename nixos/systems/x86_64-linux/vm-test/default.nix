# VM testing configuration for NixOS
{ lib, pkgs, config, inputs, ... }:

{
  # User account - same as hardware setup
  users.users.agucova = {
    isNormalUser = true;
    description = "Agustin Covarrubias";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    initialPassword = "nixos";
  };

  # Enable base GNOME environment
  baseGnome.enable           = true;
  virtualizedEnvironment.enable = true;

  # Enable automatic login for testing
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "agucova";

  # Disable some hardware-specific optimizations that don't make sense in VM
  boot.kernelParams = lib.mkForce [
    "preempt=full"
  ];

  # Simplify boot configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = lib.mkForce 0;
  };

  # Filesystem
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos"; # Standard label used by many NixOS VM tools
    fsType = "ext4";                     # Common filesystem type for VMs
  };

  # Boot partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Add minimal GUI packages for VM testing
  environment.systemPackages = with pkgs; [
    # Basic GUI applications for testing
    firefox
    gnome-terminal

    # Debug tools
    strace
    lsof
    file
    # Debug scripts for Home Manager
    (pkgs.writeScriptBin "debug-home-manager" ''
      #!/usr/bin/env bash
      # Debug script to inspect home-manager activation and configuration

      echo "============== HOME MANAGER STATUS ================"
      echo "Checking for Home Manager generations:"
      ls -la ~/.local/state/home-manager/generations/ 2>/dev/null || echo "No generations found"

      echo -e "\nChecking Home Manager activation data:"
      find ~/.local/state/home-manager/ -type f 2>/dev/null | while read file; do
        echo "--- $file ---"
        cat "$file" 2>/dev/null
      done || echo "No activation data found"

      echo -e "\nChecking environment variables:"
      env | grep -i "home\\|nix\\|hm_" | sort

      echo -e "\n============== SHELL INTEGRATION ================"
      echo "Checking for fish config directories/files:"
      find ~/.config/fish/ -type f -o -type l 2>/dev/null | while read file; do
        echo "--- $file ---"
        cat "$file" 2>/dev/null || echo "[Could not display content]"
      done || echo "No fish configs found"

      echo -e "\nSearching for command-not-found handlers:"
      find ~ -type f -name "*command*not*found*" 2>/dev/null || echo "No command-not-found handlers found in home"

      echo -e "\nChecking nix-index database and status:"
      ls -la ~/.cache/nix-index/ 2>/dev/null
      find ~ -name "*nix-index*" -type f -o -type l 2>/dev/null
      which nix-index nix-locate comma 2>/dev/null || echo "Commands not found"

      echo -e "\n============== DONE ================"
    '')

    # Add another script to dump home-manager configuration
    (pkgs.writeScriptBin "dump-home-config" ''
      #!/usr/bin/env bash
      # Dump home-manager config info

      # Get all activation scripts
      echo "============== HOME MANAGER ACTIVATION SCRIPTS ================"
      find ~/.nix-profile/lib/systemd/ -name "*home-manager*" -type f 2>/dev/null | xargs cat 2>/dev/null || echo "No activation scripts found"

      # Dump nix profile
      echo -e "\n============== NIX PROFILE ================"
      nix profile list

      # Show all fish configuration files
      echo -e "\n============== FISH CONFIGURATION FILES ================"
      find ~/.config/fish -type f 2>/dev/null | while read file; do
        echo -e "\n--- $file ---"
        cat "$file" 2>/dev/null
      done || echo "No fish configuration files found"

      # Extract all command-not-found handlers
      echo -e "\n============== COMMAND NOT FOUND HANDLERS ================"
      find /nix/store -name "*command*not*found*" -type f 2>/dev/null | head -n 5 | while read file; do
        echo -e "\n--- $file ---"
        cat "$file" 2>/dev/null
      done || echo "No command-not-found handlers found"
    '')
  ];

  # Enable macOS-like keyboard remapping with xremap
  macos-remap.enable = true;
  snowfallorg.users.agucova.home.config.macos-remap.keybindings = true;

  # Fix for nixos user in VM builds
  users.users.nixos = {
    isNormalUser = true;
    group = "nixos";
  };
  users.groups.nixos = {};

  virtualisation.vmVariant.virtualisation = {
    cores = 12;
    memorySize = 8192; # 8GB RAM
    diskSize = 40 * 1024; # 40960 MiB

    qemu.options = [
      "-vga virtio"
      "-display gtk,grab-on-hover=on"
      "-cpu host"
      "-device virtio-keyboard-pci"
      "-usb"
      "-device usb-tablet"
      "-device virtio-serial-pci"
    ];
  };

  # State version
  system.stateVersion = "24.11";
}
