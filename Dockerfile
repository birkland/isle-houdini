FROM php:7.4.3-apache
# Apache https://github.com/docker-library/php/blob/04c0ee7a0277e0ebc3fcdc46620cf6c1f6273100/7.4/buster/apache/Dockerfile

## General Dependencies
RUN GEN_DEP_PACKS="software-properties-common \
    gnupg \
    zip \
    unzip \
    git \
    gettext-base" && \
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

COPY rootfs /

# Composer & Houdini
# @see: Composer https://github.com/composer/getcomposer.org/commits/master (replace hash below with most recent hash)
# @see: Houdini https://github.com/Islandora/Crayfish

ARG HOUDINI_JWT_ADMIN_TOKEN
ARG HOUDINI_LOG_LEVEL

ENV PATH=$PATH:$HOME/.composer/vendor/bin \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HASH=${COMPOSER_HASH:-b9cc694e39b669376d7a033fb348324b945bce05} \
    HOUDINI_BRANCH=dev

RUN curl https://raw.githubusercontent.com/composer/getcomposer.org/$COMPOSER_HASH/web/installer --output composer-setup.php --silent && \
    php composer-setup.php --filename=composer --install-dir=/usr/local/bin && \
    rm composer-setup.php && \
    mkdir -p /opt/crayfish && \
    git clone -b $HOUDINI_BRANCH https://github.com/Islandora/Crayfish.git /opt/crayfish && \
    composer install -d /opt/crayfish/Houdini && \
    chown -Rv www-data:www-data /opt/crayfish && \
    mkdir /var/log/islandora && \
    chown www-data:www-data /var/log/islandora && \
    envsubst < /opt/templates/syn-settings.xml.template > /opt/crayfish/Houdini/syn-settings.xml && \
    envsubst < /opt/templates/monolog.yaml.template > /opt/crayfish/Houdini/config/packages/monolog.yaml && \
    cp /opt/config/services.yaml /opt/crayfish/Houdini/config/services.yaml && \
    cp /opt/config/crayfish_commons.yaml /opt/crayfish/Houdini/config/packages/crayfish_commons.yaml && \
    a2dissite 000-default && \
    #echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf && \
    #a2enconf servername && \
    a2enmod rewrite deflate headers expires proxy proxy_http proxy_html proxy_connect remoteip xml2enc cache_disk && \
    php /opt/crayfish/Houdini/bin/console cache:clear

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

ENTRYPOINT ["docker-php-entrypoint"]

STOPSIGNAL SIGWINCH

WORKDIR /opt/crayfish/Houdini/

EXPOSE 8000
CMD ["apache2-foreground"]
