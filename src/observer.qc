//
// Observer.qc
//
// Contains code for handling observers.
//
// All code by J.P. Grossman unless otherwise commented.
//
// Fields used:
//
// .wait            - time to look for teleports when observing
// .trigger_field   - closest teleport entity; used when observing
// .t_width         - activation radius for closest teleport
// .dest            - stores destination for popping forward
// .dest1           - stores velocity for popping forward
// .movetarget      - player being watched in observer mode (world if none)
// .clanring_othertarget     - player to focus on during tourney cam // CRMOD
// .delay           - time to refresh head's up display for observing
// .speed           - z component of velocity from previous frame (for fly)
// .lip             - time to clear display when no target is in line of sight (walk/fly)
//

// function declarations
entity (entity e) observer_find_target;
entity (entity e) observer_find_camera;			// CRMOD
void () observer_set_camera_position;			// CRMOD
void () observer_set_chase_position;
void () observer_set_demo_position;
void () observer_heads_up;
void () SetNewParms2;
void () observer_get_target;
void () observer_next_target;
void () WaterMove;
void () CheckWaterJump;
void (entity player) match_remove_player;
void () UnHookPlayer;
void (entity player, float reset) TeamCaptureDropFlagOfPlayer;
void () respawn;
void () DropRune;

//
//  F I N D  T E L E P O R T
//
//  Find the closest teleport and remember it.  Called once every second.
//
void () observer_find_teleport =
{
    local entity e;
    local float d, mindist;

    // find the closest teleport
    mindist = 99999999;
    e = self.trigger_field = find(world, classname, "trigger_teleport");
    while (e)
    {
        d = vlen(self.origin - (e.mins + e.maxs) * 0.5);
        if (d < mindist)
        {
            mindist = d;
            self.trigger_field = e;
        }
        e = find(e, classname, "trigger_teleport");
    }
    e = self.trigger_field;

    // compute an 'activation radius'
    if (e)
        self.t_width = utils_min3(e.size_x, e.size_y, e.size_z) * 0.7;
};


//
//  S P A W N  T F O G
//
void (vector pos) observer_spawn_tfog =
{
    msg_entity = self;
    WriteByte(MSG_ONE, SVC_TEMPENTITY);
    WriteByte(MSG_ONE, TE_TELEPORT);
    WriteCoord(MSG_ONE, pos_x);
    WriteCoord(MSG_ONE, pos_y);
    WriteCoord(MSG_ONE, pos_z);
};

//
//  C H E C K  T E L E P O R T
//
//  Check to see if on observer hit the closest teleport.
//
void () observer_check_teleport =
{
    local entity t;
    local vector d;

    t = self.trigger_field;
    if (!t)
        return;

    // Only check if the observer is not completely above/below the teleport
    if (self.absmin_z < t.absmax_z && self.absmax_z > t.absmin_z)
    {
        d = self.origin - (t.absmin + t.absmax) * 0.5;
        d_z = 0;
        if (vlen(d) < 24 + self.t_width)
        {
            // find the destination
            t = find(world, targetname, t.target);
            if (!t)
                return;

            // spawn a tfog flash for the observer only
            makevectors(t.mangle);
            observer_spawn_tfog(t.origin + 32 * v_forward);

            // move the observer
            setorigin(self, t.origin);
            self.angles = t.mangle;
            self.fixangle = 1;
            self.velocity = v_forward * 300;
            if (self.oflags & OBSERVER_WALK)
                self.flags = self.flags - (self.flags & FL_ONGROUND);
        }
    }
};

//
//  C L E A R   P L A Y E R S   I N F O K E Y S
//
//  Clear the observer infokeys for all connected players.
//
void () observer_clear_players_infokeys =
{ 
	entity player = find(world, classname, "player");
	while (player)
	{		
		if (player.style & CLANRING_CONNECTED)
		{
			forceinfokey(player, "observing", "off");
			forceinfokey(player, "*observer", "off");
			forceinfokey(player, "observer", "off");	
		}
		player = find(player, classname, "player");
	}	
};

//
//  U P D A T E   P L A Y E R   I N F O K E Y 
//
//  Update the player's infokey for current observer mode.
//
void (entity player) observer_update_player_observer_key =
{
	if (!(self.style & CLANRING_OBSERVER))
	{
		if (player.style & CLANRING_CONNECTED)
		{
			forceinfokey(player, "observing", "off");
			forceinfokey(player, "*observer", "off");
			forceinfokey(player, "observer", "off");	
		}
		print("observer_update_player_observer_key: not an observer\n");
		return;
	}

	if (player.oflags & OBSERVER_WALK)
	{
		forceinfokey(player, "*observer", "walk");
		forceinfokey(player, "observer", "walk");
	}
	else if (player.oflags & OBSERVER_FLY)
	{
		forceinfokey(player, "*observer", "fly");
		forceinfokey(player, "observer", "fly");
	}
	else if (player.oflags & OBSERVER_CHASE)
	{
		forceinfokey(player, "*observer", "chase");
		forceinfokey(player, "observer", "chase");
	}
	else if (player.oflags & OBSERVER_DEMO)
	{
		forceinfokey(player, "*observer", "eyecam");
		forceinfokey(player, "observer", "eyecam");
	}
	else if (player.oflags & OBSERVER_CAMERA)
	{
		forceinfokey(player, "*observer", "camera");
		forceinfokey(player, "observer", "camera");
	}
	else
	{
		forceinfokey(player, "*observer", "off");
		forceinfokey(player, "observer", "off");
	}

	if (player.movetarget)
	{
		forceinfokey(player, "observing", player.movetarget.netname);
	}
	else
	{
		forceinfokey(player, "observing", "off");
	}
}
//
//  C L E A R  F L A G S
//
void () observer_clear_flags =
{
	self.oflags = self.oflags - self.oflags & (OBSERVER_WALK | OBSERVER_FLY | OBSERVER_CHASE | OBSERVER_DEMO | OBSERVER_CAMERA | OBSERVER_AUTO);
	self.clanring_othertarget = world;	// CRMOD
};

//
//  C H E C K  D E M O  E N D
//
//  If we're coming out of demo mode, we need to do a bit of cleaning up.
//  The reason for the model junk is that, for some reason, setting
//  the model to string_null (done in observer_demo_start) causes the
//  player to be unable to move.  The hack-fix is to set the model to
//  something real (eyes) which allows the player to move, and then
//  immediately assign string_null to self.model so that nobody sees the
//  player.  I don't know enough about quake to understand why it's
//  okay to assign string_null to self.model but not to call setmodel
//  with string_null; all I know is that this works.
//
void () observer_check_demo_end =
{
	if (self.oflags & OBSERVER_DEMO)
	{
		setmodel (self, "progs/eyes.mdl");
		self.model = string_null;
		msg_entity = self;
		WriteByte(MSG_ONE, SVC_SETVIEWPORT);
		WriteEntity (MSG_ONE, self);
	}
};

//
//  W A L K  S T A R T
//
void () observer_walk_start =
{
	observer_check_demo_end();
	observer_clear_flags();
	self.oflags = self.oflags | OBSERVER_WALK;
	self.finaldest_y = self.movetype = MOVETYPE_WALK;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.view_ofs = '0 0 22';

//	droptofloor(0, 0);
//R00k: removing this junk (3/04/2022)
/*	if (self.style & CLANRING_FOUND_BINDINGS)// CRMOD - don't send sm0 if they don't have that alias
		stuffcmd(self, "sm0\n");// CRMOD - smoothing off
	else
		stuffcmd(self, "cl_nolerp 0\n");// CRMOD - send the real thing instead
	stuffcmd(self, "v_centerspeed 500\n");
	sprint(self, "walk mode\n");
	if (!(self.style & CLANRING_HEADS_UP))
		sprint(self, "type 'headsup' for fullscreen display\n");
*/
	observer_update_player_observer_key(self);

	if (mode_is_arena())
	{
		if (boss.state == CA_MATCH_WAITING)
		{
			self.style = self.style - (self.style & CLANRING_MOTD);
			motd_arena_start();
		}
	}
};

//
//  F L Y  S T A R T
//
void () observer_fly_start =
{
	observer_check_demo_end();
	observer_clear_flags();
	self.oflags = self.oflags | OBSERVER_FLY;
	self.movetype = MOVETYPE_NOCLIP;			//R00k: changed (2022-01-26 11:01) from MOVETYPE_FLY;
	self.finaldest_y = MOVETYPE_NOCLIP;			//R00k: changed (2022-01-26 11:01) from MOVETYPE_FLY;
	self.view_ofs = '0 0 22';
	self.flags = self.flags | FL_ONGROUND;
	self.waterlevel = 0;
	
	observer_update_player_observer_key(self);
/*
	stuffcmd(self, "sm0\n");		// CRMOD - smoothing off
	stuffcmd(self, "v_centerspeed 500\n");

	if (!(self.style & CLANRING_HEADS_UP))
		sprint(self, "type 'headsup' for fullscreen display\n");
*/
	sprint(self, "fly mode\n");
	centerprint(self, "fly mode\n");
	if (mode_is_arena())
	{
		if (boss.state == CA_MATCH_WAITING)
		{
			self.style = self.style - (self.style & CLANRING_MOTD);
			motd_arena_start();
		}
	}
};

// CRMOD
// C A M E R A  S T A R T
//   by Paul Baker
//
//   Starts up Camera Mode
void () observer_camera_start =
{
	local entity camera;

	if (!self.movetarget)
	{
		// see if we can find a camera
		self.movetarget = observer_find_camera(world);
		if (!self.movetarget)
		{
			sprint(self, "no cameras found\n");
			if (self.oflags & OBSERVER_QUAKETV) //R00k: the show must go on!
				observer_chase_start();
			else
				observer_fly_start();
			return;
		}
		self.delay = 0;
	}
	else
	{
		if ((self.movetarget.classname != "clanring_camera") || (self.movetarget.classname != "info_intermission"))
		{
			// see if we can find a camera
			self.movetarget = observer_find_camera(world);
			if (!self.movetarget)
			{
				sprint(self, "no cameras found\n");
				if (self.oflags & OBSERVER_QUAKETV) //R00k: the show must go on!
					observer_chase_start();
				else
					observer_fly_start();

				return;
			}
			self.delay = 0;
		}
	}

	observer_check_demo_end();
	observer_clear_flags();
	self.oflags = self.oflags | OBSERVER_CAMERA;
	self.movetype = MOVETYPE_NONE;
	self.finaldest_y = MOVETYPE_NONE;
	self.view_ofs = '0 0 0';
	camera = self.movetarget;
	setorigin(self, camera.origin);
	
	local vector angle;

	if ((camera.movetarget != world)&&(camera.movetarget.health))
		angle = angles_bestaim (camera.origin, camera.movetarget.origin);
	else
		angle = camera.angles;
	angles_fixangle(angle);
	observer_set_camera_position();
	stuffcmd(self, "v_centerspeed 0\n");
	sprint(self, "camera mode - help-camera for help\n");

	if (self.oflags & OBSERVER_GO_AUTO)				// CRMOD
	{												// CRMOD
		sprint(self,"Automatic Cameras Enabled.\n");	// CRMOD
		self.oflags = self.oflags - OBSERVER_GO_AUTO;	// CRMOD
		self.oflags = self.oflags | OBSERVER_AUTO;	// CRMOD
	}												// CRMOD
	else																// CRMOD
		sprint(self,"type 'autocam' for automatic camera switching\n");	// CRMOD

	//if (!(self.style & CLANRING_HEADS_UP))
		//sprint(self, "type 'headsup' for fullscreen display\n");

	//sprint(self, "type 'smooth' to eliminate choppines\n");
	observer_update_player_observer_key(self);
};

//
//  C H A S E  S T A R T
//
void () observer_chase_start =
{
	if (!self.movetarget || self.movetarget.classname != "player")
	{
		// see if we can find a target to chase
		self.movetarget = observer_find_target(world);
		if (!self.movetarget)
		{
			sprint(self, "no chase target found\n");
			observer_walk_start();
			return;
		}
		self.delay = 0;
	}
	observer_check_demo_end();
	observer_clear_flags();
	self.oflags = self.oflags | OBSERVER_CHASE;
	self.movetype = MOVETYPE_FLY;
	self.finaldest_y = MOVETYPE_FLY;
	self.view_ofs = '0 0 0';
	observer_set_chase_position();
	stuffcmd(self, "v_centerspeed 0\n");
	sprint(self, "chase mode - help-chase for help\n");

	// CRMOD - auto, tourney
	if (self.oflags & OBSERVER_GO_AUTO)
	{
		sprint(self, "Automatic Chasecam Enabled.\n");
		self.oflags = self.oflags - OBSERVER_GO_AUTO;
		self.oflags = self.oflags | OBSERVER_AUTO;
	}
	else
	{
		sprint(self, "type 'autochase' for automatic chase switching\n");
	}
	if (self.oflags & OBSERVER_TOURNEY)
		sprint(self, "Tournament Mode Enabled.\n");
	// END_CRMOD
	//if (!(self.style & CLANRING_HEADS_UP))
		//sprint(self, "type 'headsup' for fullscreen display\n");
	
	//sprint(self, "type 'smooth' to eliminate choppines\n");
	if ((((clanring_playmode & CLANRING_MATCH_MODE)&&(!(clanring_state & CLANRING_MATCH_STARTED)))||(clanring_playmode & CLANRING_NORMAL_MODE))||(self.statstate < 0))
	{	
		if (self.oflags & OBSERVER_AUTO)
			centerprint(self,sprintf("auto chasecam \[%s\]", self.movetarget.netname));
		else
			centerprint(self,sprintf("chasecam \[%s\]", self.movetarget.netname));
		self.laststattime = time + 2;//Delay the flagstatus bar for 2 seconds.
	}
	observer_update_player_observer_key(self);	
};

//
//  D E M O  S T A R T
//
//  Not only do we have to set the viewport to the chase target for demo
//  mode to work, but we also have to call setmodel on self.. for some
//  reason the client will draw a player model where 'self' is when the
//  viewport is changed!  The effect is that you seem to be standing
//  inside yourself - even though no-one else can see you.  The fix is
//  the setmodel call.. but this can cause a problem later on when we
//  want to change back to walk mode (see comment before
//  observer_check_demo_end, above).
//
void () observer_demo_start =
{
	observer_check_demo_end();

	// If a player number was provided, try to find that specific player
	if (self.observer_number)
	{
		local entity target = find(world, classname, "player");
		while (target)
		{
			if ((target.colormap) == self.observer_number)  // colormap is the player number
			{
				// Only allow targeting connected players who aren't observers
				if ((target.style & CLANRING_CONNECTED) && !(target.style & CLANRING_OBSERVER))
				{
					self.movetarget = target;
					break;
				}
			}
			target = find(target, classname, "player");
		}

    	self.observer_number = 0;  // Clear the number here?

		if (!self.movetarget)
		{
			sprint(self, "Player number not found or is an observer\n");

			observer_fly_start();
			return;
		}
	}

	if (mode_is_arena())
	{
		if ((self.movetarget == world) || (self.movetarget.ca_player_flag == PF_DEAD))
		{
			observer_next_target();
		}
	}

    if (!self.movetarget || self.movetarget.classname != "player")
    {
        // see if we can find a target to chase
        self.movetarget = observer_find_target(world);
        if (!self.movetarget)
        {
            sprint(self, "no chase target found\n");
			observer_fly_start();
            return;
        }
        self.delay = 0;
    }

    observer_clear_flags();
    self.oflags = self.oflags | OBSERVER_DEMO;
    self.finaldest_y = self.movetype = MOVETYPE_FLY;
    self.view_ofs = '0 0 22';

	msg_entity = self;
	WriteByte(MSG_ONE, SVC_SETVIEWPORT);
	WriteEntity(MSG_ONE, self.movetarget);
	
	setmodel(self, string_null);
	observer_set_demo_position();

	stuffcmd(self, "v_centerspeed 0\n");
	sprint(self, "eyecam mode\n");
    
	// if (!(self.style & CLANRING_HEADS_UP))
    // 	sprint(self, "type 'headsup' for fullscreen display\n");
	// sprint(self, "type 'smooth' to eliminate choppines\n");
	
	observer_update_player_observer_key(self);

	//R00k: added auto pov
	if (self.oflags & OBSERVER_GO_AUTO)
	{
		sprint(self, "Automatic Eyecam Enabled.\n");
		self.oflags = self.oflags - OBSERVER_GO_AUTO;
		self.oflags = self.oflags | OBSERVER_AUTO;
	}
	else
	{
		sprint(self, "type '\bautopov\b' for automatic eyecam switching\n");
	}

	self.nextthink = -1;
    self.think = SUB_Null;
	if ((((clanring_playmode & CLANRING_MATCH_MODE)&&(!(clanring_state & CLANRING_MATCH_STARTED)))||(clanring_playmode & CLANRING_NORMAL_MODE))||(self.statstate < 0))
	{	
		if (self.oflags & OBSERVER_AUTO)
			centerprint(self,sprintf("auto eyecam \[%s\]", self.movetarget.netname));
		else
			centerprint(self,sprintf("eyecam \[%s\]", self.movetarget.netname));
		self.laststattime = time + 2;//Delay the flagstatus bar for 2 seconds.			
	}
};

//
//  S T A R T
//
//  Enter observer mode.
//
void () observer_start =
{
	//local float go_auto;
	local string tmp="";

	self.style = self.style | CLANRING_OBSERVER;

	setcolour(self, 0, 0);
	stuffcmd(self, "color 0\n");

  	// Notify the match module that this player has become an observer
	// Must do this before calling chase_start etc.. since we need to
	// remove the player from the list before messing with next_player
	//
	// Must also come before self.items is reset to avoid messing up the RL count
  	if (!(mode_is_arena()))
	{
		if (clanring_playmode & CLANRING_MATCH_MODE)
		{
			match_remove_player (self);// This needs to go first
			match_disconnect_notify (self);
			clear_name();//remove ready from scoreboard
		}
		else 
			clanring_remove_player_from_list ();

		self.next_player = world;
	}

	DropRune ();
	UnHookPlayer ();

	// If the player is dead, then call respawn to reset a bunch of stuff and
	// give him a new position.
	if (self.deadflag != DEAD_NO)
	{
		if (self.deadflag >= DEAD_DEAD)
			respawn();
		else
		{
			self.style = self.style - (self.style & CLANRING_OBSERVER);
			return;
		}
	}

	if (!(clanring_playmode & CLANRING_PRACTICE_MODE))	
    		TeamCaptureDropFlagOfPlayer (self, 1);//drop and reset the flag

	self.hook2 = (self.hook2 - (self.hook2 & HOOK_OUT));
    	
	self.style = self.style - (self.style & (CLANRING_RED_TEAM|CLANRING_BLUE_TEAM));

	self.clanring_chase_score = CLANRING_NEGINF;// CRMOD make sure they don't have some high rating that can't be beat by the other players
	
	if (mode_is_arena())
	{
		// Add check for match end state
		if (boss.state == CA_MATCH_CLEANUP || boss.state == CA_MATCH_OVER)
		{
			// Reset everyone to white when match ends
			setcolour(self, 0, 0);
			stuffcmd(self, ";color 0;\n");
		}
		else if (self.next_team != world)
		{
			setcolour(self,self.team2,0);
			tmp = ftos(self.team2);
			stuffcmd(self,";color ");
			stuffcmd(self,tmp);
			stuffcmd(self,",0;\n");
		}
		else
		{
			setcolour(self, 0, 0);
			stuffcmd (self, ";color 0;\n");

		}
				
		self.team2 	= TEAM_SPECTATOR;//dont allow dead teammates to talk to playing teammates
	}

	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;

	// get rid of powerups
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.super_damage_finished = 0;
	self.rad_time = 0;
	self.invisible_time = 0;
	self.invincible_time = 0;
	self.super_time = 0;
	self.effects = 0;

	// status bar stuff
	self.health = 999;
	self.items = 0;
	self.armorvalue = 0;
	self.ammo_shells = 0;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	self.ammo_cells = 0;
	self.currentammo = 0;	

	if (mode_is_arena())
	{
		if (self.next_team == world)
			self.frags = -99;
	}
	else	
		self.frags = -99;	

	self.show_hostile = 0;

	// model and view offset
	self.modelindex	= modelindex_eyes;//R00k: added
	self.model = string_null;
	self.mdl = string_null;
	self.weaponmodel = string_null;
	setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
	self.view_ofs = '0 0 22';
	self.nextthink = -1;    // thinking is used to animate client models
	self.think = SUB_Null;
    // teleport stuff
	observer_find_teleport();
	self.wait = time + 2;
    // update display immediately
	self.delay = 0;
	// reset display hold time	
	self.lip = 0;	
	self.height = TEAM_SPECTATOR;// fixed observer color cheat?

	if (self.oflags & OBSERVER_FLY)
		observer_fly_start();
	else
	if (self.oflags & OBSERVER_CHASE)
	{
		if (self.oflags & OBSERVER_AUTO)
			self.oflags = self.oflags | OBSERVER_GO_AUTO;
		observer_chase_start();
	}
	else
	if (self.oflags & OBSERVER_DEMO)
	{
		// This is necessary to prevent the other player's model from being drawn. Don't fucking ask me why!!!
		if (self.oflags & OBSERVER_AUTO)//R00k added autopov
			self.oflags = self.oflags | OBSERVER_GO_AUTO;
		self.nextthink = time + 0.1;
		self.think = observer_demo_start;
	}
	else
	if (self.oflags & OBSERVER_CAMERA)
	{
		if (self.oflags & OBSERVER_AUTO)
			self.oflags = self.oflags | OBSERVER_GO_AUTO;
		observer_camera_start();
	}
	else
		observer_walk_start();

	if (clanring_playmode & CLANRING_CA_MODE)
	{
		if (boss.state == CA_MATCH_PLAYING)
		{
			observer_demo_start(); //force observer mode during matches; this will call observer_next_target 
		}
	}

	if (self.style & CLANRING_HEADS_UP)
		stuffcmd(self, "viewsize 120\n");

	// Check to see if anyone was observing this client
	observer_disconnect_notify(self);	
};

//
//  O B S E R V E R  E N D
//
//  Return to normal player mode.
//
void() observer_end =
{
	local string tmp = "";

	if (!(self.style & CLANRING_OBSERVER))
		return;

	if (mode_is_arena())
	{
		self.team2 = self.next_team.team2;//reinit your team ownership
		clear_name();
		setcolour (self, self.team2,self.team2);
		tmp = ftos (self.team2);
		stuffcmd (self, "color ");
		stuffcmd (self, tmp);
		stuffcmd (self, "\n");

		self.velocity = '0 0 0';//R00k 1.95
		self.ca_player_flag = PF_PLAYING;
		self.enemy = world;//R00k, v1.92
		self.delay = 0;
		self.wait = time;//11/6/2014 11:29AM
		//R00k: this is a silly hack to fix RA mode when someone spawns but their viewpoint is elsewhere
		msg_entity = self;
		WriteByte(MSG_ONE, SVC_SETVIEWPORT);
		WriteEntity (MSG_ONE, self);
	}

	self.style 	= self.style - (self.style & CLANRING_OBSERVER);//dont clear the .oflags as we want to keep our observer settings.
	self.dmg_tally = 0;

	if (!mode_is_arena())
		self.frags 	= 0;

	if ((clanring_playmode & CLANRING_NORMAL_MODE) || (clanring_playmode & CLANRING_PRACTICE_MODE))
	{
		self.join_time = time;  // Normal/Practice/CTF modes use actual join time
	}

	self.killed = 0;
	observer_check_demo_end();

//	stuffcmd(self, "sm0\n");// CRMOD - smoothing off
//	stuffcmd(self, "v_centerspeed 500\n");

//Force these off now...
	forceinfokey(self, "observer" , "off"); // woods
	forceinfokey(self, "*observer", "off");
	forceinfokey(self, "observing", "off");

	if (self.style & CLANRING_HEADS_UP)
		stuffcmd(self, "viewsize 100\n");
	if (!(clanring_playmode & CLANRING_MATCH_MODE) && (mode_is_arena() == FALSE))
	{
		clanring_put_player_in_list();
	}

	// This is to prevent a condition where one player is another player's
	// movetarget, which can confuse the auto module.
	self.movetarget = world;
	if (!mode_is_arena())
		stats_reset_player();
	clear_afk_status(self);		//R00k: added (12/7/2022)
	SetNewParms2();	
	PutClientInServer();
};

// CRMOD
//  F I N D  C A M E R A
//    by Paul Baker
//
//  Returns the next camera after the given entity.
//
entity (entity e) observer_find_camera =
{
	local entity targ;

	targ = find(e, classname, "clanring_camera");
	
	if (targ == world)
		targ = find(targ, classname, "clanring_camera");
	
	if (!targ)//R00k: if no cameras lets use the intermission point
   	{
		targ = find(e, classname, "info_intermission");     	
		if (targ == world)
		{
			targ = find(targ, classname, "info_intermission");
		}
    }
    	
	return targ;
};

// CRMOD
//  N E X T  C A M E R A
//    by Paul Baker
//
//  Get next camera to watch from.
//
void() observer_next_camera =
{
	local entity camera;
	local vector angle;

	self.movetarget = camera = observer_find_camera(self.movetarget);
	setorigin(self, camera.origin);
	if (camera.movetarget != world)
		angle = angles_bestaim(camera.origin, camera.movetarget.origin);
	else
		angle = camera.angles;

	angles_fixangle(angle);
	self.delay = 0;
};

// CRMOD
//  P R E V  C A M E R A
//    by Paul Baker
//    
//  Get previous camera to watch from.
//
void() observer_prev_camera =
{
	local entity e, curr, camera;
	local vector angle;

	curr = self.movetarget;
	e = observer_find_camera(curr);
	
	if (curr == world)//R00k something went wrong!
	{
		curr = e;
		self.movetarget = e;
	}
	
	while (e != curr)
	{
		self.movetarget = e;
		e = observer_find_camera(e);
	}
	
	camera = self.movetarget;
	setorigin(self, camera.origin);
	if (camera.movetarget != world)
		angle = angles_bestaim(camera.origin, camera.movetarget.origin);
	else
		angle = camera.angles;

	angles_fixangle(angle);
	self.delay = 0;
};

//
//  F I N D  T A R G E T
//
//  Returns the next watch target after the given entity.
//
entity (entity e) observer_find_target =
{
	local entity targ;

	if ((e.classname != "player") || (e.style & CLANRING_OBSERVER) || !(e.style & CLANRING_CONNECTED))
		e = world;
	targ = find(e, classname, "player");
	while (targ != e && (!targ || (targ.style & CLANRING_OBSERVER) || !(targ.style & CLANRING_CONNECTED)))
		targ = find(targ, classname, "player");

	observer_update_player_observer_key(self);
	return targ;
};

//
//  F I N D  B E S T  T A R G E T
//
//  Returns the player with the best score
//	Arena mode only.

void () observer_find_best_target =
{
    local entity targ;
    
    targ = find (world, classname, "player");

    while (targ != world)
    {
        if ((IS_CA_OBSERVER(targ) == FALSE) && (targ.style & CLANRING_CONNECTED))
        {
            if ((targ.frags > self.movetarget.frags))
                self.movetarget = targ;
        }
        targ = find (targ, classname, "player");
    }
};

//
//  F I N D  T E A M T A R G E T
//
//  Returns the next teammate to watch
//	Arena mode only.

entity (entity e) observer_find_team_target =
{
	local entity p;

	p = e.next_player;

	while (p)
	{
        if ((p.deadflag == DEAD_NO) && (IS_CA_OBSERVER(p) == FALSE) && ((p.style & CLANRING_CONNECTED)))
			return p;
		p = p.next_player;
	}
	
	if (p == world)
	{
		p = observer_find_target(world); // Find the winner of the match if opponent
	}

	return p;
};

//
//  N E X T  T A R G E T
//
//  Get the next target to watch.
//
void () observer_arena_next_target =
{	
	if (mode_is_arena() && (boss.state != CA_MATCH_PLAYING && boss.state != CA_MATCH_ROUNDSTART))
	{
		observer_fly_start();
		return;
	}

    entity newt;

    // With cam lock a player can only track his teammates.
    if (self.next_team != world)
        newt = observer_find_team_target(self.movetarget);
    else
         newt = observer_find_target(self.movetarget);

    if (newt == world)
    {
        observer_fly_start ();
        return;
    }

	if (self.movetarget != newt)    // If it's not the same target, then notify
    {
        sprint (self, "Tracking ", self.movetarget.netname, "\n");
        centerprint (self,self.movetarget.netname);
    }

	self.movetarget = newt;

    self.delay = 0;

    if (((self.oflags & OBSERVER_DEMO) && (self.movetarget != world)) && (self.movetarget.player_flag == PF_PLAYING))
    {
        msg_entity = self;
        WriteByte(MSG_ONE, SVC_SETVIEWPORT);
        WriteEntity(MSG_ONE, self.movetarget);
        observer_set_demo_position();
    }    
	observer_update_player_observer_key(self);
};

void () observer_next_target =
{
	if (mode_is_arena())
	{
		observer_arena_next_target();
		return;
	}

	self.movetarget = observer_find_target (self.movetarget);
	
	if (self.movetarget == world)
	{	
		observer_fly_start();
		return;
	}

    // Force an immediate update of the heads-up display
    self.delay = 0;
    
	if ((self.oflags & OBSERVER_DEMO) && (self.movetarget != world))
	{
		msg_entity = self;
		WriteByte(MSG_ONE, SVC_SETVIEWPORT);
		WriteEntity(MSG_ONE, self.movetarget);
		observer_set_demo_position();
	}

	if ((((clanring_playmode & CLANRING_MATCH_MODE)&&(!(clanring_state & CLANRING_MATCH_STARTED)))||(clanring_playmode & CLANRING_NORMAL_MODE))||(self.statstate <0))
	{
		centerprint (self,self.movetarget.netname);
		self.laststattime = time + 2;//Delay the flagstatus bar for 2 seconds.
	}
	observer_update_player_observer_key(self);
};

//
//  P R E V  T A R G E T
//
//  Get the previous target to watch.
//
void () observer_prev_target =
{
    local entity e, curr;

    if (!self.movetarget)
    {
        observer_next_target();
        return;
    }

    curr = self.movetarget;
    if (curr.style & CLANRING_OBSERVER || curr.classname != "player" || !(curr.style & CLANRING_CONNECTED))
    {
        self.movetarget = curr = observer_find_target(curr);
    }
    e = observer_find_target(curr);
    while (e != curr)
    {
        self.movetarget = e;
        e = observer_find_target(e);
    }

    // Force an immediate update of the heads-up display
    self.delay = 0;

    if ((self.oflags & OBSERVER_DEMO) && (self.movetarget != world))
	{
		msg_entity = self;
		WriteByte(MSG_ONE, SVC_SETVIEWPORT);
		WriteEntity(MSG_ONE, self.movetarget);
		observer_set_demo_position();
	}
	observer_update_player_observer_key(self);
};

//
//  L O O K  F O R  T A R G E T
//
//  Helper function for observer_get_target; looks in a single direction.
//  Returns TRUE if a target is found; FALSE otherwise.
//
float (vector from) observer_look_for_target = 
{
	traceline(from, from + v_forward * 1200, FALSE, self);
	if (trace_fraction < 1.0)
	{
		if (trace_ent.classname == "player" && (trace_ent.style & CLANRING_CONNECTED) && (trace_ent.health))//R00k added health check
		{
			if (self.movetarget != trace_ent)
			{
				self.movetarget = trace_ent;
				self.delay = 0;
				self.lip = time + 1;
			}
			return TRUE;
		}
	}
	return FALSE;
};

//
//  G E T  T A R G E T
//
//  Looks for a client in the line of sight.
//
void () observer_get_target =
{
	local vector from;
	local vector angle;

	// first check to see if old one is still visible
	if (self.movetarget)
	{
		local float temp;
		angle = vectoangles(self.movetarget.origin - self.origin);
		temp = angle_y - self.v_angle_y;
		if (temp > 180)
			temp = temp - 360;
		temp = fabs(temp);
		if (temp < 15)
		{
			// they're still there
			self.lip = time + 1;
			return;
		}
	}

	angle = self.v_angle;
	from = self.origin + '0 0 22';

    makevectors(angle);
	if (observer_look_for_target(from))
		return;
	angle_y = angle_y + 5;
    makevectors(angle);
	if (observer_look_for_target(from))
		return;
	angle_y = angle_y - 10;
    makevectors(angle);
	if (observer_look_for_target(from))
		return;

	// didn't find anyone
	if (self.movetarget != world && self.lip < time)
	{
		self.movetarget = world;
		self.delay = 0;
	}
};

//
//  D I S C O N N E C T  N O T I F Y
//
//  Called when a client disconnects or becomes an observer.  Used to
//  update the watch target for any observers that were watching this client.
//
void (entity client) observer_disconnect_notify =
{
    local entity e, oself;
    
    e = find(world, classname, "player");
    while (e)
    {
        if ((e.style & CLANRING_OBSERVER) && (e.movetarget == client))
        {
            oself = self;
            self = e;
            observer_next_target();
            if (!self.movetarget)
			{
				if (self.oflags & (OBSERVER_CHASE | OBSERVER_DEMO))
				{
					sprint(self, "No more chase targets\n");
					observer_walk_start();
				}
				else if (self.oflags & (OBSERVER_CAMERA))
					observer_next_camera();
			}
            self = oself;
        }
        e = find(e, classname, "player");
    }
    
    // CRMOD so cameras don't follow either
    if (self == clanring_best_chase_target)
    	clanring_best_chase_target = world;
	if (self == clanring_current_chase_target)
		clanring_current_chase_target = clanring_best_chase_target;
	if (self == clanring_best_camera)
		clanring_best_camera = find(world, classname, "clanring_camera");
	if (self == clanring_current_camera)
		clanring_current_camera = clanring_best_camera;

    e = find(world, classname, "clanring_camera");
    while (e)
    {
    	if (e.movetarget == client)
    	{
    		oself = self;
    		self = e;
			self.movetarget = world;
    		auto_camera_think();
    		self = oself;
    	}
    	e = find(e, classname, "clanring_camera");
    }
    // CRMOD END
};

//
//  F I N D  E N E M Y
//    by Paul Baker
//
//  Corrected and optimized by J.P.
//
//  Called by observer_set_chase_position for use in tourneycam mode
//
void () observer_find_enemy =
{
	local entity potential;

	if (self.clanring_did_damage + 1 > time) // did he hurt someone?
		self.clanring_othertarget = self.movetarget.clanring_inflicted;
	else if ((!self.clanring_othertarget) || (self.health > self.movetarget.health)) // did he get hurt?
	{
		if (self.movetarget.dmg_inflictor.classname == "missile" || self.movetarget.dmg_inflictor.classname == "grenade")
			self.clanring_othertarget = self.movetarget.dmg_inflictor.owner;
		else if (self.movetarget.dmg_inflictor.classname == "player")
			self.clanring_othertarget = self.movetarget.dmg_inflictor;
	}

	// Sanity check
	if (self.clanring_othertarget)
	{
		if ((self.clanring_othertarget.style & CLANRING_OBSERVER) || !(self.clanring_othertarget.style & CLANRING_CONNECTED) || (self.clanring_othertarget == self.movetarget))
			self.clanring_othertarget = world;
		else if ((self.clanring_othertarget.team == self.movetarget.team) && teamplay)
			self.clanring_othertarget = world;
		else if (!utils_new_visible(self.movetarget, self.clanring_othertarget))
			self.clanring_othertarget = world;
		else if (self.clanring_othertarget.health > 0)//R00k: tourney-cam's dead camera shake bug fix (testing)
			self.clanring_othertarget = world;
	}	

	// If no target, then look for a good one (check next player in list)
	if (!self.clanring_othertarget)
	{
		if (!self.next_player)
			self.next_player = clanring_sentinel.next_player;
		if (self.next_player == self.movetarget)
			self.next_player = self.next_player.next_player;
		potential = self.next_player;
		if (potential)
		{
			if (((potential.team != self.movetarget.team) || !teamplay) && (potential.health > 0))//R00k: added health check
			{
				if (utils_new_visible(self.movetarget, potential))
					self.clanring_othertarget = potential;
			}
			self.next_player = potential.next_player;
		}
	}
};

//
//  S E T  C H A S E  P O S I T I O N
//
//  Called every frame for observers in chase mode.  Used to position
//  the observer behind the player being chased.
//
//  Chase cameras are tricky business - they are notoriously choppy.
//  This choppines is due to two problems:
//
//  1.  The network protocol quantizes angles into 256 discrete values.
//      The client, on the other hand, can set the angle (through user
//      input) much more precisely.  Hence, the chase target's view
//      angle is constantly being rounded off.
//
//  2.  The client side doesn't use the exact positions sent by the server
//
//  To address problem 1, we quantize the angles of the player being chased
//  *before* using them to calculate the new position.  This ensures that
//  the player being watched will stay in the center of the screen and will
//  not jitter back and forth due to angle roundoff.
//
//  To address problem 2, the client should enter "cl_nolerp 1" in their
//  console (the "smooth" alias does this automatically);
//
void () observer_set_chase_position =
{
    local vector pos;
    local vector desired_angle;	// CRMOD
    local vector angle;
    
    if (self.oflags & OBSERVER_AUTO)
	{
		// JP - added this because now this can be called from observer_set_camera_position
		if (self.oflags & OBSERVER_CHASE)
		{
			if (time > self.clanring_cam_delay)
			{
				if (clanring_current_chase_target != world && self.movetarget != clanring_current_chase_target)
				{
					self.movetarget = clanring_current_chase_target;
					observer_chase_start();//R00k: reset in case we were in autopov
					self.delay = 0;
					return;
				}
			}
		}
	}

	// CRMOD - Setting angle equal to v_angle tricks the placement code below into
	// CRMOD - thinking that the direction you are looking is what the chase target
	// CRMOD - is lookin in.  This way freelook still keeps the player in view.

    // if (self.button0)	// freelook
	// {           
    // 	angle = self.v_angle;
	// 	self.clanring_oldangle = self.v_angle;
	// }
    // else
    {
    	// CRMOD - tourney cam
       	if (self.oflags & OBSERVER_TOURNEY)
    	{
    		observer_find_enemy();
    		if (self.clanring_othertarget)
    		   	desired_angle = angles_bestaim(self.movetarget.origin, self.clanring_othertarget.origin);
    		else
    			desired_angle = self.movetarget.v_angle;
    	}
    	else
    		desired_angle = self.movetarget.v_angle;

		angle_x = self.clanring_oldangle_x * (1 - CLANRING_ANGLE_SMOOTHING) + desired_angle_x * CLANRING_ANGLE_SMOOTHING;
		angle_y = angles_pick_angle(self.clanring_oldangle_y, desired_angle_y, CLANRING_ANGLE_SMOOTHING);
		angle_z = 0;
	}

	// Quantize the player's angle so that the angle we use here will
	// be the same as the one used by the client (after the angle has been
	// garbled by the network protocol)
	//
	// if (!self.button0)
	// {
	// 	angle_x = 360.0 / 256.0 * rint(angle_x * 256.0 / 360.0);
	// 	angle_y = 360.0 / 256.0 * rint(angle_y * 256.0 / 360.0);
	// }

    // The "ideal" position is 100 units behind and 40 units above the
    // chase target.  To deal with walls and ceilings, we first trace a
    // line 50 units up and then move 80% of the way along the
    // part of the line that was traced.  We then trace a line 120 units 
	// backwards and move 83% of the way along the part that was traced.
    //    
    makevectors(angle);
    pos = self.movetarget.origin;
    traceline(pos, pos + 50 * v_up, TRUE, self.movetarget);		
    pos = pos + (trace_fraction * 40) * v_up;					
    traceline(pos, pos - 120 * v_forward, TRUE, self.movetarget);
    pos = pos - (trace_fraction * 100) * v_forward;				
    setorigin(self, pos);

	//R00k:	Replaced .button0 to toggle obs modes..
    // if (self.button0)
    //     return;  // freelook; don't set the viewing angle

    angles_fixangle(angle);
};

//
//  S E T  D E M O  P O S I T I O N
//
//  Similar to, but simpler than, observer_set_chase_position.  We need
//  to set the view angles.  The view position is set semi-automatically,
//  but quake gets confused if the observer's entity is in a very different
//  location, so to keep it happy we move the observer's entity to the
//  chasetargets location.
//
void () observer_set_demo_position =
{
	if ((self.movetarget == world)||(self.movetarget.style & CLANRING_OBSERVER)||(!(self.movetarget.style & CLANRING_CONNECTED)))
	 	return;

	if (self.oflags & OBSERVER_AUTO)
	{
		if (self.oflags & OBSERVER_DEMO)
		{
			if (time > self.clanring_cam_delay)
			{
				if (clanring_current_chase_target != world && self.movetarget != clanring_current_chase_target)
				{
					self.movetarget = clanring_current_chase_target;
				    msg_entity = self;
				    WriteByte(MSG_ONE, SVC_SETVIEWPORT);
				    WriteEntity(MSG_ONE, self.movetarget);
					self.delay = 0;
				}
			}
		}
	}

    setorigin(self, self.movetarget.origin);

    // if (self.button0)
    //     return;  // freelook; don't set the viewing angle

    self.v_angle = self.angles = self.movetarget.v_angle;	// CRMOD added v_angle
    self.fixangle = TRUE;
};

// CRMOD
// S E T  C A M E R A  P O S I T I O N
//   by Paul Baker
//
//   Camera movement
//
void () observer_set_camera_position =
{	
	local entity camera;
	local vector angle;
	local entity player;
	
	camera = self.movetarget;

	if (self.oflags & OBSERVER_AUTO)
	{
		if (time > self.clanring_cam_delay)
		{
			if (clanring_current_camera != world && self.movetarget != clanring_current_camera)
			{
				camera = self.movetarget = clanring_current_camera;
				self.delay = 0;
				if (clanring_current_camera.classname == "elohim_camera")
				{
					setorigin(self, clanring_best_camera.origin);
					if (camera.movetarget)
						angle = angles_bestaim(camera.origin, camera.movetarget.origin);
					else
						angle = camera.angles;
					angles_fixangle(angle);
				}
			}
		}
	}
	else if (camera.classname == "elohim_camera") // in case the movetarget is a debug target
	{
		if ((time > self.clanring_cam_delay) && (time > camera.clanring_cam_delay))
			camera.movetarget = world;
		else if (camera.movetarget) 
		{
			if (!utils_visible(camera, camera.movetarget))
				camera.movetarget = world;
		}
		if (!camera.movetarget) 
		{
			camera.movetarget = clanring_sentinel;
			player = clanring_sentinel.next_player;
			while (player) 
			{
				if (utils_visible(camera, player)) 
				{
					if (player.clanring_chase_score > camera.movetarget.clanring_chase_score)
						camera.movetarget = player;
				}
				player = player.next_player;
			}
			if (camera.movetarget == clanring_sentinel)
				camera.movetarget = world;
			else
				self.clanring_cam_delay = time + 4;
		}
	}
	
	if (camera.classname == "player")
	{
		observer_set_chase_position();	// JP - added this
		return;
	}

	// if (self.button0) // freelook
	// 	return;
	
	if (camera.movetarget)
	{
		local float seeable;	//R00k: let's test if we have a visible target; we don't want the camera facing a wall.
		seeable = utils_new_visible (camera, camera.movetarget);
		if (seeable)
			angle = angles_bestaim (camera.origin, camera.movetarget.origin);
		else
		{
			camera.clanring_cam_delay = (camera.clanring_cam_delay - 0.05);		//R00k: If our camera target is behind a wall reduce the time we are focused on them.
			angle = angles_bestaim (camera.origin, camera.movetarget.origin);	//Still point towards their direction
		}
	}
	else
		angle = camera.angles;

	angle_x = self.clanring_oldangle_x * (1 - CLANRING_ANGLE_SMOOTHING) + angle_x * CLANRING_ANGLE_SMOOTHING;
	angle_y = angles_pick_angle(self.clanring_oldangle_y, angle_y, CLANRING_ANGLE_SMOOTHING);
	angle_z = 0;
	angles_fixangle(angle);
};

//
//  H E L P
//
void () observer_help =
{
        sprint(self, "Observer commands:\n");
        sprint(self, " help-walk       - \bhelp for walk mode\n");
        sprint(self, " help-fly        - \bhelp for fly mode\n");
        sprint(self, " help-chase      - \bhelp for chase/demo mode\n");
        sprint(self, " help-camera     - \bhelp for camera mode\n");
        sprint(self, " ready           - \bexit observer mode\n");
        sprint(self, " walk/flyme      > \bchoose mode\n");
        sprint(self, " chase/eyecam    > \bchoose mode \n");
        sprint(self, " autochase       - \bautomatic chasecam mode\n");
        sprint(self, " camera          - \bcamera mode\n");
        sprint(self, " autocam         - \bautomatic camera mode\n");
        sprint(self, " headsup         - \btoggle heads up display\n");
        sprint(self, " tourney         - \btoggle tournament chase\n");
        sprint(self, " commentary      - \btoggle commentary\n");
};

//
//  W A L K  H E L P
//
void () observer_walk_help =
{
        sprint(self, "Walk mode controls:\n");
        sprint(self, " jump            - \bjump\n");
        sprint(self, " attack          - \bfly (through walls)\n");
        sprint(self, "help-observer    - \bobserver mode help\n");
};

//
//  F L Y  H E L P
//
void () observer_fly_help =
{
        sprint(self, "Fly mode controls:\n");
        sprint(self, " jump            - \bmove up\n");
        sprint(self, " attack          - \bfly through walls\n");
        sprint(self, "help-observer    - \bobserver mode help\n");
};

//
//  C H A S E  H E L P
//
void () observer_chase_help =
{
        sprint(self, "Chase/eyecam mode controls:\n");
        sprint(self, " attack          - \bfreelook\n");
        sprint(self, " jump            - \bselect next player\n");
        sprint(self, " attack+jump     - \bprevious player\n");
        sprint(self, " smooth          - \btoggle camera smoothing\n");
        sprint(self, " autochase       - \bautomatic chase mode\n");
        sprint(self, "                   \b(chase mode only)\n");
        sprint(self, " tourney         - \btoggle tourneycam\n");
        sprint(self, "                   \b(chase mode only)\n");
        sprint(self, "help-observer    - \bobserver mode help\n");
};

// CRMOD
//  C A M E R A  H E L P
//    by Paul Baker
void () observer_camera_help =
{
        sprint(self, "Camera mode controls:\n");
        sprint(self, " attack          - \bfreelook\n");
        sprint(self, " jump            - \bselect next camera\n");
        sprint(self, " attack+jump     - \bprevious camera\n");
        sprint(self, " smooth          - \btoggle camera smoothing\n");
        sprint(self, " autocam         - \bautomatic camera mode\n");
        sprint(self, "help-observer    - \bobserver mode help\n");
};

//
//  C A N C E L  L E A V E
//
//  *Don't* leave the match.
//
void () observer_cancel_leave =
{
	if (self.owner.style & CLANRING_CONFIRM_LEAVE)
	{
		self.owner.style = self.owner.style - (self.owner.style & CLANRING_CONFIRM_LEAVE);
		sprint(self.owner, "Cancelled\n");
	}
	remove (self);
};

//
//  C O N F I R M
//
//  If someone enters the 'observer' impulse during a match, ask
//  them if they are sure they want to leave the match.
//
void () observer_confirm =
{
	if (self.style & CLANRING_CONFIRM_LEAVE)
		return;

	sprint(self, "Leave match?  Type yes to confirm.\n");
	self.style = self.style | CLANRING_CONFIRM_LEAVE;
	utils_make_scheduled_event(observer_cancel_leave, 5);
};

//
//  C O N F I R M  L E A V E  R E S P O N S E
//
//  They entered yes or know in response to the above prompt.
//
void (float response) observer_confirm_leave_response =
{
	self.style = self.style - (self.style & CLANRING_CONFIRM_LEAVE);

	if (mode_is_arena())
	{
		arena_client_disconnect();
	}

	if (response)
	{
		bprint(sprintf("%s became an \bobserver\b.\n", self.netname));
		observer_start ();
	}
	else
		sprint(self, "Cancelled\n");
};

//
//  I M P U L S E
//
//  Called from elohim_impulse in elohim.qc to handle observer impulses.
//
void () observer_impulse =
{
	if (clanring_state & CLANRING_TAKING_AUTOSS)
		return;

    if (self.style & CLANRING_OBSERVER)
    {
        if (self.impulse == 141)
		{
			self.oflags = self.oflags - (self.oflags & OBSERVER_QUAKETV);	//R00k, the player specifically chose this mode, placing here instead of observer_clear_flags.
            observer_walk_start();
		}
        else if (self.impulse == 142)
		{
			self.oflags = self.oflags - (self.oflags & OBSERVER_QUAKETV);	//R00k
            observer_fly_start();
		}
        else if (self.impulse == 143)
		{
			self.oflags = self.oflags - (self.oflags & OBSERVER_QUAKETV);	//R00k
            observer_chase_start();
		}
		else if (self.impulse == 147)
			utils_toggle_oflag(OBSERVER_COMMENTARY, "Running commentary");
        else if (self.impulse == 148)
            observer_heads_up();
        else if (self.impulse == 149)
            observer_demo_start();
        else if (self.impulse == 150)						
        	stuffcmd(self,"smooth\n"); 
        else if (self.impulse == 151)						
			utils_toggle_oflag(OBSERVER_TOURNEY, "Tournament chasecam mode");
		else if (self.impulse == 153)
			observer_camera_start();
		else if (self.impulse == 154)
			auto_camera_start();
		else if (self.impulse == 155)
			auto_chase_start();
		else if (self.impulse == 157)
			auto_pov_start();
    }
    else
    {                                                                              // CRMOD more commands to go observer
        if ((self.impulse >= 140 && self.impulse <= 143) || self.impulse == 149 || (self.impulse >= 153 && self.impulse <= 155))
        {
			if (self.impulse != 140)
			{
				observer_clear_flags();
				if (self.impulse == 141)
					self.oflags = self.oflags | OBSERVER_WALK;
				else if (self.impulse == 142)
					self.oflags = self.oflags | OBSERVER_FLY;
				else if (self.impulse == 143)
					self.oflags = self.oflags | OBSERVER_CHASE;
				else if (self.impulse == 149)
					self.oflags = self.oflags | OBSERVER_DEMO;
				// CRMOD more commands to go observer
				else if (self.impulse == 155)
					self.oflags = self.oflags | OBSERVER_CHASE | OBSERVER_GO_AUTO;
				else if (self.impulse == 153)
					self.oflags = self.oflags | OBSERVER_CAMERA;
				else if (self.impulse == 154)
					self.oflags = self.oflags | OBSERVER_CAMERA | OBSERVER_GO_AUTO;
				// CRMOD END
			}
			
            if (((clanring_playmode & CLANRING_MATCH_MODE) & (clanring_state & CLANRING_MATCH_STARTED)) ||
				((mode_is_arena()) && (boss.state != CA_MATCH_WAITING)))
                observer_confirm();
            else
                observer_start();
        }
        else if (self.impulse >= 147 && self.impulse != 156)
            sprint(self, "You must be an observer first\n");
    }

    if (self.impulse == 144)
        observer_walk_help();
    else if (self.impulse == 145)
        observer_fly_help();
    else if (self.impulse == 146)
        observer_chase_help();
    else if (self.impulse == 156)
    	observer_camera_help();
};

//
//  J U M P
//
//  Modified version of PlayerJump in Client.qc
//  Fast movement in water/slime/lava; no sounds.
//
//  jump is TRUE if 'jump' was just pressed, FALSE if it is being
//  held down.
//
void (float jump) observer_jump =
{
	if (self.flags & FL_WATERJUMP)
		return;

    if (self.waterlevel >= 2)
	{
        if (self.waterlevel == 3)
            self.velocity_z = 320;
        else
            self.velocity_z = 100;
		return;
	}

    if (!(self.flags & FL_ONGROUND) || !jump)
		return;

	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk
    self.velocity_z = 270;
};

//
//  C H E C K  S I Z E
//
//  If an observer gets caught in a door/platform etc, their size can
//  be set to zero.  This routine is called once every second to make
//  sure that this doesn't last.
//
void () observer_check_size =
{
    if (self.maxs_x < 16 || self.maxs_y < 16)
        setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
};

//
//  U P D A T E  D I S P L A Y
//
//  Heads up display for watching targets.  The format of the display is
//  as follows:
//
//     <player name> [QOR] <weapon>
//     Armour: <type> <value>  Health: <value>  Ammo: <value>
//
//  Q, O, R are the quad, ring and suit flags.  The suit flag is not really
//  an R; it's some weird quake symbol.
//
void () observer_update_display =
{
	local entity player;	// CRMOD cameras

    if ((clanring_state & CLANRING_MATCH_PAUSED) || (self.style & (CLANRING_SETTING_OPTIONS | CLANRING_MOTD)))
        return;

	if (prematch_rules())
	{
		clanring_show_rules_prematch();
		return;
	}

	self.delay = time + 0.5;

	if (self.style & CLANRING_HEADS_UP)
    {		
		player = self.movetarget;
		// CRMOD account for cameras
		if ((player != world) && (player.classname == "clanring_camera"))
			player = player.movetarget;
    
		local string w="", armour="", aval="", healthammo="", ammo="", pad_top="";
        w = strings_get_weapon(player);
        armour = strings_get_armour_type(player);
        aval = strings_get_armour_val(player);
        healthammo = strings_get_health_ammo(player);
        ammo = ftos(player.currentammo);
    	pad_top = TeamSetStatRes2(self);//R00k : position the display based on the observer's .statstate value.
		centerprint7(self, pad_top, player.netname, w, armour, aval, healthammo, ammo);
    }
	else
	{
		if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
		{			
			if (((clanring_playmode & CLANRING_MATCH_MODE)&&(clanring_state & CLANRING_MATCH_STARTED))||(clanring_playmode & CLANRING_NORMAL_MODE))
			{
				TeamCapturePlayerUpdate();
			}
		}	
		else if (clanring_playmode & CLANRING_WIPEOUT_MODE)
		{
			WipeoutModePlayerUpdate();
		}
	}
};

//
//  U P D A T E  S T A T U S  B A R
//
//  Copy the chasetarget's status into the observer's status bar.
//
void () observer_update_status_bar =
{
	local entity player;

	if ( (self.movetarget.classname == "clanring_camera") || (self.movetarget.classname == "info_intermission") )
		player = self.movetarget.movetarget;
	else
		player = self.movetarget;

	if (!player)
	{
		if (self.health == 1000)
			return;
		self.health = 1000;
		self.items = 0;
		self.armorvalue = 0;
		self.ammo_shells = 0;
		self.ammo_nails = 0;
		self.ammo_rockets = 0;
		self.ammo_cells = 0;
		self.currentammo = 0;
		self.show_hostile = 0;
		self.weapon = 0;
		self.weaponmodel = string_null;
		self.items2 = 0;//oops fixed!
		return;
	}
	self.items = player.items;

	if (player.player_flag & ITEM_RUNE_MASK)
	{
		self.items2 = 0;
		if (player.player_flag & ITEM_RUNE1_FLAG)
			self.items2 = (self.items2 | IT2_SIGIL1);
		else
		if (player.player_flag & ITEM_RUNE2_FLAG)
			self.items2 = (self.items2 | IT2_SIGIL2);
		else
		if (player.player_flag & ITEM_RUNE3_FLAG)
			self.items2 = (self.items2 | IT2_SIGIL3);
		else
		if (player.player_flag & ITEM_RUNE4_FLAG)
			self.items2 = (self.items2 | IT2_SIGIL4);
	}//end cam target has rune
	else
		self.items2 = 0;

	self.ammo_shells 	= player.ammo_shells;
	self.ammo_nails 	= player.ammo_nails;
	self.ammo_rockets 	= player.ammo_rockets;
	self.ammo_cells 	= player.ammo_cells;
	self.currentammo 	= player.currentammo;
	self.show_hostile 	= player.show_hostile;
	self.weapon 		= player.weapon;

	if (self.oflags & OBSERVER_DEMO)
	{
		self.weaponmodel = player.weaponmodel;
		self.weaponframe = player.weaponframe;
/*		if ((self.armorvalue != player.armorvalue) ||
			(self.health > player.health + 3) ||
			(self.health < player.health) ||
			(self.items < player.items))
			stuffcmd(self, "bf\n");*/
	}
	else
		self.weaponmodel = string_null;
	self.health = player.health;
	self.armorvalue = player.armorvalue;
	if (self.health <= 0)
		self.health = 1000;
};

//
//  S E T  O R I G I N
//
//  Try to put the observer somewhere around spot.  Return TRUE if successful,
//  FALSE otherwise.
//
float (vector spot) observer_set_origin = 
{
	local float d1, d2;

	// x
	traceline(spot, spot + '32 0 0', TRUE, world);
	d1 = 32 * trace_fraction;
	traceline(spot, spot - '32 0 0', TRUE, world);
	d2 = 32 * trace_fraction;
	if (d1 + d2 < 32)
		return FALSE;
	if (d1 < 16)
		spot_x = spot_x - (16 - d1);
	else if (d2 < 16)
		spot_x = spot_x + (16 - d2);

	// y
	traceline(spot, spot + '0 32 0', TRUE, world);
	d1 = 32 * trace_fraction;
	traceline(spot, spot - '0 32 0', TRUE, world);
	d2 = 32 * trace_fraction;
	if (d1 + d2 < 32)
		return FALSE;
	if (d1 < 16)
		spot_y = spot_y - (16 - d1);
	else if (d2 < 16)
		spot_y = spot_y + (16 - d2);

	// z
	traceline(spot, spot + '0 0 56', TRUE, world);
	d1 = 56 * trace_fraction;
	traceline(spot, spot - '0 0 56', TRUE, world);
	d2 = 56 * trace_fraction;
	if (d1 + d2 < 56)
		return FALSE;
	if (d1 < 32)
		spot_z = spot_z - (32 - d1);
	else if (d2 < 24)
		spot_z = spot_z + (24 - d2);

	setorigin(self, spot);
	return TRUE;
};

//
//  F L Y  T H R O U G H  O B S T A C L E
//
void () observer_fly_through_obstacle =
{
	local float i, spots;
	local vector spot, inc;

	spot = self.origin + '0 0 22';
	makevectors(self.v_angle);//R00k
	traceline(spot, spot + 48 * v_forward, TRUE, self);
	if (trace_fraction == 1)
	{
		self.attack_finished = time;
		return;
	}
	else if (time < self.attack_finished + 0.2)
		return;

	inc = 32 * v_forward;
	spot = spot + 100 * v_forward;
	i = 0;
	spots = 0;
	while (i < 6)
	{
		local float c;
		c = pointcontents(spot);
		if ((c != CONTENT_SOLID) && (c != CONTENT_SKY))
		{
			spots = spots + 1;
			if (spots > 1)
			{
				if (observer_set_origin(spot - 16 * v_forward))
					return;
			}
		}
		else
			spots = 0;
		spot = spot + inc;
		i = i + 1;
	}
};

//
//  F L Y  M O V E
//
//  Called every frame for observers in Fly mode.
//
void() observer_fly_move =
{
	float z;
	
	if (self.button2) 
		z = 200;
	else
		z = self.movement_z;
	
	makevectors(self.v_angle);
	self.velocity = v_forward * self.movement_x + v_right * self.movement_y;
	self.velocity_z = self.velocity_z + z;
	z = vlen(self.velocity);
	
	if (z > 2000)
		self.velocity = (normalize(self.velocity) * 2000);
	
	// if (self.button0)
	// 	observer_fly_through_obstacle ();
	// else
	// 	self.attack_finished = time;
};

//
//  P R E  T H I N K
//
//  Called from PlayerPreThink in client.qc
//
void () observer_pre_think =
{
    local float jump;

    // Deal with button2.  jump is set to TRUE if button2 was just pressed,
    // FALSE otherwise.
    if (self.button2)
    {
        if (self.flags & FL_JUMPRELEASED)
        {
            jump = TRUE;
            self.flags = self.flags - FL_JUMPRELEASED;
        }
        else
            jump = FALSE;
    }
    else
    {
        jump = FALSE;
        self.flags = self.flags | FL_JUMPRELEASED;
    }

    if (self.oflags & (OBSERVER_CHASE | OBSERVER_DEMO | OBSERVER_CAMERA))
    {
        if (jump)
		{
			if (self.movetarget.classname == "player")
			{
				// if (self.button0)
				// 	observer_prev_target();
				// else
				observer_next_target();
			}
			else
			{
    			// if (self.button0)
    			// 	observer_prev_camera();
    			// else
    				observer_next_camera();
			}
			self.clanring_cam_delay = time + 0.2;
		}
 	}
    else
    {
        if (self.oflags & OBSERVER_WALK)// && !self.button0)
        {
            if (self.waterlevel == 2)
                CheckWaterJump ();
    
            if (self.button2)
                observer_jump(jump);
    
            self.finaldest_y = self.movetype = MOVETYPE_WALK;
        }
        else
        {
			self.waterlevel = 0;
            observer_fly_move();
            self.flags = self.flags | FL_ONGROUND;
            self.finaldest_y = self.movetype = MOVETYPE_NOCLIP;//R00k: changed to MOVETYPE_NOCLIP was MOVETYPE_FLY
        }
        observer_check_teleport();

		// check for player in sight every frame
		if (!(mode_is_arena()))
			observer_get_target(); //tourneycam
    }

	if (clanring_playmode & CLANRING_CA_MODE)
	{
		if (
			((boss.state == CA_MATCH_ROUNDSTART)&&(boss.count == 7))
			|| 
		    ((boss.state == CA_MATCH_PLAYING)&&(((self.movetarget == world) || (IS_CA_OBSERVER(self.movetarget))) && (time < self.clanring_cam_delay)))
		   )
		{			
			if (self.next_team == world)
			{				
				if (self.movetarget == world)
				{
					observer_find_best_target();    // find the best player, if no one is cammed.
					self.clanring_cam_delay = time + 0.1;
				}
				observer_demo_start();
			}
		}
	}   

	if ((clanring_playmode & CLANRING_WIPEOUT_MODE) && (self.next_team != world) && (boss.state == CA_MATCH_PLAYING) && (boss.wait == 0))
	{
		if (self.next_team.teamalive < 1)
		{
			self.respawntime = 0;
		}
		else if (self.respawntime > 0) //needed?
		{
			if (time >= self.respawntime)
			{
				observer_end ();
				bprint2(self.netname, " has respawned\n");
				self.next_team.teamalive += 1;
				if (self.next_team.teamalive >= self.next_team.teamtotal)
				{
					self.next_team.nextspawn = 0;
				}
				return;
			}
			else
			{
				if ((self.next_team.nextspawn == 0) || (self.next_team.nextspawn > self.respawntime))
				{
					self.next_team.nextspawn = self.respawntime;
				}
			}
		}
	}
};

//
//  P O S T  T H I N K
//
//  Called from PlayerPostThink in Client.qc
//
void () observer_post_think =
{
	if (!gameover)
	{
		//R00k: cycle modes with +attack button
		if ((self.button0) && (time > self.attack_finished))
		{						
			self.oflags = self.oflags - (self.oflags & (OBSERVER_AUTO|OBSERVER_GO_AUTO|OBSERVER_QUAKETV));

			if (self.oflags & OBSERVER_FLY)
			{
				observer_demo_start ();
			}
			else
			{
				observer_fly_start ();
			}			
			self.attack_finished = time + 0.8;	
		}

		if ((mode_is_arena() == FALSE) || (mode_is_arena() && self.movetarget.ca_player_flag == PF_PLAYING))
		{
			if (self.oflags & OBSERVER_CHASE)
				observer_set_chase_position();
			else if (self.oflags & OBSERVER_DEMO)
				observer_set_demo_position();
			else if (self.oflags & OBSERVER_CAMERA)
				observer_set_camera_position();
		}

		// When an observer touches a door they are not teleported through
		// the door immediately as this doesn't seem to work.  Instead, the
		// POP_FORWARD flag is set and they are teleported through the next
		// time observer_post_think is called.
		//
		if (self.oflags & OBSERVER_POP_FORWARD)
		{
			self.oflags = self.oflags - OBSERVER_POP_FORWARD;
			setorigin(self, self.dest);
			self.velocity = self.dest1;
		}

		// CRMOD - this was moved here, so the observers.health could be
		//         compared to movetarget's in tourney and auto modes
		//         to see if movetarget was damaged
        
		// Update the status bar every frame
		if (!(self.style & CLANRING_HEADS_UP))
			observer_update_status_bar();

		// Update the heads up display every 0.5 seconds
		if (time > self.delay)
			observer_update_display();
	}

	if (self.button0 || self.button2)
	{
		clear_afk_status(self);//R00k: this was missing? (6/27/2022)
	}
	
    if (self.impulse)
    {
		self.finaldest_x = time;//R00k
		// Redirect impulses 1-10 when player is entering a number
		if (self.use != SUB_Null)
		{
			if ((self.use != select_episode) && (self.use != select_map))//R00k WARP 
			{
				if (self.impulse >= 1 && self.impulse <= 10)
				{
					if (self.impulse == 10)
						self.impulse = 230;
					else
						self.impulse = self.impulse + 230;
				}
			}
		}
		else
		if ((mode_is_arena()) && self.impulse >= 1 && self.impulse <= 5 && time > 3)
		{
			if (boss.state != CA_MATCH_CLEANUP)
			{
				Teamplay_Select_Team ();//self.impulse is cleared in this function.
			}
			else
			{
				sprint (self, "Match has ended, you may not join at this time.\n");
				self.impulse = 0; //R00k cleanup console spam after match end.
			}
		}

        if ((self.impulse >= 20) && (self.impulse <= 250))
            clanring_impulse ();
    }
};

//
//  D O O R  T O U C H
//
//  Called from door_touch in Doors.qc.  When an observer in walk or
//  fly mode touches a door, their POP_FORWARD flag is set when it is
//  possible to teleport them through the door.  The global variable
//  'other' points to the player that touched the door.
//
void () observer_door_touch =
{
    local float temp;

    // Ignore observers that are in chase mode or who are above the door
    if (other.origin_z > self.absmax_z || self.oflags & (OBSERVER_CHASE | OBSERVER_DEMO))
        return;

    temp = utils_min(self.size_x, self.size_y) + 40;
    other.dest1 = other.dest = other.velocity;
    other.dest_z = 0;
    other.dest = other.dest * (temp / vlen(other.dest));
    other.dest = other.origin + other.dest;
    if (pointcontents(other.dest) != CONTENT_SOLID)
        other.oflags = other.oflags | OBSERVER_POP_FORWARD;
};

//
//  H E A D S  U P
//
//  Enable/disable heads up display.
//
void () observer_heads_up =
{
    if (self.style & CLANRING_HEADS_UP)
    {
        self.style = self.style - CLANRING_HEADS_UP;
        sprint(self, "Heads up display disabled\n");
        stuffcmd(self, "viewsize 100\n");
    }
    else
    {
        self.style = self.style | CLANRING_HEADS_UP;
        sprint(self, "Heads up display enabled\n\btype \bheadsup\b again to disable.\n");
        stuffcmd(self, "viewsize 120\n");
    }
    self.delay = 0;
};
