# Attrset consumed by the home module.
{
  "org.gnome.mutter" = { overlay-key = ""; };

  "org.gnome.desktop.wm.keybindings" = {
    minimize                      = [ ];
    show-desktop                  = [ "<Control>d" ];
    switch-applications           = [ "<Control>Tab" ];
    switch-applications-backward  = [ "<Shift><Control>Tab" ];
    switch-group                  = [ "<Control>grave" ];
    switch-group-backward         = [ "<Shift><Control>grave" ];
    switch-input-source           = [ ];
    switch-input-source-backward  = [ ];
    switch-to-workspace-left      = [ "<Super>Left" ];
    switch-to-workspace-right     = [ "<Super>Right" ];
  };

  "org.gnome.mutter.keybindings" = {
    toggle-tiled-left  = [ ];
    toggle-tiled-right = [ ];
  };

  "org.gnome.shell.keybindings" = {
    toggle-message-tray      = [ ];
    screenshot               = [ "<Shift><Control>3" ];
    show-screenshot-ui       = [ "<Shift><Control>4" ];
    screenshot-window        = [ "<Shift><Control>5" ];
    toggle-overview          = [ "LaunchA" ];
    toggle-application-view  = [ "<Primary>space" "LaunchB" ];
  };

  "org.gnome.settings-daemon.plugins.media-keys" = { screensaver = [ ]; };

  "org.gnome.Terminal.Legacy.Keybindings" = {
    copy        = "<Shift><Super>c";
    paste       = "<Shift><Super>v";
    new-tab     = "<Shift><Super>t";
    new-window  = "<Shift><Super>n";
    close-tab   = "<Shift><Super>w";
    close-window = "<Shift><Super>q";
    find        = "<Shift><Super>f";
  };
}
