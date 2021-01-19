#!/bin/sh
# 2021-01
# mysql backup
# 50 23 * * * root /bin/bash /root/scripts/mysql_backup.sh
# 需要预装阿里云 ossutil 工具

backup_dir=/mnt/data/backups
ts=`date +%Y-%m-%d_%H%M%S`
# endpoint=`hostname`

if [ ! -d $backup_dir ];then
  mkdir -p $backup_dir
fi

mysqldump -uroot -p'JArcLUe2VyfG2vtr'  --single-transaction --all-databases |gzip > $backup_dir/$ts.gz

# 备份至阿里云oss
/usr/bin/ossutil --config-file /usr/local/ossutil/config  cp $backup_dir/$ts.gz  oss://bbmm-op/backups/wiki-jira-mysql/

if [[ $? != 0 ]];then
  curl 'https://oapi.dingtalk.com/robot/send?access_token=*5f621c7e6c5b8*' \
   -H 'Content-Type: application/json' \
   -d '{"msgtype": "text","text": {"content": "dev数据库备份失败！！！"}}'
else
  #curl 'https://oapi.dingtalk.com/robot/send?access_token=11ea1a204b09d89e758276816fc867515f621c7e6c5b833a9e2eea13beded114' \
  # -H 'Content-Type: application/json' \
  # -d '{"msgtype": "text","text": {"content": "dev数据库备份成功！！！"}}'
  find $backup_dir -mtime +7 -name '*.gz' |xargs rm -rf
fi