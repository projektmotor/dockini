# postgres
RUN apt-get update \&\& apt-get install -y \\
    gnupg \\
    wget

RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - \| apt-key add -
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
# postgres non-interactively
RUN sh -c 'echo "postgres:5432:sospos:postgres:postgres_password" >> /root/.pgpass'
RUN chmod 0600 /root/.pgpass

RUN apt-get update \&\& apt-get install -y \\
    libpq-dev \\
    postgresql-client

RUN docker-php-ext-install pdo_pgsql
