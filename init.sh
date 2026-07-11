#!/bin/env bash
set -euo pipefail

BASE_URL="${INIT_BASE_URL:-https://raw.githubusercontent.com/ParkSnoopy/ubuntu-slim-zsh/refs/heads/main}"

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
	oh-my-tmux
)

DEFAULT_TOPICS=(unminimize packages oh-my-zsh)
SELECTED_TOPICS=("${DEFAULT_TOPICS[@]}")
DRY_RUN=false
ASSUME_YES=false

usage() {
	cat <<EOF
Usage: init.sh [--list] [--dry-run] [-y] [--include topic ...]

Installs the default topics: unminimize packages oh-my-zsh.
With --include, appends extra topics in the order given.
Use --include '*' to append every available topic.
Duplicated topics are skipped.
Topic order is normalized: unminimize, apt-https, packages, then the rest.
--dry-run previews the core install commands without running them.

Available topics:
EOF
	printf '  %s\n' "${AVAILABLE_TOPICS[@]}"
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

append_selected_topic() {
	local topic="$1"

	if [ "$topic" = '*' ]; then
		append_all_available_topics
		return 0
	fi

	if ! is_available_topic "$topic"; then
		echo "Unknown topic: $topic" >&2
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

preview_topic() {
	local topic="$1"

	case "$topic" in
		unminimize)
			printf '%s\n' 'yes | sudo unminimize'
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
		oh-my-tmux)
			printf '%s\n' 'sudo apt install -y git zsh'
			printf '%s\n' 'git clone --single-branch https://github.com/gpakosz/.tmux.git'
			;;
	esac
}

while [ "$#" -gt 0 ]; do
	case "$1" in
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
		--include)
			shift
			if [ "$#" -eq 0 ] || [[ "$1" == --* ]]; then
				echo "--include requires at least one topic" >&2
				exit 1
			fi

			while [ "$#" -gt 0 ] && [[ "$1" != --* ]]; do
				append_selected_topic "$1"
				shift
			done
			;;
		--*)
			echo "Unknown option: $1" >&2
			exit 1
			;;
		*)
			echo "Unexpected argument: $1" >&2
			echo "Use --include to select topics." >&2
			exit 1
			;;
	esac
done

normalize_topic_order

confirm_install() {
	local reply

	echo "Selected topics: ${SELECTED_TOPICS[*]}"
	printf 'Proceed? [y/N] '
	if ! read -r reply; then
		reply=
	fi

	case "$reply" in
		y|Y|yes|YES)
			return 0
			;;
		*)
			echo "Cancelled."
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
		echo "==> Preview topic: $topic"
		preview_topic "$topic"
	else
		echo "==> Installing topic: $topic"
		if ! run_topic "$topic"; then
			FAILED_TOPICS+=("$topic")
			echo "Topic failed: $topic" >&2
		fi
	fi
done

if [ "${#FAILED_TOPICS[@]}" -gt 0 ]; then
	echo
	echo "Failed topics: ${FAILED_TOPICS[*]}" >&2
	exit 1
fi

if [ "$DRY_RUN" = false ]; then
	# Post comment
	echo
	echo "--------------------"
	echo "Restart container to take effect"
	echo "--------------------"
fi
