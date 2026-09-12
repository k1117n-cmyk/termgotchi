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
typeset -g TG_SELECTED_TALK_LINE=""
typeset -g TG_SELECTED_TALK_PHRASE=""
typeset -g TG_SELECTED_TALK_THEME=""
typeset -g TG_SELECTED_TALK_TONE=""
typeset -g TG_SELECTED_TALK_MEANING=""
typeset -g TG_SELECTED_TALK_EXAMPLE_A=""
typeset -g TG_SELECTED_TALK_EXAMPLE_B=""
if [[ "${(t)TG_RUNTIME_VERSION-}" != *readonly* ]]; then
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

tg_validate_state_file() {
  local state_file="$1"

  jq -e '
    type == "object"
    and (.version | type == "number")
    and (.level | type == "number")
    and (.xp | type == "number")
    and (.xp_to_next | type == "number")
    and (.unique_commands | type == "array")
  ' "${state_file}" >/dev/null 2>&1
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

tg_export() {
  if ! tg_load_state; then
    return 1
  fi

  local export_target="${1:-}"
  local now

  now="$(date '+%Y%m%d-%H%M%S')"
  if [[ -z "${export_target}" ]]; then
    export_target="termgotchi-state.${now}.json"
  elif [[ -d "${export_target}" ]]; then
    export_target="${export_target}/termgotchi-state.${now}.json"
  fi

  if ! cp "${TG_STATE_FILE}" "${export_target}"; then
    tg_print_runtime_error "failed to export state to ${export_target}"
    return 1
  fi

  printf 'Exported Term-gotchi state to %s\n' "${export_target}"
}

tg_import() {
  local import_source="${1:-}"
  local backup_file temp_file now

  if [[ -z "${import_source}" ]]; then
    tg_print_runtime_error "usage: tg_import <state.json>"
    return 1
  fi

  if [[ ! -f "${import_source}" ]]; then
    tg_print_runtime_error "import file not found: ${import_source}"
    return 1
  fi

  if ! tg_require_dependencies; then
    tg_print_runtime_error "jq is required. Re-run install after installing jq."
    return 1
  fi

  if ! tg_validate_state_file "${import_source}"; then
    tg_print_runtime_error "import file is not a valid Term-gotchi state: ${import_source}"
    return 1
  fi

  if [[ "${import_source:A}" == "${TG_STATE_FILE:A}" ]]; then
    printf 'Import source is already the active Term-gotchi state.\n'
    return 0
  fi

  mkdir -p "${TG_HOME}/backup" || {
    tg_print_runtime_error "failed to create backup directory"
    return 1
  }

  now="$(date '+%Y%m%d-%H%M%S')"
  if [[ -f "${TG_STATE_FILE}" ]]; then
    backup_file="${TG_HOME}/backup/state.before-import.${now}.json"
    if ! cp "${TG_STATE_FILE}" "${backup_file}"; then
      tg_print_runtime_error "failed to back up current state"
      return 1
    fi
  fi

  temp_file="$(mktemp "${TG_HOME}/state.json.import.XXXXXX")" || {
    tg_print_runtime_error "failed to create import temp file"
    return 1
  }

  if ! cp "${import_source}" "${temp_file}"; then
    rm -f "${temp_file}"
    tg_print_runtime_error "failed to copy import file"
    return 1
  fi

  if ! tg_validate_state_file "${temp_file}"; then
    rm -f "${temp_file}"
    tg_print_runtime_error "copied import file is invalid"
    return 1
  fi

  if ! mv "${temp_file}" "${TG_STATE_FILE}"; then
    rm -f "${temp_file}"
    tg_print_runtime_error "failed to replace state file"
    return 1
  fi

  if [[ -n "${backup_file:-}" ]]; then
    printf 'Imported Term-gotchi state from %s\n' "${import_source}"
    printf 'Previous state backed up to %s\n' "${backup_file}"
  else
    printf 'Imported Term-gotchi state from %s\n' "${import_source}"
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

tg_get_time_bucket() {
  local hour

  hour="$(date '+%H')"

  if (( hour < 12 )); then
    printf 'morning'
  elif (( hour < 18 )); then
    printf 'afternoon'
  else
    printf 'evening'
  fi
}

tg_get_command_category() {
  local command_name="${1:-}"

  case "${command_name}" in
    git)
      printf 'git'
      ;;
    rg|grep|find|ls|sed|awk|cat|less|head|tail)
      printf 'inspect'
      ;;
    npm|pnpm|yarn|cargo|make)
      printf 'build'
      ;;
    vi|vim|nvim|code)
      printf 'edit'
      ;;
    *)
      printf 'general'
      ;;
  esac
}

tg_pick_vocab_talk_line() {
  local vocab_level="$1"
  local time_bucket="${2:-}"
  local command_category="${3:-general}"
  local lesson_index lesson
  local -a lessons

  lessons=(
    "Let us take a quick look before we change anything.|take a quick look / change anything|casual attention-directing phrases|cautious|Useful when you want to inspect the situation before making edits.|A: Should I patch it right away?|B: Not yet. Let us take a quick look first."
    "I am with you. Let us keep the momentum going.|keep the momentum going / I am with you|workplace momentum and pair flow|collaborative|Useful when the work is going well and you want to continue without overthinking.|A: Should we keep going?|B: Yeah. Let us keep the momentum going."
    "Sounds good. What do you want to tackle next?|tackle next / sounds good|next-task handoff|casual|Common for moving from one finished task to the next in a working session.|A: The tests are green now.|B: Sounds good. What do you want to tackle next?"
    "One sec. Let me check this out first.|one sec / check this out|casual review requests|casual|Used when you need a short moment to inspect something before answering.|A: Can you tell what changed here?|B: One sec. Let me check this out first."
    "I am on it. Let us make a small, clean pass.|I am on it / take a pass|ownership and follow-through|confident|Useful when you accept a task and plan to make a focused improvement.|A: Can you take a pass at this?|B: I am on it. I will make a small, clean pass."
    "A quiet look around might help us spot the issue.|quiet look around / spot the issue|careful issue spotting|cautious|Useful when you want to inspect calmly and notice what is actually wrong.|A: Should we jump straight into a fix?|B: Maybe not. A quiet look around might help."
  )

  case "${time_bucket}" in
    morning)
      lessons+=(
        "I like exploratory work in the morning. Let us inspect things.|inspect things / exploratory work|morning investigation language|methodical|Useful when you are still mapping the problem and do not want to jump to a fix.|A: Do we know what is broken yet?|B: Not really. Let us inspect things first."
      )
      ;;
    afternoon)
      lessons+=(
        "Let us narrow this down before the afternoon gets away from us.|narrow this down / gets away from us|focused afternoon debugging|direct|Useful when you want to reduce a broad problem to something manageable.|A: There are a few possible causes.|B: Let us narrow this down first."
      )
      ;;
    evening)
      lessons+=(
        "Let us keep this tight and avoid a late-day rabbit hole.|keep this tight / rabbit hole|late-day scope control|pragmatic|Useful when you want to avoid opening a large investigation late in the day.|A: Should we refactor this whole area?|B: Not tonight. Let us keep this tight."
        "Night is not bad for a little debugging archaeology.|debugging archaeology / dig in|slow, methodical debugging|methodical|Focuses on careful investigation instead of jumping straight to conclusions.|A: Should we slow down and dig into this?|B: I think so. We need a clearer trace."
        "We do not need to rush. One thoughtful move is enough tonight.|manageable / make it count|night work pacing|cautious|Useful when the task is still manageable and you want one intentional step to matter.|A: Should we try a few more random fixes?|B: No. One thoughtful move is enough tonight."
      )
      ;;
  esac

  case "${command_category}" in
    git)
      lessons+=(
        "Let us take a look at the diff before we decide anything.|take a look at the diff / decide anything|code review and diff reading|cautious|Common before reviewing, committing, or changing code based on a diff.|A: Should we commit this now?|B: Let us take a look at the diff first."
        "This change looks small, but the diff tells the story.|the diff tells the story / looks small|review judgment|methodical|Useful when a small-looking change may still have important details in the diff.|A: Is this just a tiny cleanup?|B: Maybe, but the diff tells the story."
      )
      ;;
    inspect)
      lessons+=(
        "Let us follow that clue and see where it leads.|follow that clue / see where it leads|signal-versus-noise thinking|methodical|Useful when a search result or log line gives you a useful direction to investigate.|A: This line shows up in three files.|B: Let us follow that clue."
        "Could you take a look at this file with me?|take a look / with me|polite review requests|collaborative|Useful when you want another person to inspect something together without sounding demanding.|A: Could you take a look at this file with me?|B: Sure. Let me check this out."
        "Let us dig into the source code of this script.|dig into / source code|source inspection|methodical|Useful when you need to read the implementation closely instead of guessing from the outside.|A: Should we just rerun it?|B: First, let us dig into the source code."
        "We need to dig into why the line endings got corrupted.|dig into why / got corrupted|root-cause investigation|cautious|Common when you are investigating why a file or workflow broke in a specific way.|A: Why does this file look different now?|B: We need to dig into why the line endings got corrupted."
        "Let us dig up the backup files before we guess.|dig up / backup files|finding old context|pragmatic|Useful when you need to find older files or records before deciding what changed.|A: Can we tell what the old version looked like?|B: Let us dig up the backup files first."
      )
      ;;
    build)
      lessons+=(
        "Let us kick off the build and see what shakes out.|kick off the build / shakes out|build verification|pragmatic|Common when you run a build to surface errors before making more decisions.|A: Should we inspect every file first?|B: Let us kick off the build and see what shakes out."
        "If the build passes, I would call this good for now.|build passes / good for now|shipping confidence|pragmatic|Useful when passing verification is enough for the current scope.|A: Do we need another pass?|B: If the build passes, this is good for now."
      )
      ;;
    edit)
      lessons+=(
        "Let us make the smallest edit that proves the point.|smallest edit / proves the point|minimal change strategy|direct|Useful when you want to test an idea without making a broad rewrite.|A: Should I rewrite the function?|B: No. Make the smallest edit that proves the point."
        "I would take a quick pass, then rerun it.|quick pass / rerun it|edit-and-verify loop|pragmatic|Common when you make a small edit and immediately verify the behavior.|A: What is the next move?|B: Take a quick pass, then rerun it."
        "I really dig this old-school vi config.|dig / old-school config|casual positive reaction|casual|Uses `dig` to mean you like or appreciate something in an informal way.|A: Do you like this vi setup?|B: Yeah. I really dig this old-school config."
      )
      ;;
  esac

  if (( vocab_level >= 10 )); then
    lessons+=(
      "Let us dig in and trace it step by step.|dig in / trace it step by step|slow, methodical debugging|methodical|Useful when you want to slow down and understand the chain of events clearly.|A: Do you want to trace this out carefully?|B: Yeah, probably. I want to go step by step."
      "That looks a little off. Let us sanity-check the assumption.|sanity-check / looks off|assumption checking|cautious|Common when something feels wrong and you want to verify the premise before changing code.|A: Should we rewrite this part?|B: Maybe, but let us sanity-check the assumption first."
      "Could you take a quick look when you have a second?|quick look / when you have a second|polite review requests|polite|Useful when you want help without making the request sound urgent.|A: Could you take a quick look when you have a second?|B: Sure. Send it over."
      "Let us dig in and analyze this log.|dig in / analyze this log|log investigation|methodical|Useful when a log has clues and you need to examine it carefully.|A: Is the error obvious from the log?|B: Not yet. Let us dig in and analyze it."
      "We need to trace the execution step by step to find the bug.|trace the execution / step by step|debugging flow|methodical|Useful when the bug depends on the order of events and needs a clear trace.|A: Can we guess where it fails?|B: I would rather trace the execution step by step."
    )
  fi

  if (( vocab_level >= 25 )); then
    lessons+=(
      "This feels like an edge case. Let us cover it before we move on.|edge case / cover it|defensive implementation|pragmatic|Useful when a rare condition could still break real users or future work.|A: Is that scenario worth handling?|B: Yes. It feels like an edge case we should cover."
      "We are close. Let us clean up the rough edges.|rough edges / clean up|polish pass|direct|Common near the end of a task when behavior works but details still need tightening.|A: Is the feature done?|B: Almost. Let us clean up the rough edges."
      "I think this is enough for a first pass.|first pass / enough for now|iteration scope|pragmatic|Useful when you want to keep progress moving without pretending the first version is final.|A: Should we perfect it today?|B: No. This is enough for a first pass."
      "I think we are in a good groove. Let us keep the momentum going.|in a good groove / keep the momentum going|productive flow|confident|Useful when the work has rhythm and stopping too early would waste that flow.|A: Should we call it for now?|B: Maybe not yet. I think we still have momentum."
      "I am in the zone right now. Let us keep the momentum going.|in the zone / keep the momentum going|focused work energy|confident|Common when you are focused and want to keep using that energy.|A: Do you want to pause here?|B: I am in the zone right now. Let us keep going."
    )
  fi

  if (( vocab_level >= 50 )); then
    lessons+=(
      "This is probably a scope issue, not a coding issue.|scope issue / coding issue|scope control|direct|Useful when the implementation is possible but the real decision is what should be included.|A: Can we add one more feature?|B: Maybe, but this is a scope issue now."
      "Let us unblock the small thing first, then come back to the bigger question.|unblock / come back to it|prioritization|pragmatic|Common when one small blocker is stopping progress but a larger decision can wait.|A: Should we solve the whole design now?|B: No. Let us unblock the small thing first."
      "I would leave a note and follow up after the build passes.|leave a note / follow up|team handoff|formal|Useful when you want to capture context without interrupting the current flow.|A: Should we ask the team right now?|B: I would leave a note and follow up after the build passes."
      "Let us wrap it up before we switch contexts.|wrap it up / switch contexts|finishing and context switching|pragmatic|Useful when you want to close the current task cleanly before moving to something else.|A: Would it help to close this out before we switch?|B: I think so. Let us wrap it up first."
      "Let us ride this wave and finish it.|ride this wave / finish it|momentum-based finishing|casual|Useful when momentum is high and the task is close enough to finish.|A: Should we stop and come back later?|B: Not yet. Let us ride this wave and finish it."
    )
  fi

  if (( vocab_level >= 100 )); then
    lessons+=(
      "I can keep up with a deeper working session now.|keep up / deeper working session|advanced collaboration|confident|Useful when a session becomes more complex but still manageable.|A: Is this getting too deep?|B: I can keep up with a deeper working session now."
      "This is shippable, but I would still call out the tradeoff.|shippable / call out the tradeoff|release judgment|formal|Useful when the work is good enough to ship but still has a known compromise.|A: Can we ship this version?|B: Yes, but I would call out the tradeoff."
      "Let us loop in someone who owns that part before we touch it.|loop in / owns that part|team coordination|formal|Common when another person or team owns the area you are about to change.|A: Should we edit that config ourselves?|B: I would loop in someone who owns that part first."
      "I would rather make one thoughtful move than try a bunch of random changes.|thoughtful move / random changes|careful decision language|cautious|Good for pushing back against random experimentation in favor of one intentional step.|A: Do you want to try a bunch of small changes?|B: Not really. I think one thoughtful move is better."
    )
  fi

  lesson_index=$(( (RANDOM % ${#lessons[@]}) + 1 ))
  lesson="${lessons[$lesson_index]}"
  TG_SELECTED_TALK_LINE="${lesson%%|*}"
  lesson="${lesson#*|}"
  TG_SELECTED_TALK_PHRASE="${lesson%%|*}"
  lesson="${lesson#*|}"
  TG_SELECTED_TALK_THEME="${lesson%%|*}"
  lesson="${lesson#*|}"
  TG_SELECTED_TALK_TONE="${lesson%%|*}"
  lesson="${lesson#*|}"
  TG_SELECTED_TALK_MEANING="${lesson%%|*}"
  lesson="${lesson#*|}"
  TG_SELECTED_TALK_EXAMPLE_A="${lesson%%|*}"
  TG_SELECTED_TALK_EXAMPLE_B="${lesson#*|}"
}

tg_talk() {
  if ! tg_load_state; then
    return 1
  fi

  local hunger health mood vocab_level line last_command_name time_bucket command_category
  local -a care_lines

  care_lines=("${(@f)$(tg_read_care_state_lines)}")
  hunger="${care_lines[1]}"
  health="${care_lines[2]}"
  mood="${care_lines[3]}"
  vocab_level="$(tg_get_state_value '.vocab_level' '1')"
  last_command_name="$(tg_get_state_value '.last_command_name' '""')"
  time_bucket="$(tg_get_time_bucket)"
  command_category="$(tg_get_command_category "${last_command_name}")"
  TG_SELECTED_TALK_PHRASE=""
  TG_SELECTED_TALK_THEME=""
  TG_SELECTED_TALK_TONE=""
  TG_SELECTED_TALK_MEANING=""
  TG_SELECTED_TALK_EXAMPLE_A=""
  TG_SELECTED_TALK_EXAMPLE_B=""

  if (( hunger < 30 )); then
    line="Can we grab a snack soon?"
  elif (( health < 30 )); then
    line="I need a little care before the next task."
  elif (( mood < 30 )); then
    line="Talk to me. I need a small boost."
  else
    tg_pick_vocab_talk_line "${vocab_level}" "${time_bucket}" "${command_category}"
    line="${TG_SELECTED_TALK_LINE}"
  fi

  printf '%s\n' "${line}"
  if [[ -n "${TG_SELECTED_TALK_PHRASE}" ]]; then
    printf 'Phrase: %s\n' "${TG_SELECTED_TALK_PHRASE}"
    printf 'Theme: %s\n' "${TG_SELECTED_TALK_THEME}"
    printf 'Tone: %s\n' "${TG_SELECTED_TALK_TONE}"
    printf 'Meaning: %s\n' "${TG_SELECTED_TALK_MEANING}"
    printf 'Example:\n'
    printf '%s\n' "${TG_SELECTED_TALK_EXAMPLE_A}"
    printf '%s\n' "${TG_SELECTED_TALK_EXAMPLE_B}"
  fi
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
  tg_status  Show current form, level, XP, mood, and recent message.
  tg_feed    Feed Term-gotchi. Hunger and mood go up a little.
  tg_clean   Clean up. Health and mood go up a little.
  tg_talk    Start a short workplace-English micro lesson.
  tg_train   Practice together. XP and vocab go up.
  tg_export  Export state JSON for manual backup or transfer.
  tg_import  Import state JSON after validation and backup.
  tg_version Show runtime version and state schema version.
  tg_help    Show this help.
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
