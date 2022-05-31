#!/bin/bash
##监控磁盘使用情况，并做告警收敛（30分钟发一次邮件）

#把脚本名字存入变量s_name
s_name=`echo $0|awk -F '/' '{print $NF}'`
#定义收件人邮箱
mail_user=admin@admin.com

# 定义检查磁盘空间使用率函数
chk_sp() 
{
    
    df -m|sed '1d' |awk -F '%| +' '$5>90 {print $7,$5}'>/tmp/chk_sp.log 
    n=`wc -l /tmp/chk_sp.log|awk '{print $1}'`
    if [ $n -gt 0 ]
    then 
        tag=1
        for d in `awk '{print $1}' /tmp/chk_sp.log`
        do
            find $d -type d |sed '1d'|xargs du -sm |sort -nr |head -3 
        done > /tmp/most_sp.txt
    fi
}

# 定义检查inode使用率函数
chk_in()
{
    df -i|sed '1d'|awk -F '%| +' '$5>90 {print $7,$5}'>/tmp/chk_in.log
        n=`wc -l /tmp/chk_in.log|awk '{print $1}'`
        if [ $n -gt 0 ]
        then
                tag=2
        fi
}

# 定义告警函数（这里的mail.py是案例二中那个脚本）
m_mail() {
    log=$1
    t_s=`date +%s`
    t_s2=`date -d "1 hours ago" +%s`
    if [ ! -f /tmp/$log ]
    then
        #创建$log文件
        touch /tmp/$log 
        #增加a权限，只允许追加内容，不允许更改或删除
        chattr +a /tmp/$log
        #第一次告警，可以直接写入1小时以前的时间戳
        echo $t_s2 >> /tmp/$log
    fi
    #无论$log文件是否是刚刚创建，都需要查看最后一行的时间戳
    t_s2=`tail -1 /tmp/$log|awk '{print $1}'`
    #取出最后一行即上次告警的时间戳后，立即写入当前的时间戳
    echo $t_s>>/tmp/$log
    #取两次时间戳差值
    v=$[$t_s-$t_s2]
    #如果差值超过1800，立即发邮件
    if [ $v -gt 1800 ]
    then
        #发邮件，其中$2为mail函数的第二个参数，这里为一个文件
        python mail.py $mail_user "磁盘使用率超过90%" "`cat $2`"  2>/dev/null   
        #定义计数器临时文件，并写入0         
        echo "0" > /tmp/$log.count
    else
        #如果计数器临时文件不存在，需要创建并写入0
        if [ ! -f /tmp/$log.count ]
        then
            echo "0" > /tmp/$log.count
        fi
        nu=`cat /tmp/$log.count`
        #30分钟内每发生1次告警，计数器加1
        nu2=$[$nu+1]
        echo $nu2>/tmp/$log.count
        #当告警次数超过30次，需要再次发邮件
        if [ $nu2 -gt 30 ]
        then
             python mail.py $mail_user "磁盘使用率超过90%持续30分钟了" "`cat $2`" 2>/dev/null  
             #第二次告警后，将计数器再次从0开始          
             echo "0" > /tmp/$log.count
        fi
    fi
}

#把进程情况存入临时文件，如果加管道求行数会有问题
ps aux |grep "$s_name" |grep -vE "$$|grep">/tmp/ps.tmp
p_n=`wc -l /tmp/ps.tmp|awk '{print $1}'`

#当进程数大于0，则说明上次的脚本还未执行完
if [ $p_n -gt 0 ]
then
    exit
fi

chk_sp
chk_in

if [ $tag == 1 ]
then
    m_mail chk_sp /tmp/most_sp.txt
elif [ $tag == 2 ]
then
        m_mail chk_in /tmp/chk_in.log
fi

