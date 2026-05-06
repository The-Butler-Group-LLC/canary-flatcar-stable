FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64

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