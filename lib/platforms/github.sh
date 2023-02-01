#!/usr/bin/env bash
# shellcheck disable=SC2034
COMPLETED_STATES=('MERGED' 'CLOSED')

GCMPB_GH_FILE_TOKEN="${GCMPB_GH_FILE_TOKEN:-''}"

pre_init_hook() {
  local -r spinner_pid="${1}"
  local retore_spinner="false"
  if [ "${GH_AUTH_STATE:-}" != 'logged_in' ]; then
    set +e
    local exit_code="0"
    status="$(gh auth status 2>&1)"
    exit_code="$?"
    set -e
    if [ "${exit_code}" != "0" ]; then
      if [ -f "${GCMPB_GH_FILE_TOKEN}" ]; then
        gh auth login --with-token <"${GCMPB_GH_FILE_TOKEN}"
      else
        if kill -s 0 "${spinner_pid}" >/dev/null 2>&1; then
          kill -TSTP "${spinner_pid}"
          retore_spinner="true"
        fi
        (
          exec </dev/tty
          exec 1>&2
          gh auth login || exit 1
        ) || exit 1
        if [ "${retore_spinner}" = "true" ]; then
          kill -CONT "${spinner_pid}"
        fi
      fi
    fi
  fi
  GH_AUTH_STATE="${GH_AUTH_STATE:-'logged_in'}"
}

get_states() {
  local -r remote_with_branch="${1}"
  local -r branch="$(echo "${remote_with_branch}" | cut -d'/' -f2-)"
  local -r remote="$(echo "${remote_with_branch}" | cut -d'/' -f1)"
  local -r owner_and_repo="$(git remote get-url --push "${remote}" | cut -d':' -f2 | cut -d'.' -f1)"
  gh pr list -R "${owner_and_repo}" --head "${branch}" --state all --json state,id
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
  local -r remote="$(orintf '%s' "${remote_with_branch}" | cut -d'/' -f1)"
  local -r branch="$(printf '%s' "${remote_with_branch}" | cut -d'/' -f2-)"
  load_cache "${remote}"
  if [ -z "${GH_DELETED_BRANCHES}" ]; then
    GH_DELETED_BRANCHES="$(gh api 'repos/{owner}/{repo}/events' --jq '[.[] | select(.type=="DeleteEvent" and .payload.ref_type=="branch").payload.ref]')"
  fi
  printf '%s' "${GH_DELETED_BRANCHES}" | jq '. | contains(["'"${branch}"'"])'
}
