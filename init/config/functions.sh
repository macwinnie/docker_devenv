#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

ask() {
    # https://djm.me/ask
    local prompt default reply

    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -ne "\033[36m$1 [$prompt] \033[0m"

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read reply </dev/tty

        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

echotask() {
    echo -e "\033[33m$1\033[0m"
}

echoinfo() {
    echo -e "\033[35m$1\033[0m"
}

register_host() {
    while IFS=',' read -ra hosts; do
        for i in "${hosts[@]}"; do
            pattern="127.0.0.1  $i"
            if ! grep -q "$pattern" /etc/hosts; then
                 echo -e "\033[31mSince we need to edit your /etc/hosts file, you probably will"
                 echo -e "be asked to enter your SUDO-Password now ... \033[0m"
                 sudo bash -c "echo \"$pattern\" >> /etc/hosts"
            fi
        done
    done <<< "$1"
}

UNSETVARS=( 'UNSETVARS' )

readVar() {
    read $1
    eval a=\$$1
    while [ -z "$a"  ]; do
        echo -ne "\033[31mYour entry was empty. Please repeat: \033[0m"
        read $1
        eval a=\$$1
    done
    export $1
    UNSETVARS+=($1)
}

setVar() {
    eval "$1"="$2"
    export $1
    UNSETVARS+=($1)
}

containergroups=()
getContainerGroups() {
    unset i
    containergroups=()
    while IFS= read -r -d $'\0' f; do
        containergroups[i++]=$( echo "$f" | sed -e "s|^$CONTAINER_PATH/||" )
    done < <(find $CONTAINER_PATH -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
}

containers=()
getContainers() {
    unset i
    containers=()
    while IFS= read -r -d $'\0' f; do
        containers[i++]=$( echo "$f" | sed -e "s|^$CONTAINER_PATH$1/||" | sed -e "s|$CONTAINER_SUFFIX$||" )
    done < <(find $CONTAINER_PATH$1 -name \*$CONTAINER_SUFFIX -mindepth 1 -maxdepth 1 -type f -print0 | sort -z)
}

listOfNetworks=()
getNetworks() {
    unset i
    listOfNetworks=()
    if [ ! -f $NETWORKS_FILE ]; then
        j2 $SCRIPT_PATH/templates/networks.j2 > $NETWORKS_FILE
    fi
    while read line; do
        listOfNetworks[i++]=$line
    done < <(cat $NETWORKS_FILE )
}

join_by() {
    local d=$1
    shift
    echo -ne "$1"
    shift
    printf "%s" "${@/#/$d}"
}

checkRunning() {
    run=0
    if [ "$(docker ps -a | grep $1)" ]; then
        if ask 'Should the container `'"$1"'` be rebuilt? (n)' N; then
            docker rm -f $1
        else
            if [ ! "$(docker ps | grep $1)" ]; then
                if ask 'The container `'"$1"'` is not running right now. Should it be restarted? (y)' Y; then
                    docker restart $1
                fi
            fi
            run=1
        fi
    fi
    return $run
}

isContainerRunning() {
    cpath="$CONTAINER_PATH$1$CONTAINER_SUFFIX"
    cname=$( echo "$1" | sed 's|/|.|' )
    run=0
    if [ ! "$(docker ps | grep $1)" ]; then
        if [ "$(docker ps -a | grep $1)" ]; then
            echoinfo 'The container `'"$1"'` is not running right now but exists.'
            if ask 'Should it be restarted? (y)' Y; then
                docker restart $1
            elif ask 'Do you want to rebuild it? (n)' N; then
                docker rm -f $1
                run=1
            fi
        else
            run=1
        fi
    fi
    if [ $run ]; then
        source $cpath
    fi
}

createVolume() {
    echoinfo 'Volume `'"$1"'` will be created for container `'"$2"'`'
    docker volume create "$1" >/dev/null 2>&1
}

controllNetwork() {
    docker network create "$1" >/dev/null 2>&1 || true
    if [ ! -z "$2" ]; then
        docker network connect "$1" "$2" >/dev/null 2>&1
    fi
}

inArray () {
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}

askForPull() {
    if ask 'Should newest images automatically be pulled? (y)' Y; then
        PULL_IMAGES='yes'
    else
        PULL_IMAGES='no'
    fi
    export PULL_IMAGES
}

pullImage() {
    if [[ "$PULL_IMAGES" == "yes" ]]; then
        docker pull "$1"
        echo 'yes, I pulled'
    else
        echo "no, I won't pull"
    fi
}
