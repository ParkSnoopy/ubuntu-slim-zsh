"""Add the Xtradeb application repository."""

from contract import Topic
from execution import APT_INSTALL, run


class Xtradeb(Topic):
    name = "xtradeb"
    description = "Add xtradeb/apps PPA repository"
    needs_apt = True

    def packages(self):
        return ()

    def install(self):
        run(*APT_INSTALL, "software-properties-common")
        run("sudo", "add-apt-repository", "-y", "ppa:xtradeb/apps")

    def preview(self):
        return (
            "sudo apt install -y software-properties-common",
            "sudo add-apt-repository -y ppa:xtradeb/apps",
        )


TOPIC = Xtradeb()
