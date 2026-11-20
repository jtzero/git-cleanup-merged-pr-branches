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

detect_host_architecture() {
  local arch
  arch="$(uname -m)"
  case "${arch}" in
  x86_64 | amd64) echo "amd64" ;;
  aarch64 | arm64) echo "arm64" ;;
  armv7l | armv6l) echo "arm" ;;
  *) echo "amd64" ;;
  esac
}

HOST_ARCH="$(detect_host_architecture)"

EXTRA_ARGS=""

PUSH="${PUSH:-"true"}"

if [ "${PUSH}" = "true" ]; then
  if [ -z "${CI_REGISTRY_USER:-}" ]; then
    docker login registry.gitlab.com
  else
    docker() {
      podman "$@"
    }
    export -f docker
    EXTRA_ARGS="--format docker "
    docker login -u "${CI_REGISTRY_USER}" -p "${CI_REGISTRY_PASSWORD}" registry.gitlab.com
  fi
fi

EXISTING_SHA="$(docker images --no-trunc --quiet gcmpb-build | cut -d ':' -f2-)"

docker image build ${EXTRA_ARGS}-t gcmpb-build --build-arg HOST_ARCH="${HOST_ARCH}" -f "${ROOT_DIR}/tests/Dockerfile" .

if [ "${PUSH}" = "true" ]; then
  NEW_SHA="$(docker images --no-trunc --quiet gcmpb-build | cut -d ':' -f2-)"
  if [ "${EXISTING_SHA}" = "${NEW_SHA}" ]; then
    LAST_EPOCH="$(docker inspect --format='{{json .RepoTags}}' gcmpb-build:latest | jq --raw-output '.[]' | cut -d ':' -f2 | sort | head -n 1)"
    docker push registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:latest
    docker push "registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:${LAST_EPOCH}"
  else
    docker tag gcmpb-build "registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:${EPOCH}"
    docker tag gcmpb-build registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:latest
    docker push registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:latest
    docker push "registry.gitlab.com/jtzero/git-cleanup-merged-pr-branches/gcmpb-build:${EPOCH}"
  fi
fi
