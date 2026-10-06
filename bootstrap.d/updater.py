"""Download complete source bundles before replacing installed files."""

import ast
import os
import re
from pathlib import Path
from urllib.parse import quote

from completion import refresh_completion
from console import emit, prompt
from files import EXECUTABLE_MODE, save
from network import fetch, fetch_json
from settings import CURRENT_COMMIT_HASH

COMMIT_MARKER = "CURRENT_COMMIT_HASH = "
SCRIPT_NAME = "bootstrap"
MODULE_DIRECTORY = "bootstrap.d"
SHORT_HASH_LENGTH = 7


def upstream():
    repository = os.environ.get(
        "BOOTSTRAP_GITHUB_REPOSITORY", "ParkSnoopy/ubuntu-slim-zsh"
    )
    branch = quote(os.environ.get("BOOTSTRAP_GITHUB_BRANCH", "main"), safe="")
    commit = fetch_json(f"https://api.github.com/repos/{repository}/commits/{branch}")[
        "sha"
    ]
    if not isinstance(commit, str) or not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("Could not read latest commit hash.")
    base = os.environ.get(
        "BOOTSTRAP_BASE_URL", f"https://raw.githubusercontent.com/{repository}/{commit}"
    )
    return repository, commit, base


def module_names(repository, commit):
    listing = fetch_json(
        f"https://api.github.com/repos/{repository}/contents/{MODULE_DIRECTORY}?ref={commit}"
    )
    names = tuple(
        entry["name"]
        for entry in listing
        if entry["type"] == "file" and entry["name"].endswith(".py")
    )
    if not names or any(
        not re.fullmatch(r"[a-z][a-z0-9_]*\.py", name) for name in names
    ):
        raise ValueError("Invalid bootstrap module listing.")
    if "settings.py" not in names:
        raise ValueError("Bootstrap module listing has no settings.py.")
    return names


def stamp_commit(payload, commit):
    lines = payload.decode().splitlines()
    positions = [
        index for index, line in enumerate(lines) if line.startswith(COMMIT_MARKER)
    ]
    if len(positions) != 1:
        raise ValueError("Downloaded bootstrap has no unique commit marker.")
    short_hash = commit[:SHORT_HASH_LENGTH]
    lines[positions[0]] = f'{COMMIT_MARKER}"{short_hash}"'
    return "\n".join((*lines, "")).encode()


def download_bundle(repository, commit, base):
    sources = {SCRIPT_NAME: fetch(f"{base}/{SCRIPT_NAME}")}
    for name in module_names(repository, commit):
        sources[f"{MODULE_DIRECTORY}/{name}"] = fetch(
            f"{base}/{MODULE_DIRECTORY}/{name}"
        )
    sources[f"{MODULE_DIRECTORY}/settings.py"] = stamp_commit(
        sources[f"{MODULE_DIRECTORY}/settings.py"], commit
    )
    for filename, payload in sources.items():
        ast.parse(payload, filename=filename)
    return sources


def install_bundle(target, sources):
    directory = target.with_name(MODULE_DIRECTORY)
    directory.mkdir(parents=True, exist_ok=True)
    for filename, payload in sources.items():
        if filename != SCRIPT_NAME:
            save(target.parent / filename, payload)
    for previous in directory.glob("*.py"):
        if f"{MODULE_DIRECTORY}/{previous.name}" not in sources:
            previous.unlink()
    save(target, sources[SCRIPT_NAME], EXECUTABLE_MODE)


def refresh_shell(base):
    reply = prompt(f"Update {Path.home()}/.zshenv?", "N")
    if reply.lower() in {"y", "yes"}:
        save(Path.home() / ".zshenv", fetch(f"{base}/src/.zshenv"))
        emit(f"✓ Updated {Path.home()}/.zshenv.")
    else:
        emit(f"Skipped {Path.home()}/.zshenv.")


def self_update():
    repository, commit, base = upstream()
    target = Path(
        os.environ.get("BOOTSTRAP_TARGET_SCRIPT", str(Path.home() / SCRIPT_NAME))
    )
    short_hash = commit[:SHORT_HASH_LENGTH]
    if short_hash == CURRENT_COMMIT_HASH:
        emit(f"✓ Already up to date ({CURRENT_COMMIT_HASH}).")
    else:
        install_bundle(target, download_bundle(repository, commit, base))
        refresh_completion(base)
        emit(f"✓ Updated {target} to {short_hash}.")
    refresh_shell(base)
