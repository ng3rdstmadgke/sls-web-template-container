#!/bin/bash
shopt -s expand_aliases
[ -f "$HOME/.bashrc" ] && source $HOME/.bashrc

function usage {
cat >&2 <<EOS
mysqlコンテナ起動コマンド

[usage]
 $0 [options]

[options]
 -h | --help:
   ヘルプを表示
EOS
exit 1
}

SCRIPT_DIR="$(cd $(dirname $0); pwd)"
PROJECT_ROOT="$(cd ${SCRIPT_DIR}/..; pwd)"
CONTAINER_DIR="$(cd ${PROJECT_ROOT}/docker; pwd)"

source "${SCRIPT_DIR}/lib/utils.sh"

APP_NAME=$(get_app_name ${PROJECT_ROOT}/app_name)

OPTIONS=
args=()
while [ "$#" != 0 ]; do
  case $1 in
    -h | --help   ) usage;;
    -* | --*      ) error "$1 : 不正なオプションです" ;;
    *             ) args+=("$1");;
  esac
  shift
done

[ "${#args[@]}" != 0 ] && usage

env_tmp="$(mktemp)"
cat > $env_tmp <<EOF
MYSQL_USER=test_admin
MYSQL_PASSWORD=admin1234
MYSQL_DATABASE=app
MYSQL_ROOT_PASSWORD=root1234
EOF
cat $env_tmp

set -e
trap 'rm $env_tmp' EXIT
export $(cat $env_tmp | grep -v -e "^ *#.*")


cd "$CONTAINER_DIR"

invoke docker rm -f ${APP_NAME}-mysql
invoke docker run $OPTIONS \
  -d \
  --rm \
  --name ${APP_NAME}-mysql \
  --network host \
  --env-file "$env_tmp" \
  "${APP_NAME}/mysql:latest"
invoke docker run \
  --rm \
  --name ${APP_NAME}-mysql-check \
  --env-file "$env_tmp" \
  --network host \
  "${APP_NAME}/mysql:latest" \
  /usr/local/bin/check-mysql-boot.sh