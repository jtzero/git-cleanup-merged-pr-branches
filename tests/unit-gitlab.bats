#!/usr/bin/env bats

setup() {
  load 'test_helper/bats-support/load' # this is required by bats-assert!
  load 'test_helper/bats-assert/load'
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  ROOT_DIR="$(dirname "${DIR}")"
  . "${ROOT_DIR}/lib/git-cleanup-merged-pr-branches"
}

@test "get_decision_on_branch_with_pr_gitlab_merged" {
  . "${ROOT_DIR}/lib/platforms/gitlab.sh"
  local -r json="$(cat<<'EOF'
[{"state": "merged", "id": 11111 }]
EOF
)"
  output="$(get_decision_on_branch_with_pr 'local-branch' 'remote-branch' "${json}")"
  local -r expected="$(cat<<'EOF'
delete:local-branch:local-branch->remote-branch had a pr that completed:[{"state": "merged", "id": 11111 }]
EOF
)"
   assert_output "${expected}"
}

@test "get_decision_on_branch_with_pr_gitlab_opened" {
  . "${ROOT_DIR}/lib/platforms/gitlab.sh"
  local -r json="$(cat<<'EOF'
[{"state": "opened", "id": 11111 }]
EOF
)"
  output="$(get_decision_on_branch_with_pr 'local-branch' 'remote-branch' "${json}")"
  local -r expected="$(cat<<'EOF'
skip:local-branch:local-branch->remote-branch has open pr's, not deleting:[{"state": "opened", "id": 11111 }]
EOF
)"
   assert_output "${expected}"
}

@test "get_decision_on_branch_without_pr_gitlab" {
  . "${ROOT_DIR}/lib/platforms/gitlab.sh"
  local -r json="$(cat<<'EOF'
[]
EOF
)"
  output="$(get_decision_on_branch_without_pr 'local-branch' 'remote-branch' "${json}")"
  local -r expected="$(cat<<'EOF'
skip:local-branch:local-branch->remote-branch never had a pr, not deleting:
EOF
)"
   assert_output "${expected}"
}

@test "get_decision_on_branch_without_pr_gitlab_deleted_remotely" {
  branch_was_deleted_remotely() {
    printf 'true'
  }
  local -r json="$(cat<<'EOF'
[]
EOF
)"
  output="$(get_decision_on_branch_without_pr 'local-branch' 'remote-branch' "${json}")"
  local -r expected="$(cat<<'EOF'
warning_deleted_on_remote:local-branch:local-branch->remote-branch never had a pr, but was deleted on remote:
EOF
)"
   assert_output "${expected}"
}
