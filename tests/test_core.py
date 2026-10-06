"""Contracts, topic selection, and the upfront package transaction."""

import contextlib
import re
import subprocess
from functools import partial
from unittest.mock import patch

from bootstrap_case import ROOT, BootstrapCase
from catalog import TOPICS
from contract import METHODS, Topic
from coordinator import main
from nix import package_command
from options import parser, selection
from settings import DEFAULT_TOPICS, TOPIC_ORDER

INSTALL = "install"
EXCLUDE = "--exclude"
ASSUME_YES = "-y"
BASE_TOPIC = "packages"
GIT_TOPIC = "git-config"


def is_program(command, program):
    return command[0] == program


class CoreTests(BootstrapCase):
    def test_contract_and_topic_metadata(self):
        self.assertEqual(tuple(TOPICS), TOPIC_ORDER)
        self.assertEqual(Topic.__abstractmethods__, METHODS)
        self.assertTrue(
            all(
                type(topic).__module__.startswith("topics.")
                for topic in TOPICS.values()
            )
        )
        self.assertTrue(
            all(
                isinstance(topic, Topic) and topic.description
                for topic in TOPICS.values()
            )
        )
        with self.assertRaises(TypeError):
            Topic()
        for method in ("extra", "_helper", "__init__"):
            with self.subTest(method=method), self.assertRaises(TypeError):
                type("Invalid", (Topic,), {method: lambda instance: None})
        with self.assertRaises(TypeError):
            type("WrongSignature", (Topic,), {INSTALL: lambda instance, argument: None})

    def test_completion_and_restored_names(self):
        completion = (ROOT / "src/_bootstrap").read_text()
        names = tuple(re.findall(r"'([a-z][a-z0-9-]*):", completion))
        self.assertEqual(names[: len(TOPIC_ORDER)], TOPIC_ORDER)
        self.assertIn("oh-my-zsh", TOPICS)
        self.assertIn("oh-my-tmux", TOPICS)
        self.assertFalse({"omz", "omt"} & TOPICS.keys())

    def test_offline_help_and_all_previews(self):
        with (
            contextlib.redirect_stdout(self.output),
            contextlib.redirect_stderr(self.output),
            patch(
                "network.fetch", side_effect=AssertionError("network during preview")
            ),
            patch(
                "subprocess.run", side_effect=AssertionError("command during preview")
            ),
        ):
            for arguments in (
                ("--help",),
                (INSTALL, "--help"),
                (INSTALL, "golang", "-h"),
                ("update", "--help"),
            ):
                stopped = self.assertRaises(SystemExit)
                with stopped:
                    main(arguments)
                self.assertEqual(stopped.exception.code, 0)
            for name in TOPICS:
                self.assertEqual(main((INSTALL, name, "--dry-run")), 0)
            self.assertEqual(main((INSTALL, "*", EXCLUDE, "*", ASSUME_YES)), 0)
            self.assertEqual(main(("--list",)), 0)

    def test_selection_and_invalid_arguments(self):
        parse = parser().parse_args
        self.assertEqual(selection(parse([])), list(DEFAULT_TOPICS))
        selected = parse(
            (
                INSTALL,
                "oh-my-zsh",
                BASE_TOPIC,
                "unminimize",
                BASE_TOPIC,
                EXCLUDE,
                "oh-my-zsh",
            )
        )
        self.assertEqual(selection(selected), ["unminimize", BASE_TOPIC])
        self.assertTrue(parse(("--dry-run", INSTALL, BASE_TOPIC)).dry_run)
        for arguments in (
            (INSTALL,),
            (INSTALL, "unknown"),
            (EXCLUDE, "unknown"),
            ("update", "extra"),
        ):
            with contextlib.redirect_stderr(self.output), self.assertRaises(SystemExit):
                parse(arguments)

    def test_single_transaction_before_topic_actions(self):
        self.assertEqual(
            self.execute(INSTALL, "*", ASSUME_YES, input_text="\n\n\n\n"), 0
        )
        installs = [command for command in self.commands if command[0] == "nix-env"]
        self.assertEqual(len(installs), 1)
        self.assertEqual(self.commands[0], installs[0])
        self.assertIn("--from-expression", installs[0])
        self.assertEqual(installs[0][-1].count("pkgs.jdk25 "), 1)
        self.assertIn("playit-", installs[0][-1])

    def test_node_selection_and_exclusions(self):
        command = package_command(
            (
                GIT_TOPIC,
                BASE_TOPIC,
                "js-node-24",
                "js-node-22",
                "minecraft-fabric",
                "minecraft-neoforge",
            )
        )
        self.assertEqual(command.count("git"), 1)
        self.assertEqual(command.count("jdk25"), 1)
        self.assertIn("nodejs_22", command)
        self.assertNotIn("nodejs_24", command)
        self.assertEqual(
            self.execute(
                INSTALL,
                "golang",
                "js-node-22",
                "js-node-24",
                EXCLUDE,
                "js-node-24",
                ASSUME_YES,
            ),
            0,
        )
        expected = ("go", "nodejs_22", "pnpm")
        self.assertEqual(self.commands[0][-3:], expected)

    def test_cancellation_and_failure_propagation(self):
        self.assertEqual(self.execute(INSTALL, GIT_TOPIC, input_text="n\n"), 0)
        self.assertEqual(self.commands, [])
        self.failure = partial(is_program, program="nix-env")
        with self.assertRaises(subprocess.CalledProcessError):
            self.execute(INSTALL, GIT_TOPIC, ASSUME_YES)
        self.assertEqual(len(self.commands), 1)
        self.failure = partial(is_program, program="git")
        self.assertEqual(self.execute(INSTALL, GIT_TOPIC, "golang", ASSUME_YES), 1)
        self.assertIn("Topic complete: golang", self.output.getvalue())
