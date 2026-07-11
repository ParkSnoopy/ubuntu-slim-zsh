#!/bin/env bash
set -euo pipefail

# This container is for isolated OS.
# Avoid `yes | ...` under pipefail: yes exits with SIGPIPE after unminimize
# finishes, which can make a successful unminimize look failed.
if sudo unminimize <<'EOF'
y
EOF
then
	exit 0
fi

# Already-unminimized systems can still return non-zero. Treat the absence of
# the minimization exclude file as success.
if [ ! -e /etc/dpkg/dpkg.cfg.d/excludes ]; then
	echo "System is already unminimized."
	exit 0
fi

exit 1
