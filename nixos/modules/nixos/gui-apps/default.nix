# GUI Applications module for NixOS
# This module includes GUI applications that can be included in hosts that need them
# NOTE: This module is automatically enabled when imported (no enable option required)
{ pkgs, ... }:

let
  # Create a patched OpenSSH that doesn't check config permissions
  # This is only used within Zed's FHS environment
  openssh-no-checkperm = pkgs.openssh.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (pkgs.writeText "openssh-no-checkperm.patch" ''
        diff --git a/readconf.h b/readconf.h
        index ded13c9..94f489e 100644
        --- a/readconf.h
        +++ b/readconf.h
        @@ -203,7 +203,7 @@ typedef struct {
         #define SESSION_TYPE_SUBSYSTEM	1
         #define SESSION_TYPE_DEFAULT	2

        -#define SSHCONF_CHECKPERM	1  /* check permissions on config file */
        +#define SSHCONF_CHECKPERM	0  /* check permissions on config file */
         #define SSHCONF_USERCONF	2  /* user provided config file not system */
         #define SSHCONF_FINAL		4  /* Final pass over config, after canon. */
         #define SSHCONF_NEVERMATCH	8  /* Match/Host never matches; internal only */
      '')
    ];
    doCheck = false;
  });

  # Create a custom Zed package with the patched OpenSSH
  zed-with-fixed-ssh = pkgs.zed-editor.fhsWithPackages (p: [ openssh-no-checkperm ]);
in
{
  # Import submodules - all are automatically enabled when imported
  imports = [
    ./1password.nix
    # ./claude-desktop-icons.nix
  ];

  # Apply configuration directly
  config = {
    # GUI applications
    environment.systemPackages = with pkgs; [
      # Basics
      google-chrome

      # Office and Productivity
      libreoffice-qt
      vscode
      ghostty # From flake overlay
      zed-with-fixed-ssh
      gitkraken

      # Media and Entertainment
      vlc
      spotify
      discord
      signal-desktop
      telegram-desktop
      slack
      zoom-us

      # Productivity
      insync
      obsidian # Already native
      zotero # Already native
      calibre

      # GNOME-specific utilities
      gnome-disk-utility
      gnome-system-monitor

      # Entertainment
      lutris
      stremio
      cavalier

      # Cryptography
      cryptomator
    ];

    # Enable Firefox
    programs.firefox.enable = true;
    programs.steam.enable = true;
  };
}
