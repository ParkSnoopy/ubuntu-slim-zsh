"""Shared Minecraft prompt and input validation."""

import os
import re
from pathlib import Path

from console import prompt


def game_settings(latest, loader):
    ram = os.environ.get("MINECRAFT_MAX_RAM", "6G")
    if not re.fullmatch(r"[1-9][0-9]*[KMGTkmgt]", ram):
        raise ValueError("MINECRAFT_MAX_RAM must be a positive size such as 6G.")
    version = prompt("Minecraft version", latest)
    if not re.fullmatch(r"[A-Za-z0-9._-]+", version):
        raise ValueError("Minecraft version contains invalid characters.")
    default = os.environ.get("MINECRAFT_INSTALL_DIR", f"/apps/minecraft-{loader}")
    directory = Path(prompt("Install directory", default)).expanduser().resolve()
    return version, directory, ram
