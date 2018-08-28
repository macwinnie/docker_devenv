#!/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
source $SCRIPT_PATH/config/require.sh

if ! ask 'Is the image provided on the official Docker-Registry (https://hub.docker.com)? (Y)' Y; then
    echotask 'Well, then please tell us the registry now:'
    readVar "DOCKER_REG"
fi
echo ''

if ! ask 'Is the image you want to use a library one, so no user / organisation has to be provided? (n)' N; then
    echotask 'Okay, which user / organisation has to be provided?'
    readVar "DOCKER_USER"
fi
echo ''

echotask 'Please tell us, how the image you want to use is called:'
readVar "DOCKER_IMG"
echo ''

if ask 'Do you want to use another version than the image default? (n)' N; then
    echotask 'Well – which version should be used?'
    readVar "DOCKER_VERSION"
fi
echo ''

if ask 'Should the container run in privileged mode? (n)' N; then
    setVar "DOCKER_PRIVILEGED" "1"
fi
echo ''

if ask 'Do you want to define environmental variables? (y)' Y; then
    HELPER_DOCKER_ENVS=()
    askForEnvs() {
        echotask 'Please enter the variable (i.e. `MYSQL_ROOT_PASSWORD="my-secret-pw"`):'
        readVar HELPER1
        HELPER_DOCKER_ENVS+=( "$HELPER1" )
        unset HELPER1
        if ask 'Do you want to add further environmental variables? (n)' N; then
            askForEnvs
        fi
    }
    askForEnvs
    setVar "DOCKER_ENVS" "'$( IFS=$'\t'; echo "${HELPER_DOCKER_ENVS[*]}" || echo '' )'"
    unset HELPER_DOCKER_ENVS
fi
echo ''

if ask 'Do you want us to publish all exposed ports on Container to random ports on host? (n)' N; then
    setVar "DOCKER_ALL_EXPOSED" "true"
elif ask 'Do you want to publish ports directly? (n)' N; then
    HELPER_DOCKER_PORTS=()
    askForPorts() {
        echotask 'Please enter the port-mapping in docker syntax (i.e. `3306:3306`):'
        readVar HELPER1
        HELPER_DOCKER_PORTS+=( "$HELPER1" )
        unset HELPER1
        if ask 'Do you want to publish further ports? (n)' N; then
            askForPorts
        fi
    }
    askForPorts
    setVar "DOCKER_PORTS" "'$( IFS=$'\t'; echo "${HELPER_DOCKER_PORTS[*]}" || echo '' )'"
    unset HELPER_DOCKER_PORTS
fi
echo ''

HELPER_DOCKER_LABELS=()
if ask 'Do you want to label your Container? (Træfik-Labels are added automatically.) (n)' N; then
    askForLabels() {
        echotask 'Please enter the label (i.e. `configurationdate="'"$(date)"'"`):'
        readVar HELPER1
        HELPER_DOCKER_LABELS+=( "$HELPER1" )
        unset HELPER1
        if ask 'Do you want to add further labels? (n)' N; then
            askForLabels
        fi
    }
    askForLabels
fi
echo ''

if ask 'Do you want to define another restart policy than `always`? (n)' N; then
    unset options
    options=( "no" "on-failure" "always" "unless-stopped" )
    selectRestartMethod() {
        select opt in "${options[@]}" "default"; do
            case $opt in
                "on-failure")
                    if ask 'Do you want to define the max number of retries? (n)' N; then
                        echotask 'Please enter the max number of retries: '
                        readVar "MAX_RETRY"
                        setVar "DOCKER_RESTART" "$opt:$MAX_RETRY"
                    else
                        setVar "DOCKER_RESTART" "$opt"
                    fi
                    break
                    ;;
                *)
                    if inArray "$opt" "${options[@]}"; then
                        setVar "DOCKER_RESTART" "$opt"
                    else
                        echotask "Okay, we won't set this so the Docker default will be taken."
                    fi
                    break
                    ;;
            esac
        done
    }
    selectRestartMethod
else
    setVar "DOCKER_RESTART" "always"
fi
echo ''

HELPER_DOCKER_NETWORKS=( )
if ask 'Do you want your container be part of one or more Docker networks? (n)' N; then
    echotask 'If you want to publish the container trough Træfik, the network `'"$NETWORK_TRAEFIK"'` will be added automatically.'
    getNetworks
    askForNetworks() {
        select opt in "${listOfNetworks[@]}" "Create a new one" "None"; do
            case $opt in
                "Create a new one")
                    echotask 'How should the name of the new network be?'
                    readVar "HELPER1"
                    HELPER1=$( echo $HELPER1 | awk '{print tolower($0)}' | sed -e 's/ /_/g' ) && export HELPER1
                    echo $HELPER1 >> $NETWORKS_FILE
                    HELPER_DOCKER_NETWORKS+=( "$HELPER1" )
                    unset HELPER1
                    if ask 'Are there more networks, you want the container to be part of? (n)' N; then
                        askForNetworks
                    fi
                    break
                    ;;
                "None")
                    echotask 'Okay, we'"'"'ll skip that ...'
                    break
                    ;;
                *)
                    if [[ " ${listOfNetworks[*]} " == *" $opt "* ]]; then
                        echoinfo "You chose $opt"
                        HELPER_DOCKER_NETWORKS+=( "$opt" )
                        if ask 'Are there more networks, you want the container to be part of? (n)' N; then
                            askForNetworks
                        fi
                    else
                        echo ''
                        echoinfo "You chose an invalid number. Let's try again."
                        askForNetworks
                    fi
                    break
                    ;;
            esac
        done
    }
    askForNetworks
fi
echo ''

askForGroup () {
    if ask 'Do you want to place the container within another group than the `default` one? (n)' N; then
        getContainerGroups
        select opt in "${containergroups[@]}" "Create a new one"; do
            case $opt in
                "Create a new one")
                    echotask 'How should the new group be called?'
                    readVar "CONTAINER_GROUP"
                    mkdir -p $CONTAINER_PATH$CONTAINER_GROUP
                    break
                    ;;
                *)
                    if [ -d "$CONTAINER_PATH$opt" ]; then
                        echoinfo "You chose $opt"
                        setVar "CONTAINER_GROUP" "$opt"
                    else
                        echo ''
                        echoinfo "You chose an invalid number. Let's try again."
                        askForGroup
                    fi
                    break
                    ;;
            esac
        done
    else
        CONTAINER_GROUP='default'
    fi
}

askForGroup

export CONTAINER_GROUP
echo ''

askForName () {
    echotask 'Please tell us the name, your Docker-Container should have:'
    readVar "TRAEFIK_BACKEND"
    DOCKER_NAME=$( echo $TRAEFIK_BACKEND | awk '{print tolower($0)}' | sed -e 's/ /_/g' )
    export DOCKER_NAME
    echo ''
    while [ -z "$DOCKER_NAME"  ]; do
        echotask 'Well ... that did not work – we received an empty name ...'
        unset DOCKER_NAME TRAEFIK_BACKEND
        askForName
    done
    while [ -f "$CONTAINER_PATH/$CONTAINER_GROUP/$DOCKER_NAME$CONTAINER_SUFFIX" ]; do
        if ask 'The destination-file does already exist. Do you want to overwrite it? (n)' N; then
            rm -f "$CONTAINER_PATH/$CONTAINER_GROUP/$DOCKER_NAME$CONTAINER_SUFFIX"
        else
            unset DOCKER_NAME TRAEFIK_BACKEND
            askForName
        fi
    done
}

askForName

if ask 'Are there folders and / or files you want to mount? (y)' Y; then
    HELPER_DOCKER_VOLUMES=()
    HELPER_DOCKER_MOUNTS=()
    askForVolumes() {
        echotask 'Please enter the path on the host:'
        readVar HELPER1
        if ask 'Your path was relative to the docker project folder? (y)' Y; then
            HELPER1='$DATA_PATH/$cgroup/$cname/'"$HELPER1"
        elif ask 'Did you enter the name for a Docker Volume? (n)' N; then
            HELPER_DOCKER_VOLUMES+=( "$HELPER1" )
        fi
        echotask 'Please enter the full path on docker container:'
        readVar HELPER2
        if ask 'Should the mount be read only? (n)' N; then
            HELPER3='ro'
        else
            HELPER3='rw'
        fi
        HELPER_DOCKER_MOUNTS+=( "$HELPER1:$HELPER2:$HELPER3" )
        unset HELPER1 HELPER2 HELPER3
        if ask 'Do you want to add further Volumes? (n)' N; then
            askForVolumes
        fi
    }
    askForVolumes
fi
echo ''

setVar "DOCKER_MOUNTS" "'$( IFS=$'\t'; echo "${HELPER_DOCKER_MOUNTS[*]}" || echo '' )'"
unset HELPER_DOCKER_MOUNTS
setVar "DOCKER_VOLUMES" "'$( IFS=$'\t'; echo "${HELPER_DOCKER_VOLUMES[*]}" || echo '' )'"
unset HELPER_DOCKER_VOLUMES

HELPER_DOCKER_REQUIRE=()
if ask 'One more thing: Do you want your container to publish through Træfik? (n)' N; then
    HELPER_DOCKER_NETWORKS+=( "$NETWORK_TRAEFIK" )
    HELPER_DOCKER_REQUIRE+=( "system/traefik" )
    echotask 'For configuring that, we need to define an URL to bind to that container (no http:// or https://!):'
    readVar "TRAEFIK_HOST"
    if ask 'Should the connection port for Træfik be sth. else than default Port 80? (n)' N; then
        echotask 'Please enter the port to be the connection port: '
        readVar "TRAEFIK_PORT"
    else
        setVar "TRAEFIK_PORT" 80
    fi
    HELPER_DOCKER_LABELS+=( 'traefik.frontend.rule="Host:$local_domain"' 'traefik.frontend.entryPoints=http' 'traefik.docker.network=$NETWORK_TRAEFIK' 'traefik.backend="'"$CONTAINER_GROUP: $TRAEFIK_BACKEND"'"' 'traefik.port='"$TRAEFIK_PORT" )
else
    HELPER_DOCKER_LABELS+=( "traefik.enable=false" )
fi
echo ''

setVar "DOCKER_NETWORKS" "'$( IFS=$'\t'; echo "${HELPER_DOCKER_NETWORKS[*]}" || echo '' )'"
unset HELPER_DOCKER_NETWORKS
setVar "DOCKER_LABELS" "'$( IFS=$'\t'; echo "${HELPER_DOCKER_LABELS[*]}" || echo '' )'"
unset HELPER_DOCKER_LABELS

if ask 'Does your container have any dependencies on other containers? (n)' N; then
    requireGroups() {
        echotask "Please select the group you want to search for containers in:"
        getContainerGroups
        select opt in "${containergroups[@]}"; do
            case $opt in
                *)
                    if [ -d "$CONTAINER_PATH$opt" ]; then
                        requireContainers "$opt"
                    else
                        echo ''
                        echoinfo "You chose an invalid number. Let's try again."
                        requireGroups
                    fi
                    break
                    ;;
            esac
        done
    }
    requireContainers() {
        echotask "Please select the container, you want to mark as dependency:"
        if [ "$1" = 'system' ] && [ ! -z ${TRAEFIK_HOST+x} ]; then
            echoinfo 'You selected `'"$1"'` and publish through Traæfik – you don'"'"'t need to add this container manually!'
        fi
        getContainers $1
        select opt in "${containers[@]}"; do
            case $opt in
                *)
                    if [ -f "$CONTAINER_PATH$1/$opt$CONTAINER_SUFFIX" ]; then
                        HELPER_DOCKER_REQUIRE+=( "$1/$opt" )
                        echoinfo 'You chose the container `'"$1.$opt"'` to be mandatory.'
                        if ask 'Do you want to add another container out of the category `'"$1"'`? (n)' N; then
                            requireContainers $1
                        elif ask 'Do you want to add another container out of another category? (n)' N; then
                            requireGroups
                        fi
                    else
                        echo ''
                        echoinfo "You chose an invalid number. Let's try again."
                        requireContainers $1
                    fi
                    break
                    ;;
            esac
        done
    }
    requireGroups
fi
echo ''

setVar "DOCKER_REQUIRE" "'$( IFS=$'\t'; echo "${HELPER_DOCKER_REQUIRE[*]}" || echo '' )'"
unset HELPER_DOCKER_REQUIRE

j2 $SCRIPT_PATH/templates/container.j2 > $CONTAINER_PATH"/"$CONTAINER_GROUP"/"$DOCKER_NAME$CONTAINER_SUFFIX

echo 'Well done, your startup config was written out.'

if ask 'Do you want to run it now? (y)' Y; then
    source $CONTAINER_PATH"/"$CONTAINER_GROUP"/"$DOCKER_NAME$CONTAINER_SUFFIX
elif ask 'Would you like to edit the definition file, i.e. to add further settings? (n)' N; then
    "${EDITOR:-vi}" $CONTAINER_PATH"/"$CONTAINER_GROUP"/"$DOCKER_NAME$CONTAINER_SUFFIX
fi

for i in ${UNSETVARS[@]}; do
    unset $i
done

exit 0
