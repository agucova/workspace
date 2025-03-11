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

    While we could use host.get_fact(Kernel) == "Darwin", this helper function:
    1. Works before PyInfra is initialized
    2. Is faster than querying the remote system
    3. Provides a consistent interface with other helper functions
    """
    return platform.system() == "Darwin"


def is_linux() -> bool:
    """
    Check if the current system is Linux.

    While we could use host.get_fact(Kernel) == "Linux", this helper function:
    1. Works before PyInfra is initialized
    2. Is faster than querying the remote system
    3. Provides a consistent interface with other helper functions
    """
    return platform.system() == "Linux"


def has_display() -> bool:
    """
    Check if there's a graphical display available.

    While we could use host.get_fact(HasGui) on Linux, this helper function:
    1. Works consistently across Linux and macOS
    2. Handles the Docker testing environment
    3. Uses a more reliable detection method
    """
    if settings.docker_testing:
        return False

    # Check for DISPLAY environment variable on Linux
    if is_linux() and not os.environ.get("DISPLAY"):
        return False

    # Check if we're in a Desktop environment
    if is_linux():
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
