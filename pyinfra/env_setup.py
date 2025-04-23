from pyinfra.api.deploy import deploy
from pyinfra.context import host
from pyinfra.operations import files, server

from config import HOME, USER


@deploy("Setup Base Directories")
def setup_directories() -> None:
    # Just create all directories - they'll be created in order
    files.directory(
        name="Create /var/cache/pyinfra",
        path="/var/cache/pyinfra",
        _sudo=True,
    )

    # Import here to avoid circular imports
    from config import settings

    # User directories
    for dirname, path in [
        ("repos", str(HOME / "repos")),
        ("bin", str(HOME / ".bin")),
        ("fonts", str(HOME / ".local" / "share" / "fonts")),
    ]:
        # In Docker testing environment, don't set owner/group
        # This avoids permission errors when mounting the host directory
        if settings.docker_testing:
            files.directory(
                name=f"Create {dirname} directory",
                path=path,
                _sudo=True,
            )
        else:
            files.directory(
                name=f"Create {dirname} directory",
                path=path,
                mode="0770",
                user=USER,
                group=USER,
            )


@deploy("Setup Python Environment")
def setup_python_env() -> None:
    # Let's first check if we need to install Python 3.13
    from facts import UvInstallation

    # Get information about current UV installation
    uv_info = host.get_fact(UvInstallation)

    # Check if Python 3.13 is already installed using a separate function
    python_check = server.shell(
        name="Check if Python 3.13 is already installed",
        commands=[
            "uv python list | grep -q '3.13' && echo 'installed' || echo 'not_installed'"
        ],
    )

    # Define a function to determine if Python 3.13 needs to be installed
    def needs_python_install():
        if python_check.did_change() and python_check.stdout:
            return "not_installed" in python_check.stdout
        return not uv_info.get("installed", False)

    # Import settings to check if we're in Docker
    from config import settings
    
    # In Docker, use the full environment setup 
    if settings.docker_testing:
        server.shell(
            name="Install Python and tools in Docker",
            commands=[
                "export PATH=$HOME/.local/bin:$PATH && " +
                "uv python install 3.13 --default --preview && " +
                "uv tool install ruff && " +
                "uv tool install pyright && " +
                "uv tool update-shell"
            ],
        )
    else:
        # Standard installation for non-Docker environment
        server.shell(
            name="Install Python 3.13",
            commands=["uv python install 3.13 --default --preview"],
            _if=needs_python_install,
        )

        # Install tools if not already installed
        for tool in ["ruff", "pyright"]:
            # Check if tool is already installed
            tool_name = tool  # Create a copy for closure

            # Define a function to check if this specific tool needs to be installed
            def needs_tool_install(t=tool_name):
                if uv_info.get("installed", False) and uv_info.get("tools", {}):
                    return t not in uv_info.get("tools", {})
                return True

            server.shell(
                name=f"Install {tool_name}",
                commands=[f"uv tool install {tool_name}"],
                _if=needs_tool_install,
            )

        # Update shell configuration
        server.shell(
            name="Update shell integration",
            commands=["uv tool update-shell"],
            _sudo=False,  # Make sure we don't use sudo for this
        )


@deploy("Setup Fish Shell")
def setup_fish() -> None:
    server.shell(
        name="Set fish as default shell",
        commands=[f"chsh -s /usr/bin/fish {USER}"],
        _sudo=True,
    )


# Julia installation moved to packages.py
