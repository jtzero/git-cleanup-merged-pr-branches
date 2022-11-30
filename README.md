
# Installation
  1. `mkdir "${HOME}/.git-hooks"`
  2. `git config --global core.hooksPath "${HOME}/.git-hooks"`
  3. `ln -nfs "${PWD}/git-cleanup-merged-prs" "${HOME}/.git-hooks/post-checkout"`
