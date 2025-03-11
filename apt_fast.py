"""
apt_fast.py - A module to use apt-fast for faster parallel downloads in PyInfra.
"""

from datetime import timedelta

from pyinfra.context import host
from pyinfra.api.operation import operation
from pyinfra.facts.apt import SimulateOperationWillChange
from pyinfra.facts.deb import DebPackages
from pyinfra.facts.files import File
from pyinfra.facts.server import Date
from pyinfra.operations.util.packaging import ensure_packages

# Constant for the apt update timestamp file
APT_UPDATE_FILENAME = "/var/lib/apt/periodic/update-success-stamp"


def noninteractive_apt_fast(command: str, force=False, parallel=8):
    """
    Generate a noninteractive apt-fast command string with parallel download support.
    
    Args:
        command: The apt-fast command to run (e.g., 'install <packages>')
        force: Whether to add --force-yes to the command
        parallel: Number of parallel downloads (default: 8)
    """
    args = ["DEBIAN_FRONTEND=noninteractive apt-fast -y"]

    if force:
        args.append("--force-yes")

    args.extend(
        (
            '-o Dpkg::Options::="--force-confdef"',
            '-o Dpkg::Options::="--force-confold"',
            f'-o Acquire::http::Dl-Limit={parallel}',  # Set number of parallel downloads
            command,
        ),
    )

    return " ".join(args)


def _simulate_then_perform(command: str, force=False, parallel=8):
    """
    Simulate an apt-fast command and only execute it if it would make changes.
    
    Args:
        command: The apt-fast command to simulate and possibly run
        force: Whether to add --force-yes to the command
        parallel: Number of parallel downloads
    """
    changes = host.get_fact(SimulateOperationWillChange, command)

    if not changes:
        # Simulation failed, so the actual operation will probably fail too
        yield noninteractive_apt_fast(command, force=force, parallel=parallel)
    elif (
        changes["upgraded"] == 0
        and changes["newly_installed"] == 0
        and changes["removed"] == 0
        and changes["not_upgraded"] == 0
    ):
        host.noop(f"{command} skipped, no changes would be performed")
    else:
        yield noninteractive_apt_fast(command, force=force, parallel=parallel)


@operation()
def update(cache_time=None, parallel=8):
    """
    Update apt repositories using apt-fast for faster downloads.
    
    Args:
        cache_time: Cache updates for this many seconds
        parallel: Number of parallel downloads (default: 8)
    """
    # If cache_time check when apt was last updated
    if cache_time:
        cache_info = host.get_fact(File, path=APT_UPDATE_FILENAME)
        host_cache_time = host.get_fact(Date).replace(tzinfo=None) - timedelta(seconds=cache_time)
        
        if cache_info and cache_info["mtime"] and cache_info["mtime"] > host_cache_time:
            host.noop("apt is already up to date")
            return

    yield noninteractive_apt_fast("update", parallel=parallel)
    
    # Touch the update timestamp file to enable cache_time functionality
    if cache_time:
        yield f"touch {APT_UPDATE_FILENAME}"


@operation()
def upgrade(auto_remove=False, parallel=8):
    """
    Upgrade all packages using apt-fast for faster downloads.
    
    Args:
        auto_remove: Remove unneeded packages after upgrade
        parallel: Number of parallel downloads (default: 8)
    """
    command = ["upgrade"]
    
    if auto_remove:
        command.append("--autoremove")
        
    yield from _simulate_then_perform(" ".join(command), parallel=parallel)


@operation()
def deb(src: str, present=True, force=False, parallel=8):
    """
    Add/remove .deb file packages using apt-fast for dependency installation.
    
    Args:
        src: filename or URL of the .deb file
        present: whether the package should exist on the system
        force: whether to force the package install by passing --force-yes to apt
        parallel: Number of parallel downloads for dependency installation
    """
    # First use the regular apt.deb operation to install the package
    from pyinfra.operations import apt
    yield from apt.deb._inner(src=src, present=present, force=force)
    
    # If we're installing the package, use apt-fast to install any dependencies
    if present:
        yield noninteractive_apt_fast("install -f", force=force, parallel=parallel)


@operation()
def packages(
    packages=None,
    present=True,
    latest=False,
    update=False,
    cache_time=None,
    upgrade=False,
    force=False,
    no_recommends=False,
    allow_downgrades=False,
    extra_install_args=None,
    extra_uninstall_args=None,
    parallel=8,
):
    """
    Install/remove/update packages using apt-fast for parallel downloads.
    
    Args:
        packages: List of packages to ensure
        present: Whether the packages should be installed
        latest: Whether to upgrade packages without a specified version
        update: Run apt-fast update before installing packages
        cache_time: When used with update, cache for this many seconds
        upgrade: Run apt-fast upgrade before installing packages
        force: Whether to force package installs by passing --force-yes to apt
        no_recommends: Don't install recommended packages
        allow_downgrades: Allow downgrading packages with version (--allow-downgrades)
        extra_install_args: Additional arguments to the apt install command
        extra_uninstall_args: Additional arguments to the apt uninstall command
        parallel: Number of parallel downloads (default: 8)
    """
    # Update if needed
    if update:
        if cache_time:
            cache_info = host.get_fact(File, path=APT_UPDATE_FILENAME)
            host_cache_time = host.get_fact(Date).replace(tzinfo=None) - timedelta(seconds=cache_time)
            
            if not (cache_info and cache_info["mtime"] and cache_info["mtime"] > host_cache_time):
                yield noninteractive_apt_fast("update", parallel=parallel)
                yield f"touch {APT_UPDATE_FILENAME}"
        else:
            yield noninteractive_apt_fast("update", parallel=parallel)

    # Upgrade if needed
    if upgrade:
        command = ["upgrade"]
        yield from _simulate_then_perform(" ".join(command), parallel=parallel)

    # Build the install command
    install_command_args = ["install"]
    if no_recommends:
        install_command_args.append("--no-install-recommends")
    if allow_downgrades:
        install_command_args.append("--allow-downgrades")

    upgrade_command = " ".join(install_command_args)

    if extra_install_args:
        install_command_args.append(extra_install_args)

    install_command = " ".join(install_command_args)

    # Build the uninstall command
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
        install_command=noninteractive_apt_fast(install_command, force=force, parallel=parallel),
        uninstall_command=noninteractive_apt_fast(uninstall_command, force=force, parallel=parallel),
        upgrade_command=noninteractive_apt_fast(upgrade_command, force=force, parallel=parallel),
        version_join="=",
        latest=latest,
    )