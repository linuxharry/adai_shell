#!/bin/bash
#多线程备份数据库

##假设100个库的库名、host、port以及配置文件路径存到了一个文件里，文件名字为/tmp/databases.list
##格式：db1 10.10.10.2 3308 /data/mysql/db1/my.cnf
##备份数据库使用xtrabackup（由于涉及到myisam，命令为inoobackupex）

exec &> /tmp/mysql_bak.log

if ! which innobackupex &>/dev/nll
then
    echo "安装xtrabackup工具"
    rpm -ivh http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm  && \
    yum install -y percona-xtrabackup-24
    if [ $? -ne 0 ]
    then
        echo "安装xtrabackup工具出错，请检查。"
        exit 1
    fi
fi

bakdir=/data/backup/mysql
bakuser=vyNctM
bakpass=99omeaBHh

function bak_data {
    db_name=$1
    db_host=$2
    db_port=$3
    cnf=$4
    [ -d $bakdir/$db_name ] || mkdir -p $bakdir/$db_name
    innobackupex --defaults-file=$4  --host=$2  --port=$3 --user=$bakuser --password=$bakpass  $bakdir/$1
        if [ $? -ne 0 ]
        then
            echo "备份数据库$1出现问题。"
        fi
}

fifofile=/tmp/$$
mkfifo $fifofile
exec 1000<>$fifofile


thread=10
for ((i=0;i<$thread;i++))
do
    echo >&1000
done

cat /tmp/databases.list | while read line
do
    read -u1000
    {
        bak_data `echo $line`
        echo >&1000
    } &
done

wait
exec 1000>&-
rm -f $fifofile
