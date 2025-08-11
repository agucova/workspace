{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.system.defaults.dock.enable = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Whether to manage dock settings through nix-darwin.
      Set to false to prevent nix-darwin from modifying dock settings or restarting the Dock.
      This is useful on macOS Sonoma where dock management is broken.
    '';
  };

  config = mkIf (!config.system.defaults.dock.enable) {
    # Override the activation script to prevent any dock-related commands and restarts
    system.activationScripts.userDefaults.text = mkForce (
      let
        cfg = config.system.defaults;
        
        writeDefault = domain: key: value:
          "defaults write ${domain} '${key}' $'${strings.escape [ "'" ] (generators.toPlist { } value)}'";

        defaultsToList = domain: attrs: mapAttrsToList (writeDefault domain) (filterAttrs (n: v: v != null) attrs);
        userDefaultsToList = domain: attrs: let
          user = escapeShellArg config.system.primaryUser;
        in map
          (cmd: ''launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- ${cmd}'')
          (defaultsToList domain attrs);

        # Generate all user defaults EXCEPT dock
        GlobalPreferences = userDefaultsToList ".GlobalPreferences" cfg.".GlobalPreferences";
        LaunchServices = userDefaultsToList "com.apple.LaunchServices" cfg.LaunchServices;
        NSGlobalDomain = userDefaultsToList "-g" cfg.NSGlobalDomain;
        menuExtraClock = userDefaultsToList "com.apple.menuextra.clock" cfg.menuExtraClock;
        finder = userDefaultsToList "com.apple.finder" cfg.finder;
        hitoolbox = userDefaultsToList "com.apple.HIToolbox" cfg.hitoolbox;
        iCal = userDefaultsToList "com.apple.iCal" cfg.iCal;
        magicmouse = userDefaultsToList "com.apple.AppleMultitouchMouse" cfg.magicmouse;
        magicmouseBluetooth = userDefaultsToList "com.apple.driver.AppleMultitouchMouse.mouse" cfg.magicmouse;
        screencapture = userDefaultsToList "com.apple.screencapture" cfg.screencapture;
        screensaver = userDefaultsToList "com.apple.screensaver" cfg.screensaver;
        spaces = userDefaultsToList "com.apple.spaces" cfg.spaces;
        trackpad = userDefaultsToList "com.apple.AppleMultitouchTrackpad" cfg.trackpad;
        trackpadBluetooth = userDefaultsToList "com.apple.driver.AppleBluetoothMultitouch.trackpad" cfg.trackpad;
        universalaccess = userDefaultsToList "com.apple.universalaccess" cfg.universalaccess;
        ActivityMonitor = userDefaultsToList "com.apple.ActivityMonitor" cfg.ActivityMonitor;
        WindowManager = userDefaultsToList "com.apple.WindowManager" cfg.WindowManager;
        controlcenter = userDefaultsToList "~${config.system.primaryUser}/Library/Preferences/ByHost/com.apple.controlcenter" cfg.controlcenter;
        CustomUserPreferences = flatten (mapAttrsToList (name: value: userDefaultsToList name value) cfg.CustomUserPreferences);

        hasAnySettings = any (attrs: attrs != [ ]) [
          GlobalPreferences
          LaunchServices
          NSGlobalDomain
          menuExtraClock
          finder
          hitoolbox
          iCal
          magicmouse
          magicmouseBluetooth
          screencapture
          screensaver
          spaces
          trackpad
          trackpadBluetooth
          universalaccess
          ActivityMonitor
          CustomUserPreferences
          WindowManager
          controlcenter
        ];
      in
        if hasAnySettings then ''
          # Set defaults
          echo >&2 "user defaults..."

          ${concatStringsSep "\n" NSGlobalDomain}

          ${concatStringsSep "\n" GlobalPreferences}
          ${concatStringsSep "\n" LaunchServices}
          ${concatStringsSep "\n" menuExtraClock}
          ${concatStringsSep "\n" finder}
          ${concatStringsSep "\n" hitoolbox}
          ${concatStringsSep "\n" iCal}
          ${concatStringsSep "\n" magicmouse}
          ${concatStringsSep "\n" magicmouseBluetooth}
          ${concatStringsSep "\n" screencapture}
          ${concatStringsSep "\n" screensaver}
          ${concatStringsSep "\n" spaces}
          ${concatStringsSep "\n" trackpad}
          ${concatStringsSep "\n" trackpadBluetooth}
          ${concatStringsSep "\n" universalaccess}
          ${concatStringsSep "\n" ActivityMonitor}
          ${concatStringsSep "\n" CustomUserPreferences}
          ${concatStringsSep "\n" WindowManager}
          ${concatStringsSep "\n" controlcenter}
        '' else ""
    );
  };
}
