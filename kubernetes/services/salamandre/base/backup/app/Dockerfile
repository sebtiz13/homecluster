FROM debian:trixie-slim

# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBE_VERSION="v1.34.2"
# renovate: datasource=github-releases depName=jqlang/jq
ARG JQ_VERSION="1.8.1"
# renovate: datasource=github-releases depName=rclone/rclone
ARG RCLONE_VERSION="v1.73.4"

# Add contrib source for zfs
RUN sed -i -e 's/ main/ main contrib/g' /etc/apt/sources.list.d/debian.sources

# Install needed packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    curl \
    ca-certificates \
    zfsutils-linux && \
    rm -rf /var/lib/apt/lists/*

# Install tools
RUN curl -LO "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl
RUN curl -L "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64" \
    -o /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq
RUN curl -LO "https://downloads.rclone.org/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-amd64.deb" && \
    dpkg -i "rclone-${RCLONE_VERSION}-linux-amd64.deb" && \
    rm "rclone-${RCLONE_VERSION}-linux-amd64.deb"

WORKDIR /app

USER root
