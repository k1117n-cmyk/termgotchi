#!/bin/zsh

set -eu

readonly ROOT_DIR="${0:A:h:h}"
readonly VERSION_FILE="${ROOT_DIR}/VERSION"
readonly DIST_DIR="${ROOT_DIR}/dist"
readonly PACKAGE_VERSION="$(tr -d '[:space:]' < "${VERSION_FILE}")"
readonly PACKAGE_NAME="termgotchi-${PACKAGE_VERSION}"
readonly PACKAGE_DIR="${DIST_DIR}/${PACKAGE_NAME}"
readonly ARCHIVE_TGZ="${DIST_DIR}/${PACKAGE_NAME}.tar.gz"
readonly ARCHIVE_ZIP="${DIST_DIR}/${PACKAGE_NAME}.zip"
readonly CHECKSUM_FILE="${DIST_DIR}/${PACKAGE_NAME}.checksums.txt"

tg_log() {
  printf '%s\n' "$*"
}

tg_fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

tg_require_command() {
  command -v "$1" >/dev/null 2>&1 || tg_fail "missing command: $1"
}

tg_copy_file() {
  local source="$1"
  local target="$2"

  cp "${ROOT_DIR}/${source}" "${PACKAGE_DIR}/${target}" || \
    tg_fail "failed to copy ${source}"
}

main() {
  tg_require_command cp
  tg_require_command mkdir
  tg_require_command tar
  tg_require_command zip
  tg_require_command shasum

  [[ -n "${PACKAGE_VERSION}" ]] || tg_fail "VERSION is empty"
  [[ ! -e "${PACKAGE_DIR}" ]] || tg_fail "${PACKAGE_DIR} already exists"
  [[ ! -e "${ARCHIVE_TGZ}" ]] || tg_fail "${ARCHIVE_TGZ} already exists"
  [[ ! -e "${ARCHIVE_ZIP}" ]] || tg_fail "${ARCHIVE_ZIP} already exists"

  mkdir -p "${PACKAGE_DIR}/art" "${PACKAGE_DIR}/docs" || \
    tg_fail "failed to create package directories"

  tg_copy_file "README.md" "README.md"
  tg_copy_file "README.ja.md" "README.ja.md"
  tg_copy_file "CHANGELOG.md" "CHANGELOG.md"
  tg_copy_file "VERSION" "VERSION"
  tg_copy_file "install.zsh" "install.zsh"
  tg_copy_file "uninstall.zsh" "uninstall.zsh"
  tg_copy_file "termgotchi.zsh" "termgotchi.zsh"

  cp "${ROOT_DIR}"/art/*.txt "${PACKAGE_DIR}/art/" || \
    tg_fail "failed to copy art assets"

  tg_copy_file "docs/spec.md" "docs/spec.md"
  tg_copy_file "docs/architecture.md" "docs/architecture.md"
  tg_copy_file "docs/implementation-plan.md" "docs/implementation-plan.md"
  tg_copy_file "docs/porting-manual.md" "docs/porting-manual.md"
  tg_copy_file "docs/porting-manual.ja.md" "docs/porting-manual.ja.md"

  chmod +x "${PACKAGE_DIR}/install.zsh" "${PACKAGE_DIR}/uninstall.zsh" || \
    tg_fail "failed to mark installer scripts executable"

  (
    cd "${DIST_DIR}" || exit 1
    tar -czf "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}"
    zip -qr "${PACKAGE_NAME}.zip" "${PACKAGE_NAME}"
    shasum -a 256 "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}.zip" > "${CHECKSUM_FILE:t}"
  ) || tg_fail "failed to create archives"

  tg_log "Created ${PACKAGE_DIR}"
  tg_log "Created ${ARCHIVE_TGZ}"
  tg_log "Created ${ARCHIVE_ZIP}"
  tg_log "Created ${CHECKSUM_FILE}"
}

main "$@"
