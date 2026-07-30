#!/bin/env bash
set -euo pipefail

sudo apt install -y curl

# NodeJS
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
. "$HOME/.nvm/nvm.sh"
nvm install 22
yes | corepack enable pnpm
