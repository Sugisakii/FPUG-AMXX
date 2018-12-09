#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <celltrie>

#define PLUGIN  "PUG MOD"
#define VERSION "1.31"
#define AUTHOR  "Sugisaki"

#define MAXPLAYERS 15
#define END_ROUND_KNIFE_FIX
#define get_team(%0) get_member(%0, m_iTeam)

#if AMXX_VERSION_NUM >= 183
	#define client_disconnect client_disconnected
#endif

new TASK_HUD_READY = 552214
new TASK_HUD_VOTE = 996541
new TASK_END_VOTE = 441017
new TASK_PUG_END = 778745

new const TAG[] = "[Pug Mod]"

enum _:PUGSTATE
{
	NO_ALIVE = 0,
	ALIVE,
	COMMENCING,
	VOTEMAP
}

enum _:PUG_ROUND
{
	TT = 0,
	CT
}


new Trie:t_Command
new Trie:t_Command_Plugin
new pug_state
new g_PluginId
new iMaxPlayers
new bool:ready[MAXPLAYERS]
new ready_count
new HamHook:SpawnWeapon
new HamHook:DefuseKit
new HamHook:PlayerPostink
new HamHook:PlayerSpawn
new bool:vote_map
new g_vote_id
new g_pcvar_votemap
new g_vote_countdown
new bool:private
new Trie:g_private
new bool:round_knife
new bool:half_time

new Sync1
new Sync2
new Sync3
new Sync4
new pcvar_max_players

new g_iDmg[MAXPLAYERS][MAXPLAYERS]
new g_iHits[MAXPLAYERS][MAXPLAYERS]

new Array:g_maps
new g_votes[32]
new g_iRound_team[2]
new g_iRounds
new g_iFrags[MAXPLAYERS]
new g_iDeaths[MAXPLAYERS]

new g_vote_count

new g_VoteMenu

new gMsgStatusIcon
new gMsgRegisterStatusIcon

new gMsgServerName
new gMsgTextMsg
new gMsgScoreInfo
new gMsgTeamScore

new bool:is_intermission

new SND_MUSIC[][] =
{
	"sound/pug/music1.mp3"
}
new SND_COUNTER_BEEP[] = "sound/UI/buttonrollover.wav"
new SND_STINGER[] = "sound/pug/cs_stinger.wav"

enum _:CMDS
{
	COMMAND[32],
	VALUE[10]
}

new Pregame_Cmds[][CMDS] =
{
	{"mp_forcerespawn", "1"},
	{"mp_round_infinite", "acdefg"},
	{"mp_auto_reload_weapons", "1"},
	{"mp_auto_join_team", "1"},
	{"mp_autoteambalance", "0"},
	{"mp_limitteams", "0"},
	{"mp_freezetime", "0"},
	{"mp_timelimit", "0"},
	{"mp_refill_bpammo_weapons", "3"},
	{"mp_startmoney", "16000"},
	{"sv_alltalk", "1"},
	{"mp_buytime", "-1"},
	{"mp_consistency", "1"},
	{"mp_flashlight", "0"},
	{"mp_forcechasecam", "0"},
	{"mp_forcecamera", "0"},
	{"mp_roundtime", "0"},
	{"allow_spectators", "1"},
	{"sv_timeout", "20"},
	{"sv_maxspeed", "320"}
}

new PugStartCmds[][CMDS] = 
{
	{"mp_forcerespawn", "0"},
	{"mp_startmoney", "800"},
	{"mp_freezetime", "0"},
	{"sv_alltalk", "2"},
	{"mp_refill_bpammo_weapons", "0"},
	{"mp_buytime", ".25"},
	{"mp_forcechasecam", "2"},
	{"mp_forcecamera", "2"},
	{"mp_freezetime", "11"},
	{"mp_roundtime", "1.75"},
	{"mp_auto_join_team", "0"}
}

public plugin_init()
{
	g_PluginId = register_plugin(PLUGIN, VERSION, AUTHOR)
	pug_state = NO_ALIVE
	register_clcmd("say", "pfn_Hook_Say")
	register_clcmd("say_team", "pfn_Hook_Say")
	SpawnWeapon = RegisterHam(Ham_Spawn, "weaponbox", "pfn_remove_weapon", 1)
	PlayerPostink = RegisterHam(Ham_Player_PostThink, "player", "pfn_postink", 1)
	PlayerSpawn = RegisterHam(Ham_Spawn, "player", "pfn_player_spawn", 1)
	DisableHamForward(PlayerSpawn)
	DisableHamForward(PlayerPostink)
	DefuseKit = RegisterHam(Ham_Spawn, "item_thighpack", "pfn_remove_weapon", 1)
	register_event("Money", "pfn_money", "b")
	g_private = TrieCreate()
	g_pcvar_votemap = register_cvar("pug_votemap", "1")
	t_Command = TrieCreate()
	t_Command_Plugin = TrieCreate()
	g_maps = ArrayCreate(32)
	iMaxPlayers = get_maxplayers();
	Sync1 = CreateHudSyncObj()
	Sync2 = CreateHudSyncObj()
	Sync3 = CreateHudSyncObj()
	Sync4 = CreateHudSyncObj()
	gMsgStatusIcon = get_user_msgid("StatusIcon")
	gMsgServerName = get_user_msgid("ServerName")
	gMsgTextMsg = get_user_msgid("TextMsg")
	gMsgScoreInfo = get_user_msgid("ScoreInfo")
	gMsgTeamScore = get_user_msgid("TeamScore")

	register_message(gMsgTeamScore, "pfn_TeamScore")
	
	pcvar_max_players = register_cvar("pug_players", "10")
	
	register_event("HLTV", "ev_new_round", "a", "1=0", "2=0")

	RegisterHookChain(RG_RoundEnd, "pfn_Round_End_Hook")
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "pfn_Hook_ChooseTeam")

	register_event("Damage", "pfn_EVENT_damage", "b")

	register_message(gMsgTextMsg, "pfn_TextMsg")
	register_message(gMsgScoreInfo, "pfn_ScoreInfo")
	register_event("DeathMsg", "pfn_PlayerDeath", "a")

	pug_register_command(".ready", "pfn_ready", g_PluginId)
	pug_register_command(".unready", "pfn_unready", g_PluginId)
	pug_register_command(".score", "pfn_score", g_PluginId)
	pug_register_command(".start", "pfn_force_start_pug", g_PluginId)
	pug_register_command(".forceready", "pfn_forceready", g_PluginId)
	pug_register_command(".cancel", "pfn_force_cancel", g_PluginId)
	pug_register_command(".dmg", "cmd_dmg", g_PluginId)
	pug_register_command(".hp", "cmds_vidas", g_PluginId)

	set_task(5.0, "start_pregame")
	read_maps()
	read_ini()
}

public pfn_player_spawn(id)
{
	if(round_knife)
	{
		rg_remove_all_items(id)
		rg_give_item(id, "weapon_knife")
		set_member(id, m_iAccount, 1)
	}
}

read_ini()
{
	new _sz_file[] = "addons/amxmodx/configs/pug_private.ini"
	if(file_exists(_sz_file))
	{
		server_print("Servidor Privado!!!!!")
		private = true
		new fh = fopen(_sz_file, "r")
		new line[34]
		new _auth[32]
		new _sz_team[3]

		while(!feof(fh))
		{
			fgets(fh, line, charsmax(line))
			trim(line)
			if(!line[0] || line[0] == ';' || line[0] == '/')
			{
				continue;
			}
			parse(line, _auth, charsmax(_auth), _sz_team, charsmax(_sz_team))
			trim(_sz_team)
			trim(_auth)
			TrieSetCell(g_private, _auth, str_to_num(_sz_team))
		}
		fclose(fh)
	}
	else
	{
		private = false
		server_print("Servidor Publico!!!!!")
	}
}

public client_connect(id)
{
	if(private)
	{
		new _steam_id[32]
		get_user_authid(id, _steam_id, charsmax(_steam_id))
		
		if(!TrieKeyExists(g_private, _steam_id))
		{
			server_cmd("kick #%i 'Servidor Privado!!!'", get_user_userid(id))
			return
		}
	}
}

public pfn_money(id)
{
	if(round_knife)
	{
		set_member(id, m_iAccount, 1)
		return
	}
	if(pug_state == ALIVE)
	{
		return 
	}
	set_member(id, m_iAccount, 16000)
}

public pfn_PlayerDeath()
{
	if(pug_state == ALIVE && !is_intermission && !round_knife )
	{
		new v = read_data(2)
		new k = read_data(1)
		
		if(!(1<= k <= iMaxPlayers) || v == k)
		{
			g_iDeaths[v]++
			g_iFrags[v]--
		}
		else
		{
			g_iFrags[k]++
			g_iDeaths[v]++
		}
	}

}

public pfn_ScoreInfo(m, s, id)
{
	static _score_player_id
	_score_player_id = get_msg_arg_int(1)
	if(pug_state == ALIVE && !round_knife)
	{
		set_msg_arg_int(2, ARG_SHORT, g_iFrags[_score_player_id])
		set_msg_arg_int(3, ARG_SHORT, g_iDeaths[_score_player_id])
	}
}

public cmds_vidas(id)
{
	new team = get_team(id)
	new name[32]
	for(new i = 1 ; i <= iMaxPlayers ; i++)
	{
		if(is_user_connected(i) && (1 <= get_team(i) <= 2) && team != get_team(i) && is_user_alive(i))
		{
			get_user_name(i, name, 32)
			client_print(id, print_chat, "%s | %s | HP: %i", TAG, name, get_user_health(i))
		}
	}
}
public pfn_EVENT_damage(id)
{
	new a = get_user_attacker(id)
	new damage = read_data(2)

	if(pug_state != ALIVE || !is_user_alive(a) || !(1 <= a <= iMaxPlayers) || a == id || damage <= 0)
	{
		return
	}
	
	g_iDmg[id][a] += damage
	g_iHits[id][a] += 1
}
public cmd_dmg(id)
{
	if(pug_state != ALIVE || is_user_alive(id))
	{
		client_print(id, print_chat, "%s Accion no permitida en este momento", TAG)
		return
	}
	new tmp_name[32], count, hit, conn, dmg
	for(new i = 1 ; i <= iMaxPlayers ; i++)
	{
		hit = g_iHits[i][id]
		if(hit)
		{
			count++
			dmg = g_iDmg[i][id]
			conn = is_user_connected(i)
			get_user_name(i, tmp_name, charsmax(tmp_name))
			
			client_print(id, print_chat, "%s | %s | Dmg: %i | Hits: %i%s", TAG, tmp_name, dmg, hit, conn ? "" : " | Jugador desconectado")
		}
	}
	if(!count)
	{
		client_print(id, print_chat, "%s No Le diste a nadie en esta ronda", TAG)
	}
}
public pfn_TeamScore(m, e, id)
{
	static _____team_score[2]
	get_msg_arg_string(1, _____team_score, charsmax(_____team_score))
	switch(_____team_score[0])
	{
		case 'T' : set_msg_arg_int(2, ARG_SHORT, g_iRound_team[TT])
		case 'C' : set_msg_arg_int(2, ARG_SHORT, g_iRound_team[CT])
	}
}
public newRound(id)
{
	fn_update_server_name(id)
}
public pfn_Round_End_Hook(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	if(pug_state == NO_ALIVE || event == ROUND_GAME_RESTART)
	{
		return HC_CONTINUE
	}
	else if(is_intermission)
	{
		SetHookChainReturn(ATYPE_INTEGER, 1)
		return HC_SUPERCEDE
	}
	if(round_knife)
	{
		if(status == WINSTATUS_CTS)
		{
			for(new i = 1 ; i <= iMaxPlayers ; i++)
			{
				if(!is_user_connected(i) || !(1 <= get_team(i) <= 2))
				{
					continue;
				}
				rg_switch_team(i)
			}
			client_print(0, print_chat, "%s Han ganado los CTs, Se realizara un cambio de equipos", TAG)
		}
		else if(status == WINSTATUS_TERRORISTS)
		{
			client_print(0, print_chat, "%s Han ganado los TTs, No realizara cambio de equipos", TAG)
		}
		else
		{
			client_print(0, print_chat, "%s Nadie Gano!, No realizara cambio de equipos", TAG)
		}
		round_knife = false
		#if defined END_ROUND_KNIFE_FIX
		set_cvar_num(Pregame_Cmds[1][COMMAND], 1)
		#endif
		DisableHamForward(PlayerSpawn)
		SetHookChainReturn(ATYPE_INTEGER, 1)
		Send_TextMsg(status == WINSTATUS_TERRORISTS ? "#Terrorists_Win" : status == WINSTATUS_CTS ? "#CTs_Win" : "")
		set_cvar_num("sv_restart", 4)

		DisableHamForward(SpawnWeapon)
		unregister_message(gMsgStatusIcon, gMsgRegisterStatusIcon)
		rg_send_audio(0, status == WINSTATUS_TERRORISTS ? "%!MRAD_terwin" : status == WINSTATUS_CTS ? "%!MRAD_ctwin" : "%!MRAD_rounddraw", PITCH_NORM)
		return HC_SUPERCEDE
	}
	
	if(status == WINSTATUS_CTS)
	{
		g_iRound_team[CT]++
		emessage_begin(MSG_ALL, gMsgTeamScore)
		ewrite_string("CT")
		ewrite_short(g_iRound_team[CT])
		emessage_end()
	}
	else if(status == WINSTATUS_TERRORISTS)
	{
		g_iRound_team[TT]++
		emessage_begin(MSG_ALL, gMsgTeamScore)
		ewrite_string("TERRORIST")
		ewrite_short(g_iRound_team[TT])
		emessage_end()
	}

	fn_update_server_name(0)

	if(g_iRounds == 15 && !half_time)
	{
		EnableHamForward(PlayerPostink)
		g_vote_countdown = 15
		set_task(1.0, "pfn_intermission_count", TASK_HUD_READY, _, _, "b")
		set_cvar_num("sv_maxspeed", 0)
		is_intermission = true
		half_time = true
		rg_send_audio(0, status == WINSTATUS_TERRORISTS ? "%!MRAD_terwin" : status == WINSTATUS_CTS ? "%!MRAD_ctwin" : "%!MRAD_rounddraw", PITCH_NORM)
		Send_TextMsg(status == WINSTATUS_TERRORISTS ? "#Terrorists_Win" : status == WINSTATUS_CTS ? "#CTs_Win" : "")
		client_cmd(0, "mp3 play ^"%s^"", SND_MUSIC[random_num(0, charsmax(SND_MUSIC))])
		client_cmd(0, "wait;^"mp3fadeTime^" ^"0.5^";wait")
		SetHookChainReturn(ATYPE_INTEGER, 1)
		return HC_SUPERCEDE
	}
	else if(g_iRounds == 30 || g_iRound_team[CT] >= 16 || g_iRound_team[TT] >= 16)
	{
		EnableHamForward(PlayerPostink)
		g_vote_countdown = 15
		set_task(1.0, "pfn_pug_end_countdown", TASK_PUG_END, _, _, "b")
		set_cvar_num("sv_maxspeed", 0)
		is_intermission = true
		Send_TextMsg(status == WINSTATUS_TERRORISTS ? "#Terrorists_Win" : status == WINSTATUS_CTS ? "#CTs_Win" : "")
		rg_send_audio(0, status == WINSTATUS_TERRORISTS ? "%!MRAD_terwin" : status == WINSTATUS_CTS ? "%!MRAD_ctwin" : "%!MRAD_rounddraw", PITCH_NORM)
		client_cmd(0, "mp3 play ^"%s^"", SND_MUSIC[random_num(0, charsmax(SND_MUSIC))])
		client_cmd(0, "wait;^"mp3fadeTime^" ^"0.5^";wait")
		SetHookChainReturn(ATYPE_INTEGER, 1)
		return HC_SUPERCEDE
	}

	return HC_CONTINUE

}

stock Send_TextMsg(msg[])
{
	message_begin(MSG_BROADCAST, gMsgTextMsg)
	write_byte(4)
	write_string(msg)
	message_end()
}

public pfn_pug_end_countdown(task)
{
	if(--g_vote_countdown > 0)
	{
		if(g_iRound_team[CT] == g_iRound_team[TT])
		{
			make_hud_title("La partida quedo empatada")
		}
		else if(g_iRound_team[CT] >= g_iRound_team[TT])
		{
			make_hud_title("Los Anti-Terroristas Han ganado la partida")
		}
		else
		{
			make_hud_title("Los Terroristas Han ganado la partida")
		}
		make_hud_body("Reiniciando en: %i", g_vote_countdown)
	}
	else
	{
		DisableHamForward(PlayerPostink)
		remove_task(task)
		start_pregame()
		client_cmd(0, "-showscores")
		client_cmd(0, "wait;^"mp3fadeTime^" ^"0.5^";wait")
		client_cmd(0, "wait;^"cd^" ^"fadeout^";wait")
	}
}

public pfn_intermission_count(task)
{
	if(--g_vote_countdown > 0)
	{
		make_hud_title("Descanso:")
		make_hud_body("Cambio de Equipos en 00:%02i", g_vote_countdown)
	}
	else
	{
		client_cmd(0, "wait;^"mp3fadeTime^" ^"0.5^";wait")
		client_cmd(0, "wait;^"cd^" ^"fadeout^";wait")
		remove_task(task)
		DisableHamForward(PlayerPostink)
		set_cvar_num("sv_maxspeed", 320)
		set_cvar_num("sv_restart", 1)
		new temp = g_iRound_team[CT]
		g_iRound_team[CT] = g_iRound_team[TT]
		g_iRound_team[TT] = temp
		is_intermission = false
		for(new i = 1 ; i<= iMaxPlayers ;i++)
		{
			if(!is_user_connected(i) || !(1<= get_team(i) <= 2))
			{
				continue
			}
			rg_switch_team(i)
		}
		
		client_cmd(0, "-showscores")
	}
}
fn_update_server_name(id)
{
	new szFmt[32]
	if(round_knife)
	{
		formatex(szFmt, charsmax(szFmt), "Ronda de cuchillos")
	}
	else if(pug_state != NO_ALIVE)
	{
		formatex(szFmt, charsmax(szFmt), "Ronda: %i | CT: %i | TT: %i", g_iRounds, g_iRound_team[CT], g_iRound_team[TT])
	}
	else
	{
		formatex(szFmt, charsmax(szFmt), "PUG NO ALIVE")
	}
	if(id)
	{
		message_begin(MSG_ONE, gMsgServerName, {0, 0, 0}, id)
	}
	else
	{
		message_begin(MSG_BROADCAST, gMsgServerName)
	}
	write_string(szFmt)
	message_end();
	if(pug_state != NO_ALIVE)
	{

		if(round_knife)
		{
			formatex(szFmt, charsmax(szFmt), "Ronda de cuchillos")
		}
		else if(g_iRound_team[CT] == g_iRound_team[TT])
		{
			formatex(szFmt, charsmax(szFmt), "Ronda: %i | TT: %i | CT: %i", g_iRounds, g_iRound_team[CT], g_iRound_team[TT])
		}
		else if(g_iRound_team[CT] > g_iRound_team[TT])
		{
			formatex(szFmt, charsmax(szFmt), "Ronda: %i | CT: %i | TT: %i", g_iRounds, g_iRound_team[CT], g_iRound_team[TT])
		}
		else
		{
			formatex(szFmt, charsmax(szFmt), "Ronda: %i | TT: %i | CT: %i", g_iRounds, g_iRound_team[TT], g_iRound_team[CT])
		}
		set_member_game(m_GameDesc, szFmt)
	}
	else
	{
		set_member_game(m_GameDesc, "PUG NO ALIVE")
	}
	
}

public ev_new_round()
{
	
	if(pug_state == NO_ALIVE)
	{
		return
	}
	else if(pug_state == COMMENCING)
	{
		pug_state = ALIVE
		set_cvar_num("mp_round_infinite", 0)
	}
	
	if(round_knife)
	{
		fn_update_server_name(0)
		return
	}

	g_iRounds++

	#if defined END_ROUND_KNIFE_FIX
	if(g_iRounds == 1)
	{
		set_cvar_num(Pregame_Cmds[1][COMMAND], 0)
		arrayset(g_iFrags, 0, MAXPLAYERS)
		arrayset(g_iDeaths, 0, MAXPLAYERS)
	}
	#endif

	if(g_iRounds == 15 || g_iRound_team[CT] == 15 || g_iRound_team[TT] == 15)
	{
		client_cmd(0, "spk ^"%s^"; spk ^"%s^"", SND_STINGER[6], SND_STINGER[6])
		set_dhudmessage(255, 255, 255, -1.0, 0.3, 0, 1.0, 1.5)
		if(g_iRounds == 30)
		{
			show_dhudmessage(0, "Ronda Final")
		}
		else
		{
			show_dhudmessage(0, "Punto de partido")
		}
	}

	fn_update_server_name(0)
	fn_score(0)
	
	for(new i = 1 ; i <= iMaxPlayers ; i++)
	{
		arrayset(g_iDmg[i], 0, MAXPLAYERS)
		arrayset(g_iHits[i], 0, MAXPLAYERS)
	}
}

public plugin_end()
{
	TrieDestroy(t_Command)
	TrieDestroy(t_Command_Plugin)
	ArrayDestroy(g_maps)
}
stock is_user_admin(id)
{
	new __flags=get_user_flags(id);
	return (__flags>0 && !(__flags&ADMIN_USER));
}
read_maps()
{
	new file[32]
	new curmap[32]
	ArrayPushString(g_maps, "Jugar Este Mapa")
	get_mapname(curmap, charsmax(curmap))
	new dh = open_dir("maps", file, charsmax(file))
	if(!dh)
	{
		set_fail_state("Error al abrir la carpeta de mapas");
		return
	}
	
	while(dh)
	{
		trim(file)
		if(check_bsp_file(file))
		{
			replace(file, charsmax(file), ".bsp", "")
			if(equal(curmap, file))
			{
				continue;
			}
			ArrayPushString(g_maps, file)
		}
		if(!next_file(dh, file, charsmax(file)))
		{
			close_dir(dh)
			dh = false
		}
	}
	
}
bool:check_bsp_file(file[])
{
	if(equal(file[strlen(file)-4], ".bsp"))
	{
		return true
	}
	
	return false
}
public pfn_postink(id)
{
	if((1 <= get_team(id) <= 2) && pug_state == ALIVE)
	{
		client_cmd(id, "+showscores")
	}
}
public pfn_remove_weapon(ent)
{
	set_pev(ent, pev_flags, FL_KILLME)
}
public pfn_remove_entity(id)
{
	if(pev_valid(id))
	{
		engfunc(EngFunc_RemoveEntity, id)
	}
	//client_print(0, print_chat, "Think")
}
reset_user_vars()
{
	arrayset(ready, false, MAXPLAYERS)
	ready_count = 0
	g_vote_id = 0;
	round_knife = false
	half_time = false
	g_iRound_team[TT] = 0
	g_iRound_team[CT] = 0
	arrayset(g_iFrags, 0, MAXPLAYERS)
	arrayset(g_iDeaths, 0, MAXPLAYERS)
}
stock pug_register_command(Command[], Function[], Plugin)
{
/*
	new szPlugin[5]
	num_to_str(Plugin, szPlugin, charsmax(szPlugin))
*/
	new funcid = get_func_id(Function, Plugin)
	if(!funcid)
	{
		server_print("Funcion: ^"%s^" No encontrada", Function)
		return
	}
	else if(TrieKeyExists(t_Command, Command))
	{
		server_print("Funcion ^"%s^" ya existente", Command)
		return
	}

	TrieSetCell(t_Command, Command, Plugin)
	TrieSetCell(t_Command_Plugin, Command, funcid)
}
public start_pregame()
{
	for(new i = 0 ; i < sizeof(Pregame_Cmds) ; i++)
	{
		set_cvar_string(Pregame_Cmds[i][COMMAND], Pregame_Cmds[i][VALUE])
	}
	is_intermission = false
	pug_state = NO_ALIVE
	gMsgRegisterStatusIcon = register_message(gMsgStatusIcon, "pfn_StatusIcon")
	set_cvar_num("sv_restart", 1)
	EnableHamForward(SpawnWeapon)
	EnableHamForward(DefuseKit)
	reset_user_vars()
	fn_update_server_name(0)
	if(get_pcvar_num(g_pcvar_votemap) == 1)
	{
		set_task(1.0, "pfn_Hud_Ready", TASK_HUD_READY, _, _, "b")
	}
	else
	{
		g_vote_countdown = 60
		set_task(1.0, "pfn_waiting_players", TASK_HUD_READY, _, _, "b")
	}

	if(private)
	{
		set_cvar_string(Pregame_Cmds[3][COMMAND], "0")
	}
}

public pfn_StatusIcon(m, e, id)
{
	if(pug_state == ALIVE && !round_knife)
	{
		unregister_message(gMsgStatusIcon, gMsgRegisterStatusIcon)
		return PLUGIN_CONTINUE
	}
	new arg[4]
	get_msg_arg_string(2, arg, charsmax(arg))
	if(equal(arg, "c4"))
	{
		client_cmd(id, "drop weapon_c4")
	}
	return PLUGIN_CONTINUE
}
public pfn_Hud_Ready()
{
	set_hudmessage(255, 0, 0, 0.8, 0.07, 0, 1.0, 1.0)
	new i;
	new __pcount = 0
	for(i = 1 ; i <= iMaxPlayers ;i++ )
	{
		if(is_user_connected(i) && 1 <= get_team(i) <= 2)
		{
			__pcount++
		}
	}
	ShowSyncHudMsg(0, Sync1, "No Listos: %i", __pcount - ready_count)
	new fmt[33 * 33], name[32]
	
	for(i = 1 ; i <= iMaxPlayers ;i++ )
	{
		if(ready[i] || !is_user_connected(i) || !(1 <= get_team(i) <= 2))
		{
			continue;
		}
		get_user_name(i, name, charsmax(name))
		format(fmt, charsmax(fmt), "%s%s^n", fmt, name)
	}
	set_hudmessage(255, 255, 255, 0.8, 0.1, 0, 1.0, 1.0)
	ShowSyncHudMsg(0, Sync2, fmt)
	copy(fmt, charsmax(fmt), "")
	set_hudmessage(0, 255, 0, 0.8, 0.5, 0, 1.0, 1.0)
	ShowSyncHudMsg(0, Sync3, "Listos: %i", ready_count)
	for(i = 1 ; i <= iMaxPlayers ;i++ )
	{
		if(!ready[i] || !is_user_connected(i) || !(1 <= get_team(i) <= 2))
		{
			continue;
		}
		get_user_name(i, name, charsmax(name))
		format(fmt, charsmax(fmt), "%s%s^n", fmt, name)
	}
	set_hudmessage(255, 255, 255, 0.8, 0.53, 0, 1.0, 1.0)
	ShowSyncHudMsg(0, Sync4, fmt)
}
public plugin_natives()
{
	register_native("pug_register_command", "native_register_command", .style=0)
	register_native("pug_get_state", "native_pug_get_state")
}
public native_pug_get_state(pl, pr)
{
	return pug_state;
}
public native_register_command(pl, pr)
{
	new szCommand[20], szForward[32]
	get_string(1, szCommand, charsmax(szCommand))
	get_string(2, szForward, charsmax(szForward))
	pug_register_command(szCommand, szForward, pl)
}
public pfn_Hook_Say(id)
{
	if(!is_user_connected(id))
	{
		return PLUGIN_CONTINUE
	}
	static said[32]
	read_argv(1, said, charsmax(said))
	remove_quotes(said)
	trim(said)
	if(TrieKeyExists(t_Command, said))
	{
		new iPlugin, iFunc
		TrieGetCell(t_Command, said, iPlugin)
		TrieGetCell(t_Command_Plugin, said, iFunc)
		callfunc_begin_i(iFunc, iPlugin)
		callfunc_push_int(id)
		callfunc_end()
		return PLUGIN_HANDLED_MAIN
	}
	return PLUGIN_CONTINUE
}

public pfn_ready(id)
{
	if(pug_state != NO_ALIVE || !(1 <= get_team(id) <= 2))
	{
		client_print(id, print_chat, "%s Accion no permitida en este momento", TAG)
		return
	}
	else if(ready[id])
	{
		client_print(id, print_chat, "%s Ya estas listo", TAG)
		return
	}
	new name[32]
	get_user_name(id, name, charsmax(name))
	client_print(0, print_chat, "%s %s Esta Listo", TAG, name)
	ready[id] = true
	ready_count ++
	if(ready_count == get_pcvar_num(pcvar_max_players))
	{
		start_vote()
	}
}
public pfn_unready(id)
{
	if(pug_state != NO_ALIVE)
	{
		client_print(id, print_chat, "%s Accion no permitida en este momento", TAG)
		return
	}
	else if(!ready[id])
	{
		client_print(id, print_chat, "%s Aun no estas listo", TAG)
		return
	}
	new name[32]
	get_user_name(id, name, charsmax(name))
	client_print(0, print_chat, "%s %s Dejo de estar Listo", TAG, name)
	ready[id] = false;
	ready_count --
}
public pfn_TextMsg(m, e, id)
{
	static msg[23]
	get_msg_arg_string(2, msg, charsmax(msg))
	if(equal(msg, "#Game_will_restart_in"))
	{
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}
public pfn_Hook_ChooseTeam(id, _:slot)
{
	new count_t, players[32], count_ct
	if(!(1 <= slot <= 2))
	{
		if(slot == 5)
		{
			get_players(players, count_t, "e", "TERRORIST")
			get_players(players, count_ct, "e", "CT")

			if(count_t >= (get_pcvar_num(pcvar_max_players) / 2) && count_ct >= (get_pcvar_num(pcvar_max_players) / 2) )
			{
				client_print(id, print_chat, "%s Todos los equipos se encuentran llenos", TAG)
				SetHookChainReturn(ATYPE_INTEGER, 0)
				return HC_BREAK
			}
		}
		return HC_CONTINUE
	}
	else if((1 <= slot <= 2) && (1 <= get_team(id) <= 2) && pug_state == ALIVE)
	{
		client_print(id, print_chat, "%s No puedes hacer un cambio de equipos estando una partida en curso", TAG)
		SetHookChainReturn(ATYPE_INTEGER, 0)
		return HC_BREAK
	}
	new count
	get_players(players, count, "e", slot == 1 ? "TERRORIST" : "CT")

	if(count >= (get_pcvar_num(pcvar_max_players) / 2) )
	{
		center_print(id, "%s Este Equipo esta lleno^n^n^n^n^n", TAG)
		SetHookChainReturn(ATYPE_INTEGER, 0)
		return HC_BREAK
	}
	return HC_CONTINUE
}

stock center_print(id, const msg[], any:...)
{
	new arg[50]
	vformat(arg, charsmax(arg), msg, 3)
	if(id == 0)
	{
		for(new z = 1 ; z <= iMaxPlayers ; z++)
		{
			if(!is_user_connected(z))
			{
				continue
			}
			engfunc(EngFunc_ClientPrintf, z, 1, arg)
		}
	}
	else
	{ 
		engfunc(EngFunc_ClientPrintf, id, 1, arg)
	}
}

public client_putinserver(id)
{
	if(ready[id])
	{
		ready[id] = false
		ready_count--
	}
	g_iFrags[id] = 0
	g_iDeaths[id] = 0
	fn_update_server_name(id)
	if(private && pug_state != ALIVE)
	{
		set_task(1.0, "pfn_set_team", id + 666)
	}
	
}
public pfn_set_team(id)
{
	id -= 666
	if(!is_user_connected(id))
		return
	new _sz__steam_id_put[32]
	get_user_authid(id, _sz__steam_id_put, charsmax(_sz__steam_id_put))
	if(TrieKeyExists(g_private, _sz__steam_id_put))
	{
		new _c_team
		TrieGetCell(g_private, _sz__steam_id_put, _c_team)
		
		if(get_team(id) == _c_team)
		{
			return
		}
		
		switch(_c_team)
		{
			case 1: rg_set_user_team(id, TEAM_TERRORIST)
			case 2: rg_set_user_team(id, TEAM_CT)
			case 3: rg_join_team(id, TEAM_SPECTATOR)
		}
		
		if(1 <= _c_team <= 2)
		{
			ExecuteHam(Ham_CS_RoundRespawn, id)
		}
	}
}
public client_disconnect(id)
{
	if(is_intermission)
	{
		return
	}
	if(ready[id])
	{
		ready[id] = false
		ready_count--
	}
	new team = get_team(id)
	if(pug_state == ALIVE && (1 <= team <= 2))
	{
		new count = 0
		
		for(new i = 1 ; i <= iMaxPlayers ;i++)
		{
			if(!is_user_connected(i) || i == id || get_team(i) != team)
			{
				continue
			}
			count++
		}
		if(count <= 2)
		{
			client_print(0, print_chat, "%s Partida cancelada por ausencia de jugadores en el equipo %s", TAG, team == 1 ? "Terrorista" : "Anti-Terrorista")
			start_pregame()
		}
	}
}

fn_score(id=0)
{
	if(pug_state == NO_ALIVE)
	{
		client_print(id, print_chat, "%s Accion no permitida en este momento", TAG)
		return
	}
	if(g_iRound_team[CT] == g_iRound_team[TT])
	{
		client_print(0, print_chat, "%s La puntuacion esta empatada %i - %i", TAG, g_iRound_team[CT], g_iRound_team[TT])
	}
	else
	{
		client_print(0, print_chat, "%s %s: %i - %s: %i ", TAG, g_iRound_team[CT] > g_iRound_team[TT] ? "Anti-Terroristas" : "Terroristas", g_iRound_team[CT] > g_iRound_team[TT] ? g_iRound_team[CT] : g_iRound_team[TT], g_iRound_team[CT] < g_iRound_team[TT] ? "Anti-Terroristas" : "Terroristas", g_iRound_team[CT] < g_iRound_team[TT] ? g_iRound_team[CT] : g_iRound_team[TT] )
	}
}
public pfn_score(id)
{
	fn_score(id)
}
public start_vote()
{
	remove_task(TASK_HUD_READY)
	g_vote_id = 0
	next_vote()
}
make_hud_title(msg[], any:...)
{
	new fmt[50]
	vformat(fmt, charsmax(fmt), msg, 2)
	set_hudmessage(0, 255, 0, -1.0, 0.0, 0, 1.0, 1.1)
	ShowSyncHudMsg(0, Sync1, fmt)
}
make_hud_body(msg[], any:...)
{
	new fmt[512]
	vformat(fmt, charsmax(fmt), msg, 2)
	set_hudmessage(255, 255, 255, -1.0, 0.03, 0, 1.0, 1.1)
	ShowSyncHudMsg(0, Sync2, fmt)
}
public next_vote()
{
	remove_task(TASK_HUD_VOTE)
	remove_task(TASK_END_VOTE)
	g_vote_id++
	switch(g_vote_id)
	{
		case 1 :
		{
			if(get_pcvar_num(g_pcvar_votemap) == 1)
			{
				set_task(1.0, "pfn_hud_votemap", TASK_HUD_VOTE, _, _, "b")
				set_task(15.0, "pfn_vote_map_end", TASK_END_VOTE)
				g_vote_countdown = 15
				pug_state = VOTEMAP
				start_vote_map()
			}
			else
			{
				set_pcvar_num(g_pcvar_votemap, 1)
				next_vote();
			}
		}
		default :
		{
			start_countdown()
		}
	}
}

public start_countdown()
{
	EnableHamForward(PlayerPostink)
	set_cvar_num("sv_maxspeed", 0)
	g_vote_countdown = 4
	set_task(1.0, "pfn_starting_game", TASK_HUD_READY, _, _, "b")
	pfn_starting_game(TASK_HUD_READY)
	set_pcvar_num(g_pcvar_votemap, 1)

}

public start_pug()
{
	set_cvar_num("sv_restart", 1)
	for(new i = 0 ; i < sizeof(PugStartCmds) ;i++)
	{
		set_cvar_string(PugStartCmds[i][COMMAND], PugStartCmds[i][VALUE])
	}
	g_iRounds = 0;
	arrayset(g_iRound_team, 0, 2)
	arrayset(g_iFrags, 0, MAXPLAYERS)
	arrayset(g_iDeaths, 0, MAXPLAYERS)
	is_intermission = false
	DisableHamForward(DefuseKit)
}

public pfn_hud_votemap()
{
	if(g_vote_countdown-- <= 0)
	{
		g_vote_countdown = 0
	}
	fn_update_vote_map_hud()
}
fn_update_vote_map_hud()
{
	make_hud_title("Votacion de Mapa: (%i)", g_vote_countdown)
	new count
	new hud[512]
	new temp
	for(new i = 0 ; i < ArraySize(g_maps) ; i++)
	{
		temp = g_votes[i]
		if(temp >= 1)
		{
			count++
			format(hud, charsmax(hud), "%s%a: %i %s^n", hud, ArrayGetStringHandle(g_maps, i), temp, temp > 1 ? "votos" : "voto")
		}	
	}
	
	if(!count)
	{
		formatex(hud, charsmax(hud), "No hay votos")
	}
	make_hud_body(hud)
}
public start_vote_map()
{
	vote_map = true
	g_vote_count = 0
	make_menu_votemap()
}
make_menu_votemap()
{
	arrayset(g_votes, 0, sizeof(g_votes))
	g_VoteMenu = menu_create("\rVotacion de Mapa", "mh_vote_map")
	new map[32]
	new i
	for(i = 0 ; i < ArraySize(g_maps) ;i++)
	{
		ArrayGetString(g_maps, i, map, charsmax(map))
		menu_additem(g_VoteMenu, map)
	}
	menu_setprop(g_VoteMenu, MPROP_EXIT, MEXIT_ALL)

	for(i = 1 ; i <= iMaxPlayers ;i++ )
	{
		if(!is_user_connected(i) || !( 1 <= get_team(i) <= 2))
		{
			continue 
		}
		menu_display(i, g_VoteMenu, .page=0)
	}
}
public mh_vote_map(id, menu, item)
{
	if(!vote_map)
	{
		return
	}
	if(item == MENU_EXIT)
	{
		g_votes[0]++
		fn_update_vote_map_hud()
		check_votes(vote_map);
		return
	}
	g_votes[item]++
	g_vote_count++
	fn_update_vote_map_hud()
	check_votes(vote_map);
}

public check_votes(bool:active)
{
	if(!active)
	{
		return
	}
	if(g_vote_count == get_pcvar_num(pcvar_max_players))
	{
		next_vote();
	}
}

public pfn_vote_map_end()
{
	vote_map = false
	client_cmd(0, "slot10")
	menu_destroy(g_VoteMenu)

	new winner, temp
	for(new i = 0 ; i < sizeof (g_votes) ; i++)
	{
		if(temp < g_votes[i])
		{
			temp = g_votes[i]
			winner = i
		}
	}

	if(!winner)
	{
		client_print(0, print_chat, "%s Se decidio %a", TAG, ArrayGetStringHandle(g_maps, 0))
		next_vote();
	}
	else
	{
		set_pcvar_num(g_pcvar_votemap, 0)
		server_cmd("changelevel ^"%a^"", ArrayGetStringHandle(g_maps, winner))
	}
}
public pfn_force_start_pug(id)
{
	if(!is_user_admin(id))
	{
		client_print(id, print_chat, "%s No tienes acceso a este comando", TAG)
		return
	}
	else if(pug_state != NO_ALIVE)
	{
		client_print(id, print_chat, "%s Accion no permitida en este momento", TAG)
		return
	}
	start_vote()
}
public pfn_force_cancel(id)
{
	if(!is_user_admin(id))
	{
		client_print(id, print_chat, "%s No tienes acceso a este comando", TAG)
		return
	}
	else if(pug_state != ALIVE)
	{
		client_print(id, print_chat, "%s Accion no permitida en este momento", TAG)
		return
	}
	start_pregame()
}
public pfn_forceready(id)
{
	if(!is_user_admin(id))
	{
		client_print(id, print_chat, "%s No tienes acceso a este comando", TAG)
		return
	}
	else if(pug_state != NO_ALIVE)
	{
		client_print(id, print_chat, "%s Accion no permitida en este momento", TAG)
		return
	}
	fn_forceready()
	
}
fn_forceready()
{
	new catch_players = get_pcvar_num(pcvar_max_players)
	for(new i = 1 ; i <= iMaxPlayers ; i++)
	{
		if(!is_user_connected(i) || !(1<= get_team(i) <= 2) || ready[i])
		{
			continue
		}
		ready[i] = true;
		ready_count++
		if(ready_count == catch_players)
		{
			start_vote()
			break;
		}
	}
}
public pfn_waiting_players(task)
{
	new pcount = 0
	for(new i = 1 ; i <= iMaxPlayers ; i++)
	{
		if(is_user_connected(i) && 1 <= get_team(i) <= 2)
		{
			pcount++
		}
	}
	if(g_vote_countdown-- > 0)
	{
		
		if(pcount == get_pcvar_num(pcvar_max_players))
		{
			center_print(0, "Calentamiento 00:%02i^n^n^n^n", g_vote_countdown)
			if(g_vote_countdown < 5)
			{
				client_cmd(0, "spk ^"%s^"", SND_COUNTER_BEEP[6])
			}
		}
		else
		{
			center_print(0, "Esperando jugadores 00:%02i^n^n^n^n", g_vote_countdown)
		}
	}
	else if(g_vote_countdown <= 0 && pcount == get_pcvar_num(pcvar_max_players))
	{
		remove_task(task)
		next_vote()
	}
	else
	{
		set_pcvar_num(g_pcvar_votemap, 1)
		remove_task(task)
		start_pregame()
		fn_forceready();
		client_print(0, print_chat, "%s Partida no iniciada por la ausencia de jugadores", TAG)

	}
}
public pfn_starting_game(task)
{
	if(g_vote_countdown == 1)
	{
		start_pug()
		pug_state = COMMENCING
		round_knife = true
		EnableHamForward(PlayerSpawn)
	}

	if(g_vote_countdown-- > 0)
	{
		center_print(0, "Empezando Partida: %i^n^n^n^n", g_vote_countdown)

	}
	else
	{
		DisableHamForward(PlayerPostink)
		set_cvar_num("sv_maxspeed", 320)
		remove_task(task)
		center_print(0, " ");
		client_print(0, print_chat, "%s Ronda cuchillo, el equipo ganador sera TT", TAG)
	}
}
public plugin_precache()
{
	precache_generic(SND_COUNTER_BEEP)
	precache_generic(SND_STINGER)
	for(new i = 0 ; i < sizeof(SND_MUSIC) ; i++)
	{
		precache_generic(SND_MUSIC[i])
	}
}
