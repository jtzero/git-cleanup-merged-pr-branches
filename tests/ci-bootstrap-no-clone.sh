#!/usr/bin/env bash

PROJECT_DIR="${1}"

printerr() { printf "\033[0;31m%s\033[0m\n" "$*" >&2; }

set_up_asdf() {
  local gitlab_ci_init_dir="${1}"
  local testing_repo_dir="${2}"
  local system_version_git="$(git --version | cut -d' ' -f3)"
  git clone https://github.com/asdf-vm/asdf.git "${gitlab_ci_init_dir}/.asdf" --branch v0.10.2 || true
  ln -nfs "${gitlab_ci_init_dir}/.asdf" "${HOME}/.asdf"
  # shellcheck disable=SC1091
  . "${gitlab_ci_init_dir}/.asdf/asdf.sh"
  local tool_versions_git="$(grep 'git' "${testing_repo_dir}/.tool-versions" | cut -d' ' -f2)"
  local largest_git_version="$(printf "%s\n%s" "${tool_versions_git}" "${system_version_git}" | sort -V | tail -n 1)"

  if [[ "${tool_versions_git}" = "${system_version_git}" ]] || [[ "${tool_versions_git}" != "${largest_git_version}" ]]; then
    printf "skipping git install"
    cut -d' ' -f1 .tool-versions | grep -v "^#" | grep -v 'git' | xargs -I{} asdf plugin add {}
    cut -d' ' -f1 .tool-versions | grep -v "^#" | grep -v 'git' | xargs -I{} asdf install {}
  else
    cut -d' ' -f1 .tool-versions | grep -v "^#" | xargs -I{} asdf plugin add {}
    cut -d' ' -f1 .tool-versions | grep -v "^#" | xargs -I{} asdf install {}
    asdf global git "${tool_versions_git}"
  fi

  asdf reshim
}

standardize_git_repo() {
  cwd="${1}"
  git config --global core.pager ""

  git config --global --add safe.directory "${cwd}"

  # change existing remote to prevent unexpected side-effects
  git remote rename origin ci

  mkdir -p tmp
}

set_up_gitlab() {
  apt-get update -y && apt-get install -y curl gpg
  curl -q 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
  echo "deb [signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr bullseye" | tee /etc/apt/sources.list.d/prebuilt-mpr.list
  apt-get install -y glab
}

set_up_github() {
  local home_dir="${1}"
  local deploy_key_path="${2}"
  mkdir -p "${home_dir}/.ssh"
  ssh-keyscan -H github.com >>"${home_dir}/.ssh/known_hosts"
  cp "${deploy_key_path}" "${home_dir}/.ssh/github"
  chmod 400 "${home_dir}/.ssh/github"
  touch "${home_dir}/.ssh/config"
  cat <<-'EOF' >>"${home_dir}/.ssh/config"
  Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github
EOF
  git remote add origin "git@github.com:jtzero/git-cleanup-merged-pr-branches.git"
  type -p curl >/dev/null || apt install curl -y
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
    apt update && apt install gh -y
}

print_debug() {
  local -r filepath="${1}"
  printf '\n=======DEBUG\n%s' "$(<"${filepath}")"
}

debug_output="${PROJECT_DIR}/tmp/set-output.log"

trap 'print_debug "${debug_output}"' EXIT

mkdir -p "${PROJECT_DIR}/tmp"
exec   > >(tee -ia "${debug_output}")
exec  2> >(tee -ia "${debug_output}" >& 2)
exec 7>>"${debug_output}"
export BASH_XTRACEFD=7
set -x

printf '\n=======SETUP\n'
cd "${PROJECT_DIR}" || exit 1
apt-get update -y && apt-get install -y gettext tree gcc unzip make autoconf ssh libz-dev xz-utils

git clone "https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/jtzero/git-cleanup-merged-pr-branches.git" "testing-scenario" --branch "stable"

set_up_asdf "${PROJECT_DIR}" "${PROJECT_DIR}/testing-scenario"

if [ "${VCS}" = "gitlab" ]; then
  set_up_gitlab
elif [ "${VCS}" = "github" ]; then
  set_up_github "${HOME}" "${GITHUB_DEPLOY_KEY}"
else
  printerr "Unknown VCS:'${VCS}'"
fi
#DEBUG
git remote -v

cd testing-scenario || exit 1

git fetch --all

standardize_git_repo "${PWD}"

printf '\n=======START\n'

# this will create the login as the hook is already set up
GCMPB_AUTO_APPLY=true GCMPB_DEBUG=true git checkout --track "origin/integration-test"
tree "${cwd}"
GCMPB_AUTO_APPLY=true GCMPB_DEBUG=true git checkout - 2>&1 | tee /tmp/result || true
set +x
result="$(</tmp/result)"
if [[ "${result}" == *"Deleted branch integration-test"* ]]; then
  printf "%s\n" "success!"
else
  printerr "Checkout did not ask to delete the branch ${result}"
  exit 2
fi
