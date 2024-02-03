#!/usr/bin/env bats

setup() {
  bats_load_library 'test_helper/bats-support' # this is required by bats-assert!
  bats_load_library 'test_helper/bats-assert'
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  ROOT_DIR="$(dirname "${BATS_TEST_LIB}")"
  . "${ROOT_DIR}/lib/platforms/github.sh"
}

@test "exits if get_states errors" {
  gh() {
    exit 12
  }
  run get_states 'origin/user/repo'
  unset -f gh
  assert_failure 12
}

@test "gh_auth_status sets GH_AUTH_LOGGED_IN_STATE to true if any users have logged in with gh" {
  gh() {
    exit 0
  }
  assert_equal "${GH_AUTH_LOGGED_IN_STATE}" 'not_logged_in'
  gh_auth_status
  unset -f gh
  assert_equal "${GH_AUTH_LOGGED_IN_STATE}" 'logged_in'
}

@test "user_has_pr_access sets GH_USER_HAS_PR_ACCESS to true if user has pr view access" {
  gh() {
    exit 0
  }
  assert_equal "${GH_USER_HAS_PR_ACCESS}" 'false'
  user_has_pr_access
  unset -f gh
  assert_equal "${GH_USER_HAS_PR_ACCESS}" 'true'
}
