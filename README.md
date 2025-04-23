# Workspace

A multi-approach repository for configuring my development environments across different operating systems and platforms.

## Repository Structure

This repository contains three different approaches to system configuration:

1. **PyInfra** (`pyinfra/`): A [PyInfra](https://pyinfra.com/) implementation for both macOS and Debian-based distributions
2. **Ansible** (`ansible/`): The original [Ansible](https://github.com/ansible/ansible) playbook for Ubuntu-based distributions
3. **NixOS** (`nixos/`): A [Nix Flake](https://nixos.wiki/wiki/Flakes)-based configuration for NixOS with GNOME Desktop

## PyInfra Configuration

The PyInfra implementation (`pyinfra/` directory) sets up my development machines with all the tools, programming languages, and applications I use, and applies my opinionated preferences for shell, GNOME, and other settings.

### Features

- Cross-platform support for macOS and Ubuntu/Pop_OS!
- Fast execution with PyInfra v3
- Modular design for easy customization
- Docker-based testing harness for non-GUI modules

### Testing

The repository includes Docker-based testing capabilities to test modules in a headless environment:

```bash
# Build the Docker image and run the entire setup (skipping GUI modules)
cd pyinfra && uv run docker_test.py run

# List available modules
cd pyinfra && uv run docker_test.py list_modules

# Run a specific function from a module
cd pyinfra && uv run docker_test.py run env_setup.setup_fish

# Force rebuilding the Docker image
cd pyinfra && uv run docker_test.py run --build

# Run with interactive shell to inspect the container after execution
cd pyinfra && uv run docker_test.py run --interactive packages.setup_rust
# or the short version
cd pyinfra && uv run docker_test.py run -i packages.setup_rust
```

Each module that requires a graphical environment (GNOME, Firefox, Kinto, Mathematica) has been updated with `has_display()` checks that automatically skip GUI-dependent operations when running in Docker or other headless environments. This allows testing the core functionality while skipping operations that would fail without a display.

## NixOS Configuration

The NixOS implementation (`nixos/` directory) provides a Nix Flake-based configuration for NixOS with GNOME Desktop. It includes:

- Modular configuration with separate files for different aspects of the system
- Host-specific configurations for both bare-metal and VM testing
- Optimized for specific hardware (AMD Ryzen 7800X3D + NVIDIA RTX 4090)
- ISO image building capabilities

See the `nixos/README.md` and `nixos/COMMANDS.md` for detailed information about working with the NixOS configuration.

## Ansible Configuration

The Ansible implementation (`ansible/` directory) contains the original playbook for Ubuntu-based distributions. It predates the PyInfra implementation and offers similar functionality focused on Ubuntu/Pop_OS! environments.

## Things Missing

- [NextDNS](https://nextdns.io/)
- [ULauncher](https://ulauncher.io/) extensions
- GNOME extensions

## Wish List

- [ ] Add Aerial screensaver
- [ ] Add [uxPlay](https://github.com/FDH2/UxPlay)
- [ ] CI/CD setup for automated testing

## To-Do

- Complete feature parity with the Ansible version
- Do a full cleanup of my shell variables and functions
- Further develop the NixOS configuration