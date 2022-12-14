

# GCMPB <sub><sup><sub>git-cleanup-merged-pr-branches</sub></sup></sub>
![broom](./web/broom-logo-wide.jpg)

[![pipeline status](https://gitlab.com/jtzero/git-cleanup-merged-pr-branches/badges/main/pipeline.svg)](https://gitlab.com/jtzero/git-cleanup-merged-pr-branches/pipelines?scope=all&page=1&ref=main)
---

# Installation
  ## Dependencies
  1. One or more CLI's that correspond to the server you are using:
      - https://gitlab.com/gitlab-org/cli
      - https://cli.github.com/
      - https://learn.microsoft.com/en-us/cli/azure/install-azure-cli & `az extension add --name azure-devops`
  1. gnu-coreutils >= 8.32
  1. git >= 2.22.0
  1. jq ~> 1.6
  - [additional-info](./DEPENDENCIES.md)

  ## Steps
  ```bash
  git clone git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git "${HOME}/.local/git-cleanup-merged-pr-branches" --branch stable \
  && mkdir "${HOME}/.git-hooks" \
  && git config --global core.hooksPath "${HOME}/.git-hooks" \
  && ln -nfs "${HOME}/.local/git-cleanup-merged-pr-branches/bin/git-cleanup-merged-pr-branches-git-hook" "${HOME}/.git-hooks/post-checkout"
  ```

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
