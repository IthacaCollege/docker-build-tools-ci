FROM ithaca.azurecr.io/ithacacollege/terminus-ci:2.4

ENV TZ /usr/share/zoneinfo/America/New_York
RUN echo '. /etc/profile' >> /root/.bashrc
ENTRYPOINT [ "/bin/bash" ]

# stops CI from converting source files when deploying with git commit
RUN git config --global core.autocrlf false

### patternlab components
ENV PATTERNLAB_BUILD_DIR /build-tools-ci/pattern-lab-sources

# emulsify-gulp install issue with npm module triggers build from source needing python + make + g++
# pattern-lab post-install issue fails, needing libarchive-tools for tar
RUN apk add --no-cache coreutils libstdc++ sudo
ARG NVM_VERSION=v12.18.4
RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash \
    && ( \
        echo 'export NVM_DIR="$HOME/.nvm";' \
        && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh";' \
        && echo 'export NVM_NODEJS_ORG_MIRROR=https://unofficial-builds.nodejs.org/download/release;' \
        && echo "nvm_get_arch() { nvm_echo \"x64-musl\"; }" \
    ) > /etc/profile.d/nvm.sh \
    && . /etc/profile.d/nvm.sh \
    && nvm install $NVM_VERSION \
    && echo 'nvm use --disable-prefix '$NVM_VERSION >> /etc/profile.d/nvm.sh \
    && nvm cache clear
RUN . /etc/profile.d/nvm.sh; \
    apk add --update --no-cache autoconf automake g++ make \
    && npm install --global yarn \
    && npm cache clean --force \
    && ln -s $(which yarn) /usr/local/bin/
