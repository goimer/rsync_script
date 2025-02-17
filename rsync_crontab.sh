#!/bin/bash

# 检查是否使用 bash
if [ -z "$BASH_VERSION" ]; then
    echo "警告：该脚本必须在 bash 环境中运行。"
    echo "请使用 bash 执行此脚本，例如：bash $0"
    exit 1
fi

# 检查并安装 rsync 和 sshpass（如果未安装）
INSTALL_LOG="rsync 和 sshpass 已安装。"
if ! which rsync > /dev/null; then
    echo "rsync 未安装，正在安装..."
    apt update -y && apt install -y rsync
    INSTALL_LOG="rsync 已安装。"
fi

if ! which sshpass > /dev/null; then
    echo "sshpass 未安装，正在安装..."
    apt update -y && apt install -y sshpass
    INSTALL_LOG="$INSTALL_LOG sshpass 已安装。"
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

# 检查 rsync 是否已经在运行
if pgrep -x "rsync" > /dev/null; then
    echo "[$(date)] 备份任务已经在运行，跳过此次执行。" >> $LOG_FILE
    exit 0
fi

# 循环遍历所有需要备份的目录
for SOURCE_DIR in "${DIRS[@]}"; do
    # 设置目标目录路径
    DEST_DIR="$SFTP_USER@$SFTP_HOST:$SFTP_BASE_DIR$SOURCE_DIR"

    # 写入日志，表示当前目录的备份已开始
    echo "[$(date)] 开始备份 $SOURCE_DIR 到 $DEST_DIR ..."

    # 执行 rsync 备份命令
    nohup sshpass -p "$SFTP_PASSWORD" rsync -avz --delete -e ssh "$SOURCE_DIR" "$DEST_DIR" >> $LOG_FILE 2>&1 &

    # 打印任务已启动的信息
    echo "[$(date)] $SOURCE_DIR 的备份任务已启动，正在后台运行，日志保存在 $LOG_FILE 中。"
done