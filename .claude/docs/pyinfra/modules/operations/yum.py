"""
Manage yum packages and repositories. Note that yum package names are case-sensitive.
"""

from __future__ import annotations

from pyinfra import host, state
from pyinfra.api import operation
from pyinfra.facts.rpm import RpmPackageProvides, RpmPackages

from .util.packaging import ensure_packages, ensure_rpm, ensure_yum_repo


@operation(is_idempotent=False)
def key(src: str):
    """
    Add yum gpg keys with ``rpm``.

    + src: filename or URL

    Note:
        always returns one command, not state checking

    **Example:**

    .. code:: python

        linux_id = host.get_fact(LinuxDistribution)["release_meta"].get("ID")
        yum.key(
            name="Add the Docker CentOS gpg key",
            src=f"https://download.docker.com/linux/{linux_id}/gpg",
        )

    """

    yield "rpm --import {0}".format(src)


@operation()
def repo(
    src: str,
    present=True,
    baseurl: str | None = None,
    description: str | None = None,
    enabled=True,
    gpgcheck=True,
    gpgkey: str | None = None,
):
    # NOTE: if updating this docstring also update `dnf.repo`
    """
    Add/remove/update yum repositories.

    + src: URL or name for the ``.repo``   file
    + present: whether the ``.repo`` file should be present
    + baseurl: the baseurl of the repo (if ``src`` is not a URL)
    + description: optional verbose description
    + enabled: whether this repo is enabled
    + gpgcheck: whether set ``gpgcheck=1``
    + gpgkey: the URL to the gpg key for this repo

    ``Baseurl``/``description``/``gpgcheck``/``gpgkey``:
        These are only valid when ``src`` is a filename (ie not a URL). This is
        for manual construction of repository files. Use a URL to download and
        install remote repository files.

    **Examples:**

    .. code:: python

        # Download a repository file
        yum.repo(
            name="Install Docker-CE repo via URL",
            src="https://download.docker.com/linux/centos/docker-ce.repo",
        )

        # Create the repository file from baseurl/etc
        yum.repo(
            name="Add the Docker CentOS repo",
            src="DockerCE",
            baseurl="https://download.docker.com/linux/centos/7/$basearch/stable",
        )
    """

    yield from ensure_yum_repo(
        host,
        src,
        baseurl,
        present,
        description,
        enabled,
        gpgcheck,
        gpgkey,
    )


@operation()
def rpm(src: str, present=True):
    # NOTE: if updating this docstring also update `dnf.rpm`
    """
    Add/remove ``.rpm`` file packages.

    + src: filename or URL of the ``.rpm`` package
    + present: whether ore not the package should exist on the system

    URL sources with ``present=False``:
        If the ``.rpm`` file isn't downloaded, pyinfra can't remove any existing
        package as the file won't exist until mid-deploy.

    **Example:**

    .. code:: python

        major_version = host.get_fact(LinuxDistribution)["major"]
        dnf.rpm(
           name="Install EPEL rpm to enable EPEL repo",
           src=f"https://dl.fedoraproject.org/pub/epel/epel-release-latest-{major_version}.noarch.rpm",
        )
    """

    yield from ensure_rpm(state, host, src, present, "yum")


@operation(is_idempotent=False)
def update():
    """
    Updates all yum packages.
    """

    yield "yum update -y"


_update = update._inner  # noqa: E305 (for use below where update is a kwarg)


@operation()
def packages(
    packages: str | list[str] | None = None,
    present=True,
    latest=False,
    update=False,
    clean=False,
    nobest=False,
    extra_install_args: str | None = None,
    extra_uninstall_args: str | None = None,
):
    """
    Install/remove/update yum packages & updates.

    + packages: list of packages to ensure
    + present: whether the packages should be installed
    + latest: whether to upgrade packages without a specified version
    + update: run ``yum update`` before installing packages
    + clean: run ``yum clean all`` before installing packages
    + nobest: add the no best option to install
    + extra_install_args: additional arguments to the yum install command
    + extra_uninstall_args: additional arguments to the yum uninstall command

    Versions:
        Package versions can be pinned as follows: ``<pkg>=<version>``

    **Examples:**

    .. code:: python

        # Update package list and install packages
        yum.packages(
            name="Install Vim and Vim enhanced",
            packages=["vim-enhanced", "vim"],
            update=True,
        )

        # Install the latest versions of packages (always check)
        yum.packages(
            name="Install latest Vim",
            packages=["vim"],
            latest=True,
        )
    """

    if clean:
        yield "yum clean all"

    if update:
        yield from _update()

    install_command = ["yum", "install", "-y"]

    if nobest:
        install_command.append("--nobest")

    if extra_install_args:
        install_command.append(extra_install_args)

    uninstall_command = ["yum", "remove", "-y"]

    if extra_uninstall_args:
        uninstall_command.append(extra_uninstall_args)

    yield from ensure_packages(
        host,
        packages,
        host.get_fact(RpmPackages),
        present,
        install_command=" ".join(install_command),
        uninstall_command=" ".join(uninstall_command),
        upgrade_command="yum update -y",
        version_join="=",
        latest=latest,
        expand_package_fact=lambda package: host.get_fact(
            RpmPackageProvides, package=package
        ),
    )
