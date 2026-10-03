#!/bin/env bash
set -euo pipefail

. "${INIT_NIX_HELPER:-$(dirname "$0")/_nix.sh}"
nix_install bun
