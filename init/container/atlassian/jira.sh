#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh

isContainerRunning "system/traefik"
isContainerRunning "atlassian/postgres"

cnt_group="atlassian"
cnt_name="jira"
docker_name="$cnt_group.$cnt_name"
image="iteconomics/jira-ite"

local_domain='jira'
register_host $local_domain # will be appended by ".$LOCAL_WILDCARD"!

if checkRunning "$docker_name"; then

    docker pull $image

    docker run --detach \
      --name $docker_name \
      --memory 2048m \
      --restart unless-stopped \
      --volume $DATA_PATH/$cnt_group/$cnt_name/data:/var/atlassian/application-data/jira:rw \
      --env JAVA_OPTS="-Xms1024m -Xmx1024m -Djdk.tls.trustNameService=true" \
      --label traefik.frontend.rule="Host:$(build_url $local_domain)" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="Atlassian: Jira" \
      --label traefik.port=8080 \
      $image

    controllNetwork "internal" "$docker_name"
    controllNetwork "traefik" "$docker_name"
fi
