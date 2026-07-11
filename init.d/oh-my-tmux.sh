#!/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y git zsh

# Setup oh-my-tmux
chsh -s "$(which zsh)"
cd "$HOME"
git clone --single-branch https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
