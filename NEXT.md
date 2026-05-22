# Next

## Purpose

This file is the restart point for the next work session.

## Current State

Safe install, status view, care commands, training, idle decay, passive growth hooks,
invalid-state recovery, and uninstall script are implemented.
The installer writes one guarded line to `.zshrc`, installs into `~/.termgotchi/`,
backs up broken `state.json` into `~/.termgotchi/backup/`, and can return `24` after recovery.
`uninstall.zsh` removes the guarded source line and `~/.termgotchi/`.
Docs now recommend `zsh ./install.zsh` and `zsh ./uninstall.zsh` so execution does not depend on file mode bits.
`tg_status`, `tg_feed`, `tg_clean`, `tg_talk`, `tg_train` work with the initial JSON state and ASCII art.
Interactive `preexec` / `precmd` hooks record commands, update XP, level, form, and unique command tracking.
Minimal idle decay applies before care/training/command recording and uses `last_decay_at` to avoid double application.
State updates use temp file + `mv`.

## Immediate Next Tasks

1. Runtime cleanup
   - reduce repeated `jq` reads further where it still matters
   - decide whether progress / care updates should share more helper paths

2. Wider command exclusion review
   - current exclusions cover `tg_*`, `source`, `.`, shell meta commands, and common wrapper prefixes
   - verify whether any additional zsh-specific builtins should stay excluded

3. Display wording refinement
   - `Recent:` stays enabled
   - tune `last_status_message` wording if needed

4. Shell UX polish
   - review whether any startup messaging should be quieter
   - decide whether installer/uninstaller should manage file mode bits or stay doc-driven

## First Implementation Cut

Implement these before anything else:

- runtime cleanup
- display refinement
- shell UX polish

## After First Runnable Version

Add in this order:

1. wider command exclusion review
2. state read/write cleanup pass
3. shell UX polish

## Known Risks To Handle Early

- idle decay double-application
- duplicate hook registration
- internal command exclusion
- repeated `jq` reads/writes
- startup noise when dependency or state is missing

## Recommended Default Decisions

- stay `zsh`-only for MVP
- keep shortcut commands disabled
- keep data in `~/.termgotchi/`
- prefer safe shell behavior over extra game effects
