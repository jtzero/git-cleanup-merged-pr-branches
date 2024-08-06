#!/usr/bin/env bats

setup() {
  bats_load_library 'test_helper/bats-support' # this is required by bats-assert!
  bats_load_library 'test_helper/bats-assert'
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  ROOT_DIR="$(dirname "${BATS_TEST_LIB}")"
}

@test "local -r is read only" {

  run bash -c '
  reassign() {
    local -r my_test_var="asdf"
    my_test_var="my_new_value"
  }
  reassign
'
  assert_failure
  assert_output --regexp "environment: line [0-9]: my_test_var: readonly variable"
}

@test "readonly is read only" {

  run bash -c '
  reassign() {
    local my_test_var="asdf"
    readonly my_test_var
    my_test_var="my_new_value"
  }
  reassign
'
  assert_failure
  assert_output --regexp "environment: line [0-9]: my_test_var: readonly variable"
}

@test "local is local" {

  run bash -c '
  init() {
    local -r my_test_var='qwer'
  }
  reassign() {
    printf '%s' "${my_test_var}"
  }
  init
  reassign
'
  assert_success
  assert_output ""
}

@test "local readonly is not readonly" {

  run bash -c '
  init() {
    local readonly my_test_var='qwer'
    my_test_var="asdf"
  }
  init
'
  assert_success
  assert_output ""
}

@test "string interpolated number will still work against a -gt" {
  run bash -c '
    [ "1" -gt 0 ] || exit 1
  '
  assert_success
}
