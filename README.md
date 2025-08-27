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


*************************************************************************************************************************************


编译和安装说明
编译插件: 使用 SourceMod 1.11 的编译器编译此文件


安装插件:将编译生成的 l4d2_vote_kick_logger.smx 文件放入 addons/sourcemod/plugins 目录

重启服务器或使用 sm plugins load l4d2_vote_kick_logger 命令加载插件

功能说明
自动记录: 插件会自动记录所有投票踢人事件到 addons/sourcemod/logs/vote_kick.log 文件
详细信息: 每条记录包含:
时间戳
投票状态 (开始/通过/失败)
发起者名称和Steam ID
目标玩家名称和Steam ID
投票原因

查询功能: 管理员可以使用 !votekicklog 命令查看最近的10条投票记录

地图分隔: 每次地图更换时会添加分隔符，便于区分不同地图的日志
