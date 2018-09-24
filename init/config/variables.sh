#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

CONTAINER_SUFFIX=".sh"

CONTAINER_PATH=$SCRIPT_PATH"/container/"
DATA_PATH=$SCRIPT_PATH"/../persistentdata/"

NETWORKS_FILE=$SCRIPT_PATH"/config/networks"
NETWORK_DATABASE='internal'
NETWORK_TRAEFIK='traefik'

LOCAL_WILDCARD='local'
LOCAL_IP='127.0.0.1'

if [ -f $SCRIPT_PATH/config/custom_vars.sh ]; then
    source $SCRIPT_PATH/config/custom_vars.sh
fi

export CONTAINER_SUFFIX CONTAINER_PATH NETWORKS_FILE NETWORK_DATABASE NETWORK_TRAEFIK

mkdir -p $CONTAINER_PATH
mkdir -p $DATA_PATH
