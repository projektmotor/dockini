FROM composer:1.8 as composer
FROM php:7.2-apache

ARG APP_ENVIRONMENT
ENV APP_ENVIRONMENT=${APP_ENVIRONMENT}

# replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# set correct timezone
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod ssl

# Use this self-generated certificate only in dev, IT IS NOT SECURE!
RUN openssl genrsa -des3 -passout pass:NotSecure -out cert.pass.key 2048
RUN openssl rsa -passin pass:NotSecure -in cert.pass.key -out /etc/ssl/private/cert.key
RUN rm cert.pass.key
RUN openssl req -new -passout pass:NotSecure -key /etc/ssl/private/cert.key -out /etc/ssl/private/cert.csr \
    -subj '/C=SS/ST=SS/L=Entenhausen/O=Dockini Dev/CN=localhost'
RUN openssl x509 -req -sha256 -days 365 -in /etc/ssl/private/cert.csr -signkey /etc/ssl/private/cert.key -out /etc/ssl/private/cert.crt

%%CRON%%

%%POSTGRES%%

%%MYSQL%%

%%YARN%%

%%XDEBUG%%

%%PANTHER%%

##############################################################
# PECL zip
##############################################################

RUN apt-get update && apt-get install -y \
    libzip-dev

RUN pecl install zip

##############################################################
# MISC
##############################################################

RUN apt-get update && apt-get install -y \
#        wget \
#        netcat \
#        libicu-dev \
#        libzip-dev \
#        libjpeg-dev \
#        libpng-dev \
#        libssl-dev \
        acl
#
#
RUN docker-php-ext-configure opcache --enable-opcache && \
        docker-php-ext-install opcache && \
        pecl install apcu && \
        docker-php-ext-enable apcu

#        docker-php-ext-configure gd --with-jpeg-dir=/usr/include/ && \
#        docker-php-ext-install gd && \
#        docker-php-ext-configure intl && \
#        docker-php-ext-install bcmath && \
#        docker-php-ext-install intl

##############################################################
# COMPOSER INIT
##############################################################

RUN apt-get update && apt-get install -y \
    libzip-dev \
    git-core

COPY --from=composer /usr/bin/composer /usr/bin/composer
## https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /home/docker/.composer
## contains dev-mode packages
RUN composer global require "hirak/prestissimo:^0.3" "sllh/composer-versions-check:^2.0" "pyrech/composer-changelogs:^1.6" --prefer-dist --no-progress --no-suggest --classmap-authoritative

COPY .docker /

COPY composer.json composer.lock symfony.lock /var/www/html/
COPY src/Kernel.php /var/www/html/src/

RUN cd /var/www/html; \
        composer install --optimize-autoloader --no-scripts

COPY package.json yarn.lock /var/www/html/
RUN cd /var/www/html; \
        yarn install

WORKDIR /var/www/html
COPY . /var/www/html

ENV APACHE_LOG_NAME=${PROJECT_NAME}_${DEPLOY_ENVIRONMENT}

RUN if [ "$APP_ENVIRONMENT" != "dev" ]; then \
        node_modules/.bin/encore production; \
    fi

COPY .docker/start-project.sh /start-project.sh

# clear apt-cache for smaller docker images
RUN apt-get clean -y
RUN chmod 777 /start-project.sh

ENTRYPOINT /start-project.sh
