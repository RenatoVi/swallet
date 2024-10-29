#!/usr/bin/env ash
DOCKER_CONTAINER_UUID=$(cat /proc/sys/kernel/random/uuid)
grep -q "DOCKER_CONTAINER_UUID" /var/www/html/project/.env; [ $? -eq 1 ] && echo "DOCKER_CONTAINER_UUID=" >> /var/www/html/project/.env
sed -i "s/DOCKER_CONTAINER_UUID=.*/DOCKER_CONTAINER_UUID=${DOCKER_CONTAINER_UUID}/gi" /var/www/html/project/.env
exec "$@"