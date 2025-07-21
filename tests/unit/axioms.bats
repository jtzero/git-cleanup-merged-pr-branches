#!/usr/bin/env bats

setup() {
  bats_load_library 'test_helper/bats-support' # this is required by bats-assert!
  bats_load_library 'test_helper/bats-assert'
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  _ROOT_DIR="$(dirname "${BATS_TEST_LIB}")"
}

@test "'local -r' is not local in bash < 5.1 and tested on 5.0.3 and 5.1.16" {

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
  printf '%s\n' "Bash version:${major}.${minor}.${patch}"
  if [ "${major}" -lt 5 ]; then
    assert_failure
  elif [ "${major}" -eq 5 ] && [ "${minor}" -lt 1 ]; then
    assert_failure
  else
    assert_success
  fi
}
