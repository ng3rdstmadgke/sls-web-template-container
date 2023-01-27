# TODO

- IaCの整備
  - RDS
  - Secrets Manager
    - RDSの接続情報
    - JWTの秘密鍵

# インストール

```bash
# nvm install
# https://github.com/nvm-sh/nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# node.jsの最新のltsをインストール
nvm install --lts
nvm use --lts
node -v
npm -v

# npm update
npm update -g npm

# serverless install
cd sls-web-template
npm install
```

# デプロイ

## terraformデプロイ
```bash
STAGE_NAME=dev

# terraformのプロジェクト作成
cp -r terraform/stage/mi1 terraform/stage/$STAGE_NAME

# シークレットファイル作成
cp terraform/stage/$STAGE_NAME/secrets.auto.tfvars.sample terraform/stage/$STAGE_NAME/secrets.auto.tfvars

# シークレット情報の定義
vim terraform/stage/$STAGE_NAME/secrets.auto.tfvars

# エントリーポイントの設定を変更
#   変更が必要な項目
#   - terraform.backend.s3.bucket
#   - terraform.backend.s3.key
#   - locals配下の変数
vim terraform/stage/$STAGE_NAME/main.tf

# 変更をコミット

# terraformデプロイ
./bin/terraform.sh -s $STAGE_NAME -- apply
```

## DBマイグレーション

```bash
# 開発用コンテナのビルド
./bin/build.sh

# 環境変数ファイル作成
cp app/sample.env app/${STAGE_NAME}.env
vim app/${STAGE_NAME}.env

# 開発用shellにログイン
./bin/shell.sh -e 環境変数ファイル名

#
# 以下開発用shell内で実行
#
# DB作成
./bin/create-database.sh

# マイグレーション
(cd api; alembic upgrade head)

# スーパーユーザー作成
./bin/manage.sh create_user admin --superuser

# devコンテナからログアウト
exit
```


## slsデプロイ
```bash
# ${APP_NAME}/lambda/ステージ名 で ECR リポジトリ作成

# イメージのビルドとpush
./bin/push-image.sh -s $STAGE_NAME

# プロファイル作成
cp ./sls/profile/sample.yml ./sls/profile/${STAGE_NAME}.yml
vim ./sls/profile/${STAGE_NAME}.yml

# デプロイ
./bin/sls.sh -- deploy --stage ${STAGE_NAME}

# 削除
./bin/sls.sh -- remove --stage ${STAGE_NAME}
```

# 開発環境
## イメージビルド

```bash
./bin/build.sh
```

## 開発用データベース起動

```bash
./bin/run-mysql.sh -d
```

## マイグレーションなど

```bash
# devコンテナ起動
./bin/shell.sh -e app/local.env
```

devコンテナ内での操作

```bash
# DB作成
/opt/app/bin/create-database.sh

# マイグレーション
alembic upgrade head

# スーパーユーザー作成
/opt/app/bin/manage.sh create_user admin --superuser

# devコンテナからログアウト
exit
```

## アプリ起動

```bash
# アプリ起動 (開発モード)
./bin/run.sh --debug -e app/local.env

# アプリ起動 (本番モード)
./bin/run.sh -e app/local.env

# アクセス
# http://localhost:3000/
# http://localhost:8000/api/docs
```

## テスト

```bash
# 開発用イメージビルド
./bin/build.sh

# 開発用データベース起動
./bin/run-mysql.sh -d

# devコンテナ起動
./bin/shell.sh -e app/local.env
```

devコンテナ内での操作

```bash
# テスト実行
./bin/test.sh
```

# 運用

## devコンテナ起動

```bash
# 開発用データベース起動
./bin/run-mysql.sh -d

# devコンテナ起動
./bin/shell.sh -e <ENV_PATH>

```

## マイグレーション(devコンテナ内での操作)

```bash
cd api

# DB作成
./bin/create-database.sh

# マイグレーション: 履歴確認
alembic history -v

# マイグレーション: 最新バージョンにアップグレード
alembic upgrade head

# マイグレーション: 次のバージョンにアップグレード
alembic upgrade +1

# マイグレーション: 最初のバージョンにダウングレード
alembic downgrade base

# マイグレーション: 次のバージョンにダウングレード
alembic downgrade -1

# マイグレーション: マイグレーションファイル生成
alembic revision --autogenerate -m "message"
```

## DBログイン(devコンテナ内での操作)

```bash
# DB作成
./bin/create-database.sh

# mysql ログイン
./bin/mysql.sh
```

## マネジメントコマンド(devコンテナ内での操作)

```bash
# ヘルプ
./bin/manage.sh

# スーパーユーザー作成
./bin/manage.sh create_user admin --superuser

# 通常ユーザー作成
./bin/manage.sh create_user user1
./bin/manage.sh create_user user2
```