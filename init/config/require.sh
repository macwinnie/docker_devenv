#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/variables.sh
source $SCRIPT_PATH/config/functions.sh

if ! hash j2 2>/dev/null; then
    echo 'Since some scripts provision Jinja2 templates, the Python-module `j2cli` is needed for rendering.'
    if ask 'Do you want to install via `pip install j2cli`?' N; then
        pip install j2cli || {
            echo 'Sorry, the regular `pip install j2cli` did not work.'
            if ask 'Should we try with `sudo`?' N; then
                sudo pip install j2cli;
            else
                echo 'Okay, we'"'"'ll shut down the script now.'
                exit 1
            fi
        }
    else
        echo 'Okay, we'"'"'ll shut down the script now.'
        exit 1
    fi
    echo ''
fi
