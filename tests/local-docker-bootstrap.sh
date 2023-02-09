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

printerr() { printf "\033[0;31m%s\033[0m\n" "$*" >&2; }

cd "${GCMPB_UP_DIR}" || exit 1
cp -r "${GCMPB_ROOT_DIR}" ./testing-dir
cd testing-dir || exit 1

git remote | xargs -n1 git remote remove

# TODO why doesn't this use the public ?
if [ "${VCS}" = 'gitlab' ]; then
  git remote add origin \
    "https://local-testing:$(cat "${PWD}/tmp/LOCAL_TESTING_DEPLOY_TOKEN")@gitlab.com/jtzero/git-cleanup-merged-pr-branches.git"
elif [ "${VCS}" = 'azure' ]; then
  git remote add origin \
    "https://jtzero@dev.azure.com/jtzero/git-cleanup-merged-pr-branches/_git/git-cleanup-merged-pr-branches"
elif [ "${VCS}" = 'github' ]; then
  git remote add origin \
    "https://github.com/jtzero/git-cleanup-merged-pr-branches.git"
else
  printerr "Invalid VCS: \`${VCS}'"
  exit 1
fi

bash "${PWD}/tests/ci-bootstrap.sh"
