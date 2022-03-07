#!/bin/bash -eu
SCRIPT_DIR=$(cd $(dirname $0); pwd)
PROJECT_ROOT=$(cd $(dirname $0)/..; pwd)
APP_NAME=$(cat ${PROJECT_ROOT}/app_name | tr '[A-Z]' '[a-z]')

cd ${PROJECT_ROOT}
source "${SCRIPT_DIR}/lib/utils.sh"

CONTAINER_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n1)

invoke docker run \
  --rm \
  -v ${PROJECT_ROOT}:/opt/sls \
  -v /root/.cache:/root/.cache \
  -v ${HOME}/.aws:/root/.aws:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ${APP_NAME}/sls:latest sls $*