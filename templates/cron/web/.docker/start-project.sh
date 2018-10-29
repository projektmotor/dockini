printenv \| sed 's/^\\(.*\\)$/export \\1/g' > /root/env.sh
cron start
