# Virtual machine specific configuration
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.myVm;
in {
  # Define options to enable/disable this module
  options.myVm = {
    enable = mkEnableOption "virtualized environment configuration";
  };

  # Apply configuration only when enabled
  config = mkIf cfg.enable {
    # Enable graphics in VM
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Override any hardware-specific settings that might be enabled
    hardware.nvidia = {
      modesetting.enable = mkForce false;
      powerManagement.enable = mkForce false;
      open = mkForce false;
      forceFullCompositionPipeline = mkForce false;
      nvidiaPersistenced = mkForce false;
      nvidiaSettings = mkForce false;
    };

    # QEMU/KVM/SPICE guest support and display settings
    services = {
      spice-vdagentd.enable = true;
      qemuGuest.enable = true;
      xserver.videoDrivers = mkForce [ "qxl" "fbdev" "vesa" ];
    };

    # VM performance optimizations
    nix.settings = {
      max-jobs = mkDefault "auto";
      cores = 0;
    };

    # CPU optimizations for better responsiveness
    boot.kernelParams = mkForce [
      "preempt=full"
    ];

    # Reduce memory usage (override the base.nix setting)
    zramSwap.memoryPercent = mkForce 25;

    # Environment configuration for VM
    environment = {
      systemPackages = with pkgs; [
        spice-gtk
        xorg.xf86inputvmmouse
      ];
      variables = {
        RUNNING_IN_VM = "1";
        # Clear any hardware-specific environment variables
        LIBVA_DRIVER_NAME = mkForce "";
        WLR_NO_HARDWARE_CURSORS = mkForce "";
        GBM_BACKEND = mkForce "";
        __GLX_VENDOR_LIBRARY_NAME = mkForce "";
        MOZ_DISABLE_RDD_SANDBOX = mkForce "";
      };
      etc."issue".text = ''
        NixOS VM Test Environment - \n \l

        This is a virtual machine test environment.
        Login with username: agucova and password: nixos
      '';
    };
  };
}