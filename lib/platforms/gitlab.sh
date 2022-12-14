#!/usr/bin/env bash

# shellcheck disable=SC2034
COMPLETED_STATES=('merged' 'closed')

GCMPB_GL_FILE_TOKEN="${GCMPB_GL_FILE_TOKEN:-''}"

pre_init_hook() {
  local -r has_errors="$(glab auth status 2>&1 | grep 'x')"
  if [ -n "${has_errors}" ]; then
    if [ -f "${GCMPB_GL_FILE_TOKEN}" ]; then
      glab auth login --stdin <"${GCMPB_GL_FILE_TOKEN}" || exit 1
    else
      exec </dev/tty
      glab auth login || exit 1
    fi
  fi
}

get_states() {
  local -r remote_with_branch="${1}"
  local -r branch="$(echo "${remote_with_branch}" | cut -d'/' -f2-)"
  local -r remote="$(echo "${remote_with_branch}" | cut -d'/' -f1)"
  glab api /projects/:id/merge_requests -Fsource_branch="${branch}" -X GET | jq -r '[.[] | {state: .state, id: .id, iid: .iid }]'
}

get_any_open_states() {
  local -r states="${*}"
  printf '%s\n' "${states}" | jq 'map(select(.state == "opened")) | length > 0'
}

get_only_completed() {
  local -r states="${*}"
  printf '%s\n' "${states}" | jq 'map(select(.state != "merged" and .state != "closed")) | length == 0'
}
