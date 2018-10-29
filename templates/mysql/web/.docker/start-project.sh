##############################################################
# GLOBAL PART - executed on all web* services
##############################################################

# wait for mysql service to be available
until nc -z -v -w30 web 3306 > /dev/null 2>\&1
do
    echo "Waiting for MySQL connection "
    sleep 5
done
