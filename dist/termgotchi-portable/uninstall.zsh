#!/bin/zsh

set -u

readonly TG_INSTALL_DIR="${HOME}/.termgotchi"
readonly TG_SOURCE_LINE='[[ -f "$HOME/.termgotchi/termgotchi.zsh" ]] && source "$HOME/.termgotchi/termgotchi.zsh" # termgotchi'
readonly TG_ZSHRC_FILE="${HOME}/.zshrc"

tg_log() {
  printf '%s\n' "$*"
}

tg_fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

tg_remove_source_line() {
  local temp_file

  [[ -f "${TG_ZSHRC_FILE}" ]] || return 0

  temp_file="$(mktemp "${HOME}/.zshrc.termgotchi.XXXXXX")" || return 1

  if ! grep -Fvx "${TG_SOURCE_LINE}" "${TG_ZSHRC_FILE}" > "${temp_file}"; then
    local grep_status=$?
    if (( grep_status != 1 )); then
      rm -f "${temp_file}"
      return 1
    fi
  fi

  mv "${temp_file}" "${TG_ZSHRC_FILE}" || {
    rm -f "${temp_file}"
    return 1
  }
}

tg_remove_install_dir() {
  [[ -d "${TG_INSTALL_DIR}" ]] || return 0
  rm -rf "${TG_INSTALL_DIR}"
}

main() {
  tg_remove_source_line || tg_fail "failed to update ~/.zshrc"
  tg_remove_install_dir || tg_fail "failed to remove ${TG_INSTALL_DIR}"

  tg_log "Removed Term-gotchi from ${TG_INSTALL_DIR}"
  tg_log "Open a new shell to finish cleanup."
}

main "$@"
