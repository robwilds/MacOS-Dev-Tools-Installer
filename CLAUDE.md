# CLAUDE.md

The agent instructions for this repo live in [AGENTS.md](AGENTS.md) — read it first. It has the current commands, menu reference, Docker generation architecture, and all gotchas (this file used to duplicate them and drifted out of date).

Quick orientation: a single bash script (`install_dev_tools.sh`) installs dev tools locally on macOS or generates Docker build files (`./install_dev_tools.sh --target=docker`). No CI, no tests — verify edits with `bash -n` and a docker-generation dry run.
