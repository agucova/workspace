# Hardware-specific configuration for RTX 4090
{ config, pkgs, lib, ... }:

{
  # Basic graphics configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA RTX 4090 configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    # Based on recent benchmarks, open-source drivers now match proprietary ones for RTX 40 series
    open = true;
    # Use latest stable drivers
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    forceFullCompositionPipeline = true;
    nvidiaPersistenced = true;  # Keeps the NVIDIA driver persistent, improving performance
    nvidiaSettings = true;      # Enable nvidia-settings utility
  };

  # Enable NVIDIA driver for X server
  services.xserver.videoDrivers = [ "nvidia" ];

  # NVIDIA-related packages
  environment.systemPackages = with pkgs; [
    # GPU monitoring tools
    glxinfo
    vulkan-tools
    nvtopPackages.full  # renamed from nvtop

    # Graphics driver utilities
    libva
    libva-utils
  ];

  # Disable the nouveau driver when using the NVIDIA driver
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Environment variables for better NVIDIA & Wayland compatibility
  environment.variables = {
    # Hardware video acceleration
    LIBVA_DRIVER_NAME = "nvidia";

    # For NVIDIA in Wayland
    WLR_NO_HARDWARE_CURSORS = "1";

    # For using the NVIDIA driver with Wayland
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # NVIDIA offloading
    MOZ_DISABLE_RDD_SANDBOX = "1";  # For Firefox hardware acceleration
  };
}
