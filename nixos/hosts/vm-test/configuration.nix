# VM testing configuration for NixOS
{ config, pkgs, lib, ... }:

{
  imports = [
    # Import base and generic modules
    ../../modules/base.nix
    ../../modules/gnome.nix
    ../../modules/gui-apps.nix  # Include GUI applications for testing
    # Import VM-specific configuration INSTEAD OF hardware.nix
    ../../modules/virtualization.nix
  ];

  # Set hostname for VM
  networking.hostName = "nixos-vm-test";

  # User account - same as hardware setup
  users.users.agucova = {
    isNormalUser = true;
    description = "Agustin Covarrubias";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    initialPassword = "nixos";
  };

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

  # Disable the default command-not-found implementation to avoid conflicts
  programs.command-not-found.enable = false;

  # Disable system-wide nix-index since we're using Home Manager module instead
  programs.nix-index.enable = false;
  
  
  # Home Manager configuration
  home-manager.users.agucova = import ../gnome/home.nix;
  
  # Add minimal GUI packages for VM testing
  environment.systemPackages = with pkgs; [
    # Basic GUI applications for testing
    firefox
    gnome-terminal
    home-manager
    
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

  # State version
  system.stateVersion = "23.11";
}
