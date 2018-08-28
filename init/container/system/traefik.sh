#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh

cnt_group="system"
cnt_name="traefik"
docker_name="$cnt_group.$cnt_name"
image="traefik"

local_domain='traefik.local'
register_host $local_domain

if checkRunning $docker_name; then

    tomlPath="$DATA_PATH$cnt_group/$cnt_name"
    tomlFile=$tomlPath'/traefik.toml'
    if [ ! -f "$tomlFile" ]; then
        mkdir -p "$tomlPath"
        touch "$tomlFile"
        j2 $SCRIPT_PATH/templates/traefik.toml.j2 > $tomlFile
    fi

    docker pull $image
    docker run --detach \
      --name $docker_name \
      --restart always \
      -p 80:80 \
      --volume /var/run/docker.sock:/var/run/docker.sock:rw \
      --volume $DATA_PATH/$cnt_group/$cnt_name/traefik.toml:/traefik.toml:ro \
      --label traefik.frontend.rule="Host:$local_domain" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="system: Traefik" \
      --label traefik.port=8080 \
      $image --docker

    controllNetwork "traefik" "$docker_name"
fi
