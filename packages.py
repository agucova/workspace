"""
packages.py

This module installs repositories and packages to bring your system to parity with your previous Ansible configuration.

It defines three deploy functions:
  • setup_repositories_and_install_packages()
  • install_docker()
  • install_firefox_dev()

Most development tools are installed via Homebrew (Linuxbrew on Linux) using a common list.
Other operations (e.g. adding apt repositories, flatpak installs) are handled separately.
"""

import itertools
from pathlib import Path

from pyinfra.api.deploy import deploy
from pyinfra.context import host
from pyinfra.facts.files import Directory, File
from pyinfra.facts.server import LsbRelease, OsRelease
from pyinfra.operations import apt, brew, cargo, flatpak, server, snap
from pyinfra.operations.files import directory

from config import BREW_PATH, HOME, USER, has_display, is_linux, is_macos, settings
from facts import (
    DebsigPolicies,
    DockerConfiguration,
    FlatpakRemotes,
    KernelParameters,
    UserGroups,
)


@deploy("Setup Repositories and Install Packages")
def setup_repositories_and_install_packages() -> None:
    # Define the common base Brew packages for development tools.
    base_brew_packages = [
        "git",
        "curl",
        "pyenv",
        "fzf",
        "lsd",
        "bat",
        "navi",
        "fd",
        "hyperfine",
        "glow",
        "gh",
        "starship",
        "btop",
        "pandoc",
        "chezmoi",
        "oven-sh/bun/bun",
        "ansible",
        "ansible-lint",
        "aria2",
        "autoconf",
        "automake",
        "cmake",
        "cowsay",
        "golang",
        "fish",
        "gzip",
        "httpie",
        "imagemagick",
        "shellcheck",
        "sqlite",
        "tree",
        "ripgrep",
        "git-delta",
        "jq",
        "colima",
        "podman",
    ]

    def linux_system_setup() -> None:
        # -------------------------
        # Repository Setup via APT
        # -------------------------
        # Add PPAs
        apt.ppa(name="Add Fish Shell PPA", src="ppa:fish-shell/release-3", _sudo=True)
        apt.ppa(name="Add apt-fast PPA", src="ppa:apt-fast/stable", _sudo=True)
        apt.ppa(name="Add Solaar PPA", src="ppa:solaar-unifying/ppa", _sudo=True)
        apt.ppa(
            name="Add Cryptomator PPA",
            src="ppa:sebastian-stenzel/cryptomator",
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

        apt.update(name="Update apt repositories", cache_time=3600, _sudo=True)
        apt.upgrade(name="Upgrade APT packages", auto_remove=True, _sudo=True)

        # -------------------------
        # System-level APT Packages
        # -------------------------
        system_apt_packages = [
            "ansible",
            "ansible-lint",
            "apt-fast",
            "apt-transport-https",
            "aria2",
            "autoconf",
            "automake",
            "build-essential",
            "dnsutils",
            "ca-certificates",
            "calibre",
            "celluloid",
            "clang-format",
            "cmake",
            "composer",
            "cowsay",
            "fastboot",
            "flameshot",
            "fonts-inter",
            "fonts-roboto",
            "gnome-boxes",
            "golang",
            "gzip",
            "httpie",
            "imagemagick",
            "inkscape",
            "insync",
            "iperf",
            "language-pack-es",
            "latexmk",
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
            "llvm",
            "lolcat",
            "magic-wormhole",
            "masscan",
            "mesa-common-dev",
            "meson",
            "micro",
            "mosh",
            "ncdu",
            "neofetch",
            "network-manager-openvpn",
            "nmap",
            "nvtop",
            "openvpn",
            "pipx",
            "ninja-build",
            "preload",
            "prettyping",
            "python3-colorama",
            "ruby",
            "shellcheck",
            "software-properties-common",
            "sqlite3",
            "snapd",
            "texinfo",
            "texlive-full",
            "tk-dev",
            "transmission",
            "tree",
            "ufw",
            "unrar",
            "whois",
            "xz-utils",
            "zlib1g-dev",
            "solaar",
            "gnome-sushi",
            "cryptomator",
            "timeshift",
            "python3-pip",
            "python3-gi",
            "flatpak",  # Always install flatpak
            "gnome-tweaks",
            "gnome-shell-extensions",
            "gnome-shell-extension-appindicator",
            "podman",
        ]
        
        # Add gaming packages if we have a display
        if has_display():
            gaming_packages = ["steam-installer", "lutris"]
            apt.packages(
                name="Install gaming packages",
                packages=gaming_packages,
                _sudo=True,
            )
            
        apt.packages(
            name="Install APT packages",
            packages=system_apt_packages,
            _sudo=True,
        )

        # Zoom (only if display is available)
        if has_display():
            apt.deb(
                name="Install Zoom",
                src="https://zoom.us/client/latest/zoom_amd64.deb",
                _sudo=True,
            )
        else:
            print("Skipping Zoom installation (no display available)")

        # -------------------------
        # Flatpak Remote and Apps
        # -------------------------
        flatpak_remotes = host.get_fact(FlatpakRemotes)
        
        # Check if flatpak is available
        if flatpak_remotes is None:
            # Try to install flatpak if not already installed
            server.shell(
                name="Ensure flatpak is installed",
                commands=[
                    "command -v flatpak || apt-get install -y flatpak",
                ],
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
            
        # Only try to install flatpak apps if flatpak is available and we have a display
        if flatpak_remotes is not None and has_display():
            flatpak_apps = [
                "com.axosoft.GitKraken",
                "com.stremio.Stremio",
                "org.zotero.Zotero",
                "md.obsidian.Obsidian",
                "org.jamovi.jamovi",
                "org.zulip.Zulip",
            ]
            flatpak.packages(
                name="Install Flatpak packages", packages=flatpak_apps, _sudo=True
            )
        else:
            if flatpak_remotes is None:
                print("Skipping Flatpak package installation (flatpak not available)")
            elif not has_display():
                print("Skipping Flatpak package installation (no display available)")

        # Snaps - first ensure snapd is installed
        server.shell(
            name="Ensure snapd is installed",
            commands=[
                "command -v snap || apt-get install -y snapd",
            ],
            _sudo=True,
        )
        
        # Only install GUI apps if display is available
        if has_display():
            snaps = [
                "discord",
                "spotify",
                "telegram-desktop",
                "signal-desktop",
                "slack",
            ]

            for snap_i in snaps:
                snap.package(name=f"Install {snap_i}", packages=snap_i, _sudo=True)
        else:
            print("Skipping Snap GUI applications (no display available)")

        # -------------------------
        # Development Tools via Brew (Linuxbrew)
        # -------------------------
        brew.tap(
            name="Tap linuxbrew/fonts",
            src="linuxbrew/fonts",
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )
        # Install in batches to prevent triggering open file limits
        for i, packages in enumerate(itertools.batched(base_brew_packages, 5)):
            brew.packages(
                name=f"Install Brew packages (Batch #{i})",
                packages=packages,
                _env={"PATH": f"{BREW_PATH}:$PATH"},
            )

    def macos_setup() -> None:
        # Tap Homebrew repositories
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
        # Install base Brew packages (dev tools)
        brew.packages(
            name="Install base Brew packages (dev tools)",
            packages=base_brew_packages,
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )
        # Install Brew casks (applications)
        brew.casks(
            name="Install Brew casks (apps)",
            casks=[
                "calibre",
                "celluloid",
                "firefox-developer-edition",
                "insync",
                "transmission",
                "vlc",
            ],
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )

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

    if is_linux():
        linux_system_setup()
    elif is_macos():
        macos_setup()


@deploy("Install Docker")
def install_docker() -> None:
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
        apt.update(name="Update apt for Docker", _sudo=True)
        apt.packages(
            name="Install Docker packages",
            packages=[
                "docker-ce",
                "docker-ce-cli",
                "containerd.io",
                "docker-buildx-plugin",
                "docker-compose-plugin",
            ],
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
    if not has_display():
        print("Skipping Firefox Developer Edition installation (no display available)")
        return
        
    if is_linux():
        apps_dir = HOME / ".local/share/applications"
        if not (
            host.get_fact(Directory, "/opt/firefox-dev")
            and host.get_fact(File, f"{apps_dir}/firefox-dev.desktop")
        ):
            directory(
                name="Create applications directory",
                path=str(apps_dir),
                mode="755",
                user=USER,
                group=USER,
            )

            installed_firefox = server.shell(
                name="Install Firefox Developer Edition",
                commands=[
                    "mkdir -p /opt/firefox-dev",
                    "wget -O /tmp/firefox-dev.tar.xz 'https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64'",
                    "tar -xJf /tmp/firefox-dev.tar.xz -C /opt/firefox-dev",
                    (
                        "echo '[Desktop Entry]\n"
                        "Version=1.0\n"
                        "Type=Application\n"
                        "Name=Firefox Developer Edition\n"
                        "GenericName=Web Browser\n"
                        "Icon=/opt/firefox-dev/firefox/browser/chrome/icons/default/default128.png\n"
                        "Exec=/opt/firefox-dev/firefox/firefox %u\n"
                        "Terminal=false\n"
                        "Categories=GNOME;GTK;Network;WebBrowser;' > "
                        f"{HOME}/.local/share/applications/firefox-dev.desktop"
                    ),
                ],
                _sudo=True,
            )
            if installed_firefox.changed:
                # Cleanup downloaded file
                server.shell(
                    name="Cleanup Firefox Dev download",
                    commands=["rm -f /tmp/firefox-dev.tar.xz"],
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
        print("In non-testing environments, would proceed to install cargo-update and cargo-edit")
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
    if is_linux():
        os_release = host.get_fact(OsRelease) or {}
        if "pop" in os_release.get("NAME", "").lower():
            # Install CUDA packages
            apt.packages(
                name="Install CUDA and cuDNN packages",
                packages=[
                    "nvidia-cuda-toolkit",
                    "nvidia-container-toolkit",
                    "nvidia-docker2",
                    "tensorman",
                ],
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


@deploy("Install 1password")
def install_1password() -> None:
    if is_linux():
        if not host.get_fact(File, "/usr/share/keyrings/1password-archive-keyring.gpg"):
            server.shell(
                name="Add 1Password GPG key",
                commands=[
                    "curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --dearmor > /usr/share/keyrings/1password-archive-keyring.gpg"
                ],
                _sudo=True,
            )
        # Add 1Password repository
        # deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main
        apt.repo(
            name="Add 1Password repository",
            src=(
                "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] "
                "https://downloads.1password.com/linux/debian/amd64 stable main"
            ),
            _sudo=True,
        )
        policies = host.get_fact(DebsigPolicies)
        if "AC2D62742012EA22" not in policies:
            directory(
                name="Create debsig policy directory",
                path="/etc/debsig/policies/AC2D62742012EA22/",
                mode="0755",
            )
            server.shell(
                name="Add 1Password debsig policy",
                commands=[
                    "curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol"
                ],
                _sudo=True,
            )

        keyrings_dir = directory(
            name="Create keyrings directory",
            path="/usr/share/debsig/keyrings/AC2D62742012EA22",
            mode="0755",
        )
        if keyrings_dir.changed:
            server.shell(
                name="Add 1Password debsig keyring",
                commands=[
                    "curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg"
                ],
                _sudo=True,
            )
        # Install 1password
        apt.packages(
            name="Install 1Password",
            packages=["1password", "1password-cli"],
            _sudo=True,
        )

    elif is_macos():
        brew.casks(
            name="Install 1Password",
            casks=["1password", "1password-cli"],
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )
