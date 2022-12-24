#!/usr/bin/env bash

echoerr() { printf "\033[0;31m%s\033[0m\n" "$*" >&2; }

curl -q 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
echo "deb [signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr bullseye" | tee /etc/apt/sources.list.d/prebuilt-mpr.list
apt-get update -y && apt-get install -y gettext glab
git clone https://github.com/asdf-vm/asdf.git .asdf --branch v0.10.2 || true
ln -nfs "${PWD}/.asdf" "${HOME}/.asdf"
. "${HOME}/.asdf/asdf.sh"
cat .tool-versions | cut -d' ' -f1 | grep "^[^\#]" | xargs -i asdf plugin add {}
asdf install
set -x
git remote rename origin ci
git branch -a
git remote add origin "https://CI:${GCMPB_TOKEN}@gitlab.com/jtzero/git-cleanup-merged-pr-branches.git"
git fetch --all
mkdir ../hooks
mkdir -p .git/hooks
UP_DIR="$(dirname "${PWD}")"
INSTALL_DIR="${UP_DIR}/gcmpb"
mkdir -p "${INSTALL_DIR}"
cp -r ./* "${INSTALL_DIR}/"
ln -nfs "${INSTALL_DIR}/bin/git-cleanup-merged-pr-branches-git-hook" ./.git/hooks/post-checkout
branch_to_be_deleted="integration-test"
git checkout --track "origin/${branch_to_be_deleted}"
tree "${INSTALL_DIR}"
git remote -v
result="$(GCMPB_AUTO_APPLY=true GCMPB_DEBUG=true git checkout - 2>&1)"
if [[ "${result}" == *"Deleted branch integration-test"* ]]; then
  printf "%s\n" "success!"
else
  echoerr "Checkout did not ask to delete the branch ${result}"
  exit 2
fi
