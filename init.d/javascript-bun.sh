#!/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y curl

# Bun
curl -fsSL https://bun.sh/install | bash
