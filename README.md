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


  ## Install as only post-checkout git hook
  ### Steps  
  1. clone repo and set up git hooks and set gcmpb as the post-checkout hook
      ```bash
      git clone git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git "${XDG_DATA_HOME:-${HOME}/.local/share}/git-cleanup-merged-pr-branches" --branch stable \
      && mkdir "${HOME}/.git-hooks" \
      && git config --global core.hooksPath "${HOME}/.git-hooks" \
      && ln -nfs "${XDG_DATA_HOME:-${HOME}/.local/share}/git-cleanup-merged-pr-branches/bin/git-cleanup-merged-pr-branches-git-hook" "${HOME}/.git-hooks/post-checkout"
      ```

  ## Install as extendable post-checkout hook
  ### Steps
  1. ensure `git-cleanup-merged-pr-branches-git-hook` is in your PATH varaible
  1. clone repo and set up git hooks
      ```bash
      git clone git@gitlab.com:jtzero/git-cleanup-merged-pr-branches.git "${XDG_DATA_HOME:-${HOME}/.local/share}/git-cleanup-merged-pr-branches" --branch stable \
      && mkdir "${HOME}/.git-hooks" \
      && git config --global core.hooksPath "${HOME}/.git-hooks"
      ```
  1. copy the templates/custom-post-checkout-hook and past it into ~/.git-hooks/post-checkout
  1. `chmod +x ~/.git-hooks/post-checkout`
  1. modify below `# other things`

# Usage as post-checkout hook with first time log in
- The first time you use the hook it will ask you to log in to the respective VCS server.
- Then once you have switched branches, if any branches have a PR that has been merged or closed, the tui will ask you if you want to delete it.

[![asciicast](https://asciinema.org/a/629452.svg)](https://asciinema.org/a/629452)

# Usage Info
  `bin/git-cleanup-merged-pr-branches-git-hook help` OR `bin/git-cleanup-merged-pr-branches help`

# API's supported
 - Github
 - GitLab
 - Azure
