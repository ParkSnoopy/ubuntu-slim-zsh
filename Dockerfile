FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

USER root

RUN \
	apt update -y						&&\
	apt install -y sudo zsh tmux dumb-init tzdata locales	&&\
	locale-gen en_US.UTF-8					&&\
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime		&&\
	TZ=Asia/Seoul echo $TZ > /etc/timezone			&&\
	rm -rf /var/lib/apt/lists/*				&&\
	echo 'ubuntu  ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo

COPY src/init.sh /root/init.sh
COPY src/.zshenv /root/.zshenv

ENTRYPOINT ["/usr/bin/dumb-init", "/usr/bin/zsh"]
