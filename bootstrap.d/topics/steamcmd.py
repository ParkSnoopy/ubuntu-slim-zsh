"""Install SteamCMD and keep its runtime under an unprivileged account."""

import grp
import os
import pwd
import shlex
from contextlib import ExitStack
from pathlib import Path
from tempfile import TemporaryDirectory

from contract import Topic
from execution import APT_INSTALL, run
from files import EXECUTABLE_MODE, save
from network import download

ABI32 = 32
ABI64 = 64
STEAM_ABIS = (ABI32, ABI64)
SUDO = "sudo"
SUDO_USER = (SUDO, "-u")
SUDO_INSTALL = (SUDO, "install")
USER_LINK = ("ln", "-sf")
DIRECTORY_NAME = "steamcmd"
STEAM_PACKAGES = (
    "ca-certificates",
    "curl",
    SUDO,
    "tar",
    "lib32gcc-s1",
    "lib32stdc++6",
)


def steam_account(user):
    if user == "root":
        raise ValueError("SteamCMD should run as an unprivileged local user, not root.")
    try:
        account = pwd.getpwnam(user)
    except KeyError:
        account = None
    if account and account.pw_uid == 0:
        raise ValueError("SteamCMD cannot run as a UID 0 account.")
    run(*APT_INSTALL, *STEAM_PACKAGES)
    if account is None:
        run(SUDO, "useradd", "-m", "-s", "/bin/bash", "--", user)
        account = pwd.getpwnam(user)
    return account


def install_archive(user, directory, temporary):
    archive = temporary / "steamcmd.tar.gz"
    download(
        "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz",
        archive,
    )
    target = directory / ".steamcmd.tar.gz"
    run(
        *SUDO_INSTALL,
        "-o",
        user,
        "-g",
        grp.getgrgid(pwd.getpwnam(user).pw_gid).gr_name,
        "-m",
        "644",
        archive,
        target,
    )
    with ExitStack() as cleanup:
        cleanup.callback(run, *SUDO_USER, user, "rm", "-f", target)
        run(*SUDO_USER, user, "tar", "-xzf", target, "-C", directory)
    run(SUDO, "-H", "-u", user, directory / "steamcmd.sh", "+quit")


def steam_links(user, home):
    directory = home / DIRECTORY_NAME
    for bits in STEAM_ABIS:
        library = directory / f"linux{bits}/steamclient.so"
        if not library.exists():
            continue
        sdk = home / f".steam/sdk{bits}"
        run(*SUDO_USER, user, "install", "-d", sdk)
        run(*SUDO_USER, user, *USER_LINK, library, sdk / "steamclient.so")
        run(
            *SUDO_USER,
            user,
            *USER_LINK,
            directory / f"linux{bits}/steamcmd",
            directory / f"linux{bits}/steam",
        )
        if bits == ABI32:
            run(*SUDO_USER, user, *USER_LINK, library, directory / "steamservice.so")
        else:
            run(SUDO, *USER_LINK, library, "/usr/lib/x86_64-linux-gnu/steamclient.so")


def steam_wrapper(user, directory, temporary):
    executable = shlex.quote(str(directory / "steamcmd.sh"))
    username = shlex.quote(user)
    launcher = f'#!/bin/sh\nif [ "$(id -un)" = {username} ]; then\n    exec {executable} "$@"\nfi\nexec sudo -H -u {username} {executable} "$@"\n'
    wrapper = temporary / DIRECTORY_NAME
    save(wrapper, launcher.encode(), EXECUTABLE_MODE)
    run(
        *SUDO_INSTALL,
        "-m",
        "755",
        wrapper,
        os.environ.get("STEAMCMD_BIN", "/usr/local/bin/steamcmd"),
    )


class Steamcmd(Topic):
    name = DIRECTORY_NAME
    description = "Install SteamCMD dedicated server client"
    needs_apt = True

    def packages(self):
        return ()

    def install(self):
        user = os.environ.get("STEAM_LOCAL_USER", "steam")
        account = steam_account(user)
        home = Path(account.pw_dir)

        directory = home / DIRECTORY_NAME
        run(
            *SUDO_INSTALL,
            "-d",
            "-o",
            user,
            "-g",
            grp.getgrgid(account.pw_gid).gr_name,
            directory,
        )
        with TemporaryDirectory(prefix="steamcmd-") as temporary:
            install_archive(user, directory, Path(temporary))
            steam_links(user, home)
            steam_wrapper(user, directory, Path(temporary))

    def preview(self):
        return (
            "reject root as SteamCMD runtime user; create user if absent",
            "sudo apt install -y ca-certificates curl sudo tar lib32gcc-s1 lib32stdc++6",
            "download SteamCMD archive over HTTPS",
            "extract and run steamcmd.sh +quit as the SteamCMD user",
            "create Steam library links and an unprivileged SteamCMD wrapper",
        )


TOPIC = Steamcmd()
