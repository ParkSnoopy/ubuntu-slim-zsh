#!/bin/env bash
set -euo pipefail

# Git Configs
. "${INIT_NIX_HELPER:-$(dirname "$0")/_nix.sh}"
nix-env --file "$NIXPKGS_URL" --install --attr git delta git-lfs

git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.quotePath false

git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global merge.conflictStyle zdiff3
git config --global diff.lfs.textconv cat
