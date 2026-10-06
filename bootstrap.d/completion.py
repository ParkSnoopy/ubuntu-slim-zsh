"""Refresh the shell completion owned by the bootstrap package."""

import os
from pathlib import Path

from console import emit
from files import save
from network import fetch


def refresh_completion(base):
    target = Path(
        os.environ.get(
            "BOOTSTRAP_COMPLETION", "/usr/local/share/zsh/site-functions/_bootstrap"
        )
    )
    if target.parent.is_dir() and os.access(target.parent, os.W_OK):
        try:
            save(target, fetch(f"{base}/src/_bootstrap"))
        except OSError as error:
            emit(f"! Completion update failed: {error}", error=True)
