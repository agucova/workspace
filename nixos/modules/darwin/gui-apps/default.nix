# Darwin GUI applications module using NixCasks
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.myDarwinGuiApps;
  casks = inputs.nix-casks.packages.${pkgs.system};
in
{
  options.myDarwinGuiApps = {
    enable = lib.mkEnableOption "Darwin GUI applications";
    
    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        # Essential apps
        "raycast"           # Spotlight replacement
        "arc"               # Browser
        "visual-studio-code" # Code editor
        "slack"             # Communication
        "1password"         # Password manager
        "ghostty"           # Terminal (if available in casks)
        "warp"              # Alternative terminal
      ];
      description = "List of GUI applications to install from NixCasks";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install selected GUI applications
    environment.systemPackages = 
      let
        # Filter out any apps that don't exist in casks
        availableApps = builtins.filter 
          (app: builtins.hasAttr app casks) 
          cfg.apps;
        
        # Get the actual packages
        appPackages = map (app: casks.${app}) availableApps;
      in
      appPackages;

    # Note which apps were requested but not available
    warnings = 
      let
        unavailableApps = builtins.filter 
          (app: !builtins.hasAttr app casks) 
          cfg.apps;
      in
      lib.optional (unavailableApps != []) 
        "The following apps are not available in NixCasks: ${builtins.concatStringsSep ", " unavailableApps}";
  };
}