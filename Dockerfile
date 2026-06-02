FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul

USER root

RUN \
	apt update -y				&&\
	apt install -y sudo zsh tzdata locales	&&\
	locale-gen en_US.UTF-8			&&\
	rm -rf /var/lib/apt/lists/*		&&\
	echo 'ubuntu  ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo

COPY src/init.sh /root/init.sh
COPY src/.zshenv /root/.zshenv

ENTRYPOINT ["/usr/bin/zsh"]
