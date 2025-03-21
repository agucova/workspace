#!/usr/bin/env python3
"""
Main deployment script that ties all modules together.
"""

from config import is_linux, settings
from env_setup import (
    setup_directories,
    setup_fish,
    setup_python_env,
)
from gnome import configure_keyboard, configure_wallpaper
from packages import (
    install_claude_code,
    install_cuda,
    install_ghostty,
    install_julia,
    install_kinto,
    install_mathematica,
    setup_repositories_and_install_packages,
)

"""
Main deployment function that orchestrates all setup tasks.
Order is important:
    1. Set up repositories and install base packages.
    2. Prepare user directories and shell environment.
    3. Install core tools and applications.
    4. Apply Linux-specific configurations.
    5. Finally, apply dotfiles.
"""
# 1. System repositories and base packages.
setup_repositories_and_install_packages()

# 2. Base directories and shell environment.
setup_directories()
setup_fish()
setup_python_env()
install_julia()

# 3. Install additional tools (install_docker and install_firefox_dev are already handled)
install_claude_code()  # Install Claude Code CLI (works on both platforms)

# 4. Linux-specific configurations.
if is_linux():
    install_cuda()
    configure_wallpaper()  # GUI check happens inside the function
    configure_keyboard()  # GUI check happens inside the function
    install_kinto()  # GUI check happens inside the function
    install_mathematica()  # GUI check happens inside the function
    install_ghostty()  # GUI check happens inside the function

# Output testing status
if settings.docker_testing:
    print("\nExecuting in Docker testing mode - GUI modules skipped")
