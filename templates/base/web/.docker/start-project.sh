#!/usr/bin/env bash

##############################################################
# wait for es services to be available
##############################################################

# enable/disable xdebug according to docker environment var

%%CRON%%

##############################################################
# execute the default command
##############################################################
apache2-foreground
