# Term-gotchi Portable Package

This directory is the portable distribution package for moving Term-gotchi to another machine.

## Included Files

- `install.zsh`
- `uninstall.zsh`
- `termgotchi.zsh`
- `art/`
- `docs/`

## Quick Start

1. Copy this whole directory to the target machine.
2. Open `zsh`.
3. Move into this directory.
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
tg_version
tg_status
```

## Manuals

- English: `docs/porting-manual.md`
- Japanese: `docs/porting-manual.ja.md`

## Notes

- `zsh` and `jq` are required on the target machine.
- This package is intended for `zsh` environments on macOS, Linux, or WSL.
- To remove it later, run:

```sh
zsh ./uninstall.zsh
```
