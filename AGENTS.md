# AGENTS.md -- dev-tools

Single bash script (`install_dev_tools.sh`) installs dev tools locally on macOS or generates Docker build files.

## Commands

| Action | Command |
|---|---|
| Interactive menu | `./install_dev_tools.sh` |
| Install specific tools | `./install_dev_tools.sh "1,3,5"` |
| Install all tools | `./install_dev_tools.sh "0"` |
| Generate Docker files only | `./install_dev_tools.sh --target=docker` |
| Generate + build + run Docker | `./install_dev_tools.sh d` |
| After local install (source path) | `source ~/.zshrc` |
| Build Docker with custom name | `./build_tools.sh` |
| Multi-arch Docker build | `docker buildx build --platform linux/amd64,linux/arm64 -t dev-tools:latest .` |
| Native arch Docker build | `docker build -t dev-tools:latest .` |

## Menu Reference
`1` Docker (Desktop for Mac) · `2` Python (latest, fetched) · `3` Java 17.0.12 · `4` Maven (latest, fetched) · `5` oMLX · `6` oMLX RC · `7` OpenCode · `8` nvm · `9` Node.js 26.1.0 · `10` Claude Code · `11` AWS CLI v2 · `12` All (except Docker) · `13` All (except Docker, with oMLX RC) · `0` All · `d` Docker (build+run)

> **Keep Docker (`13`) as the last numbered menu item.** If adding new tools, insert them before Docker so the build-and-run-Docker action always stays at the end.

## Architecture
- **Source of truth**: `install_dev_tools.sh`. Do NOT modify generated files (`Dockerfile`, `docker-compose.yml`, `.dockerignore`) — regenerate with `./install_dev_tools.sh --target=docker`.
- `build_tools.sh` prompts for a repo name, tags as `:develop`, and offers to run `docker build`. Custom names require manual `docker-compose.yml` update (the script does not patch it). With `--fetch-python` it fetches the latest Python and passes `--build-arg PYTHON_VERSION=x.y.z`; without a version the Dockerfile's baked-in default is used.
- Dockerfile is multi-stage (Python, Java, Maven, Node.js stages merged into final image).
- **Docker generation**: `generate_dockerfile <file> [node] [python] [maven]` — the python/maven args default to live fetches. Versions are substituted into the template (`__NODE_VERSION__`, `__PYTHON_VERSION__`, `__MAVEN_VERSION__`); Python is also declared as `ARG PYTHON_VERSION=<ver>` so `docker build --build-arg PYTHON_VERSION=x.y.z` can override at build time. Maven installs to the version-agnostic `/opt/maven/maven` (compose `MAVEN_HOME` matches) — only the tarball URL carries the version.
- Docker image excludes oMLX App, OpenCode, Claude Code. Angular CLI, nvm, and AWS CLI are installed at Docker build time (via `npm install -g`, nvm install script, official AWS installer).
- **Version fetching**: Each tool has a `fetch_latest_*` function that queries upstream sources using `curl --compressed` (python.org serves gzip; raw compressed bytes make BSD sed fail with `RE error: illegal byte sequence`) plus portable parsers (`grep -oE`, `sort -V` — never `grep -P`, which is GNU-only and absent from macOS BSD grep). Hardcoded fallbacks used when fetch fails. Menu items `2` (Python) and `4` (Maven) render from these fetchers.
- **Upgrade prompts**: On each run, script checks installed vs latest version and prompts to upgrade if newer available. The install steps download the version that was compared (`$MAVEN_LATEST`, `$NODE_LATEST`) so prompts can't loop on a stale hardcoded URL.

## Gotchas
- **Menu Alignment**: In `show_menu()`, maintain vertical alignment between digits and descriptions. Single-digit options (1-9) need 3 spaces after the dot; double-digit options (10+) need 2 spaces.
- **oMLX Installation**: Downloads the latest oMLX .dmg (macOS) or .sh (Linux) from GitHub releases (jundot/omlx). macOS downloads DMG to ~/Downloads, Linux downloads shell script to the script directory. Creates a CLI shim at `/usr/local/bin/omlx`. Supports stable and RC versions.
- **Version regexes are brittle** — parsing `--version` output via `sed`. No CI catches format changes. Update `fetch_latest_*` and `check_*_version` functions if tool output changes.
- **Never escape `$` as `\$` in the Dockerfile template**: the heredoc is quoted (`<< 'DOCKERFILE'`), so escapes are written verbatim into the generated file and break shell/`ENV` expansion (arch detection, `PATH`). Declare a real `ARG`/`ENV` instead.
- **Upstream quirks**: AWS CLI has no GitHub Releases (`releases/latest` → 404; fetcher reads `/tags`); Maven's `closer.cgi` no longer lists versions (parse the `dlcdn.apache.org` directory listing with `sort -V`); nodejs.org hrefs are full paths (`/dist/latest-v26.x/node-v26.12.0...`), so match `node-vX.Y.Z` anywhere in the line, not right after `href="`.
- **`sed: RE error: illegal byte sequence`** (typically under menu item 1) means gzip bytes reached BSD sed under a UTF-8 locale — keep `--compressed` on every fetch `curl`.
- **Generated Docker files pin versions at generation time** — rerun `./install_dev_tools.sh --target=docker` to pick up new Python/Maven releases.
- **Java URL** hardcoded for macOS `aarch64`; Oracle download scheme changes break local installs.
- **Arch detection** (`install_dev_tools.sh:850`): `uname -m` -> `arm64` or `x86_64` (controls Java arch, Node.js pkg).
- **Local install paths**: Java -> `/Library/Java/JavaVirtualMachines/`, Maven -> `/opt/maven/maven`, symlinks in `/usr/local/bin`.
- **Docker ENV vs zshrc**: Docker uses `ENV` directives for PATH. Local installs use `~/.zshrc` guarded by `# dev_tools_config` sentinel.
- **Docker volumes** in compose: `./projects:/workspace`, `~/.gitconfig:/root/.gitconfig:ro`.
- **Stale file**: `install_dev_tools copy.sh` — listed in `.gitignore`; delete if found.
- **`nvm alias default system`** in Dockerfile aliases the `/opt/node` install so that `nvm use system` works.
- **Auto-verification** after local install: script sources `.zshrc` and runs `verify_all_versions` at line 1186.
- **`.claude/settings.local.json`** exists with a permission allow for `Bash(claude --version)`.

## Version Differences: Local vs Docker
| Tool | Local Default | Docker Default | Notes |
|---|---|---|---|
| Python | latest (fetched; fallback 3.14.5) | latest (baked at generation; fallback 3.14.5) | Local: pkg from python.org. Docker: builds from source, overridable via `--build-arg PYTHON_VERSION=x.y.z` |
| Java | 17.0.12 (Oracle) | 17.0.12 (Oracle) | Same |
| Maven | latest (fetched; fallback 3.9.16) | latest (baked at generation; fallback 3.9.16) | Both install to version-agnostic `/opt/maven/maven` |
| Node.js | 26.1.0 default (prompt offers 3 latest majors) | 26.1.0 | Docker bakes `$NODE_VERSION` at generation |
| nvm | latest via GitHub | 0.40.4 | Docker uses fixed version |
| Angular CLI | latest via npm | latest via npm | |
| AWS CLI | latest via GitHub tags | latest via installer | aws-cli has no GitHub Releases |

## Key Functions to Modify for Version Updates
Line numbers refer to `install_dev_tools.sh` and shift as the file changes; every fetcher falls back to a hardcoded version when the fetch/parse fails.
- `fetch_latest_python_version` (line 167) — parses python.org/downloads for the `/ftp/python/X.Y.Z/` link
- `fetch_latest_java_version` (line 184) — hardcoded
- `fetch_latest_maven_version` (line 189) — Apache CDN directory listing + `sort -V`
- `fetch_latest_node_version` (line 207) — uses `$NODE_VERSION` major
- `fetch_latest_claude_version` (line 221) / `fetch_latest_angular_version` (line 231) — `npm view`
- `fetch_latest_nvm_version` (line 241)
- `fetch_latest_aws_cli_version` (line 251) — GitHub tags API
- oMLX: `fetch_latest_mlx_tag` (line 263), `fetch_latest_mlx_version` (line 274), `fetch_latest_mlx_rc_version` (line 284)