#!/bin/bash
# 日志文件路径
log_file="/tmp/network_check.log"
# 自动断网时间段
start_hour=23
end_hour=5
# 获取当前时间和星期几（1 = 周一，7 = 周日）
current_time=$(date +'%Y-%m-%d %H:%M:%S')
current_hour=$(date +'%H')
current_day=$(date +'%u') # 1 = 周一，7 = 周日
# 记录当前时间和当前星期几到日志
echo "[$current_time] 开始检查网络，今天是星期 $current_day。" >> "$log_file"
# 如果是学校的自动断网时间段，且不是周五或周六，跳过操作
if [[ ($current_hour -ge $start_hour || $current_hour -lt $end_hour) && ($current_day -ne 5 && $current_day -ne 6) ]]; then
    echo "[$current_time] 当前时间为学校自动断网时间，不进行任何操作。" >> "$log_file"
    exit 0
fi
# 最大重试次数
max_attempts=10
# 重试计数
attempt=0
# 请求百度并检查网络状态
while [[ $attempt -lt $max_attempts ]]; do
    echo "[$current_time] 尝试连接网络 (第 $((attempt+1))/$max_attempts 次尝试)..." >> "$log_file"
    
    # 使用curl获取页面内容，并捕获退出状态
    response=$(curl -s --connect-timeout 5 http://baidu.com)
    curl_exit_code=$?
    
    # 检查curl是否超时或者进入认证页面
    if [[ $curl_exit_code -eq 28 ]] || echo "$response" | grep -q "auth.ysu.edu.cn"; then
        echo "[$current_time] 检测到网络问题或需要认证，尝试重新认证..." >> "$log_file"
        # 执行认证操作
        python netlogin.py logout
        ./auth.sh
        
        # 等待5秒
        sleep 5
    else
        echo "[$current_time] 网络正常。" >> "$log_file"
        exit 0
    fi
    # 增加重试计数
    attempt=$((attempt+1))
done
# 如果尝试了10次仍然失败，重启路由器
if [[ $attempt -eq $max_attempts ]]; then
    echo "[$current_time] 多次尝试认证失败，准备重启路由器..." >> "$log_file"
    reboot
fi
# 检查日志文件长度，并保留最后200行
log_length=$(wc -l < "$log_file")
if [[ $log_length -gt 200 ]]; then
    tail -n 200 "$log_file" > "$log_file.tmp" && mv "$log_file.tmp" "$log_file"
    echo "[$current_time] 日志文件超过200行，只保留最后200行。" >> "$log_file"
fi
