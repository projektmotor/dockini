RUN apt-get update \&\& apt-get install -y \\
    cron \\
    mc

ADD .docker/etc/cron.d/crontab /etc/cron.d/update-cron
RUN touch /var/log/cron.log
RUN chmod 0644 /etc/cron.d/update-cron
RUN /usr/bin/crontab /etc/cron.d/update-cron
