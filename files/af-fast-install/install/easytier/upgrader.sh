#!/bin/sh
set -e
trap 'systemctl start easytier.service' EXIT

BASE_DIR="/opt/easytier"
URL_BASE="https://static.itedev.com/files/af-fast-install/install/easytier"
REMOTE_VERSION_URL="$URL_BASE/version"
LOCAL_VERSION_FILE="$BASE_DIR/version"
FILES="easytier-cli easytier-core version"

cd "$BASE_DIR" || {
  echo "$(date +'%F %T') ERROR: 无法进入目录 $BASE_DIR" >&2
  exit 1
}

TMP_REMOTE="$(mktemp /tmp/remote_version.XXXXXX)"
curl -fsSL -H "Cache-Control: no-cache" "$REMOTE_VERSION_URL" -o "$TMP_REMOTE"

LOCAL_VER=""
[ -f "$LOCAL_VERSION_FILE" ] && LOCAL_VER=$(cat "$LOCAL_VERSION_FILE")
REMOTE_VER=$(cat "$TMP_REMOTE")

echo "$(date +'%F %T') 本地版本: '$LOCAL_VER', 远程版本: '$REMOTE_VER'"

if [ "$LOCAL_VER" = "$REMOTE_VER" ]; then
  echo "$(date +'%F %T') 版本一致，跳过更新"
  rm -f "$TMP_REMOTE"
  exit 0
fi

echo "$(date +'%F %T') 检测到新版本，开始更新..."
systemctl stop easytier.service

for f in $FILES; do
  echo "$(date +'%F %T') 正在下载 $f ..."
  TMP_DL="$(mktemp "/tmp/${f}.XXXXXX")"
  curl -fsSL -H "Cache-Control: no-cache" "$URL_BASE/$f" -o "$TMP_DL"

  # 如果已有文件则对比 MD5
  if [ -f "$BASE_DIR/$f" ]; then
    OLD_MD5=$(md5sum "$BASE_DIR/$f" | awk '{print $1}')
    NEW_MD5=$(md5sum "$TMP_DL" | awk '{print $1}')
    if [ "$OLD_MD5" = "$NEW_MD5" ]; then
      echo "$(date +'%F %T') $f 内容未变化，跳过替换"
      rm -f "$TMP_DL"
      continue
    fi
  fi

  mv "$TMP_DL" "$BASE_DIR/$f"
done

chmod +x "$BASE_DIR"/easytier-*

echo "$(date +'%F %T') 更新完成，新版本: '$REMOTE_VER'"
rm -f "$TMP_REMOTE"
exit 0
