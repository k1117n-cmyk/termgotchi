#!/bin/zsh
set -eo pipefail

cd /Users/noi/termgotchi

export HOME=/tmp/termgotchi-vhs-home
rm -rf "${HOME}"
mkdir -p "${HOME}"
zsh ./install.zsh >/dev/null
source "${HOME}/.termgotchi/termgotchi.zsh"

prompt() {
  printf '\n%% %s\n' "$*"
}

pause() {
  sleep "${1:-1}"
}

set_growth_stage() {
  local form="$1"
  local level="$2"
  local xp="$3"
  local commands="$4"
  local vocab="$5"
  local message="$6"

  jq \
    --arg form "${form}" \
    --arg message "${message}" \
    --argjson level "${level}" \
    --argjson xp "${xp}" \
    --argjson commands "${commands}" \
    --argjson vocab "${vocab}" \
    '.form = $form
      | .level = $level
      | .xp = $xp
      | .xp_to_next = (20 + (($level - 1) * 10))
      | .command_count = $commands
      | .vocab_level = $vocab
      | .hunger = 88
      | .health = 90
      | .mood = 92
      | .last_status_message = $message' \
    "${TG_STATE_FILE}" > "${TG_STATE_FILE}.tmp"
  mv "${TG_STATE_FILE}.tmp" "${TG_STATE_FILE}"
}

printf '\033[2J\033[H'
printf 'Term-gotchi\n'
printf 'A tiny terminal companion for zsh\n'
printf 'Normal commands become growth input.\n'
pause 1.6

printf '\033[2J\033[H'
prompt "tg_status"
tg_status
pause 2.2

printf '\033[2J\033[H'
prompt "git status --short"
git status --short
tg_record_command_progress git
pause 1.2

prompt "rg tg_status README.md termgotchi.zsh"
rg -n "tg_status" README.md termgotchi.zsh | head -4
tg_record_command_progress rg
pause 1.5

printf '\033[2J\033[H'
prompt "tg_feed"
tg_feed
pause 1.1

prompt "tg_talk"
tg_talk | sed -n '1,6p'
pause 2.2

printf '\033[2J\033[H'
printf 'Growth path\n'
printf 'Commands, care, and variety unlock new forms.\n'
pause 1.1

set_growth_stage egg 1 0 0 1 "A new terminal companion."
prompt "tg_status  # egg"
tg_status
pause 1.6

set_growth_stage sprout 2 5 8 4 "A tiny sprout appears."
prompt "tg_status  # sprout"
tg_status
pause 1.6

set_growth_stage buddy 3 9 18 10 "Your buddy is ready to help."
prompt "tg_status  # buddy"
tg_status
pause 1.6

set_growth_stage builder 10 12 55 28 "Builder mode unlocked."
prompt "tg_status  # builder"
tg_status
pause 1.6

set_growth_stage sage 20 18 120 60 "Sage mode unlocked."
prompt "tg_status  # sage"
tg_status
pause 2.4
