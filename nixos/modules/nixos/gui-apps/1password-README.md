# 1Password Module

This module provides integration for 1Password GUI application and CLI with SSH/Git integration.

## Features

- 1Password GUI application installation
- 1Password CLI installation with proper integration
- SSH agent integration for authentication
- Git commit signing integration
- Shell plugin support for bash and fish

## System Integration

The NixOS system module (`my1Password`) provides the following:

- GUI application installation
- CLI tool installation
- Polkit integration for permissions
- Shell plugin initialization

## Home Manager Integration

The Home Manager module (`my1Password`) provides:

- SSH agent integration for authentication
- Git commit signing configuration
- Shell plugin integration for bash and fish

## Usage

### System Configuration

In your system configuration (e.g., `/nixos/systems/x86_64-linux/hackstation/default.nix`):

```nix
{
  # Enable 1Password with SSH/CLI integration
  my1Password.enable = true;
  
  # Optional: Specify users that should have polkit permissions
  my1Password.users = [ "username1" "username2" ];
}
```

### Home Manager Configuration

In your home configuration (e.g., `/nixos/homes/x86_64-linux/agucova/default.nix`):

```nix
{
  # Enable 1Password SSH/Git integration
  my1Password.enable = true;
  
  # Optional: Configure SSH and Git individually
  my1Password.enableSSH = true;  # Default is true
  my1Password.enableGit = true;  # Default is true
}
```

## SSH Integration

This module configures SSH to use 1Password's SSH agent by adding the following to your SSH config:

```
IdentityAgent "~/.1password/agent.sock"
```

## Git Integration

For Git commit signing, this module configures Git to use 1Password's SSH signing:

```
[gpg]
  format = "ssh"
  ssh.program = "/path/to/op-ssh-sign"
```

## Shell Plugins

The module automatically sources 1Password shell plugins if available:

```bash
if [ -f ~/.config/op/plugins.sh ]; then
  source ~/.config/op/plugins.sh
fi
```

## Additional Setup

After installation, you'll need to:

1. Set up 1Password account in the GUI application
2. Enable SSH agent in 1Password settings
3. Add SSH keys to 1Password for authentication
4. For Git signing, configure your commit email to match your 1Password account

## Troubleshooting

- If SSH integration doesn't work, ensure SSH agent is enabled in 1Password settings
- For Git signing issues, make sure your commit email matches your 1Password account
- Check the 1Password status in the GUI application
- Verify the SSH agent socket exists at `~/.1password/agent.sock`