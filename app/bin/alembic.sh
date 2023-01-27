#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
APP_ROOT=$(cd $SCRIPT_DIR/../; pwd)
API_DIR=$(cd $SCRIPT_DIR/../api; pwd)
source $SCRIPT_DIR/lib/utils.sh
cd $API_DIR

invoke alembic $*
