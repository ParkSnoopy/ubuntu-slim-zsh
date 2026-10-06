"""Fabric server discovery and installation."""

import shlex

from contract import Topic
from execution import run
from files import EXECUTABLE_MODE, save
from game_settings import game_settings
from network import download, fetch_json, stable_version

META = "https://meta.fabricmc.net/v2/versions"


def fabric_url(version):
    loaders = fetch_json(f"{META}/loader/{version}")
    loader = stable_version([entry["loader"] for entry in loaders], "Fabric loader")
    installer = stable_version(fetch_json(f"{META}/installer"), "Fabric installer")
    return f"{META}/loader/{version}/{loader}/{installer}/server/jar"


class MinecraftFabric(Topic):
    name = "minecraft-fabric"
    description = "Install Minecraft Fabric server"

    def packages(self):
        return ("jdk25",)

    def install(self):
        version, directory, ram = game_settings(
            stable_version(fetch_json(f"{META}/game"), "Minecraft"), "fabric"
        )
        url = fabric_url(version)
        run("sudo", "install", "-d", directory)
        download(url, directory / "fabric-server-launch.jar")
        launcher = f"#!/bin/env bash\nset -euo pipefail\ncd {shlex.quote(str(directory))}\nexec java -Xmx{ram} -jar fabric-server-launch.jar nogui\n"
        save(directory / "run.sh", launcher.encode(), EXECUTABLE_MODE)

    def preview(self):
        return (
            "prompt: Minecraft version, install directory",
            "download latest compatible stable Fabric server jar; write run.sh (-Xmx6G)",
        )


TOPIC = MinecraftFabric()
