FROM ubuntu:22.04

SHELL [ "/bin/bash", "-c" ]

ENV DEBIAN_FRONTEND noninteractive

COPY install-packages upgrade-packages /usr/bin/

RUN yes | unminimize && \
    install-packages \
      locales && \
    locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

RUN yes | unminimize && \
    install-packages \
      bash-completion \
      build-essential \
      htop \
      iputils-ping \
      jq \
      less \
      man-db \
      nano \
      software-properties-common \
      sudo \
      time \
      lsof \
      ssl-cert \
      fish \
      zsh \
      zip unzip \
      bzip2 pigz xz-utils zstd \
      systemd udev dbus cloud-init openssh-server ubuntu-minimal containerd \
      ca-certificates curl gnupg && \
    upgrade-packages

RUN add-apt-repository -y ppa:git-core/ppa
# https://github.com/git-lfs/git-lfs/blob/main/INSTALLING.md
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    install-packages git git-lfs && \
    git lfs install --system --skip-repo

RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list

RUN install-packages \
    docker-ce \
    docker-ce-cli \
    docker-buildx-plugin \
    docker-compose-plugin

ENV NERDCTL_VERSION 1.6.0
RUN curl -sSL "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-full-${NERDCTL_VERSION}-linux-amd64.tar.gz" -o - | tar -xz -C /usr/local && \
    mkdir -p /opt/cni && \
    ln -s /usr/local/libexec/cni /opt/cni/bin && \
    rm -f /usr/local/lib/systemd/system/*.service

RUN curl -sSfL https://github.com/moby/buildkit/releases/download/v0.12.2/buildkit-v0.12.2.linux-amd64.tar.gz | tar -C /usr/local -xz

RUN rm -f /etc/systemd/system/default.target && \
    ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target

COPY rootfs/ /

RUN rm /etc/systemd/system/multi-user.target.wants/containerd.service && \
    ln -s /etc/systemd/system/containerd.service /etc/systemd/system/multi-user.target.wants/containerd.service
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
    (systemctl disable ubuntu-advantage.service || true) && \
    (systemctl disable e2scrub_reap.service || true) && \
    rm /etc/systemd/system/timers.target.wants/* && \
    rm -f /etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service

## Gitpod integration (supervisor, workspacekit)
RUN passwd -d root

RUN echo "CONTAINERD_NAMESPACE=k8s.io" >> /etc/environment
