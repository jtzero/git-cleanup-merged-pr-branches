#!/usr/bin/env bats

setup() {
  bats_load_library 'test_helper/bats-support' # this is required by bats-assert!
  bats_load_library 'test_helper/bats-assert'
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  ROOT_DIR="$(dirname "${BATS_TEST_LIB}")"
  . "${ROOT_DIR}/lib/platforms/gitlab.sh"
}

@test "get_cache_config" {
  . "${ROOT_DIR}/lib/platforms/gitlab.sh"
  local -r remote='origin'
  local -r fixture_file="${DIR}/fixtures/info/cleanup-az-cache-${remote}"
  printf '%s' 'zxcv=qwer' >"${fixture_file}"
  git() {
    printf '%s' "${DIR}/fixtures"
  }
  get_cache_config "${remote}"
  assert [ "${zxcv}" = 'qwer' ]
}
