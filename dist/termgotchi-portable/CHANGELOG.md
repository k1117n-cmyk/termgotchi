# CHANGELOG

Term-gotchi の変更履歴です。

このファイルは、細かいコミットログではなく、使う人が「何が変わったか」を読みやすく追えるようにまとめます。

## Unreleased

- Added this `CHANGELOG.md` so project changes can be followed without reading every Git commit.
- Clarified that user state and local history are separate from the repository contents.

## 0.1.1 - 2026-07-16

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
