#!/usr/bin/env bash
#
#
set -Eeuo pipefail

# shellcheck disable=SC2034
COMPLETED_STATES=('merged' 'closed')

GCMPB_GL_FILE_TOKEN="${GCMPB_GL_FILE_TOKEN:-''}"

NEW_VERSION_STATEMENT="A new version of glab has been released|https://gitlab.com/gitlab-org/cli/-/releases/"

get_cache_config() {
  local -r remote="${1}"
  local -r config_file="$(git rev-parse git rev-parse --git-dir)/info/cleanup-az-cache-${remote}"
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

pre_init_hook() {
  local -r spinner_pid="${1}"
  local retore_spinner="false"
  local -r has_errors="$(glab auth status 2>&1 | grep --color=always -Ev "${NEW_VERSION_STATEMENT}" | grep 'x')"
  if [ -n "${has_errors}" ]; then
    if [ -f "${GCMPB_GL_FILE_TOKEN}" ]; then
      glab auth login --stdin <"${GCMPB_GL_FILE_TOKEN}" 2> >(grep --color=always -Ev "${NEW_VERSION_STATEMENT}" >&2) || exit 1
    else
      if kill -s 0 "${spinner_pid}" >/dev/null 2>&1; then
        kill -TSTP "${spinner_pid}"
        retore_spinner="true"
      fi
      (
        exec </dev/tty
        exec 1>&2
        glab auth login 2> >(grep --color=always -Ev "${NEW_VERSION_STATEMENT}" >&2) || exit 1
      ) || exit 1
      if [ "${retore_spinner}" = "true" ]; then
        kill -CONT "${spinner_pid}"
      fi
    fi
  fi
  GL_AUTH_STATE="${GL_AUTH_STATE:-'logged_in'}"
}

get_states() {
  local -r remote_with_branch="${1}"
  local -r branch="$(echo "${remote_with_branch}" | cut -d'/' -f2-)"
  local -r remote="$(echo "${remote_with_branch}" | cut -d'/' -f1)"
  glab api /projects/:id/merge_requests -Fsource_branch="${branch}" -X GET 2> >(grep --color=always -Ev "${NEW_VERSION_STATEMENT}" >&2) | jq -r '[.[] | {state: .state, id: .id, iid: .iid }]'
}

get_any_open_states() {
  local -r states="${*}"
  printf '%s\n' "${states}" | jq 'map(select(.state == "opened")) | length > 0'
}

get_only_completed() {
  local -r states="${*}"
  printf '%s\n' "${states}" | jq 'map(select(.state != "merged" and .state != "closed")) | length == 0'
}

load_cache() {
  local -r remote="${1}"
  GL_REMOTE="${GH_REMOTE:-}"
  if [ "${GL_REMOTE}" != "${remote}" ]; then
    GL_REMOTE="${remote}"
    GL_DELETED_BRANCHES=""
  fi
}

branch_was_deleted_remotely() {
  local -r remote_with_branch="${1}"
  local -r remote="$(printf '%s' "${remote_with_branch}" | cut -d'/' -f1)"
  local -r branch="$(printf '%s' "${remote_with_branch}" | cut -d'/' -f2-)"
  load_cache "${remote}"
  if [ -z "${GL_DELETED_BRANCHES:-}" ]; then
    GL_DELETED_BRANCHES="$(glab api /projects/:id/events 2> >(grep --color=always -Ev "${NEW_VERSION_STATEMENT}" >&2) | jq -r '[.[] | select(.action_name=="deleted" and .push_data.ref_type=="branch") | .push_data.ref]')"
  fi
  printf '%s' "${GL_DELETED_BRANCHES}" | jq '. | contains(["'"${branch}"'"])'
}

post_run_hook() {
  # shellcheck disable=SC2260
  glab >/dev/null
}
