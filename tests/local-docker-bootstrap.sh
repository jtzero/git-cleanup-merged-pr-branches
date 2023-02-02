#!/usr/bin/env bash

set -Eeuo pipefail

if [ -z "${BASH_SOURCE[0]:-}" ]; then
  # zsh
  GCMPB_TESTS_DIR="${0:A:h}"
else
  GCMPB_TESTS_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
fi

GCMPB_ROOT_DIR="$(dirname "${GCMPB_TESTS_DIR}")"
GCMPB_UP_DIR="$(dirname "${GCMPB_ROOT_DIR}")"

cd "${GCMPB_UP_DIR}" || exit 1
cp -r "${GCMPB_ROOT_DIR}" ./testing-dir
cd testing-dir || exit 1

git remote | xargs -n1 git remote remove

# TODO why doesn't this use the public ?
git remote add origin \
  "https://local-testing:$(cat "${PWD}/tmp/LOCAL_TESTING_DEPLOY_TOKEN")@gitlab.com/jtzero/git-cleanup-merged-pr-branches.git"

git remote add azure \
  "https://jtzero@dev.azure.com/jtzero/git-cleanup-merged-pr-branches/_git/git-cleanup-merged-pr-branches"

git remote add github \
  "https://github.com/jtzero/git-cleanup-merged-pr-branches.git"

bash "${PWD}/tests/ci-bootstrap.sh"
