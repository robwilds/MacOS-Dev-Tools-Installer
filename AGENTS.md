# AGENTS.md -- dev-tools

Single bash script (`install_dev_tools.sh`) installs dev tools locally on macOS or generates Docker build files.

## Commands

| Action | Command |
|---|---|
| Interactive menu | `./install_dev_tools.sh` |
| Install specific tools | `./install_dev_tools.sh "1,3,5"` |
| Install all tools | `./install_dev_tools.sh "0"` |
| Generate Docker files only | `./install_dev_tools.sh --target=docker` |
| Generate + build + run Docker | `./install_dev_tools.sh "11"` |
| After local install (source path) | `source ~/.zshrc` |
| Build Docker with custom name | `./build_tools.sh` |
| Multi-arch Docker build | `docker buildx build --platform linux/amd64,linux/arm64 -t dev-tools:latest .` |
| Native arch Docker build | `docker build -t dev-tools:latest .` |

## Menu Reference
`1` Python 3.14.5 · `2` Java 17.0.12 · `3` Maven 3.9.16 · `4` Ollama · `5` OpenCode · `6` nvm · `7` Node.js 26.1.0 · `8` Claude Code · `9` Angular CLI · `10` AWS CLI v2 · `11` Docker (build+run) · `0` All

> **Keep Docker (`11`) as the last numbered menu item.** If adding new tools, insert them before Docker so the build-and-run-Docker action always stays at the end.

## Architecture
- **Source of truth**: `install_dev_tools.sh`. Do NOT modify generated files (`Dockerfile`, `docker-compose.yml`, `.dockerignore`).
- `build_tools.sh` prompts for a repo name, tags as `:develop`. Custom names require manual docker-compose.yml update (the script does not patch it).
- Dockerfile is multi-stage (Python, Java, Maven, Node.js stages merged into final image).
- Docker image excludes Ollama, OpenCode, Claude Code. Angular CLI, nvm, and AWS CLI are installed at Docker build time (via `npm install -g`, nvm install script, official AWS installer).

## Gotchas
- **Version regexes are brittle** — parsing `--version` output via `sed`. No CI catches format changes. Update `fetch_latest_*` functions if tool output changes.
- **Java URL** hardcoded for macOS `aarch64`; Oracle download scheme changes break local installs.
- **Arch detection** (`install_dev_tools.sh:703`): `uname -m` -> `arm64` or `x86_64` (controls Java arch, Node.js pkg).
- **Local install paths**: Java -> `/Library/Java/JavaVirtualMachines/`, Maven -> `/opt/maven/maven`, symlinks in `/usr/local/bin`.
- **Docker ENV vs zshrc**: Docker uses `ENV` directives for PATH. Local installs use `~/.zshrc` guarded by `# dev_tools_config` sentinel.
- **Docker volumes** in compose: `./projects:/workspace`, `~/.gitconfig:/root/.gitconfig:ro`.
- **Stale file**: `install_dev_tools copy.sh` — listed in `.gitignore`; delete if found.
- **`nvm alias default system`** in Dockerfile aliases the /opt/node install so that `nvm use system` works.
- **Auto-verification** after local install: script sources `.zshrc` and runs `verify_all_versions` at line 906.
- **`.claude/settings.local.json`** exists with a permission allow for `Bash(claude --version)`.