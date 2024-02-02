FROM docker.io/ruby:3.0.2-bullseye

SHELL ["/bin/bash", "-c"]

WORKDIR "/root"

COPY ./.tool-versions "./.tool-versions"

RUN apt-get update -y && apt-get install -y gettext tree gcc unzip make autoconf ssh libz-dev xz-utils

RUN curl -q 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr bullseye" | tee /etc/apt/sources.list.d/prebuilt-mpr.list

RUN type -p curl >/dev/null || apt install curl -y
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list >/dev/null

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
      az extension add --name azure-devops


RUN apt update -y && apt install -y gh glab && apt-get upgrade -y
RUN git clone https://github.com/asdf-vm/asdf.git "${HOME}/.asdf" --branch v0.10.2 || true

RUN . "${HOME}/.asdf/asdf.sh" && cut -d' ' -f1 .tool-versions | grep -v "^#" | \
      xargs -I{} asdf plugin add {} && cut -d' ' -f1 .tool-versions | grep -v "^#" | xargs -I{} asdf install {} && asdf reshim
RUN echo '. "${HOME}/.asdf/asdf.sh"' >> "${HOME}/.bashrc"
