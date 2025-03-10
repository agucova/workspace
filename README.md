# Workspace

A [PyInfra](https://pyinfra.com/) script that sets up my development machines. Installs all the tools, programming languages and apps that I use and applies my opinionated preferences for the shell, GNOME and other settings.

Supports both macOS and Ubuntu/Pop_OS! environments. This is a rewrite of my previous [Ansible](https://github.com/ansible/ansible) playbook (still available in the `ansible/` directory) with better performance and cross-platform support.

## Features

- Cross-platform support for macOS and Ubuntu/Pop_OS!
- Fast execution with PyInfra v3
- Modular design for easy customization
- Docker-based testing harness for non-GUI modules

## Testing

The repository includes Docker-based testing capabilities to test modules in a headless environment:

```bash
# Build the Docker image and run the entire setup (skipping GUI modules)
./docker-test.sh

# List available modules
./docker-test.sh --list

# Run a specific function from a module
./docker-test.sh env_setup.setup_fish

# Force rebuilding the Docker image
./docker-test.sh --build
```

Each module that requires a graphical environment (GNOME, Firefox, Kinto, Mathematica) has been updated with `has_display()` checks that automatically skip GUI-dependent operations when running in Docker or other headless environments. This allows testing the core functionality while skipping operations that would fail without a display.

## Things missing

- [NextDNS](https://nextdns.io/)
- [ULauncher](https://ulauncher.io/) extensions
- GNOME extensions

## Wish list

- [ ] Add Aerial screensaver
- [ ] Add [uxPlay](https://github.com/FDH2/UxPlay)
- [ ] CI/CD setup for automated testing

## To-do

- Complete feature parity with the Ansible version
- Do a full cleanup of my shell variables and functions
