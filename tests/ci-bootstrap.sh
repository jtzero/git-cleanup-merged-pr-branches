#!/usr/bin/env bash

printerr() { printf "\033[0;31m%s\033[0m\n" "$*" >&2; }

apt-get update -y && apt-get install -y curl gpg
curl -q 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
echo "deb [signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr bullseye" | tee /etc/apt/sources.list.d/prebuilt-mpr.list
apt-get update -y && apt-get install -y gettext tree gcc unzip make autoconf ssh libz-dev xz-utils
git clone https://github.com/asdf-vm/asdf.git "${PWD}/.asdf" --branch v0.10.2 || true
ln -nfs "${PWD}/.asdf" "${HOME}/.asdf"
# shellcheck disable=SC1091
. "${PWD}/.asdf/asdf.sh"

system_version_git="$(git --version | cut -d' ' -f3)"
tool_versions_git="$(grep 'git' "${PWD}/.tool-versions" | cut -d' ' -f2)"
largest_git_version="$(printf "%s\n%s" "${tool_versions_git}" "${system_version_git}" | sort -V | tail -n 1)"

set -x
if [[ "${tool_versions_git}" = "${system_version_git}" ]] || [[ "${tool_versions_git}" != "${largest_git_version}" ]]; then
  printf "skipping git install"
  cut -d' ' -f1 .tool-versions | grep -v "^#" | grep -v 'git' | xargs -I{} asdf plugin add {}
  cut -d' ' -f1 .tool-versions | grep -v "^#" | grep -v 'git' | xargs -I{} asdf install {}
else
  cut -d' ' -f1 .tool-versions | grep -v "^#" | xargs -I{} asdf plugin add {}
  cut -d' ' -f1 .tool-versions | grep -v "^#" | xargs -I{} asdf install {}
fi

asdf reshim
git config --global core.pager ""

# TODO convert the above into a DOCKERFILE
git config --global --add safe.directory "${PWD}"

git remote rename origin ci
git branch -a
if [ "${VCS}" = "gitlab" ]; then
  git remote add origin "https://CI:${GCMPB_GL_TOKEN}@gitlab.com/jtzero/git-cleanup-merged-pr-branches.git"
  apt-get install -y glab
elif [ "${VCS}" = "github" ]; then
  mkdir -p "${HOME}/.ssh"
  ssh-keyscan -H github.com >> "${HOME}/.ssh/known_hosts"
  cp "${GITHUB_DEPLOY_KEY}" "${HOME}/.ssh/github"
  chmod 400 "${HOME}/.ssh/github"
  touch "${HOME}/.ssh/config"
cat <<-'EOF' >> "${HOME}/.ssh/config"
  Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github
EOF
  git remote add origin "git@github.com:jtzero/git-cleanup-merged-pr-branches.git"
  type -p curl >/dev/null || apt install curl -y
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt update && apt install gh -y
else
  printerr "Unknown VCS:'${VCS}'"
fi
git remote -v
git fetch --all
git branch -u "origin/$(git branch --show-current)"
mkdir ../hooks
mkdir -p .git/hooks
UP_DIR="$(dirname "${PWD}")"
INSTALL_DIR="${UP_DIR}/gcmpb"
mkdir -p "${INSTALL_DIR}"
cp -r ./* "${INSTALL_DIR}/"
ln -nfs "${INSTALL_DIR}/bin/git-cleanup-merged-pr-branches-git-hook" ./.git/hooks/post-checkout
branch_to_be_deleted="integration-test"
git branch -D "${branch_to_be_deleted}"
git checkout --track "origin/${branch_to_be_deleted}"
tree "${INSTALL_DIR}"
git remote -v
GCMPB_AUTO_APPLY=true GCMPB_DEBUG=true git checkout - 2>&1 | tee /tmp/result
result="$(cat /tmp/result)"
if [[ "${result}" == *"Deleted branch integration-test"* ]]; then
  printf "%s\n" "success!"
else
  printerr "Checkout did not ask to delete the branch ${result}"
  exit 2
fi
