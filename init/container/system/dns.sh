#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh

cnt_group="system"
cnt_name="dns"
docker_name="$cnt_group.$cnt_name"
image="cytopia/bind"

local_domain='dns'
register_host $local_domain # will be appended by ".$LOCAL_WILDCARD"!

if checkRunning "$docker_name"; then

    dnsf=''
    if ask 'Should DNS forwarding be activated within this DNS server? (n)' N; then
        while [ -z "$dns_forwarder"  ]; do
            echotask 'Please enter a comma separated list of IP addresses, the container should use as DNS forwarder (i.e. `8.8.8.8,8.8.4.4` for Googles DNS):'
            readVar dns_forwarder
            dnsf="--env DNS_FORWARDER=$dns_forwarder"
        done
    fi

    pullImage $image
    docker run --detach \
      --name $docker_name \
      --restart unless-stopped \
      -p 53:53/tcp \
      -p 53:53/udp \
      --env WILDCARD_DNS="local=$LOCAL_IP" $dnsf \
      --label traefik.enable=false \
      $image
fi
