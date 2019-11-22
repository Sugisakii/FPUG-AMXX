#if defined _pug_include
	#endinput
#endif
#define _pug_include
enum PUG_STATE
{
	NO_ALIVE = 0,
	VOTING,
	COMMENCING,
	ALIVE,
	ENDING
}
enum PUG_EVENTS
{
	PUG_START = 0, /*(void)*/
	ALL_PLAYER_IS_READY, /*(void)*/
	ROUND_START, /*(void)*/
	ROUND_END, /*(TeamName:win_team)*/
	PUG_END, /*(TeamName:win_team)*/
	INTERMISSION_START, /* (void) */
	INTERMISSION_END /* void */
}
/*
* Registrar un comando
*
*
* @param name	Comado a registrar
* @param fwd	Funcion a llamar cuando se ejecuta el comando
*
* @note			public fwd(index, argument[])
* 				index: player index
*				argument[type = string]: String adicional a pasar
*
*/
native PugRegisterCommand(name[], fwd[], flags = -1, PUG_STATE:pugstate = NO_ALIVE);
native PugNextVote();
native PugRegisterVote(name[], function[]);
native PugRegisterVoteOption(option[]);
native PugStart();
native register_pug_event(PUG_EVENTS:event, const function[]);
native PUG_STATE:pug_get_state()