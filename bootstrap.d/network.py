"""Fetch HTTPS resources without permitting protocol downgrades."""

import json
from urllib.parse import urlsplit
from urllib.request import (
    HTTPDefaultErrorHandler,
    HTTPErrorProcessor,
    HTTPRedirectHandler,
    HTTPSHandler,
    OpenerDirector,
    ProxyHandler,
    UnknownHandler,
)

from files import save


def fetch(url):
    if urlsplit(url).scheme != "https":
        raise ValueError(f"Refusing non-HTTPS download: {url}")
    opener = OpenerDirector()
    for protocol in (
        ProxyHandler(),
        HTTPSHandler(),
        HTTPDefaultErrorHandler(),
        HTTPRedirectHandler(),
        HTTPErrorProcessor(),
        UnknownHandler(),
    ):
        opener.add_handler(protocol)
    with opener.open(url, timeout=60) as response:
        return response.read()


def fetch_json(url):
    return json.loads(fetch(url))


def download(url, path):
    save(path, fetch(url))


def stable_version(entries, label):
    version = next((entry["version"] for entry in entries if entry["stable"]), None)
    if not version:
        raise ValueError(f"No stable {label} version found.")
    return version
