/*  Copyright (C) 1996-1997  Id Software, Inc.

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

    See file, 'COPYING', for details.
*/

//void() InitBodyQue;

void() main =
{
    /*
    dprint ("main function\n");
// these are just commands the the prog compiler to copy these files
    precache_file ("progs.dat");
    precache_file ("gfx.wad");
    precache_file ("quake.rc");
    precache_file ("default.cfg");
    precache_file ("end1.bin");
    precache_file2 ("end2.bin");
    precache_file ("demo1.dem");
    precache_file ("demo2.dem");
    precache_file ("demo3.dem");
//
// these are all of the lumps from the cached.ls files
//
    precache_file ("gfx/palette.lmp");
    precache_file ("gfx/colormap.lmp");
    precache_file2 ("gfx/pop.lmp");
    precache_file ("gfx/complete.lmp");
    precache_file ("gfx/inter.lmp");
    precache_file ("gfx/ranking.lmp");
    precache_file ("gfx/vidmodes.lmp");
    precache_file ("gfx/finale.lmp");
    precache_file ("gfx/conback.lmp");
    precache_file ("gfx/qplaque.lmp");
    precache_file ("gfx/menudot1.lmp");
    precache_file ("gfx/menudot2.lmp");
    precache_file ("gfx/menudot3.lmp");
    precache_file ("gfx/menudot4.lmp");
    precache_file ("gfx/menudot5.lmp");
    precache_file ("gfx/menudot6.lmp");
    precache_file ("gfx/menuplyr.lmp");
    precache_file ("gfx/bigbox.lmp");
    precache_file ("gfx/dim_modm.lmp");
    precache_file ("gfx/dim_drct.lmp");
    precache_file ("gfx/dim_ipx.lmp");
    precache_file ("gfx/dim_tcp.lmp");
    precache_file ("gfx/dim_mult.lmp");
    precache_file ("gfx/mainmenu.lmp");
    precache_file ("gfx/box_tl.lmp");
    precache_file ("gfx/box_tm.lmp");
    precache_file ("gfx/box_tr.lmp");
    precache_file ("gfx/box_ml.lmp");
    precache_file ("gfx/box_mm.lmp");
    precache_file ("gfx/box_mm2.lmp");
    precache_file ("gfx/box_mr.lmp");
    precache_file ("gfx/box_bl.lmp");
    precache_file ("gfx/box_bm.lmp");
    precache_file ("gfx/box_br.lmp");
    precache_file ("gfx/sp_menu.lmp");
    precache_file ("gfx/ttl_sgl.lmp");
    precache_file ("gfx/ttl_main.lmp");
    precache_file ("gfx/ttl_cstm.lmp");
    precache_file ("gfx/mp_menu.lmp");
    precache_file ("gfx/netmen1.lmp");
    precache_file ("gfx/netmen2.lmp");
    precache_file ("gfx/netmen3.lmp");
    precache_file ("gfx/netmen4.lmp");
    precache_file ("gfx/netmen5.lmp");
    precache_file ("gfx/sell.lmp");
    precache_file ("gfx/help0.lmp");
    precache_file ("gfx/help1.lmp");
    precache_file ("gfx/help2.lmp");
    precache_file ("gfx/help3.lmp");
    precache_file ("gfx/help4.lmp");
    precache_file ("gfx/help5.lmp");
    precache_file ("gfx/pause.lmp");
    precache_file ("gfx/loading.lmp");
    precache_file ("gfx/p_option.lmp");
    precache_file ("gfx/p_load.lmp");
    precache_file ("gfx/p_save.lmp");
    precache_file ("gfx/p_multi.lmp");
// sounds loaded by C code
    precache_sound ("misc/menu1.wav");
    precache_sound ("misc/menu2.wav");
    precache_sound ("misc/menu3.wav");
    precache_sound ("ambience/water1.wav");
    precache_sound ("ambience/wind2.wav");
// shareware
    precache_file ("maps/start.bsp");
    precache_file ("maps/e1m1.bsp");
    precache_file ("maps/e1m2.bsp");
    precache_file ("maps/e1m3.bsp");
    precache_file ("maps/e1m4.bsp");
    precache_file ("maps/e1m5.bsp");
    precache_file ("maps/e1m6.bsp");
    precache_file ("maps/e1m7.bsp");
    precache_file ("maps/e1m8.bsp");
// registered
    precache_file2 ("gfx/pop.lmp");
    precache_file2 ("maps/e2m1.bsp");
    precache_file2 ("maps/e2m2.bsp");
    precache_file2 ("maps/e2m3.bsp");
    precache_file2 ("maps/e2m4.bsp");
    precache_file2 ("maps/e2m5.bsp");
    precache_file2 ("maps/e2m6.bsp");
    precache_file2 ("maps/e2m7.bsp");
    precache_file2 ("maps/e3m1.bsp");
    precache_file2 ("maps/e3m2.bsp");
    precache_file2 ("maps/e3m3.bsp");
    precache_file2 ("maps/e3m4.bsp");
    precache_file2 ("maps/e3m5.bsp");
    precache_file2 ("maps/e3m6.bsp");
    precache_file2 ("maps/e3m7.bsp");
    precache_file2 ("maps/e4m1.bsp");
    precache_file2 ("maps/e4m2.bsp");
    precache_file2 ("maps/e4m3.bsp");
    precache_file2 ("maps/e4m4.bsp");
    precache_file2 ("maps/e4m5.bsp");
    precache_file2 ("maps/e4m6.bsp");
    precache_file2 ("maps/e4m7.bsp");
    precache_file2 ("maps/e4m8.bsp");
    precache_file2 ("maps/end.bsp");
    precache_file2 ("maps/dm1.bsp");
    precache_file2 ("maps/dm2.bsp");
    precache_file2 ("maps/dm3.bsp");
    precache_file2 ("maps/dm4.bsp");
    precache_file2 ("maps/dm5.bsp");
    precache_file2 ("maps/dm6.bsp");
    */
};

entity lastspawn;

//=======================
/*QUAKED worldspawn (0 0 0) ?
Only used for the world entity.
Set message to the level name.
Set sounds to the cd track to play.

World Types:
0: medieval
1: metal
2: base
*/
//=======================
void() worldspawn =
{
    lastspawn 	= world;
    runespawn  	= world;
    team1_lastspawn = world;
    team2_lastspawn = world;
    ra_lastspawn = world;

//	InternalInit();
//	InitSearchHunk();
    //InitBodyQue ();
// custom map attributes
    if ((self.model == "maps/e1m8.bsp"))
    {
        cvar_set ("sv_gravity", "100");
    }
    else
    {
        cvar_set ("sv_gravity", "800");
    }

    forceinfokey (world, "intermission","off");
    
    // the area based ambient sounds MUST be the first precache_sounds
    
    // player precaches	
    //W_Precache ();								// get weapon precaches //moved to clanring_init_world

    // sounds used from C physics code
    precache_sound ("demon/dland2.wav");		// landing thud
    precache_sound ("misc/h2ohit1.wav");		// landing splash

// setup precaches allways needed
    precache_sound ("items/itembk2.wav");		// item respawn sound
    precache_sound ("player/plyrjmp8.wav");		// player jump
    precache_sound ("player/land.wav");			// player landing
    precache_sound ("player/land2.wav");		// player hurt landing
    precache_sound ("player/drown1.wav");		// drowning pain
    precache_sound ("player/drown2.wav");		// drowning pain
    precache_sound ("player/gasp1.wav");		// gasping for air
    precache_sound ("player/gasp2.wav");		// taking breath
    precache_sound ("player/h2odeath.wav");		// drowning death

    precache_sound ("misc/talk.wav");			// talk
    precache_sound ("player/teledth1.wav");		// telefrag
    precache_sound ("misc/r_tele1.wav");		// teleport sounds
    precache_sound ("misc/r_tele2.wav");
    precache_sound ("misc/r_tele3.wav");
    precache_sound ("misc/r_tele4.wav");
    precache_sound ("misc/r_tele5.wav");
    precache_sound ("weapons/lock4.wav");		// ammo pick up
    precache_sound ("weapons/pkup.wav");		// weapon up
    precache_sound ("items/armor1.wav");		// armor up
    precache_sound ("weapons/lhit.wav");		//lightning
    precache_sound ("weapons/lstart.wav");		//lightning start
    precache_sound ("items/damage3.wav");

    precache_sound ("misc/power.wav");			//lightning for boss
    precache_sound ("misc/secret.wav");
    precache_sound ("demon/ddeath.wav");

// player gib sounds
    precache_sound ("player/gib.wav");			// player gib sound
    precache_sound ("player/udeath.wav");		// player gib sound
    precache_sound ("player/tornoff2.wav");		// gib sound

// player pain sounds
    precache_sound ("player/pain1.wav");
    precache_sound ("player/pain2.wav");
    precache_sound ("player/pain3.wav");
    precache_sound ("player/pain4.wav");
    precache_sound ("player/pain5.wav");
    precache_sound ("player/pain6.wav");
// player death sounds
    precache_sound ("player/death1.wav");
    precache_sound ("player/death2.wav");
    precache_sound ("player/death3.wav");
    precache_sound ("player/death4.wav");
    precache_sound ("player/death5.wav");

// ax sounds	
    precache_sound ("weapons/ax1.wav");			// ax swoosh
    precache_sound ("player/axhit1.wav");		// ax hit meat
    precache_sound ("player/axhit2.wav");		// ax hit world

    precache_sound ("player/h2ojump.wav");		// player jumping into water
    precache_sound ("player/slimbrn2.wav");		// player enter slime
    precache_sound ("player/inh2o.wav");		// player enter water
    precache_sound ("player/inlava.wav");		// player enter lava
    precache_sound ("misc/outwater.wav");		// leaving water sound

    precache_sound ("player/lburn1.wav");		// lava burn
    precache_sound ("player/lburn2.wav");		// lava burn

    precache_sound ("misc/water1.wav");			// swimming
    precache_sound ("misc/water2.wav");			// swimming

    precache_sound ("misc/menu1.wav");
    precache_sound ("misc/menu2.wav");
    precache_sound ("fish/bite.wav");
    precache_sound ("boss2/pop2.wav");
    precache_model ("progs/player.mdl");
    precache_model ("progs/eyes.mdl");
    precache_model ("progs/h_player.mdl");
    precache_model ("progs/gib1.mdl");
    precache_model ("progs/gib2.mdl");
    precache_model ("progs/gib3.mdl");

    precache_model ("progs/s_bubble.spr");	// drowning bubbles
    precache_model ("progs/s_explod.spr");	// sprite explosion
    precache_model ("progs/v_axe.mdl");
    precache_model ("progs/v_shot.mdl");
    precache_model ("progs/v_nail.mdl");
    precache_model ("progs/v_rock.mdl");
    precache_model ("progs/v_shot2.mdl");
    precache_model ("progs/v_nail2.mdl");
    precache_model ("progs/v_rock2.mdl");
    precache_model ("progs/bolt.mdl");		// for lightning gun
    precache_model ("progs/bolt2.mdl");		// for lightning gun
    precache_model ("progs/bolt3.mdl");		// for boss shock
    precache_model ("progs/lavaball.mdl");	// for testing
    precache_model ("progs/missile.mdl");
    precache_model ("progs/grenade.mdl");
    precache_model ("progs/spike.mdl");
    precache_model ("progs/s_spike.mdl");
    precache_model ("progs/backpack.mdl");
    precache_model ("progs/zom_gib.mdl");
    precache_model ("progs/v_light.mdl");

    // ELOHIM_MOD - precache more stuff so that entity files will work
    precache_model ("maps/b_bh10.bsp");
    precache_sound ("items/r_item1.wav");
    precache_model ("maps/b_bh100.bsp");
    precache_sound ("items/r_item2.wav");
    precache_model ("maps/b_bh25.bsp");
    precache_sound ("items/health1.wav");
    precache_model ("progs/armor.mdl");
    precache_model ("progs/g_shot.mdl");
    precache_model ("progs/g_nail.mdl");
    precache_model ("progs/g_nail2.mdl");
    precache_model ("progs/g_rock.mdl");
    precache_model ("progs/g_rock2.mdl");
    precache_model ("progs/g_light.mdl");
    precache_model ("maps/b_shell1.bsp");
    precache_model ("maps/b_shell0.bsp");
    precache_model ("maps/b_nail1.bsp");
    precache_model ("maps/b_nail0.bsp");
    precache_model ("maps/b_rock1.bsp");
    precache_model ("maps/b_rock0.bsp");
    precache_model ("maps/b_batt1.bsp");
    precache_model ("maps/b_batt0.bsp");
    precache_model ("progs/invulner.mdl");
    precache_model ("progs/v_spike.mdl");
    precache_sound ("blob/land1.wav");
    precache_sound ("hknight/hit.wav");
    precache_sound ("items/protect.wav");
    precache_sound ("items/protect2.wav");
    precache_sound ("items/protect3.wav");
    precache_model ("progs/suit.mdl");
    precache_sound ("items/suit.wav");
    precache_sound ("items/suit2.wav");
    precache_model ("progs/invisibl.mdl");
    precache_sound ("items/inv1.wav");
    precache_sound ("items/inv2.wav");
    precache_sound ("items/inv3.wav");
    precache_model ("progs/quaddama.mdl");
    precache_sound ("items/damage.wav");
    precache_sound ("items/damage2.wav");
    precache_sound ("items/damage3.wav");

    precache_sound ("shambler/smack.wav");//tear-away hook sound
    precache_sound ("zombie/z_pain.wav");// inactive player sound

    //precache for ammo tossing -
    precache_model ("maps/b_batt0.bsp");
    precache_model ("maps/b_rock0.bsp");
    precache_model ("maps/b_nail0.bsp");
    precache_model ("maps/b_shell0.bsp");
    //---

    //--Runes-
    precache_model ("progs/end1.mdl");
    precache_model ("progs/end2.mdl");
    precache_model ("progs/end3.mdl");
    precache_model ("progs/end4.mdl");
    //--Runes-
    precache_sound("misc/runekey.wav");

    precache_sound ("boss1/sight1.wav"); //haste
    precache_sound ("hknight/slash1.wav"); //rune toss
    precache_sound ("misc/basekey.wav"); //flag dropped notification
    precache_sound("buttons/switch04.wav"); //match timer countdown
    precache_sound("crx/prepare.wav");

    precache_sound("enforcer/sight3.wav");//Item tossing "You There!"
    precache_sound ("ra/laugh.wav"); // Powerup Denied sound.
    //precache_model ("progs/spawn.mdl");
    
    //
    // Setup light animation tables. 'a' is total darkness, 'z' is maxbright.
    //

    // 0 normal
    lightstyle(0, "m");

    // 1 FLICKER (first variety)
    lightstyle(1, "mmnmmommommnonmmonqnmmo");

    // 2 SLOW STRONG PULSE
    lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");

    // 3 CANDLE (first variety)
    lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");

    // 4 FAST STROBE
    lightstyle(4, "mamamamamama");

    // 5 GENTLE PULSE 1
    lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");

    // 6 FLICKER (second variety)
    lightstyle(6, "nmonqnmomnmomomno");

    // 7 CANDLE (second variety)
    lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");

    // 8 CANDLE (third variety)
    lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");

    // 9 SLOW STROBE (fourth variety)
    lightstyle(9, "aaaaaaaazzzzzzzz");

    // 10 FLUORESCENT FLICKER
    lightstyle(10, "mmamammmmammamamaaamammma");

    // 11 SLOW PULSE NOT FADE TO BLACK
    lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");

    // styles 32-62 are assigned by the light program for switchable lights

    // 63 testing
    lightstyle(63, "a");

    clanring_init_world ();    // ELOHIM_MOD - do server specific stuff
    isFTEserver = checkextension("FTE_MULTIPROGS");
    if (isFTEserver) print ("FTE server detected.\n");
};

void() StartFrame =
{
    local entity serverinactive;
    //this restarts the server after 6 hour if no one is on the server
    //it keeps the server running smooth

    if (!(clanring_state & CLANRING_MATCH_PAUSED))
    {
        if (clanring_playmode & CLANRING_CONSOLE_INITIALIZED)
        {
            if (clanring_levelcount == -1)
            {
                if (time > 21600)
                {
                    serverinactive = find(world, classname, "player");
                    if (serverinactive == world)
                    {
                        localcmd(";restart;\n");
                        clanring_playmode = (clanring_playmode - CLANRING_CONSOLE_INITIALIZED);
                    }
                }
            }
        }
    }
    
    framecount = framecount + 1;
    
    if (framecount == 1)	
    {
        // Check if we have a custom ents_dir set from warp.cfg
        string current_ents_dir = cvar_string("external_ents_dir");
        float found_custom_ents = FALSE;
        
        // Search warpmap array to see if current ents_dir matches any custom setting
        for (float i = 1; i < (WARP_CATEGORY_SIZE * WARP_MAPLIST_SIZE); i++)
        {
            if (warpmap[i].ents_dir != "" && 
                warpmap[i].ents_dir == current_ents_dir)
            {
                found_custom_ents = TRUE;
                break;
            }
        }
        
        if (found_custom_ents)
        {
            // Keep the custom external_ents_dir
            // Don't change it
        }
        else if ((cvar("gamecfg")) & CLANRING_ALTERNATIVE_ENTS)
        {
            if ((cvar("samelevel")) & CLANRING_CAPTURE_THE_FLAG)
                cvar_set("external_ents_dir", "ctf_alt");
            else
                cvar_set("external_ents_dir", "dm_alt");	
        }
        else
        {
            if ((cvar("samelevel")) & CLANRING_CAPTURE_THE_FLAG)
                cvar_set("external_ents_dir", "ctf");
            else
                cvar_set("external_ents_dir", "");	
        }
    }

    clanring_start_frame();
};


// 2001-11-18 Random number function  start
/*
General solution to always get a valid random number of a given range and stepsize.

All possible values have the same chance of being calculated.
(Ok, the last value has a slighlty higher chance :)

It works for negative and positive parameters, only the stepsize should fit the range:
end > start : positive stepsize
start > end : negative stepsize

Note that the typical "result = START + floor( random() * ( COUNT - 0.01 ) )"
only works for positive integer ranges with stepsize +1.
*/
float(float start, float end, float stepsize) rnd_number =
{
    local float	rcnt;
    local float	rnd;
    local float result;

    // calculate the number of possible different values
    rcnt = floor( fabs( ( end - start ) / stepsize ) ) + 1;

    // calculate the random part of the result value
    rnd = floor( random() * rcnt );
    if ( rnd == rcnt )
    {
        rnd = rnd - 1;
    }

    // calculate the result value
    result = start + ( rnd * stepsize );

    return result;
};
// 2001-11-18 Random number function  end
