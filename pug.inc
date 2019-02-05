#if defined _pug_include
	#endinput
#endif
#define _pug_include

native PugRegisterCommand(name[], fwd[], flags = -1);
native PugNextVote()
native PugRegisterVote(name[], function[])
native PugRegisterVoteOption(option[])