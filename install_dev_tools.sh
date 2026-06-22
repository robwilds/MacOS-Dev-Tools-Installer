#!/bin/bash

# --- Setup Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- Mode Selection ---
INSTALL_MODE="local"  # "local" or "docker"

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --target=docker)
            INSTALL_MODE="docker"
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --target=docker      Generate multi-arch Dockerfile for containerized tools"
            echo ""
            echo "Default (no target): Interactive installer for local macOS"
            exit 0
            ;;
    esac
done

# --- Version Checking Functions ---
check_python_version() {
    if command -v python3 &>/dev/null; then
        local version
        version=$(python3 --version 2>&1 | sed -n 's/.*Python \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

check_java_version() {
    if command -v java &>/dev/null; then
        local version
        version=$(java -version 2>&1 | sed -n 's/.*version "\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' | head -1)
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

check_maven_version() {
    if command -v mvn &>/dev/null; then
        local version
        version=$(mvn -version 2>&1 | sed -n 's/.*Apache Maven \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

check_ollama_version() {
    if command -v ollama &>/dev/null; then
        local version
        version=$(ollama --version 2>&1 | sed -n 's/.*version is \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

check_opencode_version() {
    if command -v opencode &>/dev/null; then
        local version
        version=$(opencode --version 2>&1 | sed -n 's/\([0-9]*\.[0-9]*\.[0-9]*\)/\1/p')
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

check_node_version() {
    if command -v node &>/dev/null; then
        local version
        version=$(node --version 2>&1 | sed -n 's/v\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

check_claude_version() {
    if command -v claude &>/dev/null; then
        local version
        version=$(claude --version 2>&1 | sed -n 's/\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

check_angular_version() {
    if command -v ng &>/dev/null; then
        local version
        version=$(ng version 2>&1 | sed -n 's/.*Angular CLI *: \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

check_aws_cli_version() {
    if command -v aws &>/dev/null; then
        local version
        version=$(aws --version 2>&1 | sed -n 's/.*aws-cli\/\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

check_nvm_version() {
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        \. "$HOME/.nvm/nvm.sh"
        local version
        version=$(nvm --version 2>/dev/null)
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

check_mlx_llm_version() {
    if python3 -c "import mlx_lm" 2>/dev/null; then
        local version
        version=$(pip3 show mlx-lm 2>/dev/null | sed -n 's/Version: \([0-9]*\.[0-9]*\.[0-9]*\)/\1/p')
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    echo ""
    return 1
}

# --- Fetch Latest Version Functions ---
fetch_latest_python_version() {
    local version
    version=$(curl -s https://www.python.org/downloads/ 2>/dev/null | sed -n 's/.*latest released release.*Python \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' | head -1)
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "3.14.5"  # fallback to hardcoded version
    fi
}

fetch_latest_java_version() {
    # Oracle JDK 17 is fixed, but we can check if a newer 17.x is available
    echo "17.0.12"
}

fetch_latest_maven_version() {
    local version
    version=$(curl -s https://www.apache.org/dyn/closer.cgi/maven/maven-3/ 2>/dev/null | sed -n 's/.*href=".*maven-3\/\([0-9]*\.[0-9]*\.[0-9]*\)\/.*".*/\1/p' | head -1)
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "3.9.16"  # fallback to hardcoded version
    fi
}

fetch_latest_ollama_version() {
    local version
    version=$(curl -s https://registry.npmjs.org/ollama 2>/dev/null | sed -n 's/.*"version":"\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/p' | head -1)
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "0.24.0"  # fallback
    fi
}

fetch_latest_opencode_version() {
    # OpenCode doesn't have a public API, use the version from --version after install
    echo "1.14.48"
}

fetch_latest_node_version() {
    local major
    major=$(echo "$NODE_VERSION" | cut -d. -f1)
    local version
    version=$(curl -s "https://nodejs.org/dist/latest-v${major}.x/" 2>/dev/null | sed -n 's/.*href="node-v\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' | head -1)
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "$NODE_VERSION"  # fallback to selected version
    fi
}

fetch_latest_claude_version() {
    local version
    version=$(npm view @anthropic-ai/claude-code version 2>/dev/null | tr -d '\n')
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "2.1.142"  # fallback
    fi
}

fetch_latest_angular_version() {
    local version
    version=$(npm view @angular/cli version 2>/dev/null | tr -d '\n')
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "19.2.5"  # fallback
    fi
}

fetch_latest_nvm_version() {
    local version
    version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null | sed -n 's/.*"tag_name": "v\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/p')
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "0.40.4"   # fallback
    fi
}

fetch_latest_aws_cli_version() {
    local version
    version=$(curl -s https://api.github.com/repos/aws/aws-cli/releases/latest 2>/dev/null | sed -n 's/.*"tag_name": "\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/p')
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "2.19.40"  # fallback
    fi
}

fetch_latest_mlx_llm_version() {
    # MLX-LM is on PyPI, fetch latest version
    local version
    version=$(pip3 index versions mlx-lm 2>/dev/null | sed -n 's/.*\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' | head -1)
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "0.0.1"  # fallback
    fi
}

prompt_ollama_small_model() {
    echo ""
    read -p "Download a small model (<14B) now? (y/n) [y]: " choice
    choice=${choice:-y}
    [[ ! "$choice" =~ ^[Yy]$ ]] && return

    local models=(
        "llama3.2:1b"
        "llama3.2:3b"
        "qwen2.5:3b"
        "phi3:3.8b"
        "gemma2:2b"
        "qwen2.5:7b"
        "mistral:7b"
        "phi3:7b"
        "gemma2:9b"
        "codellama:7b"
        "deepseek-coder:6.7b"
    )

    echo "Popular small models (<14B):"
    for i in "${!models[@]}"; do
        echo "  $((i+1)). ${models[i]}"
    done
    echo "  0. Custom model name"

    read -p "Select [1]: " selection
    selection=${selection:-1}

    local model=""
    if [[ "$selection" == "0" ]]; then
        read -p "Enter model name (e.g., llama3.2:1b): " model
    elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#models[@]}" ]; then
        model="${models[$((selection-1))]}"
    else
        model="${models[0]}"
    fi

    if [ -n "$model" ]; then
        echo "Starting background pull for $model..."
        local log_file="/tmp/ollama_pull_${model//:/_}.log"
        ollama pull "$model" > "$log_file" 2>&1 &
        local pid=$!
        echo "Pulling $model in background (PID: $pid)"
        echo "Log: $log_file"
        echo "Check progress with: tail -f $log_file"
        echo "Or check status with: ollama ps / ollama list"
    fi
}

fetch_node_version_choices() {
    local majors
    majors=$(curl -s https://nodejs.org/dist/ 2>/dev/null | sed -n 's/.*href="latest-v\([0-9]*\)\.x\/".*/\1/p' | sort -rn | head -3)
    for major in $majors; do
        local full
        full=$(curl -s "https://nodejs.org/dist/latest-v${major}.x/" 2>/dev/null | sed -n 's/.*href="node-v\([0-9]*\.[0-9]*\.[0-9]*\)\.pkg".*/\1/p' | head -1)
        if [ -n "$full" ]; then
            echo "$major $full"
        fi
    done
}

prompt_node_version() {
    local -a majors=()
    local -a versions=()
    local i=1

    echo -e "${BLUE}Fetching available Node.js versions...${NC}"

    while IFS=' ' read -r major full; do
        majors+=("$major")
        versions+=("$full")
        echo "  $i. Node.js $full (v$major)"
        i=$((i + 1))
    done < <(fetch_node_version_choices)

    if [ ${#versions[@]} -eq 0 ]; then
        echo -e "${YELLOW}Could not fetch versions — using default Node.js $DEFAULT_NODE_VERSION${NC}"
        NODE_VERSION="$DEFAULT_NODE_VERSION"
        return
    fi

    echo ""
    read -p "Select Node.js version [1]: " choice
    choice=${choice:-1}

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#versions[@]}" ]; then
        NODE_VERSION="${versions[$((choice-1))]}"
    else
        NODE_VERSION="${versions[0]}"
    fi

    echo -e "${GREEN}Using Node.js $NODE_VERSION${NC}"
}

# Compare versions: returns 0 if $1 >= $2
version_gte() {
    local installed="$1"
    local required="$2"

    local inst_major inst_minor inst_patch
    local req_major req_minor req_patch

    IFS='.' read -r inst_major inst_minor inst_patch <<< "$installed"
    IFS='.' read -r req_major req_minor req_patch <<< "$required"

    inst_major=${inst_major:-0}
    inst_minor=${inst_minor:-0}
    inst_patch=${inst_patch:-0}
    req_major=${req_major:-0}
    req_minor=${req_minor:-0}
    req_patch=${req_patch:-0}

    if [ "$inst_major" -gt "$req_major" ]; then
        return 0
    elif [ "$inst_major" -lt "$req_major" ]; then
        return 1
    fi

    if [ "$inst_minor" -gt "$req_minor" ]; then
        return 0
    elif [ "$inst_minor" -lt "$req_minor" ]; then
        return 1
    fi

    if [ "$inst_patch" -ge "$req_patch" ]; then
        return 0
    fi

    return 1
}

# --- Version Verification Functions ---
verify_tool_version() {
    local tool_name="$1"
    local version_cmd="$2"
    
    echo -n "  Checking $tool_name... "
    local output
    if output=$($version_cmd 2>&1); then
        echo -e "${GREEN}OK${NC}"
        echo -e "    ${BLUE}$output${NC}"
    else
        echo -e "${YELLOW}FAILED${NC}"
    fi
}

verify_all_versions() {
    source ~/.zshrc
    
    echo ""
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${BLUE}Verifying installations...${NC}"
    
    if [ "$INSTALL_PYTHON" = true ]; then
        verify_tool_version "Python" "python3 --version"
    fi
    if [ "$INSTALL_JAVA" = true ]; then
        verify_tool_version "Java" "java -version"
    fi
    if [ "$INSTALL_MAVEN" = true ]; then
        verify_tool_version "Maven" "mvn -version"
    fi
    if [ "$INSTALL_OLLAMA" = true ]; then
        verify_tool_version "Ollama" "ollama --version"
    fi
    if [ "$INSTALL_OPENCODE" = true ]; then
        verify_tool_version "OpenCode" "opencode --version"
    fi
    if [ "$INSTALL_NODE" = true ]; then
        verify_tool_version "Node.js" "node --version"
    fi
    if [ "$INSTALL_CLAUDE" = true ]; then
        verify_tool_version "Claude Code" "claude --version"
    fi
    if [ "$INSTALL_NVM" = true ]; then
        verify_tool_version "nvm" "nvm --version"
    fi
    if [ "$INSTALL_AWS_CLI" = true ]; then
        verify_tool_version "AWS CLI" "aws --version"
    fi
    if [ "$INSTALL_ANGULAR" = true ]; then
        verify_tool_version "Angular CLI" "ng version"
    fi
    if [ "$INSTALL_MLX_LLM" = true ]; then
        verify_tool_version "MLX-LM" "python3 -c \"import mlx_lm; print('mlx-lm installed')\""
    fi
    
    echo -e "${BLUE}------------------------------------------------------------${NC}"
}

# Track which tools to install
INSTALL_PYTHON=false
INSTALL_JAVA=false
INSTALL_MAVEN=false
INSTALL_OLLAMA=false
INSTALL_OPENCODE=false
INSTALL_NODE=false
INSTALL_CLAUDE=false
INSTALL_ANGULAR=false
INSTALL_NVM=false
INSTALL_AWS_CLI=false
INSTALL_MLX_LLM=false

# Default Node.js version (used when non-interactive or when fetch fails)
DEFAULT_NODE_VERSION="26.1.0"
NODE_VERSION="$DEFAULT_NODE_VERSION"

# --- Docker Containerization Functions ---
generate_dockerfile() {
    local output_file="${1:-Dockerfile}"
    local node_version="${2:-26.1.0}"

    cat > "$output_file" << 'DOCKERFILE'
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

# Node.js __NODE_VERSION__ (install to version-agnostic path)
FROM base AS nodejs
ARG TARGETARCH
RUN NODE_ARCH="${TARGETARCH:-$(uname -m)}" && \
    if [ "$NODE_ARCH" = "arm64" ] || [ "$NODE_ARCH" = "aarch64" ]; then NODE_ARCH="arm64"; else NODE_ARCH="x64"; fi && \
    curl -fsSL https://nodejs.org/dist/v__NODE_VERSION__/node-v__NODE_VERSION__-linux-${NODE_ARCH}.tar.xz | tar -xJ -C /opt && \
    mv /opt/node-v__NODE_VERSION__-linux-${NODE_ARCH} /opt/node && \
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
DOCKERFILE

    sed -i '' "s/__NODE_VERSION__/${node_version}/g" "$output_file"
}

generate_compose() {
    local output_file="${1:-docker-compose.yml}"
    local image_name="${2:-dev-tools}"
    
    cat > "$output_file" << COMPOSE
version: '3.8'

services:
  ${image_name}:
    container_name: ${image_name}
    image: ${image_name}:latest
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./projects:/workspace
      - ~/.gitconfig:/root/.gitconfig:ro
    environment:
      - JAVA_HOME=/opt/jdk-17.0.12
      - MAVEN_HOME=/opt/maven/apache-maven-3.9.16
    tty: true
    stdin_open: true
    command: /bin/bash
COMPOSE
}

generate_dockerignore() {
    local output_file="${1:-.dockerignore}"
    
    cat > "$output_file" << 'DOCKERIGNORE'
.git
.gitignore
.env
node_modules
__pycache__
*.pyc
*.pyo
.DS_Store
*.md
log*
*.log
.DS_Store
.dockerignore
docker-compose*.yml
DOCKERIGNORE
}

build_and_run_docker() {
    local default_name="dev-tools"

    if ! docker info &>/dev/null; then
        echo -e "${YELLOW}Docker daemon is not running. Attempting to start Docker...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open -a Docker
        else
            sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null || {
                echo -e "${RED}Could not start Docker automatically. Please start Docker and try again.${NC}"
                exit 1
            }
        fi
        echo -n "Waiting for Docker to become ready.."
        for i in {1..60}; do
            if docker info &>/dev/null; then
                echo -e " ${GREEN}ready!${NC}"
                break
            fi
            echo -n "."
            sleep 2
        done
        if ! docker info &>/dev/null; then
            echo -e " ${RED}timed out. Please start Docker manually and try again.${NC}"
            exit 1
        fi
    fi

    read -p "Enter container name (default: ${default_name}): " container_name
    container_name=${container_name:-$default_name}
    container_name=$(echo "$container_name" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_-' '_' | sed 's/_*$//')

    echo -e "${GREEN}Generating Docker build files for '${container_name}'...${NC}"
    generate_dockerfile Dockerfile "$NODE_VERSION"
    generate_compose docker-compose.yml "$container_name"
    generate_dockerignore .dockerignore
    echo -e "${GREEN}Docker files generated.${NC}"

    echo ""
    echo -e "${BLUE}Building Docker image (native arch)...${NC}"
    if docker build -t "${container_name}:latest" .; then
        echo -e "${GREEN}Image built successfully.${NC}"
    else
        echo -e "${RED}Docker build failed.${NC}"
        exit 1
    fi

    echo ""
    echo -e "${BLUE}Starting container...${NC}"
    docker-compose up -d
    echo ""
    echo -e "${GREEN}Container running! Access it with:${NC}"
    echo -e "  ${BLUE}docker exec -it ${container_name} bash${NC}"
}

# Docker mode: Generate files instead of installing
if [ "$INSTALL_MODE" == "docker" ]; then
    echo -e "${GREEN}Generating Docker build files...${NC}"
    
    generate_dockerfile Dockerfile "$NODE_VERSION"
    echo -e "${GREEN}Created Dockerfile${NC}"

    generate_compose docker-compose.yml
    echo -e "${GREEN}Created docker-compose.yml${NC}"
    
    generate_dockerignore .dockerignore
    echo -e "${GREEN}Created .dockerignore${NC}"
    
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Docker Build Instructions${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    echo -e "${GREEN}To build multi-arch image (Intel + ARM):${NC}"
    echo -e "  ${BLUE}docker buildx create --use${NC}"
    echo -e "  ${BLUE}docker buildx build --platform linux/amd64,linux/arm64 -t dev-tools:latest .${NC}"
    echo ""
    echo -e "${GREEN}To build single-arch (native):${NC}"
    echo -e "  ${BLUE}docker build -t dev-tools:latest .${NC}"
    echo ""
    echo -e "${BLUE}To run:${NC}"
    echo -e "  ${BLUE}docker-compose up -d${NC}"
    echo -e "  ${BLUE}docker exec -it dev-tools bash${NC}"
    echo ""
    
    exit 0
fi

# Check if upgrade is available and prompt user
should_upgrade() {
    local tool_name="$1"
    local installed_version="$2"
    local latest_version="$3"

    if [ -z "$installed_version" ]; then
        return 0  # Not installed, should install
    fi

    if version_gte "$installed_version" "$latest_version"; then
        return 1  # Already at latest version
    fi

    # Prompt for upgrade
    echo -e "${YELLOW}Newer version available for $tool_name!${NC}"
    echo -e "  Installed: $installed_version"
    echo -e "  Latest:    $latest_version"
    read -p "  Upgrade? (y/n) [y]: " upgrade_choice
    upgrade_choice=${upgrade_choice:-y}

    if [[ "$upgrade_choice" == "y" || "$upgrade_choice" == "Y" ]]; then
        return 0  # Should upgrade
    fi

    return 1  # Should not upgrade
}

# Parse user input (comma-separated numbers or "all")
parse_selection() {
    local selection="$1"

    if [[ "$selection" == "0" ]]; then
        INSTALL_PYTHON=true
        INSTALL_JAVA=true
        INSTALL_MAVEN=true
        INSTALL_OLLAMA=true
        INSTALL_OPENCODE=true
        INSTALL_NODE=true
        INSTALL_CLAUDE=true
        INSTALL_ANGULAR=true
        INSTALL_NVM=true
        INSTALL_AWS_CLI=true
        INSTALL_MLX_LLM=true
        return
    fi

    IFS=',' read -ra numbers <<< "$selection"
    for num in "${numbers[@]}"; do
          case "${num// /}" in
               1) INSTALL_PYTHON=true ;;
               2) INSTALL_JAVA=true ;;
               3) INSTALL_MAVEN=true ;;
               4) INSTALL_OLLAMA=true ;;
               5) INSTALL_OPENCODE=true ;;
               6) INSTALL_NVM=true ;;
               7) INSTALL_NODE=true ;;
               8) INSTALL_CLAUDE=true ;;
               9) INSTALL_ANGULAR=true ;;
             10) INSTALL_AWS_CLI=true ;;
             11) INSTALL_MLX_LLM=true ;;
          esac
    done

    # Handle letter options
    case "$selection" in
        d) build_and_run_docker; exit 0 ;;
    esac
}

show_menu() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Development Tools Installer${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    echo "Select tools to install (comma-separated numbers):"
    echo ""
    echo "   1.   Python 3.14.5"
    echo "   2.   Java 17 (Oracle JDK)"
    echo "   3.   Maven 3.9.16"
    echo "   4.   Ollama"
    echo "   5.   OpenCode"
    echo "   6.   nvm (Node Version Manager)"
    echo "   7.   Node.js 26.1.0"
    echo "   8.   Claude Code"
    echo "   9.   Angular CLI"
    echo "   10.  AWS CLI v2"
    echo "   11.  MLX-LM"
    echo ""
    echo "   d.   Build and run Docker container"
    echo ""
    echo "   0.   Install all tools"
    echo ""
    echo "   q.   Quit"
    echo ""
}


# If script is run with arguments, parse them as selections
if [ $# -gt 0 ]; then
    # Filter out --target flags and pass rest as selection
    non_target_args=()
    for arg in "$@"; do
        case $arg in
            --target=*) ;;
            *) non_target_args+=("$arg") ;;
        esac
    done
    parse_selection "${non_target_args[*]:-0}"
else
    show_menu
    read -p "Enter your selection: " selection
    [[ "$selection" == "q" ]] && exit 0
    parse_selection "$selection"
fi

# If interactive menu, prompt for Node.js version
if [ "$INSTALL_NODE" = true ] && [ $# -eq 0 ]; then
    prompt_node_version
fi

echo -e "${BLUE}Starting Manual Installation Script (No Brew/Pyenv)...${NC}"

# Prompt for sudo password upfront so subsequent sudo commands don't interrupt
sudo -v
# Keep sudo alive in the background
(while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null) &

# Detect Architecture
ARCH=$(uname -m)
if [ "$ARCH" == "arm64" ]; then
    echo "Detected Apple Silicon (arm64)"
    JAVA_ARCH="aarch64"
    NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}.pkg"
else
    echo "Detected Intel (x86_64)"
    JAVA_ARCH="x64"
    NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}.pkg"
fi

JAVA_VERSION="17.0.12"
JAVA_URL="https://download.oracle.com/java/17/archive/jdk-${JAVA_VERSION}_macos-${JAVA_ARCH}_bin.tar.gz"
echo "Java URL: $JAVA_URL"

# Create a temporary folder for downloads
TMP_DIR=$(mktemp -d)
cd $TMP_DIR

# 1. INSTALL PYTHON (Official PKG)
if [ "$INSTALL_PYTHON" = true ]; then
    PYTHON_INSTALLED=$(check_python_version)
    PYTHON_LATEST=$(fetch_latest_python_version)
    if should_upgrade "Python" "$PYTHON_INSTALLED" "$PYTHON_LATEST"; then
        echo -e "${GREEN}Installing Python...${NC}"
        if [ -n "$PYTHON_INSTALLED" ]; then
            echo -e "${YELLOW}Current version: $PYTHON_INSTALLED${NC}"
        fi
        curl -L -O https://www.python.org/ftp/python/3.14.5/python-3.14.5-macos11.pkg
        sudo installer -pkg python-3.14.5-macos11.pkg -target /
    else
        echo -e "${YELLOW}Python already at latest version ($PYTHON_INSTALLED), skipping...${NC}"
    fi
fi

# 2. INSTALL JAVA (Oracle JDK)
if [ "$INSTALL_JAVA" = true ]; then
    JAVA_INSTALLED=$(check_java_version)
    JAVA_LATEST=$(fetch_latest_java_version)
    if should_upgrade "Java" "$JAVA_INSTALLED" "$JAVA_LATEST"; then
        echo -e "${GREEN}Installing Java 17...${NC}"
        if [ -n "$JAVA_INSTALLED" ]; then
            echo -e "${YELLOW}Current version: $JAVA_INSTALLED${NC}"
        fi
        JAVA_TAR=$(basename "$JAVA_URL")
        curl -L -O "$JAVA_URL"
        tar -xzf "$JAVA_TAR"
        sudo mkdir -p /Library/Java/JavaVirtualMachines
        JDK_FOLDER=$(find . -maxdepth 1 -type d -name "jdk*" | head -1 | sed 's|^\./||')
        if [ -z "$JDK_FOLDER" ]; then
            echo "ERROR: Could not find extracted JDK directory"
            exit 1
        fi
        sudo mv "$JDK_FOLDER" /Library/Java/JavaVirtualMachines/
        JDK_HOME="/Library/Java/JavaVirtualMachines/$JDK_FOLDER/Contents/Home"
        sudo ln -sf "$JDK_HOME/bin/java" /usr/local/bin/java
        sudo ln -sf "$JDK_HOME/bin/javac" /usr/local/bin/javac
    else
        echo -e "${YELLOW}Java already at latest version ($JAVA_INSTALLED), skipping...${NC}"
    fi
fi

# 3. INSTALL MAVEN
if [ "$INSTALL_MAVEN" = true ]; then
    MAVEN_INSTALLED=$(check_maven_version)
    MAVEN_LATEST=$(fetch_latest_maven_version)
    if should_upgrade "Maven" "$MAVEN_INSTALLED" "$MAVEN_LATEST"; then
        echo -e "${GREEN}Installing Maven...${NC}"
        if [ -n "$MAVEN_INSTALLED" ]; then
            echo -e "${YELLOW}Current version: $MAVEN_INSTALLED${NC}"
        fi
        curl -L -O https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.tar.gz
        tar -xzf apache-maven-3.9.16-bin.tar.gz
        sudo mkdir -p /opt/maven
        sudo rm -rf /opt/maven/maven
        sudo mv apache-maven-3.9.16 /opt/maven/maven
        sudo ln -sf /opt/maven/maven/bin/mvn /usr/local/bin/mvn
    else
        echo -e "${YELLOW}Maven already at latest version ($MAVEN_INSTALLED), skipping...${NC}"
    fi
fi

# 4. INSTALL OLLAMA (Official Install Script)
if [ "$INSTALL_OLLAMA" = true ]; then
    OLLAMA_INSTALLED=$(check_ollama_version)
    OLLAMA_LATEST=$(fetch_latest_ollama_version)
    if should_upgrade "Ollama" "$OLLAMA_INSTALLED" "$OLLAMA_LATEST"; then
        echo -e "${GREEN}Installing Ollama...${NC}"
        if [ -n "$OLLAMA_INSTALLED" ]; then
            echo -e "${YELLOW}Current version: $OLLAMA_INSTALLED${NC}"
        fi
        curl -fsSL https://ollama.com/install.sh | sh
        source ~/.nvm/nvm.sh 2>/dev/null || true
        # Prompt for model download only on fresh install
        if [ -z "$OLLAMA_INSTALLED" ]; then
            prompt_ollama_small_model
        fi
    else
        echo -e "${YELLOW}Ollama already at latest version ($OLLAMA_INSTALLED), skipping...${NC}"
    fi
fi

# 5. INSTALL OPENCODE (Requested Command)
if [ "$INSTALL_OPENCODE" = true ]; then
    OPENCODE_INSTALLED=$(check_opencode_version)
    OPENCODE_LATEST=$(fetch_latest_opencode_version)
    if should_upgrade "OpenCode" "$OPENCODE_INSTALLED" "$OPENCODE_LATEST"; then
        echo -e "${GREEN}Installing OpenCode...${NC}"
        if [ -n "$OPENCODE_INSTALLED" ]; then
            echo -e "${YELLOW}Current version: $OPENCODE_INSTALLED${NC}"
        fi
        curl -fsSL https://opencode.ai/install | bash
    else
        echo -e "${YELLOW}OpenCode already at latest version ($OPENCODE_INSTALLED), skipping...${NC}"
    fi
fi

# 6. INSTALL NVM (Node Version Manager)
if [ "$INSTALL_NVM" = true ]; then
    NVM_INSTALLED=$(check_nvm_version)
    NVM_LATEST=$(fetch_latest_nvm_version)
    if should_upgrade "nvm" "$NVM_INSTALLED" "$NVM_LATEST"; then
        echo -e "${GREEN}Installing nvm...${NC}"
        if [ -n "$NVM_INSTALLED" ]; then
            echo -e "${YELLOW}Current version: $NVM_INSTALLED${NC}"
        fi
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_LATEST}/install.sh" | bash
    else
        echo -e "${YELLOW}nvm already at latest version ($NVM_INSTALLED), skipping...${NC}"
    fi
fi

# 7. INSTALL NODE.JS (Requirement for Claude Code)
if [ "$INSTALL_NODE" = true ]; then
    NODE_INSTALLED=$(check_node_version)
    NODE_LATEST=$(fetch_latest_node_version)
    if should_upgrade "Node.js" "$NODE_INSTALLED" "$NODE_LATEST"; then
        echo -e "${GREEN}Installing Node.js (for Claude Code)...${NC}"
        if [ -n "$NODE_INSTALLED" ]; then
            echo -e "${YELLOW}Current version: v$NODE_INSTALLED${NC}"
        fi
        curl -L -O "$NODE_URL"
        sudo installer -pkg "node-v${NODE_VERSION}.pkg" -target /
    else
        echo -e "${YELLOW}Node.js already at latest version (v$NODE_INSTALLED), skipping...${NC}"
    fi
fi

# 8. INSTALL CLAUDE CODE
if [ "$INSTALL_CLAUDE" = true ]; then
    CLAUDE_INSTALLED=$(check_claude_version)
    CLAUDE_LATEST=$(fetch_latest_claude_version)
    if should_upgrade "Claude Code" "$CLAUDE_INSTALLED" "$CLAUDE_LATEST"; then
        echo -e "${GREEN}Installing Claude Code via npm...${NC}"
        if [ -n "$CLAUDE_INSTALLED" ]; then
            echo -e "${YELLOW}Current version: $CLAUDE_INSTALLED${NC}"
    fi
        sudo /usr/local/bin/npm install -g @anthropic-ai/claude-code
    else
        echo -e "${YELLOW}Claude Code already at latest version ($CLAUDE_INSTALLED), skipping...${NC}"
    fi
fi

# 9. INSTALL ANGULAR CLI (requires Node.js/npm)
if [ "$INSTALL_ANGULAR" = true ]; then
    ANGULAR_INSTALLED=$(check_angular_version)
    ANGULAR_LATEST=$(fetch_latest_angular_version)
    if should_upgrade "Angular CLI" "$ANGULAR_INSTALLED" "$ANGULAR_LATEST"; then
        echo -e "${GREEN}Installing Angular CLI...${NC}"
        if [ -n "$ANGULAR_INSTALLED" ]; then
            echo -e "${YELLOW}Current version: $ANGULAR_INSTALLED${NC}"
        fi
        sudo /usr/local/bin/npm install -g @angular/cli
    else
        echo -e "${YELLOW}Angular CLI already at latest version ($ANGULAR_INSTALLED), skipping...${NC}"
    fi
fi

# 10. INSTALL AWS CLI v2 (Official Installer from AWS)
if [ "$INSTALL_AWS_CLI" = true ]; then
    AWS_CLI_INSTALLED=$(check_aws_cli_version)
    AWS_CLI_LATEST=$(fetch_latest_aws_cli_version)
    if should_upgrade "AWS CLI" "$AWS_CLI_INSTALLED" "$AWS_CLI_LATEST"; then
        echo -e "${GREEN}Installing AWS CLI v2...${NC}"
        if [ -n "$AWS_CLI_INSTALLED" ]; then
            echo -e "${YELLOW}Current version: $AWS_CLI_INSTALLED${NC}"
        fi
        curl -fsSL https://awscli.amazonaws.com/AWSCLIV2.pkg -o AWSCLIV2.pkg
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm -f AWSCLIV2.pkg
    else
        echo -e "${YELLOW}AWS CLI already at latest version ($AWS_CLI_INSTALLED), skipping...${NC}"
    fi
fi

# 11. INSTALL MLX-LM (via pip)
if [ "$INSTALL_MLX_LLM" = true ]; then
    MLX_LLM_INSTALLED=$(check_mlx_llm_version)
    MLX_LLM_LATEST=$(fetch_latest_mlx_llm_version)
    if should_upgrade "MLX-LM" "$MLX_LLM_INSTALLED" "$MLX_LLM_LATEST"; then
        echo -e "${GREEN}Installing MLX-LM via pip...${NC}"
        if [ -n "$MLX_LLM_INSTALLED" ]; then
            echo -e "${YELLOW}Current version: $MLX_LLM_INSTALLED${NC}"
        fi
        PIP_CMD=$(command -v pip3 || command -v pip) && $PIP_CMD install mlx-lm
    else
        echo -e "${YELLOW}MLX-LM already at latest version ($MLX_LLM_INSTALLED), skipping...${NC}"
    fi
fi

# --- PATH CONFIGURATION ---
echo -e "${BLUE}Configuring ZSH path...${NC}"
# Use the dynamic JDK folder name for the JAVA_HOME export (only if Java was installed)
if [ "$INSTALL_JAVA" = true ]; then
    JDK_PATH="/Library/Java/JavaVirtualMachines/$JDK_FOLDER/Contents/Home"
else
    # Try to find existing JDK if Java wasn't installed in this run
    existing_jdk=$(ls -d /Library/Java/JavaVirtualMachines/jdk* 2>/dev/null | head -1)
    if [ -n "$existing_jdk" ]; then
        JDK_PATH="$existing_jdk/Contents/Home"
    else
        JDK_PATH=""
    fi
fi

grep -q "# dev_tools_config" ~/.zshrc || {
    echo "" >> ~/.zshrc
    echo "# dev_tools_config" >> ~/.zshrc
    if [ -n "$JDK_PATH" ]; then
        echo "export JAVA_HOME=\"$JDK_PATH\"" >> ~/.zshrc
    fi
    echo 'export MAVEN_HOME="/opt/maven/maven"' >> ~/.zshrc
    echo 'export PATH="$PATH:$JAVA_HOME/bin:$MAVEN_HOME/bin:/usr/local/bin"' >> ~/.zshrc
}

# Add mlx_lm shell function (idempotent)
grep -q "mlx_lm()" ~/.zshrc || {
    echo "" >> ~/.zshrc
    echo "# mlx_lm alias" >> ~/.zshrc
    echo 'mlx_lm() { python3 -m mlx_lm "$@"; }' >> ~/.zshrc
}

# Final Cleanup
cd ~
rm -rf $TMP_DIR

verify_all_versions
