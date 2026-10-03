#!/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/init-test.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
export ROOT HOME="$TEST_DIR/home" LOG="$TEST_DIR/commands"
mkdir -p "$HOME"

# These doubles exercise dispatch and failure propagation, not package builds.
curl() {
	local url= output=
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-o) output="$2"; shift 2 ;;
			https://*) url="$1"; shift ;;
			*) shift ;;
		esac
	done
	echo "curl $url" >> "$LOG"
	case "$url" in
		*/init.d/*.sh) cp "$ROOT/init.d/${url##*/}" "$output" ;;
		*) echo "Unexpected download: $url" >&2; return 1 ;;
	esac
}
nix-env() {
	echo "nix-env $*" >> "$LOG"
	[ "$1" = --version ] || [ "${FAIL_INSTALL:-false}" = false ]
}
sudo() {
	echo "sudo $*" >> "$LOG"
	return 1
}
export -f curl nix-env sudo

for command in install update; do
	for flag in --help -h; do
		help="$(bash "$ROOT/init.sh" "$command" "$flag")"
		[[ "$help" == *"init.sh $command"* ]]
		test ! -e "$LOG"
	done
done
help="$(bash "$ROOT/init.sh" install golang --help)"
[[ "$help" == *'init.sh install'* ]]

preview="$(bash "$ROOT/init.sh" install golang js-node-22 --dry-run)"
[[ "$preview" == *'nix-env --file "$NIXPKGS_URL" --install --attr go'*'nix-env --file "$NIXPKGS_URL" --install --attr nodejs_22 pnpm'* ]]
[[ "$preview" != *'sudo apt update'* ]]
[[ "${preview#*'. init.d/_nix.sh'}" != *'. init.d/_nix.sh'* ]]
preview="$(bash "$ROOT/init.sh" install xtradeb golang --dry-run)"
[[ "$preview" == *'sudo apt update'*'. init.d/_nix.sh'* ]]
preview="$(bash "$ROOT/init.sh" install '*' --exclude '*' --dry-run)"
[[ "$preview" != *'sudo apt update'* && "$preview" != *'. init.d/_nix.sh'* ]]

. "$ROOT/init.d/_nix.sh"
[[ "$NIXPKGS_URL" =~ /[0-9a-f]{40}\.tar\.gz$ ]]
rm -f "$LOG"

bash "$ROOT/init.sh" install golang js-node-22 js-node-24 -y
helper_downloads=0
while IFS= read -r record; do
	case "$record" in
		'curl '*/_nix.sh) helper_downloads=$((helper_downloads + 1)) ;;
		'sudo '*) echo 'Nix-only selection invoked sudo.' >&2; exit 1 ;;
		'nix-env --file '*) [[ "$record" == "nix-env --file $NIXPKGS_URL --install --attr "* ]] ;;
	esac
done < "$LOG"
[[ "$helper_downloads" -eq 1 ]]

export FAIL_INSTALL=true
if bash "$ROOT/init.sh" install golang -y; then
	echo 'A failed Nix installation reported success.' >&2
	exit 1
fi

unset FAIL_INSTALL
bash "$ROOT/init.d/js-node-24.sh"

if command -v zsh >/dev/null; then
	mkdir -p "$HOME/.nix-profile/bin"
	NIX_CONFIG='sandbox = false' zsh -e -c '
		getent() { return 1; }
		. "$ROOT/src/.zshenv"
		if [ "$EUID" -eq 0 ]; then
			expected="sandbox = false
build-users-group ="
			[[ "$NIX_CONFIG" == "$expected" ]]
		else
			[[ "$NIX_CONFIG" == "sandbox = false" ]]
		fi
	'
fi

bash "$ROOT/init.sh" --list | while IFS= read -r topic; do
	test -f "$ROOT/init.d/$topic.sh"
	bash -n "$ROOT/init.d/$topic.sh"
	preview="$(bash "$ROOT/init.sh" install "$topic" --dry-run)"
	while IFS= read -r command; do
		case "$command" in
			'nix-env --file '*) [[ "$preview" == *"$command"* ]] ;;
		esac
	done < "$ROOT/init.d/$topic.sh"
done
for script in "$ROOT/init.sh" "$ROOT/src/init.sh" "$ROOT/init.d/_nix.sh"; do
	bash -n "$script"
done
echo 'Installer integration checks passed.'
