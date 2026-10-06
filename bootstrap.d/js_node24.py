"""Install Node.js 24 and pnpm."""

from contract import Topic


class Node24(Topic):
    name = "js-node-24"
    description = "Install pinned Node.js 24 and pnpm with Nix"

    def packages(self):
        return ("nodejs_24", "pnpm")

    def install(self):
        """No actions after package installation."""

    def preview(self):
        return ()


TOPIC = Node24()
