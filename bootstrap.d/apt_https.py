"""Switch APT source URLs to HTTPS."""

from itertools import chain
from pathlib import Path

from contract import Topic
from execution import APT_INSTALL, run


def source_paths():
    directory = Path("/etc/apt/sources.list.d")
    return chain(
        (Path("/etc/apt/sources.list"),),
        directory.glob("*.list"),
        directory.glob("*.sources"),
    )


class AptHTTPS(Topic):
    name = "apt-https"
    description = "Switch APT repositories to HTTPS"
    needs_apt = True

    def packages(self):
        return ()

    def install(self):
        run(*APT_INSTALL, "ca-certificates", "apt-transport-https")
        for source in source_paths():
            if source.is_file():
                run("sudo", "sed", "-i", "s|http://|https://|g", source)
        run("sudo", "apt", "update")

    def preview(self):
        return (
            "sudo apt install -y ca-certificates apt-transport-https",
            "sudo sed -i 's|http://|https://|g' /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources",
            "sudo apt update",
        )


TOPIC = AptHTTPS()
