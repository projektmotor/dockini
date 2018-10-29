RUN apt-get update \&\& apt-get install -y \\
        mysql-client

RUN docker-php-ext-install -j$(nproc) pdo_mysql
