ARG PHP_VERSION=7.4.33
ARG ALPINE_VERSION=''

FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION}

RUN apk --update --no-cache add linux-headers git bash tzdata msmtp wget imagemagick-dev \
    && set -ex \
    && apk --no-cache add libxml2-dev libpng libpng-dev libjpeg libwebp-dev libjpeg-turbo-dev libzip-dev freetype-dev \
    && docker-php-ext-configure gd --with-jpeg --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install mysqli soap sockets gd zip \
    && apk --no-cache add g++ gcc make autoconf \
    && docker-php-source extract

# opcache
RUN docker-php-ext-install opcache

# memcache
RUN wget https://pecl.php.net/get/memcache && tar -zxvf memcache* \
    && cd memcache-8.2 && phpize && ./configure --enable-memcache && make && make install

# imagick
RUN apk add --update --no-cache --virtual .imagick-runtime-deps imagemagick \
    && pecl install imagick-3.4.4 \
    && docker-php-ext-enable imagick 

# xdebug
RUN pecl install xdebug-3.1.5 && docker-php-ext-enable xdebug

# yaml
RUN apk add --update yaml yaml-dev \
    && pecl install yaml && docker-php-ext-enable yaml

# mhsendmail for MailHog (https://github.com/mailhog/mhsendmail)
RUN curl -LkSso /usr/bin/mhsendmail 'https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64' \
    && chmod 0755 /usr/bin/mhsendmail

# packages to index documents (doc, xls, ppt, pdf)
RUN apk add --update poppler poppler-utils \
    && apk add catdoc --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing/

# ldap
RUN apk add --update --no-cache \
    libldap && \
    # Build dependancy for ldap \
    apk add --update --no-cache --virtual .docker-php-ldap-dependencies \
    openldap-dev && \
    docker-php-ext-configure ldap && \
    docker-php-ext-install ldap && \
    apk del .docker-php-ldap-dependencies

# clear
RUN apk del make gcc g++ autoconf pkgconfig libxml2-dev libpng-dev libjpeg-turbo-dev libmemcached-dev

COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

RUN chown -R www-data:www-data /var/www

EXPOSE 9000
