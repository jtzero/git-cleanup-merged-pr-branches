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

@test "config_file_path" {
  output="$(config_file_path)"
  unset -f git
  assert_output --regexp '.git\/.+\/cleanup'
}

@test "config" {
  git() {
    printf '%s\n' '/nop'
  }
  output="$(config)"
  unset -f git
  assert_output ''
}

@test "excluded_by_config_default" {
  output="$(excluded_by_config)"
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

@test "decide_remote_group" {
  decide() {
    printf '%s' 'doit'
  }
  output="$(decide_remote_group "${DIR}/fixtures/platforms/gitlab.sh" "origin" "1111" "true")"
  assert_output "ZG9pdA=="
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

@test "delete_branches" {
  git() {
    printf '%s' 'Deleted branch integration-test (was fe0bfc8)'
  }
  output="$(delete_branches 'ted')"
  expected="Deleted branch integration-test \(was .+\)"
  assert_output --regexp "${expected}"
}

@test "should_run_succeeds" {
  output="$(should_run "false" "BRANCHES" "false" "asdfqwer" "asdf" "false")"
  expected="true"
  assert_output "${expected}"
}

@test "should_run_skip" {
  output="$(should_run "true" "BRANCHES" "false" "asdfqwer" "asdf" "false")"
  expected="false"
  assert_output "${expected}"
}

@test "should_run_files" {
  output="$(should_run "false" "FILES" "false" "asdfqwer" "asdf" "false")"
  expected="false"
  assert_output "${expected}"
}

@test "should_run_interactive_rebase" {
  output="$(should_run "false" "BRANCHES" "true" "asdfqwer" "asdf" "false")"
  expected="false"
  assert_output "${expected}"
}

@test "should_run_on_clone" {
  output="$(should_run "false" "BRANCHES" "false" "${CLONE_SHA}" "asdf" "false")"
  expected="false"
  assert_output "${expected}"
}

@test "should_run_new_branch_new_branch_and_config_true" {
  output="$(should_run "false" "BRANCHES" "false" "asdfqwer" "asdfqwer" "true")"
  expected="true"
  assert_output "${expected}"
}

@test "should_run_new_branch_new_branch_and_config_false" {
  output="$(should_run "false" "BRANCHES" "false" "asdfqwer" "asdfqwer" "false")"
  expected="false"
  assert_output "${expected}"
}
