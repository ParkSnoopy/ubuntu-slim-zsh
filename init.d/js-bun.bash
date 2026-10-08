#!/bin/env bash
set -euo pipefail

sudo apt install -y curl unzip

INSTALLER_PATH="$(mktemp "${TMPDIR:-/tmp}/bun-install.XXXXXX")"
trap 'rm -f "$INSTALLER_PATH"' EXIT
curl --proto '=https' --tlsv1.2 -fsSL https://bun.sh/install -o "$INSTALLER_PATH"
bash "$INSTALLER_PATH"
