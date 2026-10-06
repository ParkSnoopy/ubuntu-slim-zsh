"""A temporary home and one shared installer integration seam."""

import contextlib
import io
import os
import sys
import unittest
from functools import partial
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
MODULE_DIRECTORY = ROOT / "bootstrap.d"
sys.path.insert(0, str(MODULE_DIRECTORY))

import coordinator
from command_fixtures import command_fixture, fetch_fixture, populate_home

TEST_UID = 1000


class BootstrapCase(unittest.TestCase):
    def setUp(self):
        self.home = Path(
            self.enterContext(TemporaryDirectory(prefix="bootstrap-test-"))
        )
        self.enterContext(
            patch.dict(
                os.environ,
                {
                    "HOME": str(self.home),
                    "MINECRAFT_INSTALL_DIR": str(self.home / "server"),
                    "STEAMCMD_BIN": str(self.home / "steam-wrapper"),
                    "BOOTSTRAP_TARGET_SCRIPT": str(self.home / "bootstrap"),
                    "BOOTSTRAP_COMPLETION": str(self.home / "completion/_bootstrap"),
                },
            )
        )
        self.commands = []
        self.requests = []
        self.output = io.StringIO()
        self.failure = None
        self.account = SimpleNamespace(
            pw_uid=TEST_UID, pw_gid=TEST_UID, pw_dir=str(self.home)
        )
        populate_home(self.home)

    def execute(self, *arguments, input_text=""):
        contexts = (
            patch.object(coordinator, "prepare_nix"),
            patch("subprocess.run", partial(command_fixture, case=self)),
            patch("network.fetch", partial(fetch_fixture, requests=self.requests)),
            patch(
                "minecraft_neoforge.fetch",
                partial(fetch_fixture, requests=self.requests),
            ),
            patch(
                "urllib.request.OpenerDirector.open",
                side_effect=AssertionError("unmocked network in offline test"),
            ),
            patch("pwd.getpwnam", return_value=self.account),
            patch("grp.getgrgid", return_value=SimpleNamespace(gr_name="users")),
            patch("sys.stdin", io.StringIO(input_text)),
            contextlib.redirect_stdout(self.output),
            contextlib.redirect_stderr(self.output),
        )
        with contextlib.ExitStack() as stack:
            for context in contexts:
                stack.enter_context(context)
            return coordinator.main(list(arguments))
