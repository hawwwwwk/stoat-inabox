FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# install base dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    bash \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# install official Docker CLI + compose plugin
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y \
    docker-ce-cli \
    docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# copy and set up entrypoint
COPY letsgo.sh /letsgo.sh
RUN chmod +x /letsgo.sh

ENTRYPOINT ["/letsgo.sh"]