from pyinfra.api.deploy import deploy
from pyinfra.context import host
from pyinfra.facts.files import File
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

    # User directories
    for dirname, path in [
        ("repos", str(HOME / "repos")),
        ("bin", str(HOME / ".bin")),
        ("fonts", str(HOME / ".local" / "share" / "fonts")),
    ]:
        files.directory(
            name=f"Create {dirname} directory",
            path=path,
            mode="0770",
            user=USER,
            group=USER,
        )


@deploy("Setup Python Environment")
def setup_python_env() -> None:
    # Install Python and tools
    server.shell(
        name="Setup Python environment",
        commands=[
            "uv python install 3.13 --default --preview",
            "uv tool install ruff",
            "uv tool install pyright",
            "uv tool update-shell",
        ],
    )


@deploy("Setup Fish Shell")
def setup_fish() -> None:
    server.shell(
        name="Set fish as default shell",
        commands=[f"chsh -s /usr/bin/fish {USER}"],
        _sudo=True,
    )


@deploy("Install Julia and Packages")
def install_julia() -> None:
    julia_path = HOME / ".juliaup" / "bin" / "julia"

    if not host.get_fact(File, str(julia_path)):
        server.shell(
            name="Install Julia",
            commands=["curl -fsSL https://install.julialang.org | sh -s -- --yes"],
        )

    # Julia packages to install
    julia_packages = [
        "Plots",
        "DifferentialEquations",
        "Revise",
        "OhMyREPL",
        "Literate",
        "Pluto",
        "PyCall",
    ]
    for pkg in julia_packages:
        server.shell(
            name=f"Install Julia package {pkg}",
            commands=[f"{julia_path} -e 'using Pkg; Pkg.add(\"{pkg}\")'"],
        )
