# 燕山大学校园网 OpenWrt 自动认证方案

这个项目提供了一个为燕山大学校园网设计的 OpenWrt 自动认证解决方案。它能够自动处理校园网的认证过程，使您的设备保持持续在线状态。

## 功能特性

- 自动进行校园网认证
- 持续监控网络状态，在需要时重新认证
- 处理认证失败情况，包括重启网络适配器和路由器
- 智能处理学校自动断网时间
- 记录认证过程和结果
- 自动管理日志文件大小
- 通过修改 TTL 值来绕过校园网多设备限制

## 安装指南

1. 将 `netlogin.py`、`auth.sh` 和 `daemon.sh` 文件上传到您的 OpenWrt 设备的 `/etc/storage/` 目录。

2. 确保您的 OpenWrt 设备已安装 Python。

3. 给予脚本执行权限：
   ```
   chmod +x /etc/storage/auth.sh /etc/storage/daemon.sh
   ```

## 配置说明

### 配置 auth.sh

1. 打开 `auth.sh` 文件进行编辑：
   ```
   vi /etc/storage/auth.sh
   ```

2. 在文件中找到以下行，并替换相应的信息：
   ```bash
   result=$(python "/etc/storage/netlogin.py" "你的学号" "你的校园网密码" "运营商编号")
   ```
   
   将 "你的学号" 替换为您的学号，"你的校园网密码" 替换为您的校园网密码，"运营商编号" 替换为相应的数字：
   - 0: 校园网
   - 1: 中国移动
   - 2: 中国联通
   - 3: 中国电信

3. 保存并退出文件。
4. 如果您的 OpenWrt 设备重置网络适配器的方式不一致（如 18.06 以上的高版本系统），可能需要您重新编写一部分脚本。

### 配置 daemon.sh

1. 打开 `daemon.sh` 文件进行编辑：
   ```
   vi /etc/storage/daemon.sh
   ```

2. 根据需要调整以下参数：
   - `start_hour` 和 `end_hour`：设置学校自动断网的时间段（默认配置即已适合燕山大学校园网环境）
   - `max_attempts`：设置最大重试次数

3. 配置其中含绝对路径的脚本文件路径（可选）：
   ```shell
   python /etc/storage/netlogin.py logout
   /etc/storage/auth.sh # 将此处和上方替换为你认证脚本的位置
   ```

4. 保存并退出文件。

### 设置定时任务

为了确保脚本定期运行，我们需要设置 cron 任务：

1. 打开 crontab 进行编辑：
   ```
   crontab -e
   ```

2. 添加以下行来每1分钟运行一次 daemon 脚本：
   ```
   */1 * * * * /etc/storage/daemon.sh
   ```

3. 保存并退出。

## 使用方法

配置完成后，`daemon.sh` 脚本将每1分钟自动运行一次，检查网络状态并在需要时进行认证。您可以查看 `/tmp/network_check.log` 文件来检查网络状态和认证结果。

## 脚本说明

### auth.sh
这个脚本负责执行实际的认证过程。它调用 `netlogin.py` 进行认证，并在失败时重启网络适配器再次尝试。

### daemon.sh
这个脚本是主要的守护进程，它负责：
- 检查当前时间是否在学校自动断网时间段内
- 定期检查网络连接状态
- 在需要时调用 `auth.sh` 进行认证
- 如果多次认证失败，将重启路由器
- 管理日志文件大小

## 故障排除

- 如果遇到认证问题，请检查您的学号、密码和运营商编号是否正确。
- 确保 `netlogin.py`、`auth.sh` 和 `daemon.sh` 文件都存在且有正确的执行权限。
- 检查 `/tmp/auth.log` 和 `/tmp/network_check.log` 文件以获取详细的错误信息。
- 如果脚本在自动断网时间段内未按预期工作，请检查 `daemon.sh` 中的 `start_hour` 和 `end_hour` 设置。

## 贡献

欢迎提交问题报告和改进建议。如果您想贡献代码，请提交 pull request。

## 许可证

本项目采用 GPL（GNU General Public License）开源许可证。您可以自由地使用、修改和分发本软件，但必须保持开源并使用相同的许可证。详细信息请参阅 [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.en.html)。

## 免责声明

本项目仅供学习和研究使用。使用本脚本可能违反校园网使用规定，使用者需自行承担风险。作者不对使用本脚本导致的任何问题负责。