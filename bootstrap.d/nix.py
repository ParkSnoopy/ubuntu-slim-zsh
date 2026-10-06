"""Gather Nix packages and install them in one transaction."""

import grp
import hashlib
import os
import shutil
from pathlib import Path
from tempfile import TemporaryDirectory

from catalog import TOPICS
from execution import run
from files import save
from network import fetch
from playit_derivation import PLAYIT_EXPRESSION
from settings import (
    NIX_ENV,
    NIX_INSTALLER_SHA256,
    NIX_INSTALLER_URL,
    NIXPKGS_URL,
    NODE_VARIANTS,
)


def package_command(selected):
    packages = list(
        dict.fromkeys(
            package for name in selected for package in TOPICS[name].packages()
        )
    )
    nodes = [package for package in packages if package in NODE_VARIANTS]
    if nodes:
        packages = [package for package in packages if package not in nodes[:-1]]
    if not packages:
        return []
    if "playit" not in packages:
        return [NIX_ENV, "--file", NIXPKGS_URL, "--install", "--attr", *packages]
    expressions = " ".join(
        PLAYIT_EXPRESSION if package == "playit" else f"pkgs.{package}"
        for package in packages
    )
    expression = f"nixpkgs: let pkgs = nixpkgs {{}}; in [ {expressions} ]"
    return [
        NIX_ENV,
        "--file",
        NIXPKGS_URL,
        "--install",
        "--from-expression",
        expression,
    ]


def configure_environment():
    profile = Path.home() / ".nix-profile"
    previous = os.environ.get("PATH", "")
    os.environ["PATH"] = f"{profile}/bin:/nix/var/nix/profiles/default/bin:{previous}"
    os.environ.setdefault("NIX_SSL_CERT_FILE", "/etc/ssl/certs/ca-certificates.crt")
    if os.getuid() == 0:
        try:
            grp.getgrnam("nixbld")
        except KeyError:
            configuration = os.environ.get("NIX_CONFIG", "")
            os.environ["NIX_CONFIG"] = f"{configuration}\nbuild-users-group ="


def install_nix():
    payload = fetch(NIX_INSTALLER_URL)
    if hashlib.sha256(payload).hexdigest() != NIX_INSTALLER_SHA256:
        raise ValueError("Nix installer checksum mismatch.")
    with TemporaryDirectory(prefix="nix-install-") as temporary:
        installer = Path(temporary) / "install"
        save(installer, payload)
        run(
            "sh",
            installer,
            "--no-daemon",
            "--yes",
            "--no-channel-add",
            "--no-modify-profile",
        )
    if not shutil.which(NIX_ENV):
        raise ValueError("Nix installation did not provide nix-env.")


def prepare_nix():
    configure_environment()
    if not shutil.which(NIX_ENV):
        install_nix()
