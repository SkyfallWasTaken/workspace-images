FROM fedora:38

SHELL [ "/bin/bash", "-c" ]

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

RUN dnf install -y \
      htop \
      iputils \
      jq \
      less \
      man-db \
      nano \
      sudo \
      time \
      lsof \
      fish \
      zsh \
      zip unzip \
      bzip2 pigz xz zstd \
      systemd udev dbus dbus-daemon cloud-init openssh-server \
      ca-certificates curl gnupg \
      git \
      passwd \
      libsss* && \
    dnf clean all

RUN dnf -y install dnf-plugins-core
RUN dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo -y
RUN dnf install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin && \
    dnf clean all

ENV NERDCTL_VERSION 1.6.0
RUN curl -sSL "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-full-${NERDCTL_VERSION}-linux-amd64.tar.gz" -o - | tar -xz -C /usr/local && \
    mkdir -p /opt/cni && \
    ln -s /usr/local/libexec/cni /opt/cni/bin && \
    rm -f /usr/local/lib/systemd/system/*.service

RUN curl -sSfL https://github.com/moby/buildkit/releases/download/v0.12.2/buildkit-v0.12.2.linux-amd64.tar.gz | tar -C /usr/local -xz

RUN rm -f /etc/systemd/system/default.target && \
    ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target

COPY rootfs/ /

RUN ln -s /etc/systemd/system/containerd.service /etc/systemd/system/multi-user.target.wants/containerd.service
RUN ln -s /etc/systemd/system/buildkit.service /etc/systemd/system/multi-user.target.wants/buildkit.service
RUN ln -s /etc/systemd/system/buildkit.socket /etc/systemd/system/multi-user.target.wants/buildkit.socket

# remove services and timers
RUN (systemctl disable disable apt-daily-upgrade.timer || true) && \
    (systemctl disable apt-daily.timer || true) && \
    (systemctl disable apt-daily-upgrade.service || true) && \
    (systemctl disable apt-daily.service || true) && \
    (systemctl disable man-db.timer || true) && \
    (systemctl disable man-db.service || true) && \
    (systemctl disable motd-news.service || true) && \
    (systemctl disable motd-news.timer || true) && \
    (systemctl disable bluetooth.target || true) && \
    (systemctl disable ua-timer.timer || true) && \
    (systemctl disable ua-timer.service || true) && \
    (systemctl disable e2scrub_reap.service || true) && \
    (systemctl disable sshd-keygen@rsa.service || true) && \
    rm /etc/systemd/system/timers.target.wants/*

# disable root passwork for interactive login
RUN passwd -d root

RUN echo "CONTAINERD_NAMESPACE=k8s.io" >> /etc/environment

# cleanup
RUN rm -rf \
    /run/log/journal \
    /var/lib/containerd/* \
    /usr/share/doc/* \
    /usr/local/bin/bypass4netns \
    /usr/local/bin/containerd-fuse-overlayfs-grpc \
    /usr/local/bin/fuse-overlayfs \
    /usr/local/bin/bypass4netnsd \
    /usr/local/bin/containerd-rootless-setuptool.sh \
    /usr/local/bin/rootlesskit \
    /usr/local/bin/containerd-rootless.sh \
    /usr/local/bin/ipfs \
    /usr/local/bin/containerd-stargz-grpc

RUN systemctl enable dbus-broker.service
RUN systemctl enable docker.service
