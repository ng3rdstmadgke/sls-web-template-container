#!/bin/bash -l

function usage {
cat >&2 <<EOS
コンテナ起動コマンド

[usage]
 $0 [options]

[options]
 -h | --help:
   ヘルプを表示
 -e | --env-file <ENV_PATH>:
   apiコンテナ用の環境変数ファイルを指定 (default=app/local.env)
 --debug:
   デバッグモードで起動
 --profile <AWS_PROFILE>:
   awsのプロファイル名を指定 例) default
 --region <AWS_REGION>:
   awsのリージョンを指定 例) ap-northeast-1
 --proxy:
   プロキシ設定を有効化

[example]
 - 開発用コンテナを起動する手順
   # mysqlコンテナ起動
   $(dirname $0)/run-mysql.sh -d

   # devコンテナ起動
   $(dirname $0)/shell.sh

   # devコンテナ内でマイグレーション (deコンテナでの操作)
   $ ./bin/create-database.sh
   $ alembic upgrade head
   $ ./bin/manage.sh create_user admin --superuser
   $ exit

   # アプリ起動
   ./bin/run.sh --debug
EOS
exit 1
}

PROJECT_ROOT="$(cd $(dirname $0)/..; pwd)"
source "${PROJECT_ROOT}/bin/lib/utils.sh"

AWS_PROFILE_OPTION=
AWS_REGION_OPTION=
ENV_PATH="${PROJECT_ROOT}/app/local.env"
PROXY=
DEBUG=
args=()
while [ "$#" != 0 ]; do
  case $1 in
    -h | --help      ) usage;;
    -e | --env-file  ) shift;ENV_PATH="$1";;
    --debug          ) DEBUG="1";;
    --profile        ) shift;AWS_PROFILE_OPTION="--profile $1";;
    --region         ) shift;AWS_REGION_OPTION="--region $1";;
    --proxy          ) PROXY="1";;
    -* | --*         ) error "$1 : 不正なオプションです" ;;
    *                ) args+=("$1");;
  esac
  shift
done

[ "${#args[@]}" != 0 ] && usage
[ -r "$ENV_PATH" -a -f "$ENV_PATH" ] || error "指定した環境変数ファイルを読み込めません: $ENV_PATH"

env_tmp="$(mktemp)"
cat "$ENV_PATH" > "$env_tmp"

AWS_ACCESS_KEY_ID=$(aws $AWS_PROFILE_OPTION $AWS_REGION_OPTION configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws $AWS_PROFILE_OPTION $AWS_REGION_OPTION configure get aws_secret_access_key)
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

# Docker build
cd "$PROJECT_ROOT"
export LOCAL_UID=$(id -u)
export LOCAL_GID=$(id -g)

# Docker run
if [ -n "$DEBUG" ]; then
  invoke docker run --rm -ti \
    --network host \
    --env-file "$env_tmp" \
    --user $LOCAL_UID:$LOCAL_GID \
    -v "${PROJECT_ROOT}/app:/opt/app" \
    "${APP_NAME}/dev:latest" \
    supervisord -c /etc/supervisor/supervisord.conf
else
  invoke docker run --rm -ti \
    --network host \
    --env-file "$env_tmp" \
    --user $LOCAL_UID:$LOCAL_GID \
    "${APP_NAME}/dev:latest" \
    /usr/local/bin/entrypoint-prd.sh
fi