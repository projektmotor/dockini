#!/usr/bin/env bash

# ${APP_ENVIRONMENT}
# => global env-var (introduced at build time, see Dockerfile)
# => could be overridden by runtime env-var


##############################################################
# wait for es services to be available
##############################################################


HOST_UID=${HOST_UID:-1000}
HOST_GID=${HOST_GID:-1000}

%%MYSQL%%

# docker user is only needed in dev dev-env, where mount volume is used (user credentials)
if [ "${APP_ENVIRONMENT}" = "dev" ]; then
    # add docker user (if not exist)
    USER_EXIST=`id -u ${HOST_UID} > /dev/null 2>&1`
    if [ $? = 1 ]; then
        groupadd --gid $HOST_GID $CONTAINER_GROUP
        useradd --uid $HOST_UID --gid $HOST_GID -ms /bin/bash $CONTAINER_USER

        echo "added system user: \"${CONTAINER_USER}\""
    fi
fi


%%CRON%%

if [ "${APP_ENVIRONMENT}" = "dev" ]; then
    SYMFONY_ENV=${APP_ENVIRONMENT} composer self-update
    SYMFONY_ENV=${APP_ENVIRONMENT} composer install
elif [ "${APP_ENVIRONMENT}" = "test" ]; then
    php bin/console doctrine:schema:update --force
    php bin/console hautelook:fixtures:load --no-interaction
    # need to use APP_ENV=${APP_ENVIRONMENT} ?
else
    php bin/console doctrine:database:create --if-not-exists --no-interaction
    php bin/console doctrine:migrations:migrate --no-interaction
fi

php bin/console cache:clear

# notice: this should be done after composer-tasks, otherwise composer-task
#         could run with enabled xdebug (endless script execution!)
#
# enable/disable xdebug:
# - only enable in dev environment
# - only enable if PHP_XDEBUG_ENABLED is set to 1
if [ "${APP_ENVIRONMENT}" != "dev" ] || [ "$PHP_XDEBUG_ENABLED" != "1" ]; then
    sed -i -e 's/zend_extension/;zend_extension/g' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
else
    PHP_XDEBUG_REMOTE_HOST=$(hostname --ip-address | awk -F '.' '{printf "%d.%d.%d.1",$1,$2,$3}')

    sed -i -e "s/xdebug\.remote_host.*/xdebug.remote_host=$PHP_XDEBUG_REMOTE_HOST/g" /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    sed -i -e 's/;zend_extension/zend_extension/g'                                   /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
fi

if [ "${APP_ENVIRONMENT}" != "dev" ]; then
    yarn encore production
else
    yarn encore dev --watch > /var/www/html/var/log/encore.log 2>&1 &
fi

##############################################################
# execute the default command
##############################################################
apache2-foreground
