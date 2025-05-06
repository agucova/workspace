# SSH Server Configuration
{ config, pkgs, lib, ... }:

{
  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    # Use better encryption settings
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
    };
    # Allow agent forwarding (convenient for git operations)
    settings.AllowAgentForwarding = true;
    # Enable only public key authentication
    settings.PubkeyAuthentication = true;
  };

  # Make sure the firewall allows SSH connections
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Install additional SSH-related tools
  environment.systemPackages = with pkgs; [
    # SSH client with better UX
    mosh
    # SSH connection manager
    sshpass
    # SSH agent management
    keychain
  ];
}