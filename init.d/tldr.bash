#!/bin/env bash
set -euo pipefail

sudo apt install -y python3 python3-pip

python3 -m pip install --break-system-packages tldr
