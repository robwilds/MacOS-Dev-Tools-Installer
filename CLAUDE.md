# CLAUDE.md – Development Tools Installer (Legacy — see AGENTS.md)

Single bash script (`install_dev_tools.sh`) that installs dev tools locally on macOS (no Homebrew/pyenv) or generates Docker build files.

## Essential Commands
- Install specific tools: `./install_dev_tools.sh "<tool1>,<tool2>"` (e.g., `"1,3,5"` for Python, Maven, OpenCode)
- Install all tools: `./install_dev_tools.sh "0"`
- Interactive mode: `./install_dev_tools.sh`
- Generate Docker files: `./install_dev_tools.sh --target=docker`
- Generate + build + run Docker: `./install_dev_tools.sh "11"`
- After local installation: `source ~/.zshrc`

## Menu Options Reference
1: Python 3.14.5, 2: Java 17.0.12, 3: Maven 3.9.16, 4: Ollama, 5: OpenCode, 6: nvm, 7: Node.js 26.1.0, 8: Claude Code, 9: Angular CLI, 10: AWS CLI v2, 11: Build/run Docker, 0: All

> **Keep Docker (`11`) as the last numbered menu item.** If adding new tools, insert them before Docker so the build-and-run-Docker action always stays at the end.

## Important Gotchas
- Tool versions and Oracle Java URL are hardcoded; changes to tool `--output` format break version detection
- Java URL is hardcoded for macOS `aarch64`; Oracle scheme changes break local installs
- Manual version verification required (no CI)
- `install_dev_tools copy.sh` is stale — delete it
- Update `.claude/settings.local.json` if modifying version regexes
- Docker container uses `ENV` directives, not `~/.zshrc`
- `~/.zshrc` config guarded by `# dev_tools_config` sentinel

## Architecture Notes
- Script detects `arm64` vs `x86_64` for arch-specific URLs
- Docker mode: `--target=docker` generates three files then exits; option `10` builds + runs
- Local installs: Java in `/Library/Java/JavaVirtualMachines/`, Maven in `/opt/maven/maven`, symlinks in `/usr/local/bin`
- Docker installs to `/opt/` (excludes Ollama, OpenCode, Claude Code)
