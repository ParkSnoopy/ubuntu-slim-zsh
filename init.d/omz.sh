#!/bin/env bash
set -euo pipefail

. "${INIT_NIX_HELPER:-$(dirname "$0")/_nix.sh}"
nix-env --file "$NIXPKGS_URL" --install --attr git zsh oh-my-zsh

# Preserve existing shell settings. New configurations use the pinned package.
if [ ! -e "$HOME/.zshrc" ]; then
	cp "$HOME/.nix-profile/share/oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
	sed -i \
		-e 's|^export ZSH=.*|export ZSH="$HOME/.nix-profile/share/oh-my-zsh"|' \
		-e 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="daveverwer"/' \
		"$HOME/.zshrc"
fi
