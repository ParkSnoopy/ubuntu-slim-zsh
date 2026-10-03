#!/bin/env bash
set -euo pipefail

# Basic Tools
. "${INIT_NIX_HELPER:-$(dirname "$0")/_nix.sh}"
nix_install man-db curl wget nano zip unzip git tree gh jq ripgrep moreutils
