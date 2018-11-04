#! /bin/bash
## 把访问量比较大的IP封掉，如果20分钟内被封的IP没有请求或者请求很少，需要解封

#定义1分钟以前的时间，用于过滤1分钟以前的日志
t1=`date -d "-1 min" +%Y:%H:%M`
log=/data/logs/access_log

block_ip()
{
    egrep "$t1:[0-5]+" $log > /tmp/tmp_last_min.log

    #把1分钟内访问量高于100的ip记录到一个临时文件中
    awk '{print $1}' /tmp/tmp_last_min.log |sort -n |uniq -c|sort -n |awk '$1>100 {print $2}' > /tmp/bad_ip.list

    #计算ip的数量
    n=`wc -l /tmp/bad_ip.list|awk '{print $1}'`

    #当ip数大于0时，才会用iptables封掉它
    if [ $n -ne 0 ]
    then
        for ip in `cat /tmp/bad_ip.list`
        do
            iptables -I INPUT -s $ip -j REJECT
        done
        #将这些被封的IP记录到日志里
        echo "`date` 封掉的IP有：" >> /tmp/block_ip.log
        cat /tmp/bad_ip.list >> /tmp/block_ip.log
    fi
}

unblock_ip()
{
    #首先将包个数小于5的ip记录到一个临时文件里，把它们标记为白名单IP
    iptables -nvL INPUT|sed '1d' |awk '$1<5 {print $8}' > /tmp/good_ip.list
    n=`wc -l /tmp/good_ip.list|awk '{print $1}'`
    if [ $n -ne 0 ]
    then
        for ip in `cat /tmp/good_ip.list`
        do
            iptables -D INPUT -s $ip -j REJECT
        done
        echo "`date` 解封的IP有：" >> /tmp/unblock_ip.log
        cat /tmp/good_ip.list >> /tmp/unblock_ip.log
    fi
    #当解封完白名单IP后，将计数器清零，进入下一个计数周期
    iptables -Z
}

#取当前时间的分钟数
t=`date +%M`

#当分钟数为00或者30时（即每隔30分钟），执行解封IP的函数，其他时间只执行封IP的函数
if [ $t == "00" ] || [ $t == "30" ]
then
   unblock_ip
   block_ip
else
   block_ip
fi
