#compdef init.sh

_init_sh() {
	local curcontext="$curcontext" state line
	typeset -A opt_args

	local -a topics
	topics=(
		'unminimize:Revert Ubuntu minimal to full system with man pages'
		'apt-https:Switch APT repositories to HTTPS'
		'packages:Install basic CLI tools (curl, wget, git, gh, etc.)'
		'git-config:Configure Git with delta and LFS'
		'nanorc:Install syntax highlighting for Nano'
		'python-uv:Install Python 3, uv, and ruff'
		'tldr:Install tldr client'
		'xtradeb:Add xtradeb/apps PPA repository'
		'oh-my-zsh:Install Oh My Zsh'
		'javascript-nodejs:Install Node.js via NVM and enable pnpm'
		'javascript-bun:Install Bun runtime'
		'steamcmd:Install SteamCMD dedicated server client'
		'minecraft-fabric:Install Minecraft Fabric server'
		'minecraft-neoforge:Install Minecraft NeoForge server'
		'oh-my-tmux:Install Oh My Tmux configuration'
		'\*:All available topics'
	)

	local -a subcommands
	subcommands=(
		'install:Install only selected topics'
		'update:Compare commit hash and replace ~/init.sh if newer'
	)

	local -a common_opts
	common_opts=(
		'(-h --help)'{-h,--help}'[Show help]'
		'--list[Print available topics]'
		'--dry-run[Preview core install commands only]'
		'-y[Skip confirmation prompt]'
	)

	_arguments -s \
		$common_opts \
		'*--exclude[Remove topics after selection]:topic:->topics' \
		':command:->cmds' \
		'*:topic:->topics' && return 0

	case "$state" in
		cmds)
			_describe -t commands 'command' subcommands
			;;
		topics)
			_describe -t topics 'topic' topics
			;;
	esac
}

_init_sh "$@"
