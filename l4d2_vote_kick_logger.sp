#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
#define LOG_FILE "addons/sourcemod/logs/vote_kick.log"

new g_iVoteKickInitiator[MAXPLAYERS+1];
new g_iVoteKickTarget[MAXPLAYERS+1];
new String:g_sVoteKickReason[MAXPLAYERS+1][256];

public Plugin:myinfo = 
{
    name = "L4D2投票踢人记录器",
    author = "AI助手",
    description = "记录游戏中的投票踢人事件",
    version = PLUGIN_VERSION,
    url = "https://github.com/YourName/l4d2-vote-kick-logger"
};

public OnPluginStart()
{
    HookEvent("vote_started", Event_VoteStarted);
    HookEvent("vote_passed", Event_VotePassed);
    HookEvent("vote_failed", Event_VoteFailed);
    
    RegConsoleCmd("sm_votekicklog", Cmd_ShowVoteKickLog, "显示最近的投票踢人记录");
    
    // 创建日志目录如果不存在
    if(!DirExists("addons/sourcemod/logs"))
    {
        CreateDirectory("addons/sourcemod/logs", 511);
    }
}

public Action:Event_VoteStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
    new initiator = GetClientOfUserId(GetEventInt(event, "initiator"));
    new String:issue[64];
    GetEventString(event, "issue", issue, sizeof(issue));
    
    // 只记录踢人投票
    if (StrEqual(issue, "kick", false))
    {
        new target = GetClientOfUserId(GetEventInt(event, "target"));
        new String:reason[256];
        GetEventString(event, "param1", reason, sizeof(reason));
        
        g_iVoteKickInitiator[initiator] = initiator;
        g_iVoteKickTarget[initiator] = target;
        strcopy(g_sVoteKickReason[initiator], sizeof(g_sVoteKickReason[]), reason);
        
        LogVoteKickEvent(initiator, target, reason, "started");
    }
    
    return Plugin_Continue;
}

public Action:Event_VotePassed(Handle:event, const String:name[], bool:dontBroadcast)
{
    new String:issue[64];
    GetEventString(event, "issue", issue, sizeof(issue));
    
    if (StrEqual(issue, "kick", false))
    {
        new initiator = GetClientOfUserId(GetEventInt(event, "initiator"));
        
        if (g_iVoteKickInitiator[initiator] != 0)
        {
            LogVoteKickEvent(initiator, g_iVoteKickTarget[initiator], g_sVoteKickReason[initiator], "passed");
            ResetVoteKickData(initiator);
        }
    }
    
    return Plugin_Continue;
}

public Action:Event_VoteFailed(Handle:event, const String:name[], bool:dontBroadcast)
{
    new String:issue[64];
    GetEventString(event, "issue", issue, sizeof(issue));
    
    if (StrEqual(issue, "kick", false))
    {
        new initiator = GetClientOfUserId(GetEventInt(event, "initiator"));
        
        if (g_iVoteKickInitiator[initiator] != 0)
        {
            LogVoteKickEvent(initiator, g_iVoteKickTarget[initiator], g_sVoteKickReason[initiator], "failed");
            ResetVoteKickData(initiator);
        }
    }
    
    return Plugin_Continue;
}

stock LogVoteKickEvent(initiator, target, const String:reason[], const String:status[])
{
    new String:initiatorName[MAX_NAME_LENGTH];
    new String:targetName[MAX_NAME_LENGTH];
    new String:initiatorAuth[32];
    new String:targetAuth[32];
    new String:timeString[64];
    
    FormatTime(timeString, sizeof(timeString), "%Y-%m-%d %H:%M:%S");
    
    if (IsValidClient(initiator))
    {
        GetClientName(initiator, initiatorName, sizeof(initiatorName));
        if (!GetClientAuthId(initiator, AuthId_Steam2, initiatorAuth, sizeof(initiatorAuth), true))
            strcopy(initiatorAuth, sizeof(initiatorAuth), "Unknown");
    }
    else
    {
        strcopy(initiatorName, sizeof(initiatorName), "Unknown");
        strcopy(initiatorAuth, sizeof(initiatorAuth), "Unknown");
    }
    
    if (IsValidClient(target))
    {
        GetClientName(target, targetName, sizeof(targetName));
        if (!GetClientAuthId(target, AuthId_Steam2, targetAuth, sizeof(targetAuth), true))
            strcopy(targetAuth, sizeof(targetAuth), "Unknown");
    }
    else
    {
        strcopy(targetName, sizeof(targetName), "Unknown");
        strcopy(targetAuth, sizeof(targetAuth), "Unknown");
    }
    
    // 记录到日志文件
    LogToFile(LOG_FILE, "[%s] 投票状态: %s | 发起者: %s (%s) | 目标玩家: %s (%s) | 原因: %s", 
        timeString, status, initiatorName, initiatorAuth, targetName, targetAuth, reason);
}

stock ResetVoteKickData(client)
{
    g_iVoteKickInitiator[client] = 0;
    g_iVoteKickTarget[client] = 0;
    g_sVoteKickReason[client][0] = '\0';
}

public Action:Cmd_ShowVoteKickLog(client, args)
{
    if (!IsValidClient(client) || !IsClientInGame(client))
    {
        return Plugin_Handled;
    }
    
    // 检查权限
    if (GetUserAdmin(client) == INVALID_ADMIN_ID)
    {
        ReplyToCommand(client, "您需要管理员权限才能使用此命令。");
        return Plugin_Handled;
    }
    
    ShowLatestLogs(client);
    return Plugin_Handled;
}

stock ShowLatestLogs(client)
{
    new Handle:file = OpenFile(LOG_FILE, "r");
    if (file == INVALID_HANDLE)
    {
        ReplyToCommand(client, "没有找到投票踢人记录。");
        return;
    }
    
    new String:line[512];
    new Handle:lines = CreateArray(512);
    
    while (ReadFileLine(file, line, sizeof(line)))
    {
        PushArrayString(lines, line);
    }
    
    CloseHandle(file);
    
    new lineCount = GetArraySize(lines);
    new start = lineCount - 10;
    if (start < 0) 
        start = 0;
    
    ReplyToCommand(client, "最近10条投票踢人记录:");
    for (new i = start; i < lineCount; i++)
    {
        GetArrayString(lines, i, line, sizeof(line));
        ReplyToCommand(client, line);
    }
    
    CloseHandle(lines);
}

bool:IsValidClient(client)
{
    if (client <= 0 || client > MaxClients)
        return false;
    
    if (!IsClientInGame(client))
        return false;
    
    return true;
}

public OnMapStart()
{
    // 每张地图开始时记录分隔符
    new String:mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    new String:timeString[64];
    FormatTime(timeString, sizeof(timeString), "%Y-%m-%d %H:%M:%S");
    
    LogToFile(LOG_FILE, "========== 地图开始: %s | 时间: %s ==========", mapName, timeString);
}