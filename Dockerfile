FROM php:7.4.3-apache
# Apache https://github.com/docker-library/php/blob/04c0ee7a0277e0ebc3fcdc46620cf6c1f6273100/7.4/buster/apache/Dockerfile

## General Dependencies
RUN GEN_DEP_PACKS="software-properties-common \
    gnupg \
    git" && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
    apt-get install --no-install-recommends -y $GEN_DEP_PACKS && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Imagick 
# @see: https://launchpad.net/~lyrasis/+archive/ubuntu/imagemagick-jp2 

ENV IMAGEMAGICK_REPO=http://ppa.launchpad.net/lyrasis/imagemagick-jp2/ubuntu \
    IMAGEMAGICK_GPG_KEY=C806C0C35327CC80F2B4A41ED2B749E9FF0FA317

RUN echo deb $IMAGEMAGICK_REPO bionic main >> /etc/apt/sources.list && \
    echo deb-src $IMAGEMAGICK_REPO bionic main >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $IMAGEMAGICK_GPG_KEY && \
    IMAGEMAGICK_PACKS="imagemagick" && \
    apt-get update && \
    apt-get install --no-install-recommends -y $IMAGEMAGICK_PACKS && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Composer & Houdini
# @see: Composer https://github.com/composer/getcomposer.org/commits/master (replace hash below with most recent hash)
# @see: Houdini https://github.com/Islandora/Crayfish

ENV PATH=$PATH:$HOME/.composer/vendor/bin \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HASH=${COMPOSER_HASH:-b9cc694e39b669376d7a033fb348324b945bce05} \
    HOUDINI_BRANCH=dev

RUN curl https://raw.githubusercontent.com/composer/getcomposer.org/$COMPOSER_HASH/web/installer --output composer-setup.php --silent && \
    php composer-setup.php --filename=composer --install-dir=/usr/local/bin && \
    rm composer-setup.php && \
    rm -rf /var/www/html/* && \
    git clone -b $HOUDINI_BRANCH https://github.com/Islandora/Crayfish.git /var/www/html && \
    sudo -u www-data composer install -d /var/www/html/Houdini && \
    mkdir /var/log/islandora && \
    chown www-data:www-data /var/log/islandora

## jwt
# https://github.com/qadan/documentation/blob/installation/docs/installation/manual/configuring_drupal.md 

## syn ?
# https://github.com/Islandora/Crayfish/blob/dev/Houdini/cfg/config.example.yaml 

## logging ?
# https://github.com/Islandora/Crayfish/blob/dev/Houdini/cfg/config.example.yaml

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="ISLE 8 Houdini Image" \
      org.label-schema.description="ISLE 8 Houdini" \
      org.label-schema.url="https://islandora.ca" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/Islandora-Devops/isle-houdini" \
      org.label-schema.vendor="Islandora Devops" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

# COPY rootfs /

VOLUME /var/www/html

EXPOSE 80

ENTRYPOINT ["/init"]