#!/bin/bash
##该脚本用来监控网站的502问题，结合mail.py使用，见README

t=`date -d "-1 min" +"%Y:%H:%M:[0-5][0-9]"`
log="/data/logs/access.log"
#假设mail.py已经写好，并放在/usr/local/sbin/下
mail_script="/usr/local/sbin/mail.py"
mail_user=aming@aminglinux.com

n=`grep $t $log|grep -n " 502 "`
if [ $n -gt 50 ]
then
    python $mail_script $mail_user "网站有502" "1分钟内出现了$n次"
fi
