# TODO

- IaCの整備
  - RDS
  - Secrets Manager
    - RDSの接続情報
    - JWTの秘密鍵
- slsコマンドコンテナ化
  - devコンテナに組み込む

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

```bash
STAGE_NAME=mi1

# /sls-web-template/lambda/ステージ名 で ECR リポジトリ作成

# イメージのビルドとpush
./bin/push-image.sh -s $STAGE_NAME

# プロファイル作成
cp ./profile/sample.yml ./profile/${STAGE_NAME}.yml
vim ./profile/${STAGE_NAME}.yml

# デプロイ
sls deploy --stage ${STAGE_NAME}

# 削除
sls remove --stage ${STAGE_NAME}
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
/opt/app/bin/alembic.sh upgrade head

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
# DB作成
./bin/create-database.sh

# マイグレーション: 履歴確認
./bin/alembic.sh history -v

# マイグレーション: 最新バージョンにアップグレード
./bin/alembic.sh upgrade head

# マイグレーション: 次のバージョンにアップグレード
./bin/alembic.sh upgrade +1

# マイグレーション: 最初のバージョンにダウングレード
./bin/alembic.sh downgrade base

# マイグレーション: 次のバージョンにダウングレード
./bin/alembic.sh downgrade -1

# マイグレーション: マイグレーションファイル生成
./bin/alembic.sh revision --autogenerate -m "message"
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