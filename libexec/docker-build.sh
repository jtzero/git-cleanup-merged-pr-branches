#!/usr/bin/env bash

set -Eeuo

if [ -z "${BASH_SOURCE[0]:-}" ]; then
  # zsh
  LIBEXEC_DIR="${0:A:h}"
else
  LIBEXEC_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
fi

ROOT_DIR="$(dirname "${LIBEXEC_DIR}")"

EPOCH="$(date +%s)"

EXISTING_SHA="$(docker images --no-trunc --quiet gcmpb-build | cut -d ':' -f2-)"

docker login registry.gitlab.com
set -x
docker image build -t gcmpb-build "${ROOT_DIR}/tests/"
NEW_SHA="$(docker images --no-trunc --quiet gcmpb-build | cut -d ':' -f2-)"
if [ "${EXISTING_SHA}" = "${NEW_SHA}" ]; then
  LAST_EPOCH="$(docker inspect --format='{{json .RepoTags}}' gcmpb-build:latest | jq --raw-output  '.[]' | cut -d ':' -f2 | sort | head -n 1)"
  docker push registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:latest
  docker push "registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:${LAST_EPOCH}"
else
  docker tag gcmpb-build "registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:${EPOCH}"
  docker tag gcmpb-build registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:latest
  docker push registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:latest
  docker push "registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:${EPOCH}"
fi
set +x
