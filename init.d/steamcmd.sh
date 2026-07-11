#!/bin/env bash
set -euo pipefail

STEAMCMD_ARCHIVE_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
STEAM_LOCAL_USER="${STEAM_LOCAL_USER:-steam}"
STEAMCMD_BIN="${STEAMCMD_BIN:-/usr/local/bin/steamcmd}"

if [ "$STEAM_LOCAL_USER" = root ]; then
	echo "SteamCMD should run as an unprivileged local user, not root." >&2
	exit 1
fi

sudo apt update
sudo apt install -y ca-certificates curl sudo tar lib32gcc-s1 lib32stdc++6

if ! id "$STEAM_LOCAL_USER" >/dev/null 2>&1; then
	sudo useradd -m -s /bin/bash "$STEAM_LOCAL_USER"
fi

USER_HOME="$(getent passwd "$STEAM_LOCAL_USER" | cut -d: -f6)"
USER_GROUP="$(id -gn "$STEAM_LOCAL_USER")"
STEAMCMD_DIR="$USER_HOME/steamcmd"
ARCHIVE_PATH="$(mktemp "${TMPDIR:-/tmp}/steamcmd.XXXXXX.tar.gz")"
WRAPPER_PATH="$(mktemp "${TMPDIR:-/tmp}/steamcmd-wrapper.XXXXXX")"
trap 'rm -f "$ARCHIVE_PATH" "$WRAPPER_PATH"' EXIT

sudo install -d -o "$STEAM_LOCAL_USER" -g "$USER_GROUP" "$STEAMCMD_DIR"
curl --proto '=https' --tlsv1.2 -fsSL "$STEAMCMD_ARCHIVE_URL" -o "$ARCHIVE_PATH"
chmod 0644 "$ARCHIVE_PATH"
sudo -u "$STEAM_LOCAL_USER" tar -xzf "$ARCHIVE_PATH" -C "$STEAMCMD_DIR"
sudo -H -u "$STEAM_LOCAL_USER" "$STEAMCMD_DIR/steamcmd.sh" +quit

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

cat > "$WRAPPER_PATH" <<EOF
#!/bin/env bash
set -euo pipefail

STEAM_LOCAL_USER="$STEAM_LOCAL_USER"
STEAMCMD="$STEAMCMD_DIR/steamcmd.sh"

if [ "\$(id -un)" = "\$STEAM_LOCAL_USER" ]; then
	exec "\$STEAMCMD" "\$@"
fi

exec sudo -H -u "\$STEAM_LOCAL_USER" "\$STEAMCMD" "\$@"
EOF

sudo install -m 755 "$WRAPPER_PATH" "$STEAMCMD_BIN"
