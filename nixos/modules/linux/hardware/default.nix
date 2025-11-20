# Simplified hardware configuration module
# This module is automatically enabled when imported and provides conditional configuration
# based on CPU type (AMD/Intel) and GPU type (NVIDIA/AMD/Intel).
{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.myHardware;
in
{
  options.myHardware = {
    # CPU options - choose exactly one type
    cpu = {
      amd = {
        enable = mkEnableOption "AMD CPU support and optimizations";
      };

      intel = {
        enable = mkEnableOption "Intel CPU support and optimizations";
      };
    };

    # GPU options - choose exactly one type
    gpu = {
      nvidia = {
        enable = mkEnableOption "NVIDIA GPU support";
        open = mkOption {
          type = types.bool;
          default = true;
          description = "Use open-source NVIDIA drivers";
        };
      };

      amd = {
        enable = mkEnableOption "AMD GPU support";
      };

      intel = {
        enable = mkEnableOption "Intel integrated GPU support";
      };
    };
  };

  config = mkMerge [
    # Common hardware configuration - always applied
    {
      # Enable firmware
      hardware.enableRedistributableFirmware = true;

      # Webcam power line frequency fix for Chilean 50Hz power grid
      services.udev.extraRules = ''
        # Set power line frequency to 50Hz for all UVC webcams in Chile
        ACTION=="add", SUBSYSTEM=="video4linux", DRIVERS=="uvcvideo", RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl -d $devnode --set-ctrl=power_line_frequency=1"
      '';

      environment.systemPackages = with pkgs; [
        v4l-utils
        sbctl
      ];
    }

    # AMD CPU configuration
    (mkIf cfg.cpu.amd.enable {
      # Update AMD microcode
      hardware.cpu.amd.updateMicrocode = true;
      # Enable AMD virtualization
      boot.kernelModules = [ "kvm-amd" ];
      # AMD-specific optimizations
      boot.kernelParams = [
        "amd_pstate=active"
        "processor.max_cstate=5"
      ];
      # Power management
      powerManagement = {
        enable = true;
        cpuFreqGovernor = "performance";
      };
    })

    # Intel CPU configuration
    (mkIf cfg.cpu.intel.enable {
      # Update Intel microcode
      hardware.cpu.intel.updateMicrocode = true;
      # Enable Intel virtualization
      boot.kernelModules = [ "kvm-intel" ];
      # Power management
      powerManagement = {
        enable = true;
        cpuFreqGovernor = "performance";
      };
    })

    # NVIDIA GPU configuration
    (mkIf cfg.gpu.nvidia.enable {
      # Basic graphics configuration
      hardware.graphics.enable = true;

      # NVIDIA configuration
      hardware.nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.beta;
        open = true;
        modesetting.enable = true;
        nvidiaSettings = true;
        powerManagement.enable = true; # experimental, but seems to fix suspend issues
      };

      # Try to fix suspend issues
      systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

      # Enable NVIDIA driver for X server
      services.xserver.videoDrivers = [ "nvidia" ];

      # NVIDIA-related packages
      environment.systemPackages = with pkgs; [
        mesa-demos
        vulkan-tools
        nvtopPackages.full
        libva
        libva-utils
      ];

      # Environment variables for better NVIDIA & Wayland compatibility
      environment.variables = {
        LIBVA_DRIVER_NAME = "nvidia";
        XDG_SESSION_TYPE = "wayland";
        WLR_NO_HARDWARE_CURSORS = "1";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        MOZ_DISABLE_RDD_SANDBOX = "1"; # For Firefox hardware acceleration
      };
    })

    # AMD GPU configuration
    (mkIf cfg.gpu.amd.enable {
      # AMD graphics drivers
      hardware.opengl.extraPackages = with pkgs; [
        rocm-opencl-icd
        rocm-opencl-runtime
        amdvlk
      ];

      # Enable AMD driver for X server
      services.xserver.videoDrivers = [ "amdgpu" ];

      # AMD GPU monitoring tools
      environment.systemPackages = with pkgs; [
        mesa-demos
        vulkan-tools
        radeontop
      ];
    })

    # Intel GPU configuration
    (mkIf cfg.gpu.intel.enable {
      # Intel graphics drivers
      hardware.opengl.extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
        intel-ocl
      ];

      # Enable Intel driver for X server
      services.xserver.videoDrivers = [ "intel" ];

      # Intel GPU tools
      environment.systemPackages = with pkgs; [
        mesa-demos
        vulkan-tools
        intel-gpu-tools
      ];
    })
  ];
}
