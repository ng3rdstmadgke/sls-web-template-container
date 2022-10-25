#!/bin/bash

for i in $(seq 1 25); do
  success=$(MYSQL_PWD=$DB_PASSWORD mysql -u $DB_USER -h 127.0.0.1 -P $DB_PORT $DB_NAME -e "SELECT 'success'" >/dev/null 2>&1; echo $?)
  if [ "$success" = "0" ]; then
    echo "success!!"
    exit
  else
    echo "mysql booting..."
  fi
  sleep 1
done
echo "failed..."
exit 1