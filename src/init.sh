#!/bin/env bash

# Change Repo: 'kr.archive.ubuntu.com/ubuntu'
sudo sed -i  's|http://archive.ubuntu.com/ubuntu|http://kr.archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list.d/*
sudo sed -i 's|http://security.ubuntu.com/ubuntu|http://kr.archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list.d/*

# fetch init script from GitHub
sudo apt update
sudo apt install -y curl
curl https://raw.githubusercontent.com/ParkSnoopy/ubuntu-slim-zsh/refs/heads/main/init.sh | bash

# remove self
rm $0
