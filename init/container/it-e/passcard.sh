#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh
isContainerRunning "system/traefik"
#isContainerRunning "system/database"

cnt_group="it-e"
cnt_name="passcard"
docker_name="$cnt_group.$cnt_name"
image="iteconomics/apache:php7.2"

local_domain='passcard.local'
register_host $local_domain

if checkRunning "$docker_name"; then
    docker pull $image
    docker run --detach \
      --name $docker_name \
      --restart unless-stopped \
      --volume $DATA_PATH/$cnt_group/$cnt_name/laravel:/var/www/html:rw \
      --volume $DATA_PATH/$cnt_group/$cnt_name/logs:/var/log/apache2:rw \
      --env PHP_XDEBUG=1 \
      --env XDEBUG_IDE_KEY="$local_domain" \
      --env APACHE_PUBLIC_DIR="/var/www/html/public" \
      --label traefik.frontend.rule="Host:$local_domain" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="it-e: passcard" \
      --label traefik.port=80 \
      $image

    echo -e "\033[31mDo not forget to check out PassCard sourcecode:"
    echo -e "git clone ssh://git@bitbucket.it-economics.de:7999/infra/passcard.git $DATA_PATH/it-e/passcard/laravel\033[0m"

    controllNetwork "internal" "$docker_name"
    controllNetwork "traefik" "$docker_name"
fi
