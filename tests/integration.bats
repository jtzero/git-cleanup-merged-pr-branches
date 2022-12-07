#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  PATH="$DIR/../bin:$PATH"
}

@test "print help" {
  git-cleanup-merged-prs 'help'
}
