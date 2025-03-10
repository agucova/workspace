"""
Manage pipx (python) applications.
"""

from pyinfra import host
from pyinfra.api import operation
from pyinfra.facts.pipx import PipxEnvironment, PipxPackages
from pyinfra.facts.server import Path

from .util.packaging import ensure_packages


@operation()
def packages(
    packages=None,
    present=True,
    latest=False,
    extra_args=None,
):
    """
    Install/remove/update pipx packages.

    + packages: list of packages to ensure
    + present: whether the packages should be installed
    + latest: whether to upgrade packages without a specified version
    + extra_args: additional arguments to the pipx command

    Versions:
        Package versions can be pinned like pip: ``<pkg>==<version>``.

    **Example:**

    .. code:: python

        pipx.packages(
            name="Install ",
            packages=["pyinfra"],
        )
    """

    prep_install_command = ["pipx", "install"]

    if extra_args:
        prep_install_command.append(extra_args)
    install_command = " ".join(prep_install_command)

    uninstall_command = "pipx uninstall"
    upgrade_command = "pipx upgrade"

    current_packages = host.get_fact(PipxPackages)

    # pipx support only one package name at a time
    for package in packages:
        yield from ensure_packages(
            host,
            [package],
            current_packages,
            present,
            install_command=install_command,
            uninstall_command=uninstall_command,
            upgrade_command=upgrade_command,
            version_join="==",
            latest=latest,
        )


@operation()
def upgrade_all():
    """
    Upgrade all pipx packages.
    """
    yield "pipx upgrade-all"


@operation()
def ensure_path():
    """
    Ensure pipx bin dir is in the PATH.
    """

    # Fetch the current user's PATH
    path = host.get_fact(Path)
    # Fetch the pipx environment variables
    pipx_env = host.get_fact(PipxEnvironment)

    # If the pipx bin dir is already in the user's PATH, we're done
    if "PIPX_BIN_DIR" in pipx_env and pipx_env["PIPX_BIN_DIR"] in path.split(":"):
        host.noop("pipx bin dir is already in the PATH")
    else:
        yield "pipx ensurepath"
