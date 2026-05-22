# Implementation Plan

## Milestone 1

Deliver a playable `zsh` MVP.

## Phase 1: Install And Status

- create `install.zsh`
- create initial `termgotchi.zsh`
- create `state.json`
- wire `.zshrc`
- implement `tg_status`

### Done

- install succeeds
- shell starts cleanly
- `tg_status` displays ASCII and stats

## Phase 2: Care And Passive Growth

- implement `tg_feed`
- implement `tg_clean`
- implement `tg_talk`
- add command capture hooks
- add XP gain
- add command count
- add unique command tracking
- add level-up
- add evolution

### Done

- care commands save state
- normal commands increase XP
- form changes are visible

## Phase 3: Stabilization

- implement `tg_train`
- implement minimal idle decay
- reduce risky state update fragmentation
- verify hook behavior
- document known gaps

### Done

- train updates progress
- idle decay is stable enough for MVP
- shell does not become noisy or fragile

## Recommended Execution Order

1. `install.zsh`
2. `state.json` initialization
3. `tg_status`
4. `tg_feed`
5. `tg_clean`
6. `tg_talk`
7. `record-command`
8. level-up
9. evolution
10. `tg_train`
11. idle decay

## Weekly Breakdown

### Week 1

- install and file placement
- state initialization
- `tg_status`

### Week 2

- feed / clean / talk
- command recording
- XP / level / evolution

### Week 3

- train
- idle decay
- stability pass

## Open Technical Issues

- internal command exclusion still needs periodic review as more commands are added
- state reads are still multi-step in some functions
- shortcut commands should stay disabled in MVP
