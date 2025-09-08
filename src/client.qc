/*
    client.qc

    client functions

    Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'gnu_gpl.txt', for details.
*/

// prototypes

void() player_pain;
void() PlayerDead;
void(entity client, float fragval) client_frag;
void(entity client) clear_afk_status;
void () client_afk_off;
void() quaketag_init;
void() votables_request_qwsucks;   // new: single-command toggle+auto-start
void() votables_request_q14ever;   // new: single-command toggle+auto-start
void () client_typing_on;
void () client_typing_off;

// Entity field declarations
.float just_suicided; // set briefly when a death is a self-kill/suicide

/*
=============================================================================

                LEVEL CHANGING / INTERMISSION

=============================================================================
*/

//float	intermission_running;  // ELOHIM_MOD - moved to elodefs.qc
//float	intermission_exittime; // ELOHIM_MOD - moved to elodefs.qc

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
    self.angles = self.mangle; // so C can get at it
};

/*
============
SetChangeParms

The server calls this function directly from the C code, when a 'changelevel' is issued.
============
*/

void() SetChangeParms =
{
    parm14 = (time - self.afk_time);	//AFK carries over
    parm15 = self.statstate;			//R00k settings carry over
    SetNewParms2 ();
};


//
// ELOHIM_MOD
//
// Created SetNewParms2 and changed all SetNewParms references to
// SetNewParms2.  SetNewParms is called by Quake.exe when a client
// first connects; SetNewParms2 is called thereafter by the QuakeC
// code every time the client is reinserted into the server (respawn,
// level change, etc.)
//
// Also created SetPracticeParms which is called for practice mode
//
void() SetPracticeParms =
{
    parm1 = IT_SHOTGUN | IT_AXE | IT_ROCKET_LAUNCHER | IT_ARMOR3 | IT_SUPER_SHOTGUN | IT_NAILGUN | IT_GRENADE_LAUNCHER | IT_LIGHTNING | IT_SUPER_NAILGUN;

    if (!(clanring_playmode & CLANRING_NO_HOOK))
        parm1 = parm1 | IT_HOOK;

    parm2 = 100;
    parm3 = 200;
    parm4 = 100;
    parm5 = 200;
    parm6 = 100;
    parm7 = 100;
    parm8 = IT_ROCKET_LAUNCHER;
    parm9 = 80.001;
};

//
//  Called by Quake server when a new client connects
//

void() SetNewParms =
{
    parm1 = parm2 = parm3 =	parm4 =	parm5 = parm6 =	parm7 = parm8 = parm9 =	0;//Clear out everything.

     if (clanring_playmode & CLANRING_PRACTICE_MODE)
    {
        SetPracticeParms ();
    }
    else
    {
        if (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))	//Deathmatch
        {
            parm1 = IT_SHOTGUN | IT_AXE;
            parm2 = 100;
            parm3 = 0;
            parm4 = 25;
            parm5 = 0;
            parm6 = 0;
            parm7 = 0;
            parm8 = IT_SHOTGUN;
            parm9 = 0;
        }
        else
        {
            parm1 = IT_SHOTGUN | IT_AXE | IT_HOOK | IT_ARMOR1;	//Capture the Flag
            parm2 = 100;
            parm3 = 50;
            parm4 = 25;
            parm5 = 0;
            parm6 = 0;
            parm7 = 0;
            parm8 = IT_SHOTGUN;
            parm9 = 30;
        }
    }

    if (!(clanring_playmode & CLANRING_NO_HOOK))//optional sethook
        parm1 = parm1 | IT_HOOK;

    parm10 = CLANRING_NEW_CLIENT | CLANRING_SMART_WEAPON; // CRMOD observer flags moved | ELOHIM_OBSERVER_WALK; // elohim player flags
    parm11 = 0;
    parm12 = OBSERVER_FLY;// CRMOD observer flags
    parm13 = 0;
};

//
//  Called by QuakeC to reset a clients parameters
//
void() SetNewParms2 =
{
    parm1 = parm2 = parm3 =	parm4 =	parm5 = parm6 =	parm7 = parm8 = parm9 =	0;//Clear out everything.

     if (clanring_playmode & CLANRING_PRACTICE_MODE)
    {
        SetPracticeParms ();
    }
    else if (mode_is_arena())
    {
        parm1 = boss.items;
        parm2 = boss.health;
        parm3 = boss.armorvalue;
        parm4 = boss.ammo_shells;
        parm5 = boss.ammo_nails;
        parm6 = boss.ammo_rockets;
        parm7 = boss.ammo_cells;
        parm8 = boss.weapon;
        parm9 = boss.armortype;

        if (!(clanring_playmode & CLANRING_NO_HOOK))
            parm1 = parm1 | IT_HOOK;
    }
    else
    {
        if ((clanring_playmode & CLANRING_MATCH_MODE) && (!(clanring_state & CLANRING_MATCH_STARTED)))	//R00k: prewar! (or whatever we call it) aka BOSHMODeA
        {
            SetPracticeParms ();
        }
        else
        {
            if (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))		//Deathmatch
            {
                parm1 = IT_SHOTGUN | IT_AXE;

                if (!(clanring_playmode & CLANRING_NO_HOOK))//someone voted for hook...
                    parm1 = parm1 | IT_HOOK;

                parm2 = 100;
                parm3 = 0;
                parm4 = 25;
                parm5 = 0;
                parm6 = 0;
                parm7 = 0;
                parm8 = IT_SHOTGUN;
                parm9 = 0;
            }
            else
            {
                parm1 = IT_SHOTGUN | IT_AXE | IT_HOOK | IT_ARMOR1;	//Capture the Flag
                parm2 = 100;
                parm3 = 50;
                parm4 = 25;
                parm5 = 0;
                parm6 = 0;
                parm7 = 0;
                parm8 = IT_SHOTGUN;
                parm9 = 30;
            }
        }
    }

    parm10 = self.style; // elohim player flags
    parm11 = self.state; // player ID
    parm12 = self.oflags; // CRMOD observer flags
    parm13 = self.clanring_hack_count;
    parm14 = (time - self.afk_time);	//AFK carries over
    parm15 = self.statstate;
};

void() DecodeLevelParms =
{
    //
    // ELOHIM_MOD
    //
    // First restore player elohim flags *then* check to see if level = start.
    // Also, reset player status at start level even if serverflags = 0.
    // Finally, reset status if fresh spawns are on.
    // Changed SetNewParms to SetNewParms2.
    self.style 					= parm10;
    self.state 					= parm11;
    self.oflags 				= parm12;  // CRMOD observer flags
    self.clanring_hack_count 	= parm13;
    self.afk_time 				= (time - parm14);
    self.statstate 				= parm15;

    self.player_flag = (self.player_flag - (self.player_flag & ITEM_RUNE_MASK));

    SetNewParms2 ();

    self.items					= parm1;
    self.items2      			= 0;
    self.health 				= parm2;
    self.armorvalue 			= parm3;
    self.ammo_shells 			= parm4;
    self.ammo_nails 			= parm5;
    self.ammo_rockets 			= parm6;
    self.ammo_cells 			= parm7;
    self.weapon 				= parm8;
    self.armortype 				= (parm9 * 0.01);
    self.last_returned_flag  	= -10;
    self.last_fragged_carrier 	= -10;
    self.flag_since           	= -10;
    self.last_hurt_carrier    	= -10;
    self.flag_carrier       	= 0;
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity () FindIntermission =
{
    local entity spot;
    local float cyc;

    // look for info_intermission first
    spot = find(world, classname, "info_intermission");
    if (spot)
    {   // pick a random one
        cyc = random () * 4;
        while (cyc > 1)
        {
            spot = find(spot, classname, "info_intermission");
            if (!spot)
                spot = find(spot, classname, "info_intermission");
            cyc = cyc - 1;
        }
        return spot;
    }
    // then look for the start position
    spot = find(world, classname, "info_player_start");
    if (spot)
        return spot;

    objerror ("FindIntermission: no spot");
    return world; //R00k added
};

void() GotoNextMap =
{
    if (nextmap == "")
    {
        clanring_nextlevel_config();

        if (nextmap == "")
        {
            nextmap = mapname;
            bprint("\nMap not found. Reloading Current Map...Please Wait.\n");
        }
    }
    changelevel (nextmap);
};

/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void ()VoteMenu_Print;

void() IntermissionThink =
{
    VoteMenu_Print();

    // Keep typing/AFK status synced during intermission
    check_client_status();

    if (self.button0 || self.button2) 								//Jump or fire to wake up
        client_afk_off();

    if ((self.impulse > 0) && (self.impulse < 6))
    {
        stuffcmd(self, "play buttons/switch04.wav\n");
        tokenize(vote_map_choices[self.impulse]);

        string myVoteMapName = strzone(argv(0));
        string myVoteMapTitle = strzone(redify(argv(1)));

        if ((self.warp_map) && ((self.warp_map) == self.impulse))
        {
            bprint(sprintf("%s \bREMOVED\b their vote for %s %s\n",self.netname, myVoteMapName, myVoteMapTitle));
            map_choices[self.warp_map] -= 1;
            self.warp_map = 0;
            self.impulse = 0;
            self.centerTime = 0;	//Update now.
            centerprint(self, VOTE_MENU_TEXTLINE[0], VOTE_MENU_TEXTLINE[1], VOTE_MENU_TEXTLINE[2], VOTE_MENU_TEXTLINE[3], VOTE_MENU_TEXTLINE[4], VOTE_MENU_TEXTLINE[5], VOTE_MENU_TEXTLINE[6]);
            return;
        }

        if ((self.warp_map) && ((self.warp_map) != self.impulse))
        {
            bprint(sprintf("%s \bREMOVED\b their vote for %s %s\n",self.netname, myVoteMapName, myVoteMapTitle));
            map_choices[self.warp_map] -= 1;
            self.warp_map = 0;
            centerprint(self, VOTE_MENU_TEXTLINE[0], VOTE_MENU_TEXTLINE[1], VOTE_MENU_TEXTLINE[2], VOTE_MENU_TEXTLINE[3], VOTE_MENU_TEXTLINE[4], VOTE_MENU_TEXTLINE[5], VOTE_MENU_TEXTLINE[6]);
        }

        self.warp_map = self.impulse;
        map_choices[self.warp_map] += 1;
        bprint(sprintf("%s voted for %s %s\n",self.netname, myVoteMapName, myVoteMapTitle));

        strunzone(myVoteMapName);
        strunzone(myVoteMapTitle);

//		if (clanring_gameconfig & CLANRING_VOTE_MAJORITY_PASS)
        {
            entity p = find(world, classname, "player");
            float c = 0;

            while (p != world)
            {
                c += 1;
                p = find (p, classname, "player");
            }

            for (float i = 1; i < 6; i++)
            {
                if (map_choices[i] >= map_choices[0])
                    map_choices[0] = map_choices[i];
            }
            //Check if we have a majority already...
            if (c && ((map_choices[0]) > (c * 0.5)))
            {
                sound (self, CHAN_AUTO, "misc/power.wav", 1, ATTN_NONE);
                intermission_exittime = time;
            }
        }

        self.centerTime = 0;	//Update now.
        self.impulse = 0;
    }
};

void() execute_changelevel =
{
    entity tmp;
    float prnd = 0;
//	local float bcount;

    intermission_running = 1;	// enforce a wait time before allowing changelevel
    intermission_exittime = time + 20;
    forceinfokey (world, "intermission","on");	//Notify everyone since we aren't send out the SVC_INTERMISSION anymore.
    pqc_match_time (0, 20);
    lightstyle(0, "f");// R00k: -added- dim light on intermission
/*
    WriteByte(MSG_ALL, SVC_CDTRACK);
    WriteByte(MSG_ALL, 3);
    WriteByte(MSG_ALL, 3);
*/
    if (clanring_gameconfig & CLANRING_ENABLE_MATCHSOUNDS)
    if (clanring_matchsound_count)
        prnd = floor(random() * clanring_matchsound_count);

    intermission_pos = FindIntermission ();
    clanring_angle = intermission_pos.mangle;
    other = find(world, classname, "player");
    while (other != world)
    {
//		bcount = bcount + 1;
        // Removed forced typing clear; allow status to persist and update during intermission

        setorigin(other, intermission_pos.origin);

        other.view_ofs 		= '0 0 0';
        other.v_angle 		= clanring_angle;
        other.angles 		= clanring_angle;
        other.fixangle 		= TRUE;
        other.nextthink 	= time + 0.5;
        other.takedamage 	= DAMAGE_NO;
        other.solid 		= SOLID_NOT;
        other.movetype 		= MOVETYPE_NONE;
        other.finaldest_y 	= MOVETYPE_NONE;
        other.modelindex 	= 0;
        other.model 		= "";
        other.weaponmodel 	= "";
        other.weapon 		= 0;
        other.items 		= 0;
        other.effects 		= 0;

        if (prnd)
        {
            stuffcmd(other, ";play ");
            stuffcmd(other, matchsound[prnd]);
            stuffcmd(other, ";\n");
        }
        tmp   = self;
        self  = other;
        teamplay_final_stats();//display score and stats
        self  = tmp;

        other = find(other, classname, "player");
    }
    //WriteByte(MSG_ALL, SVC_INTERMISSION);
};

void() pre_execute_changelevel =
{
    if (clanring_levelcount == -1)
        execute_changelevel ();
    else
        self.nextthink = time + 0.1;
};

void() changelevel_touch =
{
    if (clanring_playmode & CLANRING_MATCH_MODE)
        return;

    if (other.classname != "player")
        return;

    if (cvar("noexit"))
    {
        if (cvar ("noexit") == 2)
            T_Damage (other, self, self, 50000);
        return;
    }
    if (clanring_levelcount != -1)
    {
        if (self.enemy != other)
        {
            stuffcmd(other, "play misc/talk.wav\n");
            sprint(other, "Exits not yet activated\n");
        }
        self.enemy = other;
        return;
    }
    gameover = TRUE;
    announce2(other.netname, " exited the level");
    if (nextmap == "")
    {
        nextmap = self.map;
    }
    SUB_UseTargets ();
    self.touch = SUB_Null;
    self.think = pre_execute_changelevel;
    self.nextthink = (time + 0.1);
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
    if (!self.map)
    {
        objerror ("changelevel trigger doesn't have map");
    }
    InitTrigger ();
    self.touch = changelevel_touch;
};

/*
=============================================================================

                PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

void() set_suicide_frame;

//void(entity ent) CreateDeadBody;
// called by ClientKill and DeadThink
void() respawn =
{
//	if (!(clanring_gameconfig & CLANRING_DEADBODY_FILTER))
//	CreateDeadBody (self);//R00k new corpse routine.
    SetNewParms2 ();

    PutClientInServer ();
};
/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =
{
    if (IS_CA_OBSERVER(self))
        return;

    if (mode_is_arena())
    {
        // Allow kill for RA participants to escape getting stuck; keep disabled for other arena modes
        if (!(clanring_playmode & CLANRING_RA_MODE))
            return;

        // Disallow kill during countdown (before round is actually playing or while wait > 0)
        if ((boss.state != CA_MATCH_PLAYING) || (boss.wait > 0))
            return;
    }

    if (gameover)
        return;

    if (self.style & CLANRING_OBSERVER)
        return;

    if (clanring_state & CLANRING_MATCH_PAUSED)
    {
        sprint(self,"The match is paused; you cannot self-gib.");
        return;
    }

    if (clanring_client_suicide () == TRUE)
        return;

    announce2(self.netname, " suicides");

    if (clanring_gameconfig & CLANRING_POWERUP_DROP)
        powerup_drop();

    DropRune();

    // if (clanring_gameconfig & CLANRING_SUICIDE_BACKPACK)
    // if (!(clanring_playmode & CLANRING_PRACTICE_MODE) && !(mode_is_arena()))
    // {
    // 	DropBackpack();
    // }

    if ((clanring_playmode & CLANRING_MATCH_MODE)&&(!(clanring_state & CLANRING_MATCH_STARTED)))
        TeamCaptureDropFlagOfPlayer (self, 1);	//During Capture Time Trials (prematch); a suicide will return the flag back to base.
    else
        TeamCaptureDropFlagOfPlayer (self, 0);	//During a match or pickup mode, drop flag at origin of suicide.

    UnHookPlayer();
    self.hook2 = (self.hook2 - (self.hook2 & HOOK_OUT));//added for server mod hook
    self.modelindex = modelindex_player;

    set_suicide_frame();

    // In Rocket Arena, treat kill as a round death without auto-respawn
    if ((mode_is_arena()) && (clanring_playmode & CLANRING_RA_MODE))
    {
        self.health = 0;
        self.ca_player_flag = PF_DEAD;
        self.nextthink = -1;
        self.think = SUB_Null;
    }

    // ELOHIM_MOD
    //
    // - use client_frag so that penalty will be added to team score
    // - changed penalty to -1
    // - no penalty during pre-match
    // - add suicide to stats
    //
    //self.frags = self.frags - 2;    // extra penalty

    if (!(clanring_playmode & CLANRING_MATCH_MODE) || clanring_state & CLANRING_MATCH_STARTED)
    {
        self.just_suicided = time;
        client_frag(self, -1);
        self.just_suicided = 0;
        self.mangle_x = self.mangle_x + 1;
    }

    if (self.items & IT_ROCKET_LAUNCHER)
    {
        quaketv_lost_rl (self);
    }

    // ELOHIM_MOD
    // check for not-ready non-observers in match mode
    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        if (!(self.style & (CLANRING_READY | CLANRING_OBSERVER)))
        {
            self.style = self.style | CLANRING_READY;
            respawn();
            self.style = self.style - CLANRING_READY;
            return;
        }
    }
    respawn();
};

entity () TeamCaptureSpawn =
{
    local entity checkmap = world;

    //Test if the map has ctf spawnpoints, in case we are in CTF mode and on a TDM map.
    checkmap = find(world, classname, "info_player_team1");
    if (checkmap == world)
    {
        team1_lastspawn = find(team1_lastspawn, classname, "info_player_deathmatch");
        return team1_lastspawn;
    }

    if ((self.team == RED) && (self.style & CLANRING_RED_TEAM))
    {
        team1_lastspawn = find(team1_lastspawn, classname, "info_player_team1");
        if (team1_lastspawn == world)
        {
            team1_lastspawn = find(team1_lastspawn, classname, "info_player_team1");
        }
        return team1_lastspawn;
    }
    else
    {
        if ((self.team == BLUE) && (self.style & CLANRING_BLUE_TEAM))
        {
            team2_lastspawn = find(team2_lastspawn, classname, "info_player_team2");
            if (team2_lastspawn == world)
            {
                team2_lastspawn = find(team2_lastspawn, classname, "info_player_team2");
            }
            return team2_lastspawn;
        }
    }
    team2_lastspawn = find(team2_lastspawn, classname, "info_player_start");
    return team2_lastspawn;
};

// S p o t  N e a r  B a d  O r i g i n
// Find if 'sp' is near where we last died or where we last spawned.
float (vector sp) SpotNearBadOrigin =
{
    float d = vlen(sp - self.deathorigin);	// Distance to the Last place of death.

    if (d < 32)
    {
    //	sprint(self, "spot near death origin.\n");
        return TRUE;
    }

    d = vlen(sp - self.trigger_field.origin);	// Distance to the Last place spawned.

    if (d < 32)
    {
    //	sprint(self, "spot near last spawn.\n");
        return TRUE;
    }
    //sprint(self, "spawnpoint clear.\n");
    return FALSE;
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity () SelectSpawnPoint =
{
    local entity spot;
    local entity thing;
    local float	pcount;
    local float	loop_count;

    spot = find(world, classname, "info_player_deathmatch");
    if (spot == world)
        objerror ("Can not find an 'info_player_deathmatch' spawnpoint on this map!");

    if ((self.killed == FALSE) && (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (!(self.style & CLANRING_OBSERVER)) && (!(clanring_playmode & CLANRING_PRACTICE_MODE)))
    {
        spot = TeamCaptureSpawn();
        if (spot.classname == "info_player_deathmatch")
        {
            sprint(self, "\bMap currently has no CTF Team spawnpoints; select another map.\b\n");
        }
        return spot;
    }

    if (clanring_gameconfig & CLANRING_SEQUENTIAL_SPAWNS)
    {
        spot = find(lastspawn, classname, "info_player_deathmatch");
        if (spot == world)
            spot = find(spot, classname, "info_player_deathmatch");
        lastspawn = spot;
        return spot;
    }

    loop_count = 64;//crash test

    pcount = random() * (dm_num_spawns - 0.001);
    pcount = floor(pcount);

    spot = world;	//Start from the beginning...

    while (pcount > 0)
    {
        spot = find(spot, classname, "info_player_deathmatch");

        if (spot != world)
            pcount = pcount - 1;
    }

    while (loop_count)
    {
        spot = find(spot, classname, "info_player_deathmatch");
        loop_count -= 1; //testing...

        if ((spot == world)||(SpotNearBadOrigin(spot.origin)))//check if this is where we last spawned or just died
            pcount = 1;
        else
        {	// SPAWNFRAG_PROTECTION: dont pick a spawnpoint that will telefrag any player -- BEGIN
            //if (clanring_gameconfig & CLANRING_SPAWNFRAG_PROTECTION)//TODO only protect spawns at match start.
            {
                thing = findradius (spot.origin, 128);
                while (thing)
                {
                    if (((thing.classname == "player") && (thing.style & CLANRING_CONNECTED)) && (!(thing.style & CLANRING_OBSERVER)) && (thing.health))//r00k: added .health
                    {
                        pcount = 1;
                        thing = world;
                    }
                    else
                    {
                        thing = thing.chain;
                    }
                }
            }
        }
        if (pcount == 0)
            return spot;
        pcount = 0;
    }

    if (serverflags)
    {
        spot = find(world, classname, "info_player_start2");
        if (spot)
            return spot;
    }
    spot = find(world, classname, "info_player_start");
    if (!spot)
    {
        error ("PutClientInServer: no info_player_start on level");
    }
    return spot;
};

/*
================
by: Philip Martin aka: Kryten
When on top of monsters or players you slide. This is a QuakeC problem.
The function below fixes that problem.
based on code given to Kryten by: Michael Turitzin (MaNiAc)
================
*/
void() player_touch =
{
    //can cause problems for monsters on top of a player,  so only players
    if (other.classname != "player")
        return;

    if (other.health <= 0)
        return;

    if ((!(other.flags & FL_ONGROUND)) && (other.absmin_z >= self.absmax_z - 2))
        other.flags = other.flags | FL_ONGROUND;

    //you can add other stuff like pushable players/monsters here
};
// 1998-09-16 Sliding/not-jumping on monsters/boxes/players fix

void(entity e) move_to_intermission =
{
    e.view_ofs 	= VEC_ORIGIN;
    e.angles 	= e.v_angle = intermission_pos.mangle;
    e.fixangle 	= TRUE;		// turn this way immediately
    e.nextthink = time + 0.5;
    setorigin(e, intermission_pos.origin);

    e.takedamage 	= DAMAGE_NO;
    e.solid 		= SOLID_NOT;
    e.movetype 		= MOVETYPE_NONE;
    e.finaldest_y 	= MOVETYPE_NONE;
    e.modelindex 	= 0;
    e.weaponmodel 	= string_null;
};

void() utils_dprint_time;
void() PlayerDie;
void() teamplay_force_player_ready;

/*
===========
PutClientInServer

called each time a player is spawned
============
*/
void() PutClientInServer =
{
    local entity spot = world;

    //R00k: when the player presses TAB the client should request pings (removed Sept '24)
    //  if (clanring_playmode & CLANRING_MATCH_MODE)
    // {
	// 	if (!(clanring_state & CLANRING_MATCH_STARTED))
    //     {
    //         if ((self.client == "Quake"))//||(self.client == "QSS-M")) //not ezq, fte, qss
    //             pqc_ping_times();
    //     }
    // }

    DecodeLevelParms ();

    if (self.style & CLANRING_CONNECTED)
    {
        if (!(self.style & CLANRING_AFK_CLIENT))
            clear_name(); //R00k: workaround for qss server losing userinfo
        else
            afk_name();
    }

    //in classic mode auto join on connect
    if (teamplay)
    {
        if (clanring_playmode & CLANRING_NORMAL_MODE)/* && (clanring_playmode & CLANRING_CAPTURE_THE_FLAG))*///Pub team Deathmatch
        {
            if  ((!(self.style & CLANRING_BLUE_TEAM)) && (!(self.style & CLANRING_RED_TEAM)) && (!(self.style & CLANRING_OBSERVER)))
            {
                utils_make_scheduled_event(teamplay_force_player_ready, 1);//R00k: changed from 0.05 to 1, give them time to establish connection.
                return;
            }
        }
    }

    if (mode_is_arena())
    {
        if ((ra_map()) && ((self.ca_player_flag == PF_READY) || (self.ca_player_flag == PF_PLAYING)))
        {
            //spot = find(spot, classname, "info_teleport_destination");
            spot = SelectRASpawnPoint();
        }
/*		else if ((clanring_playmode & CLANRING_WIPEOUT_MODE) && (self.next_team != world) && (self.rounddeaths > 0))
        {
        //TODO: spawn near team ?
        // spot = SelectWipeoutSpawnPoint();
        //  if (spot == world)
                spot = SelectSpawnPoint();
        }*/
        else
        {
            spot = SelectSpawnPoint();
        }
    }
    else
    {
        spot = SelectSpawnPoint();
    }

    if (spot == world)
    {
        sprint(self, "Finding a better spawnpoint...\n");
        spot = SelectSpawnPoint();
    }

    self.trigger_field			= spot;	// Our last spawn point.

    if (clanring_playmode & CLANRING_AIRSHOT_MODE)
         spot.origin = airshot_droptofloor(spot);

    self.classname 				= "player";
    self.health 				= 100;
    self.takedamage 			= DAMAGE_AIM;
    // Set solidity based on leavemealone flag
    if (self.leavemealone)
        self.solid = SOLID_TRIGGER;
    else
        self.solid = SOLID_SLIDEBOX;
    self.movetype 				= MOVETYPE_WALK;
    self.finaldest_y 			= MOVETYPE_WALK;
    self.show_hostile 			= 0;
    self.max_health 			= 100;
    self.flags					= FL_CLIENT;
    self.air_finished			= time + 12;
    self.dmg 					= 2;
    self.super_damage_finished 	= 0;
    self.radsuit_finished 		= 0;
    self.invisible_finished 	= 0;
    self.invincible_finished 	= 0;
    self.effects 				= 0;
    self.regen_time   			= 0;
    self.invincible_time 		= 0;
    self.watertype 				= CONTENT_EMPTY;
    self.waterlevel 			= 0;
    self.velocity 				= '0 0 0';
    self.killstreak				= 0;
    self.combo_frags 			= 0;
    self.combo_time 			= 0;
    self.enemy					= world;	//who shot/killed us
    self.enemy_target			= world;	//who we last shot/killed

    if ((clanring_playmode & CLANRING_DMM4_MODE) || (clanring_playmode & CLANRING_AIRSHOT_MODE))
    {
        if ((self.ca_player_flag == PF_PLAYING) && (boss.state == CA_MATCH_PLAYING) && (boss.wait == 0))
        {
            self.health = 250;
            self.max_health = 250;

            self.invincible_finished 	= time + 2;
            self.invincible_time 		= 1;
            self.effects = self.effects | EF_DIMLIGHT;
            self.effects = self.effects | EF_RED;
        }
    }

    W_SetCurrentAmmo();

    self.attack_finished 	= time;
    //Todo enable this with a votable so dm2's quad team-boost works
    //self.touch 			= player_touch;
    self.th_pain 			= player_pain;
    self.th_die 			= PlayerDie;
    self.deadflag 			= DEAD_NO;
    //self.angles 			= spot.angles;
    //self.fixangle 		= TRUE;
    angles_fixangle(spot.angles);

    self.avelocity 		= '0 0 0';
    self.punchangle		= '0 0 0';
         
    self.origin = self.oldorigin = spot.origin; //R00k: update oldorigin so we dont respawn where we died.
    setorigin(self, spot.origin);	    //R00k: change our origin and relink our edict.
    
    self.lefty 		= 0;
    self.jump_flag 	= 0; // clear jump velocity to prevent falling damage

    // oh, this is a hack!
    if (modelindex_eyes == 0) //R00k: hasn't been done yet
    {
        setmodel (self, "progs/eyes.mdl");
        modelindex_eyes = self.modelindex;

        setmodel (self, "progs/h_player.mdl");
        modelindex_head = self.modelindex;
    }

    setmodel(self, "progs/player.mdl");
    modelindex_player = self.modelindex;

    setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

    self.view_ofs = '0 0 22';

    if (intermission_running)
    {
        move_to_intermission (self);
    }
    else
    {
        clanring_put_client_in_server ();
    }
};

/*
=============================================================================

QUAKED FUNCTIONS

=============================================================================
*/


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 =
{
};


/*
saved out by quaked in region mode
*/
void() testplayerstart =
{
};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch =
{
    dm_num_spawns = dm_num_spawns + 1.00;
    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        self.mdl = "progs/player.mdl";
        self.frame = 6;
        self.alpha = 0.4;
        spawns_restore_model();
    }
};

void() info_player_team1 =
{
    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        self.mdl = "progs/player.mdl";
        self.frame = 139;
        self.alpha = 0.4;
        self.skin = 1;
        spawns_restore_model();
    }
};

void() info_player_team2 =
{
    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        self.mdl = "progs/player.mdl";
        self.frame = 119;
        self.alpha = 0.4;
        self.skin = 3;
        spawns_restore_model();
    }
};
/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop =
{
    remove(self);   // ELOHIM_MOD - coop not supported
};

/*
===============================================================================

RULES

===============================================================================
*/

//
// CLANRING_MOD
//
// Fixed the bug that causes the start level to loop.  Changed the sequence
// of levels to:
//
// start->episode1->start->episode2->start->episode3->start->episode4->
// start->end->deathmatch->deathmatch->deathmatch->deathmatch->start
//
// (one big loop.. first start = last start).
// (of course, deathmatch = dm1->dm2->dm3->dm4->dm5->dm6)
//
// Included the Underearth in episode 2, but NOT Ziggurat Vertigo in e1.
//

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void() NextLevel =
{
    local entity o = world;

    o = spawn();

    if (clanring_levelcount != -1) //if levels.cfg wasnt found, fallback
    {
        if (mapname == "start")
        {
            if (!cvar("registered"))
            {
                mapname = "e1m1";
            }
            else if (!(serverflags & 1))
            {
                mapname = "e1m1";
                serverflags = serverflags | 1;
            }
            else if (!(serverflags & 2))
            {
                mapname = "e2m1";
                serverflags = serverflags | 2;
            }
            else if (!(serverflags & 4))
            {
                mapname = "e3m1";
                serverflags = serverflags | 4;
            }
            else if (!(serverflags & 8))
            {
                mapname = "e4m1";
                serverflags = serverflags | 8;
            }
            else
                mapname = "end";

            o.map = mapname;
        }
        else if (mapname == "end")
        {
            o.map = "dm1";
        }
        else if (mapname == "dm6")
        {
            serverflags = (serverflags & 14) / 2;
            if (serverflags > 0)
                o.map = "dm1";
            else
                o.map = "start";
        }
        else if (mapname == "e2m3")
        {
            o.map = "e2m7";
        }
        else
        {
            // find a trigger changelevel
            o = find(world, classname, "trigger_changelevel");

            // go back to start if no trigger_changelevel
            if (!o)
            {
                mapname = "start";

                o.map = mapname;
            }
        }
        if (nextmap != "") strunzone(nextmap);
        if (o.map != string_null) //just in case.
            nextmap = strzone(o.map);
    }

    if (clanring_playmode & CLANRING_RA_MODE)
    if (nextmap == "")							//If there is no -ra- section in their levels.cfg, grab a known hardcoded map.
        nextmap = strzone(ra_get_next_map());

    gameover = TRUE;

    o.think = execute_changelevel;
    o.nextthink = time + 0.1;
};
// END_MOD

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
// CLANRING_MOD - this function was removed for efficiency

//============================================================================
void() PlayerDeathThink =
{
    local float forward;

    if (self.flags & FL_ONGROUND)
    {
        forward = vlen(self.velocity);
        forward = forward - 20;
        if (forward <= 0)
            self.velocity = '0 0 0';
        else
            self.velocity = forward * normalize(self.velocity);
    }

    if (mode_is_arena())
    {
        local vector angle = '0 0 0';

        //R00k 1.55 look at enemy when dead
        if ((self.enemy.classname == "player") && (self.enemy != self))
        {
            if (time < self.ca_deathcamtime)
            {
                if (self.enemy.ca_player_flag == PF_PLAYING)
                {
                    makevectors (self.v_angle);
                    traceline (self.origin, self.enemy.origin, TRUE, self.enemy);
                    if (trace_fraction == 1)
                    {
                        angle = angles_bestaim (self.origin, self.enemy.origin);
                        angles_fixangle (angle);
                    }
                }
            }
        }

        if (!(clanring_playmode & CLANRING_WIPEOUT_MODE) || ((clanring_playmode & CLANRING_WIPEOUT_MODE) && (boss.wait > 0)))
            return;
    }
    // wait for all buttons released
    if (self.deadflag == DEAD_DEAD)
    {
        if (self.button2 || self.button1 || self.button0)
            return;

        self.deadflag = DEAD_RESPAWNABLE;
        return;
    }

    // wait for any button down
    if (!self.button2 && !self.button1 && !self.button0)
        return;
    clear_afk_status(self);								//R00k:
    self.button0 = self.button1 = self.button2 = 0;
    respawn();
};

void() PlayerJump =
{
    if (self.flags & FL_WATERJUMP)
        return;

    if (self.waterlevel >= 2)
    {
        if (self.watertype == CONTENT_WATER)
            self.velocity_z = 100;
        else if (self.watertype == CONTENT_SLIME)
            self.velocity_z = 80;
        else
            self.velocity_z = 50;

// play swiming sound
        if (self.swim_flag < time)
        {
            self.swim_flag = time + 1;
            if (random() < 0.5)
                sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
            else
                sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
        }
        return;
    }

    if (!(self.flags & FL_ONGROUND))
        return;

    if (!(self.flags & FL_JUMPRELEASED))
        return;		// don't pogo stick

    //self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
    //self.flags = self.flags - FL_ONGROUND;	// don't stairwalk
    //CRMOD - this is more efficient
    self.flags = self.flags - (self.flags & (FL_JUMPRELEASED | FL_ONGROUND));//
    self.finaldest_x = time;  // CRMOD - player is alive
    clear_afk_status(self);								//R00k:
    self.button2 = 0;
// player jumping sound
    sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
    self.velocity_z = self.velocity_z + 270;
};


/*
===========
WaterMove

============
*/
.float dmgtime;

void() WaterMove =
{
    // ELOHIM_MOD - if !self.waterlevel then FL_INWATER must be set
    // or this wouldn't be called.  Moved this test to the start of
    // the function.

    if (!self.waterlevel)
    {
        sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
        self.flags = self.flags - (self.flags & FL_INWATER);
        return;
    }
    // END_MOD

    if (!(self.flags & FL_INWATER))  // ELOHIM_MOD - moved this test
    {
        // player enter water sound
        if (self.watertype == CONTENT_LAVA)
            sound (self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);

        if (self.watertype == CONTENT_WATER)
            sound (self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);

        if (self.watertype == CONTENT_SLIME)
            sound (self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);

        self.flags = self.flags | FL_INWATER;
        self.dmgtime = 0;
        // ELOHIM_MOD - added these
        self.air_finished = time + 12;
        self.dmg = 2;
    }
    if (self.waterlevel != 3)
    {
        if (self.air_finished < time)
            sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
        else
        if (self.air_finished < time + 9)
            sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);

        self.air_finished = time + 12;
        self.dmg = 2;
    }
    else
    if (self.air_finished < time)
    {	// drown!
        if (self.pain_finished < time)
        {
            self.dmg = self.dmg + 2;
            if (self.dmg > 15)
                self.dmg = 10;
            self.deathtype = "drowning";	// 1998-08-12 optional: Drowning doesn't hurt armor by Maddes/Athos
            T_Damage (self, world, world, self.dmg);
            self.pain_finished = time + 1;
        }
    }
    else if (mode_is_arena())
    {
        if ((boss.state == CA_MATCH_ROUNDSTART) && (self.waterlevel == 3))
        {
                self.air_finished = time + 12;	//R00k: This resets the air_finished if you went and hid in water before round starts.
        }
    }

    if (self.watertype == CONTENT_LAVA)
    {	// do damage
        if (self.dmgtime < time)
        {
            if (self.radsuit_finished > time)
                self.dmgtime = time + 1;
            else
                self.dmgtime = time + 0.2;
            T_Damage (self, world, world, 10 * self.waterlevel);
        }
    }
    else
    if (self.watertype == CONTENT_SLIME)
    {	// do damage
        if ((self.dmgtime < time) && (self.radsuit_finished < time))
        {
            self.dmgtime = time + 1;
            T_Damage (self, world, world, 4 * self.waterlevel);
        }
    }
    // ELOHIM_MOD - rearranged expression for efficiency
    if (! (self.flags & FL_WATERJUMP) )
    self.velocity = (1 - 0.8*self.waterlevel*frametime)*self.velocity;
    // END_MOD
    // ELOHIM_MOD - moved here from PlayerPreThink
    if (self.waterlevel == 2)
        CheckWaterJump ();
    // END_MOD
};

void() CheckWaterJump =
{
    local vector start, end;

// check for a jump-out-of-water
    makevectors (self.angles);
    start = self.origin;
    start_z = start_z + 8;
    v_forward_z = 0;
    normalize(v_forward);
    end = start + v_forward * 24;
    traceline (start, end, TRUE, self);
    if (trace_fraction < 1)// solid at waist
    {
        // ELOHIM_MOD - changed these two lines
        start_z = start_z + 24;
        end_z = end_z + 24;
        traceline (start, end, TRUE, self);
        if (trace_fraction == 1)
        {	// open at eye level
            self.flags = self.flags | FL_WATERJUMP;
            self.velocity_z = 225;
            self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
            self.teleport_time = time + 2;	// safety net - DON'T TOUCH!!! USED BY QUAKE.EXE
            // return; ELOHIM_MOD - unnecessary
        }
    }
};

/*
================
PlayerPreThink

Called every frame before physics are run
================
*/

void() PlayerPreThink =
{
    // ELOHIM_MOD
    //
    // - moved intermission_running test inside of if (gameover)
    // - go to observer_pre_think when observing
    // - go to options_pre_think when setting options
    // - changed gameover test from (self.view_ofs == '0 0 0') to (gameover)
    // - don't call check rules
    //      - fraglimit, timelimit are set in elohim_start_frame
    //      - timelimit is checked in elohim_start_frame
    //      - fraglimit is checked in client_frag
    // - removed unnecessary makevectors
    // - put dead checks inside a single if statement
    // - removed unused pausetime check
    // - optimized ammo-out check
    // - do periodic checks
    // - moved CheckWaterJump to WaterMove

    if (gameover)
    {
        self.style = (self.style | CLANRING_NO_POST_THINK);
        if (intermission_running)
        {
            // otherwise a button could be missed between the think tics
            IntermissionThink ();
        }
        return;		// intermission or finale
    }

    if (!(clanring_playmode & CLANRING_PRACTICE_MODE) && !(mode_is_arena()))
    if (self.height != self.team - 1)
        match_verify_team ();

//	if (self.movetype != self.finaldest_y) // dork used admin 0 noclip or fly (R00k: CL_PRIVILEGED was removed is this still needed?)
//		self.movetype = self.finaldest_y;

    if (time > self.wait)
    {
        clanring_periodic_checks ();
        self.wait = time + 1;
    }

    if (self.style & CLANRING_SETTING_OPTIONS)
    {
        self.style = self.style | CLANRING_NO_POST_THINK;
        options_pre_think ();
        if (clanring_state & CLANRING_MATCH_PAUSED)
            self.velocity = '0 0 0';

        if (self.deadflag == DEAD_NO)
        {
            if (self.waterlevel || (self.flags & FL_INWATER))
                WaterMove ();
        }
        return;
    }

    if (self.style & CLANRING_OBSERVER)
    {
        observer_pre_think ();
        return;
    }

    if (self.deadflag)
    {
        self.style = self.style | CLANRING_NO_POST_THINK;
        if (self.deadflag >= DEAD_DEAD)
            PlayerDeathThink ();
        return;
    }
    if (clanring_state & CLANRING_MATCH_PAUSED)
    {
        self.style = self.style | CLANRING_NO_POST_THINK;
        self.velocity = '0 0 0';
        self.movement = '0 0 0';//FIXME?
        return;
    }

    self.deathtype = "";	//R00k - wrong obituary messages fix by Zoid

    if (self.waterlevel || (self.flags & FL_INWATER))
        WaterMove ();

    if (self.deadflag == DEAD_DYING) return;	// dying, so do nothing

    if (self.button2)
        PlayerJump ();
    else
        self.flags = self.flags | FL_JUMPRELEASED;

/*    if (!self.currentammo)
    {
        if ((self.weapon != IT_AXE) && (self.weapon != IT_HOOK))
        {
            if (time > self.attack_finished)
            {
                self.weapon = W_BestWeapon();
                W_SetCurrentAmmo();
            }
        }
    }*/

    // Keep bbox and link sane while intangible
    if (self.leavemealone)
    {
        if ((self.mins_x == 0) || (self.mins_y == 0))
            setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);

        if (self.solid != SOLID_TRIGGER)
            self.solid = SOLID_TRIGGER;

        setorigin(self, self.origin); // relink to avoid world hull squash
    }
};

//R00k: Silly function for practice mode when an admin get pent
void() admin_pushplayers =
{
    local entity guy;
    local vector direc;
    local float dist;

    guy = findradius(self.origin, 100);

    while(guy)
    {
        //if (guy.flags & FL_CLIENT)//removing this will also deflect projectiles
        {
            if (vlen(guy.origin - self.origin) < 100)
            {
                direc = normalize(guy.origin - self.origin);
                dist = (100 - (	vlen(guy.origin - self.origin)) );
                guy.velocity = guy.velocity + direc * dist * 16;
                self.velocity = self.velocity - direc * dist;
            }
        }
        guy = guy.chain;
    }
};

/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{
// invisibility
    if (self.invisible_finished)
    {
        // R00k remove powerups in "real-time"
        if (clanring_playmode & CLANRING_NO_RING)
        {
            self.items = self.items - (self.items & IT_INVISIBILITY);
            self.invisible_finished = 0;
            self.invisible_time = 0;
            self.modelindex = modelindex_player;
            setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
            player_run();

            if (clanring_playmode & CLANRING_MATCH_MODE)
            {
                if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
                {
                    if (self.team == RED)   self.skin = 1;
                    if (self.team == BLUE)  self.skin = 3;
                }
            }
        }// end
        else
        {
            if (self.invisible_sound < time)
            {
                sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
                self.invisible_sound = time + ((random() * 3) + 1);
            }
            if (self.invisible_finished < time + 3)
            {
                if (self.invisible_time == 1)
                {
                    sprint(self, "Ring of Shadows magic is fading\n");
                    stuffcmd(self, "bf\n");
                    sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
                    self.invisible_time = time + 1;
                }
                if (self.invisible_time < time)
                {
                    self.invisible_time = time + 1;
                    stuffcmd(self, "bf\n");
                }
            }

            // use the eyes
            self.frame = 0;
            if (self.skin == 0)//wait one frame to reset the skin
            {
                self.modelindex	= modelindex_eyes;
                setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
            }
            self.skin  = 0;//R00k: oversight 3wave forgot to reset the skin; engine complains about this during execution. :(

            if (self.invisible_finished < time)
            {	// just stopped
                self.items = self.items - (self.items & IT_INVISIBILITY);
                self.invisible_finished = 0;
                self.invisible_time = 0;
                self.modelindex = modelindex_player;	// don't use eyes
                setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
                player_run();

                if (clanring_playmode & CLANRING_MATCH_MODE)
                {
                    if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
                    {
                        if (self.team == RED)   self.skin = 1;
                        if (self.team == BLUE)  self.skin = 3;
                    }
                }
            }
        }
    }
    if (self.invincible_finished)
    {
        // R00k remove powerups in "real-time"
        if (clanring_playmode & CLANRING_NO_PENT)
        {
            self.items = self.items - (self.items & IT_INVULNERABILITY);
            self.invincible_time = 0;
            self.invincible_finished = 0;
            if (!self.super_damage_finished)
                self.effects = self.effects - (self.effects & EF_DIMLIGHT);
            self.effects = self.effects - (self.effects & EF_RED);
        }// end
        else
        {
            if ((self.style & CLANRING_ADMINISTRATOR)&&(clanring_playmode & CLANRING_PRACTICE_MODE))
                admin_pushplayers();

            if (self.invincible_finished < time + 3)
            {
                if (self.invincible_time == 1)
                {
                    if (!(clanring_playmode & CLANRING_DMM4_MODE) && !(clanring_playmode & CLANRING_AIRSHOT_MODE))
                        sprint(self, "Protection is almost burned out\n");
                    stuffcmd(self, "bf\n");
                    sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
                    self.invincible_time = time + 1;
                }
                if (self.invincible_time < time)
                {
                    self.invincible_time = time + 1;
                    stuffcmd(self, "bf\n");
                }
            }
            if (self.invincible_finished < time)
            {
                self.items = self.items - (self.items & IT_INVULNERABILITY);
                self.invincible_time = 0;
                self.invincible_finished = 0;
                if (!self.super_damage_finished)
                    self.effects = self.effects - (self.effects & EF_DIMLIGHT);
                self.effects = self.effects - (self.effects & EF_RED);
            }
        }
    }
    if (self.super_damage_finished)
    {
        // R00k remove powerups in "real-time"
        if (clanring_playmode & CLANRING_NO_QUAD)
        {
            self.items = self.items - (self.items & IT_QUAD);
            self.super_damage_finished = 0;
            self.super_time = 0;
            if (!self.invincible_finished)
            {
                self.effects = self.effects - (self.effects & EF_DIMLIGHT);
            }
            self.effects = self.effects - (self.effects & EF_BLUE);
            return;
        }// end
        else
        {
            if (self.super_damage_finished < time + 3)
            {
                if (self.super_time == 1)
                {
                    if (!(clanring_playmode & CLANRING_AIRSHOT_MODE))
                        sprint(self, "Quad Damage is wearing off\n");
                    stuffcmd(self, "bf\n");
                    sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
                    self.super_time = time + 1;
                }
                if (self.super_time < time)
                {
                    self.super_time = time + 1;
                    stuffcmd(self, "bf\n");
                }
            }
            if (self.super_damage_finished < time)
            {
                self.items = self.items - (self.items & IT_QUAD);
                self.super_damage_finished = 0;
                self.super_time = 0;
                self.totalquad += (time - self.quadtime);
                if (!self.invincible_finished)
                {
                    self.effects = self.effects - (self.effects & EF_DIMLIGHT);
                }
                self.effects = self.effects - (self.effects & EF_BLUE);

                if (clanring_playmode & CLANRING_AIRSHOT_MODE)
                {
                    new_player_record = 0;
                    check_player_high_record(self.killstreak, self.team2, self.netname);
                    if (new_player_record > 0)
                    {
                        if (new_player_record == 1)
                        {
                            bprint(self.netname);
                            bprint(" set the new \bair-gib streak\b\n");
                            sound (self, CHAN_VOICE, "crx/hiscore.wav", 1, ATTN_NORM);
                        }
                        write_airshot_streak_stats();
                    }

                    //since player should always get quad after frag, check limit here to let juggling continue
                    if (((fraglimit) && (self.frags >= fraglimit)) || (boss.suddendeath == TRUE))
                    {
                        boss.busy = TRUE;
                        gameover = TRUE;
                        match_show_timelimit();
                        arena_match_end();
                    }
                }
            }
        }
    }
    if (self.radsuit_finished)
    {
        self.air_finished = time + 12;
        if (self.radsuit_finished < (time + 3))
        {
            if (self.rad_time == 1)
            {
                sprint(self, "Air supply in Biosuit expiring\n");
                stuffcmd(self, "bf\n");
                sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
                self.rad_time = time + 1;
            }
            if (self.rad_time < time)
            {
                self.rad_time = time + 1;
                stuffcmd(self, "bf\n");
            }
        }
        if (self.radsuit_finished < time)
        {
            self.items = self.items - (self.items & IT_SUIT);
            self.rad_time = 0;
            self.radsuit_finished = 0;
        }
    }

    //R00k: Multiple megahealth rot fix
    if ((self.items & IT_SUPERHEALTH) && (time > self.rotthink))
    {
        if (self.health > self.max_health)
        {
            if ((self.invincible_finished < time) && !(self.player_flag & ITEM_RUNE4_FLAG))//dont rot with regen
            {
                self.health = (self.health - 1.00);
                self.rotthink = (time + 1.00);
            }
        }
        else
        {
            self.items = self.items - (self.items & IT_SUPERHEALTH);
        }
    }
};

void () CheckCombos =
{
    //local float rnum;
    if ((self.combo_time) && (time > (self.combo_time + 1)))
    {
        if (self.combo_frags > 1)
        {
            bprint3("\x90", ftos(self.combo_frags), "-kill combo\x91\n");
            //no more sounds here
        }

        self.combo_time = 0;
        self.combo_frags = 0;
    }
}

.float jump_time;
float FL_BHOP	= 8192; // R00k: flag when the player bunnyhops (basically 200ms between off-ground -> on-ground -> off-ground)

/*
===============================================================
TeamsBalancedWithMinimum

Returns TRUE when the two active teams have an equal number
of non-observer players and that number is >= minplayers.
===============================================================
*/
float(float minplayers) TeamsBalancedWithMinimum =
{
    local float redcount, bluecount;
    local entity p;

    redcount  = 0;
    bluecount = 0;

    for (p = world; (p = find(p, classname, "player")); )
    {
        // skip dead bodies and spectators
        if (p.health <= 0 || (p.style & CLANRING_OBSERVER))
            continue;

        if (p.team == RED)
            redcount = redcount + 1;
        else if (p.team == BLUE)
            bluecount = bluecount + 1;
    }

    if ((redcount >= minplayers) && (bluecount >= minplayers) && (redcount == bluecount))
        return TRUE;

    return FALSE;
};

/*
===============================================================
CountUnreadyPlayers

Returns the number of non-observer players who are not ready.
===============================================================
*/
float() CountUnreadyPlayers =
{
    local float unreadycount;
    local entity p;

    unreadycount = 0;

    for (p = world; (p = find(p, classname, "player")); )
    {
        // skip dead bodies and spectators
        if (p.health <= 0 || (p.style & CLANRING_OBSERVER))
            continue;

        if (!(p.style & CLANRING_READY))
            unreadycount = unreadycount + 1;
    }

    return unreadycount;
};

/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() PlayerPostThink =
{
    if (!(self.style & CLANRING_CONNECTED))
        return;

    Send_TeamInfo();

    // ELOHIM_MOD
    //
    // - don't do post think stuff while observing
    // - don't do post think stuff while setting options
    // - redirect impulses in [20, 250]
    // - changed gameover test from (self.view_ofs == '0 0 0') to (gameover)

    if (mode_is_arena())
    {
        if ((boss.state == CA_MATCH_WAITING))
        {
            if ((self.next_team == world) && (!(self.style & CLANRING_AFK_CLIENT)))	//not on a team, and not afk...
            {
                if (clanring_playmode & CLANRING_CA_MODE)
                {
                    boss.allready = FALSE;

                    if (number_teams () > 1)
                    {
                        motd_top5 = self.netname;
                        motd_top6 = " \bis holding things up!\n";
                    }
                    else
                    {
                        motd_top5 = string_null;
                        motd_top6 = string_null;
                    }
                }
                else if (clanring_playmode & CLANRING_AIRSHOT_MODE)
                {
                    if (number_teams () > 1)
                        boss.allready = TRUE;
                    else
                        boss.allready = FALSE;
                }
            }
            else boss.allready = TRUE;
        }
    }

    if (self.style & CLANRING_OBSERVER)
    {
        // If they switch to observer, make sure leavemealone is cleared
        // so it doesn't persist when returning to play.
        if (self.leavemealone)
        {
            self.leavemealone = 0;
        }
        self.effects = 0;
        observer_post_think ();
        return;
    }

    if (prematch_rules())
    {
        if (time >= self.delay)
        {
            self.delay = time + 0.5;
            clanring_show_rules_prematch();
        }
    }
    else if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
    {
        if (((clanring_playmode & CLANRING_MATCH_MODE)&&(clanring_state & CLANRING_MATCH_STARTED))||(clanring_playmode & CLANRING_NORMAL_MODE))
        {
            TeamCapturePlayerUpdate();

             // Check if player is carrying enemy flag
            if (self.flag_carrier && self.flag_carry_start > 0)
            {
                // Check for movement every second to detect camping
                if (time >= self.last_pos_check + 1)
                {
                    local float distance_moved = vlen(self.origin - self.last_carry_pos);
                
                    // If moved more than 64 units in last second, count as active carry time
                    if (distance_moved > 64)
                    {
                        self.fcarries_time += 1;
                    }
                
                    self.last_carry_pos = self.origin;
                    self.last_pos_check = time;
        }
    }

        }
    }
    else if (clanring_playmode & CLANRING_WIPEOUT_MODE)
    {
        WipeoutModePlayerUpdate();
    }

    if (self.impulse)
    {
        self.finaldest_x = time;  // player is alive

        if (self.impulse == 22)
    		W_ChangeWeapon ();

        // Redirect impulses 1-10 when player is entering a number
        if (self.use != SUB_Null)
        {
            if ((self.use != select_episode) && (self.use != select_map))//R00k WARP
            {
                if ((self.impulse >= 1) && (self.impulse <= 10))
                {
                    if (self.impulse == 10)
                        self.impulse = 230;
                    else
                        self.impulse = self.impulse + 230;
                }
            }
        }

        if ((self.impulse >= 19) && (self.impulse != 22))
        {
            if (self.impulse != 39) //Remove afk status when the client issues an impulse command, *except* 39, which is our (automated) lag-out checker.
                clear_afk_status(self);

            if (self.impulse <= 250)
                clanring_impulse ();
        }
        else
            self.delayed_impulse = self.impulse;
    }

    CheckCombos();

    // ELOHIM_NO_POST_THINK is set for gameover, deadflag,
    // setting options and match paused
    if (self.style & CLANRING_NO_POST_THINK)
    {
        self.style = self.style - (self.style & CLANRING_NO_POST_THINK);
        return;
    }

    if (time >= self.attack_finished)
        W_WeaponFrame ();

    //R00k: indicate to the player they are not ready.
    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        if (!(self.style & CLANRING_OBSERVER))
        {
            if (!(self.style & CLANRING_READY))
            {
                // Only show red glow when teams are balanced AND this is the last unready player
                if (TeamsBalancedWithMinimum(2) && CountUnreadyPlayers() == 1)
                {
                    if (!(self.effects & EF_RED))
                        self.effects |= EF_RED;
                }
                else
                {
                    // Either teams not balanced, insufficient players, or multiple unready - turn off glow
                    // Do NOT remove EF_RED if invulnerability is currently active (covers pent and spawn protection)
                    if ((self.effects & EF_RED) && !(self.invincible_finished > time))
                        self.effects = self.effects - (self.effects & EF_RED);
                }
            }
            else
            {
                // Player is ready; remove unready red glow but preserve invulnerability red if active
                if ((self.effects & EF_RED) && !(self.invincible_finished > time))
                    self.effects = self.effects - (self.effects & EF_RED);
            }
        }
    }

    // check to see if player landed and play landing sound
    // ELOHIM_MOD - rearranged if clauses for efficiency
    if (!(self.flags & FL_ONGROUND))
    {
        self.jump_flag = self.velocity_z;

        //Normalize bunnyhopping at all ticrates/client protocols (ie sv_nqplayerphysics 0)
        if ((cvar("sv_nqplayerphysics") == 0) && (cvar("nqfriction")))//this works differently than 'pm_bunnyspeedcap' as it reduces the velocity over hops.
        {
            if ((!(self.flags & FL_BHOP))&&(time - self.jump_time < 0.2))
            {
                self.flags |= FL_BHOP;

                if ((vlen(self.velocity)) >= 320) //sv_maxspeed
                {
                    self.velocity[0] -= self.velocity[0] * 0.06;
                    self.velocity[1] -= self.velocity[1] * 0.08;//Strafing will increase the speed by modifying wishdir, so make this stronger...
                }
            }
            else
            {
                self.jump_time = 0;
            }
        }
    }
    else
    {
        if (self.jump_flag < -300)
        {
            if (self.health > 0)
            {
                if (self.watertype == CONTENT_WATER)
                {
                    sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
                }
                else
                {
                    if (self.jump_flag < -650)
                    {
                        self.deathtype = "falling";	//R00k - wrong obituary messages fix
                        T_Damage (self, world, world, 5);
                        sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
                    }
                    else
                    {
                        sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);
                    }
                }
                self.jump_flag = 0;
            }
        }
        if (self.jump_time == 0)
        {
            self.flags = self.flags - (self.flags & FL_BHOP);
            self.jump_time = time;//time we landed
        }
    }

    CheckPowerups ();

    //Regen adds to health every 1/2 second and armor ever 1/2 second if values are below 150.
    if (self.player_flag & ITEM_RUNE4_FLAG)
    {
        local float rjs = 0;
        if (self.regen_time < time)
        {
            self.regen_time = time + 0.5;

            if (self.health < 150)
            {
                rjs = 1;
                self.health = self.health + 5;
                if (self.health > 150)
                    self.health = 150;
            }

            if (self.armorvalue < 150 && self.armortype)
            //?if (self.armorvalue < (250 * self.armortype))//R00k: max value based on armor type (200R 150Y 100G)
            {
                rjs = 1;
                self.armorvalue = self.armorvalue + 5;
                if (self.armorvalue > 150)
                    self.armorvalue = 150;
            }
            if (rjs == 1)
                RegenerationSound();
        }
    }
};

/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect =
{
    self.finaldest_x = time;//lagout timer

    clanring_client_connect ();

    if (stof(infokey(self, "csqcactive")))
    {
        self.csqc_enabled = TRUE;
    }

    utils_ui_supported_now();

    // Reset quad disabled message flag (show once per map per client)
    self.quadDisabledMsgShown = 0;
};

/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
    // ELOHIM_MOD - check to see if we've already done this
    // (can happen since elohim_kick_player calls ClientDisconnect directly
    if (!(self.style & CLANRING_CONNECTED))
        return;

    // ELOHIM_MOD - check for null name
    if (utils_illegal_name (self.netname))
    {
        self.netname = "someone";
    }

    if (self.modelindex == modelindex_eyes)
    {
        self.modelindex = modelindex_player;
        setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
    }

    if (!self.plag)
    {
        if (kick_target != self)
        {
            local string s = ftos(self.frags);
            local string pl = strings_szplural(self.frags);

            if (self.frags > 0)
                announce5(self.netname, " left the game with ", s, " frag", pl);
            else
            {
                if ((self.frags < 1) && (self.frags > -99))
                    announce5(self.netname, " rage-quit with ", s, " frag", pl);
                else
                    announce2(self.netname, " disconnected.");	//observers
            }
        }
    }
    // ELOHIM_MOD - play gib sound if client was kicked for suiciding
    if (!(clanring_playmode & CLANRING_MATCH_MODE) || !(clanring_state & CLANRING_MATCH_STARTED) || !(self.style & CLANRING_OBSERVER))//R00k: dont make a sound when match is going, unless a player disconnected.
    {
        if (self.cnt < 0)
            sound (self, CHAN_BODY, "player/gib.wav", 1, ATTN_NONE);
        else
            sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);
    }

    TeamCaptureDropFlagOfPlayer (self, 0);
    if (!(self.style & CLANRING_OBSERVER))
    {
        powerup_drop(); // Spite the rage-quitter
        DropRune();
        if (!(clanring_playmode & CLANRING_PRACTICE_MODE) && !(mode_is_arena()))
        {
            DropBackpack ();
        }
        UnHookPlayer ();
        self.hook2 = self.hook2 - (self.hook2 & HOOK_OUT);//TODO remove the off-hand newbie hook...
    }

//	if (self.super_damage_finished > 0 && (clanring_playmode & CLANRING_WIPEOUT_MODE))
//	{
//		wipeout_drop_quad (self.super_damage_finished - time);
//	}

    clanring_client_disconnect ();
    
    // Log the disconnect for the 'last' command
    if (self.netname != "")
    {
        utils_log_disconnect(self.netname, utils_server_time());
    }
    
    set_suicide_frame ();

    // ghost eyes and hovering bodies fix
    //CopyToBodyQue(self);// make a copy of the dead body for appearances sake
    setmodel(self, string_null);
    setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
    // end

    self.classname 	= string_null;
    self.health 	= 0;
    self.team 		= 0;
    self.height 	= 0;
    // Clean up zoned strings to prevent memory leaks
    if (self.name_ready) { strunzone(self.name_ready); self.name_ready = string_null; }
    if (self.name_before_typing) { strunzone(self.name_before_typing); self.name_before_typing = string_null; }
    self.had_ready_before_typing = 0;
    self.netname	= string_null;
};

//
// ELOHIM_MOD
//
// Added a bunch of new obituaries; got rid of "can't exist on slime alone"
// (I never much liked that one)
//
// Added a same-team check for telefragging.
//
// Added code to keep track of team scores
//
// Added code to keep track of kill stats
//
// Removed check for killed by monster
//

//
//  F R A G
//
//  Adds/substracts a frag to a client and his team in match mode.
//
void(entity client, float fragval) client_frag =
{
    local float old_frags, window, old_togo, togo; // Declare locals once to avoid duplicates

    if ((clanring_playmode & CLANRING_CA_MODE) || (clanring_playmode & CLANRING_RA_MODE))
        return;

    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        if (teamplay)
        {
            client.frags = (client.frags + fragval);
            score_frag (client.next_team, fragval);
            pqc_team_frags(client.height, client.next_team.frags);
        }
        else
        {
            score_frag (client, fragval);
        }

        if (fraglimit)//R00k added fraglimit for Brazilians, they use fraglimit even in match mode!
        {
            if (client.frags >= fraglimit)
            {
                local entity ent;
                ent = find(world,classname,"clanring_match_timer");
                if (ent)
                    ent.think = match_end;
            }
        }
    }
    else
    {
        // Track old frags so we can detect leaving/entering the window
        old_frags = client.frags;
        client.frags += fragval;

        // Late-game status for plain DM (not match/arena/CTF/practice)
        if ( fraglimit
          && !(clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
          && !(clanring_playmode & CLANRING_PRACTICE_MODE)
          && !(mode_is_arena()) )
        {
            window   = 4; // announce when 1..4 remain
            old_togo = fraglimit - old_frags;
            togo     = fraglimit - client.frags;

            if (fragval < 0)
            {
                // Announce if we were in the window OR still are after the loss
                if ( ((togo >= 1) && (togo <= window)) || ((old_togo >= 1) && (old_togo <= window)) )
                {
                    bprint4(client.netname, " lost a frag (",
                            strings_ftos_gold(togo),
                            sprintf(" %s)\n", redify("to win")));
                }
                // no generic "has NN frags" line on a loss
            }
            else if ((togo >= 1) && (togo <= window))
            {
                if (togo == 1)
                    bprint2(client.netname, " is on \bgame point\b!\n");
                else
                    bprint4(client.netname, " has ",
                            strings_ftos_gold(client.frags),
                            sprintf(" frags (%s %s)\n", strings_ftos_gold(togo), redify("to win")));
            }
        }

        if (client.frags >= fraglimit)
        {
            if (fraglimit && (clanring_levelcount == -1) && (!(mode_is_arena())))//bucksh0t: arena modes will handle fraglimit, stay on map)
            {
                if (!gameover)
                {
                    local string stime;
                    stime = ftos(ceil(time/60));
                    bprint("Fraglimit Hit -- Game Over!\n");
                    bprint("Game won in ",stime," minutes.\n");
                    NextLevel ();
                }
            }
        }
    }
};

/*
===========
ClientObituary
called when a player dies
Modified for CTF -- ugh what a mess!
============
*/
void(entity targ, entity attacker) ClientObituary =
{
    local entity head;
    local float flag_radius;
    local float flag_carrier_radius;
    local string s = "";
    local float rnum;
    local string deathstring = "";
    local string deathstring2 = "";
    local string deathstring3 = "";

    rnum = random ();
    if (targ.classname == "player")
    {
        if (targ.flag_carrier)
        {
            head = find(world, classname, "player");
            while (head != world)
            {
                if (head.team != targ.team)
                {
                    head.last_hurt_carrier = -10;
                }
                head = find(head, classname, "player");
            }
        }
        if (attacker.classname == "teledeath")
        {
            if ((teamplay) && (targ.team > 0) && (targ.team == attacker.owner.team))
            {
                attacker.owner.mangle_y = attacker.owner.mangle_y + 1;// attacker.owner killed teammate
                if (attacker.super_damage_finished > time)
                    attacker.clanring_qdkill_y = attacker.clanring_qdkill_y + 1;//STATS
                if (attacker.invincible_finished > time)
                    attacker.clanring_ptkill_y = attacker.clanring_ptkill_y + 1;
                client_frag (attacker.owner, -1);
                announce3(targ.netname, " telefragged his teammate ", attacker.owner.netname);
            }
            else
            {
                if ((!teamplay) || (targ.team != attacker.owner.team))// targ was killed by enemy
                {
                    targ.mangle_z = targ.mangle_z + 1;
                    client_frag (attacker.owner, 1);
                    attacker.owner.true_kills = (attacker.owner.true_kills + 1);
                }
                announce3(targ.netname, " was telefragged by ", attacker.owner.netname);
            }
            return;
        }
        if (attacker.classname == "teledeath2")
        {
            announce3("Pentegram power deflects ", targ.netname, "'s telefrag");
            targ.mangle_z = targ.mangle_z + 1;
            client_frag (targ, -1);
            return;
        }
        if (attacker.classname == "teledeath3")
        {
            announce4(targ.netname, " was telefragged by ", attacker.owner.netname, "'s protection.");
            targ.mangle_z = targ.mangle_z + 1;
            client_frag (attacker.owner, 1);
            attacker.owner.true_kills = (attacker.owner.true_kills + 1);
            return;
        }
        if (targ.deathtype == "squish")
        {
            if ((teamplay) && (targ.team == attacker.team) && (targ != attacker))
            {
                attacker.mangle_y = attacker.mangle_y + 1;
                client_frag (attacker, -1);
                announce2(attacker.netname, " squished a teammate");
                return;
            }
            else
            {
                if (attacker.classname == "player" && targ != attacker)
                {
                    targ.mangle_z = targ.mangle_z + 1;
                    announce3(attacker.netname, " squishes ", targ.netname);
                    client_frag (attacker, 1);
                    attacker.true_kills = (attacker.true_kills + 1);
                    return;
                }
                else
                {
                    targ.mangle_x = targ.mangle_x + 1;
                    targ.just_suicided = time;
                    client_frag (targ, -1);
                    targ.just_suicided = 0;
                    announce2(targ.netname, " is now just a greasy spot on the floor");
                    return;
                }
            }
            return;
        }
        if (attacker.classname == "player")
        {
            if (targ == attacker)
            {
                attacker.mangle_x = attacker.mangle_x + 1;
                if (attacker.super_damage_finished > time)
                    attacker.clanring_qdkill_z = (attacker.clanring_qdkill_z + 1);
                attacker.just_suicided = time;
                client_frag (attacker, -1);
                attacker.just_suicided = 0;

                if (targ.deathtype == "grenade")
                {
                    if (targ.health < -20)
                        announce2(targ.netname, " tried to juggle too many grenades");
                    else
                        announce2(targ.netname, " tripped over his own grenade");
                    return;
                }
                else
                {
                    if (targ.deathtype == "rocket")
                    {
                        if (targ.health < -40)
                            announce2(targ.netname, " blew himself up");
                        else
                            announce2(targ.netname, " discovers blast radius");
                        return;
                    }
                    else
                    {
                        if (targ.weapon == IT_LIGHTNING && targ.waterlevel > 1)
                        {
                            if (targ.watertype == CONTENT_SLIME)
                                announce2(targ.netname, " discharged in slime");
                            else
                            if (targ.watertype == CONTENT_LAVA)
                                announce2(targ.netname, " discharged in lava");
                            else
                                announce2(targ.netname, " tried to heat the pool");
                            return;
                        }

                    }
                }
                announce2(targ.netname, "  becomes bored with quake");
                if ((self.super_damage_finished > time) && (self.items & IT_QUAD))
                {
                    if (rnum < 0.5)
                        sound (world, CHAN_VOICE, "crx/laugh3.wav", 1, ATTN_NONE);
                    else
                        sound (world, CHAN_VOICE, "crx/laugh6.wav", 1, ATTN_NONE);
                }
                return;
            }
            else
            {
                if ((teamplay == 2) && !(clanring_playmode & CLANRING_RA_MODE) && (targ.team > 0) && (targ.team == attacker.team))
                {
                    attacker.mangle_y = attacker.mangle_y + 1;

                    if (attacker.super_damage_finished > time)
                        attacker.clanring_qdkill_y = attacker.clanring_qdkill_y + 1;
                    if (attacker.invincible_finished > time)
                        attacker.clanring_ptkill_y = attacker.clanring_ptkill_y + 1;

                    // NEW: Track when killing a teammate who had quad damage
                    if (targ.super_damage_finished > time)
                        attacker.stats_teamkill_quad = attacker.stats_teamkill_quad + 1;

                    if (rnum < 0.25)
                    {
                        deathstring = " teamkills ";
                    }
                    else
                    {
                        if (rnum < 0.5)
                        {
                            deathstring = " blindly shoots his teammate ";
                        }
                        else
                        {
                            if (rnum < 0.75)
                            {
                                deathstring = " actually wanted to kill his teammate ";
                            }
                            else
                            {
                                deathstring = " destroys his teammate ";
                            }
                        }
                    }

                    deathstring2 = ", with just his bare hands.\n";

                    if (attacker.weapon == IT_ROCKET_LAUNCHER)
                        deathstring2 = ", with a Rocket Launcher.";
                    if (attacker.weapon == IT_LIGHTNING)
                        deathstring2 = ", with a Lightning Gun.";
                    if ((attacker.weapon == IT_GRENADE_LAUNCHER))
                        deathstring2 = ", with a Grenade Launcher.";
                    if ((attacker.weapon == IT_SUPER_NAILGUN))
                        deathstring2 = ", with a Super Nailgun.";
                    if ((attacker.weapon == IT_SUPER_SHOTGUN))
                        deathstring2 = ", with a Super Shotgun.";
                    if ((attacker.weapon == IT_NAILGUN))
                        deathstring2 = ", with a Nailgun.";
                    if ((attacker.weapon == IT_SHOTGUN))
                        deathstring2 = ", with a Shotgun.";
                    if ((attacker.weapon == IT_AXE))
                        deathstring2 = ", with an Axe.";
                    if ((attacker.weapon == IT_HOOK))
                        deathstring2 = ", with a Hook.";

                    announce4(attacker.netname, deathstring, targ.netname, deathstring2);
                    client_frag (attacker, -1);
                    deathstring2 = "";
                    return;
                }
                else
                {
                    //ctf match mode kill bonuses
                    if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (!(clanring_playmode & CLANRING_PRACTICE_MODE)))
                    {
                        if (((targ.flag_carrier) && (targ.team != attacker.team)))
                        {
                            attacker.last_fragged_carrier = time;
                            attacker.fcfrags += 1;
                            // what you get for fragging enemy flag carrier
                            if (((targ.flag_since + TEAM_CAPTURE_CARRIER_FLAG_SINCE_TIMEOUT) < time))
                                client_frag (attacker, TEAM_CAPTURE_FRAG_CARRIER_BONUS);
                        }
                        flag_radius = 0;
                        flag_carrier_radius = 0;

                        if (attacker.team == RED) s = ("\bRED\b");
                        else
                        if (attacker.team == BLUE) s = ("\bBLUE\b");

                        if ((((targ.last_hurt_carrier + TEAM_CAPTURE_CARRIER_DANGER_PROTECT_TIMEOUT) > time) && !(attacker.flag_carrier)))
                        {
                            client_frag (attacker, TEAM_CAPTURE_CARRIER_DANGER_PROTECT_BONUS);
                            // bonus for fraggin someone who has recently hurt your flag carrier
                            flag_carrier_radius = 1;
                            announce4(attacker.netname," defends ",s,"'s flag carrier against an agressive enemy");
                            attacker.fcdefenses = attacker.fcdefenses + 1;
                        }

                        if (!(attacker.flag_carrier))// speed
                        {
                            head = findradius (attacker.origin, TEAM_CAPTURE_ATTACKER_PROTECT_RADIUS);
                            while (head)
                            {
                                if (head.classname == "player")
                                {
                                    if ( ( ( ((head.team == attacker.team) && (head.flag_carrier)) && (head != attacker) ) && !flag_carrier_radius) )
                                    {
                                        client_frag (attacker, TEAM_CAPTURE_CARRIER_PROTECT_BONUS);
                                        flag_carrier_radius = 1;
                                        announce4(attacker.netname," defends ",s,"'s flag carrier");
                                        attacker.fcdefenses = (attacker.fcdefenses + 1);
                                    }
                                }
                                if (((head.classname == "item_flag_team1") || (head.classname == "item_flag_team2")))
                                {
                                    if ((((attacker.team == RED) && (head.classname == "item_flag_team1")) || ((attacker.team == BLUE) && (head.classname == "item_flag_team2"))))
                                    {
                                        client_frag (attacker, TEAM_CAPTURE_FLAG_DEFENSE_BONUS);
                                        flag_radius = 1;
                                        announce4(attacker.netname," defends the ",s," flag");
                                        if (head.cnt == FLAG_AT_BASE)
                                            attacker.fdefenses = (attacker.fdefenses + 1);
                                        else
                                            attacker.stats_defense_dropped_flag += 1;	//
                                    }
                                }
                                head = head.chain;
                            }
                            head = findradius (targ.origin, TEAM_CAPTURE_TARGET_PROTECT_RADIUS);
                            while (head)
                            {
                                if ((head.classname == "player"))
                                {
                                    if ( ( ( (head.team == attacker.team) && (head.flag_carrier) && (head != attacker)) && !flag_carrier_radius) )
                                    {
                                        client_frag (attacker, TEAM_CAPTURE_CARRIER_PROTECT_BONUS);
                                        flag_carrier_radius = 1;
                                        announce4(attacker.netname," defends ",s,"'s flag carrier");
                                        attacker.fcdefenses = (attacker.fcdefenses + 1);
                                    }
                                }
                                if (((((attacker.team == RED) && (head.classname == "item_flag_team1")) || ((attacker.team == BLUE) && (head.classname == "item_flag_team2"))) && !flag_radius))
                                {
                                    //if (head.cnt == FLAG_AT_BASE) client_frag (attacker, TEAM_CAPTURE_FLAG_DEFENSE_BONUS + 1);
                                    //else
                                    client_frag (attacker, TEAM_CAPTURE_FLAG_DEFENSE_BONUS);

                                    flag_radius = 1;
                                    announce4(attacker.netname," defends the ",s," flag");
                                    if (head.cnt == FLAG_AT_BASE)
                                        attacker.fdefenses = (attacker.fdefenses + 1);
                                    else
                                        attacker.stats_defense_dropped_flag += 1;
                                }
                                head = head.chain;
                            }
                        }
                    }

                    if (attacker.super_damage_finished > time)
                        attacker.clanring_qdkill_x = attacker.clanring_qdkill_x + 1;
                    if (attacker.invincible_finished > time)
                        attacker.clanring_ptkill_x = attacker.clanring_ptkill_x + 1;

                    // NEW: Track powerup denial - killing enemy who had powerups
                    if (targ.super_damage_finished > time)
                        attacker.stats_powerup_denial_quad = attacker.stats_powerup_denial_quad + 1; 

                    targ.mangle_z = targ.mangle_z + 1;//STATS
                    client_frag (attacker, 1);
                    attacker.true_kills = (attacker.true_kills + 1);
                    deathstring2 = "";
                    rnum = attacker.weapon;
                    if (targ.deathtype == "nail")
                    {
                        deathstring = " was nailed by ";
                    }
                    else
                    {
                        if (targ.deathtype == "supernail")
                        {
                            deathstring = " was pierced by ";
                        }
                        else
                        {
                            if (targ.deathtype == "grenade")
                            {
                                deathstring = " found ";
                                deathstring2 = "'s grenade";
                                if (targ.health < -40)
                                {
                                    if (clanring_playmode & CLANRING_NO_GIBS)
                                    {
                                        deathstring = " was annihilated by ";
                                    }
                                    else
                                    {
                                        deathstring = " was blown to chunks by ";
                                    }
                                }
                                if (targ.teleport_time > time) // when a player gets out of the water, their teleport_time is time + 2, their feet are wet...
                                {
                                    deathstring = " slips on ";
                                }
                            }
                            else
                            {
                                if (targ.deathtype == "rocket")
                                {
                                    if (attacker.super_damage_finished > time)
                                    {
                                        rnum = random()*3;
                                        if (rnum < 2)
                                        deathstring = " was obliterated by ";
                                        else
                                        if (rnum ==2)
                                        deathstring = " was pummelled by ";
                                        else
                                        if (rnum >2)
                                        deathstring = " was pulverized by ";
                                        deathstring2 = "'s quad rocket";
                                    }
                                    else
                                    {
                                        deathstring = " rides ";
                                        deathstring2 = "'s rocket";
                                        if (targ.health < -40)
                                        {
                                            if (clanring_playmode & CLANRING_NO_GIBS)
                                                deathstring = " was annihilated by ";
                                            else
                                                deathstring = " was blown to chunks by ";
                                        }
                                    }
                                }
                                else
                                {
                                    if (targ.deathtype == "hook")
                                    {
                                        deathstring = " was hooked by ";
                                    }
                                    else
                                    {
                                        if (rnum == IT_AXE)
                                        {
                                            targ.clanring_badstats2_y += 1;
                                            
                                            rnum=(random()*3);
                                            if (rnum<2)  deathstring = " was chopped into little pieces by ";
                                            if (rnum==2) deathstring = " was hacked up by ";
                                            if (rnum>2)  deathstring = " was butchered by ";

                                            if (attacker.super_damage_finished > 0 && targ.health < -10)
                                                deathstring2 = "'s quad Axe";
                                            else
                                                deathstring2 = "'s cleaver";
                                        }
                                        else
                                        {
                                            if (rnum == IT_HOOK)
                                            {
                                                deathstring = " was hooked by ";
                                            }
                                            else
                                            {
                                                if (rnum == IT_SHOTGUN)
                                                {
                                                    deathstring = " gets lead poisoned by ";
                                                    deathstring2 = "'s shotgun";
                                                }
                                                else
                                                {
                                                    if (rnum == IT_SUPER_SHOTGUN)
                                                    {
                                                        deathstring = " got his head blown off by ";
                                                        deathstring2 = "'s buckshot";
                                                    }
                                                    else
                                                    {
                                                        if (rnum == IT_LIGHTNING)
                                                        {
                                                            deathstring = " was shocked by ";
                                                            deathstring2 = "'s thunderbolt";

                                                            if (attacker.super_damage_finished > 0 && targ.health < -10)
                                                            {
                                                                deathstring = " was electrocuted by ";

                                                                if (attacker.waterlevel > 1)
                                                                {
                                                                    deathstring2 = "'s quad discharge";
                                                                }
                                                                else
                                                                {
                                                                    deathstring2 = "'s quad thunderbolt";
                                                                }
                                                            }
                                                            else
                                                            {
                                                                if (attacker.waterlevel > 1)
                                                                {
                                                                    deathstring2 = "'s discharge";
                                                                }
                                                                else
                                                                {
                                                                    deathstring2 = "'s thunderbolt";
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    //bucksh0t: add to combo
                    attacker.combo_frags += 1;
                    attacker.combo_time = time;

                    //bucksh0t: kill streak
                    if (!(mode_is_arena()))
                    {
                        attacker.killstreak += 1;

                        //show quad kill streak instead
                        // if (attacker.killstreak > 1)
                        // 	deathstring3 = sprintf(" (%s)", strings_ftos_gold(attacker.killstreak));
                        // else
                            deathstring3 = "";

                        announce5(targ.netname, deathstring, attacker.netname, deathstring2, deathstring3);

                        if (attacker.killstreak == 5)
                        {
                            bprint2(attacker.netname, " is on a \bkilling spree\b! \5 kills in a row!\n");
                        }
                        // else if (attacker.killstreak == 10)
                        // {
                        // 	bprint2(attacker.netname, " is \bunstoppable\b! \1\0 kills in a row!\n");
                        // 	//sound(world,CHAN_AUTO,"crx/nostop1.wav",1,ATTN_NONE);
                        // 	//sound (self, CHAN_VOICE, "crx/onfire.wav", 1, ATTN_NORM);
                        // }
                        // else if (attacker.killstreak == 10)
                        // {
                        // 	bprint2(attacker.netname, " has \1\5 kills in a row!\n");
                        // 	//sound(world,CHAN_AUTO,"crx/noenter.wav",1,ATTN_NONE);
                        // }
                        // else if (attacker.killstreak == 20)
                        // {
                        // 	bprint2(attacker.netname, " is \bdominating\b! \2\0 kills in a row!\n");
                        // 	//sound(world,CHAN_AUTO,"crx/king.wav",1,ATTN_NONE);
                        // }
                        else if (attacker.killstreak % 5 == 0)
                        {
                            bprint4(attacker.netname, " has ", strings_ftos_gold(attacker.killstreak), " kills in a row!\n");
                        }
                    }
                    else
                    {
                        announce4(targ.netname, deathstring, attacker.netname, deathstring2);
                    }
                }
            }
            return;
        }
        else
            {// targ got himself killed
            targ.mangle_x = (targ.mangle_x + 1);
            client_frag (targ, -1);

            if (attacker.classname == "explo_box")
            {
                announce2(targ.netname, " blew up");
                return;
            }
            if (targ.deathtype == "falling")
            {
                announce2(targ.netname, " burries himself in the ground");
                targ.clanring_badstats2_z += 1;
                return;
            }
            if ((targ.deathtype == "nail") || (targ.deathtype == "supernail"))
            {
                announce2(targ.netname, " was spiked");
                return;
            }
            if (targ.deathtype == "laser")
            {
                announce2(targ.netname, " was zapped");
                return;
            }
            if (attacker.classname == "fireball")
            {
                announce2(targ.netname, " coughed a lavaball");
                return;
            }
            if (attacker.classname == "trigger_changelevel")
            {
                announce2(targ.netname, " tried to escape");
                return;
            }
            rnum = targ.watertype;
            if (rnum == CONTENT_WATER)
            {
                if (random() < 0.5)
                    announce2(targ.netname, " sinks like a rock");
                else
                    announce2(targ.netname, " forgot to come up for air");
                return;
            }
            else
            {
                if (rnum == CONTENT_SLIME)
                {
                    if (random() < 0.5)
                        announce2(targ.netname, " discovers the hazards of toxic waste");
                    else
                        announce2(targ.netname, " dissolves in an acidic pool");
                    return;
                }
                else
                {
                    if (rnum == CONTENT_LAVA)
                    {
                        targ.clanring_badstats2_x += 1;
                        
                        if (targ.health < -15)
                        {
                            announce2(targ.netname, " burst into flames");
                            return;
                        }
                        if (random() < 0.5)
                            announce2(targ.netname, " melted in lava");
                        else
                            announce2(targ.netname, " takes a nice hot lava bath");
                        return;
                    }
                }
            }
            announce2(targ.netname, " died");
        }
    }
};

void () client_afk_on =
{
    if (!(self.style & CLANRING_AFK_CLIENT))
    {
        // Turn off typing if it's on
        if (self.style & CLANRING_TYPING_CLIENT)
            self.style &= ~CLANRING_TYPING_CLIENT;
        
        afk_name();
        forceinfokey(self, "afk", "yes");// woods
        forceinfokey(self, "chat", "2");  // New chat status key - 2 means AFK
        self.style |= CLANRING_AFK_CLIENT;
        self.afk_time = time;
    }
};

void () client_afk_off =
{
    if (self.style & CLANRING_AFK_CLIENT)
    {
        clear_afk_status(self);
    }
};

void () typing_name =
{
    local string text = "\btyping\b";
    updatenameoverload(text);
    updatename(self, self.name_ready);
};

void () client_typing_on =
{
    if (!(self.style & CLANRING_AFK_CLIENT) && !(self.style & CLANRING_TYPING_CLIENT))
    {
        // Remember what was being displayed before switching to typing (make a stable copy)
        if (self.name_before_typing) {
            strunzone(self.name_before_typing);
            self.name_before_typing = string_null;
        }
        // Track whether we were showing a formatted overlay or plain netname
        self.had_ready_before_typing = (self.name_ready != string_null);
        if (self.had_ready_before_typing)
            self.name_before_typing = strzone(self.name_ready);
        else
            self.name_before_typing = strzone(self.netname);

        typing_name();
        self.style |= CLANRING_TYPING_CLIENT;
        forceinfokey(self, "chat", "1"); // Set typing status
    }
};

void () client_typing_off =
{
    if (self.style & CLANRING_TYPING_CLIENT)
    {
        if (self.name_before_typing)
        {
            // Restore the previous displayed name/status immediately
            updatename(self, self.name_before_typing);
            // Keep name_ready in sync and ensure we own the memory
            if (self.had_ready_before_typing)
            {
                if (self.name_ready) strunzone(self.name_ready);
                self.name_ready = strzone(self.name_before_typing);
            }
            else
            {
                if (self.name_ready) strunzone(self.name_ready);
                self.name_ready = string_null; // we were showing raw netname
            }
            strunzone(self.name_before_typing);
            self.name_before_typing = string_null;
            self.had_ready_before_typing = 0;
        }
        else
        {
        clear_name();
        }
        self.style &= ~CLANRING_TYPING_CLIENT;
        forceinfokey(self, "chat", "0"); // Set to active
    }
};

void () check_client_status =
{
    if (!(self.style & CLANRING_CONNECTED))
        return;
        
    local string chat_status = infokey(self, "chat");
    
    if (chat_status == "2") // AFK
    {
        if (!(self.style & CLANRING_AFK_CLIENT))
            client_afk_on();
            
        if (self.style & CLANRING_TYPING_CLIENT)
            self.style &= ~CLANRING_TYPING_CLIENT;
    }
    else if (chat_status == "1") // Typing
    {
        if (self.style & CLANRING_AFK_CLIENT)
            client_afk_off();
            
        if (!(self.style & CLANRING_TYPING_CLIENT))
            client_typing_on();
    }
    else if (chat_status == "0") // Active
    {
        if (self.style & CLANRING_AFK_CLIENT)
            client_afk_off();
            
        if (self.style & CLANRING_TYPING_CLIENT)
            client_typing_off();
    }
};

float (string s) FindNumericalInput =
{
    float pass;

    pass = 0;

    if (self.use)
    {
        float n;

        if ((strlen(s)) > 2) // 00 to 99
        {
            n = 0;
            pass = 0;
        }
        else
        {
            n = stof(s);
            pass = 1;
        }

        self.finaldest_z = n;
        self.use();
    }

    return pass;
}

void(string cmd) SV_ParseClientCommand =
{
    local float args, modecmd, mapnumber=0;
    local string arg0 = "", arg1 = "", arg2 = "";

    if (!(self.style & CLANRING_CONNECTED))
    {
        clientcommand(self, cmd); //this client has not finished connecting, or has lagged out.
        return;
    }

    args = tokenize(cmd);
    if (args > 0)
        arg0 = argv(0);
    if (args > 1)
        arg1 = argv(1);
    if (args > 2)
        arg2 = argv(2);

    switch (arg0)
    {
        // removed: webhooktest
        // removed: urigettest / uriposttest

        case "altents":
            votables_request_set_altents();
            return;

        case "eyecam":
            if (arg1 != "")
            {
                self.observer_number = stof(arg1);
            }
            if (self.style & CLANRING_OBSERVER)
                observer_demo_start();
            else
            {
                self.oflags = self.oflags | OBSERVER_DEMO;
                if (((clanring_playmode & CLANRING_MATCH_MODE) & (clanring_state & CLANRING_MATCH_STARTED)) || ((mode_is_arena()) && (boss.state != CA_MATCH_WAITING)))
                    observer_confirm();
                else
                    observer_start();    
            }
            return;
        
        case "shownick":
            if ((!(self.style & CLANRING_OBSERVER)))//R00k; not observers.
            {
                if (teamplay)
                {
                    if (time > self.id_time)
                    {
                        ident_get_target();
                        self.id_time = (time + 0.2);
                    }
                }
            }
            return;

        case "fragset":
            if ((self.style & CLANRING_ADMINISTRATOR) && (argv(1) != ""))
                clanring_set_fraglimit(stof(arg1));
            else
                votables_select_fraglimit();
            return;

        case "timeset":
            // Optional numeric argument: minutes. Without args, open the menu
            if (arg1 != "")
            {
                votables_request_set_timelimit(stof(arg1));
            }
            else
            {
                votables_select_timelimit();
            }
            return;

        case "admin":
            // Support both interactive and direct code entry: "cmd admin 123456"
            if (arg1 == "")
            {
                admin_start_code();
                return;
            }

            // If admin codes are disabled
            if (array_password[0] == 0)
            {
                sprint(self, "Administrator password disabled\n");
                sprint(self, "Edit the 'configs/clanring.cfg' on the server.\n");
                return;
            }

            // If already admin, do nothing
            if (self.style & CLANRING_ADMINISTRATOR)
            {
                sprint(self, "You are already an administrator.\n");
                return;
            }

            // Parse numeric code and validate reasonable length (4-7 digits)
            local float code, len;
            len = strlen(arg1);
            code = stof(arg1);

            if (len < 4 || len > 7 || code < 1000 || code > 9999999)
            {
                sprint(self, "Invalid code\n");
                self.clanring_hack_count = self.clanring_hack_count + 1;
                if (self.clanring_hack_count > 3)
                {
                    announce2(self.netname, " kicked for admin hacking");
                    clanring_kick_player(self);
                }
                return;
            }

            // Check against configured admin codes
            local float i;
            for (i = 0; i < array_password.length; i = i + 1)
            {
                if (code == array_password[i])
                {
                    self.clanring_hack_count = i;
                    admin_create();
                    return;
                }
            }

            // Not matched
            sprint(self, "Invalid code\n");
            self.clanring_hack_count = self.clanring_hack_count + 1;
            if (self.clanring_hack_count > 3)
            {
                announce2(self.netname, " kicked for admin hacking");
                clanring_kick_player(self);
            }
            return;

        case "afkon":
            client_afk_on();
            return;

        case "afkoff":
            client_afk_off();
            return;

        case "typingon":
            client_typing_on();
            return;
            
        case "typingoff":
            client_typing_off();
            return;

        case "wtstats":
            if ((self.style & CLANRING_OBSERVER)||(gameover)||((clanring_playmode & CLANRING_MATCH_MODE) && (!(clanring_state & CLANRING_MATCH_STARTED))))
                stats_show_weapon_items_taken_stats();
            else
                sprint(self,"\bYou may not view these stats during a game as a player.\n");
            return;

        case "itstats":
            if ((self.style & CLANRING_OBSERVER)||(gameover)||((clanring_playmode & CLANRING_MATCH_MODE) && (!(clanring_state & CLANRING_MATCH_STARTED))))
                stats_show_items_taken_stats();
            else
                sprint(self,"\bYou may not view these stats during a game as a player.\n");
            return;

        case "dstats":
                stats_show_defense_stats();
                return;

        case "last":
                utils_show_last_disconnects();
                return;

        case "lastscores":
                utils_show_last_scores();
                return;

        case "powerupdrop":
        case "pudrop":
                votables_request_set_powerupdrop();
                return;

        // Back-compat alias: 'quaketag' behaves like 'qwsucks' toggle/start
        case "quaketag":
            votables_request_qwsucks();
            return;

        case "qwsucks":
            votables_request_qwsucks();
            return;

        case "q14ever":
            votables_request_q14ever();
            return;

        case "dm":
            if (arg2 != "")
            {
                modecmd = get_mode_from_string(arg1);
                if (modecmd < 0)
                {
                    sprint2(self, arg1, " is not a recognized mode.\n");
                    return;
                }

                mapnumber = found_in_warp_list(arg2);
                if (mapnumber)
                    votables_request_set_gametype_mode_map(0, modecmd, mapnumber);
                else
                    sprint2(self, arg2, " is not a recognized map.\n");
                return;
            }
            else if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                {
                    votables_request_set_gametype_mode_map(0, -1, mapnumber);
                }
                else
                {
                    modecmd = get_mode_from_string(arg1);
                    if (modecmd < 0)
                    {
                        sprint2(self, arg1, " is not a recognized map or mode.\n");
                        return;
                    }
                    votables_request_set_gametype_mode_map(0, modecmd, 0);
                }
                return;
            }
            votables_request_set_gametype_mode_map(0, -1, 0);
            return;
        case "ffa":
            if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                {
                    votables_request_set_gametype_mode_map(0, 0, mapnumber);
                }
                else
                {
                    sprint2(self, arg1, " is not a recognized map.\n");
                }
                return;
            }
            votables_request_set_gametype_mode_map(0, 0, 0);
            return;
        case "ctf":
            if (arg2 != "")
            {
                modecmd = get_mode_from_string(arg1);
                if (modecmd < 0)
                {
                    sprint2(self, arg1, " is not a recognized mode.\n");
                    return;
                }

                mapnumber = found_in_warp_list(arg2);
                if (mapnumber)
                    votables_request_set_gametype_mode_map(1, modecmd, mapnumber);
                else
                    sprint2(self, arg2, " is not a recognized map.\n");
                return;
            }
            else if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                {
                    votables_request_set_gametype_mode_map(1, -1, mapnumber);
                }
                else
                {
                    modecmd = get_mode_from_string(arg1);
                    if (modecmd < 0)
                    {
                        sprint2(self, arg1, " is not a recognized map or mode.\n");
                        return;
                    }
                    votables_request_set_gametype_mode_map(1, modecmd, 0);
                }
                return;
            }
            votables_request_set_gametype_mode_map(1, -1, 0);
            return;
        case "normal":
            if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                    votables_request_set_gametype_mode_map(-1, 0, mapnumber);
                else
                    sprint2(self, arg1, " is not a recognized map.\n");
                return;
            }
            votables_request_set_gametype_mode_map(-1, 0, 0);
            return;
        case "practice":
            if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                    votables_request_set_gametype_mode_map(-1, 1, mapnumber);
                else
                    sprint2(self, arg1, " is not a recognized map.\n");
                return;
            }
            votables_request_set_gametype_mode_map(-1, 1, 0);
            return;
        case "match":
            if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                    votables_request_set_gametype_mode_map(-1, 2, mapnumber);
                else
                    sprint2(self, arg1, " is not a recognized map.\n");
                return;
            }
            votables_request_set_gametype_mode_map(-1, 2, 0);
            return;
        case "dmm4":
            if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                    votables_request_set_gametype_mode_map(4, -1, mapnumber);
                else
                    sprint2(self, arg1, " is not a recognized map.\n");
                return;
            }
            votables_request_set_gametype_mode_map(4, -1, 0);
            return;
        case "airshot":
            if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                    votables_request_set_gametype_mode_map(5, -1, mapnumber);
                else
                    sprint2(self, arg1, " is not a recognized map.\n");
                return;
            }
            votables_request_set_gametype_mode_map(5, -1, 0);
            return;
        case "wipeout":
            if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                    votables_request_set_gametype_mode_map(6, -1, mapnumber);
                else
                    sprint2(self, arg1, " is not a recognized map.\n");
                return;
            }
            votables_request_set_gametype_mode_map(6, -1, 0);
            return;
        case "ctfdmm4":
            if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                    votables_request_set_gametype_mode_map(7, -1, mapnumber);
                else
                    sprint2(self, arg1, " is not a recognized map.\n");
                return;
            }
            votables_request_set_gametype_mode_map(7, -1, 0);
            return;
        case "ca":
            if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                    votables_request_set_gametype_mode_map(2, -1, mapnumber);
                else
                    sprint2(self, arg1, " is not a recognized map.\n");
                return;
            }
            votables_request_set_gametype_mode_map(2, -1, 0);
            return;
        case "ra":
            if (arg1 != "")
            {
                mapnumber = found_in_warp_list(arg1);
                if (mapnumber)
                    votables_request_set_gametype_mode_map(3, -1, mapnumber);
                else
                    sprint2(self, arg1, " is not a recognized map.\n");
                return;
            }
            votables_request_set_gametype_mode_map(3, -1, 0);
            return;

        // Position tools (prewar only; DM/CTF match mode)
        case "pos_save":
        {
            if (!((clanring_playmode & CLANRING_MATCH_MODE) && !(clanring_state & CLANRING_MATCH_STARTED) && !mode_is_arena()))
            {
                sprint(self, "Position commands only work during prewar.\n");
                return;
            }
            if (self.style & CLANRING_OBSERVER)
            {
                sprint(self, "Observers cannot save positions.\n");
                return;
            }
            self.saved_pos_origin = self.origin;
            self.saved_pos_angles = self.v_angle;
            self.saved_pos_velocity = self.velocity;
            self.saved_pos_valid = 1;
            sprint(self, "Position was saved.\n");
            return;
        }

        case "pos_move":
        {
            if (!((clanring_playmode & CLANRING_MATCH_MODE) && !(clanring_state & CLANRING_MATCH_STARTED) && !mode_is_arena()))
            {
                sprint(self, "Position commands only work during prewar.\n");
                return;
            }
            if (self.style & CLANRING_OBSERVER)
            {
                sprint(self, "Observers cannot restore positions.\n");
                return;
            }
            if (!self.saved_pos_valid)
            {
                sprint(self, "No saved position. Use 'pos_save' first.\n");
                return;
            }
            // Rate limit to once per second
            if (time < self.saved_pos_last_move_time + 1)
            {
                sprint(self, "Please wait before using pos_move again.\n");
                return;
            }
            // Fail if target location is occupied
            tracebox(self.saved_pos_origin, VEC_HULL_MIN, VEC_HULL_MAX, self.saved_pos_origin, 0, self);
            if (trace_startsolid || trace_fraction < 1)
            {
                sprint(self, "Saved location is occupied.\n");
                return;
            }
            // If carrying a flag, return flags to base
            if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (self.items & (IT_KEY1 | IT_KEY2)))
            {
                TeamCaptureRegenFlags();
            }
            // Teleport effects similar to trigger_teleport
            spawn_tfog(self.origin);
            setorigin(self, self.saved_pos_origin);
            self.angles = self.v_angle = self.saved_pos_angles;
            if (isFTEserver)
                self.fixangle = 3;
            else
                self.fixangle = TRUE;
            self.flags = self.flags - (self.flags & FL_ONGROUND);
            self.velocity = self.saved_pos_velocity;
            spawn_tfog(self.origin);
            self.saved_pos_last_move_time = time;
            sprint(self, "Position was restored.\n");
            return;
        }

        case "pos_show":
        {
            if (!self.saved_pos_valid)
            {
                sprint(self, "No saved position. Use 'pos_save' first.\n");
                return;
            }
            sprint(self, sprintf("Saved origin: %s\n", vtos(self.saved_pos_origin)));
            sprint(self, sprintf("Saved angles: %s\n", vtos(self.saved_pos_angles)));
            sprint(self, sprintf("Saved velocity: %s\n", vtos(self.saved_pos_velocity)));
            sprint(self, sprintf("Current origin: %s\n", vtos(self.origin)));
            sprint(self, sprintf("Current angles: %s\n", vtos(self.v_angle)));
            sprint(self, sprintf("Current velocity: %s\n", vtos(self.velocity)));
            return;
        }

        case "pos_origin":
        {
            if (!((clanring_playmode & CLANRING_MATCH_MODE) && !(clanring_state & CLANRING_MATCH_STARTED) && !mode_is_arena()))
            {
                sprint(self, "Position commands only work during prewar.\n");
                return;
            }
            if (self.style & CLANRING_OBSERVER)
            {
                sprint(self, "Observers cannot set positions.\n");
                return;
            }
            local string sx, sy, sz;
            local vector base;
            base = self.saved_pos_valid ? self.saved_pos_origin : self.origin;
            sx = argv(1);
            sy = argv(2);
            sz = argv(3);
            if (sx == "" || sy == "" || sz == "")
            {
                sprint(self, "Usage: pos_origin x y z (use * to keep current)\n");
                return;
            }
            if (sx != "*") base_x = stof(sx);
            if (sy != "*") base_y = stof(sy);
            if (sz != "*") base_z = stof(sz);
            self.saved_pos_origin = base;
            self.saved_pos_angles = self.v_angle;
            self.saved_pos_velocity = self.velocity;
            self.saved_pos_valid = 1;
            sprint(self, sprintf("Saved origin set to %s\n", vtos(self.saved_pos_origin)));
            return;
        }

        case "pos_angles":
        {
            if (!((clanring_playmode & CLANRING_MATCH_MODE) && !(clanring_state & CLANRING_MATCH_STARTED) && !mode_is_arena()))
            {
                sprint(self, "Position commands only work during prewar.\n");
                return;
            }
            if (self.style & CLANRING_OBSERVER)
            {
                sprint(self, "Observers cannot set positions.\n");
                return;
            }
            local string ax, ay, az;
            local vector basea;
            basea = self.saved_pos_valid ? self.saved_pos_angles : self.v_angle;
            ax = argv(1);
            ay = argv(2);
            az = argv(3);
            if (ax == "" || ay == "" || az == "")
            {
                sprint(self, "Usage: pos_angles pitch yaw roll (use * to keep current)\n");
                return;
            }
            if (ax != "*") basea_x = stof(ax);
            if (ay != "*") basea_y = stof(ay);
            if (az != "*") basea_z = stof(az);
            self.saved_pos_angles = basea;
            self.saved_pos_origin = self.saved_pos_valid ? self.saved_pos_origin : self.origin;
            self.saved_pos_velocity = self.velocity;
            self.saved_pos_valid = 1;
            sprint(self, sprintf("Saved angles set to %s\n", vtos(self.saved_pos_angles)));
            return;
        }

        case "leavemealone":
        {
            // Global off switch
            registercvar("cr_allow_leavemealone", "1");
            local float allow_lma = cvar("cr_allow_leavemealone");
            if (allow_lma < 1)
            {
                sprint(self, sprintf("Leave-me-alone command is disabled on this server (cvar value: %g)\n", allow_lma));
                return;
            }

            // Prewar only; Rocket Arena blocked
            if (match_in_progress())
            {
                sprint(self, "Cannot use leave-me-alone during a match\n");
                return;
            }
            if (clanring_playmode & CLANRING_RA_MODE) // keep RA lobby logic clean
            {
                sprint(self, "Leave-me-alone is not available in Rocket Arena\n");
                return;
            }

            // Observers cannot use leavemealone
            if (self.style & CLANRING_OBSERVER)
            {
                sprint(self, "Observers cannot use leave-me-alone\n");
                return;
            }

            // Per-client 5s cooldown
            if (time < self.next_lma_toggle)
            {
                local float remain;
                remain = self.next_lma_toggle - time;
                if (remain < 0) remain = 0;
                sprint(self, strcat("Please wait ", ftos(ceil(remain)), " seconds before using leave-me-alone again\n"));
                return;
            }

            // Toggle OFF -> ON (become intangible)
            if (!self.leavemealone)
            {
                self.leavemealone = 1;
                self.solid = SOLID_TRIGGER; // intangible to players/projectiles; bbox maintained elsewhere
                setorigin(self, self.origin); // relink
                stuffcmd(self, "play buttons/switch04.wav\n");
                sprint(self, "Leave-me-alone: \bon\b (you are intangible; no pickups/telefrags)\n");
                // Notify everyone EXCEPT the toggling player
                {
                    entity p = world;
                    while ( (p = find(p, classname, "player")) )
                    {
                        if (p != self)
                        {
                            sprint2(p, self.netname, " wants to be left alone\n");
                        }
                    }
                }
                self.next_lma_toggle = time + 5;
                return;
            }

            // Toggle ON -> OFF (return to solid). Prevent popping inside others.
            if (AnySolidPlayerInRadius(self, 32))
            {
                sprint(self, "Can't turn off leave-me-alone here, someone is too close\n");
                return;
            }

            self.leavemealone = 0;
            self.solid = SOLID_SLIDEBOX;
            setorigin(self, self.origin); // relink as solid
            stuffcmd(self, "play buttons/switch04.wav\n");
            sprint(self, "Leave-me-alone: \boff\b (you are solid again)\n");
            // Notify everyone EXCEPT the toggling player
            {
                entity other_player = world;
                while ( (other_player = find(other_player, classname, "player")) )
                {
                    if (other_player != self)
                    {
                        sprint2(other_player, self.netname, " no longer wants to be left alone\n");
                    }
                }
            }
            self.next_lma_toggle = time + 5;
            return;
        }

        default:
            if (arg0 != "")
            {
                mapnumber = found_in_warp_list(arg0);
                if (mapnumber)
                {
                    votables_request_set_gametype_mode_map(-1, -1, mapnumber);
                    return;
                }
            }
        break;
    }

    if (FindNumericalInput(arg0))
    {
        return;
    }

    clientcommand(self, cmd);
    return;
};