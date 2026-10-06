"""Minecraft parsing, prompt isolation, and generated server artifacts."""

import contextlib
import io
import os
import sys
from unittest.mock import patch

from bootstrap_case import BootstrapCase
from console import prompt
from execution import run

GAME_TOPICS = ("minecraft-fabric", "minecraft-neoforge")
INSTALL = "install"
ASSUME_YES = "-y"


class TerminalInput(io.StringIO):
    def readline(self, *arguments):
        sys.stdout.write("\x1b[?2004h")
        return super().readline(*arguments)


class MinecraftTests(BootstrapCase):
    def test_defaults_and_eof(self):
        for name in GAME_TOPICS:
            for answers in ("\n\n", ""):
                self.assertEqual(
                    self.execute(INSTALL, name, ASSUME_YES, input_text=answers), 0
                )
                self.assertTrue((self.home / "server/run.sh").is_file())
        expected = (
            "https://meta.fabricmc.net/v2/versions/loader/26.3/0.19.5/1.1.2/server/jar"
        )
        self.assertIn(expected, self.requests)
        self.assertIn("-Xmx6G", (self.home / "server/user_jvm_args.txt").read_text())
        self.assertEqual(
            (self.home / "server/run.sh").read_text(), "upstream launcher\n"
        )

    def test_custom_paths_and_versions(self):
        for name in GAME_TOPICS:
            custom = self.home / f"{name} space's directory"
            self.assertEqual(
                self.execute(
                    INSTALL, name, ASSUME_YES, input_text=f"1.21.1\n{custom}\n"
                ),
                0,
            )
            self.assertTrue((custom / "run.sh").is_file())
            self.assertFalse((custom / "run.bat").exists())
            run("bash", "-n", custom / "run.sh")
        self.assertTrue(
            any("/loader/1.21.1/0.19.5/1.1.2/" in url for url in self.requests)
        )
        self.assertTrue(
            any("/21.1.1/neoforge-21.1.1-installer.jar" in url for url in self.requests)
        )

    def test_prompt_output_and_input_validation(self):
        with (
            patch("sys.stdin", TerminalInput("\n26.3\n")),
            contextlib.redirect_stdout(self.output),
            contextlib.redirect_stderr(self.output),
        ):
            self.assertEqual(prompt("Version", "1.21.1"), "1.21.1")
            self.assertEqual(prompt("Version", "1.21.1"), "26.3")
        self.assertEqual(
            self.execute(
                INSTALL, GAME_TOPICS[0], ASSUME_YES, input_text="\x1b[200~26.3\n"
            ),
            1,
        )
        with patch.dict(os.environ, {"MINECRAFT_MAX_RAM": "6G; bad"}):
            self.assertEqual(self.execute(INSTALL, GAME_TOPICS[0], ASSUME_YES), 1)
