#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh

cnt_group="it-e"
cnt_name="database_achievo"
docker_name="$cnt_group.$cnt_name"
image="mysql:5.5.60"


if checkRunning "$docker_name"; then

    controllNetwork "internal"

    pullImage $image
    docker run --detach \
      --name $docker_name \
      --restart always \
      -p 3306:3306 \
      --network $NETWORK_DATABASE \
      --network-alias='database_achievo' \
      --volume $DATA_PATH/$cnt_group/$cnt_name/data:/var/lib/mysql:rw \
      --env MYSQL_ROOT_PASSWORD="Def12345" \
      --label traefik.enable=false \
      $image
fi
