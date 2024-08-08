#!/usr/bin/env bash

set -Eeuo pipefail

if [ -z "${GCMPB_PLATFORMS_DIR:-}" ]; then
  if [ -z "${BASH_SOURCE[0]:-}" ]; then
    # zsh
    GCMPB_PLATFORMS_DIR="${0:A:h}"
    # shellcheck disable=SC2034
    IS_ZSH=1
  else
    if ! command -v realpath >/dev/null 2>&1; then
      exit 1
    fi
    GCMPB_PLATFORMS_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
    # shellcheck disable=SC2034
    IS_BASH=1
  fi
fi

GCMPB_LIB_DIR="$(dirname "${GCMPB_PLATFORMS_DIR}")"
# shellcheck source=../cache.sh
. "${GCMPB_LIB_DIR}/cache.sh"
# shellcheck disable=SC2034
COMPLETED_STATES=('MERGED' 'CLOSED')

GCMPB_GH_FILE_TOKEN="${GCMPB_GH_FILE_TOKEN:-}"

GH_AUTH_LOGGED_IN_STATE='not_logged_in'
GH_USER_HAS_PR_ACCESS='false'

# TODO replace this with the one from main
printerr() { printf "\033[0;31m%s\033[0m\n" "$*" >&2; }

current_active_github_user() {
  gh api /user | jq .login
}

get_last_active_github_user() {
  (cache_file | grep 'last_active_github_user=' || [[ $? == 1 ]]) | head -n 1 | cut -d'=' -f2 | tr -d '"'
}

save_current_active_github_user() {
  local -r current_active_github_user_name="$(current_active_github_user)"
  local -r filepath="$(cache_filepath)"
  local -r other_lines="$(cache_file | grep -v 'last_active_github_user=' || [[ $? == 1 ]])"
  printf '%s\n' "${other_lines}" >"${filepath}"
  printf 'last_active_github_user=%s\n' "${current_active_github_user_name}" >>"${filepath}"
}

activate_last_active_github_user() {
  local last_active_github_user="$(get_last_active_github_user)"
  readonly last_active_github_user
  if [ -z "${last_active_github_user}" ]; then
    local -r user_found="$(switch_to_user_that_can_acces_this_repo)"
    if [ -z "${user_found}" ]; then
      printerr "No user listed in \`gh auth status\` can access this repo\n"
    else
      GH_AUTH_LOGGED_IN_STATE='logged_in'
    fi
  else
    (gh auth switch -u "${last_active_github_user}" && GH_AUTH_LOGGED_IN_STATE='logged_in') || GH_AUTH_LOGGED_IN_STATE='not_logged_in'
  fi
}

gh_auth_status() {
  set +e
  local exit_code="0"
  _status="$(gh auth status 2>&1)"
  exit_code="$?"
  if [ "${exit_code}" = "0" ]; then
    GH_AUTH_LOGGED_IN_STATE='logged_in'
  fi
  set -e
}

user_has_pr_access() {
  set +e
  local exit_code="1"
  (gh pr list --limit 1 >/dev/null 2>&1)
  exit_code="$?"
  set -e
  if [ "${exit_code}" -eq 0 ]; then
    GH_USER_HAS_PR_ACCESS='true'
  else
    GH_USER_HAS_PR_ACCESS='false'
  fi
}

pre_init_hook() {
  local -r spinner_pid="${1}"
  local retore_spinner="false"
  gh_auth_status
  if [ "${GH_AUTH_LOGGED_IN_STATE}" = 'logged_in' ]; then
    user_has_pr_access
  fi
  if [ "${GH_USER_HAS_PR_ACCESS}" = 'false' ] && [ -n "${GCMPB_GH_FILE_TOKEN}" ]; then
    gh auth login --with-token <"${GCMPB_GH_FILE_TOKEN}" && GH_AUTH_LOGGED_IN_STATE='logged_in' && user_has_pr_access
  fi
  if [ "${GH_USER_HAS_PR_ACCESS}" = 'false' ]; then
    activate_last_active_github_user
    user_has_pr_access
  fi
  if [ "${GH_USER_HAS_PR_ACCESS}" = 'false' ]; then
    if kill -s 0 "${spinner_pid}" >/dev/null 2>&1; then
      kill -TSTP "${spinner_pid}"
      retore_spinner="true"
    fi
    (
      exec </dev/tty
      exec 1>&2
      gh auth login || exit 1
    ) || exit 1
    GH_AUTH_LOGGED_IN_STATE='logged_in'
    if [ "${retore_spinner}" = "true" ]; then
      kill -CONT "${spinner_pid}"
    fi
  fi
}

switch_to_user_that_can_acces_this_repo() {
  if gh pr list --limit 1 >/dev/null 2>&1; then
    printf 'found'
  else
    while IFS= read -r user; do
      if gh auth switch -u "${user}" && gh repo view >/dev/null 2>&1; then
        printf 'found'
        return
      fi
    done <<<"$(user_names)"
  fi
}

user_names() {
  gh auth status | grep 'Logged' | grep -oE "account.*" | cut -d' ' -f2
}

get_states() {
  local -r remote_with_branch="${1}"
  local -r branch="$(echo "${remote_with_branch}" | cut -d'/' -f2-)"
  local -r remote="$(echo "${remote_with_branch}" | cut -d'/' -f1)"
  local owner_and_repo remote_url
  remote_url="$(git remote get-url --push "${remote}")"
  readonly remote_url
  owner_and_repo="$(parse_remote_url "${remote_url}")"
  readonly owner_and_repo
  if [ -z "${owner_and_repo}" ]; then
    printerr "Could not parse owner and repo from remote url: ${remote_url}"
    exit 1
  fi
  gh pr list -R "${owner_and_repo}" --head "${branch}" --state all --json state,id
}

parse_remote_url() {
  local -r remote_url="${1}"
  if [[ "${remote_url}" =~ ^git@ ]]; then
    printf '%s' "${remote_url}" | cut -d':' -f2 | cut -d'.' -f1
  elif [[ "${remote_url}" =~ ^[a-z]+: ]]; then
    printf '%s' "${remote_url}" | cut -d'/' -f4- | cut -d'.' -f1
  fi
}

get_any_open_states() {
  local states="${*}"
  printf '%s\n' "${states}" | jq 'map(select(.state == "OPEN")) | length > 0'
}

get_only_completed() {
  local states="${*}"
  printf '%s\n' "${states}" | jq 'map(select(.state != "MERGED" and .state != "CLOSED")) | length == 0'
}

load_cache() {
  local -r remote="${1}"
  GH_REMOTE="${GH_REMOTE:-}"
  if [ "${GH_REMOTE}" != "${remote}" ]; then
    GH_REMOTE="${remote}"
    GH_DELETED_BRANCHES=""
  fi
}

branch_was_deleted_remotely() {
  local -r remote_with_branch="${1}"
  local -r remote="$(printf '%s' "${remote_with_branch}" | cut -d'/' -f1)"
  local -r branch="$(printf '%s' "${remote_with_branch}" | cut -d'/' -f2-)"
  load_cache "${remote}"
  if [ -z "${GH_DELETED_BRANCHES:-}" ]; then
    GH_DELETED_BRANCHES="$(gh api 'repos/{owner}/{repo}/events' --jq '[.[] | select(.type=="DeleteEvent" and .payload.ref_type=="branch").payload.ref]')"
  fi
  printf '%s' "${GH_DELETED_BRANCHES}" | jq '. | contains(["'"${branch}"'"])'
}

post_run_hook() {
  save_current_active_github_user
}
