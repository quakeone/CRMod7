//
// Votables.qc
//
// Code to handle all votes
//
// All code by J.P. Grossman unless otherwise commented
//

// global variables
float request_mapnum;     	// Used for requesting a new level
float request_timelimit;    // Used for requesting a new time limit
float request_fraglimit;    // Used for requesting a new frag limit
float request_overtime;		// Used for requesting a new overtime
float request_gibs;         // Used to set gib level
float request_mode;         // Used to request a new mode
float request_gametype;		// Used to request a new game type
float request_weaponstay;   // Used to request weaponstay
// q14ever overlay: remember who initiated the enable so we can attach the prop to them.
entity q14ever_last_requester;

void() UnHookPlayer;
void() utils_update_server_time;
void() utils_save_disconnect_log;
void(float ghost) G1v1_UpdateQuadAlpha;

//
//  S E N D  A L I A S E S
//
//  Stuffs aliases for votable commands and numbers.
//
// Return 1 if at least one non-observer is actually in the game (spawned)
float() votables_has_active_players =
{
    local entity p;
    p = find(world, classname, "player");
    while (p)
    {
        if ((p.style & CLANRING_CONNECTED) && !(p.style & CLANRING_OBSERVER))
            return 1;
        p = find(p, classname, "player");
    }
    return 0;
};

void() votables_send_aliases =
{
	local entity temp;

	temp = self;
	self = self.owner;
	stuffcmd(self, "alias w5 \"wait;wait;wait;wait;wait\"\n");
	stuffcmd(self, "alias sethook impulse 202\n");
	stuffcmd(self, "alias setrunes impulse 203\n");
	stuffcmd(self, "alias abortmatch impulse 214\n");
	stuffcmd(self, "alias force impulse 217\n");
	stuffcmd(self, "alias weaponstay impulse 218\n");
	// toggle faststarts	
	stuffcmd(self, "alias faststart impulse 209\n");
	stuffcmd(self, "alias autopause impulse 210\n");
	// toggle extended obits
	stuffcmd(self, "alias obits impulse 211\n");
	// timelimit aliases
	stuffcmd(self, "alias timeset cmd timeset\n");
	stuffcmd(self, "alias otset impulse 216\n");
	stuffcmd(self, "alias fragset impulse 219\n");
	// Quad, Pent, Ring aliases
	stuffcmd(self, "alias setquad impulse 221\n");
	stuffcmd(self, "alias setpent impulse 222\n");
	stuffcmd(self, "alias setring impulse 223\n");
	// gib aliases
	stuffcmd(self, "alias nogibs impulse 225\n");
	stuffcmd(self, "alias lowgibs impulse 226\n");
	stuffcmd(self, "alias highgibs impulse 227\n");
	// playmode aliases
	stuffcmd(self, "alias normal cmd normal\n");
	stuffcmd(self, "alias practice cmd practice\n");
	stuffcmd(self, "alias match cmd match\n");
	stuffcmd(self, "alias dm cmd dm\n");
	stuffcmd(self, "alias ctf cmd ctf\n");
	stuffcmd(self, "alias wipeout cmd wipeout\n");
	stuffcmd(self, "alias ca cmd ca\n");
	stuffcmd(self, "alias ra cmd ra\n");
	stuffcmd(self, "alias dmm4 cmd dmm4\n");
	stuffcmd(self, "alias ctfdmm4 cmd ctfdmm4\n");
	stuffcmd(self, "alias airshot cmd airshot\n");
	stuffcmd(self, "alias powerupdrop cmd powerupdrop;\n");
	stuffcmd(self, "alias leavemealone \"cmd leavemealone\"\n");

	// QuakeTag aliases (only two commands now)
	stuffcmd(self, "alias qwsucks \"cmd qwsucks\"\n");
	stuffcmd(self, "alias q14ever \"cmd q14ever\"\n");

	// R00k: allow 0 to 50 as commands for console input for menus
	for (float i = 50; i >= 0; i -= 1)
	{
		stuffcmd (self, sprintf("alias %g cmd %g\n", i, i));
	}

	// send this LAST to make sure that the client received all impulses
	stuffcmd(self, "alias crx_ignorethis \"impulse 180;\"\n");

	self = temp;
	remove(self);
};

//----------------------------------------------------------------
//	V O T A B L E S  S E T  H O O K
//
//	R00K: Enable or disable the hook
//
//----------------------------------------------------------------
void() votables_set_hook =
{
	local entity p;
	
	if (!(clanring_playmode & CLANRING_NO_HOOK))
	{
		clanring_playmode = (clanring_playmode | CLANRING_NO_HOOK);

		clanring_state = clanring_state - (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM);

		p = find(world, classname, "player");

		while (p)
		{
			if (p.style & CLANRING_CONNECTED)
			{				
				if (p.weapon == IT_HOOK)
				{
					local entity tmp;
					tmp = self;
					self = p;
					UnHookPlayer();							
					self = tmp;
					p.weapon = IT_AXE;
				}			
				p.hook2 = (p.hook2 - (p.hook2 & HOOK_OUT)); //not this?
				p.items = p.items - (p.items & IT_HOOK);
			}
			p= find(p ,classname , "player");			
		}
		bprint("grappling hook has been \bdisabled\n");
	}
	else
	{
		if (clanring_playmode & CLANRING_NO_HOOK)
		{
			clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_NO_HOOK);
			clanring_state = clanring_state - (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM);

			if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (clanring_playmode & (CLANRING_MATCH_MODE | CLANRING_PRACTICE_MODE)))
			{
				clanring_state = clanring_state | CLANRING_TEAM_CAPTURE_CUSTOM;
				bprint("custom grappling hook has been \benabled\n");
			}
			else
				bprint("grappling hook has been \benabled\n");

			p = find(world, classname, "player");
			while (p)
			{
				if (p.style & CLANRING_CONNECTED)
				{				
					p.items = p.items | IT_HOOK;	
				}
				p= find(p ,classname , "player");			
			}
		}
	}

	utils_set_cvar("samelevel", clanring_playmode);	
};

void() votables_request_set_hook =
{
	local string newstate = "", newstate2 = "";

	if (self.style & CLANRING_ADMINISTRATOR)
	{
		votables_set_hook();
		return;
	}

	if (!(clanring_playmode & CLANRING_NO_HOOK))
	{
		newstate  = "disable";
		newstate2 = " grappling hook";
	}
	else
	{
		if (clanring_playmode & CLANRING_NO_HOOK)
		{
			newstate  = "enable";
			newstate2 = " grappling hook";
		}
	}						
	
	if (vote_init(newstate, newstate2, votables_set_hook))
	{
		vote_yes();
	}	
};

//
//  C H A N G E  L E V E L
//
//  Called when a request to change level passses.  The level name is
//  stored in request_mapname.
//
void () votables_change_level =
{
	local string request_mapname = warpmap[request_mapnum].name;

	if (clanring_state & CLANRING_MATCH_STARTED)
	return;

	utils_set_cvar("timelimit", clanring_timelimit);

	observer_clear_players_infokeys();
	
	if (request_mapname == "start0")
	{
		serverflags = 0;
		utils_update_server_time();  // Update persistent time
		utils_save_disconnect_log();  // Save to file before map change
		changelevel("start");
	}
	else if (request_mapname == "start1")
	{
		serverflags = 15;
		utils_update_server_time();  // Update persistent time
		utils_save_disconnect_log();  // Save to file before map change
		changelevel("start");
	}
	else
	{
		utils_update_server_time();  // Update persistent time
		utils_save_disconnect_log();  // Save to file before map change
		changelevel (request_mapname);
	}	
};


//
//  R E Q U E S T  C H A N G E  L E V E L
//
//  Called when a player requests a new level.
//
void() votables_request_change_level =
{
	local float level;
	local string newmap = "";

	if (clanring_levelcount != -1)
	{
		sprint(self, "Wait for map to initialize\n");
		return;
	}

	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		sprint(self, "Cannot change level while match is in progress.\n");
		return;
	}

	level = (self.warp_episode * WARP_MAPLIST_SIZE) + (self.warp_map);
	newmap = sprintf("%s (%s)", warpmap[level].name, warpmap[level].title);
	
	//clear warp_flags;
	self.warp_episode=0;
	self.warp_map=0;

	if (warpmap[level].name == "")
	{
		sprint(self, "Invalid level\n");
		return;
	}

    // Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		request_mapnum = level;
		votables_change_level();
	}
	else
	if (vote_init("\bchange level to\b ", newmap, votables_change_level))
	{
		request_mapnum = level;
		vote_yes();
	}
};


//
//  I N I T  W A R P
//
//  Called to initiate the warp.  The episode is passed as a parameter.
//  The level will be entered next; votables_request_change_level will be
//  called when it is.
//
void(float episode) votables_init_warp =
{
	self.count = episode;
	self.use = votables_request_change_level;
};

void() votables_starve_player =
{
	self.items = 0;
	self.items = (IT_SHOTGUN | IT_AXE);

	if (!(clanring_playmode & CLANRING_NO_HOOK))
		self.items = (self.items | IT_HOOK);

	self.health = 100;
	self.armorvalue = 0;
	self.ammo_shells = 0;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	self.ammo_cells = 0;
	self.weapon = 1;
	self.armortype = 0;
	self.weaponmodel = "progs/v_shot.mdl";
	self.weaponframe = 0;
};

//
//  P H A T T E N  P L A Y E R
//
//  Phatten up players when entering practice mode.
//
void() votables_phatten_player =
{
	self.items = IT_SHOTGUN | IT_AXE | IT_ROCKET_LAUNCHER | IT_ARMOR3 | IT_SUPER_SHOTGUN | IT_NAILGUN | IT_GRENADE_LAUNCHER | IT_LIGHTNING | IT_SUPER_NAILGUN;

	if (!(clanring_playmode & CLANRING_NO_HOOK))
		self.items = self.items | IT_HOOK;

	self.health = 100;
	self.armorvalue = 200;
	self.ammo_shells = 100;
	self.ammo_nails = 200;
	self.ammo_rockets = 100;
	self.ammo_cells = 100;
	self.weapon = 32;
	self.armortype = 0.8;
	self.weaponmodel = "progs/v_rock2.mdl";
	self.weaponframe = 0;
};

void() votables_clear_arena_playmode_flags =
{
	clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_CA_MODE);
	clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_RA_MODE);
	clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_DMM4_MODE);
	clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_AIRSHOT_MODE);
	clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_WIPEOUT_MODE);
}

void() votables_clear_playmode_flags =
{
	clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_NORMAL_MODE);
	clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_MATCH_MODE);
	clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_PRACTICE_MODE);
	clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_CAPTURE_THE_FLAG);
	votables_clear_arena_playmode_flags();
}

void() clanring_nextlevel_config;
//
// V O T A B L E S  S E T  G A M E T Y P E  M O D E  M A P
//
// Called when a request to set the gametype/mode/level passes.
void() votables_set_gametype_mode_map =
{
	if (clanring_state & CLANRING_MATCH_STARTED)
		return;

	local string newmapname = "", request_mapname = "";

	if (request_gametype >= 0)
	{
		if (request_gametype == 0)
		{
			clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_CAPTURE_THE_FLAG);
			
			if (!(clanring_playmode & CLANRING_NORMAL_MODE) && !(clanring_playmode & CLANRING_PRACTICE_MODE) && !(clanring_playmode & CLANRING_MATCH_MODE))
				clanring_playmode = clanring_playmode | CLANRING_MATCH_MODE;
			
				clanring_playmode = clanring_playmode | CLANRING_NO_HOOK;
			cvar_set("timelimit", "0");
			votables_clear_arena_playmode_flags();
			 //R00k: force teamplay 0 as default. Match sets this later.
			if (clanring_playmode & CLANRING_NORMAL_MODE)
				cvar_set("teamplay", "0");

			cvar_set("deathmatch", "1");
			bprint("gametype set to Deathmatch\n");
		}
		else if (request_gametype == 1)
		{
			votables_clear_arena_playmode_flags();
			if (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))
				clanring_playmode = (clanring_playmode | CLANRING_CAPTURE_THE_FLAG);
			if (!(clanring_playmode & CLANRING_NORMAL_MODE) && !(clanring_playmode & CLANRING_PRACTICE_MODE)
				 && !(clanring_playmode & CLANRING_MATCH_MODE))
			{clanring_playmode = clanring_playmode | CLANRING_MATCH_MODE;}
			clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_NO_HOOK);
			cvar_set("timelimit", "0");
			cvar_set("teamplay", "1");
			cvar_set("deathmatch", "1");
			bprint("gametype set to Capture The Flag\n");
		}
		else if (request_gametype == 2)
		{
			votables_clear_playmode_flags();
			clanring_playmode = (clanring_playmode | CLANRING_CA_MODE | CLANRING_NO_HOOK);
			cvar_set("teamplay", "1");
			cvar_set("deathmatch", "1");
			bprint("gametype set to Clan Arena\n");
			newmapname = "dm3";
		}
		else if (request_gametype == 3)
		{
			votables_clear_playmode_flags();
			clanring_playmode = (clanring_playmode | CLANRING_RA_MODE | CLANRING_NO_HOOK);
			cvar_set("teamplay", "0");
			cvar_set("deathmatch", "1");
			bprint("gametype set to Rocket Arena\n");
			if (!ra_map())
				newmapname = "arenax";
		}
		else if (request_gametype == 4)
		{
			votables_clear_playmode_flags();
			clanring_playmode = (clanring_playmode | CLANRING_DMM4_MODE | CLANRING_NO_HOOK);
			cvar_set("timelimit", "3");
			cvar_set("fraglimit", "0");
			cvar_set("teamplay", "0");
			cvar_set("deathmatch", "4");
			cvar_set ("scratch2", "0");//overtime
			bprint("gametype set to dmm4\n");
			newmapname = "povdmm4";
		}
		else if (request_gametype == 5)
		{
			votables_clear_playmode_flags();
			clanring_playmode = (clanring_playmode | CLANRING_AIRSHOT_MODE | CLANRING_NO_HOOK);
			cvar_set("timelimit", "3");
			cvar_set("fraglimit", "10");
			cvar_set("teamplay", "0");
			cvar_set("deathmatch", "4");
			cvar_set ("scratch2", "0");//overtime
			bprint("gametype set to Airshot\n");

			newmapname = "endif";
		}
		else if (request_gametype == 6)
		{
			votables_clear_playmode_flags();
			clanring_playmode = (clanring_playmode | CLANRING_CA_MODE | CLANRING_WIPEOUT_MODE | CLANRING_NO_HOOK);
			//cvar_set("timelimit", "0");
			cvar_set("teamplay", "1");
			cvar_set("deathmatch", "1");
			bprint("gametype set to Clan Arena Wipeout\n");
			newmapname = "dm3";
		}
		else if (request_gametype == 7)
		{
			votables_clear_playmode_flags();
			clanring_playmode = (clanring_playmode | CLANRING_DMM4_MODE);
			cvar_set("timelimit", "3");
			cvar_set("fraglimit", "0");
			cvar_set("teamplay", "0");
			cvar_set("deathmatch", "4");
			cvar_set ("scratch2", "0");//overtime
			bprint("gametype set to ctf dmm4\n");

			newmapname = "ctf8dmm4";
		}

		utils_set_cvar ("samelevel", clanring_playmode);
		clanring_level = 1;//Reset the map count if we changed modes
		utils_set_cvar ("scratch1", clanring_level);
		if (nextmap != "") strunzone(nextmap);
		nextmap = ""; //Reset the nextmap too
	}
	if (request_mode >= 0)
	{
		// don't remove CTF in case we just set it above
		clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_NORMAL_MODE);
		clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_MATCH_MODE);
		clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_PRACTICE_MODE);
		votables_clear_arena_playmode_flags();
		
		// Set the default timelimit if it was not set by options	
		if (!(self.style & CLANRING_SETTING_OPTIONS) || (self.pos1_x != cvar ("timelimit")))
		{
			if (request_mode == ADMIN_NORMAL_MODE)
			{
				utils_set_cvar("timelimit", clanring_timelimit);
				
				cvar_set("teamplay", "0");
				
				utils_do_players(votables_starve_player);//R00k ADDED, going from pmode to normal everyone has full inventory. (CVAR?)
				clanring_playmode = clanring_playmode | CLANRING_NORMAL_MODE;
			}
			else
			{
				if (request_mode == ADMIN_PRACTICE_MODE)
				{
					cvar_set("timelimit", "0");
					cvar_set("teamplay", "0");
				}
			}
		}

		if (request_mode == ADMIN_PRACTICE_MODE)
		{
			cvar_set("timelimit", "0");
			cvar_set("teamplay", "0");
			clanring_playmode = clanring_playmode | CLANRING_PRACTICE_MODE;
			utils_do_players(votables_phatten_player);
		}
		else
		{
			if (request_mode == ADMIN_MATCH_MODE)
			{
				clanring_playmode = clanring_playmode | CLANRING_MATCH_MODE;
				utils_do_players(votables_starve_player);//R00k ADDED
				utils_set_cvar("timelimit", clanring_timelimit);
				utils_set_cvar("fraglimit", 0);
				
				if (!(self.style & CLANRING_SETTING_OPTIONS))
				{
					if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
						cvar_set("teamplay", "1");//default for CTF
					else
						cvar_set("teamplay", "2");
				}	
			}
			else
			{
				if (request_mode == ADMIN_NORMAL_MODE)
				{
					utils_set_cvar("timelimit", clanring_timelimit);
					cvar_set("teamplay", "0");
					utils_do_players(votables_starve_player);
					clanring_playmode = clanring_playmode | CLANRING_NORMAL_MODE;
				}
			}
		}

		local string mode;
		mode = strings_get_mode(request_mode);
		announce3("playmode set to '", mode, "'");
		utils_set_cvar("samelevel", clanring_playmode);
		if (nextmap != "") strunzone(nextmap);
		nextmap = ""; //Reset the nextmap too
		clanring_level = 1;//Reset the map count if we changed modes
		utils_set_cvar ("scratch1", clanring_level);
	}
	if (request_mapnum)
	{
		request_mapname = warpmap[request_mapnum].name;

		utils_set_cvar("timelimit", clanring_timelimit);

		if (request_mapname == "start0")
		{
			serverflags = 0;
			newmapname = "start";
		}
		else if (request_mapname == "start1")
		{
			serverflags = 15;
			newmapname = "start";
		}
		else
		newmapname = request_mapname;
	}

	observer_clear_players_infokeys();

	if (newmapname == "")
		newmapname = mapname;

	changelevel (newmapname);
};

//
// V O T A B L E S  R E Q U E S T  S E T  G A M E T Y P E  M O D E  M A P
//
// newtype
//     -1	-	no change
//		0	-	dm
//		1	-	ctf
//		2	-	ca
//		3	-	ra
//		4	-	1v1
//		5	-	airshot
//		6	-	wipeout
//		7	-	ctfdmm4
//
// newmode		(dm/ctf)
//	   -1	-	no change
//      0   -   normal
//      1   -   practice
//      2   -   match
void(float newtype, float newmode, float newmap) votables_request_set_gametype_mode_map =
{
	local string mode = "", request_mapname = "";

	if (clanring_request != world)
	{
		bprint("\n\bThere is already a vote in progress to ", clanring_request.noise1, clanring_request.noise2, "\n");
		return;
	}

	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		if (self == world)
			cprint("Cannot change map or mode while match is in progress\n");
		else
			sprint(self, "Match has started; cannot change map or mode\n");
		return;
	}

	if (time < 4)
	{
		sprint(self, "The server is still initializing, please try again.\n");
		return;//(REQUIRED for FTEsv)
	}

	if (clanring_levelcount != -1)
	{
		if (self == world)
			cprint("Wait for levels.cfg to finish\n");
		else
			sprint(self, "Wait for map to initialize\n");
		return;
	}

	if (newtype >= 0)
	{
		//if request is only to change to the game type we are already in
		if (newtype == 0 && !(clanring_playmode & CLANRING_CAPTURE_THE_FLAG) 
			&& !(clanring_playmode & CLANRING_DMM4_MODE) && !(clanring_playmode & CLANRING_CA_MODE) 
			&& !(clanring_playmode & CLANRING_RA_MODE) && !(clanring_playmode & CLANRING_AIRSHOT_MODE) 
			&& newmode < 0 && !newmap)
		{
			sprint(self, "Already in DeathMatch mode\n");
			return;
		}
		else if (newtype == 1 && clanring_playmode & CLANRING_CAPTURE_THE_FLAG && newmode < 0 && !newmap)
		{
			sprint(self, "Already in Capture The Flag mode\n");
			return;
		}
		else if (newtype == 2 && (mode_clan_arena()) && newmode < 0 && !newmap)
		{
			sprint(self, "Already in Clan Arena mode\n");
			return;
		}
		else if (newtype == 3 && clanring_playmode & CLANRING_RA_MODE && newmode < 0 && !newmap)
		{
			sprint(self, "Already in Rocket Arena mode\n");
			return;
		}
		//allow switch to dmm4 from ctfdmm4.  combine with ctf mode to distinguish?
		// else if (newtype == 4 && clanring_playmode & CLANRING_DMM4_MODE && newmode < 0 && !newmap)
		// {
		// 	sprint(self, "Already in 1v1 mode\n");
		// 	return;
		// }
		else if (newtype == 5 && clanring_playmode & CLANRING_AIRSHOT_MODE && newmode < 0 && !newmap)
		{
			sprint(self, "Already in airshot mode\n");
			return;
		}
		else if (newtype == 6 && clanring_playmode & CLANRING_WIPEOUT_MODE && newmode < 0 && !newmap)
		{
			sprint(self, "Already in wipeout mode\n");
			return;
		}
	}

	if (newmode >= 0)
	{
		mode = strings_get_mode (newmode);
		if ((newmode == options_get_mode()) && !(self.style & CLANRING_SETTING_OPTIONS) && newtype < 0 && !newmap)
		{
			if (self == world)
				cprint3("Already in ", mode, " mode\n");
			else
				sprint3(self, "Already in ", mode, " mode\n");
			return;
		}
		mode = strings_get_mode_gold(newmode);
		if (!(self.style & CLANRING_ADMINISTRATOR) && !(clanring_playmode & CLANRING_MODE_VOTE))
		{
			sprint(self, "Mode voting has been disabled\n");
			return;
		}
		if ((request_mode == 1) && !(self.style & CLANRING_ADMINISTRATOR) && (clanring_state & CLANRING_NO_PRACTICE))
		{
			sprint(self, "Practice mode has been disabled\n");
			return;
		}
		mode = strings_get_mode (newmode);
	}

	if (newmap)
	{
		self.use = SUB_Null;
		request_mapname = sprintf("%s (%s)",warpmap[newmap].name,warpmap[newmap].title);
	}

	//clear warp_flags;
	if (self != world)
	{
		self.warp_episode=0;
		self.warp_map=0;
	}
	request_gametype = newtype;
	request_mode = newmode;
	request_mapnum = newmap;

	//If ya'll could pass my vote, thanks!
	//if (self.style & CLANRING_ADMINISTRATOR)
	//{
	//	votables_set_gametype_mode_map();
	//}
	//else
	{
		//start vote
		local string gametype_string = "", mode_string = "", vote_title_string = "", vote_string = "";

		if (request_gametype == 0)
		{
			if ((request_mode == 0) 
				|| ((request_mode < 0) 
					&& !(clanring_playmode & CLANRING_PRACTICE_MODE) 
					&& !(clanring_playmode & CLANRING_MATCH_MODE)))
			{
				gametype_string = "Free For All";
				mode = "";
			}
			else
				gametype_string = "Team DeathMatch";
		}
		else if (request_gametype == 1)
		{
			gametype_string = "Capture The Flag";
		}
		else if (request_gametype == 2)
		{
			gametype_string = "Clan Arena";
		}
		else if (request_gametype == 3)
		{
			gametype_string = "Rocket Arena";
		}
		else if (request_gametype == 4)
		{
			gametype_string = "Duel";
		}
		else if (request_gametype == 5)
		{
			gametype_string = "Airshot";
		}
		else if (request_gametype == 6)
		{
			gametype_string = "Wipeout";
		}
		else if (request_gametype == 7)
		{
			gametype_string = "CTF Duel";
		}

		if (request_mapname != "")
		{
			if (request_gametype < 0 && request_mode < 0)
			{
				vote_title_string = "\bChange Map to\b ";
				vote_string = request_mapname;
			}
			else if (request_mode < 0)
			{
				vote_title_string = "\bChange Gametype/Map to\b ";
				vote_string = sprintf("%s \bon\b %s", gametype_string, request_mapname);
			}
			else if (request_gametype < 0)
			{
				vote_title_string = "\bChange Mode/Map to\b ";
				vote_string = sprintf("%s \bon\b %s", mode, request_mapname);
			}
			else
			{
				vote_title_string = "\bChange Gametype/Mode/Map to\b ";
				vote_string = sprintf("%s %s \bon\b %s", gametype_string, mode, request_mapname);
			}
		}
		else
		{
			if (request_mode < 0)
			{
				vote_title_string = "\bChange Gametype to\b ";
				vote_string = gametype_string;
			}
			else
			{
				if (request_gametype < 0)
				{
					vote_title_string = "\bChange Mode to\b ";
					vote_string = mode;
				}
				else
				{
					vote_title_string = "\bChange Gametype/Mode to\b ";
					vote_string = sprintf("%s %s", gametype_string, mode);
				}
			}
		}

		if (vote_init(vote_title_string, vote_string, votables_set_gametype_mode_map))
		{
			vote_yes();
		}
	}
};

void() votables_set_weaponstay =
{
	if (request_weaponstay)
	{
		cvar_set("deathmatch", "3");
		deathmatch = 3;
		utils_do_weapons(SUB_regen);
		bprint("Deathmatch set to \3 [weaponstay \bon\b]\n");

		// Clean up weapon animations when weaponstay is turned on
		utils_do_weapons(weapon_prewar_cleanup);
	}
	else
	{
		cvar_set("deathmatch", "1");
		deathmatch = 1;
		bprint("Deathmatch set to \1 [weaponstay \boff\b]\n");

		// Set up weapon animations when weaponstay is turned off in DM mode
		if ((clanring_playmode & CLANRING_MATCH_MODE) &&
			!(clanring_state & CLANRING_MATCH_STARTED) &&
			!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))
		{
			utils_do_weapons(weapon_prewar_setup);
		}
	}
};

void () votables_request_set_weaponstay =
{
	local string temp;
	local float newweaponstay;

	if (match_in_progress())
	{
		sprint(self, "Cannot change deathmatch mode while match is in progress.\n");
		return;
	}

	if (cvar("deathmatch") == 3)
		newweaponstay = 0;
	else
		newweaponstay = 1;

    // Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		request_weaponstay = newweaponstay;
		votables_set_weaponstay ();
	}
	else
	{
		temp = (newweaponstay) ? "\bon\b" : "\boff\b";
		if (vote_init("change weaponstay to ", temp, votables_set_weaponstay))
		{
			request_weaponstay = newweaponstay;
			vote_yes();
		}
	}
};

// ------------------------------------------------------------
// Filesystem helpers (portable-ish)
// ------------------------------------------------------------
// NOTE: whichpack() and checkextension() are provided by fteextensions.qc.
// Do not redeclare them here to avoid signature-mismatch warnings.

// Can we probe the FS for file existence?
float() FS_CanProbe =
{
    if (checkextension("DP_QC_WHICHPACK")) return TRUE;
    if (checkextension("FTE_QC_WHICHPACK")) return TRUE;
    return FALSE;
};

// Does <path> exist somewhere on the search path?
float(string path) FS_FileExists =
{
    if (!FS_CanProbe())
        return FALSE; // strict: if we can't probe, we treat as missing
    return (whichpack(path) && whichpack(path) != "");
};

// Return TRUE iff an alt .ent for this map exists in the given dir.
// We try both:
//   1) "maps/<dir>/<map>.ent"   (your current layout)
//   2) "<dir>/maps/<map>.ent"   (alternate layout)
float(string target_dir) AltEntForCurrentMapExists =
{
    local string m, c1, c2;
    m = mapname;
    if (!m || m == "") return FALSE;
    if (!FS_CanProbe())  return FALSE; // strict: require probing
    if (!target_dir || target_dir == "") return FALSE;

    c1 = strcat("maps/", target_dir, "/", m, ".ent");
    c2 = strcat(target_dir, "/maps/", m, ".ent");

    if (FS_FileExists(c1) || FS_FileExists(c2))
    {
        if (cvar("developer"))
            bprint(strcat("^7[altents probe] OK: ", FS_FileExists(c1) ? c1 : c2, "\n"));
        return TRUE;
    }

    if (cvar("developer"))
        bprint(strcat("^7[altents probe] MISS: ", c1, " & ", c2, "\n"));
    return FALSE;
};

//
//  S E T  A L T E R N A T I V E  E N T I T I E S
//
//  Enable/disable alternative entity sets
//
void() votables_set_altents =
{
    local string dir_next;
    if (clanring_gameconfig & CLANRING_ALTERNATIVE_ENTS)
    {
        // Switching back to standard entities
        clanring_gameconfig = clanring_gameconfig - (clanring_gameconfig & CLANRING_ALTERNATIVE_ENTS);

        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
            cvar_set("external_ents_dir", "ctf");
        else
            cvar_set("external_ents_dir", "");

        bprint("Standard entity set enabled\n");
    }
    else
    {
        // Switching TO alt: probe the *target* dir (not current external_ents_dir)
        dir_next = (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) ? "ctf_alt" : "dm_alt";
        if (!AltEntForCurrentMapExists(dir_next))
        {
            bprint(strcat("No alternate entities available for ", mapname, "\n"));
            return;
        }

        // Switching to alternative entities
        clanring_gameconfig = clanring_gameconfig | CLANRING_ALTERNATIVE_ENTS;
        cvar_set("external_ents_dir", dir_next);
        bprint("Alternative entity set enabled\n");
    }

    utils_set_cvar("gamecfg", clanring_gameconfig);
	utils_update_server_time();  // Update persistent time
	utils_save_disconnect_log();  // Save to file before map change
	changelevel(mapname);
};

//
//  R E Q U E S T  S E T  A L T E R N A T I V E  E N T I T I E S
//
//  Request to enable/disable alternative entity sets
//
void() votables_request_set_altents =
{
    local string dir_next; // declare once, reuse
    // Do it right away if we're an administrator, otherwise vote
    if (self.style & CLANRING_ADMINISTRATOR)
    {
        // Admin direct toggle: block if no alt for this map in the *target* dir
        if (!(clanring_gameconfig & CLANRING_ALTERNATIVE_ENTS))
        {
            dir_next = (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) ? "ctf_alt" : "dm_alt";
            if (!AltEntForCurrentMapExists(dir_next))
            {
                bprint(strcat("No alternate entities available for ", mapname, "\n"));
                return;
            }
        }
        votables_set_altents();
    }
    else
    {
        string newstate = "";

        if (clanring_gameconfig & CLANRING_ALTERNATIVE_ENTS)
            newstate = "\bstandard\b";
        else
            newstate = "\balternative\b";

        // If switching TO alt, ensure a .ent exists in the target dir
        if (!(clanring_gameconfig & CLANRING_ALTERNATIVE_ENTS))
        {
            dir_next = (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) ? "ctf_alt" : "dm_alt";
            if (!AltEntForCurrentMapExists(dir_next))
            {
                bprint(strcat("No alternate entities available for ", mapname, "\n"));
                return;
            }
        }
        if (vote_init("switch entity set to ", newstate, votables_set_altents, "altents"))
            vote_yes();
    }
};

void() GotoNextMap;

// ----------------------------
// QuakeTag toggles (prototypes)
// ----------------------------
void() votables_request_qwsucks;   // NEW single-command flow
void() votables_request_q14ever;   // NEW single-command flow
void(float on) votables_toggle_qwsucks;
void(float on) votables_toggle_q14ever;
// Vote callbacks (no lambdas in QC)
void() votables_qwsucks_enable_and_start_callback;
void() votables_qwsucks_disable_and_clear_callback;
void() votables_q14ever_enable_and_start_callback;
void() votables_q14ever_disable_and_clear_callback;
// Need QuakeTag helpers
void() quaketag_start_regular_auto;
void() quaketag_start_q14ever_auto;
void() quaketag_clear;
// q14ever presence/flag helpers (from quaketag.qc)
float() Q14ever_AnyProps;
void() Q14ever_SyncFlag;
void() Q14ever_RemoveAllProps;
void(entity player_owner) q14ever_spawn_penis;

// External QuakeTag entity (defined in quaketag.qc)
entity crmod_qtag_it;

void() votables_vote_exit =
{
	if (clanring_levelcount == -1)
	{
		GotoNextMap();
	}
};

//Vote to exit to next map in levels.cfg
void() votables_request_vote_exit =
{
	if (clanring_levelcount != -1)
	{
		sprint(self, "Wait for map to initialize\n");
		return;
	}
	
	if (clanring_playmode & CLANRING_MATCH_MODE)
	{
		sprint(self,"Command not allowed in current gamemode.\n");
		return;
	}

	if (self.style & CLANRING_ADMINISTRATOR)
		votables_vote_exit();
	else
	{
		string newstate = "";
		sprint(self,"\byou have voted to exit to the next level.\n\botherwise, use WARP to specify map.\n");
		
		newstate = " exit to ";
		if (vote_init(newstate, "next level.", votables_vote_exit))
			vote_yes();
	}
};

//
//	S E T  F R A G L I M I T
//
void() votables_set_fraglimit =
{
	clanring_set_fraglimit(request_fraglimit);
};
void (float newlimit) votables_request_set_fraglimit =
{
	string temp = ""; 

	if ((clanring_playmode & CLANRING_MATCH_MODE) && (clanring_state & CLANRING_MATCH_STARTED))
	{
		sprint(self, "Cannot change frag limit while match is in progress.\n");
		return;
	}
	else if (((clanring_playmode & CLANRING_AIRSHOT_MODE) || (clanring_playmode & CLANRING_DMM4_MODE))
		&& ((boss != world) && (boss.state == CA_MATCH_PLAYING)))
	{
		sprint(self, "Cannot change frag limit while match is in progress.\n");
		return;
	}

    // Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		request_fraglimit = newlimit;
		votables_set_fraglimit ();
	}
	else
	{
		temp = strings_ftos_bronze (newlimit);
		if (vote_init("change frag limit to ", temp, votables_set_fraglimit))
		{
			request_fraglimit = newlimit;
			vote_yes();
		}
	}
};
void() votables_get_fraglimit =
{
	if (self.finaldest_z >= 1 && self.finaldest_z <= 5)
		votables_request_set_fraglimit(self.finaldest_z * 5);
	else if (self.finaldest_z == 6)
		votables_request_set_fraglimit(35);
	else if (self.finaldest_z == 7)
		votables_request_set_fraglimit(50);
	else if (self.finaldest_z == 8)
		votables_request_set_fraglimit(75);
	else if (self.finaldest_z == 9)
		votables_request_set_fraglimit(100);
	else if (self.finaldest_z == 10)
		votables_request_set_fraglimit(0);
	else if (self.finaldest_z == 0)
		sprint(self, "cancelled\n");
	else
		sprint(self, "invalid selection\n");
	self.use = SUB_Null;
};
void() votables_select_fraglimit =
{
	if ((clanring_playmode & CLANRING_AIRSHOT_MODE) || (clanring_playmode & CLANRING_DMM4_MODE) || (clanring_playmode & CLANRING_RA_MODE))
	{
		if ((boss != world) && (boss.state == CA_MATCH_PLAYING))
		{
			sprint(self, "Cannot change frag limit while match is in progress.\n");
			return;
		}
	}
	else
	{
		if (!(clanring_playmode & CLANRING_MATCH_MODE))
		{
			sprint(self, "Command valid in match modes only\n");
			return;
		}
		if (clanring_state & CLANRING_MATCH_STARTED)
		{
			sprint(self, "Cannot change frag limit while match is in progress.\n");
			return;
		}
	}

	sprint(self, "Select fraglimit:\n");
	sprint(self, "\x80\1\x82   \b5 frags\b    \x80\4\x82 \b20 frags\b    \x80\7\x82  \b50 frags\b\n");
	sprint(self, "\x80\2\x82  \b10 frags\b    \x80\5\x82 \b25 frags\b    \x80\8\x82  \b75 frags\b\n");
	sprint(self, "\x80\3\x82  \b15 frags\b    \x80\6\x82 \b35 frags\b    \x80\9\x82 \b100 frags\b\n");
	sprint(self, "\x80\1\0\x82 \bNo fraglimit\b\n");
	sprint(self, "\x80\0\x82  \bcancel\b\n");
	self.use = votables_get_fraglimit;
};

//
//  S E T  T I M E L I M I T
//
//  Called when a request to change the timelimit passes.  The new
//  timelimit is stored in the global variable request_timelimit.
//
void() votables_set_timelimit =
{
	local string temp;

	if (clanring_playmode & CLANRING_MATCH_MODE)
	{
		clanring_timelimit = request_timelimit;
		default_timelimit = clanring_timelimit;
		temp = ftos(clanring_timelimit);
		bprint("Match length changed to ", temp, " minutes\n");
		forceinfokey(world, "matchtime", ftos(clanring_timelimit));//R00k: requested by Woods.
		match_show_timelimit();
	}
	else
	{
		//set default time for arena modes
		if ((clanring_playmode & CLANRING_DMM4_MODE) || (clanring_playmode & CLANRING_AIRSHOT_MODE))
		{
			default_timelimit = request_timelimit;
		}

		timelimit = request_timelimit * 60;
		utils_set_cvar("timelimit", request_timelimit);
		temp = ftos(request_timelimit);
		bprint3("timelimit changed to ", temp, " minutes\n");
	}
};

//
//  R E Q U E S T  S E T  T I M E L I M I T
//
//  Called when a player requests a new timelimit.
//

void (float newlimit) votables_request_set_timelimit =
{
	local string temp;

	if (clanring_timelimit == newlimit) 
	{
		sprint(self, sprintf("Time limit is already set to %s.\n", ftos(newlimit)));
		return;
	}

	if ((clanring_playmode & CLANRING_MATCH_MODE) && (clanring_state & CLANRING_MATCH_STARTED))
	{
		sprint(self, "Cannot change time limit while match is in progress.\n");
		return;
	}
	else if (((clanring_playmode & CLANRING_AIRSHOT_MODE) || (clanring_playmode & CLANRING_DMM4_MODE))
		&& ((boss != world) && (boss.state == CA_MATCH_PLAYING)))
	{
		sprint(self, "Cannot change time limit while match is in progress.\n");
		return;
	}

    // Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		request_timelimit = newlimit;
		votables_set_timelimit ();
	}
	else
	{
		temp = strings_ftos_bronze (newlimit);
		if (vote_init("change match length to ", temp, votables_set_timelimit))
		{
			request_timelimit = newlimit;
			vote_yes();
		}
	}
};

//
//  G E T  T I M E L I M I T
//
void() votables_get_timelimit =
{
	if (self.finaldest_z >= 1 && self.finaldest_z <= 6)
		votables_request_set_timelimit(self.finaldest_z * 5);
	else if (self.finaldest_z == 7)
		votables_request_set_timelimit(3);
	else if (self.finaldest_z == 10)
		votables_request_set_timelimit(0);
	else if (self.finaldest_z == 0)
		sprint(self, "cancelled\n");
	else
		sprint(self, "invalid selection\n");
	self.use = SUB_Null;
};

//
//  S E L E C T  T I M E L I M I T
//
void() votables_select_timelimit =
{
	if ((clanring_playmode & CLANRING_AIRSHOT_MODE) || (clanring_playmode & CLANRING_DMM4_MODE))
	{
		if ((boss != world) && (boss.state == CA_MATCH_PLAYING))
		{
			sprint(self, "Cannot change time limit while match is in progress.\n");
			return;
		}
	}
	else
	{
		if (!(clanring_playmode & CLANRING_MATCH_MODE))
		{
			sprint(self, "Command valid in match modes only\n");
			return;
		}
		if (clanring_state & CLANRING_MATCH_STARTED)
		{
			sprint(self, "Cannot change time limit while match is in progress.\n");
			return;
		}
	}

	sprint(self, "Select timelimit:\n");
	sprint(self, "\x80\1\x82   \b5 minutes\b  \x80\4\x82 \b20 minutes\b  \x80\7\x82 \b3 minutes\b\n");
	sprint(self, "\x80\2\x82  \b10 minutes\b  \x80\5\x82 \b25 minutes\b\n");
	sprint(self, "\x80\3\x82  \b15 minutes\b  \x80\6\x82 \b30 minutes\b\n");
	sprint(self, "\x80\1\0\x82 \bNo timelimit\b\n");
	sprint(self, "\x80\0\x82  \bcancel\b\n");
	self.use = votables_get_timelimit;
};

// 
//  S E T  O V E R T I M E
//
void() votables_set_overtime =
{
	local string temp;
	local string szplural;

	clanring_overtime = request_overtime;
	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		sprint(self, "Cannot change overtime while match is in progress.\n");
		return;
	}
	if (clanring_overtime == -1)
	{
		announce("Overtime set to Sudden Death");
	}
	else
	{
		if (clanring_overtime == 0)
		{
			announce("Overtime disabled");
		}
		else
		{
			temp = ftos(clanring_overtime);
			szplural = strings_szplural(clanring_overtime);
			announce4("Overtime changed to ", temp, " minute", szplural);
		}
	}

	utils_set_cvar("scratch2", clanring_overtime);
};

//
//  R E Q U E S T  S E T  O V E R T I M E
//
void(float overtime) votables_request_set_overtime =
{
	local string temp;

	overtime = floor(overtime);
	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		sprint(self, "Cannot change overtime while match is in progress.\n");
		return;
	}
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		request_overtime = overtime;
		votables_set_overtime ();
	}
	else
	{
		if (overtime == 0)
		{
			if (vote_init("turn off overtime", "", votables_set_overtime))
			{
				request_overtime = overtime;
				vote_yes();
			}
		}
		else
		{
			if (overtime < 0)
			{
				temp = "\bsudden death\b";
			}
			else
			{
				temp = strings_ftos_bronze (overtime);
			}
			if (vote_init("change overtime to ", temp, votables_set_overtime))
			{
				request_overtime = overtime;
				vote_yes();
			}
		}
	}
};

//
//  G E T  O V E R T I M E
//
void () votables_get_overtime =
{
	if (self.finaldest_z < 6)
	votables_request_set_overtime(self.finaldest_z);
	else if (self.finaldest_z == 6)
	votables_request_set_overtime(10);
	else if (self.finaldest_z == 7)
	votables_request_set_overtime(-1);
	else
	sprint(self, "invalid selection\n");

	self.use = SUB_Null;
};


//
//  S E L E C T  O V E R T I M E
//

void() votables_select_overtime =
{
	if (!(clanring_playmode & CLANRING_MATCH_MODE))
	{
		sprint(self, "Command valid in match mode only\n");
		return;
	}
	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		sprint(self, "Cannot change overtime while match is in progress.\n");
		return;
	}
	sprint(self, "Select overtime:\n");
	sprint(self, "\x80\0\x82 \bturn off\b      \x80\4\x82 \b4 minutes\b\n");
	sprint(self, "\x80\1\x82 \b1 minute\b      \x80\5\x82 \b5 minutes\b\n");
	sprint(self, "\x80\2\x82 \b2 minutes\b     \x80\6\x82 \b10 minutes\b\n");
	sprint(self, "\x80\3\x82 \b3 minutes\b     \x80\7\x82 \bsudden deeath\b\n");
	self.use = votables_get_overtime;
};

void () arena_force_start =
{
	if ((boss.state == CA_MATCH_WAITING))
	{
		boss.forced = TRUE;
		announce ("Match \bforced\b.");
	}
};

void () votables_force_start =
{
	if (mode_is_arena() == FALSE)
		return;

	if (boss.state != CA_MATCH_WAITING)
		return;

	if (number_teams () < 2)
	{
		sprint(self, "Match requires at least \btwo teams\b to force start.\n");
		return;
	}

	if (boss.allready == TRUE)
		return;

	if (self.style & CLANRING_ADMINISTRATOR)
	{
		arena_force_start ();
	}
	else
	{
		if (vote_init ("\bforce match start\b", "", arena_force_start))
			vote_yes ();
	}
};

//
//  S E T  G I B S
//
//  Called when a request to set gibs passes.  The new setting for gibs
//  is specified by the global variable request_gibs.
//
void() votables_set_gibs =
{
	clanring_playmode = (clanring_playmode - (clanring_playmode & (CLANRING_NO_GIBS | CLANRING_LOW_GIBS)));
	if (request_gibs == 0)
	{
		clanring_playmode = clanring_playmode | CLANRING_NO_GIBS;
		announce("Gibs disabled");
	}
	else
	{
		if (request_gibs == 1)
		{
			clanring_playmode = clanring_playmode | CLANRING_LOW_GIBS;
			announce("Gibs set to 'low'");
		}
		else
		{
			announce("Gibs set to 'high'");
		}
	}
	utils_set_cvar ("samelevel", clanring_playmode);
};

//
//  R E Q U E S T  S E T  G I B S
//
//  Called when a player requests a new setting for gibs.
//

void (float gibs) votables_request_set_gibs =
{
	if (clanring_playmode & CLANRING_NO_GIBS)
	{
		if (gibs == 0)
		{
			if (self == world)
			cprint("Gibs already disabled\n");
			else
			sprint(self, "Gibs already disabled\n");
			return;
		}
	}
	else if (clanring_playmode & CLANRING_LOW_GIBS)
	{
		if (gibs == 1)
		{
			if (self == world)
			cprint("\"Gibs already set to 'low'\"\n");
			else
			sprint(self, "Gibs already set to 'low'\n");
			return;
		}
	}
	else
	{
		if (gibs == 2)
		{
			if (self == world)
			cprint("\"Gibs already set to 'high'\"\n");
			else
			sprint(self, "Gibs already set to 'high'\n");
			return;
		}
	}

	// Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		request_gibs = gibs;
		votables_set_gibs();
	}
	else
	{
		local string gibmode;
		if (gibs == 0)
		gibmode = "'disabled'";
		else if (gibs == 1)
		gibmode = "'low'";
		else
		gibmode = "'high'";
		if (vote_init("\bchange gibs to\b ", gibmode, votables_set_gibs))
		{
			request_gibs = gibs;
			vote_yes();
		}
	}
};

//
//  D I S A B L E  I T E M
//
//  Used to disable quad/pent/ring.  Called with the item as 'self'.
//

void () votables_disable_item =
{
	self.effects = self.effects - (self.effects & self.effects);
	self.model = string_null;
	self.solid = SOLID_NOT;
	self.nextthink = 9999999; // must be really big for quaketv
};

//
//  S E T  Q U A D
//
//  Enable/disable quad.
//
void () votables_set_quad =
{
    // Special behavior while auto-ghost is active in DM normal (1v1):
    // - Toggle "ghost/unghost" without physically removing the item
    if (g1v1_in_effect)
    {
        if (clanring_playmode & CLANRING_NO_QUAD)
        {
            // turn it ON within 1v1 (unghost)
            clanring_playmode = clanring_playmode - CLANRING_NO_QUAD;
            g1v1_quad_ghosted = FALSE;
            utils_do_item(SUB_regen, "item_artifact_super_damage"); // ensure present
            bprint("Quad enabled\n");
            G1v1_UpdateQuadAlpha(FALSE); // -> 1.0
        }
        else
        {
            // turn it OFF within 1v1 (ghost, keep entity)
            clanring_playmode = clanring_playmode | CLANRING_NO_QUAD;
            g1v1_quad_ghosted = TRUE;
            bprint("Quad disabled for 1 on 1\n");
            G1v1_UpdateQuadAlpha(TRUE);  // -> 0.5
        }
        utils_set_cvar("samelevel", clanring_playmode);
        return;
    }

    // Normal behavior outside 1v1: physically remove/restore items
    if (clanring_playmode & CLANRING_NO_QUAD)
    {
        utils_do_item(SUB_regen, "item_artifact_super_damage");
        bprint("Quad enabled\n");
        clanring_playmode = clanring_playmode - CLANRING_NO_QUAD;
    }
    else
    {
        utils_do_item(votables_disable_item, "item_artifact_super_damage");
        bprint("Quad disabled\n");
        clanring_playmode = clanring_playmode | CLANRING_NO_QUAD;
    }
    utils_set_cvar("samelevel", clanring_playmode);
};

//
//  R E Q U E S T  S E T  Q U A D
//
//  Request to enable/disable quad.
//
void() votables_request_set_quad =
{
	// Do it right away if we're an administrator, otherwise vote	
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		if (clanring_state & (CLANRING_SETQUAD_COUNT * 4))
		{
			sprint(self, "Stop fucking with the quad\n");
			return;
		}
		clanring_state = clanring_state + CLANRING_SETQUAD_COUNT;
		votables_set_quad ();
	}
	else
	{
		local string newstate;
		if (clanring_playmode & CLANRING_NO_QUAD)
			newstate = "\benable\b";
		else
			newstate = "\bdisable\b";

		if (vote_init(newstate, " \bquad\b", votables_set_quad))
			vote_yes();
	}
};

//
//  S E T  P E N T
//
//  Enable/disable pentagram.
//
void() votables_set_pent =
{
	if (clanring_playmode & CLANRING_NO_PENT)
	{
		utils_do_item(SUB_regen, "item_artifact_invulnerability");
		announce("Pentagram enabled");
		clanring_playmode = clanring_playmode - CLANRING_NO_PENT;
	}
	else
	{
		utils_do_item(votables_disable_item, "item_artifact_invulnerability");
		announce("Pentagram disabled");
		clanring_playmode = clanring_playmode | CLANRING_NO_PENT;
	}
	utils_set_cvar("samelevel", clanring_playmode);
};

//
//  R E Q U E S T  S E T  P E N T
//
//  Request to enable/disable pentagram.
//
void() votables_request_set_pent =
{
	// Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		if (clanring_state & (CLANRING_SETPENT_COUNT * 4))
		{
			sprint(self, "Stop fucking with the pentagram\n");
			return;
		}
		clanring_state = clanring_state + CLANRING_SETPENT_COUNT;
		votables_set_pent();
	}
	else
	{
		local string newstate;
		if (clanring_playmode & CLANRING_NO_PENT)
			newstate = "\benable\b";
		else
			newstate = "\bdisable\b";

		if (vote_init(newstate, " \bpentagram\b", votables_set_pent))
			vote_yes();
	}
};

//
//  S E T  R I N G
//
//  Enable/disable ring of shadows.
//
void() votables_set_ring =
{
	if (clanring_playmode & CLANRING_NO_RING)
	{
		utils_do_item(SUB_regen, "item_artifact_invisibility");
		announce("Ring of shadows enabled");
		clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_NO_RING);
	}
	else
	{
		utils_do_item(votables_disable_item, "item_artifact_invisibility");
		announce("Ring of shadows disabled");
		clanring_playmode = clanring_playmode | CLANRING_NO_RING;
	}
	utils_set_cvar ("samelevel", clanring_playmode);
};

//
//  R E Q U E S T  S E T  R I N G
//
//  Request to enable/disable ring of shadows.
//
void() votables_request_set_ring =
{
	// Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		if (clanring_state & (CLANRING_SETRING_COUNT * 4))
		{
			sprint(self, "Stop fucking with the ring\n");
			return;
		}
		clanring_state = clanring_state + CLANRING_SETRING_COUNT;
		votables_set_ring();
	}
	else
	{
		local string newstate;
		if (clanring_playmode & CLANRING_NO_RING)
		newstate = "\benable\b";
		else
		newstate = "\bdisable\b";

		if (vote_init(newstate, " \bring of shadows\b", votables_set_ring))
			vote_yes();
	}
};

//
//  S E T  O B I T S
//
//  Enable/disable extended obituaries.
//
void() votables_set_obits =
{
	utils_toggle_sflag (CLANRING_EXTENDED_OBITS, "Extended obituaries");
};

//
//  R E Q U E S T  S E T  O B I T S
//
//  Request to enable/disable extended obituaries.
//
void() votables_request_set_obits =
{
    // Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	utils_toggle_sflag(CLANRING_EXTENDED_OBITS, "Extended obituaries");
	else
	{
		local string newstate;
		if ((clanring_playmode & CLANRING_EXTENDED_OBITS))
		newstate = "\bdisable\b";
		else
		newstate = "\benable\b";

								  
		if (vote_init(newstate, " extra obituaries", votables_set_obits))
			vote_yes();
	}
};

//
//  S E T  A U T O P A U S E
//
//  Enable/disable autopausing
//
void() votables_set_autopause =
{
	utils_toggle_sflag (CLANRING_AUTO_PAUSE, "Automatic match pausing");
};

//
//  R E Q U E S T  S E T  A U T O P A U S E
//
//  Request to enable/disable autopausing
//

void() votables_request_set_autopause =
{

	// Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
		utils_toggle_sflag(CLANRING_AUTO_PAUSE, "Automatic match pausing");
	else
	{
		local string newstate;
		if (clanring_playmode & CLANRING_AUTO_PAUSE)
			newstate = "\bdisable\b";
		else
			newstate = "\benable\b";

		if (vote_init(newstate, " \bmatch autopause\b", votables_set_autopause))
			vote_yes();
	}
};

void() StartRuneSpawn;
void() DropRune;

void() votables_set_runes =
{
	if (clanring_playmode & CLANRING_RUNES)
	{		
		utils_do_players(DropRune);
		utils_do_item(SUB_Remove, "item_rune");
		bprint("Runes Disabled\n");		
		clanring_playmode = (clanring_playmode - (clanring_playmode & CLANRING_RUNES));
		utils_set_cvar("samelevel", clanring_playmode);
	}
	else
	{	
		StartRuneSpawn ();
		bprint("Runes Enabled\n");
		clanring_playmode = (clanring_playmode | CLANRING_RUNES);
		utils_set_cvar("samelevel", clanring_playmode);
	}
};

void() votables_request_set_runes =
{
	local string newstate;

	if ((self.style) & CLANRING_ADMINISTRATOR) 
	{
		votables_set_runes ();
	}
	else
	{
		if (!(clanring_playmode & CLANRING_RUNES))
		{		   
			newstate = "\benable\b";
		}
		else
		{
			newstate = "\bdisable\b";
		}
		
		if (vote_init(newstate, " \brunes\b", votables_set_runes))
		{
			vote_yes();
		}
	}
};

//
//  S E T  F A S T S T A R T S
//
//  Enable/disable faststarts
//
void() votables_set_faststarts =
{
	//utils_toggle_sflag (CLANRING_FAST_START, "Fast match starts");
};

//
//  R E Q U E S T  S E T  F A S T S T A R T S
//
//  Request to enable/disable faststarts
//
void() votables_request_set_faststarts =
{
	sprint(self, "there is only fast start\n");
	// local string newstate;

	// if ((self.style & CLANRING_ADMINISTRATOR))
	// {
	// 	votables_set_faststarts ();
	// }
	// else
	// {
	// 	if ((clanring_playmode & CLANRING_FAST_START))
	// 	{
	// 		newstate = "\bdisable\b";
	// 	}
	// 	else
	// 	{
	// 		newstate = "\benable\b";
	// 	}
	// 	if (vote_init(newstate, " fast match starts", votables_set_faststarts))
	// 	{
	// 		vote_yes();
	// 	}
	// }
};

void() votables_do_abortmatch =
{
	if (mode_is_arena())
	{
		boss.aborted = TRUE;
		arena_match_end();
	}
	else
		match_end();
};

void() votables_request_abortmatch =
{
	if (mode_is_arena())
	{
		if ((boss == world) || ((boss.state != CA_MATCH_PLAYING) && (boss.state != CA_MATCH_ROUNDSTART)))
		{
			sprint(self, "No match in progress\n");
			return;
		}
	}
	else if (clanring_playmode & CLANRING_MATCH_MODE)
	{
		if ( !(clanring_state & CLANRING_MATCH_STARTED))
		{
			sprint(self, "No match in progress\n");
			return;
		}
	}
	else
	{
		sprint(self, "Command not valid in this mode\n");
		return;
	}

	if ((self.style) & CLANRING_ADMINISTRATOR) 
	{
		votables_do_abortmatch ();
	}
	else
	{
		if (vote_init("\babort\b", " match", votables_do_abortmatch))
		{
			vote_yes();
		}
	}
};

//
//  S E T  D R O P  P O W E R U P S
//
//  Enable/disable powerup dropping
//
void() votables_set_powerupdrop =
{
	utils_toggle_gflag (CLANRING_POWERUP_DROP, "Powerup Dropping");
};

//
//  R E Q U E S T  S E T  D R O P  P O W E R U P S
//
//  Request to enable/disable powerup dropping
//
void() votables_request_set_powerupdrop =
{
	// Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
		utils_toggle_gflag (CLANRING_POWERUP_DROP, "Powerup Dropping");
	else
	{
		local string newstate;
		if (clanring_gameconfig & CLANRING_POWERUP_DROP)
			newstate = "\bdisable\b";
		else
			newstate = "\benable\b";

		if (vote_init(newstate, " \bpowerup dropping\b", votables_set_powerupdrop))
			vote_yes();
	}
};

// ----------------------------
// Vote callback functions (enable+start / disable+clear)
// ----------------------------
void() votables_qwsucks_enable_and_start_callback =
{
    votables_toggle_qwsucks(1);
    quaketag_start_regular_auto(); // auto-pick a starter and start Tag
};

void() votables_qwsucks_disable_and_clear_callback =
{
    if (crmod_qtag_it != world) quaketag_clear();
    votables_toggle_qwsucks(0);
};

void() votables_q14ever_enable_and_start_callback =
{
    entity target, p, keepself;
    votables_toggle_q14ever(1);
    // Prefer the original requester if still valid
    target = q14ever_last_requester;
    if (!target || !(target.style & CLANRING_CONNECTED) || (target.style & CLANRING_OBSERVER))
    {
        // If Tag is running, prefer the current "it"
        if (crmod_qtag_it != world)
            target = crmod_qtag_it;
    }
    // Fallback: first active non-observer
    if (!target || !(target.style & CLANRING_CONNECTED) || (target.style & CLANRING_OBSERVER))
    {
        p = find(world, classname, "player");
        while (p)
        {
            if ((p.style & CLANRING_CONNECTED) && !(p.style & CLANRING_OBSERVER)) { target = p; break; }
            p = find(p, classname, "player");
        }
    }
    if (!target) { bprint("q14ever: no eligible player to attach.\n"); return; }
    keepself = self; self = target;
    Q14ever_RemoveAllProps();
    q14ever_spawn_penis(self);
    // Keep q14ever activation off CHAN_AUTO so it never masks qwsucks start
    sound(self, CHAN_ITEM, "dog/dsight.wav", 1, ATTN_NONE);
    self = keepself;
};

void() votables_q14ever_disable_and_clear_callback =
{
    // Remove prop(s) but do NOT touch Tag.
    Q14ever_RemoveAllProps();
    votables_toggle_q14ever(0);
};

// ----------------------------
// Single-command, vote-backed toggle + auto-start/clear
// ----------------------------
void() votables_request_qwsucks =
{
    // Only allow in match modes (not CA/RA/DMM4/AIRSHOT/etc.)
    if (!(clanring_playmode & CLANRING_MATCH_MODE))
    {
        sprint(self, "Command valid in match mode only (DM/CTF).\n");
        return;
    }
    if (clanring_playmode & (CLANRING_CA_MODE | CLANRING_RA_MODE | CLANRING_DMM4_MODE | CLANRING_AIRSHOT_MODE |
                             CLANRING_WIPEOUT_MODE))
    {
        sprint(self, "Command valid only in DM/CTF match modes.\n");
        return;
    }
    // Require at least one active (non-observer) player in the level
    if (!votables_has_active_players())
    {
        sprint(self, "Cannot vote: no active players have spawned (observers only).\n");
        return;
    }

    if (!clanring_allow_qwsucks)
    {
        // Turn ON by vote (or admin), then auto-start
        if (self.style & CLANRING_ADMINISTRATOR)
        {
            votables_toggle_qwsucks(1);
            quaketag_start_regular_auto();
            return;
        }
        if (vote_init("Enable qwsucks (regular QuakeTag)", "", votables_qwsucks_enable_and_start_callback))
            vote_yes();
    }
    else
    {
        // Turn OFF by vote (or admin), clearing game if running
        if (self.style & CLANRING_ADMINISTRATOR)
        {
            if (crmod_qtag_it != world) quaketag_clear();
            votables_toggle_qwsucks(0);
            return;
        }
        if (vote_init("Disable qwsucks", "", votables_qwsucks_disable_and_clear_callback))
            vote_yes();
    }
};

void() votables_request_q14ever =
{
    // Only allow in match modes (not CA/RA/DMM4/AIRSHOT/etc.)
    if (!(clanring_playmode & CLANRING_MATCH_MODE))
    {
        sprint(self, "Command valid in match mode only (DM/CTF).\n");
        return;
    }
    if (clanring_playmode & (CLANRING_CA_MODE | CLANRING_RA_MODE | CLANRING_DMM4_MODE | CLANRING_AIRSHOT_MODE |
                             CLANRING_WIPEOUT_MODE))
    {
        sprint(self, "Command valid only in DM/CTF match modes.\n");
        return;
    }
    // Require at least one active (non-observer) player in the level
    if (!votables_has_active_players())
    {
        sprint(self, "Cannot vote: no active players have spawned (observers only).\n");
        return;
    }

    // Remember who asked; we'll attach to them on success.
    q14ever_last_requester = self;
    // Normalize the toggle based on current world state (prop/flag may be out of sync)
    Q14ever_SyncFlag();

    if (!clanring_allow_q14ever)
    {
        // If the requester already has a prop, do NOT allow another enable vote.
        // (Others can still enable to reattach to themselves.)
        local entity pe;
        pe = find(world, classname, "penis");
        while (pe)
        {
            if (pe.owner == self) { sprint(self, "q14ever is already enabled for you.\n"); return; }
            pe = find(pe, classname, "penis");
        }
        pe = find(world, classname, "q14ever_penis");
        while (pe)
        {
            if (pe.owner == self) { sprint(self, "q14ever is already enabled for you.\n"); return; }
            pe = find(pe, classname, "q14ever_penis");
        }

        if (self.style & CLANRING_ADMINISTRATOR)
        {
            // Admin enable: also block if the requester already has the prop.
            pe = find(world, classname, "penis");
            while (pe)
            {
                if (pe.owner == self) { sprint(self, "q14ever is already enabled for you.\n"); return; }
                pe = find(pe, classname, "penis");
            }
            pe = find(world, classname, "q14ever_penis");
            while (pe)
            {
                if (pe.owner == self) { sprint(self, "q14ever is already enabled for you.\n"); return; }
                pe = find(pe, classname, "q14ever_penis");
            }
            entity keepself; votables_toggle_q14ever(1);
            keepself = self; Q14ever_RemoveAllProps(); q14ever_spawn_penis(self);
            sound(self, CHAN_ITEM, "dog/dsight.wav", 1, ATTN_NONE);
            self = keepself; return;
        }
        if (vote_init("Enable q14ever (overlay)", "", votables_q14ever_enable_and_start_callback))
            vote_yes();
    }
    else
    {
        if (self.style & CLANRING_ADMINISTRATOR)
        {
            // Admin disable removes the prop but leaves Tag alone
            Q14ever_RemoveAllProps();
            votables_toggle_q14ever(0);
            return;
        }
        if (vote_init("Disable q14ever", "", votables_q14ever_disable_and_clear_callback))
            vote_yes();
    }
};

// ----------------------------
// The actual togglers
// ----------------------------
void(float on) votables_toggle_qwsucks =
{
    if (on)
    {
        clanring_allow_qwsucks = 1;
        cvar_set("cr_allow_qwsucks", "1"); // keep cvar in sync/persistent
        bprint("\bQWSUCKS enabled\b (regular QuakeTag).\n");
    }
    else
    {
        clanring_allow_qwsucks = 0;
        cvar_set("cr_allow_qwsucks", "0");
        bprint("\bQWSUCKS disabled\b.\n");
    }
};


void(float on) votables_toggle_q14ever =
{
    if (on)
    {
        clanring_allow_q14ever = 1;
        cvar_set("cr_allow_q14ever", "1");
        bprint("\bQ14EVER enabled\b (overlay).\n");
    }
    else
    {
        clanring_allow_q14ever = 0;
        cvar_set("cr_allow_q14ever", "0");
        bprint("\bQ14EVER disabled\b.\n");
        // Defensive: ensure no lingering prop
        Q14ever_RemoveAllProps();
    }
};

