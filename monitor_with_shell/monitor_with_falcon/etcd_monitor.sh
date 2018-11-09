#!/bin/bash

monit_keys=`curl --cacert /home/etcd/ca/ca.pem --cert /home/etcd/ca/client.pem --key /home/etcd/ca/client-key.pem https://127.0.0.1:2379/metrics 2>/dev/null |grep -v '#'`
ts=`date +%s`;

#"领导者是否存在; 领导者变化的数量; 共识提案的总数; 共识提案的总数; 目前正在处理的提案数量; 失败提案总数; wal调用的fsync总延迟时间; 后端调用总延迟时间; 发送给具有ID的对等体的总字节数; 发送给grpc客户端的总字节数; 接收到grpc客户端的总
字节数; 同级之间总的往返时间; 打开文件描述符的数量; 允许打开文件描述符的最大数量"
items="etcd_server_has_leader etcd_server_leader_changes_seen_total etcd_server_proposals_applied_total etcd_server_proposals_committed_total etcd_server_proposals_failed_total etcd_server_proposals_pending etcd_disk_wal_fsync_duration_seconds_count etcd_disk_backend_commit_duration_seconds_count etcd_network_peer_sent_bytes_total etcd_network_client_grpc_received_bytes_total etcd_network_client_grpc_sent_bytes_total etcd_network_peer_round_trip_time_seconds_count process_open_fds process_max_fds"

for item in $items;do

  valus=`echo $monit_keys|xargs -n2 |grep "$item" |awk '{print $2}'`

  if [ $item == etcd_network_peer_sent_bytes_total ];then
    valus=`echo $valus |awk '{print $1}' |awk -F'e+' '{print $1}'`
    valus=$(printf "%.f" `echo "$valus*10000000"|bc`)
  fi

  if [ $item == etcd_network_peer_received_bytes_total ];then
    valus=`echo $valus |awk '{print $1}' |awk -F'e+' '{print $1}'`
    valus=$(printf "%.f" `echo "$valus*1000000"|bc`)
  fi

  if [ $item == etcd_network_peer_round_trip_time_seconds_count ];then
    valus=`echo $valus |awk '{print $1}'`
  fi

  curl -X POST -d "[{\"metric\": \"$item\", \"endpoint\": \"{{ cluster_name }}\", \"timestamp\": $ts,\"step\": 60,\"value\": $valus,\"counterType\": \"GAUGE\",\"tags\": \"etcd_cluster={{ cluster_name }},service=etcd\"}]" http://127.0.0.1:1988/v1/push

done