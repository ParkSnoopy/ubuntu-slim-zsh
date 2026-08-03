#!/bin/env bash
set -euo pipefail

sudo apt install -y curl unzip wget

curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh
