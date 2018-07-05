#!/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
source $SCRIPT_PATH/config/require.sh

useGroups() {
    echotask "Please select the group you want to start container(s) from:"
    getContainerGroups
    select opt in "${containergroups[@]}"; do
        case $opt in
            *)
                if [ -d "$CONTAINER_PATH$opt" ]; then
                    manageContainer "$opt"
                else
                    echo ''
                    echoinfo "You chose an invalid number. Let's try again."
                    useGroups
                fi
                break
                ;;
        esac
    done
}
manageContainer() {
    echotask "Please select the container:"
    getContainers $1
    select opt in "${containers[@]}"; do
        case $opt in
            *)
                if [ -f "$CONTAINER_PATH$1/$opt$CONTAINER_SUFFIX" ]; then
                    source $CONTAINER_PATH$1/$opt$CONTAINER_SUFFIX
                    if ask 'Do you want to manage another container out of the category `'"$1"'`? (n)' N; then
                        manageContainer $1
                    elif ask 'Do you want to manage another container out of another category? (n)' N; then
                        useGroups
                    fi
                else
                    echo ''
                    echoinfo "You chose an invalid number. Let's try again."
                    manageContainer $1
                fi
                break
                ;;
        esac
    done
}
useGroups
