#!/usr/bin/env bash

printerr() { printf "\033[0;31m%s\033[0m\n" "$*" >&2; }


set_up_asdf() {
  local cwd="${1}"
  git clone https://github.com/asdf-vm/asdf.git "${cwd}/.asdf" --branch v0.10.2 || true
  ln -nfs "${cwd}/.asdf" "${HOME}/.asdf"
  # shellcheck disable=SC1091
  . "${cwd}/.asdf/asdf.sh"
  system_version_git="$(git --version | cut -d' ' -f3)"
  tool_versions_git="$(grep 'git' "${cwd}/.tool-versions" | cut -d' ' -f2)"
  largest_git_version="$(printf "%s\n%s" "${tool_versions_git}" "${system_version_git}" | sort -V | tail -n 1)"

  if [[ "${tool_versions_git}" = "${system_version_git}" ]] || [[ "${tool_versions_git}" != "${largest_git_version}" ]]; then
    printf "skipping git install"
    cut -d' ' -f1 .tool-versions | grep -v "^#" | grep -v 'git' | xargs -I{} asdf plugin add {}
    cut -d' ' -f1 .tool-versions | grep -v "^#" | grep -v 'git' | xargs -I{} asdf install {}
  else
    cut -d' ' -f1 .tool-versions | grep -v "^#" | xargs -I{} asdf plugin add {}
    cut -d' ' -f1 .tool-versions | grep -v "^#" | xargs -I{} asdf install {}
  fi

  asdf reshim
}

standardize_git_repo() {
  cwd="${1}"
  git config --global core.pager ""

  git config --global --add safe.directory "${cwd}"

  # change existing remote to prevent unexpected side-effects
  git remote rename origin ci

  mkdir -p "${cwd}/tmp"
}

set_up_gitlab() {
  git remote add origin "https://CI:${GCMPB_GL_TOKEN}@gitlab.com/jtzero/git-cleanup-merged-pr-branches.git"
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
}

set_up_azure() {
  local home_dir="${1}"
  curl -sL https://aka.ms/InstallAzureCLIDeb | bash
  az extension add --name azure-devops
  ssh-keyscan -H ssh.dev.azure.com >>"${home_dir}/.ssh/known_hosts"
  ssh-keyscan -t rsa -H ssh.dev.azure.com >>"${home_dir}/.ssh/known_hosts"
  git remote add origin "https://jtzero:${AZURE_DEVOPS_EXT_PAT}@dev.azure.com/jtzero/git-cleanup-merged-pr-branches/_git/git-cleanup-merged-pr-branches"
}

set_up_hook() {
  local -r cwd="${1}"
  mkdir ../hooks
  mkdir -p .git/hooks
  local -r up_dir="$(dirname "${cwd}")"
  local -r install_dir="${up_dir}/gcmpb"
  mkdir -p "${install_dir}"
  cp -r ./* "${install_dir}/"
  ln -nfs "${install_dir}/bin/git-cleanup-merged-pr-branches-git-hook" ./.git/hooks/post-checkout
}

prepare_testing_branch() {
  local branch_to_be_deleted="${1}"
  local cwd="${2}"
  git branch -D "${branch_to_be_deleted}" || true
  # this will create the login as the hook is already set up
  git checkout --track "origin/${branch_to_be_deleted}"
  tree "${cwd}"
}

printf '\n=======SETUP\n'

ROOT_DIR="${PWD}"

set_up_asdf "${ROOT_DIR}"

standardize_git_repo "${ROOT_DIR}"

exec 7>"${ROOT_DIR}/tmp/set-output.log"
export BASH_XTRACEFD=7
set -x

#DEBUG
git branch -a

if [ "${VCS}" = "gitlab" ]; then
  set_up_gitlab
elif [ "${VCS}" = "github" ]; then
  set_up_github "${HOME}" "${GITHUB_DEPLOY_KEY}"
elif [ "${VCS}" = "azure" ]; then
  set_up_azure "${HOME}"
else
  printerr "Unknown VCS:'${VCS}'"
fi
#DEBUG
git remote -v
git fetch --all

set_up_hook "${ROOT_DIR}"
prepare_testing_branch "integration-test" "${ROOT_DIR}"

printf '\n=======START\n'
printf 'currently on:\n%s' "$(git branch -vv)"
GCMPB_AUTO_APPLY=true GCMPB_DEBUG=true git checkout - 2>&1 | tee /tmp/result || true
set +x
result="$(</tmp/result)"
printf '\n=======DEBUG\n%s' "$(<tmp/set-output.log)"
if [[ "${result}" == *"Deleted branch integration-test"* ]]; then
  printf "%s\n" "success!"
else
  printerr "Checkout did not ask to delete the branch ${result}"
  exit 2
fi
