#!/bin/env bash
set -euo pipefail

MAVEN="https://maven.neoforged.net/releases/net/neoforged/neoforge"
INSTALL_DIR="${MINECRAFT_INSTALL_DIR:-/apps/minecraft-neoforge}"
MAX_RAM="${MINECRAFT_MAX_RAM:-6G}"

prompt() {
	local label="$1" default="$2" value
	printf '\n%s [%s]: ' "$label" "$default" >&2
	read -r value || true
	printf '%s\n' "${value:-$default}"
}

METADATA="$(curl --proto '=https' --tlsv1.2 -fsSL "$MAVEN/maven-metadata.xml")"
LATEST_NEOFORGE="$(printf '%s\n' "$METADATA" |
	sed -n 's/.*<version>\([^<]*\)<\/version>.*/\1/p' | tail -n 1)"
LATEST_MAJOR="${LATEST_NEOFORGE%%.*}"
LATEST_REMAINDER="${LATEST_NEOFORGE#*.}"
LATEST_MINOR="${LATEST_REMAINDER%%.*}"
if [ "$LATEST_MAJOR" -ge 26 ]; then
	LATEST_MINECRAFT="$LATEST_MAJOR.$LATEST_MINOR"
else
	LATEST_MINECRAFT="1.$LATEST_MAJOR.$LATEST_MINOR"
fi

MINECRAFT_VERSION="$(prompt 'Minecraft version' "$LATEST_MINECRAFT")"
INSTALL_DIR="$(prompt 'Install directory' "$INSTALL_DIR")"
VERSION_PREFIX="${MINECRAFT_VERSION#1.}"
NEOFORGE_VERSION="$(printf '%s\n' "$METADATA" |
	sed -n 's/.*<version>\([^<]*\)<\/version>.*/\1/p' |
	awk -v prefix="$VERSION_PREFIX." 'index($0, prefix) == 1 {version=$0} END {print version}')"

if [ -z "$NEOFORGE_VERSION" ]; then
	echo "No NeoForge release found for Minecraft $MINECRAFT_VERSION." >&2
	exit 1
fi

sudo apt install -y openjdk-25-jdk
sudo install -d "$INSTALL_DIR"
cd "$INSTALL_DIR"
curl --proto '=https' --tlsv1.2 -fsSL \
	"$MAVEN/$NEOFORGE_VERSION/neoforge-$NEOFORGE_VERSION-installer.jar" \
	-o neoforge-installer.jar
java -jar neoforge-installer.jar --installServer

if grep -q '^-Xmx' user_jvm_args.txt; then
	sed -i "s/^-Xmx.*/-Xmx$MAX_RAM/" user_jvm_args.txt
else
	printf '%s\n' "-Xmx$MAX_RAM" >> user_jvm_args.txt
fi
rm -f run.bat
