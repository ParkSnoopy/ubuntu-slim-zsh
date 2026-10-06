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
preview="$(bash "$ROOT/init.sh" install playit-gg --dry-run)"
[[ "$preview" == *'Playit 0.17.1'*'nix-env --file "$NIXPKGS_URL" --install --from-expression "$PLAYIT_EXPRESSION"'* ]]
[[ "$preview" != *'sudo apt update'* ]]
test ! -e "$LOG"

. "$ROOT/init.d/_nix.sh"
[[ "$NIXPKGS_URL" =~ /[0-9a-f]{40}\.tar\.gz$ ]]
rm -f "$LOG"

bash "$ROOT/init.sh" install golang js-node-22 js-node-24 playit-gg -y
helper_downloads=0
while IFS= read -r record; do
	case "$record" in
		'curl '*/_nix.sh) helper_downloads=$((helper_downloads + 1)) ;;
		'sudo '*) echo 'Nix-only selection invoked sudo.' >&2; exit 1 ;;
		'nix-env --file '*) [[ "$record" == "nix-env --file $NIXPKGS_URL --install --attr "* || "$record" == "nix-env --file $NIXPKGS_URL --install --from-expression "* ]] ;;
	esac
done < "$LOG"
[[ "$helper_downloads" -eq 1 ]]

export FAIL_INSTALL=true
for topic in golang playit-gg; do
	if bash "$ROOT/init.sh" install "$topic" -y; then
		echo 'A failed Nix installation reported success.' >&2
		exit 1
	fi
done

unset FAIL_INSTALL
bash "$ROOT/init.d/js-node-24.sh"

(
	# Terminal output from read must never become a version or directory value.
	read() { printf '\033[?2004h\033[?2004l'; builtin read "$@"; }
	sudo() { [ "$1" = install ]; "$@"; }
	curl() {
		local url= output=
		while [ "$#" -gt 0 ]; do
			case "$1" in
				-o) output="$2"; shift 2 ;;
				https://*) url="$1"; shift ;;
				*) shift ;;
			esac
		done
		echo "$url" >> "$LOG"
		case "$url" in
			*/game) echo $'[{\n"version": "26.3",\n"stable": true\n}]' ;;
			*/loader/26.3|*/loader/1.21.1|*/installer)
				echo $'[{\n"version": "1.0.0",\n"stable": true\n}]' ;;
			*/maven-metadata.xml)
				echo $'<version>21.1.1</version>\n<version>26.3.0.1</version>' ;;
			*/server/jar|*/neoforge-*-installer.jar) touch "$output" ;;
			*) echo "Unexpected download: $url" >&2; return 1 ;;
		esac
	}
	java() { touch run.sh run.bat user_jvm_args.txt; }
	export -f read sudo curl java
	export INIT_NIX_HELPER="$ROOT/init.d/_nix.sh"
	for topic in minecraft-fabric minecraft-neoforge; do
		for version in '' 1.21.1; do
			export MINECRAFT_INSTALL_DIR="$TEST_DIR/$topic/default"
			directory="$TEST_DIR/$topic/custom path"
			if [ -z "$version" ]; then directory="$MINECRAFT_INSTALL_DIR"; fi
			printf '%s\n%s\n' "$version" "${version:+$directory}" | bash "$ROOT/init.d/$topic.sh"
			test -f "$directory/run.sh"
			test ! -e "$directory/run.bat"
			if [ "$topic" = minecraft-fabric ]; then
				test -f "$directory/fabric-server-launch.jar"
			else
				[[ "$(< "$directory/user_jvm_args.txt")" == '-Xmx6G' ]]
			fi
		done
	done
)

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
