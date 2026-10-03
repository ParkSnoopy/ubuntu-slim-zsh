#!/bin/env bash

# All tool topics use the same immutable Nixpkgs snapshot, without channels.
NIXPKGS_URL="https://github.com/NixOS/nixpkgs/archive/774debe7a0d1b496e35677ad955a1011c6ff74f3.tar.gz"
NIX_INSTALLER_URL="https://releases.nixos.org/nix/nix-2.24.14/install"
NIX_INSTALLER_SHA256="00f90bcea17b7d89af1efa4452221403054aad8765759cef8dae1cd3c474abc8"

ensure_nix() {
	local installer

	if [ -s "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
		. "$HOME/.nix-profile/etc/profile.d/nix.sh"
	elif [ -s /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
	fi

	# Single-user root containers have no build-user group or running daemon.
	if [ "$(id -u)" -eq 0 ] && ! getent group nixbld >/dev/null; then
		export NIX_CONFIG="${NIX_CONFIG:-}
build-users-group ="
	fi

	if ! command -v nix-env >/dev/null; then
		installer="$(mktemp "${TMPDIR:-/tmp}/nix-install.XXXXXX")"
		if ! curl --proto '=https' --tlsv1.2 -fsSL "$NIX_INSTALLER_URL" -o "$installer"; then
			rm -f "$installer"
			return 1
		fi
		if ! printf '%s  %s\n' "$NIX_INSTALLER_SHA256" "$installer" | sha256sum --check --status; then
			echo 'Nix installer checksum mismatch.' >&2
			rm -f "$installer"
			return 1
		fi
		if ! sh "$installer" --no-daemon --yes --no-channel-add --no-modify-profile; then
			rm -f "$installer"
			return 1
		fi
		rm -f "$installer"
		. "$HOME/.nix-profile/etc/profile.d/nix.sh"
	fi

	export PATH="$HOME/.nix-profile/bin:$PATH"
	nix-env --version >/dev/null
}

nix_install() {
	ensure_nix
	nix-env --file "$NIXPKGS_URL" --install --attr "$@"
}
