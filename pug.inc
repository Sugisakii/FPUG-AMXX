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
native PugRegisterCommand(name[], fwd[], flags = -1, PUG_STATE:pugstate = NO_ALIVE);
native PugNextVote();
native PugRegisterVote(name[], function[]);
native PugRegisterVoteOption(option[]);
native PugStart();