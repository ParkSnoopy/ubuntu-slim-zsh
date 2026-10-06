"""Nix setup verification and privileged-runtime boundaries."""

import hashlib
import os
from types import SimpleNamespace
from unittest.mock import patch

from bootstrap_case import BootstrapCase
from catalog import TOPICS
from network import fetch
from nix import install_nix, prepare_nix
from settings import NIX_INSTALLER_SHA256


class SetupTests(BootstrapCase):
    def test_existing_nix_does_not_repeat_setup(self):
        with (
            patch("nix.shutil.which", return_value="/profile/bin/nix-env"),
            patch("nix.fetch", side_effect=AssertionError("unnecessary bootstrap")),
            patch("nix.run", side_effect=AssertionError("unnecessary command")),
        ):
            prepare_nix()

    def test_checksum_failure_stops_installer(self):
        with (
            patch("nix.fetch", return_value=b"invalid installer"),
            patch("nix.run") as invoked,
        ):
            with self.assertRaisesRegex(ValueError, "checksum"):
                install_nix()
            invoked.assert_not_called()

    def test_verified_installer_flags(self):
        digest = SimpleNamespace(hexdigest=lambda: NIX_INSTALLER_SHA256)
        with (
            patch("nix.fetch", return_value=b"test installer"),
            patch.object(hashlib, "sha256", return_value=digest),
            patch("nix.shutil.which", return_value="/profile/bin/nix-env"),
            patch("nix.run") as invoked,
        ):
            install_nix()
            self.assertEqual(invoked.call_args.args[0], "sh")
            self.assertEqual(
                invoked.call_args.args[2:],
                ("--no-daemon", "--yes", "--no-channel-add", "--no-modify-profile"),
            )

    def test_existing_shell_settings_are_preserved(self):
        config = self.home / ".zshrc"
        config.write_text("preserve settings\n")
        TOPICS["oh-my-zsh"].install()
        self.assertEqual(config.read_text(), "preserve settings\n")
        self.assertEqual(self.execute("install", "nanorc", "-y"), 0)
        self.assertEqual(self.execute("install", "nanorc", "-y"), 0)
        self.assertEqual((self.home / ".nanorc").read_text().count("include "), 1)

    def test_steam_root_guard_precedes_mutation(self):
        with (
            patch("steamcmd.run") as invoked,
            patch.dict(os.environ, {"STEAM_LOCAL_USER": "root"}),
        ):
            with self.assertRaisesRegex(ValueError, "unprivileged"):
                TOPICS["steamcmd"].install()
            invoked.assert_not_called()
        root_account = SimpleNamespace(pw_uid=0)
        with (
            patch("steamcmd.run") as invoked,
            patch("pwd.getpwnam", return_value=root_account),
        ):
            with self.assertRaisesRegex(ValueError, "UID 0"):
                TOPICS["steamcmd"].install()
            invoked.assert_not_called()

    def test_non_https_downloads_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "non-HTTPS"):
            fetch("http://example.com/file")

    def test_apt_only_selection_skips_nix(self):
        self.assertEqual(self.execute("install", "xtradeb", "-y"), 0)
        invoked = tuple(command[0] for command in self.commands)
        self.assertNotIn("nix-env", invoked)
