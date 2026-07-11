#!/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y python3 python-is-python3 python3-pip

python -m pip install --break-system-packages uv ruff
