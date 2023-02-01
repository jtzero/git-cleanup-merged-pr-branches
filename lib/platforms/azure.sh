#!/usr/bin/env bash

AZ_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}/az"

# shellcheck disable=SC2034
COMPLETED_STATES=('completed' 'abandoned')

source_cache_config() {
  local -r remote="${1}"
  local -r config_file="$(git rev-parse --show-toplevel)/.git/info/cleanup-az-cache-${remote}"
  touch "${config_file}" >/dev/null
  #shellcheck source=/dev/null
  . "${config_file}"
}

set_cache_config() {
  local -r remote="${1}"
  local -r blob="${2}"
  local -r config_file="$(git rev-parse --show-toplevel)/.git/info/cleanup-az-cache-${remote}"
  printf '%s' "${blob}" >"${config_file}"
}

load_cache() {
  local -r remote="${1}"
  AZ_REMOTE="${AZ_REMOTE:-}"
  if [ -z "${AZ_REMOTE}" ]; then
    source_cache_config "${remote}"
  fi
  if [ "${AZ_REMOTE}" != "${remote}" ]; then
    AZ_REMOTE="${remote}"
    AZ_PROJECT_NAME="$(get_project_from_url "$(git remote get-url --push "${remote}")")"
    AZ_PROJECT_URL="$(az repos show -r "${AZ_PROJECT_NAME}" | jq -r '.url')"
    set_cache_config "${remote}" "$(
      cat <<EOF
  AZ_REMOTE="${remote}"
  AZ_PROJECT_NAME="${AZ_PROJECT_NAME}"
  AZ_PROJECT_URL="${AZ_PROJECT_URL}"
EOF
    )"
  fi
}

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
select_option() {

  # little helpers for terminal print control and key input
  ESC=$(printf "\033")
  cursor_blink_on() { printf "$ESC[?25h"; }
  cursor_blink_off() { printf "$ESC[?25l"; }
  cursor_to() { printf "$ESC[$1;${2:-1}H"; }
  print_option() { printf "   $1 "; }
  print_selected() { printf "  $ESC[7m $1 $ESC[27m"; }
  get_cursor_row() {
    IFS=';' read -sdR -p $'\E[6n' ROW COL
    echo ${ROW#*[}
  }
  key_input() {
    read -s -n3 key 2>/dev/null >&2
    if [[ $key = $ESC[A ]]; then echo up; fi
    if [[ $key = $ESC[B ]]; then echo down; fi
    if [[ $key = "" ]]; then echo enter; fi
  }

  # initially print empty new lines (scroll down if at bottom of screen)
  for opt; do printf "\n"; done

  # determine current screen position for overwriting the options
  local lastrow=$(get_cursor_row)
  local startrow=$(($lastrow - $#))

  # ensure cursor and input echoing back on upon a ctrl+c during read -s
  trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
  cursor_blink_off

  local selected=0
  while true; do
    # print options by overwriting the last lines
    local idx=0
    for opt; do
      cursor_to $(($startrow + $idx))
      if [ $idx -eq $selected ]; then
        print_selected "$opt"
      else
        print_option "$opt"
      fi
      ((idx++))
    done

    # user key control
    case $(key_input) in
    enter) break ;;
    up)
      ((selected--))
      if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi
      ;;
    down)
      ((selected++))
      if [ $selected -ge $# ]; then selected=0; fi
      ;;
    esac
  done

  # cursor position back to normal
  cursor_to "${lastrow}"
  printf "\n"
  cursor_blink_on

  return $selected
}

ask_for_pat() {
  local config_folder="${1}"
  read -s -p "Token:" token
  mkdir -p "${config_folder}"
  printf '%s' "${token}" >"${config_folder}/token"
}

pre_init_hook() {
  local -r spinner_pid="${1}"
  local retore_spinner="false"

  if [ -d "${AZ_CONFIG_HOME}" ]; then
    local -r cached_pat="$(<"${AZ_CONFIG_HOME}/token")"
  else
    local -r cached_pat=''
  fi
  AZURE_DEVOPS_EXT_PAT="${AZURE_DEVOPS_EXT_PAT:-${cached_pat}}"

  if [ -z "${AZURE_DEVOPS_EXT_PAT:-}" ]; then
    set +e
    local exit_code="0", command_output=""
    command_output="$(az account show 2>&1)"
    exit_code="$?"
    if [ "${exit_code}" != "0" ]; then
      if kill -s 0 "${spinner_pid}" >/dev/null 2>&1; then
        kill -TSTP "${spinner_pid}"
        retore_spinner="true"
      fi
      local options=("PAT" "AZ Web SSO")
      (
        exec </dev/tty
        exec 1>&2
        select_option "${options[@]}"
      )
      choice=$?
      if [ "${choice}" = "0" ]; then
        (
          exec </dev/tty
          ask_for_pat "${AZ_CONFIG_HOME}"
        )
        AZURE_DEVOPS_EXT_PAT="$(<"${AZ_CONFIG_HOME}/token")"
        az devops login | exit 1
      else
        az login || exit 1
      fi
      if [ "${retore_spinner}" = "true" ]; then
        kill -CONT "${spinner_pid}"
      fi
      set -e
    fi
  fi
}

get_project_from_url() {
  local url="${1}"

  if [[ "${url}" = https://* ]]; then
    printf '%s' "${url}" | cut -d'/' -f 5
  else
    printf '%s' "${url}" | cut -d':' -f2 | cut -d'.' -f1 | cut -d '/' -f3
  fi
}

get_states() {
  local -r remote_with_branch="${1}"
  local -r branch="$(echo "${remote_with_branch}" | cut -d'/' -f2-)"
  local -r remote="$(echo "${remote_with_branch}" | cut -d'/' -f1)"
  load_cache "${remote}"
  az repos pr list --detect true --project "${AZ_PROJECT_NAME}" --source-branch "${branch}" --status all | jq -r '[.[] | {state: .status, id: .pullRequestId }]'
}

get_any_open_states() {
  local states="${*}"
  printf '%s\n' "${states}" | jq 'map(select(.state == "active")) | length > 0'
}

get_only_completed() {
  local states="${*}"
  printf '%s\n' "${states}" | jq 'map(select(.state != "completed" and .state != "abandoned")) | length == 0'
}

declare -r EMPTY_OBJECT_ID='0000000000000000000000000000000000000000'

branch_was_deleted_remotely() {
  local -r remote_with_branch="${1}"
  local -r branch="$(printf '%s' "${remote_with_branch}" | cut -d'/' -f2-)"
  local -r remote="$(echo "${remote_with_branch}" | cut -d'/' -f1)"
  load_cache "${remote}"
  az rest --only-show-errors -u "${AZ_PROJECT_URL}/pushes?%24skip=0&%24top=1&searchCriteria.refName=refs/heads/${branch}&searchCriteria.includeRefUpdates=true" | jq -r '.value[0].refUpdates[0].newObjectId=="'"${EMPTY_OBJECT_ID}"'"'
}
