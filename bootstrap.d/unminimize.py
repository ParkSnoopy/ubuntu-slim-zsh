"""Restore the Ubuntu documentation and minimal-system exclusions."""

import subprocess
from contextlib import ExitStack
from pathlib import Path

from contract import Topic
from execution import APT_INSTALL, run


class Unminimize(Topic):
    name = "unminimize"
    description = "Revert Ubuntu minimal to full system with man pages"
    needs_apt = True

    def packages(self):
        return ()

    def install(self):
        with (
            subprocess.Popen(["yes"], stdout=subprocess.PIPE) as producer,
            ExitStack() as cleanup,
        ):
            assert producer.stdout is not None
            cleanup.callback(producer.terminate)
            cleanup.callback(producer.stdout.close)
            completed = subprocess.run(
                ["sudo", "unminimize"], stdin=producer.stdout, check=False
            )
            if completed.returncode and Path("/etc/dpkg/dpkg.cfg.d/excludes").exists():
                raise subprocess.CalledProcessError(
                    completed.returncode, completed.args
                )
        run(*APT_INSTALL, "man-db")

    def preview(self):
        return ("yes | sudo unminimize", "sudo apt install -y man-db")


TOPIC = Unminimize()
