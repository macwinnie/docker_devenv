#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh
isContainerRunning "system/traefik"

cnt_group="system"
cnt_name="mailtrap"
docker_name="$cnt_group.$cnt_name"

local_domain='mailtrap'
register_host $local_domain

image="mailhog/mailhog"

if checkRunning "$docker_name"; then

    pullImage $image

    docker run --detach \
      --name $docker_name \
      --restart unless-stopped \
      --env "MH_STORAGE=maildir" \
      --volume $DATA_PATH/$cnt_group/$cnt_name/data:/maildir \
      --label traefik.frontend.rule="Host:$(build_url $local_domain)" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="System: Mailtrap" \
      --label traefik.port=8025 \
      --health-cmd 'echo | telnet 127.0.0.1 1025' \
      $image

    controllNetwork "traefik" "$docker_name"

    echo -e "\033[31mAccess Mailtrap by http://$(build_url $local_domain)"
    echo -e "SMTP-Host: $docker_name:1025, no authentification (user and password empty) for \"sending\" mails\033[0m"
fi
