#!/bin/env bash

# Change Repo: 'kr.archive.ubuntu.com/ubuntu'
sudo sed -i  's|http://archive.ubuntu.com/ubuntu|http://kr.archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list.d/*
sudo sed -i 's|http://security.ubuntu.com/ubuntu|http://kr.archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list.d/*

# This container is for isolated OS
yes | unminimize

# http -> https
sudo apt update
sudo apt install -y ca-certificates apt-transport-https
sudo sed -i 's|http://|https://|g' /etc/apt/sources.list.d/*

# Basic Tools
sudo apt update
sudo apt upgrade -y
sudo apt install -y man-db curl wget nano zip unzip git python3 python-is-python3 python3-pip git-lfs ripgrep jq git-delta
python -m pip install --break-system-packages uv ruff

# Git Configs
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.quotePath false

git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global merge.conflictStyle zdiff3

# oh-my-zsh with 'daveverwer' theme
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="daveverwer"/g' $HOME/.zshrc

# Bun
curl -fsSL https://bun.sh/install | bash

# NodeJS
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 22
yes | corepack enable pnpm

# Setup oh-my-tmux
chsh -s $(which zsh)
cd $HOME
git clone --single-branch https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .

# Post comment
echo
echo "--------------------"
echo "Restart container to take effect"
echo "--------------------"

# remove self
rm $0
