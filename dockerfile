FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for VM management and cloud-init ISO creation
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    bash \
    git \
    qemu-utils \
    cloud-image-utils \
    virtinst \
    libvirt-clients \
    socat \
    && rm -rf /var/lib/apt/lists/*

COPY letsgo.sh /letsgo.sh
RUN chmod +x /letsgo.sh

ENTRYPOINT ["/letsgo.sh"]