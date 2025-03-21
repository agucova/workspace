# Virtual machine specific configuration
{ config, pkgs, lib, ... }:

{
  # Enable OpenGL in VM
  hardware.opengl = {
    enable = true;
    driSupport = true;
  };
  
  # QEMU/KVM/SPICE guest support
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  
  # Better VM performance
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  
  # Auto-resize display
  services.xserver.videoDrivers = [ "qxl" ];
  
  # Enable better performance options
  nix.settings.max-jobs = lib.mkDefault 3;
  hardware.video.hidpi.enable = false;
  
  # Host name
  networking.hostName = "cosmic-nixos";
  
  # Set graphical target
  services.xserver.enable = true;
  services.xserver.desktopManager.xterm.enable = false;
}