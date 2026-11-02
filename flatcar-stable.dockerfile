FROM ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c

RUN apt-get update && apt-get install -y \
    qemu-system-x86 \
    qemu-utils \
    curl \
    openssh-client \
    openssh-server \
    netcat-openbsd \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Butane
RUN curl -L -o /usr/local/bin/butane \
    https://github.com/coreos/butane/releases/latest/download/butane-x86_64-unknown-linux-gnu && \
    chmod +x /usr/local/bin/butane

# Install Trivy
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh

WORKDIR /flatcar

# Download Flatcar image
RUN curl -L -o flatcar.img \
    https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]