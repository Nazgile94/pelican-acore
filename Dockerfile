# Pelican-compatible AzerothCore All-in-One Yolk
# Current AzerothCore Linux requirements recommend Ubuntu 26.04 + MySQL 8.4 LTS.
FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash ca-certificates curl wget git jq unzip zip rsync openssl \
        lsb-release procps iproute2 netcat-openbsd tini \
        cmake make ninja-build gcc g++ clang ccache \
        libstdc++-16-dev libgoogle-perftools-dev \
        default-libmysqlclient-dev libssl-dev libbz2-dev \
        libreadline-dev libncurses-dev libboost-all-dev \
        mysql-server mysql-client \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/container -s /bin/bash container \
    && mkdir -p /home/container \
    && chown -R container:container /home/container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container
STOPSIGNAL SIGINT

COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
