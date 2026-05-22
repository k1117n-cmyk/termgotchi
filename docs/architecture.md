# Architecture Notes

## Install Model

Installation target:

```text
~/.termgotchi/
```

### Installed Files

- `~/.termgotchi/termgotchi.zsh`
- `~/.termgotchi/state.json`
- `~/.termgotchi/art/`
- `~/.termgotchi/backup/`

## Repository-Side Layout

Planned source layout:

```text
termgotchi/
  install.zsh
  termgotchi.zsh
  art/
    egg.txt
    sprout.txt
    buddy.txt
  docs/
```

## Installer Behavior

`install.zsh` should:

1. validate dependencies
2. create target directories
3. copy runtime files
4. initialize `state.json` if missing
5. update `.zshrc` with one guarded source line
6. avoid duplicate source blocks
7. back up invalid `state.json` before reinitializing it

## Installer Exit Policy

- `0`: success
- `10`: partial success
- `20`: missing dependency
- `21`: file install failure
- `22`: state initialization failure
- `24`: recovered from invalid existing state

## Runtime Model

`termgotchi.zsh` is responsible for:

- source guard
- helper functions
- state load/save
- user commands
- shell hook registration

## Hook Policy

Use:

- `add-zsh-hook preexec tg_on_command_start`
- `add-zsh-hook precmd tg_on_command_finish`

Do not overwrite raw `preexec()` / `precmd()` functions directly.

### Remaining Risk To Address

- remove existing hook entries before re-adding to avoid duplicates
- exclude internal and shell-meta commands safely while still counting normal builtins like `cd` and `pwd`

## Persistence Policy

- state is updated through temp file + `mv`
- no destructive resets without explicit request
- broken state should be backed up before replacement

## Uninstall Model

Removal should be explicit and reversible:

1. remove the guarded `# termgotchi` source line from `~/.zshrc`
2. remove `~/.termgotchi/`
3. open a new shell

`uninstall.zsh` can perform this flow, but it should only touch the exact guarded source line and the `~/.termgotchi/` directory.

## Design Constraints

- fail safe over feature completeness
- shell responsiveness matters more than rich effects
- keep `.zshrc` modifications minimal and reversible
