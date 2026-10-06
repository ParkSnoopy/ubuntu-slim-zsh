"""Updates preserve installed files until the full source bundle validates."""

import contextlib
import io
import stat
import subprocess
import sys
from functools import partial
from unittest.mock import patch

from bootstrap_case import BootstrapCase
from repository_fixtures import invalid_bundle, repository_fixture
from updater import self_update

NETWORK_FETCH = "network.fetch"
UPDATER_FETCH = "updater.fetch"


class UpdateTests(BootstrapCase):
    def test_complete_bundle_and_config_confirmation(self):
        target = self.home / "bootstrap"
        target.write_text("old executable\n")
        config = self.home / ".zshenv"
        config.write_text("old config\n")
        with (
            patch(NETWORK_FETCH, repository_fixture),
            patch(UPDATER_FETCH, repository_fixture),
            patch("sys.stdin", io.StringIO("n\n")),
            contextlib.redirect_stdout(self.output),
            contextlib.redirect_stderr(self.output),
        ):
            self_update()
        self.assertTrue(target.stat().st_mode & stat.S_IXUSR)
        self.assertEqual(config.read_text(), "old config\n")
        self.assertIn(f"Update {config}? [y/N]: ", self.output.getvalue())
        completed = subprocess.run(
            [sys.executable, str(target), "--list"],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertIn("oh-my-tmux", completed.stdout)

    def test_current_version_offers_shell_refresh(self):
        config = self.home / ".zshenv"
        config.write_text("old config\n")
        with (
            patch("updater.CURRENT_COMMIT_HASH", "aaaaaaa"),
            patch(NETWORK_FETCH, repository_fixture),
            patch(UPDATER_FETCH, repository_fixture),
            patch("sys.stdin", io.StringIO("y\n")),
            contextlib.redirect_stdout(self.output),
            contextlib.redirect_stderr(self.output),
        ):
            self_update()
        self.assertEqual(config.read_text(), "new config\n")
        self.assertFalse((self.home / "bootstrap").exists())

    def test_invalid_source_does_not_replace_files(self):
        target = self.home / "bootstrap"
        target.write_text("keep executable\n")
        for suffix in ("/coordinator.py", "/topics/minecraft_fabric.py"):
            with (
                self.subTest(suffix=suffix),
                patch(NETWORK_FETCH, repository_fixture),
                patch(UPDATER_FETCH, partial(invalid_bundle, suffix=suffix)),
                self.assertRaises(SyntaxError),
            ):
                self_update()
        self.assertEqual(target.read_text(), "keep executable\n")
        self.assertFalse((self.home / "bootstrap.d").exists())

    def test_completion_and_stale_module_cleanup(self):
        directory = self.home / "bootstrap.d"
        for filename in ("stale.py", "minecraft_fabric.py", "topics/stale.py"):
            previous = directory / filename
            previous.parent.mkdir(parents=True, exist_ok=True)
            previous.touch()
        completion = self.home / "completion"
        completion.mkdir()
        with (
            patch(NETWORK_FETCH, repository_fixture),
            patch(UPDATER_FETCH, repository_fixture),
            patch("completion.fetch", repository_fixture),
            patch("sys.stdin", io.StringIO("n\n")),
            contextlib.redirect_stdout(self.output),
            contextlib.redirect_stderr(self.output),
        ):
            self_update()
        self.assertFalse((directory / "stale.py").exists())
        self.assertFalse((directory / "minecraft_fabric.py").exists())
        self.assertFalse((directory / "topics/stale.py").exists())
        self.assertTrue((directory / "topics/minecraft_fabric.py").is_file())
        self.assertIn("oh-my-zsh", (completion / "_bootstrap").read_text())
