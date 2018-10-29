FROM composer:1.7 as composer
FROM php:7.2-apache

ENV PROJECT_NAME=%%PROJECT_NAME%%

# replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# set correct timezone
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

%%CRON%%

%%POSTGRES%%

%%MYSQL%%

#RUN apt-get update && apt-get install -y \
#        wget \
#        netcat \
#        libicu-dev \
#        libzip-dev \
#        libjpeg-dev \
#        libpng-dev \
#        libssl-dev \
#        git-core \
#        acl
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

COPY .docker /usr/local/etc/php/

#RUN pecl install zip


COPY --from=composer /usr/bin/composer /usr/bin/composer
## https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /home/docker/.composer
## contains dev-mode packages
RUN composer global require "hirak/prestissimo:^0.3" "sllh/composer-versions-check:^2.0" "pyrech/composer-changelogs:^1.5" --prefer-dist --no-progress --no-suggest --classmap-authoritative

COPY composer.json composer.lock symfony.lock /var/www/html/
COPY src/Kernel.php /var/www/html/src/

RUN cd /var/www/html; \
        composer install --optimize-autoloader

COPY package.json yarn.lock /var/www/html/
RUN yarn install

WORKDIR /var/www/html
COPY . /var/www/html

ARG APP_ENVIRONMENT=prod
ENV APP_ENVIRONMENT=${APP_ENVIRONMENT}
ENV APACHE_LOG_NAME=${PROJECT_NAME}_${APP_ENVIRONMENT}

###RUN SYMFONY_ENV=$APP_ENVIRONMENT composer symfony-scripts
##
RUN if [ "$APP_ENVIRONMENT" != "dev" ]; then \
        node_modules/.bin/encore production; \
    fi

COPY .docker /
# start can be removed
#COPY .docker /etc/apache2/.htpasswd
#COPY .docker /etc/apache2/sites-enabled/
# end can be removed

RUN a2enmod rewrite
RUN a2enmod headers


#COPY .docker/apache-php /
COPY .docker/start-project.sh /start-project.sh

#EXPOSE 80
#EXPOSE 443

# clear apt-cache for smaller docker images
RUN apt-get clean -y
RUN chmod 777 /start-project.sh

ENTRYPOINT /start-project.sh
