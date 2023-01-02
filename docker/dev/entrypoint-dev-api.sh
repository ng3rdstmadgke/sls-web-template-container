#!/bin/bash
set -xe

mkdir -p /opt/app/front_dist
cd /opt/app/
printenv
/var/lang/bin/uvicorn api.main:app --log-config api/log_config.yml --reload