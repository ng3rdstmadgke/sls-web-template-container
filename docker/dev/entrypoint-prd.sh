#!/bin/bash
set -xe

cd /opt/app/front
#npm install
#npm run generate

cd /opt/app/
printenv
/var/lang/bin/uvicorn api.main:app --log-config api/log_config.yml