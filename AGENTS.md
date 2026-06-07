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
- `build_tools.sh` prompts for a repo name, tags as `:develop`. Custom names require manual `docker-compose.yml` update (the script does not patch it).
- Dockerfile is multi-stage (Python, Java, Maven, Node.js stages merged into final image).
- Docker image excludes Ollama, OpenCode, Claude Code. Angular CLI, nvm, and AWS CLI are installed at Docker build time (via `npm install -g`, nvm install script, official AWS installer).
- **Version fetching**: Each tool has a `fetch_latest_*` function that queries upstream sources. Hardcoded fallbacks used when fetch fails.
- **Upgrade prompts**: On each run, script checks installed vs latest version and prompts to upgrade if newer available.

## Gotchas
- **Menu Alignment**: In `show_menu()`, maintain vertical alignment between digits and descriptions. Single-digit options (1-9) need 3 spaces after the dot; double-digit options (10+) need 2 spaces.
- **Version regexes are brittle** — parsing `--version` output via `sed`. No CI catches format changes. Update `fetch_latest_*` and `check_*_version` functions if tool output changes.
- **Java URL** hardcoded for macOS `aarch64`; Oracle download scheme changes break local installs.
- **Arch detection** (`install_dev_tools.sh:770`): `uname -m` -> `arm64` or `x86_64` (controls Java arch, Node.js pkg).
- **Local install paths**: Java -> `/Library/Java/JavaVirtualMachines/`, Maven -> `/opt/maven/maven`, symlinks in `/usr/local/bin`.
- **Docker ENV vs zshrc**: Docker uses `ENV` directives for PATH. Local installs use `~/.zshrc` guarded by `# dev_tools_config` sentinel.
- **Docker volumes** in compose: `./projects:/workspace`, `~/.gitconfig:/root/.gitconfig:ro`.
- **Stale file**: `install_dev_tools copy.sh` — listed in `.gitignore`; delete if found.
- **`nvm alias default system`** in Dockerfile aliases the `/opt/node` install so that `nvm use system` works.
- **Auto-verification** after local install: script sources `.zshrc` and runs `verify_all_versions` at line 990.
- **`.claude/settings.local.json`** exists with a permission allow for `Bash(claude --version)`.

## Version Differences: Local vs Docker
| Tool | Local Default | Docker Default | Notes |
|---|---|---|---|
| Python | 3.14.5 (pkg) | 3.14.5 (source) | Docker builds from source |
| Java | 17.0.12 (Oracle) | 17.0.12 (Oracle) | Same |
| Maven | 3.9.16 | 3.9.16 | Same |
| Node.js | 26.1.0 (interactive menu) | 26.1.0 | Docker uses fixed version |
| nvm | latest via GitHub | 0.40.4 | Docker uses fixed version |
| Angular CLI | latest via npm | latest via npm | |
| AWS CLI | latest via GitHub | latest via installer | |

## Key Functions to Modify for Version Updates
- `fetch_latest_python_version` (line 165)
- `fetch_latest_java_version` (line 175) — hardcoded
- `fetch_latest_maven_version` (line 180)
- `fetch_latest_node_version` (line 205) — uses `$NODE_VERSION` major
- `fetch_latest_ollama_version` (line 190)
- `fetch_latest_claude_version` (line 217)
- `fetch_latest_angular_version` (line 227)
- `fetch_latest_nvm_version` (line 237)
- `fetch_latest_aws_cli_version` (line 247)