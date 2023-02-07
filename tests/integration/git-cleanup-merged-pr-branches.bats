#!/usr/bin/env bats

setup() {
  bats_load_library 'test_helper/bats-support' # this is required by bats-assert!
  bats_load_library 'test_helper/bats-assert'
  ROOT_DIR="$(dirname "${BATS_TEST_LIB}")"
  PATH="${ROOT_DIR}/bin:$PATH"
}

@test "print help" {
  run git-cleanup-merged-pr-branches 'help'
  [ "$status" -eq 0 ]
}
