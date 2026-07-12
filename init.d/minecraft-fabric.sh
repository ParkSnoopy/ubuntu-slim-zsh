#!/bin/env bash
set -euo pipefail

FABRIC_META_GAME="https://meta.fabricmc.net/v2/versions/game"
FABRIC_META_LOADER="https://meta.fabricmc.net/v2/versions/loader"
FABRIC_META_INSTALLER="https://meta.fabricmc.net/v2/versions/installer"
FABRIC_MAVEN_BASE="https://maven.fabricmc.net/net/fabricmc/fabric-installer"
MAX_RAM="${MINECRAFT_MAX_RAM:-6G}"
INSTALL_DIR="${MINECRAFT_INSTALL_DIR:-/apps/minecraft-fabric}"

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

fetch_stable_game_versions() {
	curl --proto '=https' --tlsv1.2 -fsSL "$FABRIC_META_GAME" |
		sed -n 's/^[[:space:]]*"version": "\([^"]*\)",$/\1/p' |
		awk 'NR==FNR{next}'
}

fetch_stable_loader_version() {
	curl --proto '=https' --tlsv1.2 -fsSL "$FABRIC_META_LOADER" |
		sed -n 's/^[[:space:]]*"version": "\([^"]*\)",$/\1/p' |
		head -n 1
}

fetch_stable_installer_url() {
	curl --proto '=https' --tlsv1.2 -fsSL "$FABRIC_META_INSTALLER" |
		sed -n 's/^[[:space:]]*"url": "\([^"]*\)",$/\1/p' |
		head -n 1
}

sudo apt update
sudo apt install -y curl sed openjdk-25-jre-headless

LATEST_GAME_VERSION="$(curl --proto '=https' --tlsv1.2 -fsSL "$FABRIC_META_GAME" |
	sed -n '/"stable": true/{ s/^[[:space:]]*"version": "\([^"]*\)",$/\1/p; q }')"

LATEST_LOADER_VERSION="$(fetch_stable_loader_version)"
INSTALLER_URL="$(fetch_stable_installer_url)"

printf '\nLatest stable Minecraft version: %s\n' "$LATEST_GAME_VERSION" >&2
printf 'Latest Fabric loader version: %s\n' "$LATEST_LOADER_VERSION" >&2
printf 'Latest Fabric installer: %s\n\n' "$INSTALLER_URL" >&2

MC_VERSION="$(prompt_with_default 'Minecraft version' "$LATEST_GAME_VERSION")"
LOADER_VERSION="$(prompt_with_default 'Fabric loader version' "$LATEST_LOADER_VERSION")"
INSTALL_DIR="$(prompt_with_default 'Install directory' "$INSTALL_DIR")"

INSTALLER_JAR="${INSTALLER_URL##*/}"

sudo install -d "$INSTALL_DIR"
INSTALLER_PATH="$INSTALL_DIR/$INSTALLER_JAR"
curl --proto '=https' --tlsv1.2 -fsSL "$INSTALLER_URL" -o "$INSTALLER_PATH"

java -jar "$INSTALLER_PATH" server \
	-mcversion "$MC_VERSION" \
	-loader "$LOADER_VERSION" \
	-dir "$INSTALL_DIR" \
	-downloadMinecraft

cat > "$INSTALL_DIR/run.sh" <<EOF
#!/bin/env bash
set -euo pipefail

MC_VERSION="$MC_VERSION"
LOADER_VERSION="$LOADER_VERSION"
MAX_RAM="${MAX_RAM}"
INSTALL_DIR="$INSTALL_DIR"

cd "\$INSTALL_DIR"

exec java -Xmx\$MAX_RAM -jar fabric-server-launch.jar nogui
EOF
chmod +x "$INSTALL_DIR/run.sh"

rm -f "$INSTALL_DIR/run.bat"