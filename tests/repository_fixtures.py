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
            {"name": source.name, "type": "file"}
            for source in (ROOT / "bootstrap.d").glob("*.py")
        )
        return json.dumps(listing).encode()
    for suffix, payload in ASSETS.items():
        if path.endswith(suffix):
            return payload
    if "/bootstrap.d/" in path:
        filename = path.rsplit("/", 1)[-1]
        return (ROOT / "bootstrap.d" / filename).read_bytes()
    raise AssertionError(f"Unexpected repository download: {url}")


def invalid_bundle(url):
    if url.endswith("/coordinator.py"):
        return b"invalid syntax !"
    return repository_fixture(url)
