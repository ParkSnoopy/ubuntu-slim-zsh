"""Shared pins and installation defaults."""

CURRENT_COMMIT_HASH = "b1ec88e"
DEFAULT_TOPICS = ("unminimize", "apt-https", "packages", "oh-my-zsh")
PRIORITY_TOPICS = ("unminimize", "apt-https", "packages")
PYTHON_VERSION = "3.12"
NIXPKGS_URL = "https://github.com/NixOS/nixpkgs/archive/774debe7a0d1b496e35677ad955a1011c6ff74f3.tar.gz"
NIX_INSTALLER_URL = "https://releases.nixos.org/nix/nix-2.24.14/install"
NIX_INSTALLER_SHA256 = (
    "00f90bcea17b7d89af1efa4452221403054aad8765759cef8dae1cd3c474abc8"
)
NODE_VARIANTS = frozenset(("nodejs_22", "nodejs_24"))
NIX_ENV = "nix-env"
TOPIC_ORDER = (
    "unminimize",
    "apt-https",
    "packages",
    "git-config",
    "nanorc",
    "python-uv",
    "tldr",
    "xtradeb",
    "oh-my-zsh",
    "js-node-22",
    "js-node-24",
    "js-bun",
    "golang",
    "playit-gg",
    "steamcmd",
    "minecraft-fabric",
    "minecraft-neoforge",
    "oh-my-tmux",
)
