FROM ithaca.azurecr.io/ithacacollege/terminus-ci:2.3

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
ARG NVM_VERSION=v8.17.0
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
    if [[ "$NVM_VERSION" = "v8.17.0" ]]; then \
    apk add --update --no-cache --virtual .dd-build-deps libarchive-tools linux-headers \
    && npm install --global --ignore-scripts gulp@^3.9.1 eslint@^4.19.1 \
    && npm install --global --ignore-scripts eslint-plugin-import@^2.12.0 eslint-plugin-jsx-a11y@^6.0.3 eslint-plugin-react@^7.9.1 eslint-config-airbnb@^17.0.0 \
    && npm cache clean --force \
    && mkdir -p $PATTERNLAB_BUILD_DIR && cd $PATTERNLAB_BUILD_DIR \
    && composer -n create-project pattern-lab/edition-twig-standard:^2.2.1 pattern-lab \
    && composer -n create-project drupal-pattern-lab/bem-twig-extension:^1.0.1 \
    && composer -n create-project drupal-pattern-lab/add-attributes-twig-extension:^1.0.1 \
    && composer clearcache \
    && apk del .dd-build-deps; \
    else \
    apk add --update --no-cache autoconf automake g++ make \
    && npm install --global yarn \
    && npm cache clean --force \
    && ln -s $(which yarn) /usr/local/bin/; \
    fi
