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

image="eaudeweb/mailtrap"

if checkRunning "$docker_name"; then

    docker pull $image

    docker run --detach \
      --name $docker_name \
      --restart unless-stopped \
      --env MT_USER="admin" \
      --env MT_PASSWD="Def12345" \
      --label traefik.frontend.rule="Host:$(build_url $local_domain)" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="System: Mailtrap" \
      --label traefik.port=80 \
      $image

    controllNetwork "traefik" "$docker_name"

    echo -e "\033[31mYou can now access RoundCube for viewing the trapped mails at http://$(build_url $local_domain)"
    echo -e "For usage within other Docker containers use:"
    echo -e "SMTP-Host: $docker_name:25, no authentification (user and password empty) for \"sending\" mails\033[0m"
fi
