#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export PATH=${PATH}

SCRIPT_DIR=$(cd $(dirname $0);/bin/pwd)
PARENT_DIR=$(cd $(dirname $0);cd ..;/bin/pwd)

. "${SCRIPT_DIR}/config.bash"

cd ${APP_ROOT}

${SCRIPT_DIR}/radio.bash stop
${RBENV_ROOT}/shims/bundle exec thin stop -P ${PID_FILE}

