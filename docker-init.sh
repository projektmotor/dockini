#!/usr/bin/env bash

function read_input() {
    read -p 'Use cron [y|N]: ' WITH_CRON
    read -p 'Use postgres [y|N]: ' WITH_POSTGRES
    read -p 'Use mysql [Y|n]: ' WITH_MYSQL
    read -p 'Use elastic search [y|N]: ' WITH_ES
    read -p 'PROJECT_NAME [my_nice_project]: ' PROJECT_NAME

    if [ "${PROJECT_NAME}" = "" ]; then
        PROJECT_NAME=my_nice_project
    fi

    PROJECT_NAME_HYPHENIZED=${PROJECT_NAME//_/-}
    echo ${PROJECT_NAME}
    echo ${PROJECT_NAME_HYPHENIZED}


    # calculate starting port number in steps of 20
    RANGE=12080 # max port is at 65535
    FLOOR=8100  # up to 1023 are privileged ports
    number=0   #initialize
    while [ "$number" -le $FLOOR ]
    do
      number=$RANDOM
      let "number %= $RANGE"  # Scales $number down within $RANGE.
      mod=${number}
      let "mod %= 20"  # Scales $number down within steps of 20.
      let "number -= $mod"
    done
    RANDOM_PORTRANGE_START=${number}
    read -p "PORTRANGE_START [${RANDOM_PORTRANGE_START}]: " PORTRANGE_START

    if [ "${PORTRANGE_START}" = "" ]; then
        PORTRANGE_START=${RANDOM_PORTRANGE_START}
    elif [ "${PORTRANGE_START}" < 1023 ]; then
        echo "PORTRANGE_START have to be larger than 1023"
        exit
    elif [ "${PORTRANGE_START}" > 65535 ]; then
        echo "PORTRANGE_START have to be lower than 65535"
        exit
    fi

    # TODO ability to use SSL
    #read -p 'Enable SSL [Y|n]: ' SSL_ENABLED

    # TODO ensure all settings are correct
}

function replace_in_file() {
    # exclude non existing files
    if [ ! -f $1 ]; then
        return
    fi

    TEMPLATE=$(<$1)

    # maybe use awk for (inline) replacement
    # escape this to get new lines
    # in templates there is escaping of \ and $ with \ required
    TEMPLATE="$(echo "${TEMPLATE}" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\$/\\$/g')"
    sed 's|'"${3}"'|'"${TEMPLATE}"'|g' $2 > /tmp/Dockerfile
    mv /tmp/Dockerfile $2
}

function remove_from_file () {
    sed 's|'"${2}"'||g' $1 > /tmp/Dockerfile2
    mv /tmp/Dockerfile2 $1
}

function handle_cron() {
    if [ "${WITH_CRON}" = "y" ]; then

        mkdir -p build/web/.docker/etc/cron.d/
        cp templates/cron/web/.docker/etc/cron.d/* build/web/.docker/etc/cron.d/

        replace_in_file "templates/cron/web/Dockerfile" "build/web/Dockerfile" "%%CRON%%"
        replace_in_file "templates/cron/web/.docker/start-project.sh" "build/web/.docker/start-project.sh" "%%CRON%%"
    else
        remove_from_file "build/web/.docker/start-project.sh" "%%CRON%%"
        remove_from_file "build/web/Dockerfile" "%%CRON%%"
    fi
}

function handle_postgres() {
    if [ "${WITH_POSTGRES}" = "y" ]; then
        replace_in_file "templates/postgres/web/Dockerfile" "build/web/Dockerfile" "%%POSTGRES%%"
        replace_in_file "templates/postgres/web/.env" "build/web/.env" "%%POSTGRES%%"
        replace_in_file "templates/postgres/docker-compose.yml" "build/docker-compose.yml" "%%POSTGRES%%"
        replace_in_file "templates/postgres/docker-compose.live.yml" "build/docker-compose.live.yml" "%%POSTGRES%%"
        replace_in_file "templates/postgres/docker-compose.override.yml" "build/docker-compose.override.yml" "%%POSTGRES%%"
        replace_in_file "templates/postgres/docker-compose.stage.yml" "build/docker-compose.stage.yml" "%%POSTGRES%%"
        replace_in_file "templates/postgres/docker-compose.test.yml" "build/docker-compose.test.yml" "%%POSTGRES%%"
        replace_in_file "templates/postgres/.env" "build/.env" "%%POSTGRES%%"

        mkdir -p build/postgres/
        cp templates/postgres/postgres/Dockerfile build/postgres/Dockerfile

        DEPENDS_ON_POSTGRES="- postgres"
        VOLUMES_POSTGRES="postgres_data:"
    else
        echo no postgres
        remove_from_file "build/web/Dockerfile" "%%POSTGRES%%"
        remove_from_file "build/web/.env" "%%POSTGRES%%"
        remove_from_file "build/docker-compose.yml" "%%POSTGRES%%"
        remove_from_file "build/docker-compose.live.yml" "%%POSTGRES%%"
        remove_from_file "build/docker-compose.override.yml" "%%POSTGRES%%"
        remove_from_file "build/docker-compose.stage.yml" "%%POSTGRES%%"
        remove_from_file "build/docker-compose.test.yml" "%%POSTGRES%%"
        remove_from_file "build/.env" "%%POSTGRES%%"

        DEPENDS_ON_POSTGRES=""
        VOLUMES_POSTGRES=""
    fi
}

function handle_mysql() {
    if [ "${WITH_MYSQL,,}" = "n" ]; then
        echo no mysql
        remove_from_file "build/web/Dockerfile" "%%MYSQL%%"
        remove_from_file "build/web/.env" "%%MYSQL%%"
        remove_from_file "build/docker-compose.yml" "%%MYSQL%%"
        remove_from_file "build/docker-compose.live.yml" "%%MYSQL%%"
        remove_from_file "build/docker-compose.override.yml" "%%MYSQL%%"
        remove_from_file "build/docker-compose.stage.yml" "%%MYSQL%%"
        remove_from_file "build/docker-compose.test.yml" "%%MYSQL%%"
        remove_from_file "build/.env" "%%MYSQL%%"

        DEPENDS_ON_MYSQL=""
        VOLUMES_MYSQL=""
    else
        echo with mysql
        replace_in_file "templates/mysql/web/Dockerfile" "build/web/Dockerfile" "%%MYSQL%%"
        replace_in_file "templates/mysql/web/.env" "build/web/.env" "%%MYSQL%%"
        replace_in_file "templates/mysql/docker-compose.yml" "build/docker-compose.yml" "%%MYSQL%%"
        replace_in_file "templates/mysql/docker-compose.live.yml" "build/docker-compose.live.yml" "%%MYSQL%%"
        replace_in_file "templates/mysql/docker-compose.override.yml" "build/docker-compose.override.yml" "%%MYSQL%%"
        replace_in_file "templates/mysql/docker-compose.stage.yml" "build/docker-compose.stage.yml" "%%MYSQL%%"
        replace_in_file "templates/mysql/docker-compose.test.yml" "build/docker-compose.test.yml" "%%MYSQL%%"
        replace_in_file "templates/mysql/.env" "build/.env" "%%MYSQL%%"

        DEPENDS_ON_MYSQL="- mysql"
        VOLUMES_MYSQL="mysql_data:"
    fi
}

function handle_es() {
    if [ "${WITH_ES}" = "y" ]; then
        echo with es - no handling yet
#        replace_in_file "templates/mysql/Dockerfile" "build/mysql/Dockerfile" "%%CRON%%"
    else
        echo no es - no handling yet
#        remove_from_file "build/web/Dockerfile" "%%MYSQL%%"
    fi
}

function prepare_build_dir() {
    mkdir -p build
    rm -rf build/

    # copy base templates
    cp --recursive templates/base/. build/
}

function set_ports_vars() {
    OUTER_WEB_PORT=$((PORTRANGE_START+0))
    OUTER_MYSQL_PORT=$((PORTRANGE_START+1))
    OUTER_POSTGRES_PORT=$((PORTRANGE_START+2))
    OUTER_ES_PORT=$((PORTRANGE_START+3))
    OUTER_WEB_PORT_TEST=$((PORTRANGE_START+10))
    OUTER_WEB_PORT_STAGE=$((PORTRANGE_START+11))
    OUTER_WEB_PORT_LIVE=$((PORTRANGE_START+12))
}

function replace_word_in_file() {
    sed 's|'"${3}"'|'"${1}"'|g' $2 > /tmp/Dockerfile_3
    mv /tmp/Dockerfile_3 $2
}

function replace_project_names() {
    find build -iname "*" -type f | \
        while read I; do
            replace_word_in_file "${PROJECT_NAME}" "$I" "%%PROJECT_NAME%%"
            replace_word_in_file "${PROJECT_NAME_HYPHENIZED}" "$I" "%%PROJECT_NAME_HYPHENIZED%%"
            replace_word_in_file "${OUTER_WEB_PORT}" "$I" "%%OUTER_WEB_PORT%%"
            replace_word_in_file "${OUTER_MYSQL_PORT}" "$I" "%%OUTER_MYSQL_PORT%%"
            replace_word_in_file "${OUTER_POSTGRES_PORT}" "$I" "%%OUTER_POSTGRES_PORT%%"
            replace_word_in_file "${OUTER_ES_PORT}" "$I" "%%OUTER_ES_PORT%%"
            replace_word_in_file "${OUTER_WEB_PORT_TEST}" "$I" "%%OUTER_WEB_PORT_TEST%%"
            replace_word_in_file "${OUTER_WEB_PORT_STAGE}" "$I" "%%OUTER_WEB_PORT_STAGE%%"
            replace_word_in_file "${OUTER_WEB_PORT_LIVE}" "$I" "%%OUTER_WEB_PORT_LIVE%%"
            replace_word_in_file "${DEPENDS_ON_MYSQL}" "$I" "%%DEPENDS_ON_MYSQL%%"
            replace_word_in_file "${DEPENDS_ON_POSTGRES}" "$I" "%%DEPENDS_ON_POSTGRES%%"
            replace_word_in_file "${VOLUMES_MYSQL}" "$I" "%%VOLUMES_MYSQL%%"
            replace_word_in_file "${VOLUMES_POSTGRES}" "$I" "%%VOLUMES_POSTGRES%%"
        done

}

function execute_docker_compose() {

    cd build

    docker-compose --file docker-compose.yml --file docker-compose.override.yml config
    # docker-compose --file docker-compose.yml --file docker-compose.override.yml up --build -d --remove-orphans
    # docker-compose --file docker-compose.yml --file docker-compose.override.yml exec web tail -f /var/log/cron.log
    # docker build --file build/Dockerfile .
}

function main() {
    prepare_build_dir
    read_input

    set_ports_vars

    handle_cron
    handle_postgres
    handle_mysql
    handle_es

    replace_project_names

    execute_docker_compose

    # TODO write next steps e.g. edit crontab
}

main