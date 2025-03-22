# nix-mineral configuration with gaming and performance-friendly overrides
{ config, lib, pkgs, nix-mineral, ... }:

{
  imports = [
    # Import the main nix-mineral module
    "${nix-mineral}/nix-mineral.nix"
  ];

  # Enable nix-mineral
  nix-mineral.enable = true;

  # Gaming and Performance Overrides
  nix-mineral.overrides = {
    # Compatibility - necessary for gaming and general system functionality
    compatibility = {
      # Allow loading unsigned kernel modules (needed for some drivers)
      allow-unsigned-modules = true;
      # Disable kernel lockdown (necessary for unsigned modules)
      no-lockdown = true;
      # Enable io_uring for better I/O performance
      allow-io-uring = true;
    };

    # Desktop - required for gaming
    desktop = {
      # Enable multilib (necessary for Steam and many games)
      allow-multilib = true;
      # Allow unprivileged user namespaces (needed for Flatpak, Steam, and browser sandboxing)
      allow-unprivileged-userns = true;
      # Allow execution in home directory (most games run from here)
      home-exec = true;
      # Allow execution in /tmp (various games and launchers need this)
      tmp-exec = true;
      # Allow execution in /var/lib (for system-wide Flatpaks and other applications)
      var-lib-exec = true;
      # Use relaxed ptrace settings (needed for some anti-cheat systems)
      yama-relaxed = true;
      # Use relaxed process hiding (better compatibility)
      hideproc-ptraceable = true;
      # Auto-allow USB devices at boot (for controllers and peripherals)
      usbguard-allow-at-boot = true;
    };

    # Performance - optimize for gaming performance
    performance = {
      # Enable SMT for better multi-threaded performance
      allow-smt = true;
      # Enable IOMMU passthrough for improved I/O performance
      iommu-passthrough = true;
      # Keep basic mitigations but avoid the most performance-impacting ones
      # Specifically NOT enabling no-mitigations as that would be too extreme
    };

    # Security - leave most defaults but adjust as needed for gaming
    security = {
      # Disable TCP timestamps for better privacy
      tcp-timestamp-disable = true;
    };
  };
}