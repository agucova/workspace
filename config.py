import platform
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


def is_macos() -> bool:
    return platform.system() == "Darwin"


def is_linux() -> bool:
    return platform.system() == "Linux"


settings = Settings()
