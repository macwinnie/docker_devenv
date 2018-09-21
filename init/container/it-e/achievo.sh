#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh
isContainerRunning "system/traefik"
isContainerRunning "it-e/database_achievo"

cnt_group="it-e"
cnt_name="achievo"
docker_name="$cnt_group.$cnt_name"
image="iteconomics/apache:php5.6"

local_domain='achievo.local'
register_host $local_domain

if checkRunning "$docker_name"; then
    pullImage $image
    docker run --detach \
      --name $docker_name \
      --restart unless-stopped \
      --volume $DATA_PATH/$cnt_group/$cnt_name/code:/var/www/html:rw \
      --volume $DATA_PATH/$cnt_group/$cnt_name/logs:/var/log/apache2:rw \
      --env PHP_XDEBUG=1 \
      --env XDEBUG_IDE_KEY="$local_domain" \
      --label traefik.frontend.rule="Host:$local_domain" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="it-e: Achievo" \
      --label traefik.port=80 \
      $image


    echo -e "\033[31mDo not forget to check out Achievo sourcecode:"
    echo -e "git clone https://bitbucket.it-economics.de/scm/infra/achievo.git $DATA_PATH/$cnt_group/$cnt_name/code\033[0m"

    controllNetwork "internal" "$docker_name"
    controllNetwork "traefik" "$docker_name"
fi
