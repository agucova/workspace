"""
Manage apt packages and repositories.
"""

from __future__ import annotations

from datetime import timedelta
from urllib.parse import urlparse

from pyinfra import host
from pyinfra.api import OperationError, operation
from pyinfra.facts.apt import (
    AptKeys,
    AptSources,
    SimulateOperationWillChange,
    noninteractive_apt,
    parse_apt_repo,
)
from pyinfra.facts.deb import DebPackage, DebPackages
from pyinfra.facts.files import File
from pyinfra.facts.gpg import GpgKey
from pyinfra.facts.server import Date

from . import files
from .util.packaging import ensure_packages

APT_UPDATE_FILENAME = "/var/lib/apt/periodic/update-success-stamp"


def _simulate_then_perform(command: str):
    changes = host.get_fact(SimulateOperationWillChange, command)

    if not changes:
        # Simulating apt-get command failed, so the actual
        # operation will probably fail too:
        yield noninteractive_apt(command)
    elif (
        changes["upgraded"] == 0
        and changes["newly_installed"] == 0
        and changes["removed"] == 0
        and changes["not_upgraded"] == 0
    ):
        host.noop(f"{command} skipped, no changes would be performed")
    else:
        yield noninteractive_apt(command)


@operation()
def key(
    src: str | None = None,
    keyserver: str | None = None,
    keyid: str | list[str] | None = None,
):
    """
    Add apt gpg keys with ``apt-key``.

    + src: filename or URL
    + keyserver: URL of keyserver to fetch key from
    + keyid: key ID or list of key IDs when using keyserver

    keyserver/id:
        These must be provided together.

    .. warning::
        ``apt-key`` is deprecated in Debian, it is recommended NOT to use this
        operation and instead follow the instructions here:

        https://wiki.debian.org/DebianRepository/UseThirdParty

    **Examples:**

    .. code:: python

        # Note: If using URL, wget is assumed to be installed.
        apt.key(
            name="Add the Docker apt gpg key",
            src="https://download.docker.com/linux/ubuntu/gpg",
        )

        apt.key(
            name="Install VirtualBox key",
            src="https://www.virtualbox.org/download/oracle_vbox_2016.asc",
        )
    """

    existing_keys = host.get_fact(AptKeys)

    if src:
        key_data = host.get_fact(GpgKey, src=src)
        if key_data:
            keyid = list(key_data.keys())

        if not keyid or not all(kid in existing_keys for kid in keyid):
            # If URL, wget the key to stdout and pipe into apt-key, because the "adv"
            # apt-key passes to gpg which doesn't always support https!
            if urlparse(src).scheme:
                yield "(wget -O - {0} || curl -sSLf {0}) | apt-key add -".format(src)
            else:
                yield "apt-key add {0}".format(src)
        else:
            host.noop(
                "All keys from {0} are already available in the apt keychain".format(
                    src
                )
            )

    if keyserver:
        if not keyid:
            raise OperationError("`keyid` must be provided with `keyserver`")

        if isinstance(keyid, str):
            keyid = [keyid]

        needed_keys = sorted(set(keyid) - set(existing_keys.keys()))
        if needed_keys:
            yield "apt-key adv --keyserver {0} --recv-keys {1}".format(
                keyserver,
                " ".join(needed_keys),
            )
        else:
            host.noop(
                "Keys {0} are already available in the apt keychain".format(
                    ", ".join(keyid),
                ),
            )


@operation()
def repo(src: str, present=True, filename: str | None = None):
    """
    Add/remove apt repositories.

    + src: apt source string eg ``deb http://X hardy main``
    + present: whether the repo should exist on the system
    + filename: optional filename to use ``/etc/apt/sources.list.d/<filename>.list``. By
      default uses ``/etc/apt/sources.list``.

    **Example:**

    .. code:: python

        apt.repo(
            name="Install VirtualBox repo",
            src="deb https://download.virtualbox.org/virtualbox/debian bionic contrib",
        )
    """

    # Get the target .list file to manage
    if filename:
        filename = "/etc/apt/sources.list.d/{0}.list".format(filename)
    else:
        filename = "/etc/apt/sources.list"

    # Work out if the repo exists already
    apt_sources = host.get_fact(AptSources)

    is_present = False
    repo = parse_apt_repo(src)
    if repo and repo in apt_sources:
        is_present = True

    # Doesn't exist and we want it
    if not is_present and present:
        yield from files.line._inner(
            path=filename,
            line=src,
            escape_regex_characters=True,
        )

    # Exists and we don't want it
    elif is_present and not present:
        yield from files.line._inner(
            path=filename,
            line=src,
            present=False,
            escape_regex_characters=True,
        )
    else:
        host.noop(
            'apt repo "{0}" {1}'.format(
                src,
                "exists" if present else "does not exist",
            ),
        )


@operation(is_idempotent=False)
def ppa(src: str, present=True):
    """
    Add/remove Ubuntu ppa repositories.

    + src: the PPA name (full ppa:user/repo format)
    + present: whether it should exist

    Note:
        requires ``apt-add-repository`` on the remote host

    **Example:**

    .. code:: python

        # Note: Assumes software-properties-common is installed.
        apt.ppa(
            name="Add the Bitcoin ppa",
            src="ppa:bitcoin/bitcoin",
        )

    """

    if present:
        yield 'apt-add-repository -y "{0}"'.format(src)

    if not present:
        yield 'apt-add-repository -y --remove "{0}"'.format(src)


@operation()
def deb(src: str, present=True, force=False):
    """
    Add/remove ``.deb`` file packages.

    + src: filename or URL of the ``.deb`` file
    + present: whether or not the package should exist on the system
    + force: whether to force the package install by passing `--force-yes` to apt

    Note:
        When installing, ``apt-get install -f`` will be run to install any unmet
        dependencies.

    URL sources with ``present=False``:
        If the ``.deb`` file isn't downloaded, pyinfra can't remove any existing
        package as the file won't exist until mid-deploy.

    **Example:**

    .. code:: python

        # Note: Assumes wget is installed.
        apt.deb(
            name="Install Chrome via deb",
            src="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb",
        )
    """

    original_src = src

    # If source is a url
    if urlparse(src).scheme:
        # Generate a temp filename
        temp_filename = host.get_temp_filename(src)

        # Ensure it's downloaded
        yield from files.download._inner(src=src, dest=temp_filename)

        # Override the source with the downloaded file
        src = temp_filename

    # Check for file .deb information (if file is present)
    info = host.get_fact(DebPackage, package=src)
    current_packages = host.get_fact(DebPackages)

    exists = False

    # We have deb info! Check against installed packages
    if info and info.get("version") in current_packages.get(info.get("name"), {}):
        exists = True

    # Package does not exist and we want?
    if present:
        if not exists:
            # Install .deb file - ignoring failure (on unmet dependencies)
            yield "dpkg --force-confdef --force-confold -i {0} 2> /dev/null || true".format(
                src
            )
            # Attempt to install any missing dependencies
            yield "{0} -f".format(noninteractive_apt("install", force=force))
            # Now reinstall, and critically configure, the package - if there are still
            # missing deps, now we error
            yield "dpkg --force-confdef --force-confold -i {0}".format(src)
        else:
            host.noop("deb {0} is installed".format(original_src))

    # Package exists but we don't want?
    if not present:
        if exists:
            yield "{0} {1}".format(
                noninteractive_apt("remove", force=force),
                info["name"],
            )
        else:
            host.noop("deb {0} is not installed".format(original_src))


@operation(
    is_idempotent=False,
    idempotent_notice=(
        "This operation will always execute commands "
        "unless the ``cache_time`` argument is provided."
    ),
)
def update(cache_time: int | None = None):
    """
    Updates apt repositories.

    + cache_time: cache updates for this many seconds

    **Example:**

    .. code:: python

        apt.update(
            name="Update apt repositories",
            cache_time=3600,
        )
    """

    # If cache_time check when apt was last updated, prevent updates if within time
    if cache_time:
        # Ubuntu provides this handy file
        cache_info = host.get_fact(File, path=APT_UPDATE_FILENAME)

        # Time on files is not tz-aware, and will be the same tz as the server's time,
        # so we can safely remove the tzinfo from the Date fact before comparison.
        host_cache_time = host.get_fact(Date).replace(tzinfo=None) - timedelta(
            seconds=cache_time
        )
        if cache_info and cache_info["mtime"] and cache_info["mtime"] > host_cache_time:
            host.noop("apt is already up to date")
            return

    yield "apt-get update"

    # Some apt systems (Debian) have the /var/lib/apt/periodic directory, but
    # don't bother touching anything in there - so pyinfra does it, enabling
    # cache_time to work.
    if cache_time:
        yield "touch {0}".format(APT_UPDATE_FILENAME)


_update = update  # noqa: E305


@operation()
def upgrade(auto_remove: bool = False):
    """
    Upgrades all apt packages.

    + auto_remove: removes transitive dependencies that are no longer needed.

    **Example:**

    .. code:: python

        # Upgrade all packages
        apt.upgrade(
            name="Upgrade apt packages",
        )

        # Upgrade all packages and remove unneeded transitive dependencies
        apt.upgrade(
            name="Upgrade apt packages and remove unneeded dependencies",
            auto_remove=True
        )
    """

    command = ["upgrade"]

    if auto_remove:
        command.append("--autoremove")

    yield from _simulate_then_perform(" ".join(command))


_upgrade = upgrade  # noqa: E305 (for use below where update is a kwarg)


@operation()
def dist_upgrade(auto_remove: bool = False):
    """
    Updates all apt packages, employing dist-upgrade.

    + auto_remove: removes transitive dependencies that are no longer needed.

    **Example:**

    .. code:: python

        apt.dist_upgrade(
            name="Upgrade apt packages using dist-upgrade",
        )
    """

    command = ["dist-upgrade"]

    if auto_remove:
        command.append("--autoremove")

    yield from _simulate_then_perform(" ".join(command))


@operation()
def packages(
    packages: str | list[str] | None = None,
    present=True,
    latest=False,
    update=False,
    cache_time: int | None = None,
    upgrade=False,
    force=False,
    no_recommends=False,
    allow_downgrades=False,
    extra_install_args: str | None = None,
    extra_uninstall_args: str | None = None,
):
    """
    Install/remove/update packages & update apt.

    + packages: list of packages to ensure
    + present: whether the packages should be installed
    + latest: whether to upgrade packages without a specified version
    + update: run ``apt update`` before installing packages
    + cache_time: when used with ``update``, cache for this many seconds
    + upgrade: run ``apt upgrade`` before installing packages
    + force: whether to force package installs by passing `--force-yes` to apt
    + no_recommends: don't install recommended packages
    + allow_downgrades: allow downgrading packages with version (--allow-downgrades)
    + extra_install_args: additional arguments to the apt install command
    + extra_uninstall_args: additional arguments to the apt uninstall command

    Versions:
        Package versions can be pinned like apt: ``<pkg>=<version>``

    Cache time:
        When ``cache_time`` is set the ``/var/lib/apt/periodic/update-success-stamp`` file
        is touched upon successful update. Some distros already do this (Ubuntu), but others
        simply leave the periodic directory empty (Debian).

    **Examples:**

    .. code:: python

        # Update package list and install packages
        apt.packages(
            name="Install Asterisk and Vim",
            packages=["asterisk", "vim"],
            update=True,
        )

        # Install the latest versions of packages (always check)
        apt.packages(
            name="Install latest Vim",
            packages=["vim"],
            latest=True,
        )

        # Note: host.get_fact(OsVersion) is the same as `uname -r` (ex: '4.15.0-72-generic')
        apt.packages(
            name="Install kernel headers",
            packages=[f"linux-headers-{host.get_fact(OsVersion)}"],
            update=True,
        )
    """

    if update:
        yield from _update._inner(cache_time=cache_time)

    if upgrade:
        yield from _upgrade._inner()

    install_command_args = ["install"]
    if no_recommends is True:
        install_command_args.append("--no-install-recommends")
    if allow_downgrades:
        install_command_args.append("--allow-downgrades")

    upgrade_command = " ".join(install_command_args)

    if extra_install_args:
        install_command_args.append(extra_install_args)

    install_command = " ".join(install_command_args)

    uninstall_command_args = ["remove"]
    if extra_uninstall_args:
        uninstall_command_args.append(extra_uninstall_args)

    uninstall_command = " ".join(uninstall_command_args)

    # Compare/ensure packages are present/not
    yield from ensure_packages(
        host,
        packages,
        host.get_fact(DebPackages),
        present,
        install_command=noninteractive_apt(install_command, force=force),
        uninstall_command=noninteractive_apt(uninstall_command, force=force),
        upgrade_command=noninteractive_apt(upgrade_command, force=force),
        version_join="=",
        latest=latest,
    )
