#!/usr/bin/env bash
# shellcheck disable=SC2034
COMPLETED_STATES=('MERGED' 'CLOSED')

GCMPB_GH_FILE_TOKEN="${GCMPB_GH_FILE_TOKEN:-''}"

pre_init_hook() {
  set +e
  local exit_code="0"
  status="$(gh auth status 2>&1)"
  exit_code="$?"
  set -e
  if [ "${exit_code}" != "0" ]; then
    if [ -f "${GCMPB_GH_FILE_TOKEN}" ]; then
      gh auth login --with-token <"${GCMPB_GH_FILE_TOKEN}"
    else
      exec </dev/tty
      gh auth login || exit 1
    fi
  fi
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

branch_was_deleted_remotely() {
  local -r remote_with_branch="${1}"
  local -r branch="$(printf '%s' "${remote_with_branch}" | cut -d'/' -f2-)"
  gh api 'repos/{owner}/{repo}/events' --jq '.[] | select(.type=="DeleteEvent").payload | select(.ref_type=="branch" and .ref=="'"${branch}"'").ref=="'"${branch}"'"'
}
