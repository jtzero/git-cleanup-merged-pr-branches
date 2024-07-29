#!/usr/bin/env bats

setup() {
  bats_load_library 'test_helper/bats-support' # this is required by bats-assert!
  bats_load_library 'test_helper/bats-assert'
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  _ROOT_DIR="$(dirname "${BATS_TEST_LIB}")"
}


@test "this fails in bash < 5.2 and tested on 5.0.3" {

  run bash -c '
  run() {
    local -r my_test_var=("qwer" "zxcv")
    reassign "${my_test_var}"
  }
  reassign() {
    local -r my_test_var=("${@:2}")
  }
  run
'
  IFS=. read -r major minor patch <<EOF
$BASH_VERSION
EOF
  if [ "${major}" -le 5 ]; then
    assert_failure
  elif [ "${major}" -eq 5 ] && [ "${minor}" -lt 2 ]; then
    assert_failure
  else
    assert_success
  fi
}
