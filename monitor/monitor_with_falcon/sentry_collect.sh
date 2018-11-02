#!/bin/bash
#sentry数量统计

apis="3 24"
for api in $apis;do
  ts=`date +%s`;
  t=`LC_ALL=en_US.UTF-8 date '+%d/%b/%Y:%H:%M' -d "-1 minute"`  # 每分钟采集一次日志
  if [ $api -eq 3 ];then
    project=medweb_online
  elif [ $api -eq 24 ];then
    project=op
  fi
  valus=`tail -1000000 /usr/local/nginx/logs/access.log |egrep 'sentry.chunyu.me' |egrep $t |egrep 'POST'|egrep "/api/$api/" |wc -l`
  curl -X POST -d "[{\"metric\": \"sentry\", \"endpoint\": \"sentry\", \"timestamp\": $ts,\"step\": 60,\"value\": $valus,\"type\":\"sentry\",\"counterType\": \"GAUGE\",\"tags\": \"project=$project\"}]" http://127.0.0.1:1988/v1/push
done
# 注意："tail -1000000" 根据nginx访问量配置数值