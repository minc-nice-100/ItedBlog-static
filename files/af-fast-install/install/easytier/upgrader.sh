#!/bin/sh
# 设置变量
URL_BASE="https://static.itedev.com/files/af-fast-install/install/easytier"
REMOTE_VERSION_URL="$URL_BASE/version"
LOCAL_VERSION_FILE="./version"
FILES="easytier-cli easytier-core version"
SERVICE="easytier.service"
TMP_REMOTE="/tmp/remote_version.$$"

# 获取远程 version 文件
if ! curl -fsSL "$REMOTE_VERSION_URL" -o "$TMP_REMOTE"; then
  echo "$(date +'%F %T') ERROR: 无法下载远程版本文件 $REMOTE_VERSION_URL" >&2
  exit 1
fi

# 读取本地版本
if [ -f "$LOCAL_VERSION_FILE" ]; then
  LOCAL_VER=$(cat "$LOCAL_VERSION_FILE")
else
  LOCAL_VER=""
fi

REMOTE_VER=$(cat "$TMP_REMOTE")

echo "$(date +'%F %T') 本地版本: '$LOCAL_VER', 远程版本: '$REMOTE_VER'"

# 比较版本
if [ "$REMOTE_VER" = "$LOCAL_VER" ]; then
  echo "$(date +'%F %T') 版本一致，跳过更新。"
  rm -f "$TMP_REMOTE"
  exit 0
fi

echo "$(date +'%F %T') 版本不同，进行更新..."

# 停止服务
if ! systemctl stop "$SERVICE"; then
  echo "$(date +'%F %T') ERROR: 停止服务失败: $SERVICE" >&2
  exit 1
fi

# 依次下载最新文件并覆盖
for f in $FILES; do
  URL="$URL_BASE/$f"
  if ! curl -fsSL "$URL" -o "./$f"; then
    echo "$(date +'%F %T') ERROR: 无法下载 $URL" >&2
    # 可选：考虑 roll-back 或继续尝试
    exit 1
  fi
done

# 授予执行权限
chmod +x ./easytier-* || {
  echo "$(date +'%F %T') WARNING: 无法更改可执行权限" >&2
}

# 启动服务
if ! systemctl start "$SERVICE"; then
  echo "$(date +'%F %T') ERROR: 启动服务失败: $SERVICE" >&2
  exit 1
fi

echo "$(date +'%F %T') 更新成功，当前版本: '$REMOTE_VER'"

rm -f "$TMP_REMOTE"
exit 0
