#!/bin/bash

if [ "$MODE" = "local" ]; then
  DB_PASSWORD=admin1234
  DB_USER=test_admin
  DB_HOST=127.0.0.1
  DB_PORT=53361
  DB_NAME=app
else
  SECRET_STRING="$(aws secretsmanager get-secret-value --secret-id "$DB_SECRET_NAME" --query 'SecretString' --output text)"
  DB_PASSWORD=$(echo "$SECRET_STRING" | jq -r '.db_password')
  DB_USER=$(echo "$SECRET_STRING" | jq -r '.db_user')
  DB_HOST=$(echo "$SECRET_STRING" | jq -r '.db_host')
  DB_PORT=$(echo "$SECRET_STRING" | jq -r '.db_port')
  DB_NAME=app
fi