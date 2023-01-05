#!/bin/bash

function usage {
cat >&2 <<EOF
slsコマンド

[usage]
 $0 [options] -- [SLS_ARG1] [SLS_ARG2] [SLS_ARG3] ...

[options]
 -h | --help:
   ヘルプを表示
 --profile <AWS_PROFILE>:
   awsのプロファイル名を指定 (default=default)
 --region <AWS_REGION>:
   awsのリージョンを指定 (default=ap-northeast-1)
 --proxy:
   プロキシ設定を有効化

[example]
  ヘルプ
    $0 -- help
  デプロイ
    $0 -- deploy --stage dev
  デプロイステータス
    $0 -- info --stage dev
  削除
    $0 -- remove --stage dev
  プラグインインストール
    $0 -- plugin install  -n serverless-python-requirements --stage dev
EOF
exit 1
}

PROJECT_ROOT="$(cd $(dirname $0)/..; pwd)"
source "${PROJECT_ROOT}/bin/lib/utils.sh"

APP_NAME=$(get_app_name ${PROJECT_ROOT}/app_name)

AWS_PROFILE="default"
AWS_REGION="ap-northeast-1"
BUILD_OPTIONS=
SLS_ARGS=()
while [ "$#" != 0 ]; do
  case $1 in
    -h | --help ) usage;;
    --proxy     ) BUILD_OPTIONS="$BUILD_OPTIONS --build-arg proxy=$proxy --build-arg no_proxy=$no_proxy";;
    --profile   ) shift;AWS_PROFILE="$1";;
    --region    ) shift;AWS_REGION="$1";;
    --          ) shift; SLS_ARGS+=($@); break;;
    -* | --*    ) error "$1 : 不正なオプションです";;
  esac
  shift
done

BUILD_OPTIONS="$BUILD_OPTIONS --build-arg host_uid=$(id -u)"
BUILD_OPTIONS="$BUILD_OPTIONS --build-arg host_gid=$(id -g)"
AWS_ACCESS_KEY_ID=$(aws --profile $AWS_PROFILE --region $AWS_REGION configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws --profile $AWS_PROFILE --region $AWS_REGION configure get aws_secret_access_key)

invoke docker build $BUILD_OPTIONS -q --rm -f docker/sls/Dockerfile -t ${APP_NAME}/sls:latest .

#!/bin/bash
PROJECT_ROOT=$(cd $(dirname $0)/..; pwd)
invoke docker run -ti --rm \
  --user app \
  -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
  -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ${HOME}/.cache:/home/app/.cache \
  -v ${PROJECT_ROOT}/sls/serverless.yml:/opt/sls/serverless.yml \
  -v ${PROJECT_ROOT}/sls/profile:/opt/sls/profile \
  -v ${PROJECT_ROOT}/sls/package.json:/opt/sls/package.json \
  -v ${PROJECT_ROOT}/sls/package-lock.json:/opt/sls/package-lock.json \
  ${APP_NAME}/sls:latest \
  sls ${SLS_ARGS[@]}