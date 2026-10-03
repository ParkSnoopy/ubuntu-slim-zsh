#!/bin/env bash
set -euo pipefail

META="https://meta.fabricmc.net/v2/versions"
. "${INIT_NIX_HELPER:-$(dirname "$0")/_nix.sh}"
nix-env --file "$NIXPKGS_URL" --install --attr curl jdk25
INSTALL_DIR="${MINECRAFT_INSTALL_DIR:-/apps/minecraft-fabric}"
MAX_RAM="${MINECRAFT_MAX_RAM:-6G}"

prompt() {
	local label="$1" default="$2" value
	printf '\n%s [%s]: ' "$label" "$default" >&2
	read -r value || true
	printf '%s\n' "${value:-$default}"
}

latest_stable() {
	curl --proto '=https' --tlsv1.2 -fsSL "$1" |
		awk -F'"' '/"version"/{version=$4} /"stable": true/ && !found {print version; found=1}'
}

LATEST_MINECRAFT="$(latest_stable "$META/game")"
MINECRAFT_VERSION="$(prompt 'Minecraft version' "$LATEST_MINECRAFT")"
INSTALL_DIR="$(prompt 'Install directory' "$INSTALL_DIR")"
LOADER_VERSION="$(latest_stable "$META/loader/$MINECRAFT_VERSION")"
INSTALLER_VERSION="$(latest_stable "$META/installer")"
SERVER_JAR_URL="$META/loader/$MINECRAFT_VERSION/$LOADER_VERSION/$INSTALLER_VERSION/server/jar"

sudo install -d "$INSTALL_DIR"
curl --proto '=https' --tlsv1.2 -fsSL "$SERVER_JAR_URL" -o "$INSTALL_DIR/fabric-server-launch.jar"

cat > "$INSTALL_DIR/run.sh" <<EOF
#!/bin/env bash
set -euo pipefail
cd "$INSTALL_DIR"
exec java -Xmx$MAX_RAM -jar fabric-server-launch.jar nogui
EOF
chmod +x "$INSTALL_DIR/run.sh"
