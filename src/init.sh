#!/bin/env bash
set -euo pipefail

INIT_SCRIPT="${TMPDIR:-/tmp}/init.sh"
INIT_SCRIPT_URL="https://raw.githubusercontent.com/ParkSnoopy/ubuntu-slim-zsh/refs/heads/main/init.sh"

if ! command -v curl >/dev/null || ! command -v xz >/dev/null || [ ! -s /etc/ssl/certs/ca-certificates.crt ]; then
	# Preserve the bootstrap's archive mirror when APT prerequisites are needed.
	sudo sed -i \
		-e 's|http://security.ubuntu.com/ubuntu|http://archive.ubuntu.com/ubuntu|g' \
		/etc/apt/sources.list.d/*
	sudo apt update
	sudo apt install -y curl ca-certificates xz-utils
fi

if [ ! -s "$INIT_SCRIPT" ]; then
	curl --proto '=https' --tlsv1.2 -sSf "$INIT_SCRIPT_URL" -o "$INIT_SCRIPT"
	chmod +x "$INIT_SCRIPT"
fi

bash "$INIT_SCRIPT" "$@"

# Replace the packaged bootstrap with the downloaded master script only after
# the master script exits successfully.
install -m 755 "$INIT_SCRIPT" "$0"
