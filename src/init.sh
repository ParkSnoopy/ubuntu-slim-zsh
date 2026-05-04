#!/bin/env bash

sudo apt update
sudo apt install -y ca-certificates apt-transport-https
sudo sed -i 's|http://|https://|g' /etc/apt/sources.list.d/*
sudo sed -i 's|https://archive.ubuntu.com/ubuntu|https://kr.archive.ubuntu.com/ubuntu|g'  /etc/apt/sources.list.d/*
sudo sed -i 's|https://security.ubuntu.com/ubuntu|https://kr.archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list.d/*
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget nano zip unzip git python3 python-is-python3 python3-pip
python -m pip install --break-system-packages uv ruff
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="eastwood"/g' $HOME/.zshrc
curl -fsSL https://bun.sh/install | bash

echo
echo "--------------------"
echo "Restart container to take effect"
echo "--------------------"

rm $0
