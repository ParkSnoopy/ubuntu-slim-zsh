"""Install the basic CLI tool set."""

from contract import Topic

BASE_PACKAGES = (
    "man-db",
    "curl",
    "wget",
    "nano",
    "zip",
    "unzip",
    "git",
    "tree",
    "gh",
    "jq",
    "ripgrep",
    "moreutils",
)


class Packages(Topic):
    name = "packages"
    description = "Install basic CLI tools"

    def packages(self):
        return BASE_PACKAGES

    def install(self):
        """No actions after package installation."""

    def preview(self):
        return ()


TOPIC = Packages()
