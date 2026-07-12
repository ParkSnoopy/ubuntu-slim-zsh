#!/bin/env bash
set -euo pipefail

BASE_URL="${INIT_BASE_URL:-https://raw.githubusercontent.com/ParkSnoopy/ubuntu-slim-zsh/refs/heads/main}"
GITHUB_REPOSITORY="${INIT_GITHUB_REPOSITORY:-ParkSnoopy/ubuntu-slim-zsh}"
GITHUB_BRANCH="${INIT_GITHUB_BRANCH:-main}"
CURRENT_COMMIT_HASH="b1ec88e"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
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
	oh-my-zsh
	javascript-nodejs
	javascript-bun
	steamcmd
	minecraft-fabric
	minecraft-neoforge
	oh-my-tmux
)

DEFAULT_TOPICS=(unminimize apt-https packages oh-my-zsh)
SELECTED_TOPICS=()
EXCLUDED_TOPICS=()
DEFAULT_ENABLED=true
DRY_RUN=false
ASSUME_YES=false

usage() {
	cat <<EOF
${BOLD}${CYAN}ubuntu-slim-zsh init${RESET} ${DIM}(${CURRENT_COMMIT_HASH})${RESET}

${BOLD}Usage${RESET}
  init.sh [command] [options]

${BOLD}Commands${RESET}
  update                         compare commit hash and replace ~/init.sh if newer

${BOLD}Selection${RESET}
  --include topic ...            append topics; use '*' for every available topic
  --exclude topic ...            remove topics after default/include selection
  --no-default                   install only explicitly included topics

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
  init.sh --include git-config javascript-bun
  init.sh --no-default --include steamcmd
  init.sh --include '*' --exclude oh-my-zsh
  init.sh update

${BOLD}Topics${RESET}
EOF
	local topic
	for topic in "${AVAILABLE_TOPICS[@]}"; do
		printf '  %b•%b %s\n' "$GREEN" "$RESET" "$topic"
	done
}

say_info() {
	printf '%b==>%b %s\n' "$CYAN" "$RESET" "$1"
}

say_success() {
	printf '%b✓%b %s\n' "$GREEN" "$RESET" "$1"
}

say_warn() {
	printf '%b!%b %s\n' "$YELLOW" "$RESET" "$1" >&2
}

say_error() {
	printf '%b✗%b %s\n' "$RED" "$RESET" "$1" >&2
}

self_update() {
	local latest_json
	local latest_hash
	local latest_short_hash
	local next_script
	local target_script

	target_script="${INIT_TARGET_SCRIPT:-$HOME/init.sh}"

	say_info "Checking ${GITHUB_REPOSITORY}@${GITHUB_BRANCH}"
	latest_json="$(curl --proto '=https' --tlsv1.2 -fsSL "https://api.github.com/repos/${GITHUB_REPOSITORY}/commits/${GITHUB_BRANCH}")"
	latest_hash="$(printf '%s\n' "$latest_json" | sed -n 's/^[[:space:]]*"sha": "\([0-9a-f]*\)",$/\1/p' | head -n 1)"
	latest_short_hash="${latest_hash:0:7}"

	if [ -z "$latest_short_hash" ]; then
		say_error "Could not read latest commit hash."
		exit 1
	fi

	if [ "$latest_short_hash" = "$CURRENT_COMMIT_HASH" ]; then
		say_success "Already up to date (${CURRENT_COMMIT_HASH})."
		return 0
	fi

	say_info "Updating ${CURRENT_COMMIT_HASH} → ${latest_short_hash}"
	next_script="$(mktemp "${TMPDIR:-/tmp}/init-update.XXXXXX")"
	trap 'rm -f "$next_script"' RETURN
	curl --proto '=https' --tlsv1.2 -fsSL "$BASE_URL/init.sh" -o "$next_script"
	chmod +x "$next_script"
	sed -i "s/^CURRENT_COMMIT_HASH=\"[0-9a-f]*\"/CURRENT_COMMIT_HASH=\"$latest_short_hash\"/" "$next_script"
	install -m 755 "$next_script" "$target_script"
	say_success "Updated $target_script to ${latest_short_hash}."
}

is_available_topic() {
	local topic="$1"
	local available_topic

	for available_topic in "${AVAILABLE_TOPICS[@]}"; do
		if [ "$topic" = "$available_topic" ]; then
			return 0
		fi
	done

	return 1
}

is_selected_topic() {
	local topic="$1"
	local selected_topic

	for selected_topic in "${SELECTED_TOPICS[@]}"; do
		if [ "$topic" = "$selected_topic" ]; then
			return 0
		fi
	done

	return 1
}

is_excluded_topic() {
	local topic="$1"
	local excluded_topic

	for excluded_topic in "${EXCLUDED_TOPICS[@]}"; do
		if [ "$topic" = "$excluded_topic" ]; then
			return 0
		fi
	done

	return 1
}

append_selected_topic() {
	local topic="$1"

	if [ "$topic" = '*' ]; then
		append_all_available_topics
		return 0
	fi

	if ! is_available_topic "$topic"; then
		say_error "Unknown topic: $topic"
		exit 1
	fi

	if is_selected_topic "$topic"; then
		return 0
	fi

	SELECTED_TOPICS+=("$topic")
}

append_all_available_topics() {
	local topic

	for topic in "${AVAILABLE_TOPICS[@]}"; do
		append_selected_topic "$topic"
	done
}

append_excluded_topic() {
	local topic="$1"

	if [ "$topic" = '*' ]; then
		append_all_excluded_topics
		return 0
	fi

	if ! is_available_topic "$topic"; then
		say_error "Unknown topic: $topic"
		exit 1
	fi

	if is_excluded_topic "$topic"; then
		return 0
	fi

	EXCLUDED_TOPICS+=("$topic")
}

append_all_excluded_topics() {
	local topic

	for topic in "${AVAILABLE_TOPICS[@]}"; do
		append_excluded_topic "$topic"
	done
}

append_topic_if_selected() {
	local topic="$1"

	if is_selected_topic "$topic"; then
		ORDERED_TOPICS+=("$topic")
	fi
}

normalize_topic_order() {
	local topic
	local selected_topic

	ORDERED_TOPICS=()
	append_topic_if_selected unminimize
	append_topic_if_selected apt-https
	append_topic_if_selected packages

	for topic in "${SELECTED_TOPICS[@]}"; do
		case "$topic" in
			unminimize|apt-https|packages)
				continue
				;;
		esac

		for selected_topic in "${ORDERED_TOPICS[@]}"; do
			if [ "$topic" = "$selected_topic" ]; then
				continue 2
			fi
		done

		ORDERED_TOPICS+=("$topic")
	done

	SELECTED_TOPICS=("${ORDERED_TOPICS[@]}")
}

remove_excluded_topics() {
	local topic

	ORDERED_TOPICS=()

	for topic in "${SELECTED_TOPICS[@]}"; do
		if is_excluded_topic "$topic"; then
			continue
		fi

		ORDERED_TOPICS+=("$topic")
	done

	SELECTED_TOPICS=("${ORDERED_TOPICS[@]}")
}

apply_default_topics() {
	local topic

	if [ "$DEFAULT_ENABLED" = false ]; then
		return 0
	fi

	ORDERED_TOPICS=("${SELECTED_TOPICS[@]}")
	SELECTED_TOPICS=()

	for topic in "${DEFAULT_TOPICS[@]}"; do
		append_selected_topic "$topic"
	done

	for topic in "${ORDERED_TOPICS[@]}"; do
		append_selected_topic "$topic"
	done
}

preview_topic() {
	local topic="$1"

	case "$topic" in
		unminimize)
			printf '%s\n' 'printf y | sudo unminimize'
			;;
		apt-https)
			printf '%s\n' 'sudo apt install -y ca-certificates apt-transport-https'
			;;
		packages)
			printf '%s\n' 'sudo apt install -y man-db curl wget nano zip unzip git tree'
			;;
		git-config)
			printf '%s\n' 'sudo apt install -y git git-delta'
			;;
		nanorc)
			printf '%s\n' 'sudo apt install -y curl'
			printf '%s\n' 'curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh'
			;;
		python-uv)
			printf '%s\n' 'sudo apt install -y python3 python-is-python3 python3-pip'
			printf '%s\n' 'python -m pip install --break-system-packages uv ruff'
			;;
		oh-my-zsh)
			printf '%s\n' 'sudo apt install -y curl zsh'
			printf '%s\n' 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
			;;
		javascript-nodejs)
			printf '%s\n' 'sudo apt install -y curl'
			printf '%s\n' 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash'
			printf '%s\n' 'nvm install 22'
			;;
		javascript-bun)
			printf '%s\n' 'sudo apt install -y curl'
			printf '%s\n' 'curl -fsSL https://bun.sh/install | bash'
			;;
		steamcmd)
			printf '%s\n' 'use local Unix user steam by default'
			printf '%s\n' 'reject root as SteamCMD runtime user'
			printf '%s\n' 'sudo apt install -y ca-certificates curl sudo tar lib32gcc-s1 lib32stdc++6'
			printf '%s\n' 'sudo useradd -m -s /bin/bash <user>  # if missing'
			printf '%s\n' 'curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -o <tmp-archive>'
			printf '%s\n' 'sudo -u <user> tar -xzf <tmp-archive> -C /home/<user>/steamcmd'
			printf '%s\n' 'sudo -u <user> /home/<user>/steamcmd/steamcmd.sh +quit'
			printf '%s\n' 'write /usr/local/bin/steamcmd wrapper that runs steamcmd.sh as <user>'
			;;
		minecraft-fabric)
			printf '%s\n' 'prompt: Minecraft version, install directory'
			printf '%s\n' 'sudo apt install -y openjdk-25-jdk'
			printf '%s\n' 'download latest compatible Fabric server jar; write run.sh (-Xmx6G)'
			;;
		minecraft-neoforge)
			printf '%s\n' 'prompt: Minecraft version, install directory'
			printf '%s\n' 'sudo apt install -y openjdk-25-jdk'
			printf '%s\n' 'install latest compatible NeoForge; set -Xmx6G; remove run.bat'
			;;
		oh-my-tmux)
			printf '%s\n' 'sudo apt install -y git tmux zsh'
			printf '%s\n' 'git clone --single-branch https://github.com/gpakosz/.tmux.git'
			;;
	esac
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		update)
			self_update
			exit 0
			;;
		--help|-h)
			usage
			exit 0
			;;
		--list)
			printf '%s\n' "${AVAILABLE_TOPICS[@]}"
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
		--no-default)
			DEFAULT_ENABLED=false
			shift
			;;
		--include)
			shift
			if [ "$#" -eq 0 ] || [[ "$1" == --* ]]; then
				say_error "--include requires at least one topic"
				exit 1
			fi

			while [ "$#" -gt 0 ] && [[ "$1" != --* ]]; do
				append_selected_topic "$1"
				shift
			done
			;;
		--exclude)
			shift
			if [ "$#" -eq 0 ] || [[ "$1" == --* ]]; then
				say_error "--exclude requires at least one topic"
				exit 1
			fi

			while [ "$#" -gt 0 ] && [[ "$1" != --* ]]; do
				append_excluded_topic "$1"
				shift
			done
			;;
		--*)
			say_error "Unknown option: $1"
			exit 1
			;;
		*)
			say_error "Unexpected argument: $1"
			say_warn "Use --include to select topics."
			exit 1
			;;
	esac
done

apply_default_topics
normalize_topic_order
remove_excluded_topics

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

	topic_script="$(mktemp "${TMPDIR:-/tmp}/init-topic-$topic.XXXXXX")"

	if ! curl --proto '=https' --tlsv1.2 -sSf "$BASE_URL/init.d/$topic.sh" -o "$topic_script"; then
		rm -f "$topic_script"
		return 1
	fi

	chmod +x "$topic_script"

	if bash "$topic_script"; then
		status=0
	else
		status=$?
	fi

	rm -f "$topic_script"
	return "$status"
}

if [ "$DRY_RUN" = false ] && [ "$ASSUME_YES" = false ]; then
	confirm_install
fi

FAILED_TOPICS=()

for topic in "${SELECTED_TOPICS[@]}"; do
	echo
	if [ "$DRY_RUN" = true ]; then
		say_info "Preview topic: $topic"
		preview_topic "$topic"
	else
		say_info "Installing topic: $topic"
		if ! run_topic "$topic"; then
			FAILED_TOPICS+=("$topic")
			say_error "Topic failed: $topic"
		else
			say_success "Topic complete: $topic"
		fi
	fi
done

if [ "${#FAILED_TOPICS[@]}" -gt 0 ]; then
	echo
	say_error "Failed topics: ${FAILED_TOPICS[*]}"
	exit 1
fi

if [ "$DRY_RUN" = false ]; then
	# Post comment
	echo
	say_success "Restart container to take effect."
fi
