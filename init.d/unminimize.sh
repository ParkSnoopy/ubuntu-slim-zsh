#!/bin/env bash
set -euo pipefail

# This container is for isolated OS.
# unminimize can prompt more than once. Disable pipefail only inside this
# subshell so yes exiting with SIGPIPE does not hide unminimize's result.
if (
	set +o pipefail
	yes | sudo unminimize
); then
	exit 0
fi

# Already-unminimized systems can still return non-zero. Treat the absence of
# the minimization exclude file as success.
if [ ! -e /etc/dpkg/dpkg.cfg.d/excludes ]; then
	echo "System is already unminimized."
	exit 0
fi

exit 1
