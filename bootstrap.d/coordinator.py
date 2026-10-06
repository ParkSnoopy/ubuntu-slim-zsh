"""Coordinate one package phase followed by isolated topic actions."""

import shlex
import subprocess
from xml.etree import ElementTree

from catalog import TOPICS
from console import emit, emit_lines, prompt
from execution import run
from nix import package_command, prepare_nix
from options import parser, selection
from settings import NIX_INSTALLER_URL
from updater import self_update

OPERATION_ERRORS = (
    OSError,
    ValueError,
    subprocess.CalledProcessError,
    ElementTree.ParseError,
)


def install_packages(selected, dry_run):
    command = package_command(selected)
    if command:
        if dry_run:
            emit("\n==> Preview shared Nix packages")
            emit(f"Nix setup: verified installer {NIX_INSTALLER_URL} if absent")
            emit(shlex.join(command))
        else:
            emit("\n==> Installing shared Nix packages")
            prepare_nix()
            run(*command)
    if any(TOPICS[name].needs_apt for name in selected):
        if dry_run:
            emit("sudo apt update")
        else:
            run("sudo", "apt", "update")


def apply_topic(name):
    try:
        TOPICS[name].install()
    except OPERATION_ERRORS as error:
        emit(f"✗ Topic failed: {name}: {error}", error=True)
        return False
    emit(f"✓ Topic complete: {name}")
    return True


def install_topics(selected, dry_run):
    failed = []
    for name in selected:
        action = "Preview" if dry_run else "Installing"
        emit(f"\n==> {action} topic: {name}")
        if dry_run:
            emit_lines(TOPICS[name].preview())
        elif not apply_topic(name):
            failed.append(name)
    if failed:
        names = " ".join(failed)
        emit(f"✗ Failed topics: {names}", error=True)
        return 1
    if not dry_run:
        emit("\n✓ Restart container to take effect.")
    return 0


def main(argv=None):
    arguments = parser().parse_args(argv)
    if getattr(arguments, "list", False):
        emit_lines(TOPICS)
        return 0
    if arguments.command == "update":
        self_update()
        return 0
    selected = selection(arguments)
    if not selected:
        return 0
    dry_run = getattr(arguments, "dry_run", False)
    if not dry_run and not getattr(arguments, "y", False):
        names = " ".join(selected)
        emit(f"Selected topics: {names}")
        if prompt("Proceed?", "N").lower() not in {"y", "yes"}:
            emit("Cancelled.")
            return 0
    install_packages(selected, dry_run)
    return install_topics(selected, dry_run)
