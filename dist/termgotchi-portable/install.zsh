#!/bin/zsh

set -u

readonly TG_INSTALL_DIR="${HOME}/.termgotchi"
readonly TG_SOURCE_LINE='[[ -f "$HOME/.termgotchi/termgotchi.zsh" ]] && source "$HOME/.termgotchi/termgotchi.zsh" # termgotchi'
readonly TG_STATE_FILE="${TG_INSTALL_DIR}/state.json"
readonly TG_RUNTIME_FILE="${TG_INSTALL_DIR}/termgotchi.zsh"
typeset -g TG_RECOVERED_INVALID_STATE=0

tg_log() {
  printf '%s\n' "$*"
}

tg_warn() {
  printf 'warn: %s\n' "$*" >&2
}

tg_fail() {
  printf 'error: %s\n' "$*" >&2
  exit "$2"
}

tg_require_command() {
  command -v "$1" >/dev/null 2>&1
}

tg_append_source_line() {
  local zshrc_file="${HOME}/.zshrc"

  touch "${zshrc_file}" || return 1

  if grep -Fqx "${TG_SOURCE_LINE}" "${zshrc_file}" 2>/dev/null; then
    return 0
  fi

  printf '\n%s\n' "${TG_SOURCE_LINE}" >> "${zshrc_file}" || return 1
}

tg_init_state() {
  local now="$1"

  if [[ -f "${TG_STATE_FILE}" ]]; then
    return 0
  fi

  cat > "${TG_STATE_FILE}" <<EOF
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
  "created_at": "${now}",
  "updated_at": "${now}",
  "last_active_at": "${now}",
  "last_decay_at": "",
  "last_fed_at": "",
  "last_cleaned_at": "",
  "last_trained_at": "",
  "last_greeted_at": ""
}
EOF
}

tg_backup_invalid_state() {
  local now backup_file

  [[ -f "${TG_STATE_FILE}" ]] || return 0

  now="$(date '+%Y%m%d-%H%M%S')"
  backup_file="${TG_INSTALL_DIR}/backup/state.invalid.${now}.json"
  cp "${TG_STATE_FILE}" "${backup_file}" || return 1
  rm -f "${TG_STATE_FILE}" || return 1
  TG_RECOVERED_INVALID_STATE=1
}

main() {
  local now

  if ! tg_require_command jq; then
    tg_fail "missing dependency: jq" 20
  fi

  mkdir -p "${TG_INSTALL_DIR}" "${TG_INSTALL_DIR}/art" "${TG_INSTALL_DIR}/backup" || \
    tg_fail "failed to create install directories" 21

  cp "termgotchi.zsh" "${TG_RUNTIME_FILE}" || tg_fail "failed to copy termgotchi.zsh" 21
  cp art/*.txt "${TG_INSTALL_DIR}/art/" || tg_fail "failed to copy art assets" 21

  if [[ -f "${TG_STATE_FILE}" ]] && ! jq empty "${TG_STATE_FILE}" >/dev/null 2>&1; then
    tg_warn "existing state.json is invalid; backing it up and reinitializing"
    tg_backup_invalid_state || tg_fail "failed to back up invalid state.json" 24
  fi

  now="$(date '+%Y-%m-%dT%H:%M:%S%z')"
  tg_init_state "${now}" || tg_fail "failed to initialize state.json" 22

  if ! jq empty "${TG_STATE_FILE}" >/dev/null 2>&1; then
    tg_fail "initialized state.json is invalid" 22
  fi

  tg_append_source_line || tg_fail "failed to update ~/.zshrc" 21

  tg_log "Installed Term-gotchi to ${TG_INSTALL_DIR}"
  tg_log "Open a new shell or run: source ~/.zshrc"

  if (( TG_RECOVERED_INVALID_STATE == 1 )); then
    exit 24
  fi
}

main "$@"
