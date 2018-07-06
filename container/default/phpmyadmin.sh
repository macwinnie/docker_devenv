#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh

isContainerRunning "system/traefik"
isContainerRunning "system/database"

docker_name="default.phpmyadmin"
image="phpmyadmin/phpmyadmin"

local_domain='pma.local'
register_host $local_domain

if checkRunning "$docker_name"; then
    docker pull $image
    docker run --detach \
      --name $docker_name \
      --restart always \
      --volume $DATA_PATH/system/phpmyadmin/config.user.inc.php:/etc/phpmyadmin/config.user.inc.php:ro \
      --env PMA_HOST=database \
      --env PMA_USER=root \
      --env PMA_PASSWORD=Def12345 \
      --label conf \
      --label traefik.frontend.rule="Host:$local_domain" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="default: phpMyAdmin" \
      --label traefik.port=80 \
      $image

    controllNetwork "internal" "$docker_name"
    controllNetwork "traefik" "$docker_name"
fi
