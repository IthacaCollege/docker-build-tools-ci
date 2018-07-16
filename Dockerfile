FROM drupaldocker/php:7.0-cli-2.x
MAINTAINER Eric Woods <ewoods@ithaca.edu>

WORKDIR /build-tools-ci
ADD . /build-tools-ci

### core tools and config
RUN apk upgrade --update --no-cache && apk add --update --no-cache \
    bash

# emulsify-gulp install issue with npm module triggers build from source needing python + make + g++
# pattern-lab post-install issue fails, needing libarchive-tools for tar
RUN apk add --update --no-cache \
    python make g++ \
    libarchive-tools

# pantheon terminus ssh has
RUN mkdir -p $HOME/.ssh \
    && echo "StrictHostKeyChecking no" >> "$HOME/.ssh/config"

### be fast...
RUN composer -n global require -n "hirak/prestissimo:^0.3"

### terminus
ENV TERMINUS_VERSION 1.8.1
ENV TERMINUS_HIDE_UPDATE_MESSAGE 1
ENV TERMINUS_DIR /usr/local/share/terminus
ENV TERMINUS_PLUGINS_DIR /usr/local/share/terminus-plugins

RUN mkdir -p $TERMINUS_DIR \
    && composer -n --working-dir=$TERMINUS_DIR require pantheon-systems/terminus:$TERMINUS_VERSION

RUN mkdir -p $TERMINUS_PLUGINS_DIR \
    && composer -n create-project -d $TERMINUS_PLUGINS_DIR pantheon-systems/terminus-build-tools-plugin:^1 \
    && composer -n create-project -d $TERMINUS_PLUGINS_DIR pantheon-systems/terminus-secrets-plugin:^1 \
    && composer -n create-project -d $TERMINUS_PLUGINS_DIR pantheon-systems/terminus-rsync-plugin:^1 \
    && composer -n create-project -d $TERMINUS_PLUGINS_DIR pantheon-systems/terminus-quicksilver-plugin:^1 \
    && composer -n create-project -d $TERMINUS_PLUGINS_DIR pantheon-systems/terminus-composer-plugin:^1 \
    && composer -n create-project -d $TERMINUS_PLUGINS_DIR pantheon-systems/terminus-drupal-console-plugin:^1 \
    && composer -n create-project -d $TERMINUS_PLUGINS_DIR pantheon-systems/terminus-mass-update:^1 \
    && composer -n create-project -d $TERMINUS_PLUGINS_DIR pantheon-systems/terminus-site-clone-plugin:^1

ENV PATH $PATH:/usr/local/share/terminus/vendor/bin

### npm + gulp for theme build + js linting tools
RUN apk add --update nodejs nodejs-npm \
    && npm install --global gulp@^3.9.1

### linting tools
## (revisions based on npm info "eslint-config-airbnb@latest" peerDependencies)
RUN npm install --global eslint@^4.19.1 \
    && npm install --global eslint-plugin-import@^2.12.0 \
    && npm install --global eslint-plugin-jsx-a11y@^6.0.3 \
    && npm install --global eslint-plugin-react@^7.9.1 \
    && npm install --global eslint-config-airbnb@^17.0.0 \
    && npm cache clean --force

### patternlab components
ENV PATTERNLAB_BUILD_DIR /build-tools-ci/pattern-lab-sources

RUN mkdir -p $PATTERNLAB_BUILD_DIR \
    && composer -n create-project -d $PATTERNLAB_BUILD_DIR pattern-lab/edition-twig-standard:^2.2.1 \
    && composer -n create-project -d $PATTERNLAB_BUILD_DIR drupal-pattern-lab/bem-twig-extension:^1.0.1 \
    && composer -n create-project -d $PATTERNLAB_BUILD_DIR drupal-pattern-lab/add-attributes-twig-extension:^1.0.1
