#!/bin/bash

# 获取当前时间，格式为 年-月-日 时:分:秒
time=$(date "+%Y-%m-%d %H:%M:%S")
# 记录认证尝试时间到日志
echo "try to auth at ${time}" >> /tmp/auth.log

# 执行认证脚本，传入用户名和密码参数
result=$(python "/etc/storage/netlogin.py" "你的学号" "你的校园网密码" "运营商编号（0.校园网 1.中国移动 2.中国联通 3.中国电信）")

# 判断认证脚本是否执行成功
if [ $? -eq 0 ]; then
    # 如果成功，输出成功状态到日志
    echo "state: succeed" >> /tmp/auth.log
else
    # 如果失败，输出失败状态到日志
    echo "state: failed" >> /tmp/auth.log
    echo "up down network adapter and retry" >> /tmp/auth.log

    # 重新启动网络适配器
    ifconfig apclii0 down
    ifconfig apclii0 up

    # 再次尝试执行认证脚本
    result=$(python "/etc/storage/netlogin.py" "你的学号" "你的校园网密码" "运营商编号（0.校园网 1.中国移动 2.中国联通 3.中国电信）")

    # 根据重试结果输出状态
    if [ $? -eq 0 ]; then
        echo "state: succeed (after retry)" >> /tmp/auth.log
    else
        echo "state: failed (after retry)" >> /tmp/auth.log
    fi
fi

# 记录认证结果到日志
echo "result: ${result}" >> /tmp/auth.log

# 重设TTL值，绕过校园网多设备限制
iptables -t mangle -A POSTROUTING -j TTL --ttl-set 128

# 检查日志文件行数，如果超过200行则只保留最后200行
log_file="/tmp/auth.log"
log_length=$(wc -l < "$log_file")
if [[ $log_length -gt 200 ]]; then
    # 使用tail命令保留最后200行，并覆盖原日志文件
    tail -n 200 "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
    echo "[$time] log exceeds 200 lines, keeping only the last 200 lines." >> "$log_file"
fi

