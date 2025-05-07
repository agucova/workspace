# Shared xremap configuration (attrset only).
{
  keypress_delay_ms = 10;

  modmap = [
    {
      name = "Make ⌘ act as Ctrl";
      remap = {
        "LeftCtrl"  = "LeftMeta";
        "LeftMeta"  = "LeftCtrl";
        "RightCtrl" = "RightMeta";
        "RightMeta" = "RightCtrl";
      };
    }
  ];

  keymap = [
    {
      name  = "Make ⌘← and ⌘→ work as Home and End";
      remap = {
        "C-LEFT"          = "HOME";
        "C-RIGHT"         = "END";
        "Shift-C-LEFT"    = "Shift-HOME";
        "Shift-C-RIGHT"   = "Shift-END";
      };
    }
    {
      name  = "Delete word";
      remap = { "Alt-BACKSPACE" = "C-BACKSPACE"; };
    }
    {
      name          = "Delete complete line";
      application.not = [ "org.gnome.Terminal" ];
      remap         = { "C-K" = "C-D"; };
    }
    {
      name            = "Nautilus (Files) shortcuts";
      application.only = [ "org.gnome.Nautilus" ];
      remap = {
        "C-UP"          = "Alt-UP";
        "C-DOWN"        = "ENTER";
        "C-BACKSPACE"   = "DELETE";
        "Shift-C-DOT"   = "C-H";
        "Shift-C-G"     = "C-L";
      };
    }
    {
      name            = "Terminal copy/paste + window management";
      application.only = [ "org.gnome.Terminal" ];
      remap = {
        "C-C" = "Shift-Super-C";
        "C-V" = "Shift-Super-V";
        "C-T" = "Shift-Super-T";
        "C-N" = "Shift-Super-N";
        "C-W" = "Shift-Super-W";
        "C-Q" = "Shift-Super-Q";
        "C-F" = "Shift-Super-F";
      };
    }
    {
      name            = "Terminal interrupt";
      application.only = [
        "org.gnome.Terminal" "org.gnome.Console"
        "org.gnome.Ptyxis"   "dev.mitchellh.ghostty"
      ];
      remap = { "Super-C" = "C-C"; };
    }
    {
      name            = "Terminal/Nano: make ⌘ send Ctrl";
      application.only = [
        "org.gnome.Terminal" "org.gnome.Console"
        "org.gnome.Ptyxis"   "dev.mitchellh.ghostty"
      ];
      remap = {
        "Super-Q" = "C-Q"; "Super-W" = "C-W"; "Super-E" = "C-E";
        "Super-R" = "C-R"; "Super-T" = "C-T"; "Super-Y" = "C-Y";
        "Super-U" = "C-U"; "Super-O" = "C-O"; "Super-P" = "C-P";
        "Super-KEY_RIGHTBRACE" = "C-KEY_RIGHTBRACE";
        "Super-A" = "C-A"; "Super-S" = "C-S"; "Super-D" = "C-D";
        "Super-F" = "C-F"; "Super-G" = "C-G"; "Super-H" = "C-H";
        "Super-J" = "C-J"; "Super-K" = "C-K"; "Super-L" = "C-L";
        "Super-Z" = "C-Z"; "Super-X" = "C-X"; "Super-V" = "C-V";
        "Super-B" = "C-B"; "Super-N" = "C-N";
        "Super-KEY_SLASH"     = "C-KEY_SLASH";
        "Super-KEY_BACKSPACE" = "C-KEY_BACKSPACE";
      };
    }
    {
      name            = "VS Code basic shortcuts";
      application.only = [ "com.visualstudio.code" ];
      remap = {
        "Alt-LEFT"           = { launch = [ "xdotool" "key" "Home" ]; };
        "Alt-RIGHT"          = { launch = [ "xdotool" "key" "End" ]; };
        "Shift-Alt-LEFT"     = { launch = [ "xdotool" "key" "shift+Home" ]; };
        "Shift-Alt-RIGHT"    = { launch = [ "xdotool" "key" "shift+End" ]; };
        "Super-C"            = "C-C";
        "C-COMMA"            = { launch = [ "xdotool" "key" "ctrl+comma" ]; };
      };
    }
    {
      name            = "Console / Ptyxis shortcuts";
      application.only = [ "org.gnome.Console" "org.gnome.Ptyxis" ];
      remap = {
        "C-C" = "C-Shift-C"; "C-V" = "C-Shift-V"; "C-N" = "C-Shift-N";
        "C-Q" = "C-Shift-Q"; "C-T" = "C-Shift-T"; "C-W" = "C-Shift-W";
        "C-F" = "Shift-C-F";
      };
    }
    {
      name            = "Ghostty shortcuts";
      application.only = [ "dev.mitchellh.ghostty" ];
      remap = {
        "C-C" = "C-Shift-C"; "C-V" = "C-Shift-V"; "C-N" = "C-Shift-N";
        "C-Q" = "C-Shift-Q"; "C-T" = "C-Shift-T"; "C-W" = "C-Shift-W";
        "C-F" = "C-Shift-F";
      };
    }
    {
      name            = "Eclipse assist";
      application.only = [ "Eclipse" ];
      remap = { "Super-KEY_SPACE" = "Alt-KEY_SPACE"; "Super-KEY_TAB" = "Alt-KEY_TAB"; };
    }
  ];
}
