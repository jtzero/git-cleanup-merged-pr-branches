
# Installation
  1. `git clone git@gitlab.com:jtzero/git-cleanup-merged-prs.git`
  1. `mkdir "${HOME}/.git-hooks"`
  1. `git config --global core.hooksPath "${HOME}/.git-hooks"`
  1. `ln -nfs "${PWD}/git-cleanup-merged-prs-git-hook" "${HOME}/.git-hooks/post-checkout"`

# Usage as post-checkout hook with first time log in
  ![first time use](./web/first-time.gif)

# Usage Info
  `bin/git-cleanup-merged-prs-git-hook help` OR `bin/git-cleanup-merged-prs help`

# API's supported
 - Github
 - GitLab
 - Azure
