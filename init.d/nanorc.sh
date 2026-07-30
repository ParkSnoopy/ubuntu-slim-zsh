#!/bin/env bash
set -euo pipefail

sudo apt install -y curl

curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh
