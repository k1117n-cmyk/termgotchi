# Term-gotchi

[![CI](https://github.com/k1117n-cmyk/termgotchi/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/k1117n-cmyk/termgotchi/actions/workflows/ci.yml)
![Shell](https://img.shields.io/badge/shell-zsh-89e051)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)
![Language](https://img.shields.io/badge/language-Shell-89e051)

Term-gotchi is a terminal companion for `zsh`.
It turns everyday command-line work into a lightweight raising game with English-learning flavor.

## Demo

![Term-gotchi demo](assets/termgotchi-demo.gif)

Japanese README: [`README.ja.md`](./README.ja.md)

## Articles

- [Term-gotchi: a tiny zsh terminal pet app](https://pc-fan.net/term-gotchi-zsh-mini-pet-app/)
- [Term-gotchi growth history: from shell hook to buddy](https://pc-fan.net/term-gotchi-growth-history/)
- [Term-gotchi tg_talk: English practice in the terminal](https://pc-fan.net/term-gotchi-tg-talk-english-practice/)
- [Term-gotchi Git/GitHub distribution workflow](https://pc-fan.net/term-gotchi-git-github-distribution/)

## Concept

- Normal terminal work becomes growth input.
- The companion responds to English commands.
- Command variety and continued use drive level-ups and evolution.
- The terminal stays usable; the companion should not break existing shell workflows.

## Current Status

Initial implementation has started.
The safe installer, runtime loader, initial state, `tg_status`, care commands, `tg_train`, idle decay, and passive XP hooks are in place.

## Install

From a GitHub checkout:

1. Ensure `zsh` and `jq` are available.
2. Run `zsh ./install.zsh` from the repository root.
3. Open a new shell, or run `source ~/.zshrc`.
4. Check with `tg_version` and `tg_status`.

From a release package:

1. Download and extract `termgotchi-<version>.tar.gz` or `termgotchi-<version>.zip`.
2. Move into the extracted directory.
3. Run `zsh ./install.zsh`.
4. Open a new shell, or run `source ~/.zshrc`.
5. Check with `tg_version` and `tg_status`.

## Uninstall

1. Run `zsh ./uninstall.zsh` from the repository root.
2. Open a new shell.

## Safety Notes

- Install writes only under `~/.termgotchi/` and appends one guarded line to `~/.zshrc`.
- Hooks are registered only in interactive `zsh`.
- Passive XP excludes `tg_*`, `source`, `.`, shell meta commands such as `alias`, `autoload`, `history`, `setopt`, and `export`, plus wrapper prefixes such as `command`, `builtin`, and `noglob`.
- State writes use a temp file plus `mv`.
- If the installer finds a broken `state.json`, it backs it up into `~/.termgotchi/backup/` and recreates it.
- Installer exit code `24` means recovery succeeded after backing up an invalid state file.
- `tg_status` can show a `Recent:` line when the last event message is more informative than the current state summary.
- `tg_import` validates the imported JSON and backs up the current state under `~/.termgotchi/backup/` before replacing it.

## Manual Backup And Migration

Term-gotchi does not perform automatic cloud sync.
To move the same companion state to another Mac or PC, explicitly export and import only `state.json`.

```sh
tg_export ~/Desktop/termgotchi-state.json
tg_import ~/Desktop/termgotchi-state.json
```

Without an argument, `tg_export` writes `termgotchi-state.<timestamp>.json` in the current directory.
`tg_import` validates the selected file, backs up the current state, and then imports it.

## Planned MVP

- `install.zsh` installs files into `~/.termgotchi/`
- `termgotchi.zsh` is sourced from `.zshrc`
- `tg_status` shows current state and ASCII art
- `tg_feed`, `tg_clean`, `tg_talk`, `tg_train` provide direct interaction
- `tg_export`, `tg_import` support manual state backup and migration
- normal commands grant XP via `preexec` / `precmd`
- level-up and command-variety evolution:
  - `egg -> sprout`
  - `sprout -> buddy`
  - `buddy -> builder`
  - `builder -> sage`

## Planned Directory Layout

```text
termgotchi/
  README.md
  install.zsh
  uninstall.zsh
  termgotchi.zsh
  art/
    egg.txt
    sprout.txt
    buddy.txt
    builder.txt
    sage.txt
  docs/
    spec.md
    architecture.md
    implementation-plan.md
```

## Documents

- [`docs/spec.md`](./docs/spec.md): product and behavior spec
- [`docs/architecture.md`](./docs/architecture.md): install/runtime structure
- [`docs/implementation-plan.md`](./docs/implementation-plan.md): MVP phases and execution order
- [`docs/porting-manual.md`](./docs/porting-manual.md): how to move the app to another Mac or PC
- [`docs/tg-talk-examples.md`](./docs/tg-talk-examples.md): workplace-English lesson examples

## Release Package

Create a portable package for GitHub Releases:

```sh
zsh ./scripts/package.zsh
```

The script creates:

- `dist/termgotchi-<version>/`
- `dist/termgotchi-<version>.tar.gz`
- `dist/termgotchi-<version>.zip`
- `dist/termgotchi-<version>.checksums.txt`

The package includes the runtime, installer, uninstaller, ASCII art, and core docs.

## MVP Priorities

1. Safe install and shell integration
2. `tg_status` and persistent state
3. care commands: `tg_feed`, `tg_clean`, `tg_talk`
4. passive growth from normal commands
5. level-up and evolution
6. minimal idle decay

## Non-Goals For MVP

- multi-shell support
- full TUI
- cloud sync
- advanced AI dialogue
- complex personality trees
- species branching beyond simple form evolution

## Guiding Constraints

- `zsh` first
- keep `.zshrc` changes minimal
- do not overwrite user shell functions directly
- fail safe if state handling breaks
- data lives in `~/.termgotchi/`
