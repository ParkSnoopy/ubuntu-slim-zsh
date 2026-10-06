"""Install uv-managed Python and ruff."""

from contract import Topic
from execution import run
from settings import PYTHON_VERSION


class PythonUV(Topic):
    name = "python-uv"
    description = "Install uv-managed Python 3 and ruff"

    def packages(self):
        return ("uv", "ruff")

    def install(self):
        run("uv", "python", "install", PYTHON_VERSION, "--default")

    def preview(self):
        return (f"uv python install {PYTHON_VERSION} --default",)


TOPIC = PythonUV()
