#!/usr/bin/env bats

setup() {
  load 'test_helper/bats-support/load' # this is required by bats-assert!
  load 'test_helper/bats-assert/load'
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  ROOT_DIR="$(dirname "${DIR}")"
  . "${ROOT_DIR}/lib/git-cleanup-merged-pr-branches"
}

@test "join_by" {
  output="$(join_by ':' $'a\nb\nc')"
  assert_output "a:b:c"
}

@test "available_platforms" {
  find() {
    printf '%s\n%s\n%s\n' 'github.sh' 'azure.sh' 'gitlab.sh'
  }
  output="$(available_platforms "/nop")"
  unset -f find
  assert_output 'github|azure|gitlab'
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
  git() {
    printf '%s\n' '/nop'
  }
  output="$(config_file_path)"
  unset -f git
  assert_output --regexp '/nop/.+/cleanup'
}

@test "config" {
  git() {
    printf '%s\n' '/nop'
  }
  output="$(config)"
  unset -f git
  assert_output ''
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

@test "interactive_prune_tracking" {
  git() {
    local remote_one="$(printf '%s' "${3}" | cut -d ' ' -f1)"
    local remote_two="$(printf '%s' "${3}" | cut -d ' ' -f2)"
    cat<<-EOF
Pruning ${remote_one}
URL: git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git
 * [pruning] origin/testing
Pruning ${remote_two}
URL: git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git
 * [pruning] upstream/testing
EOF
  }
  local -r remotes_to_prune=('origin' 'upstream')
  output="$(interactive_prune_tracking true "${remotes_to_prune[*]}" <<<$(printf $'y\n'))"
  local -r expected="$(cat<<EOF
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

@test "decide_print" {
  output="$(decide_print 'delete' 'local-branch' 'idk' '[{\"state\": \"merged\", \"id\": 11111 }]')"
  assert_output 'delete:local-branch:idk:[{\"state\": \"merged\", \"id\": 11111 }]'
}
