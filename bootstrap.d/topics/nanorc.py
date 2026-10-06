"""Enable pinned Nano syntax definitions without duplicate includes."""

from pathlib import Path

from contract import Topic
from files import save


class Nanorc(Topic):
    name = "nanorc"
    description = "Install syntax highlighting for Nano"

    def packages(self):
        return ("nano", "nanorc")

    def install(self):
        path = Path.home() / ".nanorc"
        text = path.read_text() if path.exists() else ""
        include = f'include "{Path.home()}/.nix-profile/share/*.nanorc"'
        if include not in text.splitlines():
            previous = text.rstrip("\n")
            save(path, f"{previous}\n{include}\n".lstrip("\n").encode())

    def preview(self):
        return ("include pinned syntax files in ~/.nanorc if absent",)


TOPIC = Nanorc()
