# Ubuntu, with zsh

Enjoy `zsh`'s powerful completion within docker container  
By default, docker `ENTRYPOINT` and `CMD` is hard to override,  
you had to run `zsh` over `bash`, which is exhausting sometimes.  

## Use
- Pull the image
```bash
docker pull ghcr.io/parksnoopy/ubuntu-slim-zsh:latest
```
- Run the container
> [!NOTE]  
> [`/root/init.sh`](src/init.sh) is initial environment setup script.
>   
> Normally, `zsh` is used with `oh-my-zsh`,
> but it makes image unnessasarily heavy.
> So initial setup (apt `http`->`https`, install git, python, and basic shell utils)
> is done manually inside container.  
```bash
docker run -it -u root -w /root ghcr.io/parksnoopy/ubuntu-slim-zsh:latest
~/init.sh
```
