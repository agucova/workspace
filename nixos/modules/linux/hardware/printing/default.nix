# Printing and scanning support module
# Provides SANE configuration for HP and driverless scanners plus modern CUPS management
{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.myHardware.printing;
in
{
  options.myHardware.printing = {
    enable = mkEnableOption "printing and scanning support";
  };

  config = mkIf cfg.enable {
    # Basic SANE configuration with HP and driverless support
    hardware.sane = {
      enable = true;
      
      # HP support with proprietary plugin and sane-airscan for driverless
      extraBackends = with pkgs; [
        hplipWithPlugin
        sane-airscan
      ];
      
      # Disable escl backend to avoid conflicts with sane-airscan
      disabledDefaultBackends = [ "escl" ];
    };

    # USB driverless scanning support
    services.ipp-usb.enable = true;

    # Network scanner discovery via Avahi
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # udev packages for sane-airscan
    services.udev.packages = [ pkgs.sane-airscan ];

    # Add agucova to scanner and lp groups
    users.users.agucova.extraGroups = [ "scanner" "lp" ];

    # Scanner and printer management packages
    environment.systemPackages = with pkgs; [
      # Basic scanning tools
      sane-frontends
      
      # Multiple GUI frontends (alternatives to simple-scan)
      simple-scan
      xsane
      gscan2pdf
      kdePackages.skanlite  # KDE scanner frontend, works on GNOME too
      
      # Modern CUPS GUI
      system-config-printer  # GTK-based printer configuration tool
    ];
  };
}