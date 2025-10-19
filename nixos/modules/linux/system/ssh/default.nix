# SSH Configuration Module
{ config, pkgs, lib, ... }:

let
  cfg = config.hardenedSSH;
in
{
  options.hardenedSSH = {
    client = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable hardened SSH client tools and configuration.";
      };
    };

    server = {
      enable = lib.mkEnableOption "Hardened SSH server configuration";
      # mkEnableOption defaults to false
    };
  };

  config = lib.mkMerge [
    # SSH Client Configuration
    (lib.mkIf cfg.client.enable {
      # Install client-related SSH tools
      environment.systemPackages = with pkgs; [
        # Standard SSH client is included in most base configurations
        openssh
        # SSH client with better UX
        mosh
        # SSH connection manager
        sshpass
        # SSH agent management
        keychain
      ];

      # Set up common SSH client configurations
      # Commented out to avoid deprecation warning about default values
      # TODO: Re-enable with proper matchBlocks configuration when needed
      # programs.ssh = {
      #   extraConfig = ''
      #     ServerAliveInterval 60
      #     ServerAliveCountMax 3
      #     AddKeysToAgent yes
      #     HashKnownHosts yes
      #   '';
      # };
    })

    # SSH Server Configuration
    (lib.mkIf cfg.server.enable {
      # Enable the OpenSSH daemon with hardened settings
      services.openssh = {
        enable = true;
        settings = {
          # Disable password authentication
          PasswordAuthentication = false;
          # Use newer key exchange algorithms
          KexAlgorithms = [
            "curve25519-sha256@libssh.org"
            "diffie-hellman-group-exchange-sha256"
          ];
          # Only allow modern ciphers
          Ciphers = [
            "chacha20-poly1305@openssh.com"
            "aes256-gcm@openssh.com"
            "aes128-gcm@openssh.com"
            "aes256-ctr"
            "aes192-ctr"
            "aes128-ctr"
          ];
          # Only use modern MACs
          Macs = [
            "hmac-sha2-512-etm@openssh.com"
            "hmac-sha2-256-etm@openssh.com"
            "umac-128-etm@openssh.com"
          ];
          # No root login
          PermitRootLogin = "no";
          # Use Linux-specific security enhancements
          UsePAM = true;
          X11Forwarding = false;
          # Allow agent forwarding (convenient for git operations)
          AllowAgentForwarding = true;
          # Enable only public key authentication
          PubkeyAuthentication = true;
        };
      };

      # Make sure the firewall allows SSH connections
      networking.firewall.allowedTCPPorts = [ 22 ];
    })
  ];
}
