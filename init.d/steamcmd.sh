#!/bin/env bash
set -euo pipefail

STEAMCMD_ARCHIVE_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"

prompt_with_default() {
	local prompt="$1"
	local default_value="$2"
	local reply

	printf '%s [%s]: ' "$prompt" "$default_value"
	if ! read -r reply; then
		reply=
	fi

	if [ -z "$reply" ]; then
		printf '%s\n' "$default_value"
	else
		printf '%s\n' "$reply"
	fi
}

require_numeric_app_ids() {
	local app_id

	for app_id in "$@"; do
		case "$app_id" in
			''|*[!0-9]*)
				echo "Invalid Steam app ID: $app_id" >&2
				exit 1
				;;
		esac
	done
}

write_runner_script() {
	local app_id="$1"
	local install_dir="$2"
	local runner_path="$install_dir/run.sh"
	local runner_tmp

	runner_tmp="$(mktemp "${TMPDIR:-/tmp}/steamcmd-runner-$app_id.XXXXXX")"

	cat > "$runner_tmp" <<'RUNNER_EOF'
#!/bin/env bash
set -euo pipefail

STEAMCMD="__STEAMCMD__"
APP_ID="__APP_ID__"
INSTALL_DIR="__INSTALL_DIR__"
STEAM_LOGIN="anonymous"

# Fill this with the game server command after install, for example:
# SERVER_RUN_COMMAND=(./server_binary -port 27015)
SERVER_RUN_COMMAND=()

"$STEAMCMD" \
	+force_install_dir "$INSTALL_DIR" \
	+login "$STEAM_LOGIN" \
	+app_update "$APP_ID" validate \
	+quit

cd "$INSTALL_DIR"

if [ "$#" -gt 0 ]; then
	exec "$@"
fi

if [ "${#SERVER_RUN_COMMAND[@]}" -gt 0 ]; then
	exec "${SERVER_RUN_COMMAND[@]}"
fi

echo "Updated Steam app $APP_ID in $INSTALL_DIR."
echo "Edit $0 and set SERVER_RUN_COMMAND=(...), or pass a command to run:"
echo "  $0 ./server_binary ..."
exit 1
RUNNER_EOF

	sed -i \
		-e "s|__STEAMCMD__|$STEAMCMD_DIR/steamcmd.sh|g" \
		-e "s|__APP_ID__|$app_id|g" \
		-e "s|__INSTALL_DIR__|$install_dir|g" \
		"$runner_tmp"
	sudo install -o "$STEAM_LOCAL_USER" -g "$USER_GROUP" -m 755 "$runner_tmp" "$runner_path"
	rm -f "$runner_tmp"
}

sudo apt update
sudo apt install -y ca-certificates curl tar lib32gcc-s1 lib32stdc++6

STEAM_LOCAL_USER="$(prompt_with_default 'Local Unix user for SteamCMD' 'steam')"

if [ "$STEAM_LOCAL_USER" = root ]; then
	echo "SteamCMD should run as an unprivileged local user, not root." >&2
	exit 1
fi

if ! id "$STEAM_LOCAL_USER" >/dev/null 2>&1; then
	sudo useradd -m -s /bin/bash "$STEAM_LOCAL_USER"
fi

USER_HOME="$(getent passwd "$STEAM_LOCAL_USER" | cut -d: -f6)"
USER_GROUP="$(id -gn "$STEAM_LOCAL_USER")"
STEAMCMD_DIR="$USER_HOME/steamcmd"
SERVER_BASE_DIR="$(prompt_with_default 'Game server base directory' "$USER_HOME/steam-servers")"

printf 'Steam app IDs to install/update (space-separated): '
if ! read -r STEAM_APP_IDS; then
	STEAM_APP_IDS=
fi

if [ -z "$STEAM_APP_IDS" ]; then
	echo "At least one Steam app ID is required." >&2
	exit 1
fi

# shellcheck disable=SC2086
require_numeric_app_ids $STEAM_APP_IDS

ARCHIVE_PATH="$(mktemp "${TMPDIR:-/tmp}/steamcmd.XXXXXX.tar.gz")"
trap 'rm -f "$ARCHIVE_PATH"' EXIT

sudo install -d -o "$STEAM_LOCAL_USER" -g "$USER_GROUP" "$STEAMCMD_DIR" "$SERVER_BASE_DIR"
curl --proto '=https' --tlsv1.2 -fsSL "$STEAMCMD_ARCHIVE_URL" -o "$ARCHIVE_PATH"
chmod 0644 "$ARCHIVE_PATH"
sudo -u "$STEAM_LOCAL_USER" tar -xzf "$ARCHIVE_PATH" -C "$STEAMCMD_DIR"
sudo -H -u "$STEAM_LOCAL_USER" "$STEAMCMD_DIR/steamcmd.sh" +quit

sudo ln -sf "$STEAMCMD_DIR/steamcmd.sh" /usr/local/bin/steamcmd

if [ -e "$STEAMCMD_DIR/linux32/steamclient.so" ]; then
	sudo -u "$STEAM_LOCAL_USER" ln -sf "$STEAMCMD_DIR/linux32/steamclient.so" "$STEAMCMD_DIR/steamservice.so"
	sudo -u "$STEAM_LOCAL_USER" install -d "$USER_HOME/.steam/sdk32"
	sudo -u "$STEAM_LOCAL_USER" ln -sf "$STEAMCMD_DIR/linux32/steamclient.so" "$USER_HOME/.steam/sdk32/steamclient.so"
	sudo -u "$STEAM_LOCAL_USER" ln -sf "$STEAMCMD_DIR/linux32/steamcmd" "$STEAMCMD_DIR/linux32/steam"
fi

if [ -e "$STEAMCMD_DIR/linux64/steamclient.so" ]; then
	sudo -u "$STEAM_LOCAL_USER" install -d "$USER_HOME/.steam/sdk64"
	sudo -u "$STEAM_LOCAL_USER" ln -sf "$STEAMCMD_DIR/linux64/steamclient.so" "$USER_HOME/.steam/sdk64/steamclient.so"
	sudo -u "$STEAM_LOCAL_USER" ln -sf "$STEAMCMD_DIR/linux64/steamcmd" "$STEAMCMD_DIR/linux64/steam"
	sudo ln -sf "$STEAMCMD_DIR/linux64/steamclient.so" /usr/lib/x86_64-linux-gnu/steamclient.so
fi

# shellcheck disable=SC2086
for app_id in $STEAM_APP_IDS; do
	install_dir="$SERVER_BASE_DIR/$app_id"
	sudo install -d -o "$STEAM_LOCAL_USER" -g "$USER_GROUP" "$install_dir"
	sudo -H -u "$STEAM_LOCAL_USER" "$STEAMCMD_DIR/steamcmd.sh" \
		+force_install_dir "$install_dir" \
		+login anonymous \
		+app_update "$app_id" validate \
		+quit
	write_runner_script "$app_id" "$install_dir"
done
