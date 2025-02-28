#!/usr/bin/env python3
"""
Main deployment script that ties all modules together.
"""

from config import is_linux
from env_setup import (
    apply_dotfiles,
    install_julia,
    setup_directories,
    setup_fish,
    setup_python_env,
)
from gnome import configure_keyboard, configure_wallpaper
from packages import (
    install_cuda,
    install_docker,
    install_firefox_dev,
    install_kinto,
    install_mathematica,
    install_rust,
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

# 3. Core system tools and applications.
install_docker()
install_firefox_dev()
install_rust()

# 4. Linux-specific configurations.
if is_linux():
    install_cuda()
    configure_wallpaper()
    configure_keyboard()
    install_mathematica()
    install_kinto()

# 5. Apply dotfiles.
apply_dotfiles()
