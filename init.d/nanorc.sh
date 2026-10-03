#!/bin/env bash
set -euo pipefail

. "${INIT_NIX_HELPER:-$(dirname "$0")/_nix.sh}"
nix_install nano nanorc

INCLUDE="include \"$HOME/.nix-profile/share/*.nanorc\""
if ! grep -Fxq "$INCLUDE" "$HOME/.nanorc" 2>/dev/null; then
	echo "$INCLUDE" >> "$HOME/.nanorc"
fi
