# Private API Keys

# uv
#export UV_LINK_MODE="copy"

# Flutter
#export PATH="$HOME/.flutter/bin:$PATH"
#export CHROME_EXECUTABLE="microsoft-edge"

# Android SDK
#export ANDROID_HOME="$HOME/.android-tools"
#export ANDROID_SDK_ROOT="$ANDROID_HOME"
#export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# Nix tools are installed in the current user's profile.
if [ -r "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
	. "$HOME/.nix-profile/etc/profile.d/nix.sh"
elif [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
	. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
if [ -d "$HOME/.nix-profile/bin" ]; then
	export PATH="$HOME/.nix-profile/bin:$PATH"
	if [ "$EUID" -eq 0 ] && ! getent group nixbld >/dev/null; then
		export NIX_CONFIG="${NIX_CONFIG:-}
build-users-group ="
	fi
fi

# Rust
#source "$HOME/.cargo/env"

# ====================

# Open GUI App from Podman
#export GDK_BACKEND="wayland"
#export XDG_RUNTIME_DIR="/tmp"
#export WAYLAND_DISPLAY="wayland-0"

# Environment
export TZ="Asia/Shanghai"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export TAR_OPTIONS="--no-same-owner"
