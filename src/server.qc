//
// S E R V E R . Q C
//
// This is the main file for CRMod++.  CRMod++ was derived from the
// Elohim server, which is why everything is still called "elohim".
//
// Developed by J.P. Grossman (a.k.a. ùMephistopheles) and Paul Baker
//
// All code by J.P. Grossman unless otherwise commented.
//
// Client fields used:
//
// General:
//
// .style           - Elohim player flags
// .count           - used for entering password / ghostcode / warplevel
// .cnt             - number of suicides remaining
// .crmod_hack_count- count of admin attempts
// .wait            - time to do periodic checks
// .state           - unique player id
// .finaldest_y     - used for pinging
// .height          - used to store player team
// .finaldest_x     - used to test for disconnected players
// .use             - pointer to function to call when a number is entered
// .finaldest_z     - the number that was entered
// .owner           - players's ghost entity
// .enemy           - stores last spawn point/camera location for admins
// .next_team		- pointer to player's team (match) or next player (individual)
// .next_player		- pointer to next player (match/individual)
// .lip             - grenade spam count for practice mode
// .delay			- touchback delay for quake tag
//
// Statistics:
//
// .dest1_x         - damage fired from bullets
// .dest2_x         - damage done from bullets (to enemies)
// .dest1_y         - damage fired from nails
// .dest2_y         - damage done from nails (to enemies)
// .dest1_z         - damage fired from lightning gun
// .dest2_z         - damage done from lightning gun (to enemies)
// .dest_x          - damage fired from rockets
// .dest_y          - damage done from rockets (to enemies)
// .mangle_x        - number of times killed self
// .mangle_y        - number of times killed teammate
// .mangle_z        - number of times was killed
// .crmod_qdwep_x   - damage done with quad        // CRMOD
// .crmod_qdwep_y   - damage fired with quad       // CRMOD
// .crmod_qdwep_z   - number times quad pickedup   // CRMOD
// .crmod_qdkill_x  - number of enemies killed     // CRMOD
// .crmod_qdkill_y  - number of teammates killed   // CRMOD
// .crmod_qdkill_z  - number of self kills         // CRMOD
// .crmod_badstats_x - number of RL paks lost
// .crmod_badstats_y - total damage done to self
// .crmod_badstats_z - total damage done to teammates
//
// Observer mode:
//
// .trigger_field   - closest teleport when observing, last spawn if playing
// .t_width         - activation radius for closest teleport
// .dest            - stores destination for popping forward through doors
// .dest1           - stores velocity for popping forward through doors
// .delay           - time to refresh head's up display for observing
// .speed           - z component of velocity from previous frame (for fly)
// .movetarget      - player being watched in observer mode (world if none)
// .owner           - last spawn point/camera for admins
// .lip             - time to clear display when no target is in line of sight (walk/fly)
// .attack_finished - used to delay before flying through obstacles
//
// Used for setting options:
//
// .delay     - time to update display (shared with observer.qc)
// .pos1_x    - timelimit
// .pos1_y    - fraglimit
// .pos1_z    - mode
// .pos2_x    - gibs
// .pos2_y    - teamplay
// .pos2_z    - noexit
// .worldtype - sys_ticrate
// .light_lev - deathmatch
// .aflag     - pausable/quad/pent/ring/mode vote
// .t_length  - which option is currently selected
//
// Ghost fields:
//
// .count			- ghostcode
// .height			- team
// .state			- indicates if the ghost contains copy on pause data
// Always copied:
// .frags
// .dest
// .dest1
// .dest2
// .mangle
// .crmod_qdwep
// .crmod_qdkill
// .style
// Copied on pause (if not dead):
// .frame
// .effects
// .origin
// .angles
// .waterlevel
// .watertype
// .crmod_old_velocity
// .punchangle
// .nextthink
// .think
// .health
// .items
// .armortype
// .armorvalue
// .weapon
// .weaponmodel
// .weaponframe
// .currentammo
// .ammo_shells
// .ammo_nails
// .ammo_rockets
// .ammo_cells
// .flags
// .walkframe
// .attack_finished
// .pain_finished
// .air_finished
// .invincible_finished
// .invisible_finished
// .super_damage_finished
// .radsuit_finished
// .invincible_time
// .invisible_time
// .super_time
// .rad_time
// .show_hostile
// .jump_flag
// .swim_flag
// .bubble_count
//
// Teams:
//
// .next_player   - first player in team
// .next_team     - next team
// .frags		  - team frags
// .height		  - team pants colour
// .count		  - number of players
// .frags         - team score
// .netname       - strings_get_teamname(...)
// .mdl           - strings_get_teamname_bronze(...)
// .ammo_rockets  - number of rocket launchers team has
//
// Sentinel:
//
// .next_player   - first player in list
// .next_team     - first team in list
// .next_camera   - first camera in list
// .crmod_chase_score - ELOHIM_NEGINF
// .frags         - ELOHIM_NEGINF
// .think         - score_check_sudden_death
// .nextthink     - check sudden death
// .ammo_rockets  - number of rocket launchers in play
//
// Match timer:
//
// .lip		- minutes remaining
// .count	- seconds remaining
// .dest	- time intervals for countdown (fast/normal)
//
// Scoreboard:
//
// .timeslot  - slot used for time remaining
//
// Powerups
//
// .noise4	  - pickup message
// .owner	  - player that picked it up
// .height    - height of player that picked it up
// .count	  - number of times in a row player picked it up
// .cnt		  - number of times in a row team picked it up
// .fly_sound - sound number for quakeTV
//
// Rockets
//
// .dmg              - did damage flag
// .state            - rocket jump flag
// .crmod_badstats_y - damage done to self
//
// Console variables used:
//
// samelevel  = elohim_playmode - server flags
// scratch1   = elohim_level    - level number in user level sequence
// scratch2   = elohim_overtime - length of overtime
// temp1                          - console commands
// v_kickpitch                    - used non-destructively for utils_stof
//

// function declarations
void () clanring_remove_start_teleport;
void () clanring_find_powerups;
void () clanring_exec_configs;
void () clanring_precache_matchsounds;
void (float value) clanring_set_teamplay;
void (float value) clanring_set_fraglimit;
void () stats_reset_player;
void () stats_impulse;
void () score_init_world;
void (float command) console_command;
void () console_set_aliases;
void () client_select_warp;
void (float episode) votables_init_warp;
void () votables_request_vote_exit;
void (entity client) observer_disconnect_notify;
void () votables_send_aliases;
void () admin_impulse;
void () admin_start_code;
void (float fDoKick) admin_confirm_kick_response;
void (float fDoKick) admin_confirm_ban_response;
void (entity player) admin_disconnect_notify;
void () observer_impulse;
void () observer_help;
void () observer_find_teleport;
void () observer_check_size;
void (float response) arena_observer_confirm_leave_response;
void (float response) observer_confirm_leave_response;
void () match_show_timelimit;
void () match_impulse;
void () match_init_world;
void (entity player) match_disconnect_notify;
void () vote_impulse;
//void () execute_changelevel;
void () NextLevel;
void (vector org, entity death_owner) spawn_tdeath;
void () player_stand1;
void (vector org) spawn_tfog;

void () observer_start;
void () W_ChangeWeapon;
void () TeamFlagStatusReport;
void () UnHookPlayer;
void () votables_request_set_runes;
void () PreviousWeaponCommand;
void () StartRuneSpawnStart;
void () player_hook1;
void () player_hook3;
void () HookFire2;
void () ban_kick_client;
void (entity client) clanring_kick_player;
void () modes_commands;
void () gameplay_commands;
void () watch_commands;
void () stat_commands;
void () misc_commands;
void () modhelp_commands;
void () shortcuts_commands;
void () arena_init_world;
void () rocket_arena_init_world;
void () arena_main_loop;
void () dmm4_main_loop;
void () rocket_arena_main_loop;
void () arena_precache;
void () RemoveFromTeam;//R00k: ca mode
void () arena_client_disconnect;
void () CaptureHighScores_sprint;
void () AirshotHighScores_sprint;
void () LongRangeGibs_sprint;
//void () Teamplay_Select_Team;
//
// C L E A R   A F K   S T A T U S
//

void (entity client) clear_afk_status =
{
    if (client.style & CLANRING_AFK_CLIENT && (client.style & CLANRING_CONNECTED))
    {
        updatename(client, client.netname);
        client.style = client.style - (client.style & CLANRING_AFK_CLIENT);
        forceinfokey(self, "afk","no");// woods
    }
    client.afk_time = time;
}
//woods —
/*
mode: dm, ctf, ra, ca, wipeout, airshot, dmm4
playmode: match, ffa, practice
*/

//Used for QSSM parsing
void () server_set_infokey_modes =
{
    local string zmode = "", pmode = "";

    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        pmode = "match";

        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
            zmode = "ctf";
        else
            zmode = "dm";
    }
    else
    {
        if (clanring_playmode & CLANRING_NORMAL_MODE)
        {
            if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
            {
                pmode = "pug";
                zmode = "ctf";
            }
            else
            {
                if (teamplay)
                {
                    pmode = "pug";
                    zmode = "dm";
                }
                else
                {
                    pmode = "ffa";
                    zmode = "dm";
                }
            }
        }
        else
        {
            if (clanring_playmode & CLANRING_PRACTICE_MODE)
            {
                zmode = ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) ? "ctf":"dm");
                pmode = "practice";
            }
        }
    }

    if ((mode_is_arena()))
    {
        pmode = "match";
        zmode = "arena";

             if (clanring_playmode & CLANRING_WIPEOUT_MODE) zmode = "wipeout";
        else if (clanring_playmode & CLANRING_DMM4_MODE) 	zmode = "dmm4";
        else if (clanring_playmode & CLANRING_CA_MODE) 		zmode = "clanarena";
        else if (clanring_playmode & CLANRING_RA_MODE) 		zmode = "rocketarena";
        else if (clanring_playmode & CLANRING_AIRSHOT_MODE) zmode = "airshot";
    //else if (clanring_playmode & CLANRING_FREEZETAG_MODE) zmode = "freezetag";
    }
    forceinfokey(world, "gametype", zmode);	//for json output; gamemode = gametype + playmode ("CTF PickUp", "CA Match", "TDM Practice")
    forceinfokey(world, "mode", zmode);
    forceinfokey(world, "playmode", pmode);
};

.float matchTime;

/**/
void () W_Precache;
//
//  I N I T  W O R L D
//
//  Called from worldspawn in World.qc
//
void () clanring_init_world =
{
    local float mode;
    local string szmode;
    local float temp;

    //CRMOD - string to be used throughout code to show version number.
    //version.year.month.day
    string vstring = strftime(TRUE, "%y.%m");

    clanring_version        = strzone(sprintf("\bClanRing\b\n(v1.%s)",vstring));		// This is used in the server console, the 'vinfo' display, and on connect.
    clanring_version_info   = strzone(sprintf("nqCRx (v1.%s)",vstring));				// This is the value for the forced server infokey named "mod" for QSSM.
    clanring_version_number = strzone(sprintf("(1.%s)",vstring));						// This is only used once when typing 'commands' in the server console. :|
    //clanring_version_red    = strzone(sprintf("\bClanRing\b\nCRx (v1.%s)",vstring));	// This isn't used anywhere :(

    // Initialize sentinel
    clanring_sentinel = spawn();
    banent = spawn();

    clanring_playmode = cvar("samelevel");
    clanring_gameconfig = cvar("gamecfg");	//R00k TODO: migrate settings

    if (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))
    {
        forceinfokey (world, "red flag","");
        forceinfokey (world, "blue flag","");
    }

    if ((clanring_state & CLANRING_MATCH_STARTED)||(!(gameover)))	//Only update if game is on-going.
        clanring_sentinel.matchTime = time;

    clanring_sentinel.next_player = world;
    clanring_sentinel.next_team = world;
    clanring_sentinel.next_camera = world;
    clanring_sentinel.clanring_chase_score = CLANRING_NEGINF;

    // Initialize user map names, MOTD, and hotspots, etc..
    userdefs_init_world();
    motd_init_world();
    score_init_world();
    match_init_world();
    //quaketag_init_world();
    if (isFTEserver)
        autocvar(nqfriction, "1");	//Set this to 1 if using FTE as a server with sv_nqplayerphysics 0 to simulate NQ bunnyhopping but allowing QW clients to use prediction.

    temp = 0;

    while(temp < 10)
    {
        array_password[temp] = 0;
        temp += 1;
    }

    // Hack to allow console to emulate an administrator
    world.style = CLANRING_ADMINISTRATOR;

    // Precache sounds
    precache_sound("wizard/wsight.wav");
    precache_sound("doors/drclos4.wav");
    precache_sound("demon/sight2.wav");
    precache_sound("dog/dsight.wav");
    precache_sound("knight/ksight.wav");
    precache_sound("ogre/ogwake.wav");
    precache_sound("shambler/ssight.wav");
    precache_sound("soldier/sight1.wav");
    precache_sound ("crx/goodstat.wav");
    precache_sound ("crx/congrats.wav");
    precache_sound ("crx/hiscore.wav");
    precache_sound ("crx/laugh3.wav");
    precache_sound ("crx/laugh6.wav");
    //end
    precache_sound ("ra/gong.wav");

    //	qsmack_init_server ();

    // Check to see if we need to initialize the server
    if (!(clanring_playmode & CLANRING_SERVER_INITIALIZED))
    {
        print("Initializing Server...[");
        print(clanring_version_info,"]\n");
        // Set aliases for console commands
        console_set_aliases ();

        // Initialize global variables
        cvar_set ("scratch1", "1");//level index
        cvar_set ("scratch2", "0");//overtime
        cvar_set ("scratch3", "2");//maxteams

        serverflags	= 0;

        // TODO:
        // clanring_gameconfig 	= clanring_gameconfig | CLANRING_EXTENDED_OBITS;
        // clanring_gameconfig 	= clanring_gameconfig | CLANRING_RUNETOSS;	//can toss runes on by default.

        clanring_playmode 	= clanring_playmode | CLANRING_EXTENDED_OBITS;
        clanring_playmode 	= clanring_playmode | CLANRING_RUNETOSS;	//can toss runes on by default.
        clanring_playmode 	= clanring_playmode | CLANRING_MATCH_MODE;
        clanring_playmode 	= clanring_playmode | CLANRING_CAPTURE_THE_FLAG;//default match clanring ctf
        clanring_playmode 	= clanring_playmode | CLANRING_SERVER_INITIALIZED;
        clanring_state 		= clanring_state 	| CLANRING_TEAM_CAPTURE_CUSTOM;

        utils_set_cvar("samelevel", clanring_playmode);
        utils_set_cvar("gamecfg", clanring_gameconfig);
    }//initialized

    // Get/set console variables
    teamplay = cvar("teamplay");
    clanring_set_teamplay(-1);
    timelimit = (cvar("timelimit") * 60);

    //R00k: this is CRCTF not 3waveCTF anymore. I prefer a smooth hook with better physics.
    //Zoid originally had hook speeds in version 1.0 at 1000 x 1000, then changed in 2.0 to 800x1000!
    //I set it to 1200 x 850, which is more FLUID! 1000x800 kinda worked but some standard hook tricks were lost...

    hookspeedfire = 1200;
    hookspeedpull = 850;

    if (mode_is_arena())
        default_nextmap = "dm3";
    else if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
        default_nextmap = "ctf1";
    else
        default_nextmap = "start";

    // Set global variables
    clanring_level 			= cvar("scratch1");
    if (clanring_level < 1) clanring_level = 1;
    clanring_overtime 		= cvar("scratch2");
    clanring_maxteams 		= cvar("scratch3");
    clanring_levelcount 	= 0; // - This is used throughout to check that levels.cfg has been read...
    clanring_lastcount 		= 0; // - used to count how many maps are listed in levels.cfg so we know when to recycle.
//	clanring_player_ids 	= 1;
    clanring_devparam 		= 0;
    clanring_nextcheck 		= time;
    clanring_nextcheck2 	= time;
    clanring_request 		= world;

    clanring_state 			= 0;
    //dm_num_spawns 	= 0;//R00k: Why reset this? the spawns are counted at map load before this init is called?
    clanring_num_starts 	= 0;
    clanring_num_cameras 	= 0;
    clanring_debug_client 	= world;

    clanring_best_chase_target 	= world;
    clanring_current_chase_target = world;

    clanring_chase_delay 		= 0;

    clanring_best_camera 		= world;
    clanring_current_camera 	= world;
    clanring_camera_delay 		= 0;
    auto_parm1 					= 600; 	// only rocket bonus
    auto_parm2 					= 1000; // pent proximity bonus
    auto_parm3 					= 500; 	// quad proximity bonus
    auto_parm4 					= 0;
    clanring_pent 				= world;
    clanring_quad 				= world;

    clanring_afk_check 			= 300; 	//R00k: 5 MINUTES default for AFK status.
    clanring_afk_timeout 		= 1800; //Time to kick after AFK (30 minutes).

    utils_make_scheduled_event(clanring_find_powerups, 5);

    if (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))
    {
        clanring_playmode |= CLANRING_NO_HOOK;// Set this for non ctf modes, so that when the hook is voted ON, we can check for this flag missing.
    }

    if ((clanring_playmode & CLANRING_MATCH_MODE) || (clanring_playmode & CLANRING_DMM4_MODE) || (clanring_playmode & CLANRING_AIRSHOT_MODE))
    {
        clanring_timelimit = cvar("timelimit");
        if ((clanring_timelimit == 0) && (clanring_playmode & CLANRING_MATCH_MODE))
            clanring_timelimit = 20;
        else if (clanring_timelimit == 0)
            clanring_timelimit = 0;
        else if (clanring_timelimit < 2)
            clanring_timelimit = 2;
        default_timelimit = clanring_timelimit;//R00k added
        match_show_timelimit();
        forceinfokey(world, "matchtime", ftos(clanring_timelimit));//R00k: requested by Woods.
    }
    else
        default_timelimit = clanring_timelimit = 20;

    if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (clanring_playmode & CLANRING_NORMAL_MODE))//Defaults for Pub CTF mode
    {
        clanring_state = clanring_state - (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM);
        cvar_set("teamplay","1");
        clanring_set_teamplay(1);
        cvar_set("fraglimit","150");
        clanring_set_fraglimit(150);
        cvar_set("timelimit","30");
        timelimit = (cvar("timelimit")*60);
    }
    else
    if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (clanring_playmode & CLANRING_PRACTICE_MODE))
        clanring_state = clanring_state | CLANRING_TEAM_CAPTURE_CUSTOM;
    else
    if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (clanring_playmode & CLANRING_MATCH_MODE))
    {
        cvar_set("teamplay","1");
        clanring_set_teamplay(1);
        clanring_state = clanring_state | CLANRING_TEAM_CAPTURE_CUSTOM;
    }
    else if (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && !(clanring_playmode & CLANRING_NO_HOOK)
        &&	!(clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM))
    {
        clanring_state = clanring_state | CLANRING_TEAM_CAPTURE_CUSTOM;
    }

    W_Precache ();
    // show mode
    mode = options_get_mode();
    szmode = strings_get_mode(mode);
    cprint2(szmode, " mode\n");

    if (mode_is_arena() == TRUE)
    {
        arena_precache();
        arena_init_world();
    }

    if (clanring_gameconfig & CLANRING_ENABLE_MATCHSOUNDS)
        clanring_precache_matchsounds();

    if (clanring_gameconfig & CLANRING_DROP_DEATH_SHARDS)
    {
        precache_model ("progs/armshr.mdl");
        precache_sound ("items/armsh1.wav");
    }

    // schedule the config files for a bit later so that they don't
    // get loaded twice on startup
    utils_make_scheduled_event(clanring_exec_configs, 1);
    // spawn runes if enabled, wait for the cfg to be read.
    utils_make_scheduled_event(StartRuneSpawnStart, 2);
    // fix the start teleport bug
    utils_make_scheduled_event(clanring_remove_start_teleport, 3);

    // woods set serverinfo mod name
    forceinfokey(world, "mod", clanring_version_info);
    server_set_infokey_modes();
};

//
//  R E M O V E  S T A R T  T E L E P O R T
//
void () clanring_remove_start_teleport =
{
    if (mapname == "start")
    {
        other = find(world, classname, "trigger_teleport");
        while (other)
        {
            if (other.absmin_z < -600)
            {
                remove(other);
                cprint("\"start: bad teleport removed (this is not an error)\"\n");
            }
            other = find(other, classname, "trigger_teleport");
        }
    }
    remove(self);
};

//
//  F I N D  P O W E R U P S
//
void () clanring_find_powerups =
{
    clanring_quad = find(world, classname, "item_artifact_super_damage");
    clanring_pent = find(world, classname, "item_artifact_invulnerability");
    remove(self);
};

//
//  S E T  T E A M P L A Y
//
//  Sets the teamplay server variable to show teamplay and "ClanRing4.0".
//  If value = -1 then the teamplay variable is preserved; otherwise it
//  is changed to 'value'.
//
void (float value) clanring_set_teamplay =
{
    local string temp;

    if (value != -1)
        teamplay = value;
    temp = ftos(teamplay);
    localcmd3("teamplay \"", temp, "\"\n");
};

//
//  S E T  F R A G L I M I T
//
//  Sets the fraglimit server variable to show fraglimit, "CRMod++",
//  and either "FFA", "Practice", "Match" or "Individual" depending on the
//  current mode.  If value = -1 then the fraglimit variable is preserved;
//  otherwise it is changed to 'value'.
//
void (float value) clanring_set_fraglimit =
{
    local string temp;

    if (value != -1)
        utils_set_cvar("fraglimit", value);

    fraglimit = cvar("fraglimit");
    temp = ftos(fraglimit);

    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
            localcmd3("fraglimit \"", temp, " : CRCTF ");
        else
            localcmd3("fraglimit \"", temp, " : CRMod++ ");

        if (teamplay)
            localcmd("Match\"\n");
        else
            localcmd("Duel\"\n");
    }
    else if (mode_is_arena())
    {
        if (clanring_playmode & CLANRING_AIRSHOT_MODE)
        {
            localcmd3("fraglimit \"", temp, " : Airshot\"\n");
        }
        else if (clanring_playmode & CLANRING_DMM4_MODE)
        {
            localcmd3("fraglimit \"", temp, " : PovDuel\"\n");
        }
        else if (clanring_playmode & CLANRING_RA_MODE)
        {
            localcmd3("fraglimit \"", temp, " : RocketArena\"\n");
        }
        else if (clanring_playmode & CLANRING_CA_MODE)
        {
            localcmd3("fraglimit \"", temp, " : ClanArena");
            if (clanring_playmode & CLANRING_WIPEOUT_MODE)
            {
                localcmd("Wipeout\"\n");
            }
            else
                localcmd("\"\n");
        }
    }
    else
    {
        localcmd3("fraglimit \"", temp, " : ClanRing ");
        if (clanring_playmode & CLANRING_PRACTICE_MODE)
            localcmd("Practice\"\n");
        else
            localcmd("Classic\"\n");
    }
};

void () clanring_set_warp_aliases =
{
    entity temp;
    float index;

    temp = self;
    self = self.owner;

    //send map warp aliases
    for (index = 1 ; index < (WARP_CATEGORY_SIZE * WARP_MAPLIST_SIZE) ; index += 1)
    {
        if (warpmap[index].name != "")
        {
            stuffcmd(self, sprintf("alias %s cmd %s\n", warpmap[index].name, warpmap[index].name));
        }
    }

    self = temp;
    self.nextthink = time + 0.3;
    self.think = votables_send_aliases;
};

//
//  S E T  A L I A S E S
//
//  This is scheduled using a temporary entity; the client
//  is stored in self.owner.
//
void () clanring_set_aliases =
{
    local entity temp;

    temp = self;
    self = self.owner;

    // Check for binds
    if (self.style & CLANRING_FOUND_BINDINGS)
    {
        self = temp;
        remove(self);
        return;
    }

    //sprint3(self, "Sending ", clanring_version, " bindings\n");

    // Cheat fixes
    stuffcmd(self, "alias r_ambient echo r_ambient has been disabled on this server.\n");

    // Set aliases
    stuffcmd(self, "alias dbbinds impulse 58\n");   // load undocumented debug aliases
    stuffcmd(self, "alias help-server impulse 100\n");
    stuffcmd(self, "alias helpserver impulse 100\n");
    stuffcmd(self, "alias help-observer impulse 101\n");
    stuffcmd(self, "alias rules impulse 103\n");

    stuffcmd(self, "alias teamplay impulse 103\n");
    stuffcmd(self, "alias deathmatch impulse 103\n");
    stuffcmd(self, "alias timelimit impulse 103\n");
    stuffcmd(self, "alias fraglimit impulse 103\n");
    stuffcmd(self, "alias noexit impulse 103\n");

    stuffcmd(self, "alias help-misc impulse 105\n");
    stuffcmd(self, "alias commands impulse 106\n");
    stuffcmd(self, "alias levels impulse 102\n");
    stuffcmd(self, "alias warp impulse 107\n");
    stuffcmd(self, "alias admin impulse 108\n");
    stuffcmd(self, "alias motd impulse 109\n");
    stuffcmd(self, "alias admins impulse 110\n");
    stuffcmd(self, "alias autoweapon impulse 114\n");
    stuffcmd(self, "alias aw impulse 114\n");
    stuffcmd(self, "alias yes impulse 115\n");
    stuffcmd(self, "alias no impulse 116\n");
    stuffcmd(self, "alias vinfo impulse 117\n");
    stuffcmd(self, "alias ticrate impulse 118\n");
    stuffcmd(self, "alias shownick cmd shownick\n");
    stuffcmd(self, "alias ready impulse 120\n");
    stuffcmd(self, "alias notready impulse 121\n");
    stuffcmd(self, "alias unlock impulse 122\n");
    stuffcmd(self, "alias ready? impulse 123\n");
    stuffcmd(self, "alias timerstop impulse 124\n");
    stuffcmd(self, "alias timerstart impulse 125\n");
    stuffcmd(self, "alias ghostcode echo You do not have a ghost\n");
    stuffcmd(self, "alias ghostlist impulse 126\n");
    stuffcmd(self, "alias ghost impulse 127\n");
    stuffcmd(self, "alias score impulse 128\n");
    stuffcmd(self, "alias help-match impulse 129\n");
    stuffcmd(self, "alias lock impulse 130\n");
    stuffcmd(self, "alias rockets impulse 133\n");
    stuffcmd(self, "alias observer impulse 140\n");
    stuffcmd(self, "alias walk impulse 141\n");
    stuffcmd(self, "alias flyme impulse 142\n");
    stuffcmd(self, "alias chase impulse 143\n");
    stuffcmd(self, "alias chasecam impulse 143\n");
    stuffcmd(self, "alias help-walk impulse 144\n");
    stuffcmd(self, "alias help-fly impulse 145\n");
    stuffcmd(self, "alias help-chase impulse 146\n");
    stuffcmd(self, "alias commentary impulse 147\n");
    stuffcmd(self, "alias headsup impulse 148\n");
    stuffcmd(self, "alias eyecam cmd eyecam\n");
    stuffcmd(self, "alias tourney impulse 151\n");      // CRMOD - enables tournament mode chasecam
    stuffcmd(self, "alias camera impulse 153\n");       // CRMOD - sets camera mode
    stuffcmd(self, "alias autocam impulse 154\n");      // CRMOD - autocam
    stuffcmd(self, "alias autocamera impulse 154\n");   // CRMOD - autocam
    stuffcmd(self, "alias quaketv impulse 154\n");      // CRMOD - autocam
    stuffcmd(self, "alias autochase impulse 155\n");
    stuffcmd(self, "alias help-camera impulse 156\n");
    stuffcmd(self, "alias autopov impulse 157\n");
    stuffcmd(self, "alias pentstats impulse 169\n");
    stuffcmd(self, "alias killstats impulse 170\n");
    stuffcmd(self, "alias efficiency impulse 171\n");
    stuffcmd(self, "alias eff impulse 171\n");          // CRMOD - so people don't have to spell out efficiency
    stuffcmd(self, "alias stats impulse 172\n");
    stuffcmd(self, "alias quadstats impulse 173\n");    // CRMOD - new impulse
    stuffcmd(self, "alias badstats impulse 174\n");
    stuffcmd(self, "alias teamstats impulse 175\n");
    stuffcmd(self, "alias flagstats impulse 176\n");
    stuffcmd(self, "alias autostats impulse 178\n");
    stuffcmd(self, "alias red \";color 4;w5;ready;\"\n");
    stuffcmd(self, "alias blue \";color 13;w5;ready;\"\n");
    stuffcmd(self, "alias help-stats impulse 179\n");
//	stuffcmd(self, "alias sm1 \"echo Smoothing ON ; cl_nolerp 1 ; alias smooth sm0\"\n");
//	stuffcmd(self, "alias sm0 \"echo Smoothing OFF ; cl_nolerp 0 ; alias smooth sm1\"\n");
//	stuffcmd(self, "alias smooth sm1\n");
    stuffcmd(self, "alias init echo\n");                // CRMOD - So clients only see 'init' once
    stuffcmd(self, "alias +hook impulse 98\n");
    stuffcmd(self, "alias -hook impulse 97\n");
    stuffcmd(self, "alias hook impulse 22\n");
    stuffcmd(self, "alias dropammo impulse 20\n");
    stuffcmd(self, "alias rune-use impulse 20\n");
    stuffcmd(self, "alias dropweapon impulse 21\n");
    stuffcmd(self, "alias flagstatus impulse 23\n");
    stuffcmd(self, "alias droprune impulse 19\n");
    stuffcmd(self, "alias nextmap impulse 199\n");
    stuffcmd(self, "alias faststart impulse 209\n");
    stuffcmd(self, "alias afk impulse 57\n");
    stuffcmd(self, "alias afkon cmd afkon\n");
    stuffcmd(self, "alias afkoff cmd afkoff\n");
    stuffcmd(self, "alias captimes impulse 58\n");
    stuffcmd(self, "alias highscores impulse 58\n");
    stuffcmd(self, "alias modes impulse 181\n");
    stuffcmd(self, "alias gameplay impulse 182\n");
    stuffcmd(self, "alias watch impulse 183\n");
    stuffcmd(self, "alias stat impulse 184\n");
    stuffcmd(self, "alias misc impulse 185\n");
    stuffcmd(self, "alias modhelp impulse 186\n");
    stuffcmd(self, "alias shortcuts impulse 187\n");
    stuffcmd(self, "alias itemstats cmd itemstats\n");
    stuffcmd(self, "alias dstats cmd dstats\n");
    stuffcmd(self, "alias wtstats cmd wtstats\n");
    stuffcmd(self, "alias itstats cmd itstats\n");
    stuffcmd(self, "alias altents cmd altents\n");
    
    self.style = self.style | CLANRING_FOUND_BINDINGS;

    // remove the temporary entity
    self = temp;
    self.nextthink = time + 0.02;
    self.think = clanring_set_warp_aliases;
};

//
//  P R E  S E T  A L I A S E S
//
void () clanring_pre_set_aliases =
{
    //sprint(self.owner, "\bUse \b-zone 512 \bif quake crashes\n");
    sprint(self.owner, "Type \bCOMMANDS\b for help\n");

    if (self.owner.style & CLANRING_OBSERVER)
    {
        if (clanring_playmode & CLANRING_PRACTICE_MODE)
            sprint(self.owner, "Type \bREADY\b to join\n");
        else if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)			//R00k
            sprint(self.owner, "Type \bRED\b or \bBLUE\b to join\n");
    }
    sprint(self.owner, sprintf("NextMap is %s.\n", nextmap));
    self.think = clanring_set_aliases;
    self.nextthink = time + 1;
};

//
//  S E N D  I G N O R E  T H I S
//
void () clanring_send_ignore_this =
{
    // also test for ghost during autopause
    local entity ghostent;
    local float temp;

    stuffcmd(self.owner, "crx_ignorethis\n");	// test for binds
    temp = 0;
    if (clanring_state & CLANRING_MATCH_PAUSED)
    {
        ghostent = find(world, classname, "clanring_ghost");
        while (ghostent)
        {
            if (ghostent.owner.owner != ghostent)
                temp = 1;
            ghostent = find(ghostent, classname, "clanring_ghost");
        }
    }
    if (temp)
        stuffcmd(self.owner, "ghost\n");

    self.think = clanring_pre_set_aliases;
    self.nextthink = time + 0.1;
};

//
//  I N I T  T H I N K
//
//  Called 0.5 seconds after a client connects.  Plays the wizard sound
//  and checks for an illegal name.
//
void () clanring_init_think =
{
    local entity temp;

    temp = self;
    self = self.owner;

    if (!(clanring_playmode & CLANRING_MATCH_MODE) || !(clanring_state & CLANRING_MATCH_STARTED))
        sound (world, CHAN_AUTO, "wizard/wsight.wav", 1, ATTN_NONE);

    if (utils_illegal_name (self.netname))
        stuffcmd(self, "name \bnew\bplayer\n");

    self.oldname = strzone(self.netname);

    self = temp;
    remove(self);
};

//
//  S H O W  M O D E
//
//  Show mode and help info to a player after they connect.
//
void () clanring_show_mode =
{
    sprint2(self.owner, clanring_version, "\n");
    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
            sprint(self.owner, "ctf match mode\n");
        else
            sprint(self.owner, "tdm match mode\n");
    }
    else
    {
        if (clanring_playmode & CLANRING_WIPEOUT_MODE)
            sprint(self.owner, "clan arena wipeout mode\n");
        else if (clanring_playmode & CLANRING_CA_MODE)
            sprint(self.owner, "clan arena mode\n");
        else if (clanring_playmode & CLANRING_DMM4_MODE)
            sprint(self.owner, "dmm4 duel mode\n");
        else if (clanring_playmode & CLANRING_AIRSHOT_MODE)
            sprint(self.owner, "airshot mode\n");
        else if (clanring_playmode & CLANRING_RA_MODE)
            sprint(self.owner, "rocket arena mode\n");
        else if (clanring_playmode & CLANRING_PRACTICE_MODE)
            sprint(self.owner, "practice mode\n");
        else if (clanring_playmode & CLANRING_NORMAL_MODE)
        {
            if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
                sprint(self.owner, "pickup ctf mode\n");
            else
            {
                if (teamplay)
                    sprint(self.owner, "pickup tdm mode\n");
                else
                    sprint(self.owner, "normal ffa deathmatch mode\n");
            }
        }
    }
    remove(self);
};

//
//  S E N D  D E T E C T
//
//  Figure out if they're using DOSQuake, WINQuake or GLQuake.  Also send
//  a little gift for screenshots.
//
void () clanring_send_detect =
{
    local entity temp;

    temp = self;
    self = self.owner;
    self.style = self.style | CLANRING_WINQUAKE | CLANRING_GLQUAKE;
    // prevent screen shots in demo by aliasing coop to screenshot
    stuffcmd(self, "alias coop screenshot\n");
    stuffcmd(self, "alias detect impulse 62\n");
    stuffcmd(self, "alias gl_texturemode alias detect impulse 60\n");
    stuffcmd(self, "gl_texturemode\n");
    stuffcmd(self, "detect\n");
    self = temp;
    remove(self);
};

//
//  C H E C K  P L A Y E R  I N  L I S T
//
float () clanring_check_player_in_list =
{
    local entity e;
    local float check;

    e = clanring_sentinel;

    check = 16;//crash test (fixme: change from 16 to SV_MAXPLAYERS)

    while ((e != world) && (e.next_player))
    {
        if (check < 1)
            return FALSE;

        if (e.next_player == self)
            return TRUE;

        check = check - 1;
        e = e.next_player;
    }
    return FALSE;
};

//
//  P U T  P L A Y E R  I N  L I S T
//
//This is for stats in Classic Mode.
void () clanring_put_player_in_list =
{
    if (clanring_check_player_in_list() == FALSE)// just in case
    {
        self.next_player = clanring_sentinel.next_player;
        clanring_sentinel.next_player = self;
    }
};

//
//  R E M O V E  P L A Y E R  F R O M  L I S T
//
void () clanring_remove_player_from_list =
{
    local entity e;
    local float check;

    e = clanring_sentinel;

    check = 16;//lagouts can cause runaway loop errors

    while ((e != world) && (e.next_player != world))
    {
        if (check < 1)
            return;

        if (e.next_player == self)
        {
            e.next_player = self.next_player;
            self.next_player = world;
            return;
        }
        check = check - 1;
        e = e.next_player;
    }
};


//
// B A N  K I C K  C L I E N T
//
// Used to kick connecting clients with an ip address which is on the banlist (ban.cfg).
//
void () ban_kick_client =
{
    local string temp;
    local entity e;

    if (banent != world)
    {
        e = self;

        self = banent;

        localcmd("ban ");
        localcmd(self.trueip);
        localcmd(" 255.255.255.255\n");
        temp = ftos(self.colormap);
        localcmd3("kick # ", temp, "\n");

        if (self.style & CLANRING_CONNECTED)
            ClientDisconnect ();

        self = e;
        remove(self);
        banent = world;
    }
};

//R00k: this finds teams active, and updates the scoreboard for new connecting clients
void () find_pqc_teamscore_teams =
{
    local entity e;

    if (mode_is_arena())
    {
        e = boss.next_team;

        while (e)
        {
            pqc_new_team (e.team2);
            pqc_team_frags(e.team2, e.wins);
            e = e.next_team;
        }
    }
    else
    {
        e = clanring_sentinel.next_team;

        while (e)
        {
            pqc_new_team (e.height);
            pqc_team_frags(e.height, e.frags);
            e = e.next_team;
        }
    }
};

//Identify/advertise the player's client in use.
string() server_find_myClient =
{    
    local string text = "";
    string myClient;

    myClient = string_null;

    myClient = infokey(self,"*ver");						//FTE and QSS

    if (myClient != "")
    {
        if (substring(myClient, 0, 5) == "QSS-M")
            self.client = "QSS-M";

        if (substring(myClient, 0, 3) == "FTE")
            self.client = "FTE";
        text = (sprintf(" with %s.\n", myClient));
    }
    else
    {
        myClient = infokey(self,"*client");					//ezQuake
        if (myClient != "")
        {
            self.client = "ezQuake";
            text = (sprintf(" with %s.\n", myClient));
        }
        else
        {
            text = ".\n";									//anything else
            self.client = "Quake";
        }
    }
    return text;
 }

//
// R E S E N D  T E A M S
//
// send updates to new clients of players' team-colors
//
void () clanring_resend_teams =
{
	entity 	pteam, player;

	pteam = boss.next_team;
	player = pteam.chain_gang;

	while (pteam != world)
	{
		while (player != world)
		{
            setcolour(player, player.team2, player.team2);
			player = player.chain_gang;
	    }            
        pteam = pteam.next_team;
        player = pteam.chain_gang;
	}	
};

//
//  C L I E N T  C O N N E C T
//
//  Called from ClientConnect in Client.qc when a client enters the
//  server.  This occurs when the client first connects over the network
//  and every time a new level is started.
//
void () clanring_client_connect =
{
    local string text = "";
        
    if (parm10 & CLANRING_NEW_CLIENT)
    {
        // This is a new client (just connected over the network)
        // Show the MOTD
        motd_create();

        utils_make_scheduled_event(clanring_init_think, 0.5);
        // Get rid of the new client flag
        parm10	= parm10 - (parm10 & CLANRING_NEW_CLIENT);
        
        parm10 |= CLANRING_CONNECTED;

        // Set default observer flags
        parm12 = OBSERVER_DEMO | OBSERVER_COMMENTARY;   // Default eyes, fallback to flymode

        parm13 = 0;

        stats_reset_player();
        if (mode_is_arena())
            clanring_resend_teams();

        if (
            ((clanring_playmode & CLANRING_MATCH_MODE) && (clanring_state & CLANRING_MATCH_STARTED)) 
            || 
            ((mode_is_arena()) && (boss.state == CA_MATCH_PLAYING))
           )
            utils_make_scheduled_event(find_pqc_teamscore_teams, 1.25);//R00k

        self.afk_time = time + 20;

        text = server_find_myClient();  //This also sets self.client
        bprint (self.netname," has connected", text);
    }
    else self.afk_time = time;

    // send aliases if necessary
    utils_make_scheduled_event(clanring_send_ignore_this, 1);

    //utils_make_scheduled_event(clanring_send_detect, 0.8);

	if (!(clanring_playmode & CLANRING_MATCH_MODE) && (mode_is_arena() == FALSE))
	{
		clanring_put_player_in_list();
	}

    utils_make_scheduled_event(clanring_show_mode, 0.5);
    self.cnt = CLANRING_MAX_SUICIDES;  // numer of suicides allowed
    self.clanring_hack_count = -1;  // count of admin code attempts
//	self.finaldest_y = MOVETYPE_WALK;
    self.killed = 0;
    self.owner = world;      // no ghost
    self.trigger_field = world; // last spawn point
    self.use = SUB_Null;//used for voting/warp
    self.style = 0;
    self.delayed_impulse = 0;
    self.clanring_cam_delay = 0;
    self.clanring_did_damage = time - 15;
    self.attack_finished = time - 10;
    self.style = self.style | CLANRING_GLQUAKE;//R00k: forced.
    // This is to prevent a condition where one player is another player's
    // movetarget, which can confuse the auto module.
    self.movetarget = world;
    self.name_ready = string_null;
    self.wait = time + 1;
    self.hack_timeout = 0;//Timer for bot scan
    self.join_time = time;

    parm10 = parm10 - (parm10 & (CLANRING_READY | CLANRING_KICK_CONFIRM | CLANRING_MOTD | CLANRING_SETTING_OPTIONS | CLANRING_SCOREBOARD | CLANRING_CONFIRM_LEAVE));

    if (mode_is_arena())
    {
        self.style 			= self.style | CLANRING_MOTD;//show new motd for changed gametypes.
        self.team2	     	= TEAM_SPECTATOR;
        self.next_team	    = world;
        self.frags          = 0;
        self.trigger_field  = world;
        self.skin	     	= 0;
        self.ca_player_flag	= PF_WAITING;
    }
};

void(entity player, float cast) Request_Poll_Vote;
//
//  C L I E N T  D I S C O N N E C T
//
//  Called from ClientDisconnect in Client.qc when a client leaves.
//            
void () clanring_client_disconnect =
{
    self.style = self.style - (self.style & (CLANRING_CONNECTED | CLANRING_BLUE_TEAM | CLANRING_RED_TEAM | CLANRING_AFK_CLIENT));

    self.plag                  	= 0;
    self.cnt                   	= 0;
    self.lagcount              	= 0;
    self.lagcheck              	= -30;
    self.finaldest_x 			= -30;
    self.items 					= self.items - (self.items & (IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD | IT_SUPERHEALTH));
    self.invisible_finished 	= 0;	// don't die as eyes
    self.invincible_finished 	= 0;
    self.super_damage_finished 	= 0;
    self.radsuit_finished 		= 0;
    self.effects 				= 0;
    self.killed 				= 0;
    self.clanring_chase_score 	= CLANRING_NEGINF;// CRMOD make sure they don't have some high rating that can't be beat by the other players
    strunzone(self.oldname);
    self.oldname 				= string_null;
    self.statstate				= 0;
    
    if (clanring_request != world)
    {
        if (self.vote)
        {
            self.vote = 0;
            Request_Poll_Vote(self, 1);//Check for a 'yes' majority
        }
    }

    // If we're in match mode, then inform match and score modules
    // Must inform score module first!  Score module checks to see if the
    // player is the first person on the team.
    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        match_disconnect_notify(self);
    }
    else if (mode_is_arena())
    {
        arena_client_disconnect();
    }
    else
        clanring_remove_player_from_list();

    self.oflags = self.oflags - (self.oflags & OBSERVER_QUAKETV);	//R00k

    // Check to see if anyone was observing this client
    // Don't do this until the player has been removed from the list!
    observer_disconnect_notify(self);

    // Let the admin module know in case there's a kick in progress
    admin_disconnect_notify(self);

    // Check to see if we were debugging this client
    if (clanring_debug_client == self)
        clanring_debug_client = world;
};

//
//  B F  T H I N K
//
//  Creates a background flash - used for player spawns.
//
void () clanring_bf_think =
{
    stuffcmd(self.owner, "bf\n");
    remove(self);
};

//
//  O B S E R V E R  S T A R T  T H I N K
//
//  This is a hack.. observer_start is being called a second time, 0.6
//  seconds after the first time, to cover a few details that don't make
//  it when the client first connects (such as the observer colour).
//
void () clanring_observer_start_think =
{
    local entity oself;

    oself = self;
    self = self.owner;
    if ((self.style & CLANRING_OBSERVER) || ((clanring_playmode & CLANRING_MATCH_MODE) && !(self.style & CLANRING_READY)))
    observer_start();
    self = oself;
    remove(self);
};

void () send_pause_match_timer =
{
    if (clanring_match_timer != world && (clanring_state & CLANRING_MATCH_PAUSED))
    {
        pqc_match_time(clanring_match_timer.lip, clanring_match_timer.count);
    }
    remove(self);
};

void () teamplay_force_player_ready;
//
//  P U T  C L I E N T  I N  S E R V E R
//
//  Called from PutClientInServer in Client.qc
//
void () clanring_put_client_in_server =
{
    self.movetype    = MOVETYPE_WALK;
    self.finaldest_y = MOVETYPE_WALK;
    self.style       = self.style | CLANRING_CONNECTED;//placed here before assigning to a team

    //utils_make_scheduled_event(clanring_bf_think, 0.1);

    utils_make_scheduled_event(send_pause_match_timer, 0.5);

    if (!(self.client))         // woods -- map change
        server_find_myClient();

    if (mode_is_arena())
    {
        if (((self.ca_player_flag == PF_WAITING) || (self.ca_player_flag == PF_DEAD)) || (boss.state == CA_MATCH_WAITING))
        {
            observer_start();
            return;
        }
        if ((clanring_playmode & CLANRING_RA_MODE) && (self.ca_player_flag != PF_READY) && (self.ca_player_flag != PF_PLAYING))
        {
            observer_start();
            return;
        }
    }

    if ((self.style & CLANRING_OBSERVER) || (self.oflags & OBSERVER_QUAKETV) || ((clanring_playmode & CLANRING_MATCH_MODE) && !(self.style & CLANRING_READY)))
    {
        observer_start ();
        utils_make_scheduled_event(clanring_observer_start_think, 0.6);
    }
    else
    {
        //in classic mode auto join on connect
        //This is called in client.qc but here again JUST to make sure.
        if (teamplay)
        {
            if (clanring_playmode & CLANRING_NORMAL_MODE)
            {
                if  ((!(self.style & CLANRING_BLUE_TEAM)) && (!(self.style & CLANRING_RED_TEAM)))
                {
                    utils_make_scheduled_event(teamplay_force_player_ready, 0.1);
                    return;//this is ok because "clanring_put_client_in_server" gets called again after they are forced on a team.
                }
            }
        }

        if (clanring_playmode & CLANRING_MATCH_MODE)
        {
            if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
            {
                if (self.team == RED)  self.skin = 1;
                if (self.team == BLUE) self.skin = 3;
            }
        }

        if (mode_is_arena())
        {
            self.cc_queue	= 0;//R00k - test
            self.cc_queue_vote	= 0;//R00k - test
            self.ca_player_flag = PF_PLAYING;
            self.respawntime = 0;

            if (clanring_timelimit & CLANRING_RA_MODE)
            {
                makevectors (self.v_angle);
                self.velocity = v_forward * 350;
            }
        }

        UnHookPlayer();
        if (!((clanring_playmode & CLANRING_PRACTICE_MODE) || ((clanring_playmode & CLANRING_NORMAL_MODE) && !teamplay)))
        {
            string temp = ftos(self.height);
            stuffcmd(self, "color ");
            stuffcmd(self, temp);
            stuffcmd(self, "\n");
            temp = "";
        }
        player_stand1();
        spawn_tdeath(self.origin, self);
        makevectors(self.angles);
        spawn_tfog(self.origin);// + (v_forward * 20)));

        if (clanring_state & CLANRING_MATCH_PAUSED)
            self.nextthink = self.nextthink + 1000000 - (time - clanring_match_pause_time);
    }
    // Prevent fire-on-respawn (in case player used attack button to respawn)
    self.style = self.style - (self.style & CLANRING_OK_TO_SHOOT);

    self.height = self.team - 1; // to prevent colour change announcements
    self.button0 = 0;
    self.wait = time + 2;    // for periodic checks
    self.finaldest_x = time; // used to check for disconnected clients
    self.lip = 0;            // grenade spam count
};

//
//  H E L P
//
//  Show general help commands.
//
void () clanring_help =
{
    sprint2(self, clanring_version, "\n");
    sprint(self, "Help commands (type in console):\n");
    sprint(self, " vinfo         - server version info\n");
    sprint(self, " help-misc     - misc commands\n");
    sprint(self, " help-observer - observer commands\n");
    sprint(self, " help-match    - match mode help\n");
    sprint(self, " help-stats    - statistics help\n");
    if (self.style & CLANRING_ADMINISTRATOR)
        sprint(self, " help-admin    - admin commands\n");
    sprint(self, " commands - list commands/impulses\n");
};

//
//  H E L P  C H A N G E
//
//  Show help on how to change levels.
//
void () clanring_help_change =
{
    sprint(self, "\n");
    sprint(self, " type \bwarp\b to change maps\n");
    sprint(self, "\n");
    //sprint(self, "Ôï ãèáîçå ìåöåìó¬ åîôåò ôèå îáíå ïæ\n");
    //sprint(self, "ôèå ìåöåì éî ôèå ãïîóïìå®\n");
};

//
//  H E L P  M I S C
//
//  Show misc commands.
//
void () clanring_help_misc =
{
    sprint(self, " admin      - enter admin code\n");
    sprint(self, " admins     - list server admins\n");
    sprint(self, " setquad    - enable/disable quad\n");
    sprint(self, " setpent    - enable/disable pent\n");
    sprint(self, " setring    - enable/disable ring\n");
    sprint(self, " setrunes   - enable/disable runes\n");
    sprint(self, " sethook    - enable/disable grappling hook\n");

    if (clanring_playmode & CLANRING_MODE_VOTE)
    {
        sprint(self, " normal     - request FFA play\n");
        sprint(self, " practice   - request practice mode\n");
        sprint(self, " match      - request match mode\n");
    }

    sprint(self, " nogibs     - disable gibs\n");
    sprint(self, " lowgibs    - set gibs to 'low'\n");
    sprint(self, " highgibs   - set gibs to 'high'\n");
    sprint(self, " motd       - show message of the day\n");
    sprint(self, " commands   - list commands/impulses\n");
    sprint(self, " observer   - toggle observer mode\n");
    sprint(self, " warp       - choose a map for vote to load\n");
    sprint(self, " rules      - view server rules\n");
    sprint(self, " ticrate    - view sys_ticrate\n");
    sprint(self, " shownick   - teammate identifier\n");
    sprint(self, " autoweapon - toggle smartweapon\n");
    sprint(self, " autopause  - toggle auto pausing\n");
};

//
//  I N F O
//
void () clanring_info =
{
    sprint(self, "\n");
};

//
//  C O M M A N D S
//
//  List all commands and impulses.
//
void () clanring_commands =
{
    // regular user commands
    sprint(self, "\n");
    sprint(self, " \byes [\by\b]\b    vote yes\n");
    sprint(self, " \bno [\bn\b]\b     vote no\n");
    sprint(self, " \bwarp\b       initiate vote to change level\n");
    sprint(self, " \bmodes\b      mode switch commands\n");
    sprint(self, " \bgameplay\b   match/game variable commands\n");
    sprint(self, " \bwatch\b      observer commands\n");
    sprint(self, " \bstats\b      match statistics\n");
    sprint(self, " \bshortcuts\b  command shortcuts\n");
    sprint(self, " \bmisc\b       miscellaneous commands\n");
    sprint(self, " \bmodhelp\b    detailed commands usage\n");
    sprint(self, " \badmin\b      enter admin code\n");
    sprint(self, "\n");


    // admin commands
    if (self.style & CLANRING_ADMINISTRATOR)
    {
        sprint(self, " admin commands\n");
        sprint(self, "\n");
        sprint(self, " \babortmatch\b   \bkick!\b\n");
        sprint(self, " \bautoss\b       \bmodvote\b\n");
        sprint(self, " \bban!\b         \bmakespawn\b\n");
        sprint(self, " \bdmset\b        \bmaxteams\b\n");
        sprint(self, " \bfaststart\b    \bnextspawn\b\n");
        sprint(self, " \bghostlist\b    \bnextcam\b\n");
        sprint(self, " \bhelp-admin\b   \boptions\b\n");
        sprint(self, " \bips\b          \bsafepractice\b\n");
        sprint(self, "\n");
    }
    //clanring_help_change ();
};

//  C O M M A N D S SUB MENUS
//
//  List all commands and impulses.

void () modes_commands =
{
        sprint(self, "\n");
        sprint(self, " \bairshot\b\n");
        sprint(self, " \bca\b\n");
        sprint(self, " \bctf\b\n");
        sprint(self, " \bdm\b\n");
        sprint(self, " \bdmm4\b\n");
        sprint(self, " \bmatch\b\n");
        sprint(self, " \bnormal\b\n");
        sprint(self, " \bpractice\b\n");
        sprint(self, " \bra\b\n");
        sprint(self, " \bwipeout\b\n");
        sprint(self, "\n");
};

void () gameplay_commands =
{
        sprint(self, "\n");
        sprint(self, " \bdroprune [\bdr\b]\b   \bsetquad\b\n");
        sprint(self, " \bflagstatus\b      \bsetring\b\n");
        sprint(self, " \bghost\b           \btimerstart [\bst\b]\b\n");
        sprint(self, " \bghostcode\b       \btimerstop [\bpa\b]\b\n");
        sprint(self, " \block\b            \btimeset\b\n");
        sprint(self, " \botset\b           \btimeset10 [\bt10\b]\b\n");
        sprint(self, " \bready [\br\b]\b       \btimeset20 [\bt20\b]\b\n");
        sprint(self, " \bready? [\b?\b]\b      \bunlock\b\n");
        sprint(self, " \bsethook\b         \bweaponstay\b\n");
        sprint(self, " \bsetpent\b\n");
        sprint(self, "\n");
};

void () watch_commands =
{
        sprint(self, "\n");
        sprint(self, " \bautocam\b\n");
        sprint(self, " \bautochase\b\n");
        sprint(self, " \bchase\b\n");
        sprint(self, " \bautopov\b\n");
        sprint(self, " \beyecam [e]\b\n");
        sprint(self, " \bflyme\b\n");
        sprint(self, "\n");
};

void () stat_commands =
{
        sprint(self, "\n");
        sprint(self, " \bbadstats\b\n");
        sprint(self, " \befficiency\b\n");
        sprint(self, " \bflagstats\b\n");
        sprint(self, " \bkillstats\b\n");
        sprint(self, " \bquadstats\b\n");
        sprint(self, " \bstats\b\n");
        sprint(self, " \bteamstats\b\n");
        sprint(self, "\n");
};

void () misc_commands =
{
        sprint(self, "\n");
        sprint(self, " \bcaptimes\b\n");
        sprint(self, " \bdropammo\b\n");
        sprint(self, " \bdropweapon\b\n");
        sprint(self, " \bhighscores\b\n");
        sprint(self, " \bmotd\b\n");
        sprint(self, " \brules\b\n");
        sprint(self, "\n");
};

void () modhelp_commands =
{
        sprint(self, "\n");
        sprint(self, " \bhelp-camera\b\n");
        sprint(self, " \bhelp-chase\b\n");
        sprint(self, " \bhelp-fly\b\n");
        sprint(self, " \bhelp-match\b\n");
        sprint(self, " \bhelp-misc\b\n");
        sprint(self, " \bhelp-observer\b\n");
        sprint(self, " \bhelp-server\b\n");
        sprint(self, " \bhelp-stats\b\n");
        sprint(self, " \bhelp-walk\b\n");
        sprint(self, " \bvinfo\b\n");
        sprint(self, "\n");
};

void () shortcuts_commands =
{
        sprint(self, "\n");
        sprint(self, " \bmapx\b  warp to    \brd\b   red\n");
        sprint(self, " \b?\b     ready?     \bt10\b  timeset10\n");
        sprint(self, " \bbl\b    blue       \bt20\b  timeset20\n");
        sprint(self, " \be\b     eyecam     \bst\b   timerstart\n");
        sprint(self, " \bn\b     no         \bpa\b   timerstop\n");
        sprint(self, " \bnr\b    notready   \byl\b   yellow\n");
        sprint(self, " \br\b     ready      \by\b    yes\n");
        sprint(self, "\n");
};

//
//  L E V E L S
//
//  List all levels recognized by the server.
//
void () clanring_levels =
{
    sprint(self, "type \bwarp\b to change maps\n");
};

//
//  P I N G  R E P L Y
//
//  Called when a client responds to a manual ping via impulse 38 (was 103).
//
void () clanring_ping_reply =
{

    cprint3("reply from \"", self.netname, "\"\n");
    self.lagcheck = time;
};

//
//  B A D  I M P U L S E
//
//  Seems like some people get stuck with the old clanring bindings.
//  Let them know that something ain't right.
//
void () clanring_bad_impulse =
{
    sprint(self, "You have entered an invalid impulse.\n");
    sprint(self, "Your bindings may be incorrect - try\n");
    sprint(self, "reconnecting to the server.\n");//TODO force an update of the server aliases..
};

//
//  V E R S I O N  I N F O
//
void () clanring_vinfo =
{
    sprint3(self, "\n", clanring_version, "\n\n");
    if (self.csqc_enabled)
        sprint(self, "CSQC Enabled\n");
    else
        sprint(self, "CSQC \bDisabled\n");
    sprint(self, "\noriginal works by \nJ.P. Grossman, Paul Baker and Dave 'Zoid' Kirsch\n");
};

//
//  T I C R A T E
//
void () clanring_ticrate =
{
    local float ticrate;

    ticrate = cvar("sys_ticrate");
    sprint(self, "sys_ticrate = ");
    utils_print_floatn(ticrate, 3);
};

//
//  S H O W  R U L E S
//
void () clanring_show_rules =
{
    local float temp;

    if (clanring_playmode & CLANRING_DMM4_MODE)
        sprint(self, "Ž 1v1 duel  mode Ž\n");
    else if (clanring_playmode & CLANRING_AIRSHOT_MODE)
        sprint(self, "Ž  airshot mode  Ž\n");
    else if (clanring_playmode & CLANRING_WIPEOUT_MODE)
        sprint(self, "Ž wipeout modeŽ\n");
    else if (clanring_playmode & CLANRING_CA_MODE)
        sprint(self, "Žclan arena  modeŽ\n");
    else if (clanring_playmode & CLANRING_RA_MODE)
        sprint(self, "Žrocket arena modeŽ\n");
    else if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
            sprint(self, "ŽCRCTF match modeŽ\n");
        else
            sprint(self, "ŽCRMod match modeŽ\n");
    }
    else if (clanring_playmode & CLANRING_PRACTICE_MODE)
    {
        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
            sprint(self, "Žctf practice modeŽ\n");
        else
            sprint(self, "Žpractice modeŽ\n");
    }
    else
    {
        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
            sprint(self, "ŽPublic CTF modeŽ\n");
        else
        {
            if (teamplay)
                sprint(self, "ŽPublic Team DeathMatch modeŽ\n");
            else
                sprint(self, "ŽFFA DeathMatch modeŽ\n");
        }
    }
    temp = cvar("deathmatch");
    sprint(self, "deathmatch®®®");
    utils_print_float(temp);
    temp = cvar("teamplay");
    sprint(self, "teamplay®®®®®");
    utils_print_float(temp);
    if (!(clanring_playmode & CLANRING_MATCH_MODE))
        temp = cvar("timelimit");
    else
        temp = clanring_timelimit;

    sprint(self, "timelimit®®®®");
    utils_print_float(temp);
    temp = cvar("fraglimit");
    sprint(self, "fraglimit®®®®");
    utils_print_float(temp);
    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        if (clanring_overtime > 0)
        {
            sprint(self, "overtime®®®®®");
            utils_print_float(clanring_overtime);
        }
        else
        {
            if (clanring_overtime == 0)
                sprint(self, "overtime®®®®®disabled\n");
            else
                sprint(self, "overtime®®®®®sudden death\n");
        }
    }
    else
    {
        temp = cvar("noexit");
        sprint(self, "noexit®®®®®®®");
        utils_print_float(temp);
    }

    sprint(self, "quad®®®®®®®®®");

    if (clanring_playmode & CLANRING_NO_QUAD)
        sprint(self, "\bOFF\n");
    else
        sprint(self, "on\n");

    sprint(self, "pent®®®®®®®®®");
    if (clanring_playmode & CLANRING_NO_PENT)
        sprint(self, "\bOFF\n");
    else
        sprint(self, "on\n");

    sprint(self, "ring®®®®®®®®®");
    if (clanring_playmode & CLANRING_NO_RING)
        sprint(self, "\bOFF\n");
    else
        sprint(self, "on\n");

    if (clanring_gameconfig & CLANRING_POWERUP_DROP)
        sprint(self, "powerupDrops®", "on\n");

    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
    {
        sprint(self, "runes®®®®®®®®");
        if (clanring_playmode & CLANRING_RUNES)
            sprint(self, "on\n");
        else
            sprint(self, "\bOFF\n");
    }
    //R00k: we *can* have the hook enabled in non-CTF modes too! :)
    sprint(self, "hook®®®®®®®®®");
    if (clanring_playmode & CLANRING_NO_HOOK)
        sprint(self, "\bOFF\n");
    else
        sprint(self, "on\n");

    if (clanring_playmode & CLANRING_NO_SPOOGE)
        sprint(self, "no spooge®®®®on\n");

    if (self.style & CLANRING_SMART_WEAPON)
        sprint(self, "autoweapon®®®on\n");

    if (!(clanring_playmode & CLANRING_MATCH_MODE))
        sprint(self, "next®map®®®®®",nextmap,"\n");

    sprint(self, "\n");
};

//
//  S H O W  R U L E S  P R E M A T C H
//
void () clanring_show_rules_prematch =
{
    local float temp, timervar;
    local string s0 = "", s1 = "", s2 = "", s3 = "", s4 = "", s5 = "", s6 = "", s7 = "", s8 = "", s9 = "", s10 = "", s11 = "", s12 = "";

    if (mode_is_arena())
    {
        if (boss.state != CA_MATCH_ROUNDSTART)
        {
            centerprint(self, "\n");
            return;
        }
        timervar = boss.count;
    }
    else
    {
        if (clanring_state & CLANRING_MATCH_STARTED || clanring_match_timer.count > 10 || clanring_match_timer.count < 1)
        {
            centerprint(self, "\n");
            return;
        }
        timervar = clanring_match_timer.count;
    }

    if (timervar > 9)
        s0 = sprintf("\bcountdown:   \b%s\n\n", strings_ftos_gold(timervar));
    else
        s0 = sprintf("\bcountdown:    \b%s\n\n", strings_ftos_gold(timervar));

    if (timervar > 3)
    {
        if (clanring_playmode & CLANRING_DMM4_MODE)
            s1 = "Ž  d u e l mode  Ž\n\n";
        else if (clanring_playmode & CLANRING_AIRSHOT_MODE)
            s1 = "Ž  airshot mode  Ž\n\n";
        else if (clanring_playmode & CLANRING_WIPEOUT_MODE)
            s1 = "Žclan arena wipeoutŽ\n\n";
        else if (clanring_playmode & CLANRING_CA_MODE)
            s1 = "Žclan arena  modeŽ\n\n";
        else if (clanring_playmode & CLANRING_RA_MODE)
            s1 = "Žrocket arena modeŽ\n\n";
        else if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
            s1 = "Žcrctf match modeŽ\n\n";
        else
            s1 = "Žcrmod match modeŽ\n\n";

        if (!(clanring_playmode & CLANRING_CA_MODE) && !(clanring_playmode & CLANRING_RA_MODE))
        {
            temp = clanring_timelimit;
        }
        else { temp = 0; }
        if (temp > 9)
            s2 = sprintf("%s%s\n", "\btimelimit    ", ftos(temp));
        else if (temp == 0)
            s2 = "\btimelimit   \boff\n";
        else
            s2 = sprintf("%s%s\n", "\btimelimit     ", ftos(temp));

        if (clanring_playmode & CLANRING_MATCH_MODE)
            temp = 0;
        else
            temp = cvar("fraglimit");
        if (temp > 99)
            s3 = sprintf("%s%s\n", "\bfraglimit   ", ftos(temp));
        else if (temp > 9)
            s3 = sprintf("%s%s\n", "\bfraglimit    ", ftos(temp));
        else if (temp == 0)
            s3 = "\bfraglimit   \boff\n";
        else
            s3 = sprintf("%s%s\n", "\bfraglimit     ", ftos(temp));

        temp = cvar("deathmatch");
        if (temp == 1)
            s4 = "\bweaponstay  \boff\n";
        else if (temp == 3)
            s4 = "\bweaponstay   \bon\n";
        else
            s4 = sprintf("%s%s\n", "\bdeathmatch    ", ftos(temp));

        temp = cvar("teamplay");
        s5 = sprintf("%s%s\n", "\bteamplay      ", ftos(temp));

        if ((clanring_playmode & CLANRING_DMM4_MODE) || (clanring_playmode & CLANRING_AIRSHOT_MODE))
        {
            if (clanring_timelimit)
                s6 = "\bovertime     \bsd\n";
            else
                s6 = "\bovertime    \boff\n";
        }
        else if (clanring_overtime > 0)
        {
            if (clanring_overtime > 9)
                s6 = sprintf("%s%s\n", "\bovertime     ", ftos(clanring_overtime));
            else
                s6 = sprintf("%s%s\n", "\bovertime      ", ftos(clanring_overtime));
        }
        else
        {
            if (clanring_overtime == 0)
                s6 = "\bovertime    \boff\n";
            else
                s6 = "\bovertime     \bsd\n";
        }

        if (clanring_playmode & CLANRING_NO_QUAD)
            s7 = "\bquad        \boff\n";
        else
            s7 = "\bquad         \bon\n";

        if (clanring_playmode & CLANRING_NO_PENT)
            s8 = "\bpent        \boff\n";
        else
            s8 = "\bpent         \bon\n";

        if (clanring_playmode & CLANRING_NO_RING)
            s9 = "\bring        \boff\n";
        else
            s9 = "\bring         \bon\n";

        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
        {
            if (clanring_playmode & CLANRING_RUNES)
                s10 = "\brunes        \bon\n";
            else
                s10 = "\brunes       \boff\n";

            if (clanring_playmode & CLANRING_NO_HOOK)
                s11 = "\bhook        \boff\n";
            else
                s11 = "\bhook         \bon\n";
        }
        else
        {
            s10 = "";
            s11 = "";
        }

        if (clanring_playmode & CLANRING_NO_SPOOGE)
            s12 = "\bno spooge    \bon\n";
        else
            s12 = "";
        local string cp1 = "", cp2 = "", cp3 = ""; //initialize locals so we dont have residual garbage next time used.
        cp1 = sprintf("%s%s%s", s2, s3, s4);
        cp2 = sprintf("%s%s%s", s6, s7, s8);
        cp3 = sprintf("%s%s%s%s", s9, s10, s11, s12);
        centerprint(self, s0, s1, cp1, cp2, cp3);
    }
    else if (timervar > 0)
    {
        centerprint(self, s0, "\n\n\n\n\n\n\n\n\n\n\n\n\n");
    }
};

//
//  A D M I N S
//
//  List the server admins and the codes they used
//
void () clanring_admins =
{
    local entity e;
    local string s;
    local float found;

    found = 0;
    e = find(world, classname, "player");
    while (e)
    {
        if ((e.style & CLANRING_CONNECTED) && (e.style & CLANRING_ADMINISTRATOR))
            found = 1;
        e = find(e, classname, "player");
    }
    if (!found)
    {
        sprint(self, "There are no administrators\n");
        return;
    }
    sprint(self, "\n Ãïäå ü      Îáíå\n");
    sprint(self, "­­­­­­«­­­­­­­­­­­­­­­­­\n");
    e = find(world, classname, "player");
    while (e)
    {
        if ((e.style & CLANRING_CONNECTED) && (e.style & CLANRING_ADMINISTRATOR))
        {
            s = ftos(e.clanring_hack_count);
            sprint5(self, "   ", s, "  ü ", e.netname, "\n");
        }
        e = find(e, classname, "player");
    }
};

//R00k: this is pretty useless anymore...
//
//  W I N G L  D E T E C T
//
void (float quakever) clanring_wingl_detect =
{
    if (!(self.style & CLANRING_WINQUAKE) || !(self.style & CLANRING_GLQUAKE))
    {
        clanring_bad_impulse ();
        return;
    }

    self.style = self.style - (self.style & (CLANRING_WINQUAKE | CLANRING_GLQUAKE));

    if (quakever == 1)
        self.style = self.style | CLANRING_WINQUAKE;
    else if (quakever == 2)
        self.style = self.style | CLANRING_GLQUAKE;
};
/*
//-----------------------------------------------------------------------------------
void () Practice_Object_Remove =
{
    local entity e;

    e = find (world, classname, "practice_object");

    if (e != world)
    {
        remove (e);
    }
};

//todo limit up to 15 objects and assign them to a team.
float () practice_check =
{
    local entity e;

    e = find (world, classname, "practice_object");

    if (e != world && self == e.movetarget)
    {
        bprint ("Practice object \bremoved\b\n");
        remove (e);
        return TRUE;
    }
    else if (e != world && self != e.movetarget)
    {
        sprint (self, "Practice object already \bactive\b\n");
        return TRUE;
    }

    return FALSE;
};

void () Practice_Think =
{
    //if (self.health < 1) { respawn();	self.nextthink = time + (sys_ticrate * 216); return; }

    local vector midorg;

    midorg = (self.origin - ((self.mins + self.maxs) * 0.5));

    if (pointcontents(midorg) == CONTENT_WATER)
    {
        self.velocity_z = 50;
        self.avelocity = '10 -10 -10';
    }
    self.nextthink = time + (sys_ticrate * 2);//every other frame
}

void () practice_spawn =
{
    local entity e;

    // If already active, remove it
    if (practice_check ())
        return;

    bprint ("Practice object \bspawned\n");
    sprint (self, "-->  use practice-object to \bremove\b\n");

    e 				= spawn();
    e.solid 		= SOLID_SLIDEBOX;
    e.movetype 		= MOVETYPE_TOSS;
    e.takedamage 	= DAMAGE_AIM;
    e.enemy			= self;
    e.movetarget	= self;
    e.classname 	= "practice_object";
    e.health		= 100;
    e.armortype 	= 0.8;
    e.armorvalue	= 200;
    e.flags        	= FL_CLIENT;
    e.netname		= "Target Practice";
    e.think 		= Practice_Think;
    e.nextthink 	= time + sys_ticrate;
    e.th_die    	= GibTarget;
    e.velocity 		= self.velocity;
    e.velocity 		= aim(self, 10000);

    setmodel (e, "progs/player.mdl");

    setsize (e, VEC_HULL_MIN, VEC_HULL_MAX);

    setorigin(e, self.origin +'0 0 32');

    e.angles_x	= self.angles_x;
    e.angles_y	= self.angles_y;
    e.frame		= 12;

//
// shoot object from gun
//
    makevectors (self.v_angle);
    e.velocity = e.velocity * v_forward * 500;
    sound (self, CHAN_WEAPON, "misc/r_tele4.wav", 1, ATTN_NORM);
};
*/
//-----------------------------------------------------------------------------------
void () TossAmmo;
void () TossWeapon;
void () TossRune;
void () HookOff;
void () votables_request_set_faststarts;
void () votables_force_start;

//
//  I M P U L S E
//
//  Called from PlayerPreThink or observer_pre_think
//
void () clanring_impulse =
{
    if (self.impulse == 19)
        TossRune ();
    else if (self.impulse == 20)
        TossAmmo();
    else if (self.impulse == 21)
        TossWeapon();
    else if (self.impulse == 69)
        PreviousWeaponCommand();
    else if (self.impulse == 203)
        votables_request_set_runes();
    else if (self.impulse == 199)
        votables_request_vote_exit();
    else if (self.impulse == 209)
        votables_request_set_faststarts();
    else if (self.impulse == 57)//R00k: allow players to manually go afk, so they wont be counted in votes.(changed to use imp 70 to toggle off the ctf hud)
    {
        if (!(self.style & CLANRING_AFK_CLIENT))
        {
            if (clanring_afk_timeout > 0)
                sprint(self, "Press FIRE or JUMP to disable '\bafk\b' status.\n");
            afk_name();
            forceinfokey(self, "afk","yes");// woods
            self.style = self.style | CLANRING_AFK_CLIENT;
            self.afk_time = time;
        }
        else
            clear_afk_status(self);
    }
    else if (self.impulse == 58)
    {
        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
            CaptureHighScores_sprint();
        else if (clanring_playmode & CLANRING_AIRSHOT_MODE)
            AirshotHighScores_sprint();
        // else
        // 	LongRangeGibs_sprint();
    }
    else if (self.impulse == 70)
    {
        if (self.statstate < 0)
        {
            self.statstate = 0;
            sprint(self, "Status bar on (impulse 71-81 set pos)\n");
        }
        else
        {
            self.statstate = -1;
            sprint(self, "Status bar off.\n");
        }
    }
    else if (self.impulse >= 71 && self.impulse <= 81)
    {
        self.statstate = self.impulse - 71;
        sprint(self, "Status bar set\n");
    }
    else if (self.impulse == 23)
    {
        if (teamplay)
            TeamFlagStatusReport ();
    }
    else if (self.impulse == 38)
        clanring_ping_reply ();
    else if (self.impulse == 39)
    {
        self.lagcheck    = self.finaldest_x;
        self.finaldest_x = time;
        if (self.finaldest_x - self.lagcheck <= 5 )
            self.lagcount = self.lagcount + 1;
        if (self.lagcount > 2)
        {
            self.lagcount  = 0.00;
            self.plag      = 0.00;
        }
    }
    else if (self.impulse >= 190)
        admin_impulse ();
    else if (self.impulse >= 120 && self.impulse <= 139)
        match_impulse ();
    else if (self.impulse >= 140 && self.impulse <= 159)
        observer_impulse ();
    else if (self.impulse >= 169 && self.impulse <= 179)
        stats_impulse ();
    else if (self.impulse == 100)
        clanring_help ();
    else if (self.impulse == 101)
        observer_help ();
    else if (self.impulse == 107)
    {
        self.finaldest_z    = 0;
        self.warp_episode   = 0;
        self.warp_map       = 0;
        self.use            = SUB_Null;
        client_select_warp();
    }
    else if (self.impulse == 103)
        clanring_show_rules ();
    else if (self.impulse == 105)
        clanring_help_misc ();
    else if (self.impulse == 106)
        clanring_commands ();
    else if (self.impulse == 102)
        clanring_levels ();
    else if (self.impulse == 108)
        admin_start_code ();
    else if (self.impulse == 109)
        motd_create ();
    else if (self.impulse == 110)
        clanring_admins ();
    else if (self.impulse == 114)
        utils_toggle_flag (CLANRING_SMART_WEAPON, "Smart weapon switching");
    else if (self.impulse == 117)
        clanring_vinfo ();
    else if (self.impulse == 118)
        clanring_ticrate ();
    else if (self.impulse == 180)
        self.style = (self.style | CLANRING_FOUND_BINDINGS);
    else if (self.impulse == 181)
        modes_commands ();
    else if (self.impulse == 182)
        gameplay_commands ();
    else if (self.impulse == 183)
        watch_commands ();
    else if (self.impulse == 184)
        stat_commands ();
    else if (self.impulse == 185)
        misc_commands ();
    else if (self.impulse == 186)
        modhelp_commands ();
    else if (self.impulse == 187)
        shortcuts_commands ();
    else if (self.impulse >= 115 && self.impulse <= 116)
    {
        if (self.style & CLANRING_KICK_CONFIRM)
        {
            if (clanring_kick_mode == KICK_KICK)
                admin_confirm_kick_response (116 - self.impulse);
            else if (clanring_kick_mode == KICK_BAN)
                admin_confirm_ban_response ((116 - self.impulse));
        }
        else
        {
            if (self.style & CLANRING_CONFIRM_LEAVE)
            {
                if (mode_is_arena())
                    arena_observer_confirm_leave_response((116 - self.impulse));
                else
                    observer_confirm_leave_response ((116 - self.impulse));
            }
            else
                vote_impulse ();
        }
    }
    else if (self.impulse == 217)
		votables_force_start();
	else
        sprint(self, "type 'help-server' in console for help\n");
    self.impulse = 0;
};

//
//  C L I E N T  S U I C I D E
//
//  Called from ClientKill in Client.qc.  Checks to see if the player
//  has exceeded their suicide limit and returns either CLANRING_SUICIDE_OK
//  or CLANRING_TOO_MANY_SUICIDES accordingly.
//
float () clanring_client_suicide =
{
    local string temp;

    // Always OK for admins or practice mode
    if (self.style & CLANRING_ADMINISTRATOR)
        return CLANRING_SUICIDE_OK;

    self.cnt -= 1;

    if (self.cnt < 0)
    {
        // too many suicides
        if (self.cnt >= -1) // only want to do this stuff once
        {
            announce2(self.netname, " kicked for suiciding");
            clanring_kick_mode = KICK_KICK;
            clanring_kick_player (self);
        }
        return CLANRING_TOO_MANY_SUICIDES;
    }
    temp = ftos(floor(self.cnt));
    sprint3(self, "you have ", temp, " suicides remaining\n");
    return CLANRING_SUICIDE_OK;
};

//
//  C L I E N T  R E A D Y
//
//  Prevent "observer spamming": rapid observer/ready in normal/practice mode
//
float () clanring_client_ready =
{
    if (self.style & CLANRING_ADMINISTRATOR)
        return FALSE;

    self.cnt -= 1;

    if (self.cnt < 0)
    {
        if (self.cnt >= -1)
        {
            announce2(self.netname, " kicked for observer spamming");
            clanring_kick_mode = KICK_KICK;
            clanring_kick_player(self);
        }
        return TRUE;
    }
    return FALSE;
};

//intermediate prototypes
entity (entity e) observer_find_target;
entity (entity e) observer_find_camera;
void() match_notready;
void (entity player) observer_update_player_observer_key;

//
//  S E N D   T E A M   I N F O
//
//  Sends team information updates to clients approximately 6 times per second.
//  Only sends to QSS-M and FTE clients. For observers, sends info about all players.
//  For team games, only sends info about players on the same team.
//

.float team_info_time;

void () Send_TeamInfo =
{
    if (self.team_info_time > time)
        return;
    self.team_info_time = time + 0.167;  // ~6 updates/sec

    if ((self.client != "QSS-M") && (self.client != "FTE"))
        return;

    void(entity target) SendPlayerInfo =
    {
        if (!(target.style & CLANRING_CONNECTED))
            return;
            
        local float speed = vlen(target.velocity);
        local float newItems = target.items;

        // Add sigil/rune bits using bits 23-26
        local float i;
        for (i = 0; i < 4; i = i + 1)
        {
            local float bitmask = 32 << i;  // produces 32, 64, 128, 256
            local float sigilBit = 1 << (23 + i);
            if (target.items2 & bitmask)
                newItems = newItems | sigilBit;
        }
        
        string part1 = sprintf("//tinfo %d %d %d %d ", 
            num_for_edict(target) - 1,
            target.origin_x,
            target.origin_y,
            target.origin_z);

        string part2 = sprintf("%d %d %d %d\n",
            floor(bound(0, target.health, 999)),
            floor(bound(0, target.armorvalue, 999)),
            newItems,
            floor(speed));

        stuffcmd(self, strcat(part1, part2));
    };

    
    if (self.style & CLANRING_OBSERVER)
    {
        if (clanring_playmode & (CLANRING_CA_MODE | CLANRING_WIPEOUT_MODE | 
            CLANRING_RA_MODE | CLANRING_DMM4_MODE | CLANRING_AIRSHOT_MODE))
        {
            // Arena mode observers - send info for all team players
            entity obs_team = boss.next_team;
            while (obs_team)
            {
                entity obs_player = obs_team.chain_gang;
                while (obs_player)
                {
                    if (obs_player.style & CLANRING_CONNECTED)
                    {
                        SendPlayerInfo(obs_player);
                    }
                    obs_player = obs_player.chain_gang;
                }
                obs_team = obs_team.next_team;
            }
        }
        else
        {
            // Standard observers - send info for all players
            entity player = clanring_sentinel.next_player;
            while (player)
            {
                if (player.style & CLANRING_CONNECTED)
                    SendPlayerInfo(player);
                player = player.next_player;
            }
        }
        return;
    }

    if (clanring_playmode & (CLANRING_CA_MODE | CLANRING_WIPEOUT_MODE))
    {
        // CA/Wipeout modes - use chain_gang structure
        entity pteam = boss.next_team;
        while (pteam)
        {
            if (pteam.team2 == self.team2)  // Match team by team2 color
            {
                entity chain_player = pteam.chain_gang;
                while (chain_player)
                {
                    if (chain_player.style & CLANRING_CONNECTED)
                    {
                        SendPlayerInfo(chain_player);
                    }
                    chain_player = chain_player.chain_gang;
                }
                break;
            }
            pteam = pteam.next_team;
        }
    }
    else if (self.team && 
             !(clanring_playmode & CLANRING_PRACTICE_MODE) && 
             ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) || 
              (clanring_playmode & CLANRING_MATCH_MODE)))
    {
        // CTF/Match modes - use player list directly
        entity list_player = clanring_sentinel.next_player;
        while (list_player)
        {
            if ((list_player.style & CLANRING_CONNECTED) && 
                (list_player.team == self.team) &&
                (list_player.height == self.height))
            {
                SendPlayerInfo(list_player);
            }
            list_player = list_player.next_player;
        }
    }
};

//
//  P E R I O D I C  C H E C K S
//
//  Do various checks every second.  Called from PlayerPreThink in
//  Client.qc.
//
void () clanring_periodic_checks =
{
    if (!(self.style & CLANRING_CONNECTED))
        return;

    local float inactive, c;

    if (!(self.style & CLANRING_ADMINISTRATOR))
    {
        if (utils_illegal_name (self.netname))
        {
            // Let's be fairly draconian about this
            updatename (self, "unnamed");//R00k...
//			announce("Player kicked for illegal name");
//			clanring_kick_mode = KICK_KICK;
//			clanring_kick_player (self);
//			return;
        }
    }

    //Regenerate suicides 20% per second.
    if (self.cnt < CLANRING_MAX_SUICIDES)
        self.cnt = self.cnt + 0.2;

    //Replenish grenade spam count once per sec.
    if (clanring_playmode & CLANRING_NO_SPOOGE)
    {
        if (self.lip > 0)
            self.lip -= 1;
    }

    if (self.style & CLANRING_OBSERVER)
    {
        if (self.style & CLANRING_MOTD) // asap
        {
            if (self.plag == FALSE)
            {
                motd_print ();
            }
        }

        observer_find_teleport();
        observer_check_size();

        //Update player's name for eyecam
        if (self.movetarget)
        {
            if (self.movetarget.netname != self.movetarget.oldname)
            {
                strunzone(self.movetarget.oldname);
                self.movetarget.oldname = strzone(self.movetarget.netname);
                observer_update_player_observer_key(self);
            }
        }

        if (self.oflags & OBSERVER_QUAKETV) //Sputnik: reset between map loads.
        {
            if (!(self.movetarget))
            {
                self.movetarget = observer_find_camera(world);// see if we can find a camera
                if (self.movetarget)
                {
                    self.oflags = self.oflags | OBSERVER_GO_AUTO;
                    observer_camera_start();
                }
                else
                {
                    self.movetarget = observer_find_target(world);// see if we can find a player
                    if (self.movetarget)
                    {
                        self.oflags = self.oflags | OBSERVER_GO_AUTO;
                        if (self.oflags & OBSERVER_DEMO) //AutoEyecam Default
                            observer_demo_start();
                        else
                            observer_chase_start();
                    }
                }
            }
        }
    }
    else
    {
        if (!self.deadflag)
        {
            auto_compute_score();
        }
    }

    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        if ((self.style & CLANRING_READY) && ((!(clanring_state & CLANRING_MATCH_STARTED)) && (!(clanring_state & CLANRING_MATCH_OVER))))
        {
            if (self.style & CLANRING_CONNECTED)
            {
                if (self.style & CLANRING_AFK_CLIENT)
                    afk_name();
                else
                    ready_name();
            }
        }
    }

    self.ping_time = client_ping(self);

    inactive = time - self.afk_time;//Seconds of inactivity

    if (self.style & CLANRING_AFK_CLIENT)
    {
        if (clanring_afk_timeout > 0)	// Set 'kickafk' in clanring.cfg to 0 to disable kicking...
        {
            if (inactive >= clanring_afk_timeout)
            {
                clanring_kick_mode = KICK_AFK;
                clanring_kick_player(self);
                //TODO: if FTE server just force them to SPECTATOR
                return;
            }

            local string s, pl;

            c = floor(inactive / 60);		//Minutes of inactivity (round down).

            s = ftos((clanring_afk_timeout / 60) - c);
            pl = strings_szplural((clanring_afk_timeout / 60) - c);

            if (c > ((clanring_afk_timeout / 60) - 5))	//If afk-timer is less than 5 minutes from timeout...
            {
                if ((inactive - (c * 60)) < 1)//One minute has passed...sorta
                {
                    stuffcmd(self, "play ");
                    //todo choose random?
                    //stuffcmd(self, "zombie/idle_w2.wav");
                    stuffcmd(self, "demon/idle1");
                    stuffcmd(self, "\n");
                    sprint(self, "AFK ALERT: \bYou will be kicked in ",s," minute",pl,".\n");
                    sprint(self, "Press jump or fire to stay connected.\n");
                }
            }
        }
    }
    else
    {
        if ((clanring_playmode & CLANRING_MATCH_MODE) && ((!(clanring_state & CLANRING_MATCH_STARTED)) && (!(clanring_state & CLANRING_MATCH_OVER))))
        {
            if (self.style & CLANRING_READY)
            {
                if (inactive > 120)
                    match_notready(); //Un-ready players that are idle for a couple minutes.
            }
        }

        if (((clanring_playmode & CLANRING_MATCH_MODE)&&(clanring_state & CLANRING_MATCH_STARTED))&&(self.next_team != world)&&(inactive == 120))	//Warn my teammates I've been standing around doing nothing for the past 2 minutes...
        {
            local entity tmate;
            tmate = self.next_team.next_player;
            while (tmate)
            {
                if (tmate != self)
                    sprint(tmate, self.netname, " has been AFK for over 2 minutes.\nUse \btimerstop\b to pause the match.\n");
                tmate = tmate.next_player;
            }
        }
        if ((inactive >= clanring_afk_check) && (!(self.style & CLANRING_ADMINISTRATOR)))
        {
            afk_name();
            self.afk_time = time;
            self.style = (self.style | CLANRING_AFK_CLIENT);
            forceinfokey(self, "afk","yes");	// woods
            if (clanring_afk_timeout > 0)//Only print afk if kick is enabled
                sprint(self, "Press FIRE or JUMP to disable '\bafk\b' status.\n");
        }
    }
    //R00k: Moved here from PlayerPreThink
    if (mode_is_arena())
    {
        if (clanring_playmode & CLANRING_CA_MODE)
        {
            if (self.style & CLANRING_CONNECTED)
            {
                if (self.team != (self.team2 + 1))
                {
                    // if (self.next_team == world)
                    // {
                    //     if (self.team == 14)
                    //         self.impulse = 1;
                    //     else if (self.team == 5)
                    //         self.impulse = 2;
                    //     else if (self.team == 13)
                    //         self.impulse = 3;
                    //     else if (self.team == 3)
                    //         self.impulse = 4;

                    //     Teamplay_Select_Team();
                    //     self.impulse = 0;
                    // }
                    // else
                    // {
                        if (self.health > 0)
                        {
                            self.team2 = self.next_team.team2;
                            //R00k -- this forces team colors, unless they are in queue to join.
                            if ((!self.cc_queue))
                            {
                                setcolour(self, self.team2, self.team2);
                            }
                            self.team = (self.team2 + 1);
                        }
                    // }
                }

                if (boss.timetofight == TRUE)
                {
                    if ((self.ca_player_flag == PF_PLAYING) && (self.style & CLANRING_CONNECTED))//v1.97 fix lagouts.
                    {
                        self.takedamage = DAMAGE_AIM;
                    }
                }
            }
        }
    }
};

//
//  S T A R T  F R A M E
//
//  Called from StartFrame in World.qc.  This routine performs periodic
//  checks in match mode and checks for server console commands.
//
void () clanring_start_frame =
{
    local float command;

    if (!gameover)
    {
        if (sys_ready)
        {
            if (mode_is_arena())
            {
                if (time >= clanring_rulescheck)
                {
                    if (boss != world)
                    {
                        if (clanring_playmode & CLANRING_CA_MODE)
                            arena_main_loop();
                        else if ((clanring_playmode & CLANRING_AIRSHOT_MODE) || (clanring_playmode & CLANRING_DMM4_MODE))
                            dmm4_main_loop();
                        else if (clanring_playmode & CLANRING_RA_MODE)
                            rocket_arena_main_loop();
                    }

                    clanring_rulescheck = (time + 1);
                }
            }
            else if (!(clanring_playmode & CLANRING_MATCH_MODE))
            {
                if (timelimit)
                {
                    if (time >= timelimit)
                    {
                        if (clanring_levelcount == -1)
                        {
                            bprint("Timelimit Hit -- Game Over!\n");
                            NextLevel ();
                            return;
                        }
                    }
                }
            }
            
            if (time >= clanring_nextcheck)                 // CLANRING_NEXTCHECK-- every 5 seconds...
            {
                local entity player;
                // update variables
                timelimit 	= cvar("timelimit") * 60;
                fraglimit 	= cvar("fraglimit");
                teamplay 	= cvar("teamplay");

                player = find(world, classname, "player");
                while (player != world)
                {
                    if (player.style & CLANRING_CONNECTED)
                    {
                        if (time > player.finaldest_x + 5)
                        {
                            // send out ping to test for disconnected players
                            msg_entity = player;
                            WriteByte(MSG_ONE, SVC_STUFFCMD);
                            WriteString(MSG_ONE, "impulse 39\n");
                        }

                        if ((time >= player.finaldest_x + 15) && (time < player.finaldest_x + 16))
                        {
                            bprint(player.netname," is \blagged\b.\n");
                            bprint("\bClanRing\b lag protection activated.\n");
                            player.plag = TRUE;
                        }

                        if (time > player.finaldest_x + 25)
                        {
                            clanring_kick_mode = KICK_LAGOUT;
                            clanring_kick_player (player);
                        }
                    }
                    else
                    {
                        if (!(player.style & CLANRING_NEW_CLIENT))
                        {
                            player.model 		= string_null;
                            player.solid 		= SOLID_NOT;
                            player.takedamage 	= DAMAGE_NO;
                            // Entity of disconnecting client not initialized fix
                            player.classname 	= string_null;
                            player.netname    	= "";
                        }
                    }
                    player = find(player, classname, "player");
                }
                clanring_nextcheck = time + 5;
            }
            
            if (time >= clanring_nextcheck2)                // CLANRING_NEXTCHECK2 every second...
            {
                for (entity e = world; (e = find(e, classname, "player")) != world;)    // Check if there is even an observer
                {
                    if (e.style & CLANRING_OBSERVER)
                    {
                        auto_check_current_camera();
                        auto_schedule_cameras();
                        utils_make_scheduled_event(auto_chase, 0.3);
                        utils_make_scheduled_event(auto_camera, 0.6);
                        break;
                    }
                }

                if ((clanring_state & CLANRING_MATCH_STARTED)||(!(gameover)))	//Only update if game is on-going.
				    clanring_sentinel.matchTime = time;

                if (timelimit && !(clanring_playmode & CLANRING_MATCH_MODE) && (mode_is_arena() == FALSE))
                {
                    float tl = rint(timelimit - time);

                    switch (tl)
                    {
                        case 300:
                            bprint("\n\bGame ends in\b \.\[ 5 \]\.\b minutes\n\n");
                            break;
                        case 60:
                            bprint("\n\bGame ends in\b \.\[ 1 \]\.\b minute\n\n");
                            break;
                        case 30:
                            bprint("\n\bGame ends in\b \.\[ 30 \]\.\bseconds\n\n");
                            break;
                        case 10:
                            bprint("\n\bGame ends in\b \.\[ 10 \]\.\bseconds\n\n");
                            break;
                        case 5:
                            bprint("\x90 5 \x91\n");
                            break;
                        case 4:
                            bprint("\x90 4 \x91\n");
                        break;
                        case 3:
                            bprint("\x90 3 \x91\n");
                        break;
                        case 2:
                            bprint("\x90 2 \x91\n");
                        break;
                        case 1:
                            bprint("\x90 1 \x91\n");
                            bprint("\n");
                        break;
                    }
                }

                clanring_nextcheck2 = time + 1;
            }
        }
    }
    else
    {
        if (intermission_running)
        {
            if (time >= intermission_exittime)
            {
                intermission_running = FALSE;
                forceinfokey (world, "intermission","off");
                pqc_match_time (0, 0);

                // V O T E M E N U   C H E C K   M A J O R I T Y -- start
                string temp = "";
                float c = 0;

                // Count the votes and store the best one in temp (by name) and map_choices[0] (by number of votes).
                for (float i = 1; i < 6; i++)
                {
                    if (map_choices[i] >= map_choices[0]) //if a tie then the last one voted for wins... :|
                    {
                        temp = vote_map_choices[i];
                        map_choices[0] = map_choices[i];
                        c = i;
                    }
                }

                if (map_choices[0] == 0) 			// no one voted.
                    temp = vote_map_choices[1];		// Default 'nextmap' filename from levels.cfg

                tokenize(temp);

                if (nextmap != "")
                    strunzone(nextmap);

                if (!(found_in_warp_list(argv(0))))	// in case the tempstring gets garbled
                    nextmap = default_nextmap;
                else
                    nextmap = strzone(argv(0));

                VoteMenu_Cleanup();
                // V O T E M E N U   C H E C K   M A J O R I T Y -- end

                changelevel(nextmap);
                strunzone(nextmap); // zoned mem carries over, over changelevels, so we need to free it now.
                nextmap = "";
            }
        }
    }
    sys_ticrate = cvar("sys_ticrate");//R00k Added
    //sv_friction = cvar("sv_friction");//R00k Added

    // Check for a console command
    command = cvar("temp1");
    cvar_set("temp1", "0");
    if (command)
        console_command(command);
};
