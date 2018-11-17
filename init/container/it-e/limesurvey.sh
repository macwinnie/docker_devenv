#!/bin/bash

if [ -z ${SCRIPT_PATH+x} ]; then
    echo "do not run this script directly!"
    exit 1
fi

source $SCRIPT_PATH/config/require.sh

isContainerRunning "system/traefik"
isContainerRunning "system/database"

docker_name="it-e.limesurvey"
image="iteconomics/limesurvey"

local_domain='ite-survey'
register_host $local_domain # will be appended by ".$LOCAL_WILDCARD"!

if checkRunning "$docker_name"; then
    pullImage $image
    docker run --detach \
      --name $docker_name \
      --restart unless-stopped \
      --volume $DATA_PATH/it-e/limesurvey/themes/admin:/var/www/html/upload/admintheme/iteconomics:rw \
      --volume $DATA_PATH/it-e/limesurvey/themes/survey:/var/www/html/upload/themes/survey/iteconomics:rw \
      --env "DB_HOST=database" \
      --env "DB_USER=limesurvey2" \
      --env "DB_PASS=limesurvey2" \
      --env "LIMESURVEY_ADMIN=ite-admin" \
      --env "LIMESURVEY_ADMIN_PASS=Def12345" \
      --env "LIMESURVEY_ADMIN_NAME=Sysadmin" \
      --env "LIMESURVEY_ADMIN_MAIL=mwinter@it-economics.de" \
      --env "ADMIN_THEME_NAME=iteconomics" \
      --env "DEFAULT_TEMPLATE=iteconomics" \
      --env "LDAP_SERVER=ldaps:\\/\\/ldap-test.it-economics.de:40636" \
      --env "LDAP_PORT=40636" \
      --env "LDAP_TLS=1" \
      --env "LDAP_ALLOW_CREATION_TO_LOGGEDIN=1" \
      --env "LDAP_GROUP_NAME=survey_user" \
      --env LDAP_USER_PREFIX="uid=" \
      --env LDAP_USER_SUFFIX=",ou=people,dc=it-economics,dc=de" \
      --env LDAP_USER_SEARCH_BASE="ou=people,dc=it-economics,dc=de" \
      --env LDAP_GROUP_SEARCH_BASE="ou=groups,dc=it-economics,dc=de" \
      --env LDAP_BIND_DN="cn=directory,ou=accounts,dc=it-economics,dc=de" \
      --env LDAP_BIND_PASS="dD1!PTuJUVQyDMbP^m" \
      --env "LIMESURVEY_DEBUG=2" \
      --label traefik.frontend.rule="Host:$(build_url $local_domain)" \
      --label traefik.frontend.entryPoints=http \
      --label traefik.docker.network=$NETWORK_TRAEFIK \
      --label traefik.backend="it-e: LimeSurvey" \
      --label traefik.port=80 \
      $image

    echo -e "\033[31mDo not forget to check out sourcecode:"
    echo -e "git clone ssh://git@bitbucket.it-economics.de:7999/infra/limesurvey-it-e-admin-theme.git $DATA_PATH/it-e/limesurvey/themes/admin"
    echo -e "git clone ssh://git@bitbucket.it-economics.de:7999/infra/limesurvey-it-e-survey-theme.git $DATA_PATH/it-e/limesurvey/themes/survey\033[0m"

    controllNetwork "internal" "$docker_name"
    controllNetwork "traefik" "$docker_name"
fi
