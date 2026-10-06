# Ubuntu, with zsh

Ubuntu 24.04 container with zsh as the default shell and dumb-init as PID 1.
The image packages the executable [`bootstrap`](bootstrap) and its Python
modules under [`bootstrap.d/`](bootstrap.d/). Runtime Python comes from uv;
the installer uses only the standard library. The project and image use Python
3.14; Ruff, wemake-python-styleguide, and integration checks support this version.

## Image tags and bind-mount ownership

The publication workflow builds two tags from the same source and Seoul date:
`{YYYYMMDD}` retains the root default; `{YYYYMMDD}-nonroot` defaults to
`ubuntu:ubuntu` (container UID/GID `1000:1000`) with home `/home/ubuntu`.
The nonroot image keeps writable bootstrap files and uv-managed installs in
that home. Both image variants share the system Python interpreter.

### Rootless Podman: keep the invoking user's ownership

Replace `YYYYMMDD` with a published image date. Run Podman as your regular
host user, without `sudo`:

```bash
podman run --rm -it \
  --userns=keep-id:uid=1000,gid=1000 --user=ubuntu:ubuntu \
  --volume "$PWD:/workspace:Z" --workdir /workspace \
  ghcr.io/parksnoopy/ubuntu-slim-zsh:YYYYMMDD-nonroot
```

This maps the invoking host user's UID and primary GID to the image's named
`ubuntu` account. New files that `ubuntu` writes in `/workspace` retain the
invoking user's numeric owner/group on the host, even when the host IDs are
not `1000:1000`. `:Z` handles private SELinux labeling, not file ownership.
Do not add `:U`: it recursively changes bind-mount ownership. Avoid `sudo`
commands that write into the bind mount or running the workload as another
container user. The mapping does not repair files created by older containers.

Setting `USER ubuntu` alone is insufficient for rootless engines: their
default user namespaces can map UID 1000 to subordinate host IDs such as
`527999:527999`. Plain `--userns=keep-id` also changes the process identity;
the explicit mapped IDs and `--user` above preserve the named Ubuntu account.
See the [Podman user-namespace reference](https://docs.podman.io/en/latest/markdown/podman-run.1.html#userns-mode).

### Rootful Docker: match numeric IDs for workspace writes

With a rootful Docker daemon and no user-namespace remapping:

```bash
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  --mount "type=bind,source=$PWD,target=/workspace" --workdir /workspace \
  ghcr.io/parksnoopy/ubuntu-slim-zsh:YYYYMMDD-nonroot
```

This overrides the image's named user with the host's numeric IDs. If those
IDs differ from `1000:1000`, access to Ubuntu-owned home files and named-account
operations is not guaranteed; use the Podman recipe for the full Ubuntu
environment. This Docker recipe is not an ownership guarantee for rootless
Docker or daemons configured with `userns-remap`.

## Installer structure

Each topic has its own module and class with its name and description under
[`bootstrap.d/topics/`](bootstrap.d/topics/). Shared infrastructure, including
the topic contract, stays directly under `bootstrap.d/`.
[`catalog.py`](bootstrap.d/catalog.py) loads topics in the declared order.
Public topic identifiers use hyphens; module names use underscores and join
numeric suffixes, such as `js-node-22` → `topics/js_node22.py`.

Every topic inherits the single [`Topic` ABC](bootstrap.d/contract.py).
Subclasses may define only three synchronous methods with a positional `self`:
`packages()`, `install()`, and `preview()`. Additional methods, extra parameters,
and static or class methods are rejected when the class is defined.
Package declarations are Nix attributes; previews must not prompt, write,
or access the network. Metadata stays on the topic class.

[`coordinator.py`](bootstrap.d/coordinator.py) applies exclusions and gathers
packages before any topic action. [`nix.py`](bootstrap.d/nix.py) deduplicates
packages, keeps the last selected Node variant, verifies Nix bootstrap when
needed, and issues one `nix-env --install` transaction. Playit joins the same
transaction through a combined expression. Empty Nix selections skip setup.
APT refresh and OS-owned topic actions follow the Nix phase.

Nixpkgs and installer pins live in [`settings.py`](bootstrap.d/settings.py).
The official Playit 0.17.1 derivation retains amd64 and arm64 release hashes;
see [mafen/playit-docker](https://github.com/mafen/playit-docker) for context.
Installation does not start Playit. Python remains uv-managed. APT retains
Ubuntu prerequisites, source configuration, native SteamCMD dependencies,
and the registered login shell. Upstream game downloads and SteamCMD updates
are not immutable, so the complete deployment is not fully reproducible.

[`updater.py`](bootstrap.d/updater.py) downloads and validates the complete
executable/module bundle, including the nested topics package, before replacing
installed source files. It refreshes completion and requires confirmation
before replacing user `.zshenv`, even when the installed source is current.
Existing shell settings are preserved
during topic installation.

Legacy flat-layout updaters cannot fetch the nested topics package. Migrating
those installations requires a full-bundle replacement or a rebuilt image,
not an update through the legacy client.

## Development checks

uv owns the project environment and lockfile. Ruff and wemake-python-styleguide
are development-only dependencies. WPS defaults apply to source and tests;
`.flake8` excludes generated environments/caches and includes `bootstrap`.

```bash
uv run --locked ruff check bootstrap bootstrap.d tests
uv run --locked ruff format --check bootstrap bootstrap.d tests
uv run flake8 . --select=WPS
uv run --locked python -m unittest discover -s tests -v
```

Integration checks cover topic contracts, dispatch, offline previews, the shared
Nix transaction, failures, prompts, and full-bundle updates. Set
`BOOTSTRAP_LIVE_TESTS=1` for real Fabric downloads and installer checksum checks.
Those optional tests do not install Nix or start game servers. Container builds
must separately verify image assembly and its uv-managed interpreter.
