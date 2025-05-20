# Desktop Settings Module for Home Manager
# Provides wallpapers and desktop configuration
{ config, lib, pkgs, ... }:

let
  wallpaper_light = pkgs.fetchurl {
    url = "https://images.unsplash.com/photo-1540028317582-ab90fe7c343f?q=80&w=1740&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D";
    sha256 = "3f132fe7fd5119109a2ca2e706d52f6678f0ba6f5556e3b90a75322d28c4cf3a";
    name = "wallpaper_light.jpg";
  };
  wallpaper_dark = pkgs.fetchurl {
    url = "https://www.almaobservatory.org/wp-content/uploads/2020/04/Antenas-ALMA-105.jpg";
    sha256 = "067cad71d42f3cc22de885b82914b28d3b57b3fcfe99c4a1ae3e747ed717aab6";
    name = "wallpaper_dark.jpg";
  };
in {
  # No need for an enable option since this module is explicitly imported
  config = {
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
