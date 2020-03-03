FROM amazeeio/php:7.3-fpm

LABEL maintainer="American Bible Society"
LABEL org.label-schema.name="Alpine with PHP7-FPM and Drush launcher" \
  org.label-schema.description="PHP7-FPM, common plugins and Drush laucher"

# Added due to https://github.com/drush-ops/drush/issues/4009
RUN apk add --update --no-cache bash

# PHP modules and build dependencies
RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS libtool imagemagick-dev \
  && pecl install imagick \
  && docker-php-ext-enable imagick \
  && apk del .phpize-deps \
  && apk add --no-cache --virtual .imagick-runtime-deps imagemagick

# Use GNU Iconv
RUN apk add gnu-libiconv --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Override Lagoon's entrypoint
# COPY entrypoints/71-php-newrelic.sh /lagoon/entrypoints/

ENV DRUSH_LAUNCHER_VERSION=0.6.0

# Backwards-compatibility for projects using an older location.
RUN mkdir -p /var/www/html && ln -s /var/www/html /app

# Add gdpr-dump globally.
# RUN apk add composer; \
#   mkdir -p ~/.composer; \
#   echo '{"minimum-stability": "dev"}' > ~/.composer/composer.json; \
#   composer global require --prefer-dist machbarmacher/gdpr-dump:dev-master; \
#   apk del composer

RUN set -ex; \
  # Install mysql client
  apk add mysql-client; \
  # Install GNU version of utilities
  apk add findutils coreutils; \
  # Install Drush launcher
  curl -OL https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar; \
  chmod +x drush.phar; \
  mv drush.phar /usr/local/bin/drush; \
  \
  # Create directory for shared files
  mkdir -p -m +w /var/www/html/web/sites/default/files; \
  mkdir -p -m +w /var/www/html/private; \
  mkdir -p -m +w /var/www/html/reference-data; \
  chown -R www-data:www-data /app

WORKDIR /app/html/

# Add composer executables to our path
ENV PATH="/home/.composer/vendor/bin:${PATH}"

RUN curl -L "https://download.newrelic.com/php_agent/archive/9.3.0.248/newrelic-php5-9.3.0.248-linux-musl.tar.gz" | tar -C /tmp -zx \
  && export NR_INSTALL_SILENT=1 \
  && export NR_INSTALL_USE_CP_NOT_LN=1 \
  && /tmp/newrelic-php5-*/newrelic-install install \
  && rm -rf /tmp/newrelic-php5-* /tmp/nrinstall* \
  && mkdir -p /var/log/newrelic \
  && chown www-data:www-data /var/log/newrelic
