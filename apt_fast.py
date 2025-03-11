"""
apt_fast.py - A module to use apt-fast for faster parallel downloads in PyInfra.

This module provides operations to use apt-fast as a drop-in replacement for apt in PyInfra,
enabling parallel downloads for significant speed improvements during package installation.

Overview:
---------
The apt-fast module is designed to:
1. Accelerate package installation with parallel downloads
2. Serve as a drop-in replacement for PyInfra's apt operations
3. Minimize changes required to existing code

Usage:
------
Import the module:
```python
import apt_fast
```

Basic operations:
```python
# Update repositories (with 8 parallel downloads)
apt_fast.update(
    name="Update apt repositories",
    parallel=8,
    _sudo=True,
)

# Install packages (with 16 parallel downloads)
apt_fast.packages(
    name="Install development tools",
    packages=["git", "build-essential", "python3-dev"],
    no_recommends=True,
    parallel=16,
    _sudo=True,
)

# Upgrade all packages
apt_fast.upgrade(
    name="Upgrade all packages",
    auto_remove=True,
    parallel=16,
    _sudo=True,
)
```

Replace apt with apt-fast in existing code:
```python
# Original:
from pyinfra.operations import apt
apt.packages(
    name="Install development tools",
    packages=["git", "build-essential"],
    _sudo=True,
)

# New code:
import apt_fast
apt_fast.packages(
    name="Install development tools",
    packages=["git", "build-essential"],
    parallel=16,  # New parameter
    _sudo=True,
)
```

Performance Recommendations:
---------------------------
- Set parallel=16 for most systems (adjust based on available bandwidth)
- Use no_recommends=True where possible to reduce download size
- Combine related package installations into larger batches
- Consider the cache_time parameter to avoid redundant updates

Requirements:
------------
- apt-fast must be installed on the target system
- The apt-fast PPA should be added (ppa:apt-fast/stable)
- PyInfra v3.x

Integration Notes:
-----------------
This module can be used directly after installing apt-fast. To ensure apt-fast is
available, first run an apt.packages operation to install it:

```python
apt.ppa(name="Add apt-fast PPA", src="ppa:apt-fast/stable", _sudo=True)
apt.packages(
    name="Ensure apt-fast is installed",
    packages=["apt-fast"],
    _sudo=True,
)
```

Then you can use apt_fast for all subsequent operations.
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
            f"-o Acquire::http::Dl-Limit={parallel}",  # Set number of parallel downloads
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

    This operation uses apt-fast instead of apt-get for repository updates,
    enabling multiple parallel downloads for better performance.

    Args:
        cache_time: Cache updates for this many seconds. When set, this operation
                   will not run if the update was performed within the specified time.
        parallel: Number of parallel downloads (default: 8). Higher values can
                 improve performance but may saturate your network connection.
                 Recommended values: 8-16 for most systems.

    Example:
        ```python
        apt_fast.update(
            name="Update apt repositories",
            cache_time=3600,  # Cache for 1 hour
            parallel=16,
            _sudo=True,
        )
        ```
    """
    # If cache_time check when apt was last updated
    if cache_time:
        cache_info = host.get_fact(File, path=APT_UPDATE_FILENAME)
        host_cache_time = host.get_fact(Date).replace(tzinfo=None) - timedelta(
            seconds=cache_time
        )

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

    This operation performs a system-wide package upgrade using apt-fast with
    parallel download support for significantly faster performance compared to
    regular apt-get upgrade.

    Args:
        auto_remove: Remove unneeded packages after upgrade. When True, this
                    performs the equivalent of apt-get --autoremove upgrade.
        parallel: Number of parallel downloads (default: 8). Higher values can
                 improve performance but may saturate your network connection.
                 Recommended values: 8-16 for most systems.

    Example:
        ```python
        apt_fast.upgrade(
            name="Upgrade all packages",
            auto_remove=True,  # Clean up unneeded dependencies
            parallel=16,
            _sudo=True,
        )
        ```
    """
    command = ["upgrade"]

    if auto_remove:
        command.append("--autoremove")

    yield from _simulate_then_perform(" ".join(command), parallel=parallel)


@operation()
def deb(src: str, present=True, force=False, parallel=8):
    """
    Add/remove .deb file packages using apt-fast for dependency installation.

    This operation is similar to PyInfra's apt.deb operation but enhances it by
    using apt-fast for dependency installation, which can significantly speed up
    the installation process when a .deb package has many dependencies.

    Args:
        src: Filename or URL of the .deb file. If a URL is provided, it will be
             downloaded automatically.
        present: Whether the package should exist on the system. When False, the
                package will be removed.
        force: Whether to force the package install by passing --force-yes to apt.
               This can help resolve some installation issues.
        parallel: Number of parallel downloads for dependency installation (default: 8).
                 Higher values can speed up dependency installation.

    Example:
        ```python
        apt_fast.deb(
            name="Install Zoom",
            src="https://zoom.us/client/latest/zoom_amd64.deb",
            parallel=16,
            _sudo=True,
        )
        ```

    Note:
        This operation uses the regular apt.deb operation to install the .deb file
        and then uses apt-fast to resolve and install dependencies, combining the
        benefits of both tools.
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

    This operation is a direct replacement for PyInfra's apt.packages operation but
    uses apt-fast for significantly faster downloads through parallelization. It maintains
    all the same functionality while adding parallel download support.

    Args:
        packages: List of packages to ensure.
        present: Whether the packages should be installed.
        latest: Whether to upgrade packages without a specified version.
        update: Run apt-fast update before installing packages.
        cache_time: When used with update, cache for this many seconds.
        upgrade: Run apt-fast upgrade before installing packages.
        force: Whether to force package installs by passing --force-yes to apt.
        no_recommends: Don't install recommended packages. Setting this to True can
                      significantly reduce download size and installation time.
        allow_downgrades: Allow downgrading packages with version (--allow-downgrades).
        extra_install_args: Additional arguments to the apt install command.
        extra_uninstall_args: Additional arguments to the apt uninstall command.
        parallel: Number of parallel downloads (default: 8). Higher values (16-32)
                 can significantly improve performance for large package installations.

    Versions:
        Package versions can be pinned like apt: ``<pkg>=<version>``

    Example:
        ```python
        apt_fast.packages(
            name="Install development tools",
            packages=["git", "build-essential", "python3-dev"],
            update=True,  # Update repositories first
            no_recommends=True,  # Skip recommended packages
            parallel=16,  # Use 16 parallel downloads
            _sudo=True,
        )
        ```

    Performance Tips:
        - Set parallel=16 or higher for large package installations
        - Use no_recommends=True to reduce download size
        - Consider combining multiple small package installations into a single larger one
        - Update and upgrade operations can also be parallelized if used
    """
    # Update if needed
    if update:
        if cache_time:
            cache_info = host.get_fact(File, path=APT_UPDATE_FILENAME)
            host_cache_time = host.get_fact(Date).replace(tzinfo=None) - timedelta(
                seconds=cache_time
            )

            if not (
                cache_info
                and cache_info["mtime"]
                and cache_info["mtime"] > host_cache_time
            ):
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
        install_command=noninteractive_apt_fast(
            install_command, force=force, parallel=parallel
        ),
        uninstall_command=noninteractive_apt_fast(
            uninstall_command, force=force, parallel=parallel
        ),
        upgrade_command=noninteractive_apt_fast(
            upgrade_command, force=force, parallel=parallel
        ),
        version_join="=",
        latest=latest,
    )
