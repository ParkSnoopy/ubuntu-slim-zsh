#!/bin/env bash
set -euo pipefail

sudo apt install -y curl zsh

# oh-my-zsh with 'daveverwer' theme
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="daveverwer"/g' "$HOME/.zshrc"
