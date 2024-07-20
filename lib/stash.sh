#!/usr/bin/env bash

get_orphaned_stashes() {
  local ordered_orphaned_stashes=""
  local orphaned_stashes=()
  while IFS= read -r line; do
    local branch_name="$(printf '%s' "$line" | cut -d':' -f2 | rev | cut -d' ' -f1 | rev)"
    local matching_branch_on_local="$(git branch --list "${branch_name}" --format='%(refname:short)')"
    if [ -z "${matching_branch_on_local}" ]; then
      orphaned_stashes+=("$line")
    fi
  done <<<"$(git stash list)"

  if [ ${#orphaned_stashes[@]} -eq 0 ]; then
    printf ""
  else
    ordered_orphaned_stashes="$(printf '%s\n' "${orphaned_stashes[@]}" | tac)"
  fi
  for stash_item in "${ordered_orphaned_stashes[@]}"; do
    printf "%s\n" "${stash_item}"
  done
}

delete_stashes_from_lines() {
  local -r ordered_orphaned_stashes="${1}"
  local stash_numebrs=()
  while IFS= read -r stash; do
    local stash_no
    stash_no="$(stash_number_from_message "${stash}")"
    stash_numbers+=("${stash_no}")
  done <<<"${orphaned_stashes}"
  delete_stashes "${stash_numbers[@]}"
}

stash_number_from_message() {
  local -r stash_line="${1}"
  printf '%s' "${stash_line}" | cut -d':' -f1
}

stash_diff() {
  local -r stash_ref="${1}"
  git stash show -p "${stash_ref}"
}

delete_stashes() {
  git stash drop "$@"
}
