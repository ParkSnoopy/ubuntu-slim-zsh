"""Repository responses for complete-bundle update checks."""

import json
from types import MappingProxyType
from urllib.parse import urlsplit

from bootstrap_case import ROOT

SHA_LENGTH = 40
LATEST_SHA = "a" * SHA_LENGTH
ASSETS = MappingProxyType(
    {
        "/bootstrap": (ROOT / "bootstrap").read_bytes(),
        "/src/.zshenv": b"new config\n",
        "/src/_bootstrap": (ROOT / "src/_bootstrap").read_bytes(),
    }
)


def repository_fixture(url):
    path = urlsplit(url).path
    if "/commits/" in path:
        return json.dumps({"sha": LATEST_SHA}).encode()
    if "/contents/" in path:
        listing = tuple(
            {"name": source.name, "type": "dir" if source.is_dir() else "file"}
            for source in (ROOT / path.partition("/contents/")[2]).iterdir()
        )
        return json.dumps(listing).encode()
    for suffix, payload in ASSETS.items():
        if path.endswith(suffix):
            return payload
    if "/bootstrap.d/" in path:
        filename = path.partition("/bootstrap.d/")[2]
        return (ROOT / "bootstrap.d" / filename).read_bytes()
    raise AssertionError(f"Unexpected repository download: {url}")


def invalid_bundle(url, suffix="/coordinator.py"):
    if url.endswith(suffix):
        return b"invalid syntax !"
    return repository_fixture(url)
