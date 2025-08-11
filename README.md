# Workspace

My system configuration repository using Nix for declarative, reproducible development environments across NixOS and macOS.

## Primary Configuration: NixOS/Darwin

The main configuration (`nixos/` directory) provides a unified Nix Flake-based setup for both Linux (NixOS) and macOS (Darwin) systems using flake-parts for modular organization.

### Features

- **Cross-platform**: Unified configuration for NixOS and macOS with shared modules
- **Declarative**: Fully reproducible system and user configurations
- **Modular**: Clean separation of concerns using flake-parts
- **Hardware-optimized**: NixOS config tuned for AMD Ryzen 7800X3D + NVIDIA RTX 4090
- **Developer-focused**: Complete development environment with modern tools

### Supported Systems

- **NixOS** (`hackstation`): Main workstation with GNOME Desktop
- **Darwin** (`hackbookv5`): MacBook Pro with minimal dev environment
- **VM** (`vm`): NixOS testing configuration
- **Server** (`server`): Headless NixOS configuration

### Quick Start

#### NixOS
```bash
git clone https://github.com/agucova/workspace.git ~/repos/workspace
cd ~/repos/workspace/nixos
sudo nixos-rebuild switch --flake .#hackstation --experimental-features 'nix-command flakes' --impure
```

#### macOS
```bash
# Install Nix, then:
git clone git@github.com:agucova/workspace.git ~/Repos/workspace
cd ~/Repos/workspace/nixos
nix run nix-darwin -- switch --flake .#hackbookv5
```

See `nixos/README.md` for comprehensive documentation, installation instructions, and module details.

## Alternative Configurations

### PyInfra (Legacy)

The PyInfra implementation (`pyinfra/` directory) provides imperative configuration management for macOS and Debian-based distributions. While functional, this approach is being phased out in favor of the declarative Nix configuration.

**Features:**
- Cross-platform support for macOS and Ubuntu/Pop_OS!
- Fast execution with PyInfra v3
- Docker-based testing for headless modules
- Modular Python-based configuration

### Ansible (Deprecated)

The original Ansible playbook (`ansible/` directory) for Ubuntu-based distributions. This implementation is deprecated and preserved for historical reference only.

## Migration Status

- ✅ **NixOS**: Primary configuration, actively maintained
- ⚠️ **PyInfra**: Legacy, not actively developed
- ❌ **Ansible**: Deprecated, reference only

## Development Focus

Current development efforts are focused on:
1. Expanding Darwin (macOS) support in the Nix configuration
2. Improving cross-platform module sharing
3. Adding more development tools and languages
4. Enhancing system hardening and security

## Repository Structure

```
workspace/
├── nixos/          # Primary: Nix-based configuration
│   ├── flake.nix   # Flake entry point
│   ├── modules/    # Shared and platform-specific modules
│   ├── systems/    # System configurations
│   └── README.md   # Detailed documentation
├── pyinfra/        # Legacy: PyInfra scripts
└── ansible/        # Deprecated: Original Ansible playbook
```

## Contributing

Feel free to explore the configurations and adapt them for your own use. The Nix configuration is designed to be modular and easily customizable.