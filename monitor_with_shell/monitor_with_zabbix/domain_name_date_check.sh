#!/bin/bash
#检测域名是否过期

mail_u=admin@admin.com
#当前日期时间戳，用于和域名的到期时间做比较
t1=`date +%s`

#检测whois命令是否存在，不存在则安装jwhois包
is_install_whois()
{
    which whois >/dev/null 2>/dev/null
    if [ $? -ne 0 ]
    then
        yum install -y whois
    fi
}

notify()
{
    e_d=`whois $1|grep 'Expiry Date'|awk '{print $4}'|cut -d 'T' -f 1`
    #如果e_d的值为空，则过滤关键词'Expiration Time'
    if [ -z "$e_d" ]
    then
        e_d=`whois $1|grep 'Expiration Time'|awk '{print $3}'`
    fi
    #将域名过期的日期转化为时间戳
    e_t=`date -d "$e_d" +%s`
    #计算一周一共有多少秒
    n=`echo "86400*7"|bc`
    e_t1=$[$e_t-$n]
    e_t2=$[$e_t+$n]
    if [ $t1 -ge $e_t1 ] && [ $t1 -lt $e_t ]
    then
        python mail.py  $mail_u "Domain $1 will  to be expired." "Domain $1 expire date is $e_d."
    fi
    if [ $t1 -ge $e_t ] && [ $t1 -lt $e_t2 ]
    then
        python mail.py $mail_u "Domain $1 has been expired" "Domain $1 expire date is $e_d." 
    fi
}

#检测上次运行的whois查询进程是否存在
#若存在，需要杀死进程，以免影响本次脚本执行
if pgrep whois &>/dev/null
then
    killall -9 whois
fi

is_install_whois

for d in aaa.net aaa.com bbb.com  aaa.cn ccc.com
do
    notify $d &
done

