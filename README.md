
# Installation
  ## Dependencies
  1. One or more CLI's that correspond to the server you are using:
    - https://gitlab.com/gitlab-org/cli
    - https://cli.github.com/
    - https://learn.microsoft.com/en-us/cli/azure/install-azure-cli & `az extension add --name azure-devops`
  1. realpath version ~> 9.0
  1. git >= 2.22.0
  1. jq ~> 1.6
  ## Steps
  1. `git clone git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git "${HOME}/.local/git-cleanup-merged-pr-branches"`
  1. `mkdir "${HOME}/.git-hooks"`
  1. `git config --global core.hooksPath "${HOME}/.git-hooks"`
  1. `ln -nfs "${HOME}/.local/git-cleanup-merged-pr-branches/bin/git-cleanup-merged-pr-branches-git-hook" "${HOME}/.git-hooks/post-checkout"`

# Usage as post-checkout hook with first time log in
- The first time you use the hook it will ask you to log in to the respective VCS server.
- Then once you have switched branches, if any branches have a PR that has been merged or closed, the tui will ask you if you want to delete it.

![first time use](./web/first-time.gif)

# Usage Info
  `bin/git-cleanup-merged-pr-branches-git-hook help` OR `bin/git-cleanup-merged-pr-branches help`

# API's supported
 - Github
 - GitLab
 - Azure
