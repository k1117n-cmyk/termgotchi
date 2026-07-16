if [[ -n "${TERM_GOTCHI_LOADED:-}" ]] && [[ -o interactive ]]; then
  autoload -Uz add-zsh-hook >/dev/null 2>&1
  add-zsh-hook -d preexec tg_on_command_start >/dev/null 2>&1
  add-zsh-hook -d precmd tg_on_command_finish >/dev/null 2>&1
fi
typeset -g TERM_GOTCHI_LOADED=1

typeset -g TG_HOME="${HOME}/.termgotchi"
typeset -g TG_STATE_FILE="${TG_HOME}/state.json"
typeset -g TG_ART_DIR="${TG_HOME}/art"
typeset -g TG_PENDING_COMMAND=""
if [[ "${(t)TG_RUNTIME_VERSION}" != *readonly* ]]; then
  typeset -g TG_RUNTIME_VERSION="0.1.1"
fi

tg_now() {
  date '+%Y-%m-%dT%H:%M:%S%z'
}

tg_to_epoch() {
  local timestamp="${1:-}"

  [[ -z "${timestamp}" ]] && return 1

  if date -j -f '%Y-%m-%dT%H:%M:%S%z' "${timestamp}" '+%s' >/dev/null 2>&1; then
    date -j -f '%Y-%m-%dT%H:%M:%S%z' "${timestamp}" '+%s' 2>/dev/null
    return 0
  fi

  date -d "${timestamp}" '+%s' 2>/dev/null
}

tg_require_dependencies() {
  command -v jq >/dev/null 2>&1
}

tg_require_state() {
  [[ -f "${TG_STATE_FILE}" ]]
}

tg_print_runtime_error() {
  printf 'termgotchi: %s\n' "$*" >&2
}

tg_clamp() {
  local value="$1"
  local min_value="$2"
  local max_value="$3"

  if (( value < min_value )); then
    printf '%s' "${min_value}"
  elif (( value > max_value )); then
    printf '%s' "${max_value}"
  else
    printf '%s' "${value}"
  fi
}

tg_load_state() {
  if ! tg_require_dependencies; then
    tg_print_runtime_error "jq is required. Re-run install after installing jq."
    return 1
  fi

  if ! tg_require_state; then
    tg_print_runtime_error "state file not found at ${TG_STATE_FILE}. Run install.zsh first."
    return 1
  fi

  if ! jq empty "${TG_STATE_FILE}" >/dev/null 2>&1; then
    tg_print_runtime_error "state file is invalid: ${TG_STATE_FILE}"
    return 1
  fi

  return 0
}

tg_get_state_value() {
  local jq_path="$1"
  local default_value="$2"

  jq -r "${jq_path} // ${default_value}" "${TG_STATE_FILE}"
}

tg_read_status_lines() {
  jq -r '
    [
      (.name // "Term-gotchi"),
      (.form // "egg"),
      ((.level // 1) | tostring),
      ((.xp // 0) | tostring),
      ((.xp_to_next // 20) | tostring),
      ((.hunger // 80) | tostring),
      ((.health // 80) | tostring),
      ((.mood // 80) | tostring),
      ((.command_count // 0) | tostring),
      ((.vocab_level // 1) | tostring),
      (.last_status_message // "")
    ] | .[]
  ' "${TG_STATE_FILE}"
}

tg_read_care_state_lines() {
  jq -r '
    [
      ((.hunger // 80) | tostring),
      ((.health // 80) | tostring),
      ((.mood // 80) | tostring)
    ] | .[]
  ' "${TG_STATE_FILE}"
}

tg_save_state_with_filter() {
  local jq_filter="$1"
  local temp_file

  temp_file="$(mktemp "${TG_HOME}/state.json.tmp.XXXXXX")" || {
    tg_print_runtime_error "failed to create temp file"
    return 1
  }

  if ! jq "${jq_filter}" "${TG_STATE_FILE}" > "${temp_file}"; then
    rm -f "${temp_file}"
    tg_print_runtime_error "failed to update state"
    return 1
  fi

  if ! jq empty "${temp_file}" >/dev/null 2>&1; then
    rm -f "${temp_file}"
    tg_print_runtime_error "generated invalid state"
    return 1
  fi

  if ! mv "${temp_file}" "${TG_STATE_FILE}"; then
    rm -f "${temp_file}"
    tg_print_runtime_error "failed to replace state file"
    return 1
  fi

  return 0
}

tg_apply_progress() {
  local earned_xp="$1"
  local vocab_gain="$2"
  local command_name="$3"
  local status_message="$4"
  local count_command="$5"
  local activity_field="${6:-}"
  local now

  if ! tg_load_state; then
    return 1
  fi

  now="$(tg_now)"

  local filter
  filter=$(cat <<EOF
. as \$state
| (\$state.unique_commands // []) as \$unique_commands
| (\$unique_commands | index("${command_name}")) as \$existing_index
| (if "${count_command}" == "1" then ((\$state.command_count // 0) + 1) else (\$state.command_count // 0) end) as \$next_command_count
| (if "${count_command}" == "1" and \$existing_index == null then \$unique_commands + ["${command_name}"] else \$unique_commands end) as \$next_unique_commands
| (${earned_xp} + (if "${count_command}" == "1" and \$existing_index == null then 2 else 0 end)) as \$total_earned_xp
| ((\$state.xp // 0) + \$total_earned_xp) as \$raw_xp
| ((\$state.level // 1)) as \$current_level
| (20 + ((\$current_level - 1) * 10)) as \$current_threshold
| (if \$raw_xp >= \$current_threshold then \$current_level + 1 else \$current_level end) as \$next_level
| (if \$raw_xp >= \$current_threshold then (\$raw_xp - \$current_threshold) else \$raw_xp end) as \$rolled_xp
| (20 + ((\$next_level - 1) * 10)) as \$next_threshold
| ((\$next_unique_commands | length)) as \$next_unique_count
| .command_count = \$next_command_count
| .unique_commands = \$next_unique_commands
| .xp = \$rolled_xp
| .level = \$next_level
| .xp_to_next = \$next_threshold
| .vocab_level = ([((\$state.vocab_level // 1) + ${vocab_gain}), (if \$next_unique_count > 0 then \$next_unique_count else 1 end)] | max)
| .form = (
    if \$next_level >= 20 and \$next_unique_count >= 100 then "sage"
    elif \$next_level >= 10 and \$next_unique_count >= 50 then "builder"
    elif \$next_level >= 3 and \$next_unique_count >= 10 then "buddy"
    elif \$next_level >= 2 then "sprout"
    else "egg"
    end
  )
| .last_command_name = "${command_name}"
| .last_active_at = "${now}"
| .updated_at = "${now}"
| .last_status_message = "${status_message}"
EOF
)

  if [[ -n "${activity_field}" ]]; then
    filter="${filter}
| .${activity_field} = \"${now}\""
  fi

  tg_save_state_with_filter "${filter}"
}

tg_apply_idle_decay() {
  if ! tg_load_state; then
    return 1
  fi

  local last_active_at last_decay_at baseline now now_epoch baseline_epoch elapsed_seconds
  local hunger mood next_hunger next_mood status_message

  last_active_at="$(tg_get_state_value '.last_active_at' '""')"
  last_decay_at="$(tg_get_state_value '.last_decay_at' '""')"
  now="$(tg_now)"
  now_epoch="$(tg_to_epoch "${now}")" || return 0

  if [[ -n "${last_decay_at}" ]]; then
    baseline="${last_decay_at}"
  else
    baseline="${last_active_at}"
  fi

  [[ -z "${baseline}" ]] && return 0

  baseline_epoch="$(tg_to_epoch "${baseline}")" || return 0
  elapsed_seconds=$(( now_epoch - baseline_epoch ))

  if (( elapsed_seconds < 21600 )); then
    return 0
  fi

  hunger="$(tg_get_state_value '.hunger' '80')"
  mood="$(tg_get_state_value '.mood' '80')"

  if (( elapsed_seconds >= 86400 )); then
    next_hunger="$(tg_clamp $(( hunger - 30 )) 0 100)"
    next_mood="$(tg_clamp $(( mood - 10 )) 0 100)"
    status_message="I missed you while you were away."
  elif (( elapsed_seconds >= 43200 )); then
    next_hunger="$(tg_clamp $(( hunger - 20 )) 0 100)"
    next_mood="$(tg_clamp $(( mood - 5 )) 0 100)"
    status_message="It's been a while. Let's get moving again."
  else
    next_hunger="$(tg_clamp $(( hunger - 10 )) 0 100)"
    next_mood="$(tg_clamp $(( mood - 0 )) 0 100)"
    status_message="I'm ready for another task."
  fi

  tg_save_state_with_filter "
    .hunger = ${next_hunger}
    | .mood = ${next_mood}
    | .last_decay_at = \"${now}\"
    | .updated_at = \"${now}\"
    | .last_status_message = \"${status_message}\"
  "
}

tg_apply_care_update() {
  local hunger_delta="$1"
  local health_delta="$2"
  local mood_delta="$3"
  local timestamp_field="$4"
  local status_message="$5"
  local hunger_value health_value mood_value now
  local next_hunger next_health next_mood
  local -a care_lines

  if ! tg_load_state; then
    return 1
  fi

  tg_apply_idle_decay || return 1
  care_lines=("${(@f)$(tg_read_care_state_lines)}")
  hunger_value="${care_lines[1]}"
  health_value="${care_lines[2]}"
  mood_value="${care_lines[3]}"

  next_hunger="$(tg_clamp $(( hunger_value + hunger_delta )) 0 100)"
  next_health="$(tg_clamp $(( health_value + health_delta )) 0 100)"
  next_mood="$(tg_clamp $(( mood_value + mood_delta )) 0 100)"
  now="$(tg_now)"

  tg_save_state_with_filter "
    .hunger = ${next_hunger}
    | .health = ${next_health}
    | .mood = ${next_mood}
    | .${timestamp_field} = \"${now}\"
    | .last_active_at = \"${now}\"
    | .updated_at = \"${now}\"
    | .last_status_message = \"${status_message}\"
  " || return 1

  printf '%s\n' "${next_hunger}" "${next_health}" "${next_mood}"
}

tg_is_command_prefix_wrapper() {
  local token="${1:-}"

  case "${token}" in
    builtin|command|exec|noglob|nocorrect|time)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

tg_command_is_internal() {
  local command_name="${1:-}"

  [[ -z "${command_name}" ]] && return 0

  case "${command_name}" in
    tg_*|termgotchi_internal_*|source|.|alias|unalias|autoload|bindkey|eval|fc|functions|hash|history|rehash|set|setopt|typeset|unset|unsetopt|export|readonly|integer|float)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

tg_extract_command_name() {
  local raw_command="${1:-}"
  local token
  local -a words

  words=("${(z)raw_command}")

  for token in "${words[@]}"; do
    if [[ "${token}" == *=* ]]; then
      continue
    fi
    if tg_is_command_prefix_wrapper "${token}"; then
      continue
    fi
    printf '%s' "${token}"
    return 0
  done

  return 1
}

tg_xp_for_command() {
  local command_name="${1:-}"

  case "${command_name}" in
    git|vi|vim|nvim|code)
      printf '2'
      ;;
    make|npm|pnpm|yarn|cargo)
      printf '3'
      ;;
    *)
      printf '1'
      ;;
  esac
}

tg_record_command_progress() {
  local command_name="${1:-}"

  if tg_command_is_internal "${command_name}"; then
    return 0
  fi

  tg_apply_idle_decay || return 1
  tg_apply_progress "$(tg_xp_for_command "${command_name}")" 0 "${command_name}" "I'm feeling productive!" 1 || return 1
}

tg_render_ascii() {
  local form="${1:-egg}"
  local art_file="${TG_ART_DIR}/${form}.txt"

  if [[ -f "${art_file}" ]]; then
    cat "${art_file}"
    return 0
  fi

  cat <<'EOF'
  ___
 /   \
|  o  |
 \___/
EOF
}

tg_get_status_message() {
  local hunger="$1"
  local health="$2"
  local mood="$3"

  if (( hunger < 30 )); then
    printf "I'm hungry."
  elif (( health < 30 )); then
    printf "I feel tired."
  elif (( mood < 30 )); then
    printf "I'm a little grumpy."
  else
    printf "I'm feeling productive!"
  fi
}

tg_should_show_recent_message() {
  local last_status_message="${1:-}"
  local display_message="${2:-}"

  [[ -z "${last_status_message}" ]] && return 1
  [[ "${last_status_message}" == "${display_message}" ]] && return 1
  [[ "${last_status_message}" == "I'm feeling productive!" ]] && return 1
  return 0
}

tg_status() {
  if ! tg_load_state; then
    return 1
  fi

  local name form level xp xp_to_next hunger health mood command_count vocab_level last_status_message display_message
  local -a state_lines

  state_lines=("${(@f)$(tg_read_status_lines)}")
  name="${state_lines[1]}"
  form="${state_lines[2]}"
  level="${state_lines[3]}"
  xp="${state_lines[4]}"
  xp_to_next="${state_lines[5]}"
  hunger="${state_lines[6]}"
  health="${state_lines[7]}"
  mood="${state_lines[8]}"
  command_count="${state_lines[9]}"
  vocab_level="${state_lines[10]}"
  last_status_message="${state_lines[11]}"
  display_message="$(tg_get_status_message "${hunger}" "${health}" "${mood}")"

  tg_render_ascii "${form}"
  printf '\n'
  printf '%s\n' "${name}"
  printf 'Form: %s\n' "${form}"
  printf 'Level: %s\n' "${level}"
  printf 'XP: %s/%s\n' "${xp}" "${xp_to_next}"
  printf 'Hunger: %s\n' "${hunger}"
  printf 'Health: %s\n' "${health}"
  printf 'Mood: %s\n' "${mood}"
  printf 'Commands: %s\n' "${command_count}"
  printf 'Vocab: %s\n' "${vocab_level}"
  printf 'Message: %s\n' "${display_message}"
  if tg_should_show_recent_message "${last_status_message}" "${display_message}"; then
    printf 'Recent: %s\n' "${last_status_message}"
  fi
}

tg_feed() {
  local hunger next_hunger next_mood
  local -a care_lines updated_values

  if ! tg_load_state; then
    return 1
  fi

  tg_apply_idle_decay || return 1
  care_lines=("${(@f)$(tg_read_care_state_lines)}")
  hunger="${care_lines[1]}"

  if (( hunger >= 95 )); then
    printf "Term-gotchi is already full.\n"
    return 0
  fi

  updated_values=("${(@f)$(tg_apply_care_update 20 0 3 "last_fed_at" "Yum! Thanks for the snack.")}") || {
    return 1
  }
  next_hunger="${updated_values[1]}"
  next_mood="${updated_values[3]}"

  printf "You fed Term-gotchi. Hunger: %s, Mood: %s\n" "${next_hunger}" "${next_mood}"
}

tg_clean() {
  local next_health next_mood
  local -a updated_values

  updated_values=("${(@f)$(tg_apply_care_update 0 15 2 "last_cleaned_at" "All clean and ready to work!")}") || {
    return 1
  }
  next_health="${updated_values[2]}"
  next_mood="${updated_values[3]}"

  printf "You cleaned Term-gotchi. Health: %s, Mood: %s\n" "${next_health}" "${next_mood}"
}

tg_talk() {
  if ! tg_load_state; then
    return 1
  fi

  local hunger health mood line
  local -a care_lines

  care_lines=("${(@f)$(tg_read_care_state_lines)}")
  hunger="${care_lines[1]}"
  health="${care_lines[2]}"
  mood="${care_lines[3]}"

  if (( hunger < 30 )); then
    line="Can we grab a snack soon?"
  elif (( health < 30 )); then
    line="I need a little care before the next task."
  elif (( mood < 30 )); then
    line="Talk to me. I need a small boost."
  else
    line="Let's keep going. I'm learning from your work."
  fi

  printf '%s\n' "${line}"
}

tg_train() {
  tg_apply_idle_decay || return 1
  tg_apply_progress 3 1 "tg_train" "That was a good practice session!" 0 "last_trained_at" || return 1
  printf "You trained Term-gotchi. XP +3, Vocab +1\n"
}

tg_on_command_start() {
  local command_name

  command_name="$(tg_extract_command_name "${1:-}")" || {
    TG_PENDING_COMMAND=""
    return 0
  }

  if tg_command_is_internal "${command_name}"; then
    TG_PENDING_COMMAND=""
    return 0
  fi

  TG_PENDING_COMMAND="${command_name}"
}

tg_on_command_finish() {
  local command_name="${TG_PENDING_COMMAND:-}"

  if [[ -z "${command_name}" ]]; then
    return 0
  fi

  TG_PENDING_COMMAND=""
  tg_record_command_progress "${command_name}"
}

tg_register_hooks() {
  if [[ ! -o interactive ]]; then
    return 0
  fi

  autoload -Uz add-zsh-hook || return 0

  add-zsh-hook -d preexec tg_on_command_start >/dev/null 2>&1
  add-zsh-hook -d precmd tg_on_command_finish >/dev/null 2>&1
  add-zsh-hook preexec tg_on_command_start
  add-zsh-hook precmd tg_on_command_finish
}

tg_help() {
  cat <<'EOF'
Term-gotchi commands:
  tg_status  今の姿、レベル、XP、気分、最近のメッセージを表示します。
  tg_feed    ごはんをあげます。hunger と mood が少し上がります。
  tg_clean   きれいにします。health と mood が少し上がります。
  tg_talk    話しかけます。今の状態に応じた短いメッセージを表示します。
  tg_train   いっしょに練習します。XP と vocab が上がり、成長のきっかけになります。
  tg_version runtime version と state version を表示します。
  tg_help    このヘルプを表示します。
EOF
}

tg_version() {
  local state_version="unknown"

  if tg_load_state; then
    state_version="$(tg_get_state_value '.version' '1')"
  fi

  printf 'Term-gotchi runtime %s\n' "${TG_RUNTIME_VERSION}"
  printf 'State schema %s\n' "${state_version}"
}

tg_register_hooks
