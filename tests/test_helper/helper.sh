#!/usr/bin/env bats
#

reset_head_state() {
  local current_branch
  current_branch="$(git branch --show-current)"
  if [ "${ORIGINALLY_DETACHED}" = "false" ]; then
    if [ "${current_branch}" != "${ORIGINAL_BRANCH_OR_DETACHED_COMMIT}" ]; then
      git checkout "${ORIGINAL_BRANCH_OR_DETACHED_COMMIT}" >/dev/null
    fi
  elif [ "${ORIGINALLY_DETACHED}" = "true" ] && [ "${current_branch}" != "" ]; then
    git checkout "${ORIGINAL_BRANCH_OR_DETACHED_COMMIT}" >/dev/null
  fi
}

unset_git_override() {
  if [ "$(type -t git)" = "function" ]; then
    unset -f git
  fi
}
