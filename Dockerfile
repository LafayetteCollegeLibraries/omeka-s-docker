FROM php:7.2-apache
MAINTAINER adam malantonio <malantoa@lafayette.edu>

ARG GIT_URL
ARG OMEKA_CORE_DIR="core"
ARG OMEKA_MODULE_DIR="modules"
ARG OMEKA_THEME_DIR="themes"

# enable rewrites early
RUN a2enmod rewrite

# system dependencies
RUN curl -sL http://deb.nodesource.com/setup_10.x | bash -
RUN apt-get -qq update && apt-get -qq -y upgrade
RUN apt-get -qq -y --no-install-recommends install \
    git \
    nodejs \
    # from dodeeric/omeka-s-docker
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libjpeg-dev \
    libmemcached-dev \
    zlib1g-dev \
    imagemagick \
    libmagickwand-dev \
    unzip

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) iconv pdo pdo_mysql mysqli gd intl zip \
    && pecl install mcrypt-1.0.2 \
    && docker-php-ext-enable mcrypt \
    && pecl install imagick \
    && docker-php-ext-enable imagick

WORKDIR /var/www
RUN git clone --recurse-submodule $GIT_URL repo

COPY scripts/ /scripts
RUN chmod +x /scripts/*.sh

RUN /scripts/move-submodule-dirs.sh

WORKDIR /var/www/html

RUN $(dirname $(which node))/npm install && node_modules/.bin/gulp init
RUN chown -R ${APACHE_RUN_USER:-www-data}:${APACHE_RUN_GROUP:-www-data} /var/www/html

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
