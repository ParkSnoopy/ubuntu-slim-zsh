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
> Normally, `zsh` is used with `oh-my-zsh`,  
> but it makes image unnessasarily heavy.  
>   
> So initial setup is split into install topics under [`init.d/`](init.d/)  
> and run by the curl-fetched master script.  

Default install with unminimize, apt HTTPS support, minimal packages, and oh-my-zsh

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
~/init.sh install oh-my-tmux python-uv
```

Exclude a topic from the default install

```bash
~/init.sh --exclude oh-my-zsh
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
