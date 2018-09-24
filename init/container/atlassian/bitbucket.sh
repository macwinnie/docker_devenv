#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh

isContainerRunning "system/traefik"
isContainerRunning "atlassian/postgres"

cnt_group="atlassian"
cnt_name="bitbucket"
docker_name="$cnt_group.$cnt_name"
image="iteconomics/bitbucket"

local_domain='bitbucket'
register_host $local_domain # will be appended by ".$LOCAL_WILDCARD"!

if checkRunning "$docker_name"; then

    docker pull $image

    mkdir -p $DATA_PATH/$cnt_group/$cnt_name/data/lib

    docker run --detach \
      --name $docker_name \
      --memory 2048m \
      --restart unless-stopped \
      --volume $DATA_PATH/$cnt_group/$cnt_name/data:/var/atlassian/application-data/bitbucket:rw \
      --env JAVA_OPTS="-Xms2048m -Xmx2048m -Djdk.tls.trustNameService=true -Duser.timezone=Europe/Berlin" \
      --label traefik.frontend.rule="Host:$(build_url $local_domain)" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="Atlassian: Bitbucket" \
      --label traefik.port=8080 \
      $image

    controllNetwork "internal" "$docker_name"
    controllNetwork "traefik" "$docker_name"
fi
