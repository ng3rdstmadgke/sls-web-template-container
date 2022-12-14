#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0); pwd)
source $SCRIPT_DIR/utils.sh

info MYSQL_PWD="$DB_PASSWORD" mysql -u "$DB_USER" -h "$DB_HOST" -P "$DB_PORT"
MYSQL_PWD="$DB_PASSWORD" mysql -u "$DB_USER" -h "$DB_HOST" -P "$DB_PORT" "$DB_NAME"
if [ $? != "0" ]; then
  info MYSQL_PWD="$DB_PASSWORD" mysql -u "$DB_USER" -h "$DB_HOST" -P "$DB_PORT"
  MYSQL_PWD="$DB_PASSWORD" mysql -u "$DB_USER" -h "$DB_HOST" -P "$DB_PORT"
fi