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
> [`/root/init.bash`](src/init.bash) is the packaged bootstrap script.  
>   
> Normally, `zsh` is used with `oh-my-zsh`,  
> but it makes image unnessasarily heavy.  
>   
> So initial setup is split into install topics under [`init.d/`](init.d/)  
> and run by the curl-fetched master script.  

Default install with unminimize, apt HTTPS support, minimal packages, and oh-my-zsh

```bash
~/init.bash
```

Preview the default install

```bash
~/init.bash --dry-run
```

List available install topics

```bash
~/init.bash --list
```

Update the installed init script when a newer git commit is available

```bash
~/init.bash update
```

Install only selected topics

```bash
~/init.bash install oh-my-tmux python-uv
```

Exclude a topic from the default install

```bash
~/init.bash --exclude oh-my-zsh
```

Install SteamCMD and create a `/usr/local/bin/steamcmd` wrapper that runs as the `steam` user

```bash
~/init.bash install steamcmd
```

Install a Minecraft Fabric server (prompts for Minecraft version and install directory)

```bash
~/init.bash install minecraft-fabric
```

Install a Minecraft NeoForge server (prompts for Minecraft version and install directory)

```bash
~/init.bash install minecraft-neoforge
```

Install every available topic without confirmation

```bash
~/init.bash install '*' -y
```

## Installer structure

`init.bash` parses arguments, applies defaults and exclusions, and orders the
selected topics before either previewing or installing them. Dry runs return
before confirmation, downloads, or package changes. Shared membership and
append helpers handle both selection and exclusion without recursive dispatch.
Topic failures remain aggregated after the installation loop.

`src/init.bash` is the image's thin bootstrap. Topic scripts remain under
`init.d/` and use direct command sequences. Upstream shell installers are
downloaded completely before execution, with temporary files removed on exit.
Self-update validates the downloaded Bash script before replacement and still
requires confirmation before replacing `.zshenv`.

The packaged completion is `src/_init.bash`, registered for `init.bash` with
the `oh-my-zsh` and `oh-my-tmux` topic names. Fabric's generated launcher is
`run.bash`; upstream script filenames are unchanged. Existing installations
require a rebuilt image or replacement of the bootstrap entry point because
older self-update URLs do not follow these renames.

## Development checks

`bash tests/init.bash` exercises the CLI with controlled download and package
command fixtures in a temporary home; it does not install packages or contact
upstream services. Run `bash -n` and `shellharden --check` on `init.bash`,
`src/init.bash`, each `init.d/*.bash` script, and `tests/init.bash` individually.
