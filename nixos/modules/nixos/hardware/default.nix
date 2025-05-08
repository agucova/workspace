# Comprehensive hardware configuration with optimizations
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.myHardware;
in {
  options.myHardware = {
    enable = mkEnableOption "Hardware configuration and optimizations";

    # CPU options
    cpu = {
      amd = {
        enable = mkEnableOption "AMD CPU support and optimizations";
        model = mkOption {
          type = types.str;
          default = "7800X3D";
          description = "AMD CPU model for specific optimizations";
        };
        optimizations = mkOption {
          type = types.bool;
          default = true;
          description = "Enable performance optimizations for AMD CPUs";
        };
      };

      intel = {
        enable = mkEnableOption "Intel CPU support and optimizations";
        model = mkOption {
          type = types.str;
          default = "";
          description = "Intel CPU model for specific optimizations";
        };
      };
    };

    # GPU options
    gpu = {
      nvidia = {
        enable = mkEnableOption "NVIDIA GPU support";
        model = mkOption {
          type = types.str;
          default = "RTX 4090";
          description = "NVIDIA GPU model";
        };
        open = mkOption {
          type = types.bool;
          default = true;
          description = "Use open-source NVIDIA drivers";
        };
        wayland = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Wayland support for NVIDIA";
        };
      };

      amd = {
        enable = mkEnableOption "AMD GPU support";
      };

      intel = {
        enable = mkEnableOption "Intel integrated GPU support";
      };
    };

    # Performance optimization options
    performance = {
      enable = mkEnableOption "System performance optimizations";
      build = {
        parallel = mkOption {
          type = types.bool;
          default = true;
          description = "Enable parallel builds";
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Common hardware configuration
    {
      # Enable firmware
      hardware.enableRedistributableFirmware = true;
    }

    # CPU-specific configurations
    (mkIf cfg.cpu.amd.enable {
      # Update AMD microcode
      hardware.cpu.amd.updateMicrocode = true;

      # Enable AMD virtualization
      boot.kernelModules = [ "kvm-amd" ];

      # Optimizations for AMD CPUs
      boot.kernelParams = mkIf cfg.cpu.amd.optimizations [
        # AMD-specific optimizations
        "amd_pstate=active"
        "processor.max_cstate=5"
        # Uncomment for maximum performance (reduces security)
        # "mitigations=off"
      ];

      # Power management
      powerManagement = {
        enable = true;
        cpuFreqGovernor = mkDefault "performance";
      };
    })

    # NVIDIA GPU configuration
    (mkIf cfg.gpu.nvidia.enable {
      # Basic graphics configuration
      hardware.graphics = {
        enable = true;
        # enable32Bit = true;
      };

      # NVIDIA configuration
      hardware.nvidia = {
        modesetting.enable = true;
        # powerManagement.enable = true;
        open = cfg.gpu.nvidia.open;
        # Use latest stable drivers
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        # forceFullCompositionPipeline = true;
        # nvidiaPersistenced = true; # Keeps the NVIDIA driver persistent, improving performance
        nvidiaSettings = true; # Enable nvidia-settings utility
      };

      # Enable NVIDIA driver for X server
      services.xserver.videoDrivers = [ "nvidia" ];

      # NVIDIA-related packages
      environment.systemPackages = with pkgs; [
        # GPU monitoring tools
        glxinfo
        vulkan-tools
        nvtopPackages.full # renamed from nvtop

        # Graphics driver utilities
        libva
        libva-utils
      ];

      # Disable the nouveau driver when using the NVIDIA driver
      # boot.blacklistedKernelModules = [ "nouveau" ];

      # Environment variables for better NVIDIA & Wayland compatibility
      environment.variables = mkIf cfg.gpu.nvidia.wayland {
        # Hardware video acceleration
        LIBVA_DRIVER_NAME = "nvidia";

        # For NVIDIA in Wayland
        WLR_NO_HARDWARE_CURSORS = "1";

        # For using the NVIDIA driver with Wayland
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";

        # NVIDIA offloading
        MOZ_DISABLE_RDD_SANDBOX = "1"; # For Firefox hardware acceleration
      };
    })

    # Performance optimizations
    (mkIf cfg.performance.enable {
      # Build optimizations
      nix.settings = mkIf cfg.performance.build.parallel {
        # Allow greater parallelism for builds
        max-jobs = "auto";
        cores = 0;
      };

      # System-level performance optimizations
      boot.kernel.sysctl = {
        # Reduce swap tendency
        "vm.swappiness" = 10;

        # Increase file handle limits for high performance
        "fs.file-max" = 2097152;
        "fs.inotify.max_user_watches" = 524288;
      };
    })
  ]);
}
