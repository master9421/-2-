#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.5"
#define PLUGIN_NAME "Player Connection Logger"

public Plugin:myinfo = 
{
    name = PLUGIN_NAME,
    author = "YourName",
    description = "记录玩家连接和断开时间",
    version = PLUGIN_VERSION,
    url = ""
};

// 全局变量
new String:g_sLogFile[PLATFORM_MAX_PATH];
new bool:g_bLateLoad = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    g_bLateLoad = late;
    return APLRes_Success;
}

public OnPluginStart()
{
    // 设置日志文件路径和名称
    SetupLogFile();
    
    // 注册事件
    HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
    
    // 如果是延迟加载，记录当前已连接的玩家
    if (g_bLateLoad)
    {
        CreateTimer(1.0, Timer_RecordExistingPlayers, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // 在服务器日志中打印加载信息
    LogToFile(g_sLogFile, "[%s] 插件已加载 - 版本 %s", PLUGIN_NAME, PLUGIN_VERSION);
    PrintToServer("[%s] 已成功加载，日志文件: %s", PLUGIN_NAME, g_sLogFile);
}

public OnMapStart()
{
    // 每张地图开始时记录一次
    decl String:mapName[128];
    GetCurrentMap(mapName, sizeof(mapName));
    LogToFile(g_sLogFile, "地图已切换至: %s", mapName);
}

public Action:Timer_RecordExistingPlayers(Handle:timer)
{
    // 记录所有已连接的玩家
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            RecordPlayerConnect(client, true);
        }
    }
    return Plugin_Stop;
}

public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    // 获取玩家信息
    decl String:playerName[MAX_NAME_LENGTH];
    decl String:steamId[32];
    decl String:ipAddress[32];
    
    GetEventString(event, "name", playerName, sizeof(playerName));
    GetEventString(event, "networkid", steamId, sizeof(steamId));
    GetEventString(event, "address", ipAddress, sizeof(ipAddress));
    
    // 从IP地址中移除端口号
    new pos = StrContains(ipAddress, ":");
    if (pos != -1)
    {
        ipAddress[pos] = '\0';
    }
    
    // 获取当前时间
    decl String:sTime[64];
    FormatTime(sTime, sizeof(sTime), "%Y-%m-%d %H:%M:%S", GetTime());
    
    // 记录到日志文件
    LogToFile(g_sLogFile, "[%s] 玩家连接 - 名称: %s | SteamID: %s | IP: %s", sTime, playerName, steamId, ipAddress);
    
    return Plugin_Continue;
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    // 获取玩家信息
    new userid = GetEventInt(event, "userid");
    new client = GetClientOfUserId(userid);
    
    if (client > 0 && !IsFakeClient(client))
    {
        RecordPlayerDisconnect(client, event);
    }
    else if (client > 0)
    {
        // 如果是机器人，也记录但标记为机器人
        decl String:playerName[MAX_NAME_LENGTH];
        GetClientName(client, playerName, sizeof(playerName));
        
        // 获取当前时间
        decl String:sTime[64];
        FormatTime(sTime, sizeof(sTime), "%Y-%m-%d %H:%M:%S", GetTime());
        
        LogToFile(g_sLogFile, "[%s] 机器人退出 - 名称: %s", sTime, playerName);
    }
    
    return Plugin_Continue;
}

RecordPlayerConnect(client, bool:isLate = false)
{
    // 获取当前时间
    decl String:sTime[64];
    FormatTime(sTime, sizeof(sTime), "%Y-%m-%d %H:%M:%S", GetTime());
    
    // 获取玩家信息
    decl String:playerName[MAX_NAME_LENGTH];
    decl String:steamId[32];
    decl String:ipAddress[32];
    
    GetClientName(client, playerName, sizeof(playerName));
    
    // 使用推荐的 GetClientAuthId 替代弃用的 GetClientAuthString
    if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
    {
        strcopy(steamId, sizeof(steamId), "Unknown");
    }
    
    GetClientIP(client, ipAddress, sizeof(ipAddress));
    
    // 记录到日志文件
    if (isLate)
    {
        LogToFile(g_sLogFile, "[%s] 已连接玩家 - 名称: %s | SteamID: %s | IP: %s", sTime, playerName, steamId, ipAddress);
    }
    else
    {
        LogToFile(g_sLogFile, "[%s] 玩家连接 - 名称: %s | SteamID: %s | IP: %s", sTime, playerName, steamId, ipAddress);
    }
}

RecordPlayerDisconnect(client, Handle:event)
{
    // 获取当前时间
    decl String:sTime[64];
    FormatTime(sTime, sizeof(sTime), "%Y-%m-%d %H:%M:%S", GetTime());
    
    // 获取玩家信息
    decl String:playerName[MAX_NAME_LENGTH];
    decl String:steamId[32];
    decl String:ipAddress[32];
    decl String:reason[128];
    
    GetClientName(client, playerName, sizeof(playerName));
    
    // 使用推荐的 GetClientAuthId 替代弃用的 GetClientAuthString
    if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
    {
        strcopy(steamId, sizeof(steamId), "Unknown");
    }
    
    GetClientIP(client, ipAddress, sizeof(ipAddress));
    GetEventString(event, "reason", reason, sizeof(reason));
    
    // 记录到日志文件
    LogToFile(g_sLogFile, "[%s] 玩家退出 - 名称: %s | SteamID: %s | IP: %s | 原因: %s", 
             sTime, playerName, steamId, ipAddress, reason);
}

SetupLogFile()
{
    // 确保日志目录存在
    decl String:logDir[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, logDir, sizeof(logDir), "logs");
    
    if (!DirExists(logDir))
    {
        CreateDirectory(logDir, 511);
    }
    
    // 设置日志文件名（按日期）
    decl String:date[16];
    FormatTime(date, sizeof(date), "%Y%m%d", GetTime());
    Format(g_sLogFile, sizeof(g_sLogFile), "%s/player_connections_%s.log", logDir, date);
}

public OnPluginEnd()
{
    // 插件卸载时记录
    LogToFile(g_sLogFile, "[%s] 插件已卸载 - 停止记录玩家连接时间", PLUGIN_NAME);
}