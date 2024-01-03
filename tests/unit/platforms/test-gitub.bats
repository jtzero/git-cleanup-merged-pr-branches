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
