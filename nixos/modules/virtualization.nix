# Virtual machine specific configuration
# Import this module INSTEAD OF hardware.nix when running in a VM
{ config, pkgs, lib, ... }:

{
  # Enable OpenGL in VM
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Disable NVIDIA configuration when running in VM
  hardware.nvidia.enable = lib.mkForce false;

  # QEMU/KVM/SPICE guest support
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;

  # Support both Intel and AMD virtualization
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];

  # Auto-resize display with QXL driver
  services.xserver.videoDrivers = [ "qxl" ];

  # VM performance optimizations
  nix.settings.max-jobs = lib.mkDefault 3;
  hardware.video.hidpi.enable = false;

  # Reduce memory usage
  zramSwap.memoryPercent = 25;  # Lower than on hardware

  # Use lighter versions of applications when possible
  environment.systemPackages = with pkgs; [
    # Add VM specific utilities
    spice-gtk  # For spice client integration
    xorg.xf86inputvmmouse  # VM mouse driver
  ];

  # Test specific environment variables
  environment.variables = {
    # Indicate we're in a VM (can be useful for scripts)
    RUNNING_IN_VM = "1";
  };

  # Hint for users that this is a VM environment
  environment.etc."issue".text = ''
    NixOS VM Test Environment - \n \l

    This is a virtual machine test environment.
    Login with username: agucova and password: nixos
  '';
}
