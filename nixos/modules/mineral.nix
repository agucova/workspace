# nix-mineral configuration with gaming and performance-friendly overrides
{ config, lib, pkgs, nix-mineral, ... }:

{
  imports = [
    # Import the main nix-mineral module
    "${nix-mineral}/nix-mineral.nix"
  ];

  # Gaming and Performance Overrides
  nm-overrides = {
    # Compatibility - necessary for gaming and general system functionality
    compatibility = {
      # Allow loading unsigned kernel modules (needed for some drivers)
      allow-unsigned-modules.enable = true;
      # Disable kernel lockdown (necessary for unsigned modules)
      no-lockdown.enable = true;
      # Enable io_uring for better I/O performance
      io-uring.enable = true;
    };

    # Desktop - required for gaming
    desktop = {
      # Enable multilib (necessary for Steam and many games)
      allow-multilib.enable = true;
      # Allow unprivileged user namespaces (needed for Flatpak, Steam, and browser sandboxing)
      allow-unprivileged-userns.enable = true;
      # Allow execution in home directory (most games run from here)
      home-exec.enable = true;
      # Allow execution in /tmp (various games and launchers need this)
      tmp-exec.enable = true;
      # Allow execution in /var/lib (for system-wide Flatpaks and other applications)
      var-lib-exec.enable = true;
      # Use relaxed ptrace settings (needed for some anti-cheat systems)
      yama-relaxed.enable = true;
      # Use relaxed process hiding (better compatibility)
      hideproc-relaxed.enable = true;
      # Auto-allow USB devices at boot (for controllers and peripherals)
      usbguard-allow-at-boot.enable = true;
    };

    # Performance - optimize for gaming performance
    performance = {
      # Enable SMT for better multi-threaded performance
      allow-smt.enable = true;
      # Enable IOMMU passthrough for improved I/O performance
      iommu-passthrough.enable = true;
      # Keep basic mitigations but avoid the most performance-impacting ones
      # Specifically NOT enabling no-mitigations.enable as that would be too extreme
    };

    # Security - leave most defaults but adjust as needed for gaming
    security = {
      # Disable TCP timestamps for better privacy
      tcp-timestamp-disable.enable = true;
    };
  };
}