# MacOS Dev Tools Installer

Installs development tools locally on macOS or builds a Docker container with a subset of tools.

## Usage

### Local Installation (macOS)

#### Interactive Menu (default)
```bash
./install_dev_tools.sh
```

Run without arguments to see an interactive menu where you can select which tools to install. When installing Node.js via the interactive menu, you'll be prompted to choose a version from the latest three major releases.

#### Select Specific Tools
You can also pass a comma-separated list of numbers directly:
```bash
./install_dev_tools.sh "1,3,5"
```

This installs Python, Maven, and OpenCode.

#### Install All Tools
- In the menu: select `0`
- Via arguments: pass `0`
```bash
./install_dev_tools.sh "0"
```

#### Help
```bash
./install_dev_tools.sh --help
```

Displays usage information and available options.

### Docker Containerization

Two approaches — one-step automated or manual.

#### One-step: Auto-build and run (menu item 11 or `"11"`)

Generates Docker files, builds the image (native arch), and starts the container in one shot. Checks if Docker is running first and attempts to start it on macOS/Linux:

```bash
./install_dev_tools.sh "11"
```

You'll be prompted for a container name (default: `dev-tools`).

#### Generate Docker files only (`--target=docker`)

Creates `Dockerfile`, `docker-compose.yml`, and `.dockerignore` without building:

```bash
./install_dev_tools.sh --target=docker
```

Then build and run manually:

**Multi-arch (Intel + ARM):**
```bash
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t dev-tools:latest .
```

**Native arch:**
```bash
docker build -t dev-tools:latest .
```

**Run container:**
```bash
docker-compose up -d
docker exec -it dev-tools bash
```

**Docker image includes:** Python 3.14.5, Java 17, Maven 3.9.16, Node.js, nvm, Angular CLI, AWS CLI

## Menu Options

- **1** - Python 3.14.5
- **2** - Java 17 (Oracle JDK)
- **3** - Maven 3.9.16
- **4** - Ollama
- **5** - OpenCode
- **6** - nvm (Node Version Manager)
- **7** - Node.js 26.1.0
- **8** - Claude Code
- **9** - Angular CLI
- **10** - AWS CLI v2
- **11** - Build and run Docker container (Python, Java, Maven, Node.js, AWS CLI)
- **0** - Install all tools
- **q** - Quit

## After Installation (Local)

The script executes automatic sourcing of ~/.zshrc, so a terminal restart is unnecessary after installation completes.

Then verify installations (automatic after running installer):
```bash
python3 --version
java -version
mvn -version
ollama --version
opencode --version
node --version
claude --version
nvm --version
aws --version
ng version
```

**After installation completes**, the script automatically sources `.zshrc` and verifies all installed tools, displaying their actual versions in a formatted output.

## Version Checking

The installer automatically checks if newer versions are available for each tool:
- **Python**: Checks against latest release from python.org
- **Java**: Checks for latest 17.x version
- **Maven**: Checks against latest 3.x from Apache
- **Node.js**: Checks against latest version of the selected major line from nodejs.org
- **Ollama**: Checks npm registry
- **OpenCode**: Uses hardcoded version
- **Claude Code**: Checks npm registry
- **Angular CLI**: Checks npm registry via `npm view @angular/cli version`
- **AWS CLI**: Checks latest GitHub release from aws/aws-cli
- **nvm**: Checks latest GitHub release from nvm-sh/nvm

If a newer version is available, you'll be prompted to upgrade.

## Docker Image Contents

| Tool         | Version | Installation Method |
|--------------|---------|-------------------|
| Python       | 3.14.5  | Build from source |
| Java         | 17      | Oracle JDK tarball |
| Maven        | 3.9.16  | Binary archive    |
| Node.js      | 26.1.0  | Binary archive    |
| nvm          | 0.40.4  | Install script    |
| Angular CLI  | Latest  | npm install       |
| AWS CLI      | Latest  | Official installer|

The following tools are **local-only** (not in the Docker image): Ollama, OpenCode, Claude Code.

## Prerequisites

### Local Installation
- macOS (Intel or Apple Silicon)
- Internet connection
- Sudo privileges

### Docker Installation
- Docker with buildx plugin installed
- Internet connection
- ~5GB disk space for image
