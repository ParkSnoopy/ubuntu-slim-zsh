"""Install Go."""

from contract import Topic


class Golang(Topic):
    name = "golang"
    description = "Install Go toolchain"

    def packages(self):
        return ("go",)

    def install(self):
        """No actions after package installation."""

    def preview(self):
        return ()


TOPIC = Golang()
