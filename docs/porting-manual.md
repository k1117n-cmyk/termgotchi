# Porting Manual

## Purpose

This document explains how to move Term-gotchi to another Mac or PC safely.

## Supported Targets

Supported:

- macOS with `zsh`
- Linux with `zsh`
- Windows via WSL where `zsh` and `jq` are available

Not supported as-is:

- Windows `cmd.exe`
- PowerShell without a `zsh` environment

## What To Copy

Copy the whole repository directory, including:

- `install.zsh`
- `uninstall.zsh`
- `termgotchi.zsh`
- `art/`
- `docs/`

You do not need to copy `~/.termgotchi/` unless you want to migrate the current pet state.

## Prerequisites On The Target Machine

Required:

- `zsh`
- `jq`

Check:

```sh
zsh --version
jq --version
```

Recommended verification after install:

```sh
tg_version
tg_status
```

## Fresh Install On Another Machine

1. Copy the repository to the target machine.
2. Open `zsh`.
3. Move to the repository root.
4. Run:

```sh
zsh ./install.zsh
```

5. Open a new shell, or run:

```sh
source ~/.zshrc
```

6. Verify:

```sh
tg_status
```

## Migrate An Existing Pet State

If you want the same companion state on the new machine:

1. Install Term-gotchi on the target machine first.
2. Copy the old machine's `~/.termgotchi/state.json` to the new machine's `~/.termgotchi/state.json`.
3. If you want matching art files too, copy `~/.termgotchi/art/` as well.
4. Open a new shell and run:

```sh
tg_status
```

Recommended order:

- run `zsh ./install.zsh` first
- replace only `state.json` after install

This keeps the runtime files on the new machine aligned with the current repository version.

## Safe Migration Checklist

- confirm `zsh` exists on the target machine
- confirm `jq` exists on the target machine
- install from the repository before copying old state
- verify `~/.zshrc` contains only one Term-gotchi source line
- run `tg_status`
- run `tg_feed`
- run `tg_train`

## What The Installer Changes

The installer only does the following:

- creates `~/.termgotchi/`
- copies runtime files into `~/.termgotchi/`
- initializes `state.json` if missing
- appends one guarded source line to `~/.zshrc`

The source line is:

```zsh
[[ -f "$HOME/.termgotchi/termgotchi.zsh" ]] && source "$HOME/.termgotchi/termgotchi.zsh" # termgotchi
```

## Recovery Behavior

If the target machine already has an invalid `~/.termgotchi/state.json`:

- the installer backs it up into `~/.termgotchi/backup/`
- a new state file is created
- the installer exits with code `24`

This means recovery succeeded, not that the install failed.

## Uninstall On The Target Machine

Run:

```sh
zsh ./uninstall.zsh
```

Then open a new shell.

This removes:

- the guarded Term-gotchi source line from `~/.zshrc`
- `~/.termgotchi/`

## Version Alignment Notes

When moving between machines:

- keep the repository contents the same on both sides when possible
- avoid mixing an old `state.json` with heavily changed runtime code unless you test `tg_status` immediately after migration
- if migration behaves oddly, back up `state.json`, reinstall, and retry with the backup copy

## Troubleshooting

`jq: command not found`

- install `jq`
- rerun `zsh ./install.zsh`

`tg_status: command not found`

- confirm `~/.zshrc` contains the guarded Term-gotchi source line
- open a new shell or run `source ~/.zshrc`

Shell startup errors after migration

- check whether `~/.zshrc` has only one Term-gotchi source line
- run `zsh -n ~/.zshrc` if needed
- remove the Term-gotchi source line temporarily and retry

State did not migrate

- confirm the copied file is exactly `~/.termgotchi/state.json`
- run `jq empty ~/.termgotchi/state.json`
- rerun `tg_status`
