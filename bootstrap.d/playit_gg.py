"""Install the pinned official Playit agent."""

from contract import Topic


class Playit(Topic):
    name = "playit-gg"
    description = "Install pinned Playit tunnel agent with Nix"

    def packages(self):
        return ("playit",)

    def install(self):
        """Do not start the agent or change its configuration."""

    def preview(self):
        return ()


TOPIC = Playit()
