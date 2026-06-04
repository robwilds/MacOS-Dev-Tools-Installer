# Multi-arch Dockerfile for development tools
# Build with: docker buildx build --platform linux/amd64,linux/arm64 -t dev-tools:latest .

FROM --platform=$BUILDPLATFORM ubuntu:22.04 AS base
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    unzip \
    sudo \
    openjdk-17-jdk \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Python 3.14.5 (build from source for latest version)
FROM base AS python
ARG TARGETARCH
RUN ARCH_NAME="${TARGETARCH:-$(uname -m)}" && \
    if [ "$ARCH_NAME" = "arm64" ] || [ "$ARCH_NAME" = "aarch64" ]; then ARCH_NAME="aarch64"; else ARCH_NAME="x86_64"; fi && \
    cd /tmp && \
    curl -fsSL https://www.python.org/ftp/python/3.14.5/Python-3.14.5.tar.xz | tar -xJ && \
    cd Python-3.14.5 && \
    ./configure --enable-optimizations --with-ensurepip=install --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && rm -rf Python-3.14.5
RUN python3 --version

# Java 17 (extract from tarball)
FROM base AS java
ARG TARGETARCH
RUN JAVA_ARCH="${TARGETARCH:-$(uname -m)}" && \
    if [ "$JAVA_ARCH" = "arm64" ] || [ "$JAVA_ARCH" = "aarch64" ]; then JAVA_ARCH="aarch64"; else JAVA_ARCH="x64"; fi && \
    curl -fsSL https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-${JAVA_ARCH}_bin.tar.gz | tar -xz -C /opt && \
    ln -sf /opt/jdk-17.0.12/bin/java /usr/local/bin/java && \
    ln -sf /opt/jdk-17.0.12/bin/javac /usr/local/bin/javac
ENV JAVA_HOME=/opt/jdk-17.0.12
ENV PATH=/usr/local/bin:$JAVA_HOME/bin:$PATH

# Maven 3.9.16
FROM base AS maven
RUN mkdir -p /opt/maven && \
    curl -fsSL https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.tar.gz | tar -xz -C /opt/maven && \
    ln -sf /opt/maven/apache-maven-3.9.16/bin/mvn /usr/local/bin/mvn
ENV MAVEN_HOME=/opt/maven/apache-maven-3.9.16
ENV PATH=/usr/local/bin:$MAVEN_HOME/bin:$PATH

# Node.js 26.1.0 (install to version-agnostic path)
FROM base AS nodejs
ARG TARGETARCH
RUN NODE_ARCH="${TARGETARCH:-$(uname -m)}" && \
    if [ "$NODE_ARCH" = "arm64" ] || [ "$NODE_ARCH" = "aarch64" ]; then NODE_ARCH="arm64"; else NODE_ARCH="x64"; fi && \
    curl -fsSL https://nodejs.org/dist/v26.1.0/node-v26.1.0-linux-${NODE_ARCH}.tar.xz | tar -xJ -C /opt && \
    mv /opt/node-v26.1.0-linux-${NODE_ARCH} /opt/node && \
    ln -sf /opt/node/bin/node /usr/local/bin/node && \
    ln -sf /opt/node/bin/npm /usr/local/bin/npm && \
    ln -sf /opt/node/bin/npx /usr/local/bin/npx
ENV PATH=/usr/local/bin:/opt/node/bin:$PATH

# Final combined image
FROM base
ARG TARGETARCH
COPY --from=python /usr/local /usr/local
COPY --from=java /opt/jdk-17.0.12 /opt/jdk-17.0.12
COPY --from=maven /opt/maven/apache-maven-3.9.16 /opt/maven/apache-maven-3.9.16
COPY --from=nodejs /opt/node /opt/node

ENV JAVA_HOME=/opt/jdk-17.0.12
ENV MAVEN_HOME=/opt/maven/apache-maven-3.9.16
ENV PATH=/usr/local/bin:/opt/node/bin:$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH

# Angular CLI (installed via npm)
RUN npm install -g @angular/cli

# nvm (Node Version Manager)
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash

# nvm: alias default to the system Node.js installed at /opt/node
RUN bash -c 'source "$HOME/.nvm/nvm.sh" && nvm alias default system'

# AWS CLI v2 (official installer)
RUN AWS_ARCH="${TARGETARCH:-$(uname -m)}" && \
    if [ "$AWS_ARCH" = "arm64" ] || [ "$AWS_ARCH" = "aarch64" ]; then AWS_ARCH="aarch64"; else AWS_ARCH="x86_64"; fi && \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/

WORKDIR /workspace
CMD ["/bin/bash"]
