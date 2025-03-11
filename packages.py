"""
packages.py

This module installs repositories and packages to bring your system to parity with your previous Ansible configuration.
It defines several deploy functions for installing different types of packages and applications.

Each category of packages is defined within the function that installs them, keeping related code together
while still maintaining organization and readability.

Most development tools are installed via Homebrew (Linuxbrew on Linux) using a common list.
Other operations (e.g. adding apt repositories, flatpak installs) are handled separately.
"""

import itertools
from io import StringIO
from pathlib import Path

from pyinfra.api.deploy import deploy
from pyinfra.context import host
from pyinfra.facts.files import Directory, File
from pyinfra.facts.server import LsbRelease, OsRelease
from pyinfra.operations import apt, brew, files, flatpak, server, snap

# Import our apt-fast module for faster parallel downloads
import apt_fast

from config import BREW_PATH, HOME, USER, has_display, is_linux, is_macos, settings
from facts import (
    DebsigPolicies,
    DockerConfiguration,
    FlatpakRemotes,
    KernelParameters,
    UserGroups,
)


# Import the Julia installation function
# We use a late import to avoid circular imports
def import_julia_function():
    try:
        from env_setup import install_julia

        return install_julia
    except ImportError:
        from pyinfra.api.deploy import deploy

        @deploy("Julia Stub")
        def install_julia_stub() -> None:
            print("Julia installation function not available")

        return install_julia_stub


@deploy("Setup Package Repositories")
def setup_repositories() -> None:
    """Set up package repositories for the system."""
    if is_linux():
        # Add PPAs
        apt.ppa(name="Add Fish Shell PPA", src="ppa:fish-shell/release-3", _sudo=True)
        apt.ppa(name="Add apt-fast PPA", src="ppa:apt-fast/stable", _sudo=True)
        apt.ppa(name="Add Solaar PPA", src="ppa:solaar-unifying/ppa", _sudo=True)
        apt.ppa(
            name="Add Cryptomator PPA",
            src="ppa:sebastian-stenzel/cryptomator",
            _sudo=True,
        )

        # Ensure apt-fast is installed
        # We use apt here since apt-fast isn't available yet
        apt.packages(
            name="Ensure apt-fast is installed",
            packages=["apt-fast"],
            _sudo=True,
        )

        # Download key ACCAF35C from ubuntu pgp, dearmor and then add signed-by
        if not host.get_fact(File, "/etc/apt/keyrings/insync.gpg"):
            server.shell(
                name="Add Insync GPG key",
                commands=[
                    "gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys ACCAF35C",
                    "gpg --export ACCAF35C > /etc/apt/keyrings/insync.gpg",
                ],
                _sudo=True,
            )

        codename = host.get_fact(LsbRelease)["codename"]
        apt.repo(
            name="Add Insync repository",
            src=(
                "deb [arch=amd64 signed-by=/etc/apt/keyrings/insync.gpg] "
                f"http://apt.insync.io/ubuntu {codename} non-free contrib"
            ),
            _sudo=True,
        )

        # Use apt-fast for update and upgrade operations with 16 parallel downloads
        apt_fast.update(
            name="Update apt repositories", cache_time=3600, parallel=16, _sudo=True
        )
        apt_fast.upgrade(
            name="Upgrade APT packages", auto_remove=True, parallel=16, _sudo=True
        )


@deploy("Setup Homebrew")
def setup_brew() -> None:
    """Set up Homebrew for package management."""
    # Check if brew is installed
    if not host.get_fact(Directory, str(BREW_PATH)):
        server.shell(
            name="Install brew",
            commands=[
                "NONINTERACTIVE=1 curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash"
            ],
            _sudo=True,
            _preserve_sudo_env=True,
            _sudo_user=USER,
        )

    # Set up taps based on platform
    if is_linux():
        brew.tap(
            name="Tap linuxbrew/fonts",
            src="linuxbrew/fonts",
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )
    elif is_macos():
        brew.tap(
            name="Tap homebrew/core",
            src="homebrew/core",
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )
        brew.tap(
            name="Tap homebrew/cask-fonts",
            src="homebrew/cask-fonts",
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )


@deploy("Install Development Tools")
def install_dev_tools() -> None:
    """Install development tools and utilities."""
    # Development tools and utilities
    dev_tools = {
        "brew": [
            "git",
            "curl",
            "pyenv",
            "fzf",
            "ripgrep",
            "git-delta",
            "jq",
            "gh",
            "httpie",
            "shellcheck",
            "hyperfine",
            "glow",
        ],
        "apt": [
            "git",
            "curl",
            "httpie",
            "shellcheck",
        ],
    }

    if is_linux():
        apt_fast.packages(
            name="Install development tools (APT)",
            packages=dev_tools["apt"],
            parallel=16,
            no_recommends=True,
            _sudo=True,
        )

    # Install Brew packages for dev tools on both platforms
    # Install in batches to prevent triggering open file limits
    for i, packages in enumerate(itertools.batched(dev_tools["brew"], 5)):
        brew.packages(
            name=f"Install dev tools (Brew batch #{i})",
            packages=packages,
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )


@deploy("Install Shell Tools")
def install_shell_tools() -> None:
    """Install shell and terminal enhancement tools."""
    # Shell and terminal enhancements
    shell_tools = {
        "brew": ["lsd", "bat", "navi", "fd", "starship", "fish", "btop"],
        "apt": ["fish", "neofetch", "micro", "btop", "ncdu", "mosh"],
    }

    if is_linux():
        apt_fast.packages(
            name="Install shell tools (APT)",
            packages=shell_tools["apt"],
            parallel=16,
            no_recommends=True,
            _sudo=True,
        )

    # Install Brew packages for shell tools on both platforms
    # Install in batches to prevent triggering open file limits
    for i, packages in enumerate(itertools.batched(shell_tools["brew"], 5)):
        brew.packages(
            name=f"Install shell tools (Brew batch #{i})",
            packages=packages,
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )


@deploy("Install Build Tools")
def install_build_tools() -> None:
    """Install build tools and development dependencies."""
    # Build tools and dependencies
    build_tools = {
        "brew": ["autoconf", "automake", "cmake", "sqlite"],
        "apt": [
            "autoconf",
            "automake",
            "cmake",
            "meson",
            "ninja-build",
            "build-essential",
            # Build dependencies
            "libbz2-dev",
            "libcurl4-openssl-dev",
            "libexpat-dev",
            "libffi-dev",
            "libharfbuzz-bin",
            "liblzma-dev",
            "libncurses-dev",
            "libnotify-bin",
            "libreadline-dev",
            "libsqlite3-dev",
            "libssl-dev",
            "libxml2-dev",
            "libxmlsec1-dev",
            "libyaml-dev",
            "zlib1g-dev",
            "mesa-common-dev",
            "llvm",
            "texinfo",
            "tk-dev",
        ],
    }

    if is_linux():
        apt_fast.packages(
            name="Install build tools (APT)",
            packages=build_tools["apt"],
            parallel=16,
            no_recommends=True,
            _sudo=True,
        )

    # Install Brew packages for build tools on both platforms
    brew.packages(
        name="Install build tools (Brew)",
        packages=build_tools["brew"],
        _env={"PATH": f"{BREW_PATH}:$PATH"},
    )


@deploy("Install Programming Languages")
def install_programming_languages() -> None:
    """Install programming languages and related tools."""
    # Programming languages and platforms
    programming_languages = {
        "brew": ["golang", "oven-sh/bun/bun", "ansible", "ansible-lint"],
        "apt": ["golang", "ruby", "python3-pip", "ansible", "ansible-lint", "composer"],
    }

    if is_linux():
        apt_fast.packages(
            name="Install programming languages (APT)",
            packages=programming_languages["apt"],
            parallel=16,
            no_recommends=True,
            _sudo=True,
        )

    # Install Brew packages for programming languages on both platforms
    brew.packages(
        name="Install programming languages (Brew)",
        packages=programming_languages["brew"],
        _env={"PATH": f"{BREW_PATH}:$PATH"},
    )

    # Install Rust (specific language installation that needs special handling)
    install_rust()

    # Install Julia (dynamically imported to avoid circular imports)
    install_julia = import_julia_function()
    install_julia()


@deploy("Install System Utilities")
def install_system_utilities() -> None:
    """Install system utilities and tools."""
    # System utilities and tools
    system_utilities = {
        "brew": ["pandoc", "aria2", "gzip", "chezmoi", "tree"],
        "apt": [
            "apt-fast",
            "apt-transport-https",
            "aria2",
            "dnsutils",
            "ca-certificates",
            "preload",
            "timeshift",
            "ufw",
            "unrar",
            "iperf",
            "cowsay",
            "lolcat",
            "magic-wormhole",
            "masscan",
            "nmap",
            "whois",
            "xz-utils",
            "tree",
            "sqlite3",
            "openvpn",
            "network-manager-openvpn",
            "software-properties-common",
            "fastboot",
            "nvtop",
            "pipx",
            "snapd",
            "python3-colorama",
            "python3-gi",
            "prettyping",
            "clang-format",
        ],
    }

    if is_linux():
        apt_fast.packages(
            name="Install system utilities (APT)",
            packages=system_utilities["apt"],
            parallel=16,
            no_recommends=True,
            _sudo=True,
        )

    # Install Brew packages for system utilities on both platforms
    brew.packages(
        name="Install system utilities (Brew)",
        packages=system_utilities["brew"],
        _env={"PATH": f"{BREW_PATH}:$PATH"},
    )


@deploy("Install GUI Applications")
def install_gui_apps() -> None:
    """Install GUI applications."""
    # GUI applications
    gui_apps = {
        "apt": [
            "calibre",
            "flameshot",
            "inkscape",
            "gnome-boxes",
            "transmission",
            "celluloid",
            "imagemagick",
            "solaar",
            "cryptomator",
            "insync",
        ],
        "brew_cask": [
            "calibre",
            "transmission",
            "vlc",
            "insync",
            "celluloid",
        ],
        "flatpak": [
            "com.axosoft.GitKraken",
            "com.stremio.Stremio",
            "org.zotero.Zotero",
            "md.obsidian.Obsidian",
            "org.jamovi.jamovi",
            "org.zulip.Zulip",
        ],
        "snap": [
            "discord",
            "spotify",
            "telegram-desktop",
            "signal-desktop",
            "slack",
        ],
    }

    # Skip if no display
    if not has_display():
        print("Skipping GUI applications (no display available)")
        return

    if is_linux():
        apt_fast.packages(
            name="Install GUI applications (APT)",
            packages=gui_apps["apt"],
            parallel=16,
            _sudo=True,
        )

        # Install Flatpak apps if flatpak is available
        flatpak_remotes = host.get_fact(FlatpakRemotes)

        # Check if flatpak is available
        if flatpak_remotes is None:
            # Install flatpak if not already installed
            apt_fast.packages(
                name="Ensure flatpak is installed",
                packages=["flatpak"],
                parallel=16,
                no_recommends=True,
                _sudo=True,
            )
            # Retry getting flatpak remotes
            flatpak_remotes = host.get_fact(FlatpakRemotes)

        # Add flathub remote if flatpak is available and flathub isn't configured
        if flatpak_remotes is not None and "flathub" not in flatpak_remotes:
            server.shell(
                name="Add Flathub remote",
                commands=[
                    "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
                ],
                _sudo=True,
            )

        # Only try to install flatpak apps if flatpak is available
        if flatpak_remotes is not None:
            flatpak.packages(
                name="Install Flatpak packages",
                packages=gui_apps["flatpak"],
                _sudo=True,
            )
        else:
            print("Skipping Flatpak package installation (flatpak not available)")

        # Install Snap apps
        # First ensure snapd is installed
        apt_fast.packages(
            name="Ensure snapd is installed",
            packages=["snapd"],
            parallel=16,
            no_recommends=True,
            _sudo=True,
        )

        for snap_app in gui_apps["snap"]:
            snap.package(name=f"Install {snap_app}", packages=snap_app, _sudo=True)

        # Install Zoom
        apt_fast.deb(
            name="Install Zoom",
            src="https://zoom.us/client/latest/zoom_amd64.deb",
            parallel=16,
            _sudo=True,
        )

    elif is_macos():
        brew.casks(
            name="Install GUI applications (Brew casks)",
            casks=gui_apps["brew_cask"],
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )


@deploy("Install Gaming Applications")
def install_gaming_apps() -> None:
    """Install gaming applications."""
    # Gaming applications
    gaming = {
        "apt": ["steam-installer", "lutris"],
    }

    # Skip if no display
    if not has_display():
        print("Skipping gaming applications (no display available)")
        return

    if is_linux():
        apt_fast.packages(
            name="Install gaming applications",
            packages=gaming["apt"],
            parallel=16,
            _sudo=True,
        )


@deploy("Install GNOME Tools")
def install_gnome_tools() -> None:
    """Install GNOME desktop tools and extensions."""
    # GNOME desktop tools
    gnome_tools = {
        "apt": [
            "gnome-tweaks",
            "gnome-shell-extensions",
            "gnome-shell-extension-appindicator",
            "gnome-sushi",
        ],
    }

    # Skip if no display or not Linux
    if not has_display() or not is_linux():
        print("Skipping GNOME tools (no display or not Linux)")
        return

    apt_fast.packages(
        name="Install GNOME tools",
        packages=gnome_tools["apt"],
        parallel=16,
        _sudo=True,
    )


@deploy("Install Fonts")
def install_fonts() -> None:
    """Install font packages."""
    # Font packages
    fonts = {
        "apt": ["fonts-inter", "fonts-roboto"],
    }

    if is_linux():
        apt_fast.packages(
            name="Install fonts (APT)",
            packages=fonts["apt"],
            parallel=16,
            _sudo=True,
        )

    # Brew font taps are set up in setup_brew


@deploy("Install Docker")
def install_docker() -> None:
    """Install Docker and related tools."""
    # Containerization - Docker packages
    docker_packages = [
        "docker-ce",
        "docker-ce-cli",
        "containerd.io",
        "docker-buildx-plugin",
        "docker-compose-plugin",
    ]

    if is_linux():
        if not host.get_fact(File, "/etc/apt/keyrings/docker.asc"):
            server.shell(
                name="Add Docker GPG key",
                commands=[
                    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
                    "chmod a+r /etc/apt/keyrings/docker.asc",
                ],
                _sudo=True,
            )
        codename = host.get_fact(LsbRelease)["codename"]
        apt.repo(
            name="Add Docker repository",
            src=(
                "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] "
                f"https://download.docker.com/linux/ubuntu {codename} stable"
            ),
            _sudo=True,
        )
        apt_fast.update(name="Update apt for Docker", parallel=16, _sudo=True)
        apt_fast.packages(
            name="Install Docker packages",
            packages=docker_packages,
            parallel=16,
            no_recommends=True,
            _sudo=True,
        )
        if "docker" not in host.get_fact(UserGroups):
            server.shell(
                name="Add user to docker group",
                commands=[f"usermod -aG docker {USER}"],
                _sudo=True,
            )
    elif is_macos():
        brew.casks(
            name="Install Docker Desktop",
            casks=["docker"],
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )


@deploy("Install Firefox Developer Edition")
def install_firefox_dev() -> None:
    """Install Firefox Developer Edition."""
    if not has_display():
        print("Skipping Firefox Developer Edition installation (no display available)")
        return

    if is_linux():
        apps_dir = HOME / ".local/share/applications"
        if not (
            host.get_fact(Directory, "/opt/firefox-dev")
            and host.get_fact(File, f"{apps_dir}/firefox-dev.desktop")
        ):
            # Create the target directories
            files.directory(
                name="Create applications directory",
                path=str(apps_dir),
                mode="755",
                user=USER,
                group=USER,
            )

            files.directory(
                name="Create Firefox Developer Edition directory",
                path="/opt/firefox-dev",
                _sudo=True,
            )

            # Download Firefox Developer Edition
            files.download(
                name="Download Firefox Developer Edition",
                src="https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64",
                dest="/tmp/firefox-dev.tar.xz",
                _sudo=True,
            )

            # Extract it to the target directory
            server.shell(
                name="Extract Firefox Developer Edition",
                commands=["tar -xJf /tmp/firefox-dev.tar.xz -C /opt/firefox-dev"],
                _sudo=True,
            )

            # Create the desktop file using files.put
            desktop_entry = (
                "[Desktop Entry]\n"
                "Version=1.0\n"
                "Type=Application\n"
                "Name=Firefox Developer Edition\n"
                "GenericName=Web Browser\n"
                "Icon=/opt/firefox-dev/firefox/browser/chrome/icons/default/default128.png\n"
                "Exec=/opt/firefox-dev/firefox/firefox %u\n"
                "Terminal=false\n"
                "Categories=GNOME;GTK;Network;WebBrowser;"
            )

            files.put(
                name="Create Firefox Developer Edition desktop entry",
                src=StringIO(desktop_entry),
                dest=f"{apps_dir}/firefox-dev.desktop",
                user=USER,
                group=USER,
                mode="644",
            )

            # Cleanup downloaded file
            files.file(
                name="Cleanup Firefox Dev download",
                path="/tmp/firefox-dev.tar.xz",
                present=False,
                _sudo=True,
            )
    elif is_macos():
        brew.casks(
            name="Install Firefox Developer Edition",
            casks=["firefox-developer-edition"],
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )


@deploy("Install Rust")
def install_rust() -> None:
    """
    Install Rust using rustup and install common cargo tools.
    This function checks if rustup is already installed, and if not,
    it installs it. Then it installs common cargo tools.
    """
    rustup_path = HOME / ".cargo" / "bin" / "rustup"

    # Install rustup if not already installed
    if not host.get_fact(File, str(rustup_path)):
        server.shell(
            name="Install Rust using rustup",
            commands=[
                "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y",
            ],
        )

    # In a real environment, we would proceed to install cargo-update and cargo-edit
    # Here we check if running in Docker to avoid long compilations during testing
    if settings.docker_testing:
        # For Docker testing, we'll just verify Rust is correctly installed
        server.shell(
            name="Verify Rust installation in Docker",
            commands=[
                f"bash -c 'source {HOME}/.cargo/env && rustc --version && cargo --version'",
            ],
        )
        print(
            "In non-testing environments, would proceed to install cargo-update and cargo-edit"
        )
    else:
        # Normal operation - install cargo tools
        server.shell(
            name="Install Cargo tools",
            commands=[
                f"bash -c 'source {HOME}/.cargo/env && cargo install cargo-edit cargo-update --force'",
            ],
        )


@deploy("Install CUDA for PopOS")
def install_cuda() -> None:
    """Install CUDA and related tools for Pop!_OS."""
    # CUDA and ML packages
    cuda_packages = [
        "nvidia-cuda-toolkit",
        "nvidia-container-toolkit",
        "nvidia-docker2",
        "tensorman",
    ]

    if is_linux():
        os_release = host.get_fact(OsRelease) or {}
        if "pop" in os_release.get("NAME", "").lower():
            # Install CUDA packages
            apt.packages(
                name="Install CUDA and cuDNN packages",
                packages=cuda_packages,
                cache_time=3600,
                _sudo=True,
            )

            if "systemd.unified_cgroup_hierarchy=0" not in host.get_fact(
                KernelParameters
            ):
                # Configure system for CUDA
                server.shell(
                    name="Configure Unified Cgroup Hierarchy",
                    commands=[
                        'kernelstub --add-options "systemd.unified_cgroup_hierarchy=0"',
                    ],
                    _sudo=True,
                )
            docker_config = host.get_fact(DockerConfiguration)
            if "nvidia-container-runtime" not in docker_config.get("runtimes", {}):
                server.shell(
                    name="Configure Docker for NVIDIA runtime",
                    commands=["nvidia-ctk runtime configure --runtime=docker"],
                    _sudo=True,
                )


@deploy("Install Mathematica")
def install_mathematica() -> None:
    """Install Mathematica if license key is available."""
    if not has_display():
        print("Skipping Mathematica installation (no display available)")
        return

    mathematica_bin = "/usr/local/bin/mathematica"
    if not Path(mathematica_bin).exists() and settings.mathematica_license_key:
        wolfram_email = "agucova@uc.cl"
        server.shell(
            name="Download and install Mathematica",
            commands=[
                f"wget -O /tmp/mathematica.sh 'https://user.wolfram.com/portal/mySiteUserProduct.html?licnumber={settings.mathematica_license_key}&email={wolfram_email}&lpid=LATEST#'",
                "bash /tmp/mathematica.sh -y",
            ],
            _sudo=True,
        )


@deploy("Install Kinto")
def install_kinto() -> None:
    """
    Clone and install Kinto for keyboard remapping.
    This deploy function clones the repository into ~/repos/kinto (if not already present)
    and then runs its setup script.
    """
    if not has_display():
        print("Skipping Kinto installation (no display available)")
        return

    kinto_dir = HOME / "repos" / "kinto"

    # Clone the repository if it doesn't exist.
    if not host.get_fact(Directory, str(kinto_dir)):
        server.shell(
            name="Clone Kinto repository",
            commands=[f"git clone https://github.com/rbreaves/kinto.git {kinto_dir}"],
        )

        # Run the Kinto setup.
        server.shell(
            name="Install Kinto",
            commands=[f"cd {kinto_dir} && python3 setup.py"],
            _sudo=True,
        )


@deploy("Install 1Password")
def install_1password() -> None:
    """Install 1Password and command-line interface."""

    if is_linux():
        try:
            # Try to check for existing GPG key
            if not host.get_fact(
                File, "/usr/share/keyrings/1password-archive-keyring.gpg"
            ):
                # Create keyrings directory if it doesn't exist
                files.directory(
                    name="Ensure keyrings directory exists",
                    path="/usr/share/keyrings",
                    mode="755",
                    _sudo=True,
                )

                # Download the key
                files.download(
                    name="Download 1Password GPG key",
                    src="https://downloads.1password.com/linux/keys/1password.asc",
                    dest="/tmp/1password.asc",
                    _sudo=True,
                )

                # Dearmor and save the key
                server.shell(
                    name="Convert 1Password GPG key",
                    commands=[
                        "gpg --dearmor < /tmp/1password.asc > /usr/share/keyrings/1password-archive-keyring.gpg",
                        "chmod 644 /usr/share/keyrings/1password-archive-keyring.gpg",
                        "rm /tmp/1password.asc",
                    ],
                    _sudo=True,
                )

            # Add 1Password repository
            apt.repo(
                name="Add 1Password repository",
                src=(
                    "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] "
                    "https://downloads.1password.com/linux/debian/amd64 stable main"
                ),
                _sudo=True,
            )

            # Update apt cache after adding repository
            apt_fast.update(
                name="Update apt cache for 1Password",
                parallel=16,
                _sudo=True,
            )

            # Check if 1Password policy already exists
            policies = host.get_fact(DebsigPolicies)
            # Handle None case explicitly - policies can be None in the Docker environment
            if policies is None or "AC2D62742012EA22" not in policies:
                # Use directories first to ensure parent directories exist
                files.directory(
                    name="Create debsig policies directory",
                    path="/etc/debsig/policies",
                    mode="0755",
                    _sudo=True,
                )

                # Make sure AC2D62742012EA22 policy directory exists
                files.directory(
                    name="Create 1Password policy directory",
                    path="/etc/debsig/policies/AC2D62742012EA22",
                    mode="0755",
                    _sudo=True,
                )

                # Add 1Password policy file
                server.shell(
                    name="Add 1Password debsig policy",
                    commands=[
                        "curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol"
                    ],
                    _sudo=True,
                )

            # Create keyrings directories if needed
            if policies is None or "AC2D62742012EA22" not in policies:
                files.directory(
                    name="Create debsig keyrings directory",
                    path="/usr/share/debsig/keyrings",
                    mode="0755",
                    _sudo=True,
                )

                files.directory(
                    name="Create 1Password keyrings directory",
                    path="/usr/share/debsig/keyrings/AC2D62742012EA22",
                    mode="0755",
                    _sudo=True,
                )

                # Add 1Password keyring
                server.shell(
                    name="Add 1Password debsig keyring",
                    commands=[
                        "curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg"
                    ],
                    _sudo=True,
                )

            # Install 1password
            apt_fast.packages(
                name="Install 1Password",
                packages=["1password", "1password-cli"],
                parallel=16,
                _sudo=True,
            )

        except Exception as e:
            # Log the error and continue
            print(f"Error installing 1Password: {e}")
            print("Continuing with other installations...")
            return
    elif is_macos():
        brew.casks(
            name="Install 1Password",
            casks=["1password", "1password-cli"],
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )


@deploy("Setup Repositories and Install Packages")
def setup_repositories_and_install_packages() -> None:
    """
    Main function that sets up repositories and installs all packages.
    This calls the individual specialized functions in the correct order.
    """
    # Setup repositories first
    setup_repositories()

    # Setup Homebrew
    setup_brew()

    # Install system-level packages
    install_system_utilities()

    # Install development tools
    install_dev_tools()
    install_build_tools()
    install_programming_languages()
    install_shell_tools()

    # Install GUI applications if display is available
    if has_display():
        install_gui_apps()
        install_gaming_apps()
        install_gnome_tools()
        install_fonts()
        install_firefox_dev()

    # Install Docker and 1Password
    install_docker()
    install_1password()
