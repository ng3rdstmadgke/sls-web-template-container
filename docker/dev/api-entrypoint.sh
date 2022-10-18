#!/bin/bash
HOST_UID=${LOCAL_UID}
HOST_GID=${LOCAL_GID}

UNAME="app"

# グループIDを指定してグループを作成
# -g: グループIDを指定する
groupadd -g $HOST_GID $UNAME

# ユーザーIDを指定してグループを作成
# -u: ユーザーIDを指定
# -o: ユーザーIDが同じユーザーの作成を許す
# -m: ホームディレクトリを作成する
# -g: ユーザーが属するプライマリグループを指定する(グループID or グループ名)
# -s: ログインシェルを指定する
useradd -u $HOST_UID -o -m -g $HOST_GID -s /bin/bash $UNAME

# sysadmin グループに追加
usermod -aG sysadmin $UNAME

mkdir -p /opt/app/front_dist

# マウント先のを所有者作成したユーザーとグループに変更
chown -R $HOST_UID:$HOST_GID /opt/app

export HOME=/home/$UNAME

# 作成したユーザーでアプリケーションサーバーを起動
exec su $UNAME -c "printenv && uvicorn api.main:app --log-config api/log_config.yml --reload"