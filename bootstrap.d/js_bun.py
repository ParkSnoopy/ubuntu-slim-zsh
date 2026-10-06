"""Install Bun."""

from contract import Topic


class Bun(Topic):
    name = "js-bun"
    description = "Install Bun runtime"

    def packages(self):
        return ("bun",)

    def install(self):
        """No actions after package installation."""

    def preview(self):
        return ()


TOPIC = Bun()
