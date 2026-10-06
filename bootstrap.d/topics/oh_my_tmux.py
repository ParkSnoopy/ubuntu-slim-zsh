"""Install the pinned Oh My Tmux configuration."""

import shutil
from pathlib import Path

from contract import Topic
from execution import APT_INSTALL, run


class OhMyTmux(Topic):
    name = "oh-my-tmux"
    description = "Install Oh My Tmux configuration"
    needs_apt = True

    def packages(self):
        return ("git", "which", "tmux")

    def install(self):
        run(*APT_INSTALL, "zsh")
        run("chsh", "-s", "/usr/bin/zsh")
        home = Path.home()
        run(
            "git",
            "clone",
            "--no-checkout",
            "--single-branch",
            "https://github.com/gpakosz/.tmux.git",
            home / ".tmux",
        )
        run(
            "git",
            "-C",
            home / ".tmux",
            "checkout",
            "58a3dcc0d718ec0fa1c0d5a2fddd640a1ad7a5b7",
        )
        config = home / ".tmux.conf"
        config.unlink(missing_ok=True)
        config.symlink_to(".tmux/.tmux.conf")
        if not (home / ".tmux.conf.local").exists():
            shutil.copyfile(home / ".tmux/.tmux.conf.local", home / ".tmux.conf.local")

    def preview(self):
        return (
            "sudo apt install -y zsh",
            "chsh -s /usr/bin/zsh",
            "git clone --no-checkout --single-branch https://github.com/gpakosz/.tmux.git ~/.tmux",
            "git -C ~/.tmux checkout 58a3dcc0d718ec0fa1c0d5a2fddd640a1ad7a5b7",
            "link ~/.tmux.conf; preserve existing ~/.tmux.conf.local",
        )


TOPIC = OhMyTmux()
