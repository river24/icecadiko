#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export PATH=${PATH}

SCRIPT_DIR=$(cd $(dirname $0);/bin/pwd)
PARENT_DIR=$(cd $(dirname $0);cd ..;/bin/pwd)

. "${SCRIPT_DIR}/config.bash"

cd ${APP_ROOT}

${RBENV_ROOT}/shims/bundle exec rackup -D -s thin -P ${PID_FILE} -p ${APP_PORT} config.ru

