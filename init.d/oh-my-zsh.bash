#!/bin/env bash
set -euo pipefail

sudo apt install -y curl git zsh

INSTALLER_PATH="$(mktemp "${TMPDIR:-/tmp}/oh-my-zsh-install.XXXXXX")"
trap 'rm -f "$INSTALLER_PATH"' EXIT
curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$INSTALLER_PATH"
sh "$INSTALLER_PATH" --unattended
sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="daveverwer"/g' "$HOME/.zshrc"
