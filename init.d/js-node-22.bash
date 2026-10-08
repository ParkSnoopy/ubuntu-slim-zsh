#!/bin/env bash
set -euo pipefail

sudo apt install -y curl

INSTALLER_PATH="$(mktemp "${TMPDIR:-/tmp}/nvm-install.XXXXXX")"
trap 'rm -f "$INSTALLER_PATH"' EXIT
curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh -o "$INSTALLER_PATH"
bash "$INSTALLER_PATH"
. "$HOME/.nvm/nvm.sh"
nvm install 22
corepack enable pnpm
