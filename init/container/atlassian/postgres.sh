#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh

docker_name="atlassian.postgres"
image="postgres:9.6"

if checkRunning "$docker_name"; then

    cnfPath="$DATA_PATH"'atlassian/postgres/multidb'
    git clone https://github.com/mrts/docker-postgresql-multiple-databases.git $cnfPath

    controllNetwork "internal"

    pullImage $image

    docker run --detach \
      --name $docker_name \
      --restart unless-stopped \
      -p 5432:5432 \
      --network $NETWORK_DATABASE \
      --volume $DATA_PATH/atlassian/postgres/data:/var/lib/postgresql/data:rw \
      --volume $DATA_PATH/atlassian/postgres/multidb:/docker-entrypoint-initdb.d:ro \
      --env POSTGRES_PASSWORD=Def12345 \
      --env POSTGRES_USER=postgres \
      --env POSTGRES_MULTIPLE_DATABASES=bamboo,bitbucket,confluence,jira \
      --label traefik.enable=false \
      $image
fi
