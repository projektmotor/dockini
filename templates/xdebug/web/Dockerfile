RUN pecl install xdebug \&\& \\
    docker-php-ext-enable xdebug

RUN sh -c "echo 'xdebug.remote_enable=1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini" \&\& \\
    sh -c "echo 'xdebug.remote_autostart=1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini" \&\& \\
    sh -c "echo 'xdebug.remote_host=172.17.0.1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini" \&\& \\
    sed -i -e 's/zend_extension/;zend_extension/g' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
