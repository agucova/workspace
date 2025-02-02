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

from pathlib import Path

from pyinfra.api.deploy import deploy
from pyinfra.context import host
from pyinfra.facts.server import LsbRelease
from pyinfra.operations import apt, brew, flatpak, server, snap
from pyinfra.operations.files import directory

from config import BREW_PATH, HOME, USER, is_linux, is_macos, settings


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
        "bun",
        "ansible",
        "ansible-lint",
        "aria2",
        "autoconf",
        "automake",
        "cmake",
        "cowsay",
        "fastboot",
        "golang",
        "fish",
        "gzip",
        "httpie",
        "imagemagick",
        "shellcheck",
        "sqlite",
        "tree",
        "unrar",
        "ripgrep",
        "git-delta",
        "jq",
        "colima",
        "podman",
        "1password-cli",
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
            "steam",
            "lutris",
            "python3-pip",
            "python3-gi",
            "gnome-tweaks",
            "gnome-shell-extensions",
            "gnome-shell-extension-appindicator",
            "podman",
        ]
        apt.packages(
            name="Install APT packages",
            packages=system_apt_packages,
            update=True,
            cache_time=3600,
            _sudo=True,
        )

        # Zoom
        apt.deb(
            name="Install Zoom",
            src="https://zoom.us/client/latest/zoom_amd64.deb",
            _sudo=True,
        )

        # -------------------------
        # Flatpak Remote and Apps
        # -------------------------
        server.shell(
            name="Add Flathub remote",
            commands=[
                "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
            ],
            _sudo=True,
        )
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

        # Snaps
        snaps = [
            "discord",
            "spotify",
            "telegram-desktop",
            "signal-desktop",
            "slack",
        ]

        snap.package(
            name="Install Snap packages",
            packages=snaps,
        )

        # -------------------------
        # Development Tools via Brew (Linuxbrew)
        # -------------------------
        brew.tap(
            name="Tap linuxbrew/fonts",
            src="linuxbrew/fonts",
            _env={"PATH": "/home/linuxbrew/.linuxbrew/bin:$PATH"},
            _sudo=True,
        )
        brew.packages(
            name="Install base Brew packages (dev tools)",
            packages=base_brew_packages,
            update=True,
            _env={"PATH": "/home/linuxbrew/.linuxbrew/bin:$PATH"},
            _sudo=True,
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
            update=True,
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
            upgrade=True,
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )

    if is_linux():
        linux_system_setup()
    elif is_macos():
        macos_setup()


@deploy("Install Docker")
def install_docker() -> None:
    if is_linux():
        server.shell(
            name="Add Docker GPG key",
            commands=[
                "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
            ],
            _sudo=True,
        )
        codename = host.get_fact(LsbRelease)["codename"]
        apt.repo(
            name="Add Docker repository",
            src=(
                "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] "
                f"https://download.docker.com/linux/ubuntu {codename} stable"
            ),
            _sudo=True,
        )
        apt.update(name="Update apt for Docker", cache_time=3600, _sudo=True)
        apt.packages(
            name="Install Docker packages",
            packages=[
                "docker-ce",
                "docker-ce-cli",
                "containerd.io",
                "docker-buildx-plugin",
                "docker-compose-plugin",
            ],
            update=True,
            cache_time=3600,
            _sudo=True,
        )
        server.shell(
            name="Add user to docker group",
            commands=[f"usermod -aG docker {USER}"],
            _sudo=True,
        )
    elif is_macos():
        brew.casks(
            name="Install Docker Desktop",
            casks=["docker"],
            upgrade=True,
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )


@deploy("Install Firefox Developer Edition")
def install_firefox_dev() -> None:
    if is_linux():
        server.shell(
            name="Install Firefox Developer Edition",
            commands=[
                "mkdir -p /opt/firefox-dev",
                "wget -O /tmp/firefox-dev.tar.bz2 'https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64'",
                "tar -xjf /tmp/firefox-dev.tar.bz2 -C /opt/firefox-dev",
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
        # Cleanup downloaded file
        server.shell(
            name="Cleanup Firefox Dev download",
            commands=["rm -f /tmp/firefox-dev.tar.bz2"],
            _sudo=True,
        )
    elif is_macos():
        brew.casks(
            name="Install Firefox Developer Edition",
            casks=["firefox-developer-edition"],
            upgrade=True,
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )


@deploy("Install Rust")
def install_rust() -> None:
    rustup_path = HOME / ".cargo" / "bin" / "rustup"
    if not rustup_path.exists():
        server.shell(
            name="Install Rust using rustup",
            commands=[
                "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
            ],
        )
        # Install common Rust tools
        server.shell(
            name="Install common Rust tools",
            commands=[
                ". $HOME/.cargo/env && cargo install cargo-update cargo-edit",
            ],
        )


@deploy("Install CUDA for PopOS")
def install_cuda() -> None:
    if is_linux():
        from pyinfra.facts.server import OsRelease

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
                update=True,
                cache_time=3600,
                _sudo=True,
            )

            # Configure system for CUDA
            server.shell(
                name="Configure CUDA system settings",
                commands=[
                    'kernelstub --add-options "systemd.unified_cgroup_hierarchy=0"',
                    "nvidia-ctk runtime configure --runtime=docker",
                ],
                _sudo=True,
            )


@deploy("Install Mathematica")
def install_mathematica() -> None:
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
    kinto_dir = HOME / "repos" / "kinto"

    # Clone the repository if it doesn't exist.
    if not kinto_dir.exists():
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
        # Get key from https://downloads.1password.com/linux/keys/1password.asc
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
        # Add debsig-verify policy
        debsig_dir = directory(
            name="Create debsig policy directory",
            path="/etc/debsig/policies/AC2D62742012EA22/",
            mode="0755",
        )
        if debsig_dir.changed:
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
            packages=["1password"],
            update=True,
            cache_time=3600,
            _sudo=True,
        )

    elif is_macos():
        brew.casks(
            name="Install 1Password",
            casks=["1password"],
            upgrade=True,
            _env={"PATH": f"{BREW_PATH}:$PATH"},
        )
