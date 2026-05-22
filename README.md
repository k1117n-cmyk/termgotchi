# Term-gotchi

Term-gotchi is a terminal companion for `zsh`.
It turns everyday command-line work into a lightweight raising game with English-learning flavor.

Japanese README: [`README.ja.md`](./README.ja.md)

## Concept

- Normal terminal work becomes growth input.
- The companion responds to English commands.
- Command variety and continued use drive level-ups and evolution.
- The terminal stays usable; the companion should not break existing shell workflows.

## Current Status

Initial implementation has started.
The safe installer, runtime loader, initial state, `tg_status`, care commands, `tg_train`, idle decay, and passive XP hooks are in place.

## Install

1. Ensure `zsh` and `jq` are available.
2. Run `zsh ./install.zsh` from the repository root.
3. Open a new shell, or run `source ~/.zshrc`.
4. Check with `tg_version` and `tg_status`.

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

## Planned MVP

- `install.zsh` installs files into `~/.termgotchi/`
- `termgotchi.zsh` is sourced from `.zshrc`
- `tg_status` shows current state and ASCII art
- `tg_feed`, `tg_clean`, `tg_talk`, `tg_train` provide direct interaction
- normal commands grant XP via `preexec` / `precmd`
- level-up and simple evolution:
  - `egg -> sprout`
  - `sprout -> buddy`

## Planned Directory Layout

```text
termgotchi/
  README.md
  NEXT.md
  install.zsh
  uninstall.zsh
  termgotchi.zsh
  art/
    egg.txt
    sprout.txt
    buddy.txt
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
- [`docs/porting-manual.ja.md`](./docs/porting-manual.ja.md): 日本語版の移植マニュアル
- [`NEXT.md`](./NEXT.md): restart memo for the next work session

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
