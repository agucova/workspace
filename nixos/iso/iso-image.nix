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
  
  # Create a systemd service to apply macOS keybindings on login for the live user
  systemd.user.services.apply-macos-keybindings = {
    description = "Apply macOS-like keybindings on session startup";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 5 && /run/current-system/sw/bin/apply-macos-keybindings'";
    };
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
    
    # Add a toggle script for macOS-like keybindings in the live environment
    (writeScriptBin "toggle-macos-keybindings" ''
      #!/usr/bin/env bash
      
      XREMAP_SERVICE="xremap"
      
      if systemctl --user is-active ''${XREMAP_SERVICE} >/dev/null 2>&1; then
        echo "Disabling macOS-like keybindings..."
        systemctl --user stop ''${XREMAP_SERVICE}
        systemctl --user disable ''${XREMAP_SERVICE}
        
        # Reset GNOME settings
        gsettings reset org.gnome.mutter overlay-key
        gsettings reset org.gnome.desktop.wm.keybindings minimize
        gsettings reset org.gnome.desktop.wm.keybindings switch-applications
        gsettings reset org.gnome.desktop.wm.keybindings switch-applications-backward
        gsettings reset org.gnome.desktop.wm.keybindings switch-group
        gsettings reset org.gnome.desktop.wm.keybindings switch-group-backward
        gsettings reset org.gnome.desktop.wm.keybindings switch-input-source
        gsettings reset org.gnome.desktop.wm.keybindings switch-input-source-backward
        gsettings reset org.gnome.mutter.keybindings toggle-tiled-left
        gsettings reset org.gnome.mutter.keybindings toggle-tiled-right
        gsettings reset org.gnome.shell.keybindings toggle-message-tray
        gsettings reset org.gnome.shell.keybindings screenshot
        gsettings reset org.gnome.shell.keybindings show-screenshot-ui
        gsettings reset org.gnome.shell.keybindings screenshot-window
        
        echo "macOS-like keybindings disabled. Restart GNOME Shell with Alt+F2, r, Enter for full effect."
      else
        echo "Enabling macOS-like keybindings..."
        
        # Apply GNOME settings
        gsettings set org.gnome.mutter overlay-key ""
        gsettings set org.gnome.desktop.wm.keybindings minimize "[]"
        gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Control>d']"
        gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Control>Tab']"
        gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Control>Tab']"
        gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Control>grave']"
        gsettings set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Control>grave']"
        gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"
        gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"
        gsettings set org.gnome.mutter.keybindings toggle-tiled-left "[]"
        gsettings set org.gnome.mutter.keybindings toggle-tiled-right "[]"
        gsettings set org.gnome.shell.keybindings toggle-message-tray "[]"
        gsettings set org.gnome.shell.keybindings screenshot "['<Shift><Control>3']"
        gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Control>4']"
        
        # Start service
        systemctl --user daemon-reload
        systemctl --user enable ''${XREMAP_SERVICE}
        systemctl --user start ''${XREMAP_SERVICE}
        
        echo "macOS-like keybindings enabled! ⌘ now acts as Ctrl and vice versa."
        echo "Try ⌘C to copy, ⌘V to paste, ⌘Tab to switch applications."
        echo "To disable, run this command again."
      fi
    '')
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