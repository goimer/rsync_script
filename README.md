# rsync_script
此脚本使用inotify和rsync将多个文件夹从源服务器备份到目标服务器上的指定文件夹。

### 一、使用定时同步

```shell
crontab -e
# 新增一条
*/30 * * * * /backup/rsync_crontab.sh
```

### 二、使用实时同步

```shell
# 新增系统任务
vi /etc/systemd/system/rsync-backup.service
# 增加内容
[Unit]
Description=Rsync Backup Service
After=network.target

[Service]
ExecStart=/bin/bash /backup/rsync.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
# 重载 systemd 配置
systemctl daemon-reload
# 启用开机自启
systemctl enable rsync-backup.service
# 启动脚本
systemctl start rsync-backup.service
# 检查状态
systemctl status rsync-backup.service
```

