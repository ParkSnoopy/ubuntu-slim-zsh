#!/bin/env bash
set -euo pipefail

BASE_URL="${INIT_BASE_URL:-https://raw.githubusercontent.com/ParkSnoopy/ubuntu-slim-zsh/refs/heads/main}"
GITHUB_REPOSITORY="${INIT_GITHUB_REPOSITORY:-ParkSnoopy/ubuntu-slim-zsh}"
GITHUB_BRANCH="${INIT_GITHUB_BRANCH:-main}"
CURRENT_COMMIT_HASH="b1ec88e"

if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
	BOLD=$'\033[1m'
	DIM=$'\033[2m'
	CYAN=$'\033[36m'
	GREEN=$'\033[32m'
	YELLOW=$'\033[33m'
	RED=$'\033[31m'
	RESET=$'\033[0m'
else
	BOLD=
	DIM=
	CYAN=
	GREEN=
	YELLOW=
	RED=
	RESET=
fi

AVAILABLE_TOPICS=(
	unminimize
	apt-https
	packages
	git-config
	nanorc
	python-uv
	tldr
	xtradeb
	oh-my-zsh
	js-node-22
	js-node-24
	js-bun
	golang
	steamcmd
	minecraft-fabric
	minecraft-neoforge
	oh-my-tmux
)

DEFAULT_TOPICS=(unminimize apt-https packages oh-my-zsh)
SELECTED_TOPICS=()
EXCLUDED_TOPICS=()
INSTALL_COMMAND=false
DRY_RUN=false
ASSUME_YES=false

usage() {
	cat <<EOF
${BOLD}${CYAN}ubuntu-slim-zsh init${RESET} ${DIM}(${CURRENT_COMMIT_HASH})${RESET}

${BOLD}Usage${RESET}
  init.bash [options]
  init.bash install topic ... [options]

${BOLD}Commands${RESET}
  install topic ...              install only selected topics; use '*' for all
  update                         compare commit hash and replace ~/init.bash if newer

${BOLD}Selection${RESET}
  --exclude topic ...            remove topics after selection

${BOLD}Run control${RESET}
  --dry-run                      preview core install commands only
  -y                             skip confirmation prompt
  --list                         print available topics
  -h, --help                     show this help

${BOLD}Defaults${RESET}
  unminimize → apt-https → packages → oh-my-zsh

${BOLD}Topic order${RESET}
  unminimize → apt-https → packages → rest

${BOLD}Examples${RESET}
  init.bash install git-config js-bun
  init.bash install steamcmd
  init.bash install '*' --exclude oh-my-zsh
  init.bash update

${BOLD}Topics${RESET}
EOF
	local topic
	for topic in "${AVAILABLE_TOPICS[@]}"; do
		echo "  ${GREEN}•${RESET} $topic"
	done
}

usage_install() {
	cat <<EOF
${BOLD}${CYAN}init.bash install${RESET}

${BOLD}Usage${RESET}
  init.bash install topic ... [options]

${BOLD}Options${RESET}
  --exclude topic ...            remove topics after selection
  --dry-run                      preview core install commands only
  -y                             skip confirmation prompt
  -h, --help                     show this help

Use '*' to select all available topics.
EOF
}

usage_update() {
	cat <<EOF
${BOLD}${CYAN}init.bash update${RESET}

${BOLD}Usage${RESET}
  init.bash update

Update ~/init.bash when a newer commit exists. Confirm before updating ~/.zshenv.
EOF
}

say_info() {
	echo
	echo "${CYAN}==>${RESET} $1"
}

say_success() {
	echo "${GREEN}✓${RESET} $1"
}

say_warn() {
	echo "${YELLOW}!${RESET} $1" >&2
}

say_error() {
	echo "${RED}✗${RESET} $1" >&2
}

self_update() (
	local latest_json
	local latest_hash
	local latest_short_hash
	local next_script
	local next_zshenv
	local reply
	local target_script

	target_script="${INIT_TARGET_SCRIPT:-$HOME/init.bash}"
	next_script=
	next_zshenv=
	trap 'rm -f "$next_script" "$next_zshenv"' EXIT

	say_info "Checking ${GITHUB_REPOSITORY}@${GITHUB_BRANCH}"
	latest_json="$(curl --proto '=https' --tlsv1.2 -fsSL "https://api.github.com/repos/${GITHUB_REPOSITORY}/commits/${GITHUB_BRANCH}")"
	latest_hash="$(printf '%s\n' "$latest_json" | sed -n 's/^[[:space:]]*"sha": "\([0-9a-f]*\)",$/\1/p' | head -n 1)"
	latest_short_hash="${latest_hash:0:7}"

	if [ "$latest_short_hash" = "" ]; then
		say_error "Could not read latest commit hash."
		exit 1
	fi

	if [ "$latest_short_hash" = "$CURRENT_COMMIT_HASH" ]; then
		say_success "Already up to date (${CURRENT_COMMIT_HASH})."
	fi

	if [ "$latest_short_hash" != "$CURRENT_COMMIT_HASH" ]; then
		say_info "Updating ${CURRENT_COMMIT_HASH} → ${latest_short_hash}"
		next_script="$(mktemp "${TMPDIR:-/tmp}/init-update.XXXXXX")"
		curl --proto '=https' --tlsv1.2 -fsSL "$BASE_URL/init.bash" -o "$next_script"
		chmod +x "$next_script"
		bash -n "$next_script"
		sed -i "s/^CURRENT_COMMIT_HASH=\"[0-9a-f]*\"/CURRENT_COMMIT_HASH=\"$latest_short_hash\"/" "$next_script"
		install -m 755 "$next_script" "$target_script"
		if [ -d /usr/local/share/zsh/site-functions ] && [ -w /usr/local/share/zsh/site-functions ]; then
			curl --proto '=https' --tlsv1.2 -fsSL "$BASE_URL/src/_init.bash" -o /usr/local/share/zsh/site-functions/_init.bash 2>/dev/null || true
		fi
		say_success "Updated $target_script to ${latest_short_hash}."
	fi

	printf 'Update %s/.zshenv? [y/N] ' "$HOME"
	if ! read -r reply; then
		reply=
	fi

	case "$reply" in
		y|Y|yes|YES)
			;;
		*)
			say_info "Skipped $HOME/.zshenv."
			return 0
			;;
	esac
	next_zshenv="$(mktemp "${TMPDIR:-/tmp}/zshenv-update.XXXXXX")"
	curl --proto '=https' --tlsv1.2 -fsSL "$BASE_URL/src/.zshenv" -o "$next_zshenv"
	install -m 644 "$next_zshenv" "$HOME/.zshenv"
	say_success "Updated $HOME/.zshenv."
)

contains_topic() {
	local topic="$1"
	local available_topic
	shift

	for available_topic in "$@"; do
		[ "$topic" = "$available_topic" ] || continue
		return 0
	done

	return 1
}

append_topics() {
	local -n topics="$1"
	local topic="$2"
	local -a requested_topics=("$topic")

	if [ "$topic" = '*' ]; then
		requested_topics=("${AVAILABLE_TOPICS[@]}")
	fi

	for topic in "${requested_topics[@]}"; do
		if ! contains_topic "$topic" "${AVAILABLE_TOPICS[@]}"; then
			say_error "Unknown topic: $topic"
			exit 1
		fi
		contains_topic "$topic" "${topics[@]}" && continue
		topics+=("$topic")
	done
}

preview_topic() {
	local topic="$1"

	case "$topic" in
		unminimize)
			echo 'yes | sudo unminimize'
			echo 'sudo apt install -y man-db'
			;;
		apt-https)
			echo 'sudo apt install -y ca-certificates apt-transport-https'
			echo "sudo sed -i 's|http://|https://|g' /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources"
			echo 'sudo apt update'
			;;
		packages)
			echo 'sudo apt install -y man-db curl wget nano zip unzip git tree gh jq ripgrep moreutils'
			;;
		git-config)
			echo 'sudo apt install -y git git-delta git-lfs'
			echo 'git config --global diff.lfs.textconv cat'
			;;
		nanorc)
			echo 'sudo apt install -y curl unzip wget'
			echo 'curl -fsSL https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh -o <tmp-installer>'
			echo 'sh <tmp-installer>'
			;;
		python-uv)
			echo 'sudo apt install -y python3 python-is-python3 python3-pip'
			echo 'python -m pip install --break-system-packages uv ruff'
			;;
		tldr)
			echo 'sudo apt install -y python3 python3-pip'
			echo 'python3 -m pip install --break-system-packages tldr'
			;;
		xtradeb)
			echo 'sudo apt install -y software-properties-common'
			echo 'sudo add-apt-repository -y ppa:xtradeb/apps'
			;;
		oh-my-zsh)
			echo 'sudo apt install -y curl git zsh'
			echo 'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o <tmp-installer>'
			echo 'sh <tmp-installer> --unattended'
			;;
		js-node-22|js-node-24)
			echo 'sudo apt install -y curl'
			echo 'curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh -o <tmp-installer>'
			echo 'bash <tmp-installer>'
			echo '. "$HOME/.nvm/nvm.sh"'
			echo "nvm install ${topic##*-}"
			echo 'corepack enable pnpm'
			;;
		js-bun)
			echo 'sudo apt install -y curl unzip'
			echo 'curl -fsSL https://bun.sh/install -o <tmp-installer>'
			echo 'bash <tmp-installer>'
			;;
		golang)
			echo 'sudo apt install -y golang'
			;;
		steamcmd)
			echo 'use local Unix user steam by default'
			echo 'reject root as SteamCMD runtime user'
			echo 'sudo apt install -y ca-certificates curl sudo tar lib32gcc-s1 lib32stdc++6'
			echo 'sudo useradd -m -s /bin/bash <user>  # if missing'
			echo 'curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -o <tmp-archive>'
			echo 'sudo -u <user> tar -xzf <tmp-archive> -C /home/<user>/steamcmd'
			echo 'sudo -u <user> /home/<user>/steamcmd/steamcmd.sh +quit'
			echo 'write /usr/local/bin/steamcmd wrapper that runs steamcmd.sh as <user>'
			;;
		minecraft-fabric)
			echo 'prompt: Minecraft version, install directory'
			echo 'sudo apt install -y curl openjdk-25-jdk'
			echo 'download latest compatible Fabric server jar; write run.bash (-Xmx6G)'
			;;
		minecraft-neoforge)
			echo 'prompt: Minecraft version, install directory'
			echo 'sudo apt install -y curl openjdk-25-jdk'
			echo 'install latest compatible NeoForge; set -Xmx6G; remove run.bat'
			;;
		oh-my-tmux)
			echo 'sudo apt install -y git gnu-which tmux zsh'
			echo 'git clone --single-branch https://github.com/gpakosz/.tmux.git'
			;;
	esac
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		install)
			if [ "$INSTALL_COMMAND" = true ]; then
				say_error "install may only be specified once"
				exit 1
			fi

			INSTALL_COMMAND=true
			shift
			if [ "${1:-}" = '--help' ] || [ "${1:-}" = '-h' ]; then
				usage_install
				exit 0
			fi
			if [ "$#" -eq 0 ] || [[ "$1" == -* ]]; then
				say_error "install requires at least one topic"
				exit 1
			fi

			while [ "$#" -gt 0 ] && [[ "$1" != -* ]]; do
				append_topics SELECTED_TOPICS "$1"
				shift
			done
			;;
		update)
			shift
			case "${1:-}" in
				'')
					self_update
					exit 0
					;;
				--help|-h)
					usage_update
					exit 0
					;;
				*)
					say_error "update does not accept arguments"
					exit 1
					;;
			esac
			;;
		--help|-h)
			if [ "$INSTALL_COMMAND" = true ]; then
				usage_install
			else
				usage
			fi
			exit 0
			;;
		--list)
			for topic in "${AVAILABLE_TOPICS[@]}"; do
				echo "$topic"
			done
			exit 0
			;;
		--dry-run)
			DRY_RUN=true
			shift
			;;
		-y)
			ASSUME_YES=true
			shift
			;;
		--exclude)
			shift
			if [ "$#" -eq 0 ] || [[ "$1" == --* ]]; then
				say_error "--exclude requires at least one topic"
				exit 1
			fi

			while [ "$#" -gt 0 ] && [[ "$1" != --* ]]; do
				append_topics EXCLUDED_TOPICS "$1"
				shift
			done
			;;
		--*)
			say_error "Unknown option: $1"
			exit 1
			;;
		*)
			say_error "Unexpected argument: $1"
			say_warn "Use install to select topics."
			exit 1
			;;
	esac
done

if [ "$INSTALL_COMMAND" = false ]; then
	ORDERED_TOPICS=("${SELECTED_TOPICS[@]}")
	SELECTED_TOPICS=()
	for topic in "${DEFAULT_TOPICS[@]}" "${ORDERED_TOPICS[@]}"; do
		append_topics SELECTED_TOPICS "$topic"
	done
fi

ORDERED_TOPICS=()
for topic in unminimize apt-https packages "${SELECTED_TOPICS[@]}"; do
	contains_topic "$topic" "${SELECTED_TOPICS[@]}" || continue
	contains_topic "$topic" "${EXCLUDED_TOPICS[@]}" && continue
	contains_topic "$topic" "${ORDERED_TOPICS[@]}" && continue
	ORDERED_TOPICS+=("$topic")
done
SELECTED_TOPICS=("${ORDERED_TOPICS[@]}")

confirm_install() {
	local reply

	say_info "Selected topics: ${SELECTED_TOPICS[*]}"
	printf 'Proceed? [y/N] '
	if ! read -r reply; then
		reply=
	fi

	case "$reply" in
		y|Y|yes|YES)
			return 0
			;;
		*)
			say_warn "Cancelled."
			exit 0
			;;
	esac
}

run_topic() {
	local topic="$1"
	local topic_script
	local status

	topic_script="$(mktemp "${TMPDIR:-/tmp}/init-topic-$topic.XXXXXX")" || return 1

	if ! curl --proto '=https' --tlsv1.2 -fsSL "$BASE_URL/init.d/$topic.bash" -o "$topic_script"; then
		rm -f "$topic_script"
		return 1
	fi

	status=0
	bash "$topic_script" || status=$?

	rm -f "$topic_script"
	return "$status"
}

if [ "$DRY_RUN" = true ]; then
	if [ "${#SELECTED_TOPICS[@]}" -gt 0 ]; then
		say_info "Preview package index update"
		echo 'sudo apt update'
	fi
	for topic in "${SELECTED_TOPICS[@]}"; do
		say_info "Preview topic: $topic"
		preview_topic "$topic"
	done
	exit 0
fi

if [ "$ASSUME_YES" = false ]; then
	confirm_install
fi

FAILED_TOPICS=()

if [ "${#SELECTED_TOPICS[@]}" -gt 0 ]; then
	say_info "Updating package index"
	sudo apt update
fi

for topic in "${SELECTED_TOPICS[@]}"; do
	say_info "Installing topic: $topic"
	if run_topic "$topic"; then
		say_success "Topic complete: $topic"
		continue
	fi
	FAILED_TOPICS+=("$topic")
	say_error "Topic failed: $topic"
done

if [ "${#FAILED_TOPICS[@]}" -gt 0 ]; then
	echo
	say_error "Failed topics: ${FAILED_TOPICS[*]}"
	exit 1
fi

echo
say_success "Restart container to take effect."
