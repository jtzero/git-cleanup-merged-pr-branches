# Non-comprehensive Instructions to installing dependencies

## https://gitlab.com/gitlab-org/cli
  - asdf: `asdf plugin add glab && asdf install glab latest`
  - mac: `brew install glab`
  - Ubuntu/Debian:
      - ```bash
        apt-get update -y && apt-get install -y curl gpg
        curl -q 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
        echo "deb [signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr bullseye" | tee /etc/apt/sources.list.d/prebuilt-mpr.list
        ```
## https://cli.github.com/
  - asdf: plugin is outdated
  - mac: `brew install gh`
  - Ubuntu/Debian:
      - ```bash
        type -p curl >/dev/null || sudo apt install curl -y
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
        && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update \
        && sudo apt install gh -y
        ```
## https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
  - post-install: `az extension add --name azure-devops`
  - asdf: plugin is outdated
  - mac: `brew install azure-cli`
  - Ubuntu/Debian:
      `curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`

## GNU coreutils >= 8.32
  - mac:
    - command: `brew install coreutils`
    - info: this will install the utils as `gcut` and `grealpath` respectively,
            however adding `export PATH="$(brew --prefix coreutils)/libexec/gnubin:${PATH}"`
            to the repscetive .bashrc or .zshrc will put the gnu version in the path
  - Ubuntu/Debian: `apt-get install coreutils`

## git >= 2.22.0
  - asdf: `asdf plugin add git && asdf install git 2.22.0`
  - mac: `brew install git`
  - Ubuntu/Debian: `apt install git`

## jq ~> 1.6
  - asdf: `asdf plugin add jq && asdf install jq 1.6`
  - mac: `brew isntall jq`
  - Ubuntu/Debian: `apt install jq`
