#!/bin/env bash
set -euo pipefail

NEOFORGE_MAVEN_BASE="https://maven.neoforged.net/releases/net/neoforged/neoforge"
NEOFORGE_VERSIONS_API="https://maven.neoforged.net/releases/net/neoforged/neoforge/maven-metadata.xml"
MAX_RAM="${MINECRAFT_MAX_RAM:-6G}"
INSTALL_DIR="${MINECRAFT_INSTALL_DIR:-/apps/minecraft-neoforge}"

prompt_with_default() {
	local prompt="$1"
	local default_value="$2"
	local reply

	printf '\n%s [%s]: ' "$prompt" "$default_value" >&2
	if ! read -r reply; then
		reply=
	fi

	if [ -z "$reply" ]; then
		printf '%s\n' "$default_value"
	else
		printf '%s\n' "$reply"
	fi
}

fetch_latest_neoforge_version() {
	curl --proto '=https' --tlsv1.2 -fsSL "$NEOFORGE_VERSIONS_API" |
		sed -n 's/.*<version>\([^<]*\)<\/version>.*/\1/p' |
		grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' |
		tail -n 1
}

sudo apt update
sudo apt install -y curl sed openjdk-25-jre-headless

LATEST_NEOFORGE_VERSION="$(fetch_latest_neoforge_version)"

printf '\nLatest NeoForge version: %s\n' "$LATEST_NEOFORGE_VERSION" >&2
printf 'Installer URL: %s/%s/neoforge-%s-installer.jar\n\n' \
	"$NEOFORGE_MAVEN_BASE" "$LATEST_NEOFORGE_VERSION" "$LATEST_NEOFORGE_VERSION" >&2

NEOFORGE_VERSION="$(prompt_with_default 'NeoForge version' "$LATEST_NEOFORGE_VERSION")"
INSTALL_DIR="$(prompt_with_default 'Install directory' "$INSTALL_DIR")"

INSTALLER_URL="$NEOFORGE_MAVEN_BASE/$NEOFORGE_VERSION/neoforge-$NEOFORGE_VERSION-installer.jar"
INSTALLER_JAR="neoforge-$NEOFORGE_VERSION-installer.jar"

sudo install -d "$INSTALL_DIR"
INSTALLER_PATH="$INSTALL_DIR/$INSTALLER_JAR"
curl --proto '=https' --tlsv1.2 -fsSL "$INSTALLER_URL" -o "$INSTALLER_PATH"

cd "$INSTALL_DIR"
java -jar "$INSTALLER_JAR" --installServer

# NeoForge bundles its own run.sh; just set max RAM in user_jvm_args.txt
if [ -f "$INSTALL_DIR/user_jvm_args.txt" ]; then
	if ! grep -q '^Xmx' "$INSTALL_DIR/user_jvm_args.txt" 2>/dev/null; then
		printf 'Xmx%s\n' "$MAX_RAM" >> "$INSTALL_DIR/user_jvm_args.txt"
	fi
fi

rm -f "$INSTALL_DIR/run.bat"