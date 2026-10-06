"""Configure Git defaults, delta, and LFS text conversion."""

from contract import Topic
from execution import run

GIT_CONFIG = (
    ("init.defaultBranch", "main"),
    ("pull.rebase", "false"),
    ("core.quotePath", "false"),
    ("core.pager", "delta"),
    ("interactive.diffFilter", "delta --color-only"),
    ("delta.navigate", "true"),
    ("merge.conflictStyle", "zdiff3"),
    ("diff.lfs.textconv", "cat"),
)


class GitConfig(Topic):
    name = "git-config"
    description = "Configure Git with delta and LFS"

    def packages(self):
        return ("git", "delta", "git-lfs")

    def install(self):
        for key, setting in GIT_CONFIG:
            run("git", "config", "--global", key, setting)

    def preview(self):
        return ("configure Git defaults, delta, and LFS text conversion",)


TOPIC = GitConfig()
