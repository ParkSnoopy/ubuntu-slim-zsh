"""Optional real upstream downloads without privileged filesystem writes."""

import contextlib
import hashlib
import io
import os
import stat
import unittest
import zipfile
from unittest.mock import patch

from bootstrap_case import BootstrapCase
from catalog import TOPICS
from network import fetch
from settings import NIX_INSTALLER_SHA256, NIX_INSTALLER_URL


def local_directory(*arguments):
    if arguments[:3] != ("sudo", "install", "-d"):
        raise AssertionError(f"Unexpected live command: {arguments}")
    os.makedirs(arguments[-1], exist_ok=True)


class LiveTests(BootstrapCase):
    @unittest.skipUnless(
        os.environ.get("BOOTSTRAP_LIVE_TESTS") == "1", "optional upstream downloads"
    )
    def test_fabric_and_installer_checksum(self):
        with (
            patch("topics.minecraft_fabric.run", local_directory),
            patch("sys.stdin", io.StringIO("\n\n")),
            contextlib.redirect_stderr(self.output),
        ):
            TOPICS["minecraft-fabric"].install()
        directory = self.home / "server"
        with zipfile.ZipFile(directory / "fabric-server-launch.jar") as jar:
            self.assertIsNone(jar.testzip())
            self.assertIn("net/fabricmc/installer/ServerLauncher.class", jar.namelist())
        self.assertTrue((directory / "run.sh").stat().st_mode & stat.S_IXUSR)
        self.assertEqual(
            hashlib.sha256(fetch(NIX_INSTALLER_URL)).hexdigest(), NIX_INSTALLER_SHA256
        )
