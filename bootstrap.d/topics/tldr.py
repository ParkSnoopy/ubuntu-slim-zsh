"""Install the tldr client."""

from contract import Topic


class Tldr(Topic):
    name = "tldr"
    description = "Install tldr client"

    def packages(self):
        return ("tldr",)

    def install(self):
        """No actions after package installation."""

    def preview(self):
        return ()


TOPIC = Tldr()
