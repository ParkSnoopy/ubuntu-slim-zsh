# Ubuntu, with zsh

Enjoy `zsh`'s powerful completion within docker container  
By default, docker `ENTRYPOINT` and `CMD` is hard to override,  
you had to run `zsh` over `bash`, which is exhausting sometimes.  

# Use

## Pull the image
```bash
docker pull ghcr.io/parksnoopy/ubuntu-slim-zsh:latest
```
## Run the container

```bash
docker run -it -u root -w /root ghcr.io/parksnoopy/ubuntu-slim-zsh:latest
```

Entrypoint as `tmux` instead of `zsh`

```bash
docker run -it -u root -w /root --entrypoint '["/usr/bin/dumb-init", "/usr/bin/tmux", "-2u"]' ghcr.io/parksnoopy/ubuntu-slim-zsh:latest
```

## Run initialization script

> [!NOTE]  
> [`/root/init.sh`](src/init.sh) is the packaged bootstrap script.  
>   
> Normally, `zsh` is used with `omz`,  
> but it makes image unnessasarily heavy.  
>   
> So initial setup is split into install topics under [`init.d/`](init.d/)  
> and run by the curl-fetched master script.  

Tool topics use the single-user Nix profile at `~/.nix-profile`. The shared
[`init.d/_nix.sh`](init.d/_nix.sh) pins Nixpkgs to an immutable commit and verifies
the version-pinned Nix installer before execution. This is a flat setup script,
without command-wrapper functions. Topic scripts source it locally or through
the coordinator's `INIT_NIX_HELPER` path, then run
`nix-env --file "$NIXPKGS_URL" --install --attr ...` directly. Dry-run previews
show the same commands. No channel update or unpinned NVM, pip, or Bun installer
is used for these tools.

Ubuntu image prerequisites, `unminimize`, `apt-https`, `xtradeb`, SteamCMD's
native 32-bit dependencies, and the registered login shell remain APT-managed.
Minecraft loader downloads and SteamCMD's self-updates remain upstream-managed;
the complete deployment is not fully reproducible. Existing shell configurations
and old tool installations are not automatically migrated. Node topics share one
profile; the last selected Node variant becomes active. The packaged `.zshenv`
loads the Nix profile.

`bash tests/init.sh` exercises topic dispatch, offline previews, scoped help,
shared helper reuse, and installation failures with isolated command doubles.

Default install with unminimize, apt HTTPS support, minimal packages, and omz

```bash
~/init.sh
```

Preview the default install

```bash
~/init.sh --dry-run
```

List available install topics

```bash
~/init.sh --list
```

Update the installed init script when a newer git commit is available

```bash
~/init.sh update
```

Install only selected topics

```bash
~/init.sh install omt python-uv
```

Exclude a topic from the default install

```bash
~/init.sh --exclude omz
```

Install SteamCMD and create a `/usr/local/bin/steamcmd` wrapper that runs as the `steam` user

```bash
~/init.sh install steamcmd
```

Install a Minecraft Fabric server (prompts for Minecraft version and install directory)

```bash
~/init.sh install minecraft-fabric
```

Install a Minecraft NeoForge server (prompts for Minecraft version and install directory)

```bash
~/init.sh install minecraft-neoforge
```

Install every available topic without confirmation

```bash
~/init.sh install '*' -y
```
