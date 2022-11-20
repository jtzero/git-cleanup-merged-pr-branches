
COMPLETED_STATES=('completed' 'abandoned')

pre_init_hook() {
  if ! az account show 2>&1 > /dev/null ; then
    az login || exit 1
  fi
}

get_states() {
  local -r remote_with_branch="${1}"
  local -r branch="$(echo "${remote_with_branch}" | cut -d'/' -f2-)"
  local -r remote="$(echo "${remote_with_branch}" | cut -d'/' -f1)"
  local -r version_and_org_and_project_and_repo="$(git remote get-url --push "$(git remote | head -n1)" | cut -d':' -f2 | cut -d'.' -f1)"
  local -r project="$(echo "${version_and_org_and_project_and_repo}" | cut -d '/' -f3)"
  az repos pr list --detect true --project "${project}"  --source-branch "${branch}" --status all | jq -r '[.[] | {state: .status, id: .pullRequestId }]'
}

get_any_open_states() {
  local states="${@}"
  printf '%s\n' "${states}" | jq 'map(select(.state == "active")) | length > 0'
}

get_only_completed() {
  local states="${@}"
  printf '%s\n' "${states}" | jq 'map(select(.state != "completed" and .state != "abandoned")) | length == 0'
}
