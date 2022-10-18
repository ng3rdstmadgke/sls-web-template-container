#!/bin/bash -l

function usage {
cat >&2 <<EOS
コンテナ起動コマンド

[usage]
 $0 [options]

[options]
 -h | --help:
   ヘルプを表示
 -d | --daemon:
   バックグラウンドで起動
 -e | --env-file <ENV_PATH>:
   apiコンテナ用の環境変数ファイルを指定(default=.env)
 --debug:
   デバッグモードで起動
 --profile <AWS_PROFILE>:
   awsのプロファイル名を指定 (default=default)
 --region <AWS_REGION>:
   awsのリージョンを指定 (default=ap-northeast-1)
 --proxy:
   プロキシ設定を有効化
EOS
exit 1
}

PROJECT_ROOT="$(cd $(dirname $0)/..; pwd)"
API_DIR="$(cd ${PROJECT_ROOT}/api; pwd)"
FRONT_DIR="$(cd ${PROJECT_ROOT}/front; pwd)"
CONTAINER_DIR="$(cd ${PROJECT_ROOT}/docker; pwd)"
source "${PROJECT_ROOT}/bin/lib/utils.sh"

OPTIONS=
ENV_PATH=
AWS_PROFILE="default"
AWS_REGION="ap-northeast-1"
PROXY=
DEBUG=
args=()
while [ "$#" != 0 ]; do
  case $1 in
    -h | --help      ) usage;;
    -d | --daemon    ) OPTIONS="$OPTIONS -d";;
    -e | --env-file  ) shift;ENV_PATH="$1";;
    --debug          ) DEBUG="1";;
    --profile        ) shift;AWS_PROFILE="$1";;
    --region         ) shift;AWS_REGION="$1";;
    --proxy          ) PROXY="1";;
    -* | --*         ) error "$1 : 不正なオプションです" ;;
    *                ) args+=("$1");;
  esac
  shift
done

[ "${#args[@]}" != 0 ] && usage
[ -z "$ENV_PATH" ] && error "-e | --env-file で環境変数ファイルを指定してください"
[ -r "$ENV_PATH" -a -f "$ENV_PATH" ] || error "指定した環境変数ファイルを読み込めません: $ENV_PATH"

env_tmp="$(mktemp)"
cat "$ENV_PATH" > "$env_tmp"

AWS_ACCESS_KEY_ID=$(aws --profile $AWS_PROFILE --region $AWS_REGION configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws --profile $AWS_PROFILE --region $AWS_REGION configure get aws_secret_access_key)
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> "$env_tmp"
echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> "$env_tmp"

if [ -n "$PROXY" ]; then
  echo "http_proxy=$proxy" >> "$env_tmp"
  echo "https_proxy=$proxy" >> "$env_tmp"
  echo "NO_PROXY=$no_proxy" >> "$env_tmp"
fi

invoke export PROJECT_ROOT="$PROJECT_ROOT"
invoke export ENV_PATH="$env_tmp"
invoke export APP_NAME=$(get_app_name ${PROJECT_ROOT}/app_name)

cd "$CONTAINER_DIR"
invoke export LOCAL_UID=$(id -u)
invoke export LOCAL_GID=$(id -g)

if [ -n "$DEBUG" ]; then
  trap "docker-compose -f docker-compose-dev.yml down; rm -f $env_tmp" EXIT
  invoke docker-compose -f docker-compose-dev.yml down
  invoke docker-compose -f docker-compose-dev.yml up $OPTIONS
else
  trap "docker-compose -f docker-compose.yml down; rm -f $env_tmp" EXIT
  invoke docker-compose -f docker-compose.yml down
  invoke docker-compose -f docker-compose.yml up $OPTIONS
fi