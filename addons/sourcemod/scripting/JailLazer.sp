#include <sourcemod>
#include <sdktools>
#include <tf2jail>
#define VERSION "1.2.0"
public Plugin:myinfo =
{
	name = "JailLazer",
	author = "MitchDizzle_/FliX",
	description = "Allows warden to draw on walls.",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=189956"
}

new const g_DefaultColors_c[7][4] = { {255,255,255,255}, {255,0,0,255}, {0,255,0,255}, {0,0,255,255}, {255,255,0,255}, {0,255,255,255}, {255,0,255,255} };
new Float:LastLaser[MAXPLAYERS+1][3];
new bool:LaserE[MAXPLAYERS+1] = {false, ...};
new g_sprite;
new bool:WardenTest[MAXPLAYERS + 1] = false;
new bool:GrantTest[MAXPLAYERS + 1] = false;
Handle GrantedTimers[MAXPLAYERS + 1];


public OnPluginStart() {
	CreateConVar("sm_jaillazer_version", VERSION, "Current Plugin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("sm_jaillazer_wardenonly", "1", "Whether or not only warden can use lazers", FCVAR_PLUGIN)
	RegAdminCmd("+laser", CMD_laser_p, ADMFLAG_BAN);
	RegAdminCmd("-laser", CMD_laser_m, ADMFLAG_BAN);
	RegAdminCmd("sm_grant", CMD_laser_grant, ADMFLAG_BAN);
	RegAdminCmd("sm_revoke", CMD_laser_revoke, ADMFLAG_BAN);
	RegAdminCmd("sm_wgrant", CMD_laser_wardengrant, ADMFLAG_BAN);
	RegAdminCmd("sm_wardengrant", CMD_laser_wardengrant, ADMFLAG_BAN);
}
public OnMapStart() {
	g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	CreateTimer(0.1, Timer_Pay, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public OnClientPutInServer(client)
{
	LaserE[client] = false;
	LastLaser[client][0] = 0.0;
	LastLaser[client][1] = 0.0;
	LastLaser[client][2] = 0.0;
}
public Action:Timer_Pay(Handle:timer)
{
	new Float:pos[3];
	new Color = GetRandomInt(0,6);
	for(new Y = 1; Y <= MaxClients; Y++) 
	{
		if(IsClientInGame(Y) && LaserE[Y])
		{
			TraceEye(Y, pos);
			if(GetVectorDistance(pos, LastLaser[Y]) > 6.0) {
				LaserP(LastLaser[Y], pos, g_DefaultColors_c[Color]);
				LastLaser[Y][0] = pos[0];
				LastLaser[Y][1] = pos[1];
				LastLaser[Y][2] = pos[2];
			}
		} 
	}
}
public Action:CMD_laser_p(client, args) {
	if(sm_jaillazer_wardenonly = 0)
	{
		PrintToChat(client,"[SM] Warden only is currently disabled, everyone can already use lazers!")
		return Plugin_Handled;
	}
	WardenTest[client] = TF2Jail_IsWarden(client);
	if(WardenTest[client] == false)
	{
		if(GrantTest[client] == true)
		{
			TraceEye(client, LastLaser[client]);
			LaserE[client] = true;	
			return Plugin_Handled;
		}
		else
		{
			PrintToChat(client, "[SM] You must be warden or have been granted permission to use this feature")
			return Plugin_Handled;
		}
	}
	if(WardenTest[client] == true)
	{
		TraceEye(client, LastLaser[client]);
		LaserE[client] = true;
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client,"[SM] Error.")
		return Plugin_Handled;


	}
}
public Action:CMD_laser_m(client, args) {
	LastLaser[client][0] = 0.0;
	LastLaser[client][1] = 0.0;
	LastLaser[client][2] = 0.0;
	LaserE[client] = false;
	return Plugin_Handled;
}
stock LaserP(Float:start[3], Float:end[3], color[4]) {
	TE_SetupBeamPoints(start, end, g_sprite, 0, 0, 0, 25.0, 2.0, 2.0, 10, 0.0, color, 0);
	TE_SendToAll();
}
TraceEye(client, Float:pos[3]) {
	decl Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(INVALID_HANDLE)) TR_GetEndPosition(pos, INVALID_HANDLE);
	return;
}
public bool:TraceEntityFilterPlayer(entity, contentsMask) {
	return (entity > GetMaxClients() || !entity);
}
public Action:CMD_laser_grant(client, args)
{
	if(sm_jaillazer_wardenonly = 0)
	{
		PrintToChat(client,"[SM] Warden only is currently disabled, everyone can already use lazers!")
		return Plugin_Handled;
	}
	char arg1[32]
	/*Check if no user to look for*/
	if(args < 1)
	{
		PrintToChat(client,"[SM] Usage: sm_grant <name>")
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true, false);
	if(target == -1)
	{
		return Plugin_Handled;
	}
	GrantTest[target] = true;
	char targetname[MAX_NAME_LENGTH];
	char clientname[MAX_NAME_LENGTH];
	GetClientName(target, targetname, sizeof(targetname));
	GetClientName(client, clientname, sizeof(clientname));
	PrintToChatAll("[SM] %s has allowed %s to use 'lazers'", clientname, targetname)
	return Plugin_Handled;
	
}
public Action:CMD_laser_revoke(client, args)
{
	char arg1[32]
	/*Check if no user to look for*/
	if(args < 1)
	{
		PrintToChat(client,"[SM] Usage: sm_revoke <name>")
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true, false);
	if(target == -1)
	{
		return Plugin_Handled;
	}
	GrantTest[target] = false;
	char targetname[MAX_NAME_LENGTH];
	char clientname[MAX_NAME_LENGTH];
	GetClientName(target, targetname, sizeof(targetname));
	GetClientName(client, clientname, sizeof(clientname));
	PrintToChatAll("[SM] %s has revoked %s's permission to use 'lazers'", clientname, targetname)
	return Plugin_Handled;
	
}
public Action:CMD_laser_wardengrant(client, args)
{
	if(sm_jaillazer_wardenonly = 0)
	{
		PrintToChat(client,"[SM] Warden only is currently disabled, everyone can already use lazers!")
		return Plugin_Handled;
	}
	WardenTest[client] = TF2Jail_IsWarden(client);
	if(WardenTest[client] == false)
	{
		PrintToChat(client,"[SM] You must be warden to use this command")
		return Plugin_Handled;
	}
	
	char arg1[32]
	char arg2[32]
	/*Check if no user to look for*/
	if(args < 2)
	{
		PrintToChat(client,"[SM] Usage: sm_wardengrant <name> [duration]")
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int target = FindTarget(client, arg1, true, false);
	if(target == -1)
	{
		return Plugin_Handled;
	}
	int lazer_timer = StringToInt(arg2)
	if(lazer_timer > 120.0)
	{
		PrintToChat(client,"Maximum time allowed is 120 seconds.")
		return Plugin_Handled;
	}
	
	GrantTest[target] = true;
	GrantedTimers[target] = CreateTimer(float(lazer_timer), wardenrevoke, target)
	char targetname[MAX_NAME_LENGTH];
	char clientname[MAX_NAME_LENGTH];
	GetClientName(target, targetname, sizeof(targetname));
	GetClientName(client, clientname, sizeof(clientname));
	PrintToChatAll("[SM] %s has allowed %s to use 'lazers' for %d seconds", clientname, targetname, lazer_timer)
	return Plugin_Handled;
	
}
public void OnClientDisconnect(int client)
{
	if(GrantTest[client] == true)
	{
		KillTimer(GrantedTimers[client]);
		GrantedTimers[client] = null;
	}
}
public Action:wardenrevoke(Handle timer, any target)
{
	GrantTest[target] = false;
	GrantedTimers[target] = null;
	PrintToChat(target,"[SM] Your permission to use 'lazers' has been revoked automatically")
}

