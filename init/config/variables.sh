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

export CONTAINER_SUFFIX CONTAINER_PATH NETWORKS_FILE NETWORK_DATABASE NETWORK_TRAEFIK

mkdir -p $CONTAINER_PATH
mkdir -p $DATA_PATH
