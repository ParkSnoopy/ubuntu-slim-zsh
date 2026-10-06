"""Parse the command line and preserve topic selection order."""

import argparse
from itertools import chain

from catalog import TOPICS
from settings import CURRENT_COMMIT_HASH, DEFAULT_TOPICS, PRIORITY_TOPICS


def parser():
    options = argparse.ArgumentParser(
        add_help=False, argument_default=argparse.SUPPRESS
    )
    options.add_argument(
        "--exclude",
        nargs="+",
        choices=[*TOPICS, "*"],
        action="extend",
        metavar="topic",
        help="remove topics after selection",
    )
    options.add_argument(
        "--dry-run", action="store_true", help="preview without prompts or changes"
    )
    options.add_argument(
        "-y", action="store_true", help="skip installation confirmation"
    )
    options.add_argument("--list", action="store_true", help="list available topics")
    root = argparse.ArgumentParser(
        prog="bootstrap",
        parents=[options],
        description=f"Ubuntu bootstrap ({CURRENT_COMMIT_HASH}).",
        epilog="\n".join(
            f"{topic.name}: {topic.description}" for topic in TOPICS.values()
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    commands = root.add_subparsers(dest="command")
    install = commands.add_parser(
        "install", parents=[options], help="install selected topics"
    )
    install.add_argument(
        "topics",
        nargs="+",
        choices=[*TOPICS, "*"],
        metavar="topic",
        help="topic names; '*' selects all",
    )
    commands.add_parser(
        "update", help="update bootstrap and confirm shell configuration refresh"
    )
    return root


def expand_topics(names):
    return chain.from_iterable(TOPICS if name == "*" else (name,) for name in names)


def selection(arguments):
    selected = tuple(
        dict.fromkeys(expand_topics(getattr(arguments, "topics", DEFAULT_TOPICS)))
    )
    excluded = frozenset(expand_topics(getattr(arguments, "exclude", ())))
    ordered = dict.fromkeys((*PRIORITY_TOPICS, *selected))
    return [name for name in ordered if name in selected and name not in excluded]
