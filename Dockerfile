FROM ubuntu:24.04

COPY --from=ghcr.io/astral-sh/uv:0.12.0 /uv /uvx /usr/local/bin/

ENV DEBIAN_FRONTEND=noninteractive
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python
ENV UV_PYTHON_BIN_DIR=/usr/local/bin

USER root

RUN \
	apt update -y						&&\
	apt install -y sudo zsh tmux dumb-init tzdata locales curl ca-certificates xz-utils	&&\
	locale-gen en_US.UTF-8					&&\
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime		&&\
	TZ=Asia/Seoul echo $TZ > /etc/timezone			&&\
	rm -rf /var/lib/apt/lists/*				&&\
	echo 'ubuntu  ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo

RUN uv python install 3.12 --default

COPY --chmod=755 bootstrap /root/bootstrap
COPY bootstrap.d/ /root/bootstrap.d/
COPY src/.zshenv /root/.zshenv
COPY src/_bootstrap /usr/local/share/zsh/site-functions/_bootstrap

ENTRYPOINT ["/usr/bin/dumb-init", "/usr/bin/zsh"]
