#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh
isContainerRunning "system/traefik"
isContainerRunning "system/database"

cnt_group="it-e"
cnt_name="certs"
docker_name="$cnt_group.$cnt_name"
image="iteconomics/apache:php7.2"

local_domain='certs'
register_host $local_domain # will be appended by ".$LOCAL_WILDCARD"!

if checkRunning "$docker_name"; then
    docker pull $image
    docker run --detach \
      --name $docker_name \
      --restart unless-stopped \
      --volume $DATA_PATH/$cnt_group/$cnt_name/data:/var/www/html:rw \
      --volume $DATA_PATH/$cnt_group/$cnt_name/logs:/var/log/apache2:rw \
      --volume $SCRIPT_PATH/container/$cnt_group/config/$cnt_name/apache.j2:/templates/apache.j2:ro \
      --env PHP_XDEBUG=1 \
      --env XDEBUG_IDE_KEY="$(build_url $local_domain)" \
      --env MODS="headers ldap authnz_ldap" \
      --label traefik.frontend.rule="Host:$(build_url $local_domain)" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="it-e: certs" \
      --label traefik.port=80 \
      $image

    controllNetwork "internal" "$docker_name"
    controllNetwork "traefik" "$docker_name"
fi
