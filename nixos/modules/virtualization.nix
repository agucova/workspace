# Virtual machine specific configuration
# Import this module INSTEAD OF hardware.nix when running in a VM
{ config, pkgs, lib, ... }:

{
  # Enable graphics in VM
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Disable NVIDIA configuration when running in VM
  hardware.nvidia = {
    # Disable all NVIDIA options that are enabled in hardware.nix
    modesetting.enable = lib.mkForce false;
    powerManagement.enable = lib.mkForce false;
    open = lib.mkForce false;
    forceFullCompositionPipeline = lib.mkForce false;
    nvidiaPersistenced = lib.mkForce false;
    nvidiaSettings = lib.mkForce false;
  };

  # QEMU/KVM/SPICE guest support
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;

  # Support both Intel and AMD virtualization
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];

  # Auto-resize display with QXL driver
  # Override the NVIDIA driver with QXL/VGA in VM
  services.xserver.videoDrivers = lib.mkForce [ "qxl" "fbdev" "vesa" ];

  # VM performance optimizations
  nix.settings = {
    max-jobs = lib.mkDefault "auto";  # Utilize all available cores for builds
    cores = 0;                        # Use all cores for each build job
  };
  
  # CPU optimizations for better responsiveness
  boot.kernelParams = lib.mkForce [
    "preempt=full"     # Better desktop responsiveness
  ];

  # Reduce memory usage (override the base.nix setting)
  zramSwap.memoryPercent = lib.mkForce 25;  # Lower than on hardware

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
    
    # Clear any NVIDIA-specific variables that might be set in hardware.nix
    LIBVA_DRIVER_NAME = lib.mkForce "";
    WLR_NO_HARDWARE_CURSORS = lib.mkForce "";
    GBM_BACKEND = lib.mkForce "";
    __GLX_VENDOR_LIBRARY_NAME = lib.mkForce "";
    MOZ_DISABLE_RDD_SANDBOX = lib.mkForce "";
  };

  # Hint for users that this is a VM environment
  environment.etc."issue".text = ''
    NixOS VM Test Environment - \n \l

    This is a virtual machine test environment.
    Login with username: agucova and password: nixos
  '';
}
