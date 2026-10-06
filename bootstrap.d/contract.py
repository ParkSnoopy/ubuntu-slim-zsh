"""The only permitted topic interface."""

import inspect
from abc import ABC, abstractmethod

METHODS = frozenset(("packages", "install", "preview"))


def validate_method(name, definition):
    if name not in METHODS:
        raise TypeError(f"Topic method is not permitted: {name}")
    if not inspect.isfunction(definition):
        raise TypeError(f"Topic method must be a plain function: {name}")
    arguments = inspect.signature(definition).parameters
    if (
        tuple(arguments) != ("self",)
        or arguments["self"].kind
        not in (
            inspect.Parameter.POSITIONAL_ONLY,
            inspect.Parameter.POSITIONAL_OR_KEYWORD,
        )
        or arguments["self"].default is not inspect.Parameter.empty
        or inspect.iscoroutinefunction(definition)
    ):
        raise TypeError(f"Topic method must have signature {name}(self)")


class Topic(ABC):
    """Permit packages(self), install(self), and preview(self), without helpers."""

    name: str
    description: str
    needs_apt = False

    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)
        for name, definition in cls.__dict__.items():
            if callable(definition) or isinstance(
                definition, (classmethod, staticmethod, property)
            ):
                validate_method(name, definition)

    @abstractmethod
    def packages(self) -> tuple[str, ...]:
        """Declare Nix attributes or the pinned Playit derivation."""

    @abstractmethod
    def install(self) -> None:
        """Apply topic actions after shared package installation."""

    @abstractmethod
    def preview(self) -> tuple[str, ...]:
        """Describe actions without external operations."""
