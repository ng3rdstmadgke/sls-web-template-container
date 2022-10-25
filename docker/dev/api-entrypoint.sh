#!/bin/bash
set -xe

cd /opt/app/
printenv
uvicorn api.main:app --log-config api/log_config.yml --reload