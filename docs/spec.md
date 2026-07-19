# Term-gotchi Specification

## Overview

Term-gotchi is a `zsh` companion that converts routine terminal usage into:

- a raising game
- a lightweight English command habit
- a persistent character living inside the shell

The MVP focuses on companion growth, not strict language enforcement.

## Core Experience

1. User opens a terminal.
2. User works normally.
3. Normal commands increase experience.
4. User checks and cares for the companion with explicit commands.
5. The companion levels up and evolves.

## Shell Scope

- Primary target: `zsh`
- Shell integration via `add-zsh-hook`
- Minimal `.zshrc` modification:

```zsh
[[ -f "$HOME/.termgotchi/termgotchi.zsh" ]] && source "$HOME/.termgotchi/termgotchi.zsh"
```

## User-Facing Commands

### Required MVP Commands

- `tg_status`
- `tg_feed`
- `tg_clean`
- `tg_talk`
- `tg_train`
- `tg_help`

### Optional Later Shortcut Commands

- `status`
- `feed`
- `clean`
- `talk`
- `train`

These are not part of the safe default MVP because they can collide with other commands.

## State Model

Persistent state lives in:

```text
~/.termgotchi/state.json
```

### Canonical State Schema

```json
{
  "version": 1,
  "name": "Term-gotchi",
  "species": "default",
  "form": "egg",
  "level": 1,
  "xp": 0,
  "xp_to_next": 20,
  "hunger": 80,
  "health": 80,
  "mood": 80,
  "command_count": 0,
  "unique_commands": [],
  "streak_days": 0,
  "vocab_level": 1,
  "last_command_name": "",
  "last_status_message": "I'm feeling productive!",
  "created_at": "2026-04-25T10:00:00+09:00",
  "updated_at": "2026-04-25T10:00:00+09:00",
  "last_active_at": "2026-04-25T10:00:00+09:00",
  "last_decay_at": "",
  "last_fed_at": "2026-04-25T10:00:00+09:00",
  "last_cleaned_at": "2026-04-25T10:00:00+09:00",
  "last_trained_at": "2026-04-25T10:00:00+09:00",
  "last_greeted_at": "2026-04-25T10:00:00+09:00"
}
```

### Notes

- `unique_command_count` is derived from `unique_commands.length`
- `form` controls ASCII art
- `version` exists for future migration support

## Status Fields

- `level`
- `xp`
- `xp_to_next`
- `hunger`
- `health`
- `mood`
- `form`
- `command_count`
- `unique_commands`
- `vocab_level`

## Growth Rules

### Base XP By Command

- `ls`, `cd`, `pwd`: `+1`
- `git`, `vi`, `vim`, `nvim`, `code`: `+2`
- `make`, `npm`, `pnpm`, `yarn`, `cargo`: `+3`
- everything else: `+1`

### New Command Bonus

- if command name is not in `unique_commands`: `+2`

### Level Threshold

```text
xp_to_next = 20 + (level - 1) * 10
```

### Evolution

- `egg -> sprout` when `level >= 2`
- `sprout -> buddy` when `level >= 3` and `unique_commands.length >= 10`
- `buddy -> builder` when `level >= 10` and `unique_commands.length >= 50`
- `builder -> sage` when `level >= 20` and `unique_commands.length >= 100`

## Care Commands

### `tg_feed`

- `hunger +20`
- `mood +3`
- clamp to `0..100`
- reject when already near full

### `tg_clean`

- `health +15`
- `mood +2`
- clamp to `0..100`

### `tg_talk`

- no required state mutation in MVP
- returns short state-based English message
- low hunger, health, or mood messages take priority
- otherwise uses `vocab_level` to unlock a wider set of English messages

### `tg_train`

- `xp +3`
- `vocab_level +1`
- `vocab_level` is also kept at least as high as `unique_commands.length`
- may trigger level-up / evolution

## Idle Decay

MVP keeps this minimal.

Apply before:

- `tg_feed`
- `tg_clean`
- `tg_train`
- `record-command`

Suggested decay:

- `>= 6h`: `hunger -10`
- `>= 12h`: `hunger -20`, `mood -5`
- `>= 24h`: `hunger -30`, `mood -10`

Important:

- do not apply decay from `tg_status` in MVP
- do not decrease `health` yet
- avoid repeated decay from the same idle window

## Display

### ASCII Forms

- `egg`
- `sprout`
- `buddy`
- `builder`
- `sage`

### Status Message Rules

- `hunger < 30`: `"I'm hungry."`
- `health < 30`: `"I feel tired."`
- `mood < 30`: `"I'm a little grumpy."`
- otherwise: `"I'm feeling productive!"`

`tg_status` may also show a `Recent:` line when the latest event message differs from the current state-derived summary.

## Shell Hooks

- `preexec`: capture raw command
- `precmd`: record command progress after completion

Internal commands and shell-meta commands should be excluded from XP updates.
Wrapper prefixes such as `command`, `builtin`, and `noglob` should resolve to the underlying command when possible.
Keep normal work-oriented builtins such as `cd` and `pwd` eligible.

## MVP Success Criteria

- install does not break shell startup
- `tg_status` works after install
- care commands persist state correctly
- normal shell commands increase XP
- level-up and evolution are visible in `tg_status`

## Deferred Items

- `streak_days`
- JSON API layer for `tg-engine`
- Python engine split
- TUI
- complex dialogue and personalities
- species branching
