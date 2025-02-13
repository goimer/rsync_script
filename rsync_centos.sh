#!/bin/bash

set -e

# 检查是否使用 bash
if [ -z "$BASH_VERSION" ]; then
    echo "警告：该脚本必须在 bash 环境中运行。"
    echo "请使用 bash 执行此脚本，例如：bash $0"
    exit 1
fi

# 检查并安装必要的软件包
INSTALL_LOG=""
for pkg in rsync sshpass; do
    if ! which $pkg > /dev/null; then
        echo "$pkg 未安装，正在安装..."
        yum update -y && yum install -y $pkg
        INSTALL_LOG="$INSTALL_LOG $pkg 已安装。"
    else
        INSTALL_LOG="$INSTALL_LOG $pkg 已安装。"
    fi
done

# 检查 inotifywait 是否存在，如果不存在则安装 inotify-tools
if ! which inotifywait > /dev/null; then
    echo "inotifywait 未安装，正在安装 inotify-tools..."
    yum update -y && yum install epel-release && yum install -y inotify-tools
    INSTALL_LOG="$INSTALL_LOG inotify-tools 已安装。"
else
    INSTALL_LOG="$INSTALL_LOG inotifywait 已安装。"
fi

echo "$INSTALL_LOG"

# 配置 SFTP 信息
SFTP_USER="sftpuser"
SFTP_HOST="192.168.3.1"
SFTP_BASE_DIR="/backup"
SFTP_PASSWORD="123456"

# 配置需要备份的目录（可以添加更多目录）
DIRS=(
    "/data/"
)

# 获取当前日期（格式：2024-12-29）
CURRENT_DATE=$(date +'%Y-%m-%d')

# 日志文件，按日期生成日志文件
LOG_DIR="/backup/rsync_log"
LOG_FILE="$LOG_DIR/rsync_$CURRENT_DATE.log"

# 检查日志目录是否存在，如果不存在则创建
if [ ! -d "$LOG_DIR" ]; then
    echo "日志目录不存在，正在创建..."
    mkdir -p "$LOG_DIR"
fi

# 定义同步函数
sync_directory() {
    local SOURCE_DIR=$1
    local DEST_DIR="$SFTP_USER@$SFTP_HOST:$SFTP_BASE_DIR$SOURCE_DIR"

    echo "[$(date)] 开始同步 $SOURCE_DIR 到 $DEST_DIR ..."
    sshpass -p "$SFTP_PASSWORD" rsync -avz -e ssh "$SOURCE_DIR" "$DEST_DIR" >> $LOG_FILE 2>&1
    echo "[$(date)] $SOURCE_DIR 同步完成。"
}

# 初始同步所有目录
for SOURCE_DIR in "${DIRS[@]}"; do
    sync_directory "$SOURCE_DIR"
done

# 启动 inotifywait 监控
for SOURCE_DIR in "${DIRS[@]}"; do
    (
        inotifywait -m -r -e modify,create,delete,move "$SOURCE_DIR" | while read path action file; do
            # 捕获到文件变动时直接执行同步
            sync_directory "$SOURCE_DIR"
        done
    ) &
done


# 保存所有后台进程的 PID
PIDS=$!

# 捕获 SIGINT 和 SIGTERM 信号
trap 'kill $PIDS; exit' SIGINT SIGTERM

# 等待所有后台进程
wait
