"""Install Node.js 22 and pnpm."""

from contract import Topic


class Node22(Topic):
    name = "js-node-22"
    description = "Install pinned Node.js 22 and pnpm with Nix"

    def packages(self):
        return ("nodejs_22", "pnpm")

    def install(self):
        """No actions after package installation."""

    def preview(self):
        return ()


TOPIC = Node22()
