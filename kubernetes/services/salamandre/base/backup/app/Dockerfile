FROM debian:trixie-slim
# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBE_VERSION="v1.34.2"

# Add contrib source for zfs
RUN sed -i -e 's/ main/ main contrib/g' /etc/apt/sources.list.d/debian.sources

# Install needed packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    jq \
    curl \
    ca-certificates \
    gzip \
    zfsutils-linux && \
    rm -rf /var/lib/apt/lists/*

RUN curl -LO "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN curl -o /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod +x /usr/local/bin/mc

WORKDIR /app

USER root
