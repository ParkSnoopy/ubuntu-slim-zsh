#!/bin/env bash
set -euo pipefail

. "${INIT_NIX_HELPER:-$(dirname "$0")/_nix.sh}"
nix_install python3 uv ruff
