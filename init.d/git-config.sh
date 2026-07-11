#!/bin/env bash
set -euo pipefail

# Git Configs
sudo apt update
sudo apt install -y git git-delta

git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.quotePath false

git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global merge.conflictStyle zdiff3
