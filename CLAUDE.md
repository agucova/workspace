# CLAUDE.md - Development Guide

## Repository Structure

This repository contains multiple approaches to configure Linux and macOS environments:

- `ansible/` - Ansible playbook for Ubuntu-based distributions
- `pyinfra/` - PyInfra v3 scripts for Debian-based distributions and macOS
- `nixos/` - NixOS flake-based configuration using flake-parts for both VM testing and bare-metal GNOME setup

## PyInfra Configuration

The `pyinfra/` directory contains PyInfra v3 scripts for setting up development machines:

### Build/Run Commands
- Setup environment: `cd pyinfra && uv run pyinfra @local main.py`
- Bootstrap (Ubuntu): `cd pyinfra && bash bootstrap.bash`
- Run specific tasks: `cd pyinfra && uv run pyinfra @local -v <module>.<function>`
- Test individual function: `cd pyinfra && echo 'from <module> import <function>; <function>()' | uv run -`
- Execute arbitrary Python: `cd pyinfra && echo '<python_code>' | uv run -`

### Docker Testing
- Run full setup (skipping GUI modules): `cd pyinfra && uv run docker_test.py run`
- List available modules: `cd pyinfra && uv run docker_test.py list_modules`
- Run specific function: `cd pyinfra && uv run docker_test.py run <module>.<function>`
- Run multiple functions in sequence: `cd pyinfra && uv run docker_test.py run packages.setup_repositories <module>.<function>`
- Rebuild Docker image: `cd pyinfra && uv run docker_test.py run --build`
- IMPORTANT: Always use `uv run` instead of `python` or `python3` for all Python commands
- Docker testing automatically skips GUI modules using config.has_display() checks
- The Dockerfile uses bootstrap.bash to set up the environment
- IMPORTANT: When testing modules that require apt-fast, always run packages.setup_repositories first
  (e.g., `cd pyinfra && uv run docker_test.py run packages.setup_repositories packages.install_1password`)

### PyInfra Features
- Supports both macOS and Debian-based distributions (Ubuntu/Pop_OS!)
- Rewrite of older Ansible playbook with better performance and macOS support
- Idempotent operations that skip actions on already-configured environments
- Modular design with separate Python modules for different setup aspects
- Platform detection with config.is_linux() and config.is_macos()
- UI detection with config.has_display() for GUI-related operations

## NixOS Configuration

The `nixos/` directory contains a Nix Flake-based configuration using flake-parts for NixOS with GNOME Desktop:

> **IMPORTANT**: When updating NixOS configuration files, do NOT add comments indicating option renames or deprecation warnings (like "# Renamed from X" or "# This option is now deprecated"). Keep the code clean and commit messages should instead document these changes.

### Directory Structure (flake-parts-based)
- `flake.nix` - Main entry point defining inputs and outputs, uses flake-parts to structure the configuration
- `modules/` - Reusable configuration modules separated by platform:
  - `nixos/` - System-level modules:
    - `base/` - Core system configuration with AMD 7800X3D optimizations
    - `gnome/` - GNOME desktop environment setup with optimizations
    - `gui-apps/` - Graphical application setup including Claude desktop
    - `hardware/` - RTX 4090 GPU configuration with proprietary drivers
    - `macos-remap/` - macOS-like keyboard remapping
    - `vm/` - VM-specific configuration
    - `hardening/` - System security hardening
    - `ssh/` - SSH configuration
  - `home/` - User-level modules for home-manager:
    - `core-shell/` - Basic shell configuration
    - `dev-shell/` - Development environment setup
    - `dotfiles/` - User configuration files
    - `macos-remap/` - User-specific keyboard remapping
- `systems/` - Host-specific configurations:
  - `x86_64-linux/` - Platform-specific system configurations
    - `hackstation/` - Main physical machine configuration
    - `vm/` - VM testing configuration
    - `server/` - Server configuration
- `homes/` - Home manager configurations:
  - `x86_64-linux/` - Platform-specific home configurations
    - `agucova/` - User-specific home configuration
- `packages/` - Custom package definitions

### flake-parts Features
- **Modular Flake Structure**: Uses flake-parts to organize flake outputs cleanly
- **Explicit Configuration**: All modules and configurations are explicitly imported in the flake.nix
- **Modular Architecture**: Modules use the `enable = lib.mkEnableOption` pattern to create toggleable features
- **Cross-Platform Support**: Architecture-specific configurations are organized by directory structure
- **Home Manager Integration**: Home configurations are imported and wired explicitly in system configurations

### Module Naming Conventions
- Modules should use the `my*` prefix for options (e.g., `myGnome.enable = true`)
- Module option definitions should follow this pattern:
  ```nix
  let
    cfg = config.myModule;
  in {
    options.myModule = {
      enable = lib.mkEnableOption "Module description";
      # Other options...
    };

    config = lib.mkIf cfg.enable {
      # Configuration when enabled...
    };
  }
  ```
- System directory names correspond to nixosConfigurations names in the flake, with hostnames set explicitly in each system configuration

### Key Features
- Flake-based configuration with modular design using flake-parts
- Optimized for AMD Ryzen 7800X3D + NVIDIA RTX 4090 hardware
- GNOME desktop with minimal customization and dark theme
- VM testing configuration for verifying changes
- Hardware configuration separating general optimizations from specific hardware details
- Home-manager integration for user-specific configuration

### NixOS Rebuild Commands
```bash
# Apply configuration changes for the main system
sudo nixos-rebuild switch --flake /path/to/workspace/nixos#hackstation --experimental-features 'nix-command flakes' --impure

# Build without applying (useful for testing)
sudo nixos-rebuild build --flake /path/to/workspace/nixos#hackstation --experimental-features 'nix-command flakes' --impure

# List all available system configurations from flake structure
nix flake show /path/to/workspace/nixos
```

The `--impure` flag is required because the configuration imports the system hardware configuration at `/etc/nixos/hardware-configuration.nix`.

### Home Manager Commands
```bash
# Home manager is integrated into the system configuration
# Apply system changes which include home-manager configuration
sudo nixos-rebuild switch --flake /path/to/workspace/nixos#hackstation --experimental-features 'nix-command flakes' --impure

# Or use nh for a better experience
nh os switch
```

### Nix Development Commands

#### Updating Dependencies
```bash
# Update flake.lock file with latest dependency versions
cd /path/to/workspace/nixos
nix flake update

# Update just one input
cd /path/to/workspace/nixos
nix flake lock --update-input nixpkgs
```

#### Flake Information
```bash
# Show all flake outputs (systems, modules, packages)
cd /path/to/workspace/nixos
nix flake show

# Show detailed metadata about the flake
cd /path/to/workspace/nixos
nix flake metadata
```

#### Check and Build
```bash
# Check flake for errors without building
cd /path/to/workspace/nixos
nix flake check

# Build a specific output
cd /path/to/workspace/nixos
nix build .#nixosConfigurations.hackstation.config.system.build.toplevel --impure
```

#### Code Linting
Use statix to lint and fix common anti-patterns in Nix code:

```bash
# Run statix linter on all Nix files
nix run nixpkgs#statix -- check nixos/

# See proposed fixes without changing files
nix run nixpkgs#statix -- fix --dry-run nixos/

# Apply fixes (be careful!)
nix run nixpkgs#statix -- fix nixos/

# List all available lints
nix run nixpkgs#statix -- list

# Get explanation for a specific warning code
nix run nixpkgs#statix -- explain W20
```

Key lints include:
- W20: Repeated attribute keys
- W03/W04: Manual inherit patterns
- W07: Eta reductions
- W08: Useless parentheses

### VM Testing
```bash
# Build a VM directly
cd /path/to/workspace/nixos
nix build .#nixosConfigurations.vm.config.system.build.vm --impure

# Run the VM after building
./result/bin/run-nixos-vm

# Test building without running (for verification)
cd /path/to/workspace/nixos
nix build .#nixosConfigurations.vm.config.system.build.toplevel --impure --dry-run

# Test building the hackstation configuration
cd /path/to/workspace/nixos
nix build .#nixosConfigurations.hackstation.config.system.build.toplevel --impure --dry-run

# Quick run using the existing run-vm script (if available)
cd /path/to/workspace/nixos
nix run .#run-vm --impure  # Uses auto CPU core detection, auto-detects VM script
```

The VM configuration includes performance optimizations:
- Uses 12 CPU cores for the VM
- Allocates 8GB of RAM for better performance
- Uses CPU host passthrough for better performance
- Optimized Nix build settings to leverage your 7800X3D

### Notable Implementation Details
- Uses open-source NVIDIA drivers with proper Wayland support
- Includes Ghostty terminal with GPU acceleration
- Sets up optimized swapping with zram and a backup swapfile
- Configures PipeWire audio with low-latency settings
- Enables automatic Nix garbage collection
- Uses flakes for reproducible builds and dependencies
- Configures Flatpak with proper font and icon integration
- Custom Claude desktop icons package
- macOS-like keyboard remapping for Linux

## Ansible Configuration

The `ansible/` directory contains the original Ansible playbook for Ubuntu-based distributions:

- Primarily designed for Ubuntu/Pop_OS! configurations
- Predates the PyInfra implementation with similar functionality
- Contains tasks for package installation, desktop environment setup, and development tools

## Linting and Type Checking
- Check types with pyright: `cd pyinfra && uv run pyright`
- Check a specific file: `cd pyinfra && uv run pyright <file.py>`
- Run ruff linter: `cd pyinfra && uv run ruff check .`
- Run ruff formatter: `cd pyinfra && uv run ruff format .`
- Fix auto-fixable issues: `cd pyinfra && uv run ruff check --fix .`
- Run complete checks: `cd pyinfra && uv run ruff check . && uv run ruff format --check . && uv run pyright`

## Recommended Workflow
1. Make changes to the codebase
2. Run formatter: `cd pyinfra && uv run ruff format .`
3. Run linter and fix issues: `cd pyinfra && uv run ruff check --fix .`
4. Run type checker: `cd pyinfra && uv run pyright`
5. Test the changes:
   - On local machine: `cd pyinfra && uv run pyinfra @local -v <module>.<function>`
   - In Docker (for headless modules): `cd pyinfra && uv run docker_test.py run <module>.<function>`
   - For NixOS changes: Run validation before committing (see below)
6. IMPORTANT: Never commit changes until they've been fully tested. Commit only after verifying functionality using the build test commands.
7. IMPORTANT: NEVER commit changes unless explicitly requested by the user. Always wait for confirmation before creating any git commits.
8. Use conventional commit messages

### Testing Before Committing
Always test your NixOS configuration changes before committing:

```bash
# Quick test - just validate the flake structure
cd /path/to/workspace/nixos
nix flake check --no-build --impure

# IMPORTANT: Always build all three system configurations before committing
# For testing the main system configuration
nix build .#nixosConfigurations.hackstation.config.system.build.toplevel --impure --dry-run

# For testing the server configuration
nix build .#nixosConfigurations.server.config.system.build.toplevel --impure --dry-run

# For testing the VM configuration
nix build .#nixosConfigurations.vm.config.system.build.toplevel --impure --dry-run

# For basic validation of flake structure and outputs
nix flake check --no-build --impure

# For testing VM builds
nix build .#nixosConfigurations.vm.config.system.build.vm --impure
```

These tests ensure your changes don't break the system configuration. If any test fails, fix the issues before committing. Common errors include:
- Missing or incorrect module references
- Type errors in configuration values
- Circular dependencies
- Missing hardware configuration settings

## Code Style Guidelines
- **Typing**: Use type hints throughout; prefer `|` for union types in Python 3.10+
- **Imports**: Group standard library first, then third-party, then local modules
- **Formatting**: Follow PEP 8 with line length of 100, enforced by ruff
- **Naming**: Use snake_case for functions/variables, PascalCase for classes
- **Path handling**: Use pathlib.Path for all filesystem operations
- **Error handling**: Prefer early returns over deeply nested conditionals
- **Configuration**: Use pydantic_settings for typed configuration
- **Platform checks**: Use config.is_linux() and config.is_macos() for OS-specific code
- **UI checks**: Use config.has_display() to check for graphical environment
- **Documentation**: Docstrings for modules and functions explaining purpose

## Development Environment
- The local development environment is a fully set up Pop_OS! machine
- PyInfra operations are idempotent and will skip actions on already-configured environment
- When making changes, assume the local machine represents the desired state by default
- Only diverge from the local machine configuration when explicitly needed
- Testing locally should be safe as operations will detect existing configurations and skip redundant actions
- Docker-based testing available for headless environments
