# Main NixOS configuration file for 7800X3D + RTX 4090 Workstation
{ config, pkgs, lib, ... }:

{
  imports = [
    # Import hardware configuration from system directory
    /etc/nixos/hardware-configuration.nix

    # Import our modular configurations
    ../../modules/base.nix
    ../../modules/hardware.nix  # RTX 4090 specific configuration
    ../../modules/gnome.nix     # GNOME desktop environment
    ../../modules/gui-apps.nix  # GUI applications
    ../../modules/dotfiles.nix  # Chezmoi dotfiles integration
  ];

  # Set hostname
  networking.hostName = "gnome-nixos";

  # User account - your account
  users.users.agucova = {
    isNormalUser = true;
    description = "Agustin Covarrubias";
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "audio" "input" "podman" ];
    shell = pkgs.fish;  # Set Fish as default shell
    # Using a plain text password is fine for initial setup, but consider
    # changing it after installation or using hashedPassword instead
    initialPassword = "nixos";
  };
  
  # Enable Docker
  virtualisation = {
    docker = {
      enable = true;
      enableNvidia = true;  # Enable NVIDIA runtime for Docker containers
    };
    
    # Enable Podman as alternative container runtime
    podman = {
      enable = true;
      dockerCompat = true;  # Docker compatibility mode
    };
  };

  # Enable automatic login if desired
  # services.xserver.displayManager.autoLogin.enable = true;
  # services.xserver.displayManager.autoLogin.user = "agucova";

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
  
  # Post-installation script to set up Julia packages
  system.activationScripts.setupJuliaEnv = ''
    # Create script to install Julia packages
    cat > /home/agucova/setup-julia-packages.sh << 'EOF'
    #!/usr/bin/env bash
    
    # Install common Julia packages
    JULIA_PACKAGES=(
      "Plots"
      "DifferentialEquations"
      "Revise"
      "OhMyREPL"
      "Literate"
      "Pluto"
      "BenchmarkTools"
    )
    
    for pkg in "${JULIA_PACKAGES[@]}"; do
      echo "Installing Julia package: $pkg"
      julia -e "using Pkg; Pkg.add(\"$pkg\")"
    done
    EOF
    
    # Make script executable
    chmod +x /home/agucova/setup-julia-packages.sh
    chown agucova:users /home/agucova/setup-julia-packages.sh
  '';
}