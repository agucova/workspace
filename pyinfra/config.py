import os
import platform
import subprocess
from pathlib import Path

from pydantic_settings import BaseSettings

USER: str = "agucova"
HOME: Path = (
    Path(f"/home/{USER}") if platform.system() != "Darwin" else Path(f"/Users/{USER}")
)
BREW_PATH: Path = (
    Path("/home/linuxbrew/.linuxbrew/bin")
    if platform.system() != "Darwin"
    else Path("/opt/homebrew/bin")  # Since Apple Silicon
)
FILES_DIR: Path = Path(__file__).parent / "files"


class Settings(BaseSettings):
    mathematica_license_key: str | None = None
    docker_testing: bool = os.environ.get("DOCKER_TESTING", "0") == "1"


def is_macos() -> bool:
    """
    Check if the current system is macOS.

    Uses PyInfra's Kernel fact to determine the OS when possible,
    with fallback to platform.system() when called outside a deploy context.
    """
    try:
        from pyinfra.context import ctx_host
        from pyinfra.facts.server import Kernel

        # Check if we're in a deploy context
        host = ctx_host.get()
        if host is not None:
            return host.get_fact(Kernel) == "Darwin"
    except (ImportError, AttributeError):
        pass

    # Fallback to platform.system() if PyInfra isn't available or initialized
    return platform.system() == "Darwin"


def is_linux() -> bool:
    """
    Check if the current system is Linux.

    Uses PyInfra's Kernel fact to determine the OS when possible,
    with fallback to platform.system() when called outside a deploy context.
    """
    try:
        from pyinfra.context import ctx_host
        from pyinfra.facts.server import Kernel

        # Check if we're in a deploy context
        host = ctx_host.get()
        if host is not None:
            return host.get_fact(Kernel) == "Linux"
    except (ImportError, AttributeError):
        pass

    # Fallback to platform.system() if PyInfra isn't available or initialized
    return platform.system() == "Linux"


def has_display() -> bool:
    """
    Check if there's a graphical display available.

    Uses PyInfra's HasGui fact on Linux when possible, with fallback to
    a combination of environment checks and shell commands.
    Handles macOS and Docker testing environments properly.
    """
    # Always return False in Docker testing
    if settings.docker_testing:
        return False

    if is_linux():
        # Try to use PyInfra's HasGui fact
        try:
            from pyinfra.context import ctx_host
            from pyinfra.facts.server import HasGui

            # Check if we're in a deploy context
            host = ctx_host.get()
            if host is not None:
                return host.get_fact(HasGui)
        except (ImportError, AttributeError):
            pass

        # Fallback to our custom checks if PyInfra isn't available

        # Check for DISPLAY environment variable
        if not os.environ.get("DISPLAY"):
            return False

        # Check if we're in a Desktop environment
        try:
            result = subprocess.run(
                [
                    "dbus-send",
                    "--session",
                    "--dest=org.gnome.Shell",
                    "--type=method_call",
                    "--print-reply",
                    "/org/gnome/Shell",
                    "org.freedesktop.DBus.Peer.Ping",
                ],
                capture_output=True,
                timeout=1,
            )
            return result.returncode == 0
        except (subprocess.SubprocessError, FileNotFoundError):
            pass

    # For macOS, assume we have a display if we're not testing
    return is_macos()


settings = Settings()
