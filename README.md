
# Installation
  ## Dependencies
  One or more CLI's that correspond to the server you are using:
  - https://gitlab.com/gitlab-org/cli
  - https://cli.github.com/
  - https://learn.microsoft.com/en-us/cli/azure/install-azure-cli & `az extension add --name azure-devops`
  ## Steps
  1. `git clone git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git`
  1. `mkdir "${HOME}/.git-hooks"`
  1. `git config --global core.hooksPath "${HOME}/.git-hooks"`
  1. `ln -nfs "${PWD}/git-cleanup-merged-pr-branches-git-hook" "${HOME}/.git-hooks/post-checkout"`

# Usage as post-checkout hook with first time log in
  ![first time use](./web/first-time.gif)

# Usage Info
  `bin/git-cleanup-merged-pr-branches-git-hook help` OR `bin/git-cleanup-merged-pr-branches help`

# API's supported
 - Github
 - GitLab
 - Azure
