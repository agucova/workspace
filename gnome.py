from pyinfra.api.deploy import deploy
from pyinfra.operations import files, server

from config import FILES_DIR, HOME, USER, has_display, is_linux


@deploy("Configure GNOME Wallpaper")
def configure_wallpaper() -> None:
    if not has_display():
        print("Skipping GNOME wallpaper configuration (no display available)")
        return

    wallpaper_src = FILES_DIR / "wallpaper.jpg"
    wallpaper_dest = HOME / ".wallpaper.jpg"

    if wallpaper_src.exists():
        # Copy wallpaper file
        files.put(
            name="Copy wallpaper",
            src=str(wallpaper_src),
            dest=str(wallpaper_dest),
            user=USER,
            group=USER,
            mode="0600",
        )

        # Set wallpaper for both light and dark themes
        server.shell(
            name="Set GNOME wallpapers",
            commands=[
                f"sudo -u {USER} dconf write /org/gnome/desktop/background/picture-uri \"'file://{wallpaper_dest}'\"",
                f"sudo -u {USER} dconf write /org/gnome/desktop/background/picture-uri-dark \"'file://{wallpaper_dest}'\"",
            ],
            _sudo=True,
        )


@deploy("Configure GNOME Keyboard")
def configure_keyboard() -> None:
    if not is_linux() or not has_display():
        print(
            "Skipping GNOME keyboard configuration (not on Linux or no display available)"
        )
        return

    server.shell(
        name="Set GNOME keyboard layout",
        commands=[
            f"sudo -u {USER} dconf write /org/gnome/desktop/input-sources/sources \"[('xkb', 'us+altgr-intl')]\""
        ],
        _sudo=True,
    )
    server.shell(
        name="Disable GNOME overlay key",
        commands=[f"sudo -u {USER} dconf write /org/gnome/mutter/overlay-key \"''\""],
        _sudo=True,
    )
