"""Create Oh My Zsh settings only when no settings exist."""

import re
from pathlib import Path

from contract import Topic
from files import save


class OhMyZsh(Topic):
    name = "oh-my-zsh"
    description = "Install Oh My Zsh"

    def packages(self):
        return ("git", "zsh", "oh-my-zsh")

    def install(self):
        target = Path.home() / ".zshrc"
        if not target.exists():
            template = (
                Path.home()
                / ".nix-profile/share/oh-my-zsh/templates/zshrc.zsh-template"
            )
            text = re.sub(
                r"^export ZSH=.*$",
                'export ZSH="$HOME/.nix-profile/share/oh-my-zsh"',
                template.read_text(),
                flags=re.MULTILINE,
            )
            save(
                target,
                text.replace(
                    'ZSH_THEME="robbyrussell"', 'ZSH_THEME="daveverwer"'
                ).encode(),
            )

    def preview(self):
        return ("create ~/.zshrc from pinned template only if absent",)


TOPIC = OhMyZsh()
