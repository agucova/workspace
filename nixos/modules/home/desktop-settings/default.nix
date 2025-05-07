# Desktop Settings Module for Home Manager
{ config, lib, pkgs, ... }:

let
  cfg = config.desktop-settings;
  wallpaper_light = pkgs.fetchurl {
    url = "https://images.unsplash.com/photo-1540028317582-ab90fe7c343f?q=80&w=1740&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D";
    sha256 = "3f132fe7fd5119109a2ca2e706d52f6678f0ba6f5556e3b90a75322d28c4cf3a";
    name = "wallpaper_light.jpg";
  };
  wallpaper_dark = pkgs.fetchurl {
    url = "https://public.nrao.edu/wp-content/uploads/2024/11/ALMA_Milky-Way_Less-Green_r6-2048x1365.jpg";
    sha256 = "7174aa2e2f117dc0cb58804254cebe7665e0e73a6f55b967cbc41942cb9a76a4";
    name = "wallpaper_dark.jpg";

  };
in {
  options.desktop-settings = {
    enable = lib.mkEnableOption "Desktop settings with wallpaper";
  };

  config = lib.mkIf cfg.enable {
    # Apply GNOME settings via dconf
    dconf.settings = {
      "org/gnome/desktop/background" = {
        picture-options = "zoom";
        picture-uri = "file://${wallpaper_light}";
        picture-uri-dark = "file://${wallpaper_dark}";
      };
    };
  };
}
