#!/usr/bin/env bash
set -euo pipefail

if ! grep -q "ubuntu" /etc/os-release; then
    echo "You're running a distro that doesn't seem to be derived from Ubuntu. This script will not work as it relies heavily on apt and Ubuntu paths."
    exit
fi

if ! command -v uv &> /dev/null; then
    # Install `uv`
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.local/bin/env
fi

# Run the main deployment script
uv run pyinfra @local main.py

# Ask the user if they want to set up dotfiles
echo ""
echo "===== PyInfra deployment completed ====="
read -p "Do you want to set up your private dotfiles now? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Run the dotfiles setup script
    echo "Setting up dotfiles..."
    uv run dotfiles_setup.py
fi
