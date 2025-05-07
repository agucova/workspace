# Virtual machine specific configuration
# Import this module INSTEAD OF hardware.nix when running in a VM
{ config, pkgs, lib, ... }:

let
  cfg = config.myVm;
in
{
  # Define options to enable/disable this module
  options.myVm = {
    enable = lib.mkEnableOption "virtualized environment configuration";
  };

  # Apply configuration only when enabled
  config = lib.mkIf cfg.enable {
    # Enable graphics in VM
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Disable NVIDIA configuration when running in VM
    hardware.nvidia = {
      modesetting.enable = lib.mkForce false;
      powerManagement.enable = lib.mkForce false;
      open = lib.mkForce false;
      forceFullCompositionPipeline = lib.mkForce false;
      nvidiaPersistenced = lib.mkForce false;
      nvidiaSettings = lib.mkForce false;
    };

    # QEMU/KVM/SPICE guest support and display settings
    services = {
      spice-vdagentd.enable = true;
      qemuGuest.enable = true;
      xserver.videoDrivers = lib.mkForce [ "qxl" "fbdev" "vesa" ];
    };


    # VM performance optimizations
    nix.settings = {
      max-jobs = lib.mkDefault "auto";
      cores = 0;
    };

    # CPU optimizations for better responsiveness
    boot.kernelParams = lib.mkForce [
      "preempt=full"
    ];

    # Reduce memory usage (override the base.nix setting)
    zramSwap.memoryPercent = lib.mkForce 25;

    # Environment configuration for VM
    environment = {
      systemPackages = with pkgs; [
        spice-gtk
        xorg.xf86inputvmmouse
      ];
      variables = {
        RUNNING_IN_VM = "1";
        LIBVA_DRIVER_NAME = lib.mkForce "";
        WLR_NO_HARDWARE_CURSORS = lib.mkForce "";
        GBM_BACKEND = lib.mkForce "";
        __GLX_VENDOR_LIBRARY_NAME = lib.mkForce "";
        MOZ_DISABLE_RDD_SANDBOX = lib.mkForce "";
      };
      etc."issue".text = ''
        NixOS VM Test Environment - \n \l

        This is a virtual machine test environment.
        Login with username: agucova and password: nixos
      '';
    };
  };
}
