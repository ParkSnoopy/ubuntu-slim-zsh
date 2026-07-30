#!/bin/env bash
set -euo pipefail

sudo apt install -y ca-certificates apt-transport-https

source_lists=(
	/etc/apt/sources.list
	/etc/apt/sources.list.d/*.list
	/etc/apt/sources.list.d/*.sources
)

for source_list in "${source_lists[@]}"; do
	[[ -f "$source_list" ]] || continue
	sudo sed -i 's|http://|https://|g' "$source_list"
done
