//
// Admin.qc
//
// Administrative functions for the Elohim server mod.
//
// Fields used:
//
// .count           - used for entering password
//
// All code by J.P. Grossman unless otherwise commented.
//

// function declarations
void() admin_cancel_kick;
void() admin_confirm_kick;
void() admin_do_kick;

void() admin_cancel_ban;
void() admin_confirm_ban;
void() admin_do_ban;

void() options_start_setting;
void() SUB_Freeze;
void() W_SetCurrentAmmo;

// global variables
entity kick_target;         // Player to kick

//
//  S E N D  A L I A S E S
//
//  Stuffs admin-only aliases into the administrators console.  Called
//  when a player becomes an administrator.
//
void() admin_send_aliases =
{
//	stuffcmd(self, "alias qsmack impulse 37\n");		//R00k removed
	stuffcmd(self, "alias bans impulse 197\n");
	stuffcmd(self, "alias unban impulse 198\n");
	stuffcmd(self, "alias help-admin impulse 200\n");
	stuffcmd(self, "alias autoss impulse 204\n");
	stuffcmd(self, "alias crban impulse 205\n");
	stuffcmd(self, "alias ips impulse 206\n");
	stuffcmd(self, "alias dmset impulse 207\n");
	stuffcmd(self, "alias maxteams impulse 208\n");
	stuffcmd(self, "alias faststart impulse 209\n");	//R00k added for users to vote
	stuffcmd(self, "alias ghostlist impulse 212\n");
	stuffcmd(self, "alias kick! impulse 213\n");
	stuffcmd(self, "alias skick impulse 213\n");
    stuffcmd(self, "alias crkick impulse 213\n");		//I think we need more kick aliases
	stuffcmd(self, "alias safepractice impulse 224\n");
	stuffcmd(self, "alias modevote impulse 228\n");
	stuffcmd(self, "alias options impulse 229\n");

    // spawn point editing
	stuffcmd(self, "alias nextspawn impulse 246\n");
	stuffcmd(self, "alias makespawn impulse 247\n");
	stuffcmd(self, "alias nextcam impulse 248\n");
	stuffcmd(self, "alias makecam impulse 249\n");
/*
	// TRAINING
	training_send_aliases();
*/
};

//
//  C R E A T E
//
//  Turn 'self' into an administrator.
//
void() admin_create =
{
	local string s;

	s = ftos(self.clanring_hack_count);
	self.style = self.style | CLANRING_ADMINISTRATOR;
	self.use = SUB_Null;
	centerprint (self, "You are now an administrator");
	announce4(self.netname, " has become an administrator (code ", s, ")");
	admin_send_aliases ();
};

//
//  E N T E R  C O D E
//
//  Enter another code digit.
//  The digit being entered is stored in self.finaldest_z.
//  The digits that are entered are accumulated by self.count;
//  when self.count == elohim_password the client is made into an
//  administrator.
//
void() admin_enter_code =
{
	local float temp = 0;

    if (self.finaldest_z > 9)
		return;

	self.count = self.count * 10 + self.finaldest_z;
	if (self.count >= 1000)
	{
		for (temp = 0 ; temp < array_password.length ; temp = temp + 1)//Spike modified
		{
			if (self.count == array_password[temp])
			{
				self.clanring_hack_count = temp;
				admin_create();
				return;
			}
		}
	}
	if (self.count >= 1000000)
	{
        sprint(self, "Invalid code\n");
        self.use = SUB_Null;
		self.clanring_hack_count = self.clanring_hack_count + 1;
		if (self.clanring_hack_count > 3)
		{
			announce2(self.netname, " kicked for admin hacking");
			clanring_kick_player(self);
		}
	}
	else
		sprint(self, "Enter the next code digit:\n");
};

//
//  S T A R T  C O D E
//
//  Initiate the admin code sequence.
//
void() admin_start_code =
{
	if (array_password[0] == 0)
	{
		sprint(self, "Administrator password disabled\n");
		sprint(self, "Edit the 'configs/clanring.cfg' on the server.\n");
		return;
	}
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		sprint(self, "You are no longer an administrator.\n");
		self.style = self.style - CLANRING_ADMINISTRATOR;
		self.clanring_hack_count = 0;
		return;
	}
	sprint(self, "Enter the first code digit:\n");
	self.count = 0;
	self.use = admin_enter_code;
};

void()admin_show_ip_list =
{
	local entity e;
	sprint(self, "\n ip address          ü      name\n");
	sprint(self, "­­­­­­­­­­­­­­­­­­­­­«­­­­­­­­­­­­­­­­­\n");
	e = find(world, classname, "player");
	while (e)
	{
		if ((e.style & CLANRING_CONNECTED) && (!(e.style & CLANRING_ADMINISTRATOR)))
		{
			sprint4(self, infokey(e, INFOKEY_P_IP), " ü ", e.netname, "\n");
		}
		e = find(e, classname, "player");
	}
};

//
//  K I C K  P L A Y E R
//
void(entity client) clanring_kick_player =
{
	local string temp;
	local entity oself;

	if (client.style & CLANRING_ADMINISTRATOR)
	{
		clanring_kick_mode = 0;
		return;//crashproof!
	}

	if (!(client.style & CLANRING_CONNECTED))
	{
		clanring_kick_mode = 0;
		return;
	}

	if (gameover)//hmm fixme?
	{
		clanring_kick_mode = 0;
		return;
	}

	if (client.style & CLANRING_NEW_CLIENT)
	{
		clanring_kick_mode = 0;
		return;
	}

	client.takedamage = DAMAGE_NO;

	if (clanring_kick_mode == KICK_KICK)
	{
		announce2(client.netname, " was kicked!");
		temp = ftos(client.colormap);
		localcmd3("kick # ", temp, "\n");
	}
	else
	{
		if (clanring_kick_mode == KICK_BAN)
		{
			utils_make_scheduled_event(ban_kick_client, sys_ticrate);
			clanring_kick_mode = 0;//1/11/2016 11:00PM --FIXME--TESTING!!!
			return;//R00k: forgot this return! FIXED 9/7/2011 10:45PM
		}
		else
		{
			if (clanring_kick_mode == KICK_AFK)
			{
				announce2(client.netname, " was kicked for being afk.");
				temp = ftos(client.colormap);
				localcmd3("kick # ", temp, "\n");
			}
			else
			{
				if (clanring_kick_mode == KICK_LAGOUT)
				{
					announce2(client.netname, " lost connection to the server.");
					temp = ftos(client.colormap);
					localcmd3("kick # ", temp, "\n");
				}
				else
				{
					bprint("Error Kick Called without kick_mode set\n");
					clanring_kick_mode = 0;
					return;
				}
			}
		}
	}

	oself = self;
	self = client;
	ClientDisconnect ();
	self = oself;
	clanring_kick_mode = 0;
};
//
//  P R I N T  K I C K  C H O I C E
//
//  Display a choice of players to kick.
//
void() admin_print_kick_choice =
{
	local entity client;
	local float index;
	local string num;

    // Print the choice
	sprint(self, "Which player do you want to kick?\n");
	sprint(self, " 0  cancel\n");

	for (index = 1 ; index < array_kick.length ; index = index + 1)//Spike modified
    {
        client = array_kick[index];
        if (client)
        {
            num = ftos(index);
            sprint(self, " ", num, " ", client.netname, "\n");
        }
    }
};

//
//  S T A R T  K I C K
//
//  Get a list of players and ask the admin which one to kick.
//
void() admin_start_kick =
{
	if ((clanring_state & CLANRING_KICKING))
	{
		sprint(self, "There is already a kick in progress\n");
		return;
	}

    // Get the list of players
    local entity client;
    local float index;

	index = 1;
	client = find(world, classname, "player");
	while (client)
	{
		if (client.style & CLANRING_CONNECTED)
		{
			if (!(client.style & CLANRING_ADMINISTRATOR) || (client.clanring_hack_count && !self.clanring_hack_count))
			{
				array_kick[index] = client;
				index += 1;
			}
		}
		client = find(client, classname, "player");
	}
	if (index == 1)
	{
		sprint(self, "There is no-one to kick\n");
		return;
	}
	for ( ; index < array_kick.length ; index = index + 1)//Spike modified
		array_kick[index] = world;

	// Print the choice
	admin_print_kick_choice ();

    // Set up the kick
    local entity kick_timeout;
	self.use = admin_confirm_kick;
	kick_timeout = spawn();
	kick_timeout.movetarget = self;
	kick_timeout.classname = "clanring_kick_timeout";
	kick_timeout.think = admin_cancel_kick;
	kick_timeout.nextthink = time + 10;
	clanring_state = (clanring_state | CLANRING_KICKING);
};

//
//  C O N F I R M  K I C K
//
//  Ask for confirmation to kick the selected player.  The index of
//  the player to be kicked is stored in self.finaldest_z.
//
void() admin_confirm_kick =
{
	if (self.finaldest_z == 0)
	{
		// Cancel the kick
		local entity oself;
		oself = self;
		self = find(world, classname, "clanring_kick_timeout");
		admin_cancel_kick ();
		self = oself;
		return;
	}

	kick_target = array_kick[self.finaldest_z];

	// sanity checks
	if (!kick_target)
	{
		sprint(self, "Invalid\n");
		admin_print_kick_choice ();
		return;
	}
	if ((kick_target.style & CLANRING_ADMINISTRATOR) && (!kick_target.clanring_hack_count || self.clanring_hack_count))
	{
		sprint2(self, kick_target.netname, " is an administrator\n");
		admin_print_kick_choice ();
		return;
	}
    // ask for confirmation
	sprint3(self, "kick ", kick_target.netname, "?\n");
	self.style = (self.style | CLANRING_KICK_CONFIRM);
	clanring_kick_mode = KICK_KICK;
};
//
//  C O N F I R M  K I C K  R E S P O N S E
//
//  Called when the administrator enters 'yes' or 'no' in
//  response to the confirmation request.
//
void(float fDoKick) admin_confirm_kick_response =
{
	if (fDoKick)
		admin_do_kick ();
	else
	{
		// Cancel the kick
		local entity oself;
		oself = self;
		self = find(world, classname, "clanring_kick_timeout");
		admin_cancel_kick ();
		self = oself;
	}
};

//
//  D O  K I C K
//
//  Kick a player once the admin has confirmed.
//

void() admin_do_kick =
{
	clanring_kick_mode = KICK_KICK;
	clanring_kick_player (kick_target);
	self.use = SUB_Null;
    // Clean up
	kick_target = find(world, classname, "clanring_kick_timeout");
	remove(kick_target);
	clanring_state = clanring_state - (clanring_state & CLANRING_KICKING);
	self.style = self.style - (self.style & CLANRING_KICK_CONFIRM);
};
//
//  C A N C E L  K I C K
//
//  Called when the kick times out or is cancelled by the admin.
//
void() admin_cancel_kick =
{
	sprint(self.movetarget, "Kick cancelled\n");
	self.movetarget.use = SUB_Null;
	remove(self);
	clanring_state = clanring_state - (clanring_state & CLANRING_KICKING);
	self.movetarget.style = (self.movetarget.style - (self.movetarget.style & CLANRING_KICK_CONFIRM));
	clanring_kick_mode = 0;
};

//
//  B A N
//
void() admin_print_ban_choice =
{
	local entity client;
	local float index;
	local string num;

	sprint(self, "Which player do you want to ban?\n");
	sprint(self, " 0  cancel\n");
	index = 1;
	while (index <= 15)
	{
		client = array_kick[index];
		if (client)
		{
			num = strings_ftos(index);
			sprint5(self, " ", num, " ", client.netname, "\n");
		}
		index = (index + 1);
	}
};

void() admin_start_ban =
{
	local entity client;
	local float index;
	local entity kick_timeout;

	if (clanring_state & CLANRING_KICKING)
	{
		sprint(self, "Administrator function already in progress\n");
		return;
	}
	index = 1;
	client = find(world, classname, "player");
	while (client)
	{
		if ((client.style & CLANRING_CONNECTED))
		{
			if ((!(client.style & CLANRING_ADMINISTRATOR) || (client.clanring_hack_count && !self.clanring_hack_count)))
			{
				array_kick [index] = client;
				index = (index + 1);
			}
		}
		client = find(client, classname, "player");
	}
	if (index == 1)
	{
		sprint(self, "There is no-one to ban\n");
		return;
	}
	while (index <= 15)
	{
		array_kick[index] = world;
		index = (index + 1);
	}
	admin_print_ban_choice ();
	self.use = admin_confirm_ban;
	kick_timeout = spawn();
	kick_timeout.movetarget = self;
	kick_timeout.classname = "clanring_kick_timeout";
	kick_timeout.think = admin_cancel_ban;
	kick_timeout.nextthink = (time + 10);
	clanring_state = (clanring_state | CLANRING_KICKING);
};

void() admin_confirm_ban =
{
	local entity oself;

	if (self.finaldest_z == 0)
	{
		oself = self;
		self = find(world, classname, "clanring_kick_timeout");
		admin_cancel_ban ();
		self = oself;
		return;
	}
	kick_target = array_kick[self.finaldest_z];
	if (!kick_target)
	{
		sprint(self, "Invalid\n");
		admin_print_ban_choice ();
		return;
	}
	if (((kick_target.style & CLANRING_ADMINISTRATOR) && (!kick_target.clanring_hack_count || self.clanring_hack_count)))
	{
		sprint2(self, kick_target.netname, " is an administrator\n");
		admin_print_ban_choice ();
		return;
	}
	sprint3(self, "ban ", kick_target.netname, "?\n");
	self.style = (self.style | CLANRING_KICK_CONFIRM);
	clanring_kick_mode = KICK_BAN;
};

//
//  C O N F I R M  K I C K  R E S P O N S E
//
//  Called when the administrator enters 'yes' or 'no' in
//  response to the confirmation request.
//
void(float fDoKick) admin_confirm_ban_response =
{
	local entity oself;

	if (fDoKick)
	{
		admin_do_ban ();
	}
	else
	{
		oself = self;
		self = find(world, classname, "clanring_kick_timeout");
		admin_cancel_ban ();
		self = oself;
	}
};

void() admin_do_ban =
{
	localcmd("addip %s ban 0 \"Banned via Admin\"\n", infokey(self, INFOKEY_P_IP));
	sprint(self, self.netname, " has been banned.\n");

	clanring_kick_mode = KICK_BAN;
	clanring_kick_player(kick_target);

	kick_target = find(world, classname, "clanring_kick_timeout");
	remove(kick_target);

	self.use  = SUB_Null;
	clanring_state = clanring_state - (clanring_state & CLANRING_KICKING);
	self.style = self.style - (self.style & CLANRING_KICK_CONFIRM);
};

void() admin_cancel_ban =
{
	sprint(self.movetarget, "Ban cancelled\n");
	self.movetarget.use = SUB_Null;
	remove(self);
	clanring_state = clanring_state - (clanring_state & CLANRING_KICKING);
	self.movetarget.style = (self.movetarget.style - (self.movetarget.style & CLANRING_KICK_CONFIRM));
	clanring_kick_mode = 0;
};

//
//  L I S T  G H O S T S
//
void() admin_list_ghosts =
{
	local entity e;

	e = find(world, classname, "clanring_ghost");
	if (!e)
	{
		sprint(self, "There are no ghosts\n");
		return;
	}
	if (teamplay)
	{
		sprint(self, "\ncodeü   team   üfragsü     name\n");
	}
	else
	{
		sprint(self, "\ncodeü  colour  üfragsü     name\n");
	}
	sprint(self, "­­­­«­­­­­­­­­­«­­­­­«­­­­­­­­­­­­­­­\n");

	local string num, szTeam, pad;
	local float frag;

	while (e)
	{
		num = ftos(e.count);
		sprint3(self, " ", num, " ü");
		szTeam = strings_get_teamname2 (e.height);
				if (e.owner.owner == e)
		frag = e.owner.frags;
		else
		frag = e.frags;
		if (frag < -99)
		pad = "ü";
		else if (frag < -9)
		pad = "ü ";
		else if (frag < 0)
		pad = "ü  ";
		else if (frag < 10)
		pad = "ü   ";
		else if (frag < 100)
		pad = "ü  ";
		else
		pad = "ü ";
		num = ftos(frag);
		if (e.owner.owner == e)
		sprint(self, szTeam, pad, num, " ü", e.owner.netname, "\n");
		else
		sprint(self, szTeam, pad, num, " ü Disconnected\n");
		e = find(e, classname, "clanring_ghost");
	}
	sprint(self, "\n");
};

//
//  S H O W  S P O T  I N F O
//
//  Display the current position and angle.
//
void() admin_show_spot_info =
{
	local string temp;

	temp = vtos ((self.origin + '0 0 22'));
	sprint3(self, " origin: ", temp, "\n");
	temp = vtos (self.v_angle);
	sprint3(self, " angle : ", temp, "\n");
};

//
//  N E X T  S P A W N  P O I N T
//
//  If the admin is in walk or fly observer mode, move him to the
//  next spawn point.
//
void() admin_next_spawn_point =
{
	if (!(self.style & CLANRING_OBSERVER) || !(self.oflags & (OBSERVER_WALK | OBSERVER_FLY)))
	{
		sprint(self, "You must be in walk or fly mode\n");
		return;
	}
	utils_do_item(match_add_spawn, "clanring_start_point");
	self.owner = find(self.owner, classname, "info_player_deathmatch");
	if (!self.owner)
	{
		self.owner = find(self.owner, classname, "info_player_deathmatch");
		if (!self.owner)
		{
			sprint(self, "No spawn points found\n");
			return;
		}
	}
	utils_do_item(match_remove_start, "info_player_deathmatch");

	// setorigin will not actually set the origin if a bad origin is given.
	// Therefore, we first set the origin manually to ensure that the spot info
	// is displayed correctly.
	//

	self.origin = self.owner.origin;
	admin_show_spot_info ();
	setorigin(self, self.owner.origin + '0 0 1');
	self.angles = self.owner.angles;
	self.fixangle = TRUE;           // turn this way immediately
	self.velocity = '0 0 0';
	makevectors (self.angles);
	observer_spawn_tfog(self.origin + v_forward*20);
};

//
//  M A K E  S P A W N  P O I N T
//
//  If the admin is in walk observer mode, standing on the ground and
//  not underwater, then create a new deathmatch spawn point at his
//  location.
//
void() admin_make_spawn_point =
{
	if ((!(self.style & CLANRING_OBSERVER) || !(self.oflags & OBSERVER_WALK)))
	{
		sprint(self, "You must be in walk mode\n");
		return;
	}
	if (!(self.flags & FL_ONGROUND))
	{
		sprint(self, "You must be on the ground\n");
		return;
	}
	if (self.waterlevel)
	{
		sprint(self, "Cannot create underwater spawn point\n");
		return;
	}
	if (dm_num_spawns >= 20)
	{
		sprint(self, "Max. number of spawn points reached\n");
		return;
	}
	self.owner = spawn();
	self.owner.owner = world;
	self.owner.solid = SOLID_NOT;
	self.owner.movetype = MOVETYPE_NONE;
	self.owner.takedamage = DAMAGE_NO;
	self.owner.fixangle = TRUE;
	self.owner.classname = "info_player_deathmatch";
	self.angles_x = 0;
	self.angles_z = 0;
	self.fixangle = TRUE;
	self.owner.angles = self.angles;
	self.owner.origin = self.origin;
	dm_num_spawns = (dm_num_spawns + 1);
	sprint(self, "Spawn point created\n");
	admin_show_spot_info ();
};

//
//  N E X T  C A M E R A
//
//  If the admin is in fly observer mode, move him to the next camera.
//
void() admin_next_camera =
{
	if (!(self.style & CLANRING_OBSERVER) || !(self.oflags & OBSERVER_FLY))
	{
		sprint(self, "You must be in fly mode\n");
		return;
	}
	self.owner = find(self.owner, classname, "clanring_camera");
	if (!self.owner)
	{
		self.owner = find(self.owner, classname, "clanring_camera");
		if (!self.owner)
		{
			sprint(self, "No cameras found\n");
			return;
		}
	}

	// setorigin will not actually set the origin if a bad origin is given.
	// Therefore, we first set the origin manually to ensure that the spot info
	// is displayed correctly.
	//
	self.origin = self.owner.origin - '0 0 22';

	self.angles = self.v_angle = self.owner.angles;
	admin_show_spot_info();
	setorigin(self, self.owner.origin);

	self.fixangle = TRUE;           // turn this way immediately
	self.velocity = '0 0 0';
};

//
//  M A K E  C A M E R A
//
//  If the admin is in fly observer mode, create a new camera at his
//  location.
//
void() admin_make_camera =
{
	if ((!(self.style & CLANRING_OBSERVER) || !(self.oflags & OBSERVER_FLY)))
	{
		sprint(self, "You must be in fly mode\n");
		return;
	}
	if ((clanring_num_cameras >= 20))
	{
		sprint(self, "Max. number of cameras reached\n");
		return;
	}
	self.owner = spawn();
	self.owner.owner = world;
	self.owner.solid = SOLID_NOT;
	self.owner.movetype = MOVETYPE_NONE;
	self.owner.takedamage = DAMAGE_NO;
	self.owner.fixangle = TRUE;
	self.owner.classname = "clanring_camera";
	self.owner.think = auto_camera_think;
	self.owner.nextthink = time + 0.2;
	self.v_angle_z = 0;
	self.angles = self.v_angle;
	self.fixangle = TRUE;
	self.owner.angles = self.v_angle;
	self.owner.origin = self.origin + '0 0 22';
	self.owner.next_camera = clanring_sentinel.next_camera;
	clanring_sentinel.next_camera = self.owner;
	clanring_num_cameras = clanring_num_cameras + 1;
	sprint(self, "Camera created\n");
	admin_show_spot_info ();
};

//
//  H E L P
//
void() admin_help =
{
	sprint(self, "Admin only commands:\n");
	sprint(self, " autoss       - automatic screenshots\n");
	sprint(self, " maxteams     - set max number of teams\n");
	sprint(self, " kick!        - kick a player\n");
	sprint(self, " crban        - ban a player\n");
	sprint(self, " modevote     - enable/disable mode votes\n");
	sprint(self, " options      - on-screen options menu\n");
	sprint(self, " dmset        - change deathmatch mode\n");
	sprint(self, " faststart    - toggle fast match start\n");
	sprint(self, " abortmatch   - abort current match\n");
	sprint(self, " ghostlist    - view list of ghosts\n");
	sprint(self, " spot         - show location/angles\n");
	sprint(self, " nextspawn    - go to next spawn point\n");
	sprint(self, " makespawn    - add spawn point\n");
	sprint(self, " nextcam      - go to next camera\n");
	sprint(self, " makecam      - add camera\n");
	sprint(self, " safepractice - no spam/discharging\n");
};

//
//  D M S E T
//
void(float val) admin_dmset =
{
	local string temp;

	if (val != -1)
	deathmatch = val - 1;
	deathmatch = deathmatch + 1;
	if (deathmatch > 4)//R00k changed to allow dmm4
	deathmatch = 1;
	temp = ftos(deathmatch);
	cvar_set("deathmatch", temp);
//	announce2("deathmatch changed to ", temp);
};

//
//  S E T  M A X T E A M S
//
void(float num) admin_set_maxteams =
{
	local string temp;

	clanring_maxteams = num;
	temp = ftos(num);
	announce2("Maximum number of teams set to ", temp);
	utils_set_cvar ("scratch3", num);
};

//
//  G E T  M A X T E A M S
//
void() admin_get_maxteams =
{
	self.use = SUB_Null;
	if (self.finaldest_z < 2 || self.finaldest_z > 8)
	{
		sprint(self, "Invalid\n");
		return;
	}
	admin_set_maxteams(self.finaldest_z);
};

//
//  C H O O S E  M A X T E A M S
//
void() admin_choose_maxteams =
{
	sprint(self, "Enter maximum number of teams:\n");
	self.use = admin_get_maxteams;
};

//
//  D M 3  S C R E E N S H O T  C L E A N U P
//
void() admin_dm3_screenshot_cleanup =
{
	gameover = 0;
	intermission_running = 0;
	clanring_state = clanring_state - (clanring_state & CLANRING_TAKING_AUTOSS);
	other = find(world, classname, "player");

	while (other != world)
	{
		if (other.style & CLANRING_CONNECTED)
		{
			if (!(other.style & CLANRING_OBSERVER) || (other.style & CLANRING_ADMINISTRATOR))
			{
				other.modelindex = other.clanring_did_damage;

				if (other.style & CLANRING_OBSERVER)
				{
					if ((other.oflags & OBSERVER_WALK) || (other.oflags & OBSERVER_FLY))
						other.view_ofs = '0 0 22';
					else
						other.view_ofs = '0 0 0';
					other.solid = SOLID_NOT;
					other.takedamage = DAMAGE_NO;
					if (other.oflags & OBSERVER_WALK)
						other.finaldest_y = other.movetype = MOVETYPE_WALK;
					else
						if (other.oflags & OBSERVER_CAMERA)
							other.finaldest_y =  other.movetype = MOVETYPE_NONE;
						else
							other.finaldest_y = other.movetype = MOVETYPE_FLY;
				}
				else
				{
					other.view_ofs = '0 0 22';
					other.solid = SOLID_SLIDEBOX;
					other.takedamage = DAMAGE_AIM;
					other.finaldest_y = other.movetype = MOVETYPE_WALK;

					local entity oself;
					oself = self;
					self = other;
					W_SetCurrentAmmo();
					self = oself;
				}
				other.angles = other.v_angle = other.clanring_oldangle;
				other.fixangle = TRUE;		// turn this way immediately
				setorigin(other, other.clanring_old_velocity);
				setorigin(other, other.clanring_old_velocity);//Twice?
			}
		}
		other = find(other, classname, "player");
	}
	remove(self);
	utils_do_item(SUB_Remove, "clanring_screenshot_entity");
};

//
//  D M 3  S C R E E N S H O T
//
void() admin_dm3_screenshot =
{
	self.nextthink = (time + 2.7);
	self.think = admin_dm3_screenshot_cleanup;
	utils_do_item(SUB_Freeze, "clanring_screenshot_entity");

	other = find(world, classname, "player");
	while (other != world)
	{
		if (other.style & CLANRING_CONNECTED)
		{
			if (!(other.style & CLANRING_OBSERVER) || (other.style & CLANRING_ADMINISTRATOR))
			{
				stuffcmd(other, "coop 0\n");
			}
		}
		other = find(other, classname, "player");
	}
};

//
//  S C R E E N S H O T  S P A W N
//
entity (string modelname, vector position) admin_screenshot_spawn =
{
	local entity e;

	e = spawn();
	e.classname = "clanring_screenshot_entity";
	setmodel(e, modelname);
	setorigin(e, position);
	e.angles = '0 0 0';
	e.angles_y = (random () * 360);
	e.fixangle = TRUE;
	return (e);
};

//
//  D M 3  S C R E E N S H O T  S E T U P
//
void() admin_dm3_screenshot_setup =
{
	if (self != clanring_match_timer)
	{
		if (clanring_state & CLANRING_TIMER_STARTED)
		{
			if ((clanring_state & CLANRING_MATCH_STARTED) || (clanring_match_timer.count <= 10))
			{
				sprint(self, "autoss will be taken at end of match\n");
				clanring_state = clanring_state | CLANRING_DELAYED_AUTOSS;
				return;
			}
		}
		if ((self.style & CLANRING_OBSERVER) && (self.oflags & OBSERVER_DEMO))
		{
			auto_camera_start();
			stuffcmd(self, "autoss\n");
			return;
		}
	}

	if (clanring_state & CLANRING_TAKING_AUTOSS)
	{
		return;
	}

	clanring_state = (clanring_state | CLANRING_TAKING_AUTOSS);
	intermission_running = 1;
	intermission_exittime = (time + 5);
	gameover = 1;
	clanring_angle = '20 -180 0';

	other = find(world, classname, "player");
	while (other != world)
	{
		if (other.style & CLANRING_CONNECTED)
		{
			if (!((other.style & CLANRING_OBSERVER) || (other.style & CLANRING_ADMINISTRATOR)))
			{
				other.view_ofs = '0 0 0';
				other.clanring_oldangle = other.v_angle;
				other.v_angle = '20 -180 0';
				other.angles = '20 -180 0';
				other.fixangle = TRUE;		// turn this way immediately
				other.nextthink = (time + 3);
				other.takedamage = DAMAGE_NO;
				other.solid = SOLID_NOT;
				other.movetype = MOVETYPE_NONE;
				other.finaldest_y = MOVETYPE_NONE;
				other.clanring_did_damage = other.modelindex;
				other.modelindex = 0;
				other.weaponmodel = string_null;
				other.clanring_old_velocity = other.origin;
				setorigin(other, '1870 -35 30');
				stuffcmd(other, "-showscores;impulse 128\n");
				if (self != clanring_match_timer)
				{
					stuffcmd(other, "echo \"Ãìáîòéîç Óãòååîóèïô âù ");
					stuffcmd(other, self.netname);
				}
				else
				{
					stuffcmd(other, "echo \"Áõôïíáôéã Ãìáîòéîç Óãòååîóèïô");
				}
				stuffcmd(other, "\"\nname\n");
			}
		}
		other = find(other, classname, "player");
	}

	// set lineup spawns
	local float cmap1, cmap2;
	local entity e;

	cmap1 = cmap2 = 0;
	e = clanring_sentinel.next_player;
	if (e)
	{
		cmap1 = e.colormap;
	}
	cmap2 = 0;
	while (e)
	{
		cmap2 = e.colormap;
		e = e.next_player;
	}

	// front row
	e = admin_screenshot_spawn ("progs/armor.mdl", '1675 -235 -146');
	e.skin = 1;
	e = admin_screenshot_spawn ("progs/eyes.mdl", '1675 -185 -146');
	e = admin_screenshot_spawn ("progs/player.mdl", '1675 -135 -146');
	e.frame = 6;
	e.colormap = cmap1;
	e = admin_screenshot_spawn ("progs/quaddama.mdl", '1675 -85 -146');
	e = admin_screenshot_spawn ("progs/player.mdl", '1675 -35 -146');
	e.frame = 0;
	e.colormap = cmap2;
	e = admin_screenshot_spawn ("progs/invulner.mdl", '1675 15 -146');
	e = admin_screenshot_spawn ("progs/player.mdl", '1675 65 -146');
	e.frame = 12;
	e.colormap = cmap1;
	e = admin_screenshot_spawn ("progs/invisibl.mdl", '1675 115 -146');
	e = admin_screenshot_spawn ("progs/armor.mdl", '1675 165 -146');
	e.skin = 2;

	// second row
	e = admin_screenshot_spawn ("progs/spike.mdl", '1625 -235 -146');
	e = admin_screenshot_spawn ("progs/g_shot.mdl", '1625 -185 -170');
	e = admin_screenshot_spawn ("progs/g_nail.mdl", '1625 -135 -170');
	e = admin_screenshot_spawn ("progs/g_nail2.mdl", '1625 -85 -170');
	e = admin_screenshot_spawn ("progs/backpack.mdl", '1625 -35 -146');
	e = admin_screenshot_spawn ("progs/g_rock.mdl", '1625 15 -170');
	e = admin_screenshot_spawn ("progs/g_rock2.mdl", '1625 65 -170');
	e = admin_screenshot_spawn ("progs/g_light.mdl", '1625 115 -170');
	e = admin_screenshot_spawn ("progs/s_spike.mdl", '1625 165 -146');

	// third row
	e = admin_screenshot_spawn ("maps/b_bh100.bsp", '1575 -285 -146');
	e.angles_y = 0;
	e = admin_screenshot_spawn ("progs/s_bubble.spr", '1575 -235 -146');
	e = admin_screenshot_spawn ("progs/bolt.mdl", '1575 -135 -146');
	e.angles_y = 90;
	e = admin_screenshot_spawn ("progs/bolt3.mdl", '1575 -85 -146');
	e.angles_y = 90;
	e = admin_screenshot_spawn ("progs/bolt2.mdl", '1575 65 -146');
	e.angles_y = 90;
	e = admin_screenshot_spawn ("progs/missile.mdl", '1575 -150 -146');
	e.movetype = MOVETYPE_FLYMISSILE;
	e.velocity = '0 1000 0';
	e.angles = '0 90 0';
	e = admin_screenshot_spawn ("progs/s_explod.spr", '1575 215 -146');
	e.frame = 3;

	// fourth row
	e = admin_screenshot_spawn ("progs/player.mdl", '1525 -185 -146');
	e.frame = 7;
	e.colormap = cmap2;
	e = admin_screenshot_spawn ("progs/player.mdl", '1525 -135 -146');
	e.frame = 13;
	e.colormap = cmap1;
	e = admin_screenshot_spawn ("progs/player.mdl", '1525 -85 -146');
	e.frame = 2;
	e.colormap = cmap2;
	e = admin_screenshot_spawn ("progs/player.mdl", '1525 -35 -146');
	e.frame = 8;
	e.colormap = cmap1;
	local float temp;
	temp = (2.999 * random ());
	temp = floor(temp);
	e = admin_screenshot_spawn ("progs/player.mdl", '1525 15 -146');
	e.frame = (3 + temp);
	e.colormap = cmap2;
	e = admin_screenshot_spawn ("progs/player.mdl", '1525 65 -146');
	e.frame = (9 + temp);
	e.colormap = cmap1;
	e = admin_screenshot_spawn ("progs/player.mdl", '1525 115 -146');
	e.frame = (14 + temp);
	e.colormap = cmap2;
	e = admin_screenshot_spawn ("progs/grenade.mdl", '1525 -150 -146');
	e.movetype = MOVETYPE_FLYMISSILE;
	e.velocity = '0 1000 0';
	e.angles = '0 90 0';

	// fifth row
	e = admin_screenshot_spawn ("progs/player.mdl", '1525 80 -90');
	e.movetype = MOVETYPE_FLYMISSILE;
	e.velocity = '0 -1000 0';
	e.frame = 1;
	e.colormap = cmap1;

	// upper bridge
	e = admin_screenshot_spawn ("maps/b_rock0.bsp", '1350 -235 -48');
	e.angles_y = 0;
	e = admin_screenshot_spawn ("maps/b_rock1.bsp", '1350 -185 -48');
	e.angles_y = 0;
	e = admin_screenshot_spawn ("maps/b_batt0.bsp", '1350 -135 -48');
	e.angles_y = 0;
	e = admin_screenshot_spawn ("maps/b_batt1.bsp", '1350 -85 -48');
	e.angles_y = 0;
	e = admin_screenshot_spawn ("maps/b_bh10.bsp", '1350 -35 -48');
	e.angles_y = 0;
	e = admin_screenshot_spawn ("maps/b_bh25.bsp", '1350 15 -48');
	e.angles_y = 0;
	utils_make_scheduled_event(admin_dm3_screenshot, 0.3);
};

//
//  A U T O  S C R E E N S H O T
//
void() admin_auto_screenshot =
{
	local entity player;

	if ((mapname == "dm3") && (clanring_playmode & CLANRING_MATCH_MODE))
	{
		admin_dm3_screenshot_setup ();
		return;
	}
	if ((self.style & CLANRING_OBSERVER) && (self.oflags & OBSERVER_DEMO))
	{	// single player screenshot
		if ((clanring_state & CLANRING_MATCH_STARTED) && (self.movetarget.style & CLANRING_GLQUAKE))
		{
			sprint2(self, self.movetarget.netname, " is using GL Quake!\n");
			sprint(self, "No autoss taken (take it after match)\n");
		}
		else
		{
			stuffcmd(self, "echo \"Ãìáîòéîç Óãòååîóèïô âù ");
			stuffcmd(self, self.netname);
			stuffcmd(self, "\"\nwait;screenshot\n");
			stuffcmd(self.movetarget, "name\n");
			stuffcmd(self.movetarget, "echo \"Ãìáîòéîç Óãòååîóèïô âù ");
			stuffcmd(self.movetarget, self.netname);
			stuffcmd(self.movetarget, "\"\nwait;coop 0\n");
		}
	}
	else
	{
		if (clanring_state & CLANRING_MATCH_STARTED)
		{
			player = find(world, classname, "player");
			while (player)
			{
				if (!(player.style & CLANRING_OBSERVER))
				{
					if (player.style & CLANRING_GLQUAKE)
					{
						sprint2(self, player.netname, " is using GL Quake\n");
					}
					else
					{
						stuffcmd(player, "name\n");
						stuffcmd(player, "echo \"Ãìáîòéîç Óãòååîóèïô âù ");
						stuffcmd(player, self.netname);
						stuffcmd(player, "\"\nwait;coop 0\n");
					}
				}
				player = find(player, classname, "player");
			}
		}
		else
		{
			player = find(world, classname, "player");
			while (player)
			{
				if (!(player.style & CLANRING_OBSERVER))
				{
					stuffcmd(player, "+showscores;\n");
					stuffcmd(player, "echo \"Ãìáîòéîç Óãòååîóèïô âù ");
					stuffcmd(player, self.netname);
					stuffcmd(player, "\"\nscr_conspeed 9999;path;name;wait;coop 0;toggleconsole;wait;coop 0;-showscores;toggleconsole\n");
				}
				player = find(player, classname, "player");
			}
		}
	}
};

//
//  I M P U L S E
//
//  Called by elohim_impulse in Server.qc
//
// 217,218,219,220 unused

void() admin_impulse =
{
	// votable commands
	if (self.impulse >= 190 && self.impulse <= 196) //this is unused
		votables_init_warp(self.impulse - 190);
	else if (self.impulse == 202)
		votables_request_set_hook();
	else if (self.impulse == 210)
		votables_request_set_autopause();
	else if (self.impulse == 211)
		votables_request_set_obits();
	else if (self.impulse == 214)
		votables_request_abortmatch();
	else if (self.impulse == 215)
		votables_select_timelimit();
	else if (self.impulse == 216)
		votables_select_overtime();
	else if (self.impulse == 217)
		votables_force_start();
	else if (self.impulse == 218)
		votables_request_set_weaponstay();
	else if (self.impulse == 219)
		votables_select_fraglimit();
	//else if (self.impulse == 220) voteables_set_teamplay_fraglimit();
	else if (self.impulse == 221)
		votables_request_set_quad();
	else if (self.impulse == 222)
		votables_request_set_pent();
	else if (self.impulse == 223)
		votables_request_set_ring();
	else if (self.impulse >= 225 && self.impulse <= 227)
		votables_request_set_gibs (self.impulse - 225);
	else if (self.impulse >= 230 && self.impulse <= 245)
	{
		if (self.use)
		{
			self.finaldest_z = self.impulse - 230;
			self.use ();
		}
	}

	if (!(self.style & CLANRING_ADMINISTRATOR))
		return;

	// admin only commands
	if (self.impulse == 200)
		admin_help ();
	else if (self.impulse == 204)
		admin_auto_screenshot ();
	else if (self.impulse == 205)
		admin_start_ban();
	else if (self.impulse == 206)
		admin_show_ip_list ();
	else if (self.impulse == 207)
		admin_dmset (-1);
	else if (self.impulse == 208)
		admin_choose_maxteams ();
	// else if (self.impulse == 209) //removed for now
	// 	utils_toggle_sflag (CLANRING_FAST_START, "Fast match starts");
	else if (self.impulse == 212)
		admin_list_ghosts ();
	else if (self.impulse == 213)
		admin_start_kick ();
	else if (self.impulse == 224)
		utils_toggle_sflag (CLANRING_NO_SPOOGE, "Safe practice mode");
	else if (self.impulse == 228)
		utils_toggle_sflag (CLANRING_MODE_VOTE, "Mode voting");
	else if (self.impulse == 229)
		options_start_setting ();
	else if (self.impulse == 246)
		admin_next_spawn_point ();
	else if (self.impulse == 247)
		admin_make_spawn_point ();
	else if (self.impulse == 248)
		admin_next_camera ();
	else if (self.impulse == 249)
		admin_make_camera ();
	else if (self.impulse == 250)
		admin_show_spot_info ();
};

//
//  D I S C O N N E C T  N O T I F Y
//
//  removethis player from the list of kickable players.
//
void(entity player) admin_disconnect_notify =
{
	local float index;

	index = 1;
	while (index < 16)
	{
		if (player == array_kick[index])
		{
			array_kick[index] = world;
		}
		index = (index + 1);
	}
};
