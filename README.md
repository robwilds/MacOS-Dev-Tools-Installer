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

This installs Docker, Python, and oMLX.

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

#### One-step: Auto-build and run (menu item 13 or `"13"`)

Generates Docker files, builds the image (native arch), and starts the container in one shot. Checks if Docker is running first and attempts to start it on macOS/Linux:

```bash
./install_dev_tools.sh "13"
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

- **1** - Docker (Desktop for Mac)
- **2** - Python 3.14.5
- **3** - Java 17 (Oracle JDK)
- **4** - Maven 3.9.16
- **5** - oMLX (MLX-based LLM App)
- **6** - oMLX Release Candidate (RC)
- **7** - OpenCode
- **8** - nvm (Node Version Manager)
- **9** - Node.js 26.1.0
- **10** - Claude Code
- **11** - AWS CLI v2
- **12** - All tools (except Docker)
- **13** - All tools (except Docker, with oMLX RC)
- **0** - Install all tools
- **d** - Build and run Docker container (Python, Java, Maven, Node.js, AWS CLI)
- **q** - Quit

## After Installation (Local)

The script executes automatic sourcing of ~/.zshrc, so a terminal restart is unnecessary after installation completes.

Then verify installations (automatic after running installer):
```bash
python3 --version
java -version
mvn -version
opencode --version
node --version
claude --version
nvm --version
aws --version
ng version
omlx --version  # macOS: /usr/local/bin/omlx
```

**After installation completes**, the script automatically sources `.zshrc` and verifies all installed tools, displaying their actual versions in a formatted output.

## Version Checking

The installer automatically checks if newer versions are available for each tool:
- **Python**: Checks against latest release from python.org
- **Java**: Checks for latest 17.x version
- **Maven**: Checks against latest 3.x from Apache
- **Node.js**: Checks against latest version of the selected major line from nodejs.org
- **oMLX**: Checks GitHub releases from jundot/omlx (supports stable and RC versions)
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

The following tools are **local-only** (not in the Docker image): oMLX, OpenCode, Claude Code.

## oMLX Installation (Local Only)

When installing oMLX fresh (not upgrading), the installer downloads the latest version from GitHub releases:

```bash
./install_dev_tools.sh "5"
```

The installer:
1. Fetches the latest oMLX version from GitHub releases
2. Downloads the oMLX DMG (macOS application installer) to ~/Downloads or shell script (Linux)
3. macOS: Downloads DMG to ~/Downloads
4. Linux: Downloads shell script to the script directory
5. For Linux, automatically runs the installation after download

After installation:
```bash
# Check CLI shim:
omlx --version

# Check app:
ls /Applications/oMLX.app
```

**Note:** oMLX is a macOS application (not like Ollama which is a CLI). It manages LLM inference with tiered KV cache, continuous batching, and a built-in admin dashboard.

This only prompts on **fresh install** — not on upgrades or if already installed.

## Prerequisites

### Local Installation
- macOS (Intel or Apple Silicon)
- Internet connection
- Sudo privileges

### Docker Installation
- Docker with buildx plugin installed
- Internet connection
- ~5GB disk space for image
