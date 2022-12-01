#!/usr/bin/env bash
# shellcheck disable=SC2034
COMPLETED_STATES=('MERGED' 'CLOSED')

pre_init_hook() {
  set +e
  local exit_code="0"
  status="$(gh auth status 2>&1)"
  exit_code="$?"
  set -e
  if [ "${exit_code}" != "0" ]; then
    printf '%s' "${status}"
    exec </dev/tty
    gh auth login || exit 1
  fi
}

get_states() {
  local -r remote_with_branch="${1}"
  local -r branch="$(echo "${remote_with_branch}" | cut -d'/' -f2-)"
  local -r remote="$(echo "${remote_with_branch}" | cut -d'/' -f1)"
  local -r owner_and_repo="$(git remote get-url --push "$(git remote "${remote}" | grep 'push')" | cut -d':' -f2 | cut -d'.' -f1)"
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
