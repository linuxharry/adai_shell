#!/bin/bash
# 截取两个关键词中间的行

#先获取abc和123所在行的行号
egrep -n 'abc|123' 1.txt |awk -F ':' '{print $1}' > /tmp/line_number.txt

#计算一共有多少包含abc和123的行
n=`wc -l /tmp/line_number.txt|awk '{print $1}'`

#计算一共有多少对abc和123
n2=$[$n/2]

for i in `seq 1 $n2`
do
    #每次循环都要处理两行，第一次是1,2，第二次是3,4，依此类推
    m1=$[$i*2-1]
    m2=$[$i*2]

    #每次遍历都要获取abc和123的行号
    nu1=`sed -n "$m1"p /tmp/line_number.txt`
    nu2=`sed -n "$m2"p /tmp/line_number.txt`

    #获取abc下面一行的行号
    nu3=$[$nu1+1]

     #获取123上面一行的行号
    nu4=$[$nu2-1]
    
    #用sed把abc和123中间的行打印出来
    sed -n "$nu3,$nu4"p 1.txt

    #便于分辨，添加分隔行符号
    echo "============="
done


## 测试文本1.txt
```
alskdfkjlasldkjfabalskdjflkajsd
asldkfjjk232k3jlk2
alskk2lklkkabclaksdj
skjjfk23kjalf09wlkjlah lkaswlekjl9
aksjdf
123asd232323
aaaaaaaaaa
222222222222222222
abcabc12121212
fa2klj
slkj32k3j
22233232123
bbbbbbb
ddddddddddd
```

