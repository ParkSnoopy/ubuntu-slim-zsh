"""Write CLI records and read answers without output capture."""

import sys


def emit(message="", *, error=False, end="\n"):
    stream = sys.stderr if error else sys.stdout
    stream.write(f"{message}{end}")
    stream.flush()


def prompt(label, default):
    emit(f"\n{label} [{default}]: ", error=True, end="")
    return sys.stdin.readline().strip() or default


def emit_lines(records):
    for record in records:
        emit(record)
