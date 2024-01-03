#!/usr/bin/env bats

setup() {
  bats_load_library 'test_helper/bats-support' # this is required by bats-assert!
  bats_load_library 'test_helper/bats-assert'
  ROOT_DIR="$(dirname "${BATS_TEST_LIB}")"
  TESTS_INTEGRATION_DIR="${BATS_TEST_LIB}/integration"
  PATH="${ROOT_DIR}/bin:$PATH"
}

@test "print help" {
  run git-cleanup-merged-pr-branches 'help'
  [ "$status" -eq 0 ]
}

@test "get_decision_on_branch_with_pr_gitlab_merged" {
  . "${ROOT_DIR}/lib/platforms/gitlab.sh"
  . "${ROOT_DIR}/lib/git-cleanup-merged-pr-branches"
  local -r json="$(
    cat <<'EOF'
[{"state": "merged", "id": 11111 }]
EOF
  )"
  output="$(get_decision_on_branch_with_pr 'local-branch' 'remote-branch' "${json}")"
  local -r expected="$(
    cat <<'EOF'
delete:local-branch:local-branch->remote-branch had a pr that completed:[{"state": "merged", "id": 11111 }]
EOF
  )"
  assert_output "${expected}"
}

@test "get_decision_on_branch_with_pr_gitlab_opened" {
  . "${ROOT_DIR}/lib/platforms/gitlab.sh"
  . "${ROOT_DIR}/lib/git-cleanup-merged-pr-branches"
  local -r json='[{"state": "opened", "id": 11111 }]'
  output="$(get_decision_on_branch_with_pr 'local-branch' 'remote-branch' "${json}")"

  local -r expected=$'skip:local-branch:local-branch->remote-branch has open pr\'s, not deleting:[{"state": "opened", "id": 11111 }]'
  assert_output "${expected}"
}

@test "get_decision_on_branch_without_pr_gitlab" {
  . "${ROOT_DIR}/lib/git-cleanup-merged-pr-branches"
  local -r json="$(
    cat <<'EOF'
[]
EOF
  )"
  output="$(get_decision_on_branch_without_pr 'local-branch' 'remote-branch' "${json}")"
  local -r expected='skip:local-branch:local-branch->remote-branch never had a pr, not deleting:[]'
  assert_output "${expected}"
}

@test "get_decision_on_branch_without_pr_gitlab_deleted_remotely" {
  . "${ROOT_DIR}/lib/git-cleanup-merged-pr-branches"
  branch_was_deleted_remotely() {
    printf 'true'
  }
  local -r json="$(
    cat <<'EOF'
[]
EOF
  )"
  output="$(get_decision_on_branch_without_pr 'local-branch' 'remote-branch' "${json}")"
  local -r expected='warning_deleted_on_remote:local-branch:local-branch->remote-branch never had a pr, but was deleted on remote:[]'
  assert_output "${expected}"
}
