"""Run the chosen program and propagate its failure."""

import subprocess

APT_INSTALL = ("sudo", "apt", "install", "-y")


def run(*arguments, **options):
    return subprocess.run(
        [str(argument) for argument in arguments], check=True, **options
    )
