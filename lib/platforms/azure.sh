#!/usr/bin/env bash

# shellcheck disable=SC2034
COMPLETED_STATES=('completed' 'abandoned')

pre_init_hook() {
  if [ -z "${AZURE_DEVOPS_EXT_PAT:-}" ]; then
    set +e
    local exit_code="0"
    local -r status="$(az account show 2>&1)"
    exit_code="$?"
    set -e
    if [ "${exit_code}" != "0" ]; then
      az login || exit 1
    fi
  fi
}

get_states() {
  local -r remote_with_branch="${1}"
  local -r branch="$(echo "${remote_with_branch}" | cut -d'/' -f2-)"
  local -r remote="$(echo "${remote_with_branch}" | cut -d'/' -f1)"
  local -r version_and_org_and_project_and_repo="$(git remote get-url --push "${remote}" | cut -d':' -f2 | cut -d'.' -f1)"
  local -r project="$(echo "${version_and_org_and_project_and_repo}" | cut -d '/' -f3)"
  az repos pr list --detect true --project "${project}" --source-branch "${branch}" --status all | jq -r '[.[] | {state: .status, id: .pullRequestId }]'
}

get_any_open_states() {
  local states="${*}"
  printf '%s\n' "${states}" | jq 'map(select(.state == "active")) | length > 0'
}

get_only_completed() {
  local states="${*}"
  printf '%s\n' "${states}" | jq 'map(select(.state != "completed" and .state != "abandoned")) | length == 0'
}
