#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh

isContainerRunning "system/traefik"

docker_name="system.portainer"
image="portainer/portainer"

local_domain='portainer.local'
register_host $local_domain

if checkRunning "$docker_name"; then
    docker pull $image
    docker run --detach \
      --name $docker_name \
      --restart always \
      --volume /var/run/docker.sock:/var/run/docker.sock:rw \
      --volume $DATA_PATH/system/portainer/data:/data:rw \
      --label traefik.frontend.rule="Host:$local_domain" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="system: Portainer" \
      --label traefik.port=9000 \
      $image

    controllNetwork "traefik" "$docker_name"
fi
