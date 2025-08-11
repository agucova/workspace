# Fish shell functions and aliases
# Migrated from Chezmoi dotfiles
{ pkgs, ... }:

{
  programs.fish = {
    shellAliases = {
      # File navigation and viewing
      ls = "lsd --icon-theme fancy";
      ll = "lsd -l";
      la = "lsd -la";
      lt = "lsd --tree";
      l = "lsd -1Fa";
      cat = "bat";
      fd = "fd --hidden";
      
      # Development tools
      nano = "micro";
      code = "code-insiders";
      pip = "uv pip";
      python3 = "python";
      
      # Networking
      ping = "gping";
      
      # Fun
      lolcat = "lolcat --truecolor";
      
      # Docker utilities
      kali = "docker run --tty --interactive kalilinux/kali-rolling /bin/bash";
      
      # System tools
      o = "open";
      r = "ranger";
      pause = "read -P 'Press any key to continue...' -n 1";
    };
    
    functions = {
      # FZF enhanced with fd backend
      fzf = ''
        set -l FZF_DEFAULT_COMMAND 'fd --type file --hidden --exclude .git'
        command fzf $argv
      '';
      
      # 1Password CLI shortcut
      "1p" = ''
        set -l ITEM_ID (op item list | tail -n +2 | fzf | cut -d' ' -f1)
        and op item get $ITEM_ID
      '';
      
      # Humanize duration - convert milliseconds to human readable format
      humanize_duration = ''
        command awk '
          function hmTime(time,   stamp) {
              split("h:m:s:ms", units, ":")
              for (i = 2; i >= -1; i--) {
                  if (t = int( i < 0 ? time % 1000 : time / (60 ^ i * 1000) % 60 )) {
                      stamp = stamp t units[sqrt((i - 2) ^ 2) + 1] " "
                  }
              }
              if (stamp ~ /^ *$/) {
                  return "0ms"
              }
              return substr(stamp, 1, length(stamp) - 1)
          }
          { 
              print hmTime($0) 
          }
        '
      '';
      
      # Spotify integration (requires spotifycli)
      current = ''
        if test (spotifycli --playbackstatus) = "▶"
            echo ""
            echo "  ▶  Currently playing:" (spotifycli --status)
        end
      '';
      
      next = ''
        spotifycli --next
        sleep 0.25
        echo ""
        echo "  ⏭  Skipped to:" (spotifycli --status)
      '';
      
      # Network scanning shortcuts
      nmap = ''
        command nmap -Pn $argv
      '';
      
      nmapr = ''
        set -l host $argv[1]
        echo "Full port scan on $host..."
        command nmap -Pn -p- $host
      '';
      
      # Git helpers
      toigtv = ''
        git add .
        and git commit -m $argv
        and git push
      '';
      
      toresolve = ''
        git add .
        and git commit -m "resolves #$argv"
        and git push
      '';
      
      # Platform-specific functions
    } // (if pkgs.stdenv.isLinux then {
      # Linux-specific functions
      apt = ''
        command apt-fast $argv
      '';
      
      set50hz = ''
        xrandr --output eDP-1 --mode 1920x1080 --rate 50
      '';
    } else {});
  };
}