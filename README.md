**使用 SourceMod 1.11 的编译器进行编译**

安装插件:将编译好的 player_connection_logger.smx 文件放入 addons/sourcemod/plugins/ 目录


注意事项
1.函数差异：
GetClientAuthId 与 GetClientAuthString 的参数略有不同，但功能相同
AuthId_Steam2 参数确保返回的 SteamID 格式与之前一致

2.错误处理：
如果 GetClientAuthId 返回 false（无法获取 SteamID），代码会将 SteamID 设置为 "Unknown"

3.日志文件位置：
日志文件将保存在 addons/sourcemod/logs/ 目录下
文件名格式为 player_connections_YYYYMMDD.log

内容示例:
[2025-08-27 14:30:25] 玩家连接 - 名称: Player1 | SteamID: STEAM_0:1:1234567 | IP: 192.168.1.100
[2025-08-27 14:35:42] 玩家退出 - 名称: Player1 | SteamID: STEAM_0:1:1234567 | IP: 192.168.1.100 | 原因: Disconnect
[2025-08-27 14:40:15] 地图已切换至: c5m1_waterfront
