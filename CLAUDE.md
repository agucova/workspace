# CLAUDE.md - Development Guide

## Build/Run Commands
- Setup environment: `uv run pyinfra @local main.py`
- Bootstrap (Ubuntu): `bash bootstrap.bash`
- Run specific tasks: `uv run pyinfra @local -v <module>.<function>`
- Test individual function: `echo 'from <module> import <function>; <function>()' | uv run -`
- Execute arbitrary Python: `echo '<python_code>' | uv run -`

## Docker Testing
- Run full setup (skipping GUI modules): `uv run docker_test.py run`
- List available modules: `uv run docker_test.py list_modules`
- Run specific function: `uv run docker_test.py run <module>.<function>`
- Run multiple functions in sequence: `uv run docker_test.py run packages.setup_repositories <module>.<function>`
- Rebuild Docker image: `uv run docker_test.py run --build`
- IMPORTANT: Always use `uv run` instead of `python` or `python3` for all Python commands
- Docker testing automatically skips GUI modules using config.has_display() checks
- The Dockerfile uses bootstrap.bash to set up the environment
- IMPORTANT: When testing modules that require apt-fast, always run packages.setup_repositories first
  (e.g., `uv run docker_test.py run packages.setup_repositories packages.install_1password`)

## NixOS Configuration

The `nixos/` directory contains a Nix Flake-based configuration for NixOS with GNOME Desktop:

> **IMPORTANT**: When updating NixOS configuration files, do NOT add comments indicating option renames or deprecation warnings (like "# Renamed from X" or "# This option is now deprecated"). Keep the code clean and commit messages should instead document these changes.

### Directory Structure
- `flake.nix` - Main entry point defining inputs and outputs for the configuration
- `modules/` - Modular NixOS configuration files:
  - `base.nix` - Core system configuration with AMD 7800X3D optimizations
  - `gnome.nix` - GNOME desktop environment setup with optimizations
  - `hardware.nix` - RTX 4090 GPU configuration with proprietary drivers
  - `virtualization.nix` - VM-specific configuration (used instead of hardware.nix)
- `hosts/` - Host-specific configurations:
  - `gnome/` - Main workstation configuration
  - `vm-test/` - VM testing configuration
- `iso/` - ISO image building configuration
- `COMMANDS.md` - Quick reference for common NixOS commands

### Key Features
- Flake-based configuration with modular design
- Optimized for AMD Ryzen 7800X3D + NVIDIA RTX 4090 hardware
- GNOME desktop with minimal customization and dark theme
- VM testing configuration for verifying changes
- ISO image building support
- Hardware configuration separating general optimizations from specific hardware details
- Home-manager integration for user-specific configuration

### NixOS Rebuild Command
```bash
# Apply configuration changes
sudo nixos-rebuild switch --flake /path/to/workspace/nixos#gnome-nixos --experimental-features 'nix-command flakes' --impure
```

The `--impure` flag is required because the configuration imports the system hardware configuration at `/etc/nixos/hardware-configuration.nix`.

### VM Testing
```bash
# Standard build and run
cd /path/to/workspace/nixos
nix build .#vm --impure
./result/bin/run-nixos-vm

# For high-performance build
cd /path/to/workspace/nixos
nix run .#run-vm  # Uses auto CPU core detection
# OR
nix run .#fast-build -- vm  # Uses optimized job settings

# Fast-build can be used for any output:
nix run .#fast-build -- [output-name]
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

## Linting and Type Checking
- Check types with pyright: `uv run pyright`
- Check a specific file: `uv run pyright <file.py>`
- Run ruff linter: `uv run ruff check .`
- Run ruff formatter: `uv run ruff format .`
- Fix auto-fixable issues: `uv run ruff check --fix .`
- Run complete checks: `uv run ruff check . && uv run ruff format --check . && uv run pyright`

## Recommended Workflow
1. Make changes to the codebase
2. Run formatter: `uv run ruff format .`
3. Run linter and fix issues: `uv run ruff check --fix .`
4. Run type checker: `uv run pyright`
5. Test the changes:
   - On local machine: `uv run pyinfra @local -v <module>.<function>`
   - In Docker (for headless modules): `uv run docker_test.py run <module>.<function>`
6. IMPORTANT: Never commit changes until they've been fully tested. Commit only after verifying functionality.
7. IMPORTANT: NEVER commit changes unless explicitly requested by the user. Always wait for confirmation before creating any git commits.
8. Use conventional commit messages

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

## Project Context
- This is a PyInfra v3 script for setting up development machines
- Supports both macOS and Ubuntu/Pop_OS! as targets
- Rewrite of older Ansible playbook (in `ansible/`) with better performance aimed at achieving better performance than Ansible, as well as adding macOS support
- PyInfra v3 documentation is available locally in `.claude/docs/pyinfra/`
- Be aware of differences between PyInfra v3 and v2 syntax, as you're likely to hallucinate constructs only present in PyInfra v2 by default

## Development Environment
- The local development environment is a fully set up Pop_OS! machine
- PyInfra operations are idempotent and will skip actions on an already-configured environment
- When making changes, assume the local machine represents the desired state by default
- Only diverge from the local machine configuration when explicitly needed
- Testing locally should be safe as operations will detect existing configurations and skip redundant actions
- Docker-based testing available for headless environments
