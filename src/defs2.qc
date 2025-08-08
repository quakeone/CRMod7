//
// Defs2.qc                                   (Elodefs.qc)
//
// Constants and global variables used in the Elohim mod.
//
// All code by J.P. Grossman unless otherwise commented.
//
// See Elohim.qc for a list of standard fields used.
//

// constants
float CLANRING_SUICIDE_OK    		= 0;
float CLANRING_TOO_MANY_SUICIDES 	= 1;
float CLANRING_NEGINF    			= -9999999;

// client styles
float CLANRING_NEW_CLIENT    	= 1;			// set when a client first connects
float CLANRING_ADMINISTRATOR    = 2;			// set if the client is an admin
float CLANRING_AFK_CLIENT    	= 4;
float CLANRING_MUTED			= 8;
float CLANRING_READY 			= 16;           // ready to play in match
float CLANRING_YES 				= 32;           // used for voting
float CLANRING_HEADS_UP 		= 64;          	// enable heads up display
float CLANRING_SETTING_OPTIONS 	= 128;  		// set when setting options
float CLANRING_MOTD 			= 256;          // showing MOTD
float CLANRING_OK_TO_SHOOT 		= 512;      	// don't fire after options/respawn
float CLANRING_KICK_CONFIRM 	= 1024;    		// used to confirm a kick
float CLANRING_CONFIRM_LEAVE 	= 2048;   		// confirmation for leaving match
float CLANRING_CONNECTED 		= 4096;       	// client has been put in server
float CLANRING_FOUND_BINDINGS 	= 8192; 		// used to check for bindings
float CLANRING_SMART_WEAPON    	= 16384;		// whether or not to use `smart' weapon switching
float CLANRING_OBSERVER    		= 32768;		// set if the client is an observer
float CLANRING_TYPING_CLIENT    = 65536;		// is the client typing
float CLANRING_SCOREBOARD 		= 131072;		// player is looking at teamscores
float CLANRING_NO_POST_THINK 	= 262144;		// don't do post think (optimization)
float CLANRING_WINQUAKE 		= 524288;     	// player is using winquake
float CLANRING_GLQUAKE 			= 1048576;     	// player is using glquake
float CLANRING_AUTOSTATS    	= 2097152;
float CLANRING_RED_TEAM			= 4194304;
float CLANRING_BLUE_TEAM		= 8388608;

// observer flags
float OBSERVER_WALK             = 1;            // set in walk mode
float OBSERVER_FLY              = 2;            // set in fly mode
float OBSERVER_CHASE            = 4;            // set in chase mode
float OBSERVER_DEMO             = 8;            // see through chasetargets eyes
float OBSERVER_CAMERA           = 16;		    // set to camera mode
float OBSERVER_AUTO             = 32;	        // view autoswitching
float OBSERVER_TOURNEY          = 64;	        // set tournement mode for chasecam
float OBSERVER_GO_AUTO          = 128;          // player entering an auto mode
float OBSERVER_COMMENTARY       = 256;          // see running commentary
float OBSERVER_POP_FORWARD    	= 512;
float OBSERVER_QUAKETV 			= 2048;		    // Sputnik: added this for streaming via quaketv

/*
// CRMOD qsmack variables
.float qsmack_level;
.float qsmack_trylevel;
float qsmack_statusokay;
*/

// server mode - stored in cvar 'samelevel' and preserved across levels
float CLANRING_NORMAL_MODE    		= 1;            //R00k:changed
float CLANRING_MATCH_MODE    		= 2;
float CLANRING_PRACTICE_MODE    	= 4;
float CLANRING_SERVER_INITIALIZED   = 8;
float CLANRING_NO_GIBS    		    = 16;
float CLANRING_LOW_GIBS    		    = 32;
float CLANRING_NO_QUAD    		    = 64;
float CLANRING_NO_PENT    		    = 128;
float CLANRING_NO_RING    		    = 256;
float CLANRING_MODE_VOTE    		= 512;
float CLANRING_CAPTURE_THE_FLAG		= 1024;
float CLANRING_NO_SPOOGE    		= 2048;
float CLANRING_RUNES			    = 4096;
float CLANRING_EXTENDED_OBITS    	= 8192;
float CLANRING_CONSOLE_INITIALIZED  = 16384;
float CLANRING_WIPEOUT_MODE			= 32768;
float CLANRING_FRESH_SPAWNS         = 0;//65536;//used?
float CLANRING_AIRSHOT_MODE			= 65536;
float CLANRING_AUTO_PAUSE    		= 131072;
float CLANRING_RUNETOSS    		    = 262144;
float CLANRING_NO_HOOK			    = 524288;
//float CLANRING_FREEZETAG			= 0;
//float CLANRING_SPEEDBALL			= 0;
//float UNUSED						= 1048576;
float CLANRING_DMM4_MODE			= 1048576;
float CLANRING_CONSOLE_STATS   		= 2097152;
float CLANRING_CA_MODE				= 4194304;
float CLANRING_RA_MODE				= 8388608;

/*
	P L A Y M O D E
	clanring_playmode - stored in cvar 'samelevel' and preserved across levels
	eg. (clanring_playmode & CLANRING_PRACTICE_MODE)

float CLANRING_FREEFORALL_MODE    = 1;        // teamplay 0 dm; normal mode
float CLANRING_PICKUP_DM_MODE     = 2;        // teamplay 1 dm; no friendly fire; normal mode
float CLANRING_MATCH_TDM_MODE     = 4;        // teamplay 2 dm; friendlyfire; match mode
float CLANRING_PRACTICE_DM_MODE   = 8;        // teamplay 0 dm; self damage; practice full inventory
float CLANRING_PICKUP_CTF_MODE    = 16;       // teamplay 1 ctf; no friendly fire; normal mode
float CLANRING_MATCH_CTF_MODE     = 32;       // teamplay 1 ctf; match timer
float CLANRING_PRACTICE_CTF_MODE  = 64;       // teamplay 0 ctf; hook enabled; practice full inventory
float CLANRING_CLAN_ARENA_MODE    = 128;      // Clan Arena
float CLANRING_FREEZETAG_MODE     = 256;      // sub mode of ClanArena, you respawn by teammate intervention.
float CLANRING_WIPEOUT_MODE       = 512;      // sub mode of ClanArena, you respawn at set time intervals.
float CLANRING_ELIMINATION_MODE   = 1024;     // Sub mode of ClanArena, you respawn when your killer dies.
float CLANRING_AIRSHOT_MODE       = 2048;     //
float CLANRING_DMM4_MODE          = 4096;     //
float CLANRING_ROCKET_ARENA_MODE  = 8192;     //
float CLANRING_SPEEDBALL_MODE     = 16384;    //
float CLANRING_INSTAGIB_MODE      = 32768;    //
float CLANRING_SERVER_INITIALIZED = 0;
*/
/*
	G A M E C O N F I G
	clanring_gameconfig - preserved across levels in cvar 'gamecfg'
	eg. (clanring_gameconfig & CLANRING_NO_HOOK)
*/
// TODO: enumflags

// float CLANRING_AUTO_PAUSE    		= 1;
// float CLANRING_CA_CC_VOTE			= 2;
float CLANRING_DISABLE_VOTE				= 4;
// float CLANRING_EXTENDED_OBITS    	= 8;
float CLANRING_ALTERNATIVE_ENTS    		= 16;
// float CLANRING_FRESH_SPAWNS         	= 32;
// float CLANRING_MODE_VOTE    			= 64;
// float CLANRING_NO_HOOK			    = 128;
// float CLANRING_NO_PENT    			= 256;
// float CLANRING_NO_QUAD    			= 512;
// float CLANRING_NO_RING    			= 1024;
// float CLANRING_NO_SPOOGE    			= 2048;
float CLANRING_POWERUP_DROP				= 4096;
// float CLANRING_RUNES			    	= 8192;
// float CLANRING_RUNETOSS    		    = 16384;
float CLANRING_SPAWNFRAG_PROTECTION 	= 32768;
float CLANRING_SEQUENTIAL_SPAWNS		= 65536;
// float CLANRING_BREAKAWAY_HOOK		= 0;
// float CLANRING_QW_ROCKET_DAMAGE		= 0;		//set rocket damage to 110 eliminate the ' + random () * 20 '
float CLANRING_DROP_DEATH_SHARDS		= 1048576;
// float CLANRING_VOTE_MAJORITY_PASS	= 0;
float CLANRING_ENABLE_MATCHSOUNDS = 2097152;
// clanring_state - not preserved across level changes
float CLANRING_TIMER_STARTED  		= 1;
float CLANRING_MATCH_STARTED    	= 2;
float CLANRING_MATCH_PAUSED    		= 4;
float CLANRING_MATCH_OVER    		= 8;
float CLANRING_MATCH_WAIT  	    	= 16;// 5 second delay after match ends
float CLANRING_KICKING    		    = 32;
float CLANRING_IGNORE_CONSOLE		= 64;
// muddle counts :)
float CLANRING_SETQUAD_COUNT    	= 128;
float CLANRING_SETPENT_COUNT    	= 1024;
float CLANRING_SETRING_COUNT    	= 8192;
// end muddle (eats bits up to 65536)
float CLANRING_NO_PRACTICE    		= 131072;
float CLANRING_TEAM_CAPTURE_CUSTOM	= 262144;
float CLANRING_UNPAUSING    		= 524288;
float CLANRING_AUTO_PAUSED    		= 1048576;
float CLANRING_DELAYED_AUTOSS    	= 2097152;
float CLANRING_TAKING_AUTOSS    	= 4194304;
float CLANRING_NULL_FLAG		    = 8388608;//R00k: added, used to make the flags untouchable during match start countdown, ie "Match begins in T minus"...

// admin constants
float ADMIN_NORMAL_MODE    	= 0;
float ADMIN_PRACTICE_MODE   = 1;
float ADMIN_MATCH_MODE    	= 2;
float ADMIN_CTF_MODE    	= 3;
float ADMIN_CA_MODE    		= 4;
float ADMIN_RA_MODE    		= 5;
float ADMIN_AIRSHOT_MODE    = 6;
float ADMIN_DMM4_MODE    	= 7;
float ADMIN_WIPEOUT_MODE	= 8;

// entity constants
float CLANRING_MANUAL_SPAWN = 1;

// global variables
//float   clanring_player_ids;        // used for assigning unique player ID's
float   clanring_devparam;          // used for development
float   clanring_playmode;          // current play mode (non volatile flags)
float	clanring_gameconfig;		// playmode sub-settings (non volatile flags)
float   clanring_state;             // server state (volatile flags)
float   clanring_timelimit;         // timelimit for matches (default 20 minutes)
float   default_timelimit;          // reset timelimit between matches in case of overtime or interrupted match abort
float   clanring_overtime;          // length of auto-overtime; 0 if none
float   clanring_nextcheck;         // used for periodic checks
float   clanring_nextcheck2;	    // used for frequent periodic checks
entity  clanring_request;           // used to control voting
float   clanring_level;             // number of current level in user level order
float   clanring_levelcount;        // used to scan through list in levels.cfg
float   clanring_lastcount;         // used to detect end-of-file in levels.cfg

float   dm_num_spawns;              // number of deathmatch spawn points (as opposed to ctf spawn points)
float   clanring_num_starts;        // number of match extra start points
float   clanring_num_cameras;       // number of cameras
string  clanring_version;           // used for motd and help-server
string  clanring_version_info;      // text info including rev. and compile time
string  clanring_version_number;    // text info storing version number (ie "4.0")
entity  clanring_debug_client;      // used for debugging
entity  clanring_quad;		        // pointer to quad for quick reference
entity  clanring_pent;		        // pointer to pent for quick reference

// match global variables
float   clanring_match_pause_time;  // records time that match was paused
float   clanring_maxteams;			// maximum number of teams
float   clanring_numteams;			// number of teams
float   clanring_maxsize;           // maximum allowed team size
entity  clanring_match_timer;       // used to time match
entity  clanring_sentinel;			// head of linked lists
string  clanring_szthe;			    // hack - = "The " for teamplay, "" for individual
string  clanring_szteam;			// hack - = "team" for teamplay, "player" for individual

// score global variables
string  clanring_winning_teamname;	// name of winning team (as returned by strings_get_teamname)
float   clanring_score_number;		// either difference in score or tied score
string 	CLANRING_STRING_TIED;       // initialized to "   Tied at "
float   clanring_score_count;	    // number of clients looking at score
entity 	clanring_first_place;
entity 	clanring_second_place;

// console global variables
float 	console_deathmatch;
float 	console_timelimit;
float 	console_fraglimit;
float 	console_pausable;
float 	console_noexit;

// auto parameters
float auto_parm1;	// 
float auto_parm2;	// 
float auto_parm3;	// 
float auto_parm4;	// 

// other global variables
string nextmap;                     // moved here from Client.qc
float timelimit;                    // this used to be local in CheckRules in Client.qc        
float fraglimit;                    // this used to be local in CheckRules in Client.qc        
float intermission_running;         // moved here from Client.qc
float intermission_exittime;        // moved here from Client.qc
.float rounddeaths;
.float respawntime;
.float teamalive;
.float teamtotal;
.float quadtime;
.float totalquad;

.float tp_time;     // last time the player teleported
.float tfrag_time;  // spawn time for a tele-death trigger

entity 	clanring_best_chase_target;		// calculated every second who is the best target to chase // CRMOD - auto
entity 	clanring_current_chase_target;
float 	clanring_chase_delay;
entity 	clanring_best_camera;			// set after each camera's think
entity 	clanring_current_camera;
float 	clanring_camera_delay;

vector 	clanring_angle;					// used for both autoss and intermission

// client variables
.vector clanring_qdwep;             // vector to keep track of quad weapon stats	// CRMOD - stats
.vector clanring_qdkill;            // vector to keep track of quad kill stats		// CRMOD - stats
.vector clanring_ptwep;             // vector to keep track of pent weapon stats	// CRMOD - stats
.vector clanring_ptkill;            // vector to keep track of pent kill stats		// CRMOD - stats
.vector clanring_badstats;          // keep track of RL paks and damage done to team
.vector clanring_badstats2;         // keep track of lava, axe, falling deaths
.float join_time;					// time when player joined the server
.vector clanring_backpacks;			// track rl|lg|gl lost/taken backpacks
.vector deathorigin;
//.float killed_who[16];				// players you killed; the number of times killed_who[playerno].netname
//.float who_killed[16];				// players who killed you; how many times you died by who_killed[playerno].netname
.entity clanring_othertarget;       // entity to focus on in tourneycam		// CRMOD - tourneycam
.entity clanring_inflicted;         // stores entity last attacked			// CRMOD - combat
.float  clanring_chase_score;       // same as above, also used by cameras
.float  clanring_did_damage;        // last time person did damage
.float  oflags;				        // CRMOD observer flags
.float  observer_number;            // Target player number for eyecam
.float  clanring_cam_delay;         // keep autocam from overswitching
.vector clanring_oldangle;          // set by angles_fixangle
.float  delayed_impulse;		    // saves self.impulse so it doesn't get nuked by a ping
.float  timeslot;			        // records which scoreboard slot is used for time
.entity next_player;		        // used to point to first/next player in team
.entity next_team;			        // used to point to next team
.entity next_camera;		        // used to point to next camera
.vector clanring_old_velocity;      // used for pausing/unpausing
.float  clanring_hack_count;	    // used to count admin hacking attempts

float 	CLANRING_ANGLE_SMOOTHING    = 0.6; // CRMOD use this instead of typing the number a billion times (actually 6 times in observer.qc ;) )


//-----------------------------------------------------------------------------------------------------------------------------------------------
/*
 * helpers. -- from cspreee
 */
 #define redify(s) strconv(0,2,2,s)
 #define whitey(s) strconv(0,1,1,s)
 #define alternate(s) strconv(0,5 + ((time*4)&1), 5 + ((time*4)&1),s)
 #define flash(s) strconv(0,1 + ((time*4)&1), 1 + ((time*4)&1),s)
 #define goldnmbr(s) strconv(0,3,3,s)
 #define lowrcase(s) strconv(1,0,0,s)
 #define brackets(s) sprintf("%s%s%s", chr2str(0x90), s, chr2str(0x91))
 #define disconnected(s) sprintf("%s %s", chr2str(0x87), s)
//---------------------------------------------------------- 
void(string s1, ...) cprint;
void(string s1, string s2) cprint2;
void(string s1, string s2, string s3) cprint3;
void(string s1, string s2, string s3, string s4) cprint4;
.float 	rotthink;//megahealth think

.string name_ready;
.string oldname;
.string name_before_typing; // stores previous display name while typing is active
.string trueip;

.float 	plag;
.float  lagcheck;
.float	lagcount;

.float 	warp_episode;//chosen episode to warp
.float 	warp_map;//chosen map to warp

//ctf variables from ZOID's 3wave
float 	TEAM_CAPTURE_CAPTURE_BONUS    			    = 5;
float 	TEAM_CAPTURE_TEAM_BONUS    			        = 10;
float 	TEAM_CAPTURE_RECOVERY_BONUS    			    = 1;
float 	TEAM_CAPTURE_FLAG_BONUS    			        = 0;
float 	TEAM_CAPTURE_FRAG_CARRIER_BONUS    		    = 2;
float 	TEAM_CAPTURE_FLAG_RETURN_TIME    		    = 30;//was 40
float 	TEAM_CAPTURE_CARRIER_DANGER_PROTECT_BONUS 	= 2;
float 	TEAM_CAPTURE_CARRIER_PROTECT_BONUS    		= 1;
float 	TEAM_CAPTURE_FLAG_DEFENSE_BONUS    		    = 1;
float 	TEAM_CAPTURE_RETURN_FLAG_ASSIST_BONUS    	= 1;
float 	TEAM_CAPTURE_FRAG_CARRIER_ASSIST_BONUS    	= 2;
float 	TEAM_CAPTURE_TARGET_PROTECT_RADIUS    		= 550;
float 	TEAM_CAPTURE_ATTACKER_PROTECT_RADIUS    	= 550;
float 	TEAM_CAPTURE_CARRIER_DANGER_PROTECT_TIMEOUT	= 2;
float 	TEAM_CAPTURE_CARRIER_FLAG_SINCE_TIMEOUT   	= 2;
float 	TEAM_CAPTURE_FRAG_CARRIER_ASSIST_TIMEOUT   	= 6;
float 	TEAM_CAPTURE_RETURN_FLAG_ASSIST_TIMEOUT   	= 4;
float 	TEAM_CAPTURE_UPDATE_TIME  			        = 120;
float 	TEAM_UPDATE_DELAY  				            = 0.1;
//color values (ie self.team = self.height + 1)
float 	RED            		= 5;
float 	BLUE          		= 14;
float 	YELLOW            	= 13;
float 	GREEN          		= 4;

float 	FLAG_AT_BASE  		= 0;
float 	FLAG_CARRIED  		= 1;
float 	FLAG_DROPPED  		= 2;
.float 	flag_carrier;
entity 	team1_lastspawn;
entity 	team2_lastspawn;

//variables from expert ctf
.float 	last_hurt_carrier;
float  	last_flag_capture;
float  	last_capture_team;
.float 	flag_since;
.float 	last_returned_flag;
.float 	last_fragged_carrier;
.float 	lastteamupdate;
.float  leaderboardtime;

//flagstats

.float 	fdefenses;
.float 	freturns;
.float 	fpickups;
.float 	fdrops;
.float 	fcaptures;
.float 	fcdefenses;
.float 	fcassists;
.float	fcfrags;
.float	fctime;

//.float 	onteam;
.float	true_kills;
.float 	direct_hit;
.float 	dmg_taken;
.float 	dmg_given;
.float	dmg_tally;
.float 	captime;

//weapon toss times
.float toss_time;

//enhanced engine colored lighting support
float	EF_YELLOW 		    = 32;
float   EF_BLUE         	= 64;
float   EF_RED          	= 128;
//float   EF_GREEN          	= 256;

float  	sys_ticrate;
//float	sv_friction;
float clanring_ctf_ticrate;
float clanring_tdm_ticrate;

.float 	hurt_together_time;
.float 	hurt_nextthink;
.float	id_time;//delay to identify teammates

.float	killed;//used to determine base spawn points
//.float	gibbed;//time to explode player
float	modelindex_head;
.float	previous_weapon;

float(float start, float end, float stepsize) rnd_number;
//.vector norg;
float 	teamscr1;
float 	teamscr2;
.float 	statstate;
.float 	laststattime;		// time of last status update
float 	lastteamscrtime;
float 	TEAMSCRTIME    = 1;
float 	PLAYERSTATTIME    = 1.75;

entity  runespawn;
float   runespawned     = 0;
float   ITEM_RUNE1_FLAG = 1;
float   ITEM_RUNE2_FLAG = 2;
float   ITEM_RUNE3_FLAG = 4;
float   ITEM_RUNE4_FLAG = 8;
float   ITEM_RUNE_MASK  = 15;
.float  items2;
float   IT2_SIGIL1 = 32;
float	IT2_SIGIL2 = 64;
float   IT2_SIGIL3 = 128;
float   IT2_SIGIL4 = 256;
.float  rune_notice_time;
.float  player_flag;//rune value
.float  regen_time;
.float  regeneration_sound;
.float  haste_sound;
.float 	hookdmg;// damage collector for hook
float  	clanring_kick_mode;
float  	KICK_NONE  	= 0;
float  	KICK_KICK  	= 1;
float  	KICK_BAN   	= 2;
float	KICK_AFK	= 3;
float 	KICK_LAGOUT	= 4;	//R00k
float 	sys_ready;//hold on the server is loading!!
float 	debug = 0;
.float 	ctime;
//string	clanring_version_red;
.entity hookentity;
.string client;

//---custom 'server modules' off-hand hook added for pub mode. (FIXME: remove this shit)
.float 	hook_out;
.float 	hook2;
float 	HOOK_OUT 	= 1;
float 	HOOK_SWING	= 2;
//---
entity	intermission_pos;
//float	banlist;
entity	banent;
float 	hookspeedfire;
float 	hookspeedpull;
.float  delay;

.float 	alpha;//server must support this.
.float	ping_time;//client pings

.float 	hack_timeout;

// JPG - added ProQuake commands
float	PQC_NOP		    =	1;
float 	PQC_NEW_TEAM	=	2;
float	PQC_ERASE_TEAM	=	3;
float 	PQC_TEAM_FRAGS	=	4;
float	PQC_MATCH_TIME	=	5;
float 	PQC_MATCH_RESET	=	6;
float 	PQC_PING_TIMES	=	7;
// JPG - end mod

float	clanring_afk_check;
float	clanring_afk_timeout;
.float 	afk_time;
.float 	vote;    //client flag that holds their vote

.float stats_item_ssg;				//
.float stats_item_ng;				//
.float stats_item_sng;				//
.float stats_item_gl;				//
.float stats_item_rl;				//
.float stats_item_lg;				//
.float stats_item_shells;			//
.float stats_item_nails;			//
.float stats_item_rockets;			//
.float stats_item_cells;			//
.float stats_item_health;			//
.float stats_item_mega;				//
.float stats_item_biosuit;			//
.float stats_item_redarmor;			//
.float stats_item_yellowarmor;		//
.float stats_item_greenarmor;		//
.float stats_item_backpacks;		//
.float stats_item_runes;			//
.float stats_avenge_teammate;		//
.float stats_defense_teammate;      //
.float stats_defense_dropped_flag;  //
.float stats_defense_backpack;      //
.float stats_defense_powerup;       //
.float stats_defense_weapon;        //
.float stats_defense_armor;         //
.float stats_discharge_kills;       //
.float stats_gl_frac;               //
.float stats_gl_tot;                //
.float enemy_hurt_time;				// timestamp of when you last hurt an opponent.
.float ready_check_time;			// timestamp of when player last used ready? command

float stats_timelimit;
float stats_matchtype;

.float  csqc_enabled;

typedef struct 
{
	string	name;	// filename WITHOUT '.bsp'
	string	title;	// Welcome to Quake
	string	author; // John Romero
	// string	type;	// CTF, DM, CA, RA, DMM4
	// string	image;  // 'data/mapshots/mymap.tga'
	// float	size;	// 1v1, 2v2, 4v4, 8v8
}servermap_t;

#define WARP_CATEGORY_SIZE 50	// Change the value in server.qc: clanring_set_aliases, if you exceed 50
#define WARP_MAPLIST_SIZE 30	// Above 15 and most users have to scroll.

servermap_t warpmap[WARP_CATEGORY_SIZE * WARP_MAPLIST_SIZE];

string warpmenutop[WARP_CATEGORY_SIZE]; // Customizable map categories for the warp menu contents.
string vote_map_choices[6];

float map_choices[6];

string default_nextmap;

float MAX_CUSTOM_MATCH_SOUNDS = 20;	//Upped
float clanring_matchsound_count;
float clanring_matchsound_rematch_count;
float clanring_matchsound_blowout_count;

string matchsound[MAX_CUSTOM_MATCH_SOUNDS];
string matchsound_rematch[MAX_CUSTOM_MATCH_SOUNDS];
string matchsound_blowout[MAX_CUSTOM_MATCH_SOUNDS];

typedef struct
{
	string player;
	//string date;
	float teamcolor;
	float statvalue;
}playerrecord_t;

float PLAYER_RECORDS_MAX_COUNT = 3;
playerrecord_t playerrecord[PLAYER_RECORDS_MAX_COUNT];
playerrecord_t playerrecord2[PLAYER_RECORDS_MAX_COUNT];
float new_player_record;
float new_player_record_match;
float RECORD_LOW = 0;
float RECORD_HIGH = 1;

//Arena
entity boss;

.float dmg_given;
.float dmg_given_round;
.float dmg_cache;
.float ewep;
.float round;
.float max_rounds;
.float max_players;
.float start_players;
.float ca_player_flag;
.float airborn_pos;
.float killstreak;
.float combo_time;
.float combo_frags;

//PER stats
.float q1_per;
.float stats_teamkill_quad;
.float stats_powerup_denial_quad;
.float strategic_returns;  // Flag returns that lead to team captures
entity last_red_returner;
entity last_blue_returner;
float last_return_time;

.float fcarries_time;        // Seconds spent carrying enemy flag (non-camping)
.float flag_carry_start;     // When current carry started
.vector last_carry_pos;      // Last position while carrying (for camping detection)
.float last_pos_check;       // When we last checked position

.float busy;
.float aborted;
.float forced;
.float draw;
.float unpausing;
.float allready;
.float suddendeath;
.float timetofight;
.float maprecycle;
.float weaponlevel;
.float motd_delay;

.entity chain_gang;
.entity next_queue;
.float next_color;

.float team2;
.float wins;
.float losses;
.float cc_queue;
.float cc_queue_vote;

entity team_first_place;
entity team_second_place;
entity team_third_place;
entity ca_mvp_entity;

float clanring_rulescheck;
.float max_teams;
float ra_wins;
entity ra_lastspawn;
//float tele_num_spawns;
.float nextspawn;

float COLOR_BLUE = 13;
float COLOR_RED = 4;
float COLOR_YELLOW = 12;
float COLOR_GREEN = 3;

float TEAM_SPECTATOR 	= 0;
float TEAM_PRACTICE	= 16;
float TEAM_BLUE = 14;
float TEAM_RED = 5;
float TEAM_YELLOW = 13;
float TEAM_GREEN = 4;

float PF_WAITING = 1;
float PF_DEAD = 2;
float PF_READY = 3;
float PF_PLAYING = 4;

float CA_MATCH_WAITING = 1;
float CA_MATCH_ROUNDSTART = 2;
float CA_MATCH_PLAYING = 3;
float CA_MATCH_OVER = 4;
float CA_MATCH_CLEANUP = 5;
.float ca_deathcamtime;
.float arena_packs;
.float color2; //since we already have .vector color

// worldtype values
float	WORLDTYPE_MEDIEVAL		= 0;
float	WORLDTYPE_METAL			= 1;
float	WORLDTYPE_BASE			= 2;

// spawnflags for func_movewall
float	MOVEWALL_VISIBLE		= 1;
float	MOVEWALL_TOUCH			= 2;
float	MOVEWALL_NONBLOCKING	= 4;

.string		origmodel; // addition by bmFbr for switchable brushes

//
// support for item_key_custom -- iw
//
.string keyname;
.float customkeys;

.string target2;		// second target's name
.string target3;		// third target's name
.string target4;		// fourth target's name
.string targetname2;	// second name
.string targetname3;	// third name
.string targetname4;	// fourth name
.string killtarget2;	// second target to kill
string lastnameused;	// the targetname that was last used to trigger somthing

//
// switchable shadow
//
.float		switchshadstyle;
.float		shadowoff;
.entity shadowcontroller;
.float speed2;

.float is_waiting;	// Supa, triggers, wait until activated before we can trigger?

.string		mdl_debris; //dumptruck_ds

.float		onladder;

.float style2; //c0burn's switchable lights

string(float num) lightstyle_fade_lookup; //addition by bmFbr for switchable shadows
void() misc_shadowcontroller;
void() misc_shadowcontroller_use;
void() shadow_fade_in;
void() shadow_fade_out;

// from Custents
// variable for healing trigger
.float	heal_timer;
.float	heal_amount;
.float	health_max;
// Constants for the healing trigger
float HEAL_START_ON	= 1;
float HEAL_PLAYER_ONLY	= 2;
float HEAL_MONSTER_ONLY	= 4;

// Custom Monster Sounds START -- dumptruck_ds

.string snd_death;
.string snd_pain;
.string snd_sight;
.string snd_attack;
.string snd_hit;
.string snd_idle;
.string snd_land;
.string snd_move;
.string snd_misc;
.string snd_misc1;
.string snd_misc2;
.string snd_misc3;

// Custom Monster Sounds END -- dumptruck_ds

// Custom Model Start -- dumptruck_ds

.string mdl_head;
.string mdl_body;
.string mdl_proj;
.string mdl_exproj;
.float skin_head;
.float skin_proj;
.float skin_exproj;
.string mdl_gib1;
.string mdl_gib2;
.string mdl_gib3;

.vector mdlsz, centeroffset; // addition by bmFbr for custom model bounding box definition

// Custom Model End -- dumptruck_ds

.float drop_item; // key DropStuff

// entity state
.float estate;
.void() dormant_use;
float STATE_ACTIVE      = 0;
float STATE_INACTIVE    = 1;
float STATE_INVISIBLE = 8;

// worldspawn default mdls
.string h_vial_mdl;
.string a_shr_mdl;

float isFTEserver; //Is the server running on FTE or QSS/M?
string clanring_new_record_player;
float ra_initial_rules_shown; // RA: track if round-1 rules were already shown

.entity enemy_target;
#define INSTALLED_NEXTMAPS_LIMIT 200
string levels[INSTALLED_NEXTMAPS_LIMIT];//levels.cfg
//eof
