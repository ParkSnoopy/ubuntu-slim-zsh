"""Explicit command and service doubles for installer integration checks."""

import json
import shutil
import subprocess
from pathlib import Path
from types import MappingProxyType, SimpleNamespace

VERSION = "version"
STABLE = "stable"
GAME_JSON = json.dumps(
    ({VERSION: "26.4-snapshot-1", STABLE: False}, {VERSION: "26.3", STABLE: True})
).encode()
LOADER_JSON = json.dumps(
    (
        {
            "loader": {VERSION: "0.20.0", STABLE: False},
            "intermediary": {VERSION: "wrong", STABLE: True},
        },
        {"loader": {VERSION: "0.19.5", STABLE: True}},
    )
).encode()
PAYLOADS = MappingProxyType(
    {
        "/game": GAME_JSON,
        "/loader/26.3": LOADER_JSON,
        "/loader/1.21.1": LOADER_JSON,
        "/installer": b'[{"stable":true,"version":"1.1.2"}]',
        "/maven-metadata.xml": b"<metadata><versioning><versions><version>21.1.1</version><version>26.3.0.1</version></versions></versioning></metadata>",
        "/server/jar": b"mock Fabric jar",
        "-installer.jar": b"mock NeoForge jar",
        "steamcmd_linux.tar.gz": b"mock Steam archive",
    }
)


def fetch_fixture(url, requests):
    requests.append(url)
    suffix = next((suffix for suffix in PAYLOADS if url.endswith(suffix)), None)
    if suffix is None:
        raise AssertionError(f"Unexpected fixture download: {url}")
    return PAYLOADS[suffix]


def populate_home(home):
    template = home / ".nix-profile/share/oh-my-zsh/templates"
    template.mkdir(parents=True)
    (template / "zshrc.zsh-template").write_text(
        'export ZSH="old"\nZSH_THEME="robbyrussell"\n'
    )
    library = home / "steamcmd/linux32"
    library.mkdir(parents=True)
    (library / "steamclient.so").touch()


def clone_fixture(directory):
    directory.mkdir()
    (directory / ".tmux.conf").write_text("tmux config\n")
    (directory / ".tmux.conf.local").write_text("tmux local\n")


def java_fixture(directory):
    (directory / "user_jvm_args.txt").write_text("# existing\n-Xmx1G\n")
    (directory / "run.sh").write_text("upstream launcher\n")
    (directory / "run.bat").touch()


def command_fixture(arguments, case, **options):
    command = tuple(str(argument) for argument in arguments)
    case.commands.append(command)
    if case.failure and case.failure(command):
        raise subprocess.CalledProcessError(1, command)
    if command == ("sudo", "unminimize"):
        case.assertEqual(options["stdin"].readline(), b"y\n")
        case.assertEqual(options["stdin"].readline(), b"y\n")
        return SimpleNamespace(returncode=0, args=command)
    if command[:3] == ("sudo", "install", "-d"):
        Path(command[-1]).mkdir(parents=True, exist_ok=True)
        return SimpleNamespace(returncode=0, args=command)
    if command[:2] == ("sudo", "install"):
        shutil.copyfile(command[-2], command[-1])
        return SimpleNamespace(returncode=0, args=command)
    if command[:2] == ("git", "clone"):
        clone_fixture(Path(command[-1]))
    if command[:2] == ("java", "-jar"):
        java_fixture(Path(options["cwd"]))
    return SimpleNamespace(returncode=0, args=command)
