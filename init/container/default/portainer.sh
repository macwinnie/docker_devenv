#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh

isContainerRunning "system/traefik"

cnt_group="default"
cnt_name="portainer"
docker_name="$cnt_group.$cnt_name"
image="portainer/portainer"

local_domain='portainer'
register_host $local_domain # will be appended by ".$LOCAL_WILDCARD"!

if checkRunning "$docker_name"; then
    pullImage $image
    docker run --detach \
      --name $docker_name \
      --restart always \
      --volume /var/run/docker.sock:/var/run/docker.sock:rw \
      --volume $DATA_PATH/$cnt_group/$cnt_name/data:/data:rw \
      --label traefik.frontend.rule="Host:$(build_url $local_domain)" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="default: Portainer" \
      --label traefik.port=9000 \
      $image

    controllNetwork "traefik" "$docker_name"
fi
