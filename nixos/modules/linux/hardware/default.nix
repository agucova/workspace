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
      # https://github.com/chaotic-cx/nyx/issues/1069
      hardware.nvidia =
        let
          # Preferred NVIDIA Version
          nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.mkDriver {
            version = "575.57.08";
            sha256_64bit = "sha256-KqcB2sGAp7IKbleMzNkB3tjUTlfWBYDwj50o3R//xvI=";
            sha256_aarch64 = "sha256-VJ5z5PdAL2YnXuZltuOirl179XKWt0O4JNcT8gUgO98=";
            openSha256 = "sha256-DOJw73sjhQoy+5R0GHGnUddE6xaXb/z/Ihq3BKBf+lg=";
            settingsSha256 = "sha256-AIeeDXFEo9VEKCgXnY3QvrW5iWZeIVg4LBCeRtMs5Io=";
            persistencedSha256 = "sha256-Len7Va4HYp5r3wMpAhL4VsPu5S0JOshPFywbO7vYnGo=";

            patches = [ gpl_symbols_linux_615_patch ];
          };

          gpl_symbols_linux_615_patch = pkgs.fetchpatch {
            url = "https://github.com/CachyOS/kernel-patches/raw/914aea4298e3744beddad09f3d2773d71839b182/6.15/misc/nvidia/0003-Workaround-nv_vm_flags_-calling-GPL-only-code.patch";
            hash = "sha256-YOTAvONchPPSVDP9eJ9236pAPtxYK5nAePNtm2dlvb4=";
            stripLen = 1;
            extraPrefix = "kernel/";
          };
        in
        {
          package = nvidiaPackage;
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
        glxinfo
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
        glxinfo
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
        glxinfo
        vulkan-tools
        intel-gpu-tools
      ];
    })
  ];
}
