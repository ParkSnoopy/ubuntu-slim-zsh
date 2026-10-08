#!/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/init-check.XXXXXX")"
trap 'rm -rf "$CHECK_DIR"' EXIT
export ROOT CHECK_DIR
export HOME="$CHECK_DIR/home" TMPDIR="$CHECK_DIR/tmp" NO_COLOR=1
export COMMAND_LOG="$CHECK_DIR/commands"
export CURL_FAIL=false APT_FAIL=false UPDATE_INVALID=false UPDATE_HASH=b1ec88e
mkdir -p "$HOME" "$TMPDIR"
touch "$COMMAND_LOG"

# Controlled command fixtures: no package installation or upstream requests.
sudo() {
	echo "sudo $*" >> "$COMMAND_LOG"
	if [ "$APT_FAIL" = true ] && [ "$*" = 'apt install -y golang' ]; then
		return 7
	fi
}

python() {
	echo "python $*" >> "$COMMAND_LOG"
}

curl() {
	local url= output=
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-o) output="$2"; shift 2 ;;
			https://*) url="$1"; shift ;;
			*) shift ;;
		esac
	done
	echo "curl $url" >> "$COMMAND_LOG"
	[ "$CURL_FAIL" = false ] || return 23
	case "$url" in
		*/commits/*)
			echo '{'
			echo "  \"sha\": \"$UPDATE_HASH\","
			echo '  "fixture": true'
			echo '}'
			;;
		*/init.d/*.bash) cp "$ROOT/init.d/${url##*/}" "$output" ;;
		*/src/.zshenv) cp "$ROOT/src/.zshenv" "$output" ;;
		*/src/_init.bash) return 23 ;;
		*/init.bash)
			if [ "$UPDATE_INVALID" = true ]; then
				echo 'if' > "$output"
				return 0
			fi
			cp "$ROOT/init.bash" "$output"
			;;
		*) return 23 ;;
	esac
}
export -f sudo python curl

run() {
	local expected="$1" status=0
	shift
	OUTPUT="$(bash "$ROOT/init.bash" "$@" </dev/null 2>&1)" || status=$?
	if [ "$status" != "$expected" ]; then
		echo "$OUTPUT" >&2
		echo "Expected status $expected; received $status for $*." >&2
		exit 1
	fi
}

run 0 --help
run 0 install --help
run 0 update --help
run 0 --list
[ "$(echo "$OUTPUT" | wc -l)" -eq 17 ]
while IFS= read -r topic; do
	[ -f "$ROOT/init.d/$topic.bash" ]
done <<< "$OUTPUT"
completion_topics="$(zsh -f -ec '
	fpath=("$ROOT/src" $fpath)
	autoload -Uz compinit
	compinit -D
	[[ ${_comps[init.bash]} == _init.bash ]]
	_arguments() { state=topics; return 1; }
	_describe() { print -l -- "${topics[@]}"; }
	_init.bash
')"
while IFS= read -r topic; do
	[[ "$completion_topics" == *"$topic:"* ]]
done <<< "$OUTPUT"
run 0 install git-config packages git-config apt-https --exclude apt-https --dry-run
[[ "$OUTPUT" == *'Preview topic: packages'*'Preview topic: git-config'* ]]
[[ "$OUTPUT" != *'Preview topic: apt-https'* ]]
[ "$(echo "$OUTPUT" | grep -c 'Preview topic: git-config')" -eq 1 ]
run 0 --dry-run
[[ "$OUTPUT" == *'Preview topic: unminimize'*'Preview topic: apt-https'*'Preview topic: packages'*'Preview topic: oh-my-zsh'* ]]
run 0 install oh-my-zsh oh-my-tmux --dry-run
[[ "$OUTPUT" == *'Preview topic: oh-my-zsh'*'Preview topic: oh-my-tmux'* ]]
run 0 install '*' --exclude '*' --dry-run
[ "$OUTPUT" = '' ]
run 1 install unknown --dry-run
run 1 install omz --dry-run
run 1 install omt --dry-run
run 1 install
run 1 update extra
run 0 install golang
[[ "$OUTPUT" == *'Proceed? [y/N]'*'Cancelled.'* ]]
[ ! -s "$COMMAND_LOG" ]

run 0 install golang -y
[[ "$OUTPUT" == *'Topic complete: golang'* ]]
OUTPUT="$(echo y | bash "$ROOT/init.bash" install golang 2>&1)"
[[ "$OUTPUT" == *'Topic complete: golang'* ]]
APT_FAIL=true run 1 install golang python-uv -y
[[ "$OUTPUT" == *'Topic failed: golang'*'Topic complete: python-uv'*'Failed topics: golang'* ]]
CURL_FAIL=true run 1 install golang -y
[[ "$OUTPUT" == *'Topic failed: golang'* ]]

run 0 update
[[ "$OUTPUT" == *'Already up to date'*'Update '*'.zshenv? [y/N]'*'Skipped '* ]]
[ ! -e "$HOME/.zshenv" ]
OUTPUT="$(echo y | bash "$ROOT/init.bash" update 2>&1)"
cmp "$ROOT/src/.zshenv" "$HOME/.zshenv"
UPDATE_HASH=1111111111111111111111111111111111111111 run 0 update
[ -x "$HOME/init.bash" ]
bash -n "$HOME/init.bash"
cmp "$HOME/init.bash" <(sed 's/^CURRENT_COMMIT_HASH="[0-9a-f]*"/CURRENT_COMMIT_HASH="1111111"/' "$ROOT/init.bash")
UPDATE_INVALID=true UPDATE_HASH=2222222222222222222222222222222222222222 run 2 update
cmp "$HOME/init.bash" <(sed 's/^CURRENT_COMMIT_HASH="[0-9a-f]*"/CURRENT_COMMIT_HASH="1111111"/' "$ROOT/init.bash")

CURL_FAIL=true
for topic in js-bun js-node-22 js-node-24 nanorc oh-my-zsh; do
	status=0
	bash "$ROOT/init.d/$topic.bash" >/dev/null 2>&1 || status=$?
	[ "$status" -eq 23 ]
done
shopt -s nullglob
temporary_files=("$TMPDIR"/*)
[ "${#temporary_files[@]}" -eq 0 ]
echo 'Installer selection, execution, failure, update, and download guards passed.'