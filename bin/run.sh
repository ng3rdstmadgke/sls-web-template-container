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
   $(dirname $0)/shell.sh -e local.env

   # devコンテナ内でマイグレーション (deコンテナでの操作)
   $ /opt/app/bin/lib/create-database.sh
   $ /opt/app/bin/lib/alembic.sh upgrade head
   $ /opt/app/bin/lib/manage.sh create_user admin --superuser
   $ exit

   # アプリ起動
   ./bin/run.sh --debug -e local.env
EOS
exit 1
}

PROJECT_ROOT="$(cd $(dirname $0)/..; pwd)"
API_DIR="$(cd ${PROJECT_ROOT}/api; pwd)"
FRONT_DIR="$(cd ${PROJECT_ROOT}/front; pwd)"
CONTAINER_DIR="$(cd ${PROJECT_ROOT}/docker; pwd)"
source "${PROJECT_ROOT}/bin/lib/utils.sh"

RUN_OPTIONS=
ENV_PATH=
AWS_PROFILE_OPTION=
AWS_REGION_OPTION=
PROXY=
DEBUG=
args=()
while [ "$#" != 0 ]; do
  case $1 in
    -h | --help      ) usage;;
    -d | --daemon    ) RUN_OPTIONS="$RUN_OPTIONS -d";;
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
[ -z "$ENV_PATH" ] && error "-e | --env-file で環境変数ファイルを指定してください"
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
    -v "${PROJECT_ROOT}:/opt/app" \
    "${APP_NAME}/dev:latest" \
    supervisord -c /opt/app/docker/dev/supervisor/supervisord.conf
else
  invoke docker run --rm -ti \
    --network host \
    --env-file "$env_tmp" \
    --user $LOCAL_UID:$LOCAL_GID \
    "${APP_NAME}/dev:latest" \
    /opt/app/docker/dev/entrypoint-prd.sh
fi