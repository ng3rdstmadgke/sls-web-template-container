#!/bin/bash
HOST_UID=${LOCAL_UID}
HOST_GID=${LOCAL_GID}

UNAME="front"

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

# マウント先のを所有者作成したユーザーとグループに変更
chown -R $HOST_UID:$HOST_GID /opt/app

export HOME=/home/$UNAME

# nuxt 開発 server 起動
exec su $UNAME -c "cd /opt/app/front && npm install && npm run dev"