#!/usr/bin/env bash

printerr() { printf "\033[0;31m%s\033[0m\n" "$*" >&2; }

add_gh_apt_source() {
  apt-get update -y && apt-get install -y curl gpg
  curl -q 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
  echo "deb [signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr bullseye" | tee /etc/apt/sources.list.d/prebuilt-mpr.list
}

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

  mkdir -p tmp
}

set_up_gitlab() {
  git remote add origin "https://CI:${GCMPB_GL_TOKEN}@gitlab.com/jtzero/git-cleanup-merged-pr-branches.git"
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

set_up_hook() {
  local -r cwd="${1}"
  mkdir ../hooks
  mkdir -p .git/hooks
  local up_dir="$(dirname "${cwd}")"
  local install_dir="${up_dir}/gcmpb"
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
add_gh_apt_source
apt-get update -y && apt-get install -y gettext tree gcc unzip make autoconf ssh libz-dev xz-utils

set_up_asdf "${PWD}"

standardize_git_repo "${PWD}"

exec 7>tmp/set-output.log
export BASH_XTRACEFD=7
set -x


#DEBUG
git branch -a

if [ "${VCS}" = "gitlab" ]; then
  set_up_gitlab
elif [ "${VCS}" = "github" ]; then
  set_up_github "${HOME}" "${GITHUB_DEPLOY_KEY}"
else
  printerr "Unknown VCS:'${VCS}'"
fi
#DEBUG
git remote -v
git fetch --all

set_up_hook "${PWD}"
prepare_testing_branch "integration-test" "${PWD}"

printf '\n=======START\n'
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
