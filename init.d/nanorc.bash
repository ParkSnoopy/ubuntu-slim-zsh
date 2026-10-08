#!/bin/env bash
set -euo pipefail

sudo apt install -y curl unzip wget

INSTALLER_PATH="$(mktemp "${TMPDIR:-/tmp}/nanorc-install.XXXXXX")"
trap 'rm -f "$INSTALLER_PATH"' EXIT
curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh -o "$INSTALLER_PATH"
sh "$INSTALLER_PATH"
