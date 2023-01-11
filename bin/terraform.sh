#!/bin/bash

function usage {
cat >&2 <<EOF
terraformコマンド

[usage]
 $0 [options] -- [SLS_ARG1] [SLS_ARG2] [SLS_ARG3] ...

[options]
 -h | --help:
   ヘルプを表示
 --stage <STAGE_NAME>: (required)
   terraformのステージ名を指定
 --profile <AWS_PROFILE>:
   awsのプロファイル名を指定 (default=default)
 --region <AWS_REGION>:
   awsのリージョンを指定 (default=ap-northeast-1)
 --proxy:
   プロキシ設定を有効化

[example]
  ヘルプ
    $0 --stage dev -- -help
  初期化
    $0 --stage dev -- init
EOF
exit 1
}

PROJECT_ROOT="$(cd $(dirname $0)/..; pwd)"
source "${PROJECT_ROOT}/bin/lib/utils.sh"

APP_NAME=$(get_app_name ${PROJECT_ROOT}/app_name)

AWS_PROFILE="default"
AWS_REGION="ap-northeast-1"
PROXY=
STAGE=
TERRAFORM_ARGS=()
while [ "$#" != 0 ]; do
  case $1 in
    -h | --help ) usage;;
    --proxy     ) PROXY="1";;
    --profile   ) shift; AWS_PROFILE="$1";;
    --region    ) shift; AWS_REGION="$1";;
    --stage     ) shift; STAGE="$1";;
    --          ) shift; TERRAFORM_ARGS+=($@); break;;
    -* | --*    ) error "$1 : 不正なオプションです";;
  esac
  shift
done

[ -z "$STAGE" ] && error "--stage オプションを指定してください"

set -e

# イメージビルド
BUILD_OPTIONS="$BUILD_OPTIONS --build-arg host_uid=$(id -u)"
BUILD_OPTIONS="$BUILD_OPTIONS --build-arg host_gid=$(id -g)"
if [ -n "$PROXY" ]; then
  BUILD_OPTIONS="$BUILD_OPTIONS --build-arg proxy=$proxy --build-arg no_proxy=$no_proxy"
fi
invoke docker build $BUILD_OPTIONS -q --rm -f docker/terraform/Dockerfile -t ${APP_NAME}/terraform:latest .

# 環境変数ファイル生成
env_tmp="$(mktemp)"
trap "rm $env_tmp" EXIT
AWS_ACCESS_KEY_ID=$(aws --profile $AWS_PROFILE --region $AWS_REGION configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws --profile $AWS_PROFILE --region $AWS_REGION configure get aws_secret_access_key)
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> "$env_tmp"
echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> "$env_tmp"
if [ -n "$PROXY" ]; then
  echo "http_proxy=$proxy" >> "$env_tmp"
  echo "https_proxy=$proxy" >> "$env_tmp"
  echo "NO_PROXY=$no_proxy" >> "$env_tmp"
fi

# terraformコマンド実行
invoke docker run -ti --rm \
  --env-file "$env_tmp" \
  --user app \
  -w /terraform \
  -v ${PROJECT_ROOT}/terraform/stage/$STAGE:/terraform \
  ${APP_NAME}/terraform:latest \
  ${TERRAFORM_ARGS[@]}