#!/bin/sh
. /etc/apache2/envvars
exec apache2ctl -D FOREGROUND  >> /var/log/apache2.log 2>&1