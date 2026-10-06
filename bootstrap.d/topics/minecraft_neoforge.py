"""NeoForge server discovery and installation."""

import re
from xml.etree import ElementTree

from contract import Topic
from execution import run
from files import save
from game_settings import game_settings
from network import download, fetch

MAVEN = "https://maven.neoforged.net/releases/net/neoforged/neoforge"
RELEASE_YEAR = 26


def neoforge_versions():
    metadata = ElementTree.fromstring(fetch(f"{MAVEN}/maven-metadata.xml"))
    releases = [
        entry.text or "" for entry in metadata.findall("./versioning/versions/version")
    ]
    if not releases:
        raise ValueError("No NeoForge versions found.")
    return releases


def minecraft_version(release):
    major, minor, *_ = release.split(".")
    if int(major) >= RELEASE_YEAR:
        return f"{major}.{minor}"
    return f"1.{major}.{minor}"


def release_for(releases, version):
    prefix = "{}.".format(version.removeprefix("1."))
    release = next(
        (release for release in reversed(releases) if release.startswith(prefix)), None
    )
    if not release:
        raise ValueError(f"No NeoForge release found for Minecraft {version}.")
    return release


def server_details():
    releases = neoforge_versions()
    version, directory, ram = game_settings(minecraft_version(releases[-1]), "neoforge")
    return directory, ram, release_for(releases, version)


def configure_heap(directory, ram):
    arguments = directory / "user_jvm_args.txt"
    text = arguments.read_text()
    if re.search(r"^-Xmx", text, re.MULTILINE):
        text = re.sub(r"^-Xmx.*$", f"-Xmx{ram}", text, flags=re.MULTILINE)
    else:
        previous = text.rstrip("\n")
        text = f"{previous}\n-Xmx{ram}\n"
    save(arguments, text.encode())


class MinecraftNeoforge(Topic):
    name = "minecraft-neoforge"
    description = "Install Minecraft NeoForge server"

    def packages(self):
        return ("jdk25",)

    def install(self):
        directory, ram, release = server_details()
        run("sudo", "install", "-d", directory)
        download(
            f"{MAVEN}/{release}/neoforge-{release}-installer.jar",
            directory / "neoforge-installer.jar",
        )
        run("java", "-jar", "neoforge-installer.jar", "--installServer", cwd=directory)
        configure_heap(directory, ram)
        (directory / "run.bat").unlink(missing_ok=True)

    def preview(self):
        return (
            "prompt: Minecraft version, install directory",
            "install latest compatible NeoForge; set -Xmx6G; remove run.bat",
        )


TOPIC = MinecraftNeoforge()
