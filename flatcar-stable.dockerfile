FROM ubuntu:26.04@sha256:c098726dd9b9733f3e885f8de0ef375206a311b0a317eadc40d347b1115fb944

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