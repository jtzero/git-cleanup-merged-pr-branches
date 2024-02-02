#!/usr/bin/env bats

setup() {
  bats_load_library 'test_helper/bats-support' # this is required by bats-assert!
  bats_load_library 'test_helper/bats-assert'
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  ROOT_DIR="$(dirname "${BATS_TEST_LIB}")"
  . "${ROOT_DIR}/lib/git-cleanup-merged-pr-branches"
}

@test "join_by" {
  output="$(join_by ':' $'a\nb\nc')"
  assert_output "a:b:c"
}

@test "query_vcs_platform" {
  git() {
    printf '%s\n%s\n' 'origin	git@gboatbin.com:jtzero/git-cleanup-merged-pr-branches.git (fetch)' 'origin	git@gboatbin.com:jtzero/git-cleanup-merged-pr-branches.git (push)'
  }
  output="$(query_vcs_platform 'origin' 'boatbin')"
  unset -f find
  unset -f git
  assert_output 'found:boatbin'
}

@test "exit_if_platform_not_found_found_result" {
  run exit_if_platform_not_found 'found:github' '${ROOT_DIR}/git-cleanup-merged-pr-branches/platforms' ''
  assert_success 0
}

@test "exit_if_platform_not_found_not_found_result" {
  run exit_if_platform_not_found 'not_found:platform not found from `git remote -v` github|azure|gitlab' '${ROOT_DIR}/git-cleanup-merged-pr-branches/platforms' ''
  assert_failure 22
}

@test "detect_pruneable" {
  git() {
    if [ "${2:-}" = "prune" ]; then
      if [ "${3:-}" = "-n" ] && [ -z "${4:-}" ]; then
        printf 'ERROR: No remote to prune specified.'
        exit 1
      fi
      printf '%s\n%s\n%s\n' 'Pruning origin' 'URL: git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git' ' * [would prune] origin/test-branch'
    elif [ "${2:-}" = "" ]; then
      printf '%s\n%s\n' 'origin' 'upstream'
    fi
  }
  output="$(detect_pruneable 2>&1)"
  assert_output <<EOF
  'Pruning origin
URL: git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git
 * [would prune] origin/test-branch
EOF
}

@test "config_file_path" {
  output="$(config_file_path)"
  unset -f git
  assert_output --regexp '.git\/.+\/gcmpb'
}

@test "config" {
  git() {
    printf '%s\n' '/nop'
  }
  output="$(config)"
  unset -f git
  assert_output ''
}

@test "ignore_cleaning_branches_config_value_default" {
  output="$(ignore_cleaning_branches_config_value)"
  assert_output ""
}

@test "printerr_stdout_empty" {
  output="$(printerr 'test')"
  assert_output ""
}

@test "printerr_stderr_value" {
  output="$(printerr 'test' 2>&1)"
  assert_output "${output}"
}

@test "printverbose_stdout_empty" {
  output="$(printerr 'test')"
  assert_output ""
}

@test "printverbose_stderr_value" {
  output="$(printerr 'test' 2>&1)"
  assert_output "${output}"
}

@test "available_platforms" {
  output="$(available_platforms "${DIR}/fixtures/platforms/")"
  assert_output "azure|gitlab"
}

@test "decide_print" {
  output="$(decide_print 'delete' 'local-branch' 'idk' '[{\"state\": \"merged\", \"id\": 11111 }]')"
  assert_output 'delete:local-branch:idk:[{\"state\": \"merged\", \"id\": 11111 }]'
}

@test "array_join_gt_one" {
  ary=(1 2 3 4)
  output="$(array_join ',' "${ary[@]}")"
  assert_output "1,2,3,4"
}

@test "array_join_only_one" {
  ary=(4)
  output="$(array_join ',' "${ary[@]}")"
  assert_output "4"
}

@test "ask" {
  output="$(ask 'question' false <<<$(printf $'y\n'))"
  assert_output "y"
}

@test "handle_plan" {
  skip
}

@test "apply_plan" {
  skip
}

@test "apply_partial" {
  skip
}

@test "interactive_prune_tracking" {
  git() {
    local remote_one="$(printf '%s' "${3}" | cut -d ' ' -f1)"
    local remote_two="$(printf '%s' "${3}" | cut -d ' ' -f2)"
    cat <<-EOF
Pruning ${remote_one}
URL: git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git
 * [pruning] origin/testing
Pruning ${remote_two}
URL: git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git
 * [pruning] upstream/testing
EOF
  }
  local -r remotes_to_prune=('origin' 'upstream')
  output="$(interactive_prune_tracking true "${remotes_to_prune[*]}" false <<<$(printf $'y\n'))"
  local -r expected="$(
    cat <<EOF
Pruning origin
URL: git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git
 * [pruning] origin/testing
Pruning upstream
URL: git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git
 * [pruning] upstream/testing
EOF
  )"
  assert_output "${expected}"
}

@test "prune_tracking" {
  output=""
  git() {
    output="${*}"
  }
  remotes_to_prune=('origin' 'upstream')
  prune_tracking "${remotes_to_prune[*]}"
  assert_output 'remote prune origin upstream'
}

@test "get_decision_on_branch_with_pr_with_open_states" {
  run bash -s <<EOF
  . "${ROOT_DIR}/lib/git-cleanup-merged-pr-branches"
  get_any_open_states() {
    printf 'true'
  }
  get_decision_on_branch_with_pr 'local-branch' 'remote-branch' '[{"state": "OPEN", "id": 11111 }]'
EOF
  assert_output 'skip:local-branch:local-branch->remote-branch has open pr'"'"'s, not deleting:[{"state": "OPEN", "id": 11111 }]'
}

@test "get_decision_on_branch_with_pr_with_no_open_states_and_completed" {
  run bash -s <<EOF
  . "${ROOT_DIR}/lib/git-cleanup-merged-pr-branches"
  get_any_open_states() {
    printf 'false'
  }
  get_only_completed() {
    printf 'true'
  }
  get_decision_on_branch_with_pr 'local-branch' 'remote-branch' '[{"state": "MERGED", "id": 11111 }]'
EOF
  assert_output 'delete:local-branch:local-branch->remote-branch had a pr that completed:[{"state": "MERGED", "id": 11111 }]'
}

@test "get_decision_on_branch_with_pr_with_no_open_states_and_no_completed" {
  run bash -s <<EOF
  . "${ROOT_DIR}/lib/git-cleanup-merged-pr-branches"
  COMPLETED_STATES='MERGED'
  get_any_open_states() {
    printf 'false'
  }
  get_only_completed() {
    printf 'false'
  }
  get_decision_on_branch_with_pr 'local-branch' 'remote-branch' '[{"state": "unknown", "id": 11111 }]'
EOF
  assert_output 'skip:local-branch:local-branch->remote-branch has a pr that is not marked as MERGED, not deleting:[{"state": "unknown", "id": 11111 }]'
}


@test "delete_branches" {
  git() {
    printf '%s' 'Deleted branch integration-test (was fe0bfc8)'
  }
  output="$(delete_branches 'ted')"
  expected="Deleted branch integration-test \(was .+\)"
  assert_output --regexp "${expected}"
}

@test "should_run_skip" {
  output="$(should_run "true" "1" "BRANCHES" "false" "asdfqwer" "asdf" "false" "0" "false")"
  expected="false:skip_env_variable_set"
  assert_output "${expected}"
}

@test "should_run_files" {
  output="$(should_run "false" "1" "FILES" "false" "asdfqwer" "asdf" "false" "0" "false")"
  expected="false:checking_out_files"
  assert_output "${expected}"
}

@test "should_run_interactive_rebase" {
  output="$(should_run "false" "1" "BRANCHES" "true" "asdfqwer" "asdf" "false" "0" "false")"
  expected="false:interactive_rebase_is_in_progress"
  assert_output "${expected}"
}

@test "should_run_on_clone" {
  output="$(should_run "false" "1" "BRANCHES" "false" "${CLONE_SHA}" "asdf" "false" "0" "false")"
  expected="false:newly_cloned_repo"
  assert_output "${expected}"
}

@test "should_run_new_branch_and_config_true" {
  new_branch() {
    printf 'true'
  }
  output="$(should_run "false" "1" "BRANCHES" "false" "asdfqwer" "asdfqwer" "true" "0" "false")"
  expected="true"
  assert_output "${expected}"
}

@test "should_run_new_branch_and_config_false" {
  new_branch() {
    printf 'true'
  }
  output="$(should_run "false" "1" "BRANCHES" "false" "asdfqwer" "asdfqwer" "false" "0" "false")"
  expected="false:run_on_first_move_to_newly_created_branch_set_to_false"
  assert_output "${expected}"
}

@test "should_run_succeeds_on_not_a_new_branch" {
  new_branch() {
    printf 'false'
  }
  output="$(should_run "false" "1" "BRANCHES" "false" "asdfqwer" "asdf" "false" "0" "false")"
  expected="true"
  assert_output "${expected}"
}

@test "new_branch_returns_true_when_branch_moved_to_for_the_first_time" {
  git() {
    local arg="${1:-}"
    local second_arg="${2:-}"
    if [ "${arg}" = "reflog" ]; then
      printf '5751447 (new-branch, main) HEAD@{10}: checkout: moving from main to new-branch'
    elif [ "${arg}" = "branch" ] && [ "${second_arg}" = "--show-current" ]; then
      printf 'new-branch'
    else
      git "$@"
    fi
  }
  output="$(new_branch "BRANCHES" "asdfqwer" "asdfqwer")"
  expected="true"
  assert_output "${expected}"
}

@test "new_branch_returns_false_when_branch_moved_to_after_the_first_time" {
  git() {
    local arg="${1:-}"
    local second_arg="${2:-}"
    if [ "${arg}" = "reflog" ]; then
      printf '%s\n%s\n' '5751447 (new-branch, main) HEAD@{10}: checkout: moving from main to new-branch' '5751447 (new-branch, main) HEAD@{10}: checkout: moving from main to new-branch'
    elif [ "${arg}" = "branch" ] && [ "${second_arg}" = "--show-current" ]; then
      printf 'new-branch'
    else
      git "$@"
    fi
  }
  output="$(new_branch "BRANCHES" "asdfqwer" "asdfqwer")"
  expected="false"
  assert_output "${expected}"
}
