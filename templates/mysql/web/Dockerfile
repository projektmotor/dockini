RUN apt-get update \&\& apt-get install -y \\
    mysql-client \\
    netcat

RUN docker-php-ext-install -j$(nproc) pdo_mysql
