"""Replace complete files without exposing partial writes."""

from contextlib import ExitStack
from pathlib import Path
from tempfile import NamedTemporaryFile

EXECUTABLE_MODE = 0o755


def save(path, payload, mode=0o644):
    path = Path(path).resolve()
    with (
        ExitStack() as cleanup,
        NamedTemporaryFile(dir=path.parent, delete=False) as stream,
    ):
        temporary = Path(stream.name)
        cleanup.callback(temporary.unlink, missing_ok=True)
        stream.write(payload)
        stream.flush()
        temporary.chmod(mode)
        temporary.replace(path)
