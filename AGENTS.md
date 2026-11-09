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
| Build Docker with custom name | `./build_tools.sh [--fetch-python]` |
| Multi-arch Docker build | `docker buildx build --platform linux/amd64,linux/arm64 -t dev-tools:latest .` |
| Native arch Docker build | `docker build -t dev-tools:latest .` |

## Verification
- No CI, no test suite. After editing `install_dev_tools.sh`: `bash -n install_dev_tools.sh` for syntax, then `./install_dev_tools.sh --target=docker` to confirm generation still works (it rewrites the 3 generated files with freshly fetched Python/Maven versions).

## Menu Reference
`1` Docker (Desktop for Mac) · `2` Python (latest, fetched) · `3` Java 17.0.12 · `4` Maven (latest, fetched) · `5` oMLX · `6` oMLX RC · `7` OpenCode · `8` nvm · `9` Node.js 26.1.0 · `10` Claude Code · `11` AWS CLI v2 · `12` Splash (desktop app) · `13` All (except Docker) · `14` All (except Docker, with oMLX RC) · `0` All · `d` Docker (build+run)

> **Items 13/14 are catch-alls with explicit flag lists** in `parse_selection()` (lines 826–827). When adding a tool, add its `case` entry AND append its `INSTALL_*` flag to both catch-all lists (and to the `0` list); keep the letter option `d` (build+run Docker) after the numbered items.

## Architecture
- **Source of truth**: `install_dev_tools.sh`. Do NOT modify generated files (`Dockerfile`, `docker-compose.yml`, `.dockerignore`) — regenerate with `./install_dev_tools.sh --target=docker`.
- `build_tools.sh` prompts for a repo name, tags as `:develop`, and offers to run `docker build`. Custom names require manual `docker-compose.yml` update (the script does not patch it). With `--fetch-python` it fetches the latest Python and passes `--build-arg PYTHON_VERSION=x.y.z`; without a version the Dockerfile's baked-in default is used.
- Dockerfile is multi-stage (Python, Java, Maven, Node.js stages merged into final image).
- **Docker generation**: `generate_dockerfile <file> [node] [python] [maven]` — the python/maven args default to live fetches. Versions are substituted into the template (`__NODE_VERSION__`, `__PYTHON_VERSION__`, `__MAVEN_VERSION__`); Python is also declared as `ARG PYTHON_VERSION=<ver>` so `docker build --build-arg PYTHON_VERSION=x.y.z` can override at build time. Maven installs to the version-agnostic `/opt/maven/maven` (compose `MAVEN_HOME` matches) — only the tarball URL carries the version.
- Docker image excludes oMLX App, Splash, OpenCode, Claude Code. Angular CLI, nvm, and AWS CLI are installed at Docker build time (via `npm install -g`, nvm install script, official AWS installer).
- **Version fetching**: Each tool has a `fetch_latest_*` function that queries upstream sources using `curl --compressed` (python.org serves gzip; raw compressed bytes make BSD sed fail with `RE error: illegal byte sequence`) plus portable parsers (`grep -oE`, `sort -V` — never `grep -P`, which is GNU-only and absent from macOS BSD grep). Hardcoded fallbacks used when fetch fails. Menu items `2` (Python) and `4` (Maven) render from these fetchers.
- **Upgrade prompts**: On each run, script checks installed vs latest version and prompts to upgrade if newer available. The install steps download the version that was compared (`$MAVEN_LATEST`, `$NODE_LATEST`) so prompts can't loop on a stale hardcoded URL.

## Gotchas
- **Menu Alignment**: In `show_menu()`, maintain vertical alignment between digits and descriptions. Single-digit options (1-9) need 3 spaces after the dot; double-digit options (10+) need 2 spaces.
- **oMLX Installation** (menu 5 stable, 6 RC): fetches tags from GitHub (jundot/omlx). macOS: picks the DMG variant by `sw_vers` major (`macos26-27`, or `macos15-sequoia` if < 26) and downloads to ~/Downloads — the user installs the .app; the `/usr/local/bin/omlx` shim comes from the app, not the script. Linux: downloads the `.sh` to the script directory and runs it with `/usr/local/bin/omlx` as the shim path.
- **Splash Installation** (menu 12, local only): fetches the latest tag from GitHub (incoai/splash; plain `X.Y.Z` tags, no leading `v`) and downloads `Splash-X.Y.Z.dmg` to ~/Downloads for manual install. Apple silicon (M3+) / macOS 26.4+ only — Intel/Linux gets a skip notice. `check_splash_version` reads `/Applications/Splash.app` Info.plist, falling back to the Homebrew `splash` CLI.
- **Version regexes are brittle** — parsing `--version` output via `sed`. No CI catches format changes. Update `fetch_latest_*` and `check_*_version` functions if tool output changes.
- **Never escape `$` as `\$` in the Dockerfile template**: the heredoc is quoted (`<< 'DOCKERFILE'`), so escapes are written verbatim into the generated file and break shell/`ENV` expansion (arch detection, `PATH`). Declare a real `ARG`/`ENV` instead.
- **Upstream quirks**: AWS CLI has no GitHub Releases (`releases/latest` → 404; fetcher reads `/tags`); Maven's `closer.cgi` no longer lists versions (parse the `dlcdn.apache.org` directory listing with `sort -V`); nodejs.org hrefs are full paths (`/dist/latest-v26.x/node-v26.12.0...`), so match `node-vX.Y.Z` anywhere in the line, not right after `href="`.
- **`sed: RE error: illegal byte sequence`** (typically under menu item 1) means gzip bytes reached BSD sed under a UTF-8 locale — keep `--compressed` on every fetch `curl`.
- **`generate_dockerfile` uses BSD `sed -i ''`** for placeholder substitution — works on macOS only; generation fails under GNU sed (Linux).
- **Menu 1 (and 0) download the Docker DMG twice**: one block saves it to ~/Downloads, a second saves it to `$TMP_DIR`, which is then `rm -rf`'d (leaving a stale path message). Both blocks are guarded by `INSTALL_DOCKER_DMG=true`.
- **CLAUDE.md is just a pointer** to this file (it previously duplicated the menu and drifted). Keep the real instructions here only.
- **Generated Docker files pin versions at generation time** — rerun `./install_dev_tools.sh --target=docker` to pick up new Python/Maven releases.
- **Java 17.0.12 is hardcoded** (local install line 955; generated Dockerfile); the URL is built from `$JAVA_ARCH` (aarch64/x64). Oracle's archive URL scheme (`java/17/archive/jdk-17.0.12_...`) is the fragile part.
- **Arch detection** (`install_dev_tools.sh:899`): `uname -m` -> `arm64` or `x86_64` (controls Java arch, Node.js pkg, Splash skip).
- **Local install paths**: Java -> `/Library/Java/JavaVirtualMachines/`, Maven -> `/opt/maven/maven`, symlinks in `/usr/local/bin`.
- **Docker ENV vs zshrc**: Docker uses `ENV` directives for PATH. Local installs append to `~/.zshrc` guarded by the `# dev_tools_config` sentinel (JAVA_HOME/MAVEN_HOME/PATH), plus an idempotent `mlx_lm()` function block.
- **Docker volumes** in compose: `./projects:/workspace`, `~/.gitconfig:/root/.gitconfig:ro`.
- **`nvm alias default system`** in Dockerfile aliases the `/opt/node` install so that `nvm use system` works.
- **Auto-verification** after local install: script sources `~/.zshrc` and runs `verify_all_versions` (function line 453; called at line 1278) — checks the 9 CLI tools but not oMLX/Splash (manual DMG installs). The ZSH-path block that runs just before is sentinel-guarded (`# dev_tools_config`); it only announces "Configuring ZSH path..." when it will actually append.
- **`.claude/settings.local.json`** exists with a permission allow for `Bash(claude --version)`.

## Version Differences: Local vs Docker
| Tool | Local Default | Docker Default | Notes |
|---|---|---|---|
| Python | latest (fetched; fallback 3.14.5) | latest (baked at generation; fallback 3.14.5) | Local: pkg from python.org. Docker: builds from source, overridable via `--build-arg PYTHON_VERSION=x.y.z` |
| Java | 17.0.12 (Oracle) | 17.0.12 (Oracle) | Same |
| Maven | latest (fetched; fallback 3.9.16) | latest (baked at generation; fallback 3.9.16) | Both install to version-agnostic `/opt/maven/maven` |
| Node.js | 26.1.0 default (interactive prompt offers 3 latest majors; arg mode skips the prompt) | 26.1.0 | Docker bakes `$NODE_VERSION` at generation |
| nvm | latest via GitHub | 0.40.4 | Docker uses fixed version |
| Angular CLI | latest via npm | latest via npm | |
| AWS CLI | latest via GitHub tags | latest via installer | aws-cli has no GitHub Releases |

## Key Functions to Modify for Version Updates
Line numbers refer to `install_dev_tools.sh` and shift as the file changes; every fetcher falls back to a hardcoded version when the fetch/parse fails.
- `fetch_latest_python_version` (line 190) — parses python.org/downloads for the `/ftp/python/X.Y.Z/` link
- `fetch_latest_java_version` (line 207) — hardcoded
- `fetch_latest_maven_version` (line 212) — Apache CDN directory listing + `sort -V`
- `fetch_latest_node_version` (line 230) — uses `$NODE_VERSION` major
- `fetch_latest_claude_version` (line 244) / `fetch_latest_angular_version` (line 254) — `npm view`
- `fetch_latest_nvm_version` (line 264)
- `fetch_latest_aws_cli_version` (line 274) — GitHub tags API
- oMLX: `fetch_latest_mlx_tag` (line 286), `fetch_latest_mlx_version` (line 297), `fetch_latest_mlx_rc_version` (line 307)
- Splash: `fetch_latest_splash_version` (line 330) — GitHub releases page (tags are plain `X.Y.Z`); `fetch_splash_download_url` (line 343) — expanded_assets, prefers `Splash-X.Y.Z.dmg`; `check_splash_version` (line 166)