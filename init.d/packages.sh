#!/bin/env bash
set -euo pipefail

# Basic Tools
sudo apt update
sudo apt upgrade -y
sudo apt install -y man-db curl wget nano zip unzip git tree
