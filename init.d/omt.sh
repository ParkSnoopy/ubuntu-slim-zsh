#!/bin/env bash
set -euo pipefail

# The login shell must be registered by Ubuntu, not a user-profile symlink.
sudo apt install -y zsh
. "${INIT_NIX_HELPER:-$(dirname "$0")/_nix.sh}"
nix_install git which tmux

# Setup oh-my-tmux
chsh -s /usr/bin/zsh
cd "$HOME"
git clone --no-checkout --single-branch https://github.com/gpakosz/.tmux.git
git -C .tmux checkout 58a3dcc0d718ec0fa1c0d5a2fddd640a1ad7a5b7
ln -s -f .tmux/.tmux.conf
if [ ! -e .tmux.conf.local ]; then
	cp .tmux/.tmux.conf.local .
fi
