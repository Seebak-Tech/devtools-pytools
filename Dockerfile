FROM seebaktec/nvim

ARG VERSION=0.0.0

LABEL "Version" = $VERSION
LABEL "Name" = "devtools-pytools"

USER root

ARG CHROME_VERSION="google-chrome-stable"

COPY wrap_chrome_binary /opt/bin/wrap_chrome_binary

# Installing packages
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y -q --allow-unauthenticated \
        tk-dev \
        ffmpeg \
        apt-transport-https \
        curl \
        docker-ce-cli \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update -qqy \
    && apt-get -qqy install \
        ${CHROME_VERSION:-google-chrome-stable} \
    && rm /etc/apt/sources.list.d/google-chrome.list \
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/* \
    && sh -x /opt/bin/wrap_chrome_binary \
    && npm install -g pyright

USER admin 

ENV HOME=/home/admin \
    PATH=/home/admin/.pyenv/shims:/home/admin/.pyenv/bin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/admin/.poetry/bin:. \
    PYTHON3_HOST_PROG=/home/admin/.pyenv/versions/neovim3/bin/python \
    ZSH_CUSTOM=/home/admin/.oh-my-zsh/custom/

ARG PYTHON3_VERSION=3.9.2

WORKDIR $HOME

COPY --chown=admin zshrc ./.zshrc

COPY --chown=admin zprofile ./.zprofile

COPY --chown=admin init.toml $HOME/.SpaceVim.d/init.toml

COPY --chown=admin cloudformation.vim $HOME/.SpaceVim.d/ftdetect/cloudformation.vim

# Python layer options for SpaceVim and touch to update the date of the init.toml
# Installing aws cdk and plugins for layers
RUN touch $HOME/.SpaceVim.d/init.toml \
    && mkdir $HOME/bin \
    && eval "$(pyenv init -)" \
    && eval "$(pyenv virtualenv-init -)" \
    && pyenv activate neovim3 && pip install --upgrade pip \
    && pip install flake8 isort yapf autoflake jedi coverage cfn-lint\
    && ln -s `pyenv which flake8` $HOME/bin/flake8 \
    && ln -s `pyenv which isort` $HOME/bin/isort \
    && ln -s `pyenv which yapf` $HOME/bin/yapf \
    && ln -s `pyenv which autoflake` $HOME/bin/autoflake \
    && ln -s `pyenv which coverage` $HOME/bin/coverage \
    && ln -s `pyenv which cfn-lint` $HOME/bin/cfn-lint \
    && sudo npm install --g dockerfile_lint aws-cdk

# Installing and configuring poetry and set password to user admin
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python - \
    && mkdir $ZSH_CUSTOM/plugins/poetry \
    && poetry completions zsh > $ZSH_CUSTOM/plugins/poetry/_poetry \
    && poetry config virtualenvs.in-project true \
    && curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscli.zip \
    && unzip -q /tmp/awscli.zip -d /tmp \
    && sudo /tmp/aws/install \
    && rm -rf /tmp/aws* \
    && echo 'admin:admin1' | sudo chpasswd

COPY docker-entrypoint.sh /tmp/docker-entrypoint.sh

EXPOSE 22 8888

ENTRYPOINT ["sh", "/tmp/docker-entrypoint.sh"]
