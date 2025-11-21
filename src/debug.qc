//
// Debug.qc
//
// Debugging routines
//

float () options_get_mode;

//
//  I N F O
//
//  General info - currently autochase scores
//
void() debug_info =
{
	local entity e;
	local string temp;//R00k move here

	sprint(self, "clients:\n");
	e = find(world, classname, "player");
	while (e)
	{
		if ((e.style & CLANRING_CONNECTED) && !(e.style & CLANRING_OBSERVER))
		{
			//local string temp;
			temp = ftos(e.colormap);
			sprint4(self, temp, " ", e.netname, "   ");
			temp = ftos(e.clanring_chase_score);
			sprint2(self, temp, "\n");
		}
		e = find(e, classname, "player");
	}
	sprint(self, "cameras:\n");
	e = find(world, classname, "clanring_camera");
	while (e)
	{
		//local string temp;
		temp = ftos(e.clanring_chase_score);
		sprint2(self, temp, " ");
		e = find(e, classname, "clanring_camera");
	}
	sprint(self, "\n");
};

//
//  F L A G S
//
//  Dump the server flags
//
void() debug_flags =
{
	sprint(self, "Server flags:\n");
	sprint(self, "\n");

	// playmode flags
	if (clanring_playmode & CLANRING_NORMAL_MODE)
		sprint(self, "CLANRING_NORMAL_MODE\n");
	if (clanring_playmode & CLANRING_MATCH_MODE)
		sprint(self, "CLANRING_MATCH_MODE\n");
	if (clanring_playmode & CLANRING_PRACTICE_MODE)
		sprint(self, "CLANRING_PRACTICE_MODE\n");
	if (clanring_playmode & CLANRING_SERVER_INITIALIZED)
		sprint(self, "CLANRING_SERVER_INITIALIZED\n");
	if (clanring_playmode & CLANRING_NO_GIBS)
		sprint(self, "CLANRING_NO_GIBS\n");
	if (clanring_playmode & CLANRING_LOW_GIBS)
		sprint(self, "CLANRING_LOW_GIBS\n");
	if (clanring_playmode & CLANRING_NO_QUAD)
		sprint(self, "CLANRING_NO_QUAD\n");
	if (clanring_playmode & CLANRING_NO_PENT)
		sprint(self, "CLANRING_NO_PENT\n");
	if (clanring_playmode & CLANRING_NO_RING)
		sprint(self, "CLANRING_NO_RING\n");
	if (clanring_playmode & CLANRING_MODE_VOTE)
		sprint(self, "CLANRING_MODE_VOTE\n");
	if (clanring_playmode & CLANRING_NO_SPOOGE)
		sprint(self, "CLANRING_NO_SPOOGE\n");
	if (clanring_playmode & CLANRING_EXTENDED_OBITS)
		sprint(self, "CLANRING_EXTENDED_OBITS\n");
	if (clanring_playmode & CLANRING_CONSOLE_INITIALIZED)
		sprint(self, "CLANRING_CONSOLE_INITIALIZED\n");
	// if (clanring_playmode & CLANRING_FAST_START)
	// 	sprint(self, "CLANRING_FAST_START\n");
/*	if (clanring_playmode & CLANRING_FRESH_SPAWNS)
		sprint(self, "CLANRING_FRESH_SPAWNS\n");
*/
	if (clanring_playmode & CLANRING_AUTO_PAUSE)
		sprint(self, "CLANRING_AUTO_PAUSE\n");
	if (clanring_playmode & CLANRING_CONSOLE_STATS)
		sprint(self, "CLANRING_CONSOLE_STATS\n");

	sprint(self, "\n");

	// state flags
	if (clanring_state & CLANRING_TIMER_STARTED)
		sprint(self, "CLANRING_TIMER_STARTED\n");
	if (clanring_state & CLANRING_MATCH_STARTED)
		sprint(self, "CLANRING_MATCH_STARTED\n");
	if (clanring_state & CLANRING_MATCH_PAUSED)
		sprint(self, "CLANRING_MATCH_PAUSED\n");
	if (clanring_state & CLANRING_MATCH_OVER)
		sprint(self, "CLANRING_MATCH_OVER\n");
	if (clanring_state & CLANRING_MATCH_WAIT)
		sprint(self, "CLANRING_MATCH_WAIT\n");
	if (clanring_state & CLANRING_KICKING)
		sprint(self, "CLANRING_KICKING\n");
	if (clanring_state & CLANRING_NO_PRACTICE)
		sprint(self, "CLANRING_NO_PRACTICE\n");
	if (clanring_state & CLANRING_UNPAUSING)
		sprint(self, "CLANRING_UNPAUSING\n");
	if (clanring_state & CLANRING_AUTO_PAUSED)
		sprint(self, "CLANRING_AUTO_PAUSED\n");
	if (clanring_state & CLANRING_DELAYED_AUTOSS)
		sprint(self, "CLANRING_DELAYED_AUTOSS\n");
	if (clanring_state & CLANRING_TAKING_AUTOSS)
		sprint(self, "CLANRING_TAKING_AUTOSS\n");
	sprint(self, "\n");
};

//
//  V A R S
//
//  Dumps certain elohim global variables to the console.
//
//  (Do NOT dump clanring_password)
//
void() debug_vars =
{
	// entities
	sprint(self, "dm_num_spawns = ");
	utils_print_float(dm_num_spawns);
	sprint(self, "clanring_num_starts = ");
	utils_print_float(clanring_num_starts);
	sprint(self, "clanring_num_cameras = ");
	utils_print_float(clanring_num_cameras);
	sprint(self, "clanring_score_count = ");
	utils_print_float(clanring_score_count);
	sprint(self, "clanring_numteams = ");
	utils_print_float(clanring_numteams);
	sprint(self, "clanring_sentinel.ammo_rockets = ");
	utils_print_float(clanring_sentinel.ammo_rockets);
};

//
//  C V A R  T H I N K
//
void() debug_cvar_think =
{
	local float f;
	local string s;

	f = cvar(self.owner.netname);
	s = ftos(f);
	sprint4(self.owner, self.owner.netname, " = ", s, "\n");
	stuffcmd(self.owner, "name clanringdebug\n");
	remove(self);
};

//
//  P A R M 1  T H I N K
//
void() debug_parm1_think =
{
	local string s;

	s = ftos(auto_parm1);
	sprint3(self.owner, "auto_parm1 changed from ", s, " to ");
	auto_parm1 = utils_stof (self.owner.netname);
	s = ftos(auto_parm1);
	sprint2(self.owner, s, "\n");
	stuffcmd(self.owner, "name clanringdebug\n");
	remove(self);
};

//
//  P A R M 2  T H I N K
//
void() debug_parm2_think =
{
	local string s;

	s = ftos(auto_parm2);
	sprint3(self.owner, "auto_parm2 changed from ", s, " to ");
	auto_parm2 = utils_stof (self.owner.netname);
	s = ftos(auto_parm2);
	sprint2(self.owner, s, "\n");
	stuffcmd(self.owner, "name clanringdebug\n");
	remove(self);
};

//
//  P A R M 3  T H I N K
//
void() debug_parm3_think =
{
	local string s;

	s = ftos(auto_parm3);
	sprint3(self.owner, "auto_parm3 changed from ", s, " to ");
	auto_parm3 = utils_stof (self.owner.netname);
	s = ftos(auto_parm3);
	sprint2(self.owner, s, "\n");
	stuffcmd(self.owner, "name clanringdebug\n");
	remove(self);
};

//
//  P A R M 4  T H I N K
//
void() debug_parm4_think =
{
	local string s;

	s = ftos(auto_parm4);
	sprint3(self.owner, "auto_parm4 changed from ", s, " to ");
	auto_parm4 = utils_stof (self.owner.netname);
	s = ftos(auto_parm4);
	sprint2(self.owner, s, "\n");
	stuffcmd(self.owner, "name clanringdebug\n");
	remove(self);
};

//
//  P A R M S
//
void() debug_parms =
{
	sprint(self, "auto_parm1 = ");
	utils_print_float(auto_parm1);
	sprint(self, "auto_parm2 = ");
	utils_print_float(auto_parm2);
	sprint(self, "auto_parm3 = ");
	utils_print_float(auto_parm3);
	sprint(self, "auto_parm4 = ");
	utils_print_float(auto_parm4);
};

//
//  C L I E N T  F L A G S
//
//  Dumps movetarget's flags
//
void() debug_client_flags =
{
	local float nulltarget;

	nulltarget = 0;
	if (!self.movetarget)
	{
		self.movetarget = self;
		nulltarget = 1;
	}
    sprint3(self, "Client flags for ", self.movetarget.netname, ":\n");
    sprint(self, "\n");
    if (self.movetarget.style & CLANRING_NEW_CLIENT)
        sprint(self, "CLANRING_NEW_CLIENT\n");
    if (self.movetarget.style & CLANRING_ADMINISTRATOR)
        sprint(self, "CLANRING_ADMINISTRATOR\n");
/*   	if (self.movetarget.style & CRMOD_DETECTING_QSMACK)	// CRMOD was SMOOTH
		sprint(self, "CRMOD_DETECTING_QSMACK\n");					// CRMOD was SMOOTH*/
	if (self.movetarget.oflags & OBSERVER_POP_FORWARD)
        sprint(self, "OBSERVER_POP_FORWARD\n");
    if (self.movetarget.style & CLANRING_READY)
        sprint(self, "CLANRING_READY\n");
    if (self.movetarget.style & CLANRING_YES)
        sprint(self, "CLANRING_YES\n");
    if (self.movetarget.style & CLANRING_HEADS_UP)
        sprint(self, "CLANRING_HEADS_UP\n");
    if (self.movetarget.style & CLANRING_SETTING_OPTIONS)
        sprint(self, "CLANRING_SETTING_OPTIONS\n");
    if (self.movetarget.style & CLANRING_MOTD)
        sprint(self, "CLANRING_MOTD\n");
    if (self.movetarget.style & CLANRING_OK_TO_SHOOT)
        sprint(self, "CLANRING_OK_TO_SHOOT\n");
    if (self.movetarget.style & CLANRING_KICK_CONFIRM)
        sprint(self, "CLANRING_KICK_CONFIRM\n");
    if (self.movetarget.style & CLANRING_CONFIRM_LEAVE)
        sprint(self, "CLANRING_CONFIRM_LEAVE\n");
    if (self.movetarget.style & CLANRING_CONNECTED)
        sprint(self, "CLANRING_CONNECTED\n");
    if (self.movetarget.style & CLANRING_FOUND_BINDINGS)
        sprint(self, "CLANRING_FOUND_BINDINGS\n");
	if (self.movetarget.style & CLANRING_SMART_WEAPON)
		sprint(self, "CRMOD_SMART_WEAPON\n");
    if (self.movetarget.style & CLANRING_OBSERVER)
        sprint(self, "CLANRING_OBSERVER\n");
/*    if (self.movetarget.style & CRMOD_QSMACK)
        sprint(self, "CRMOD_QSMACK\n");*/
    if (self.movetarget.style & CLANRING_SCOREBOARD)
        sprint(self, "CLANRING_SCOREBOARD\n");
    if (self.movetarget.style & CLANRING_NO_POST_THINK)
        sprint(self, "CLANRING_NO_POST_THINK\n");
    if (self.movetarget.style & CLANRING_WINQUAKE)
        sprint(self, "CLANRING_WINQUAKE\n");
    if (self.movetarget.style & CLANRING_GLQUAKE)
        sprint(self, "CLANRING_GLQUAKE\n");
    if (self.movetarget.style & CLANRING_AUTOSTATS)
        sprint(self, "CLANRING_AUTOSTATS\n");
    sprint(self, "\n");

    if (self.movetarget.oflags & OBSERVER_WALK)
        sprint(self, "OBSERVER_WALK\n");
    if (self.movetarget.oflags & OBSERVER_FLY)
        sprint(self, "OBSERVER_FLY\n");
    if (self.movetarget.oflags & OBSERVER_CHASE)
        sprint(self, "OBSERVER_CHASE\n");
    if (self.movetarget.oflags & OBSERVER_DEMO)
        sprint(self, "OBSERVER_DEMO\n");
    if (self.movetarget.oflags & OBSERVER_CAMERA)
    	sprint(self, "OBSERVER_CAMERA\n");
	if (self.movetarget.oflags & OBSERVER_AUTO)
		sprint(self, "OBSERVER_AUTO\n");
	if (self.movetarget.oflags & OBSERVER_TOURNEY)
		sprint(self, "OBSERVER_TOURNEY\n");
	if (self.movetarget.oflags & OBSERVER_GO_AUTO)
		sprint(self, "OBSERVER_GO_AUTO\n");
	if (self.movetarget.oflags & OBSERVER_COMMENTARY)
		sprint(self, "OBSERVER_COMMENTARY\n");
	if (self.movetarget.style & CLANRING_BLUE_TEAM)
		sprint(self, "CLANRING_BLUE_TEAM\n");
	if (self.movetarget.style & CLANRING_RED_TEAM)
		sprint(self, "CLANRING_RED_TEAM\n");
	sprint(self, "\n");
	
	if (nulltarget)
		self.movetarget = world;
};

//
//  G E T  M O V E T A R G E T
//
void() debug_get_movetarget =
{
	self.use = SUB_Null;
	other = self.movetarget;
	self.movetarget = find(world, classname, "player");
	while (self.movetarget)
	{
		if (self.movetarget.colormap == self.finaldest_z)
		{
			sprint3(self, "Debugging ", self.movetarget.netname, "\n");
			return;
		}
		self.movetarget = find(self.movetarget, classname, "player");
	}
	sprint(self, "Not found\n");
	self.movetarget = other;
};

//
//  H E L P
//
//  Print out debug commands
//
void() debug_help =
{
	sprint(self, "Debug commands:\n");
	sprint(self, " dbinfo     - General info\n");
	sprint(self, " dbflags    - Server flags\n");
	sprint(self, " dbvars     - ClanRing global variables\n");
	sprint(self, " dbcvar     - Console variable\n");
	sprint(self, " dbclient   - Choose movetarget\n");
	sprint(self, " dbcflags   - View movetarget flags\n");
	sprint(self, " dbparm1-4  - change auto_parm1-4\n");
	sprint(self, " dbparms    - view auto_parms\n");
	sprint(self, " dbplayers  - list players\n");
	sprint(self, " dbteams    - list teams\n");
	sprint(self, " dbsettings - list server settings\n");
	sprint(self, " dbents     - show entity information\n");
	sprint(self, " dbwingl    - who is using dos/win/gl\n");
};

//
//  P L A Y E R S
//
void() debug_players =
{
	local entity player;

	player = clanring_sentinel.next_player;
	while (player)
	{
		sprint2(self, player.netname, "\n");
		player = player.next_player;
	}
};

//
//  T E A M S
//
void() debug_teams =
{
	local entity pteam;
	local entity player;
	local float n;

	if (!(clanring_playmode && CLANRING_MATCH_MODE) || !teamplay)
	{
		{
			local float mode; local string szmode;
			mode = options_get_mode(); szmode = strings_get_mode(mode);
			sprint(self, sprintf("Valid in match mode only (current: %s)\n", szmode));
		}
		return;
	}
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		sprint2(self, pteam.mdl, " - rockets = ");
		utils_print_float(pteam.ammo_rockets);
		n = pteam.count;
		player = pteam.next_player;
		while (n)
		{
			sprint3(self, "    ", player.netname, "\n");
			player = player.next_player;
			n -= 1;
		}
		pteam = pteam.next_team;
	}
};


//
//  O N O F F
//
void(float val) debug_onoff = 
{
	if (val)
		sprint(self, "on\n");
	else
		sprint(self, "off\n");
};

//
//  S H O W  C V A R
//
void(string varname) debug_show_cvar = 
{
	local float temp;

	temp = cvar(varname);
	sprint(self, varname, " = ");
	utils_print_float(temp);
};

//
//  S E T T I N G S
//
void() debug_settings =
{
	local float temp;
	local string sz;

	temp = options_get_mode ();
	sz = strings_get_mode (temp);
	sprint2(self, sz, " mode\n");
	debug_show_cvar("timelimit");
	debug_show_cvar("fraglimit");
	debug_show_cvar("teamplay");
	debug_show_cvar("deathmatch");
	debug_show_cvar("pausable");
	temp = cvar("sys_ticrate");
	sprint(self, "sys_ticrate = ");
	utils_print_floatn(temp, 3);
	sprint(self, "overtime: ");
	if (clanring_overtime == -1)
		sprint(self, "sudden death\n");
	else if (clanring_overtime == 0)
		sprint(self, "disabled\n");
	else
	{
		sz = ftos(clanring_overtime);
		sprint(self, sz);
		sz = strings_szplural(clanring_overtime);
		sprint3(self, " minute", sz, "\n");
	}

	sz = ftos(clanring_maxteams);
	sprint3(self, "maxteams: ", sz, "\n");
	sprint(self, "gibs: ");
	if (clanring_playmode & CLANRING_NO_GIBS)
		sprint(self, "off\n");
	else if (clanring_playmode & CLANRING_LOW_GIBS)
		sprint(self, "low\n");
	else
		sprint(self, "high\n");

	sprint(self, "safe practice: ");
	debug_onoff(clanring_playmode & CLANRING_NO_SPOOGE);
	sprint(self, "quad: ");
	debug_onoff(CLANRING_NO_QUAD - (clanring_playmode & CLANRING_NO_QUAD));
	sprint(self, "pentagram: ");
	debug_onoff(CLANRING_NO_PENT - (clanring_playmode & CLANRING_NO_PENT));
	sprint(self, "ring: ");
	debug_onoff(CLANRING_NO_RING - (clanring_playmode & CLANRING_NO_RING));
	sprint(self, "mode voting: ");
	debug_onoff(clanring_playmode & CLANRING_MODE_VOTE);
	sprint(self, "extended obituaries: ");
	debug_onoff(clanring_playmode & CLANRING_EXTENDED_OBITS);
	// sprint(self, "fast match starts: ");
	// debug_onoff(clanring_playmode & CLANRING_FAST_START);
/*	sprint(self, "fresh spawns: ");
	debug_onoff ((clanring_playmode & CLANRING_FRESH_SPAWNS));
*/
};

//
//  E N T I T I E S
//
void() debug_entities =
{
	local entity e;
	local float num;

	e = nextent (world);
	sprint3(self, "  0 \"", e.classname, "\"\n");
	num = 1;
	while (e)
	{
		utils_print_int3 (num);
		num = (num + 1);
		sprint3(self, " \"", e.classname, "\"\n");
		e = nextent (e);
	}
};

//
//  W I N G L
//
void() debug_wingl = 
{
	local entity e;

	sprint(self, "\b Quake Version | Name\n");
	sprint(self, "\b---------------+----------------\n");
	e = find(world, classname, "player");
	while (e)
	{
		if (e.style & CLANRING_CONNECTED)
		{
			if (e.style & CLANRING_WINQUAKE)
			{
				if (e.style & CLANRING_GLQUAKE)
					sprint3(self, "   ???         ü ", e.netname, "\n");
				else
					sprint3(self, "   WinQuake    ü ", e.netname, "\n");
			}
			else if (e.style & CLANRING_GLQUAKE)
					sprint3(self, "   GlQuake     ü ", e.netname, "\n");
			else
					sprint3(self, "   DosQuake    ü ", e.netname, "\n");
		}
		e = find(e, classname, "player");
	}
};

//
//  L O A D  A L I A S E S
//
void() debug_load_aliases =
{
	sprint(self, "Loading debug binds...\n");
	stuffcmd(self, "alias dbbinds echo debug binds already loaded\n");
	stuffcmd(self, "alias dbinfo impulse 40\n");
	stuffcmd(self, "alias dbflags impulse 41\n");
	stuffcmd(self, "alias dbvars impulse 42\n");
	stuffcmd(self, "alias dbcvar impulse 43\n");
	stuffcmd(self, "alias dbclient impulse 44\n");
	stuffcmd(self, "alias dbcflags impulse 45\n");
	stuffcmd(self, "alias dbparm1 impulse 46\n");
	stuffcmd(self, "alias dbparm2 impulse 47\n");
	stuffcmd(self, "alias dbparm3 impulse 48\n");
	stuffcmd(self, "alias dbparm4 impulse 49\n");
	stuffcmd(self, "alias dbparms impulse 50\n");
	stuffcmd(self, "alias dbplayers impulse 51\n");
	stuffcmd(self, "alias dbteams impulse 52\n");
	stuffcmd(self, "alias dbsettings impulse 53\n");
	stuffcmd(self, "alias dbents impulse 54\n");
	stuffcmd(self, "alias dbwingl impulse 55\n");
	stuffcmd(self, "alias dbhelp impulse 59\n");
};

//
//  I M P U L S E
//
void() debug_impulse =
{
	if (!(self.style & CLANRING_ADMINISTRATOR) && (self.netname != "clanringdebug"))
		return;

	switch(self.impulse)
	{
		case 40: debug_info (); break;		
		case 41: debug_flags (); break;
		case 42: debug_vars (); break;
		case 43: utils_make_scheduled_event(debug_cvar_think, 0.5); break;
		case 44:
		{
			sprint(self, "Enter client number:\n");
			self.use = debug_get_movetarget;
			break;
		}
		case 45: debug_client_flags (); break;
		case 46: utils_make_scheduled_event(debug_parm1_think, 0.5); break;
		case 47: utils_make_scheduled_event(debug_parm2_think, 0.5); break;
		case 48: utils_make_scheduled_event(debug_parm3_think, 0.5); break;
		case 49: utils_make_scheduled_event(debug_parm4_think, 0.5); break;
		case 50: debug_parms (); break;
		case 51: debug_players (); break;
		case 52: debug_teams (); break;
		case 53: debug_settings (); break;
		case 54: debug_entities (); break;
		case 55: debug_wingl (); break;
		case 58: debug_load_aliases (); break;
		case 59: debug_help (); break;
	}
};
