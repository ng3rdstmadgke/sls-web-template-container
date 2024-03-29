#!/bin/bash

function usage {
cat >&2 <<EOS
DBログインコマンド

[usage]
 $0 [options]

[options]
 -h | --help:
   ヘルプを表示
 -e | --env-file <ENV_PATH>:
   環境変数ファイルを指定 (default=app/local.env)
 --profile <AWS_PROFILE>:
   awsのプロファイル名を指定 (default=default)
 --region <AWS_REGION>:
   awsのリージョンを指定 (default=ap-northeast-1)
 --proxy:
   プロキシ設定を有効化
EOS
exit 1
}

SCRIPT_DIR=$(cd $(dirname $0); pwd)
PROJECT_ROOT=$(cd $(dirname $0)/..; pwd)
source "${SCRIPT_DIR}/lib/utils.sh"

APP_NAME=$(get_app_name ${PROJECT_ROOT}/app_name)

AWS_PROFILE="default"
AWS_REGION="ap-northeast-1"
ENV_PATH="${PROJECT_ROOT}/app/local.env"
PROXY=
args=()
while [ "$#" != 0 ]; do
  case $1 in
    -h | --help     ) usage;;
    -e | --env-file ) shift;ENV_PATH="$1";;
    --profile       ) shift;AWS_PROFILE="$1";;
    --region        ) shift;AWS_REGION="$1";;
    --proxy         ) PROXY="1";;
    -* | --*        ) error "$1 : 不正なオプションです" ;;
    *               ) args+=("$1");;
  esac
  shift
done

[ "${#args[@]}" != 0 ] && usage
[ -r "$ENV_PATH" -a -f "$ENV_PATH" ] || error "コンテナ用の環境変数ファイルを読み込めません: $ENV_PATH"

env_tmp="$(mktemp)"
cat "$ENV_PATH" > "$env_tmp"

AWS_ACCESS_KEY_ID=$(aws --profile $AWS_PROFILE --region $AWS_REGION configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws --profile $AWS_PROFILE --region $AWS_REGION configure get aws_secret_access_key)
echo "" >> "$env_tmp"
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> "$env_tmp"
echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> "$env_tmp"

if [ -n "$PROXY" ]; then
  echo "http_proxy=$proxy" >> "$env_tmp"
  echo "https_proxy=$proxy" >> "$env_tmp"
  echo "NO_PROXY=$no_proxy" >> "$env_tmp"
fi

set -e
trap 'rm -f $env_tmp;' EXIT

export LOCAL_UID=$(id -u)
export LOCAL_GID=$(id -g)
docker run --rm -ti \
  --network host \
  --env-file "$env_tmp" \
  --user $LOCAL_UID:$LOCAL_GID \
  -v "${PROJECT_ROOT}/app:/opt/app" \
  "${APP_NAME}/dev:latest" \
  /bin/bash