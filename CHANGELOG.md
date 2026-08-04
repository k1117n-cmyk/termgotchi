# CHANGELOG

Term-gotchi release notes.

This file summarizes user-facing changes without requiring readers to inspect every commit.

## Unreleased

- Expanded `tg_talk` output with Phrase, Theme, Tone, Meaning, and Example fields.
- Refined `tg_talk` lesson wording around everyday engineering phrases such as `dig in`, `sanity-check`, `edge case`, `unblock`, `follow up`, and `loop in`.
- Added time-of-day and last-command context to `tg_talk` lesson selection.
- Restored more workplace-English lesson lines around `wrap it up`, `in a good groove`, `debugging archaeology`, and `dig into`.
- Added `dig` variants for investigation, recovering old files, and casual positive reactions.
- Normalized `tg_talk` tone labels around casual, polite, formal, methodical, direct, collaborative, confident, cautious, and pragmatic usage.
- Documented that `tg_talk` lesson selection varies by vocab level, time of day, last command category, and random Tone.
- Updated the `sage` ASCII art.
- Changed `tg_help` output to English.
- Removed Japanese documentation from the English package surface, keeping `README.ja.md` as the only Japanese reference.

## 0.1.2 - 2026-07-19

- Updated `tg_talk` so normal-state messages vary and use `vocab_level` to unlock more lines.

## 0.1.1 - 2026-07-16

- Added this `CHANGELOG.md` so project changes can be followed without reading every Git commit.
- Clarified that user state and local history are separate from the repository contents.
- Kept `vocab_level` at least as high as the number of unique commands learned.
- Added `builder` and `sage` evolution stages based on level and command variety.
- Added `builder` and `sage` ASCII art to the portable distribution.
- Fixed repeated `source ~/.zshrc` reloads so updated hooks replace old hook functions.
- Avoided reload failures when an older runtime left `TG_RUNTIME_VERSION` read-only.

## 0.1.0 - 2026-07-05

- Added the initial Term-gotchi runtime for interactive `zsh` sessions.
- Added safe install and uninstall scripts.
- Added persistent local state under `~/.termgotchi/`.
- Added `tg_status` to show the current form, level, XP, mood, hunger, and recent message.
- Added care commands: `tg_feed`, `tg_clean`, and `tg_talk`.
- Added `tg_train` as a small practice action that helps growth.
- Added passive XP from normal terminal commands.
- Added idle decay so hunger and mood can change over time.
- Added simple evolution from `egg` to `sprout` to `buddy`.
- Added ASCII art for the companion forms.
- Added release packaging scripts for portable `.tar.gz` and `.zip` archives.
- Added English and Japanese README files.
