#!/bin/env bash
set -euo pipefail

INIT_SCRIPT="${TMPDIR:-/tmp}/init.sh"
INIT_SCRIPT_URL="https://raw.githubusercontent.com/ParkSnoopy/ubuntu-slim-zsh/refs/heads/main/init.sh"

# Use the plain Ubuntu archive mirror from the packaged container init script.
sudo sed -i \
	-e 's|http://security.ubuntu.com/ubuntu|http://archive.ubuntu.com/ubuntu|g' \
	/etc/apt/sources.list.d/*

sudo apt update
sudo apt install -y curl ca-certificates

if [ ! -s "$INIT_SCRIPT" ]; then
	curl --proto '=https' --tlsv1.2 -sSf "$INIT_SCRIPT_URL" -o "$INIT_SCRIPT"
	chmod +x "$INIT_SCRIPT"
fi

bash "$INIT_SCRIPT" "$@"

# remove self only after the remote script exits successfully
rm -- "$0"
