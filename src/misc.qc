// ELOHIM_MOD - spawn function for event_lightning
void() event_lightning =
{
	remove(self);
};

// END_MOD

float START_OFF		= 1;
float FADE_IN_OUT	= 2;

/*QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
*/
void() info_null =
{
    // ELOHIM_MOD - this was used for development
    if (mapname == "eliltest")
    {
        self.classname = "player";

        self.health = 100;
        self.takedamage = DAMAGE_NO;
        self.solid = SOLID_SLIDEBOX;
        self.movetype = MOVETYPE_STEP;
        //self.movetype = MOVETYPE_FLY;
        //self.velocity = '-30 0 15';
        self.velocity = '0 0 0';
        self.angles = self.v_angle = '0 45 0';
        self.fixangle = TRUE;
        self.show_hostile = 0;
        self.max_health = 100;
        self.air_finished = time + 12;
        self.dmg = 2;           // initial water damage
        self.super_damage_finished = 0;
        self.radsuit_finished = 0;
        self.invisible_finished = 0;
        self.invincible_finished = 0;
        self.effects = 0;
        self.invincible_time = 0;
    
        SetNewParms ();
        DecodeLevelParms ();
     
        W_SetCurrentAmmo();
        self.weapon = 16;
        self.armorvalue = 200;
        self.armortype = 0.8;
        self.currentammo = 100;
    
        self.attack_finished = time;
     
        self.deadflag = DEAD_NO;
     
        setmodel (self, "progs/player.mdl");
        setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

        player_stand1();
    }
    else
    // END_MOD
        remove(self);
};


/*QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for lightning.
*/
void() info_notnull =
{
};

/*==========
lightstyle_lookup
==========*/
string(float num) lightstyle_lookup =
{
	switch (num)
	{
		// 0 normal
		case 0:
			return "m";
			break;
		// 1 FLICKER (first variety)
		case 1:
			return "mmnmmommommnonmmonqnmmo";
			break;
		// 2 SLOW STRONG PULSE
		case 2:
			return "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba";
			break;
		// 3 CANDLE (first variety)
		case 3:
			return "mmmmmaaaaammmmmaaaaaabcdefgabcdefg";
			break;
		// 4 FAST STROBE
		case 4:
			return "mamamamamama";
			break;
		// 5 GENTLE PULSE 1
		case 5:
			return "jklmnopqrstuvwxyzyxwvutsrqponmlkj";
			break;
		// 6 FLICKER (second variety)
		case 6:
			return "nmonqnmomnmomomno";
			break;
		// 7 CANDLE (second variety)
		case 7:
			return "mmmaaaabcdefgmmmmaaaammmaamm";
			break;
		// 8 CANDLE (third variety)
		case 8:
			return "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa";
			break;
		// 9 SLOW STROBE (fourth variety)
		case 9:
			return "aaaaaaaazzzzzzzz";
			break;
		// 10 FLUORESCENT FLICKER
		case 10:
			return "mmamammmmammamamaaamammma";
			break;
		// 11 SLOW PULSE NOT FADE TO BLACK
		case 11:
			return "abcdefghijklmnopqrrqponmlkjihgfedcba";
			break;
		// 12 BLINK OFF / ON (can be synced with animated textures, e.g. +0light and +1light)
		case 12:
			return "aamm";	// textures animate at 5fps but lights are 10fps...
			break;
		// DEFAULT
		default:
			return "a";
			break;
	}
};

/*==========
setup_lightstyles

Setup light animation tables. 'a' is total darkness, 'z' is maxbright.
Styles 32+ are assigned by the light program for switchable lights.
==========*/
void() setup_lightstyles =
{
	for (float i = 0; i <= 12; i++)
	{
		lightstyle(i, lightstyle_lookup(i));
	}
};

/*==========
lightstyle_fade_lookup
==========*/
string(float num) lightstyle_fade_lookup =
{
	switch (num)
	{
		case 0:
			return "a";
			break;
		case 1:
			return "b";
			break;
		case 2:
			return "c";
			break;
		case 3:
			return "d";
			break;
		case 4:
			return "e";
			break;
		case 5:
			return "f";
			break;
		case 6:
			return "g";
			break;
		case 7:
			return "h";
			break;
		case 8:
			return "i";
			break;
		case 9:
			return "j";
			break;
		case 10:
			return "k";
			break;
		case 11:
			return "l";
			break;
		case 12:
			return "m";
			break;
		default:
			error("count out of range\n");
			break;
	}
};

/*==========
light_fade_in
==========*/
void() light_fade_in =
{
	if (self.count < 0)
		self.count = 0;
	if (self.count > 12)
		self.count = 12;

	lightstyle(self.style, lightstyle_fade_lookup(self.count));
	self.count = self.count + 1;
	if (self.count > 12)
		return;

	self.think = light_fade_in;
	self.nextthink = time + self.speed;
};

/*==========
light_fade_out
==========*/
void() light_fade_out =
{
	if (self.count < 0)
		self.count = 0;
	if (self.count > 12)
		self.count = 12;

	lightstyle(self.style, lightstyle_fade_lookup(self.count));
	self.count = self.count - 1;
	if (self.count < 0)
		return;

	self.think = light_fade_out;
	self.nextthink = time + self.speed;
};

void() light_use =
{
	if (self.spawnflags & START_OFF)
	{
		self.spawnflags = self.spawnflags - START_OFF;
		if (self.spawnflags & FADE_IN_OUT && !self.style2)
			light_fade_in();
		else
			lightstyle(self.style, lightstyle_lookup(self.style2));
	}
	else
	{
		self.spawnflags = self.spawnflags + START_OFF;
		if (self.spawnflags & FADE_IN_OUT && !self.style2)
			light_fade_out();
		else
			lightstyle(self.style, "a");
	}
};

/*QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
*/
void() light =
{
	// default speed for fading in/out
	if (self.speed <= 0)
		self.speed = 0.1;

	if (!self.targetname)
	{	// inert light
		remove(self);
		return;
	}
	
	if (self.style >= 32)
	{
		self.use = light_use;
		if (self.spawnflags & START_OFF)
		{
			self.count = 0;
			lightstyle(self.style, "a");
		}
		else
		{
			self.count = 12;
			lightstyle(self.style, lightstyle_lookup(self.style2));
		}
	}
};


/*QUAKED light_fluoro (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
Makes steady fluorescent humming sound
*/
void() light_fluoro =
{
	if (self.style >= 32)
	{
		self.use = light_use;
		if (self.spawnflags & START_OFF)
			lightstyle(self.style, "a");
		else
			lightstyle(self.style, "m");
	}
	
	precache_sound ("ambience/fl_hum1.wav");
	ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_fluorospark (0 1 0) (-8 -8 -8) (8 8 8)
Non-displayed light.
Default light value is 300
Default style is 10
Makes sparking, broken fluorescent sound
*/
void() light_fluorospark =
{
	if (!self.style)
		self.style = 10;

	precache_sound ("ambience/buzz1.wav");
	ambientsound (self.origin, "ambience/buzz1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_globe (0 1 0) (-8 -8 -8) (8 8 8)
Sphere globe light.
Default light value is 300
Default style is 0
*/
void() light_globe =
{
	precache_model ("progs/s_light.spr");
	setmodel (self, "progs/s_light.spr");
	makestatic (self);
};


void() FireAmbient =
{
	precache_sound ("ambience/fire1.wav");
	ambientsound (self.origin, "ambience/fire1.wav", 0.2, ATTN_STATIC);
};

/*QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
Short wall torch
Default light value is 200
Default style is 0
*/
void() light_torch_small_walltorch =
{
	precache_model ("progs/flame.mdl");
	setmodel (self, "progs/flame.mdl");
	FireAmbient ();
	makestatic (self);
};

/*QUAKED light_flame_large_yellow (0 1 0) (-10 -10 -12) (12 12 18)
Large yellow flame ball
*/
void() light_flame_large_yellow =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	self.frame = 1;
	FireAmbient ();
	makestatic (self);
};

/*QUAKED light_flame_small_yellow (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Small yellow flame ball
*/
void() light_flame_small_yellow =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	FireAmbient ();
	makestatic (self);
};

/*QUAKED light_flame_small_white (0 1 0) (-10 -10 -40) (10 10 40) START_OFF
Small white flame ball
*/
void() light_flame_small_white =
{
	precache_model ("progs/flame2.mdl");
	setmodel (self, "progs/flame2.mdl");
	FireAmbient ();
	makestatic (self);
};

//============================================================================


/*QUAKED misc_fireball (0 .5 .8) (-8 -8 -8) (8 8 8)
Lava Balls
*/
void() fire_fly;
void() fire_touch;

void() misc_fireball =
{ 
	precache_model ("progs/lavaball.mdl");
	self.classname = "fireball";
	self.nextthink = time + 0.1 + (random() * 5);
	self.think = fire_fly;
	
	if (!self.speed) 
		self.speed = 1000;
};

void() fire_fly =
{
local entity	fireball;

	fireball = spawn();
	fireball.solid = SOLID_TRIGGER;
	fireball.movetype = MOVETYPE_TOSS;
	fireball.velocity = '0 0 1000';
	fireball.velocity_x = (random() * 100) - 50;
	fireball.velocity_y = (random() * 100) - 50;
	fireball.velocity_z = self.speed + (random() * 200);
	fireball.classname = "fireball";
	setmodel (fireball, "progs/lavaball.mdl");
	setsize (fireball, '0 0 0', '0 0 0');
	setorigin(fireball, self.origin);
	fireball.nextthink = time + 5;
	fireball.think = SUB_Remove;
	fireball.touch = fire_touch;
	
	self.nextthink = time + (random() * 5) + 3;
	self.think = fire_fly;
};


void() fire_touch =
{
	T_Damage (other, self, self, 20);
	remove(self);
};

//============================================================================

// 1998-08-08 T_RadiusDamage workaround by Patrick Martin  start
void() barrel_damage =
{
	T_RadiusDamage (self, self, 160, world, "");	// 1998-07-24 Wrong obituary messages fix by Zoid
	sound (self, CHAN_VOICE, "weapons/r_exp3.wav", 1, ATTN_NORM);
	particle (self.origin, '0 0 0', 75, 255);
	self.origin_z = self.origin_z + 32;
	BecomeExplosion ();
};
// 1998-08-08 T_RadiusDamage workaround by Patrick Martin  end

void() barrel_explode =
{
	self.takedamage = DAMAGE_NO;
	self.classname = "explo_box";
	self.nextthink = time + 0.1;
	self.think = barrel_damage;
// 1998-08-08 T_RadiusDamage workaround by Patrick Martin  end
};

/*QUAKED misc_explobox (0 .5 .8) (0 0 0) (32 32 64)
TESTING THING
*/

void() misc_explobox =
{
	local float oldz;

	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_NONE;
	precache_model ("maps/b_explob.bsp");
	setmodel (self, "maps/b_explob.bsp");
	precache_sound ("weapons/r_exp3.wav");
	self.health = 20;
	self.th_die = barrel_explode;
	self.takedamage = DAMAGE_AIM;

	self.origin_z = self.origin_z + 2;
	oldz = self.origin_z;
	droptofloor();
	if (oldz - self.origin_z > 250)
	{
		dprint ("item fell out of level at ");
		dprint (vtos (self.origin));
		dprint ("\n");
		remove(self);
	}
};

/*QUAKED misc_explobox2 (0 .5 .8) (0 0 0) (32 32 64)
Smaller exploding box, REGISTERED ONLY
*/

void() misc_explobox2 =
{
	local float oldz;

	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_NONE;
	precache_model2 ("maps/b_exbox2.bsp");
	setmodel (self, "maps/b_exbox2.bsp");
	precache_sound ("weapons/r_exp3.wav");
	self.health = 20;
	self.th_die = barrel_explode;
	self.takedamage = DAMAGE_AIM;
	self.origin_z = self.origin_z + 2;
	oldz = self.origin_z;
	droptofloor();
	if (oldz - self.origin_z > 250)
	{
		dprint ("item fell out of level at ");
		dprint (vtos (self.origin));
		dprint ("\n");
		remove(self);
	}
};

//============================================================================

float SPAWNFLAG_SUPERSPIKE    = 1;
float SPAWNFLAG_LASER    = 2;

void() spikeshooter_use =
{
	if (self.spawnflags & SPAWNFLAG_LASER)
	{
		sound (self, CHAN_VOICE, "enforcer/enfire.wav", 1, ATTN_NORM);
		LaunchLaser (self.origin, self.movedir);
	}
	else
	{
		sound (self, CHAN_VOICE, "weapons/spike2.wav", 1, ATTN_NORM);
		launch_spike (self.origin, self.movedir,500);
		//newmis.velocity = self.movedir * 500;
		if (self.spawnflags & SPAWNFLAG_SUPERSPIKE)
			newmis.touch = superspike_touch;
	}
};

void() shooter_think =
{
	spikeshooter_use ();
	self.nextthink = time + self.wait;
	newmis.velocity = self.movedir * 500;
};


/*QUAKED trap_spikeshooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
When triggered, fires a spike in the direction set in QuakeEd.
Laser is only for REGISTERED.
*/

void() trap_spikeshooter =
{
	SetMovedir ();
	self.use = spikeshooter_use;
	if (self.spawnflags & SPAWNFLAG_LASER)
	{
		precache_model2 ("progs/laser.mdl");
		precache_sound2 ("enforcer/enfire.wav");
		precache_sound2 ("enforcer/enfstop.wav");
	}
	else
		precache_sound ("weapons/spike2.wav");
};

/*QUAKED trap_shooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
Continuously fires spikes.
"wait" time between spike (1.0 default)
"nextthink" delay before firing first spike, so multiple shooters can be stagered.
*/
void() trap_shooter =
{
	trap_spikeshooter ();

	if (self.wait == 0)
		self.wait = 1;
	self.nextthink = self.nextthink + self.wait + self.ltime;
	self.think = shooter_think;
};

/*
===============================================================================


===============================================================================
*/

void() make_bubbles;
void() bubble_remove;

/*QUAKED air_bubbles (0 .5 .8) (-8 -8 -8) (8 8 8)

testing air bubbles
*/

void() air_bubbles =

{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model ("progs/s_bubble.spr");
	self.nextthink = time + 1;
	self.think = make_bubbles;
};

void() make_bubbles =
{
local entity	bubble;

	bubble = spawn();
	setmodel (bubble, "progs/s_bubble.spr");
	setorigin(bubble, self.origin);
	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = '0 0 15';
	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;
	bubble.touch = bubble_remove;
	bubble.classname = "bubble";
	bubble.frame = 0;
	bubble.cnt = 0;
	setsize (bubble, '-8 -8 -8', '8 8 8');
	self.nextthink = time + random() + 0.5;
	self.think = make_bubbles;
};


void() bubble_split =
{
local entity	bubble;
	bubble = spawn();
	setmodel (bubble, "progs/s_bubble.spr");
	setorigin(bubble, self.origin);
	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = self.velocity;
	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;
	bubble.touch = bubble_remove;
	bubble.classname = "bubble";
	bubble.frame = 1;
	bubble.cnt = 10;
	setsize (bubble, '-8 -8 -8', '8 8 8');
	self.frame = 1;
	self.cnt = 10;
	if (self.waterlevel != 3)
		remove(self);
};

void() bubble_remove=
{
	if (other.classname == self.classname)
	{
//		dprint ("bump");
		return;
	}
	remove(self);
};

void() bubble_bob =
{
local float		rnd1, rnd2, rnd3;
//local vector	vtmp1, modi;

	self.cnt = self.cnt + 1;
	if (self.cnt == 4)
		bubble_split();
	if (self.cnt == 20)
		remove(self);

	rnd1 = self.velocity_x + (-10 + (random() * 20));
	rnd2 = self.velocity_y + (-10 + (random() * 20));
	rnd3 = self.velocity_z + 10 + random() * 10;

	if (rnd1 > 10)
		rnd1 = 5;
	if (rnd1 < -10)
		rnd1 = -5;
		
	if (rnd2 > 10)
		rnd2 = 5;
	if (rnd2 < -10)
		rnd2 = -5;
		
	if (rnd3 < 10)
		rnd3 = 15;
	if (rnd3 > 30)
		rnd3 = 25;
	
	self.velocity_x = rnd1;
	self.velocity_y = rnd2;
	self.velocity_z = rnd3;
		
	self.nextthink = time + 0.5;
	self.think = bubble_bob;
};

/*~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>
~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~<~>~*/

/*QUAKED viewthing (0 .5 .8) (-8 -8 -8) (8 8 8)

Just for the debugging level.  Don't use
*/

void() viewthing =

{
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	precache_model ("progs/player.mdl");
	setmodel (self, "progs/player.mdl");
};


/*
==============================================================================

SIMPLE BMODELS

==============================================================================
*/

void() func_wall_use =
{	// change to alternate textures
	self.frame = 1 - self.frame;
};

/*QUAKED func_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
*/
void() func_wall =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};


/*QUAKED func_illusionary (0 .5 .8) ?
A simple entity that looks solid but lets you walk through it.
*/
void() func_illusionary =

{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel (self, self.model);
	makestatic (self);
};

/*QUAKED func_episodegate (0 .5 .8) ? E1 E2 E3 E4
This bmodel will appear if the episode has allready been completed, so players can't reenter it.
*/
void() func_episodegate =

{
	if (!(serverflags & self.spawnflags))
		return;			// can still enter episode

	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};

/*QUAKED func_bossgate (0 .5 .8) ?
This bmodel appears unless players have all of the episode sigils.
*/
void() func_bossgate =

{
	if ( (serverflags & 15) == 15)
		return;		// all episodes completed
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};

//============================================================================
/*QUAKED ambient_suck_wind (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_suck_wind =
{
	precache_sound ("ambience/suck1.wav");
	ambientsound (self.origin, "ambience/suck1.wav", 1, ATTN_STATIC);
};

/*QUAKED ambient_drone (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_drone =
{
	precache_sound ("ambience/drone6.wav");
	ambientsound (self.origin, "ambience/drone6.wav", 0.5, ATTN_STATIC);
};

/*QUAKED ambient_flouro_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_flouro_buzz =
{
	precache_sound ("ambience/buzz1.wav");
	ambientsound (self.origin, "ambience/buzz1.wav", 1, ATTN_STATIC);
};
/*QUAKED ambient_drip (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_drip =
{
	precache_sound ("ambience/drip1.wav");
	ambientsound (self.origin, "ambience/drip1.wav", 0.5, ATTN_STATIC);
};
/*QUAKED ambient_comp_hum (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_comp_hum =
{
	precache_sound ("ambience/comp1.wav");
	ambientsound (self.origin, "ambience/comp1.wav", 1, ATTN_STATIC);
};
/*QUAKED ambient_thunder (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_thunder =
{
	precache_sound ("ambience/thunder1.wav");
	ambientsound (self.origin, "ambience/thunder1.wav", 0.5, ATTN_STATIC);
};
/*QUAKED ambient_light_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_light_buzz =
{
	precache_sound ("ambience/fl_hum1.wav");
	ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
};
/*QUAKED ambient_swamp1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_swamp1 =
{
	precache_sound ("ambience/swamp1.wav");
	ambientsound (self.origin, "ambience/swamp1.wav", 0.5, ATTN_STATIC);
};
/*QUAKED ambient_swamp2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void() ambient_swamp2 =
{
	precache_sound ("ambience/swamp2.wav");
	ambientsound (self.origin, "ambience/swamp2.wav", 0.5, ATTN_STATIC);
};

//============================================================================

void() noise_think =
{
	self.nextthink = time + 0.5;
	sound (self, 1, "enforcer/enfire.wav", 1, ATTN_NORM);
	sound (self, 2, "enforcer/enfstop.wav", 1, ATTN_NORM);
	sound (self, 3, "enforcer/sight1.wav", 1, ATTN_NORM);
	sound (self, 4, "enforcer/sight2.wav", 1, ATTN_NORM);
	sound (self, 5, "enforcer/sight3.wav", 1, ATTN_NORM);
	sound (self, 6, "enforcer/sight4.wav", 1, ATTN_NORM);
	sound (self, 7, "enforcer/pain1.wav", 1, ATTN_NORM);
};

/*QUAKED misc_noisemaker (1 0.5 0) (-10 -10 -10) (10 10 10)

For optimzation testing, starts a lot of sounds.
*/

void() misc_noisemaker =

{
	precache_sound2 ("enforcer/enfire.wav");
	precache_sound2 ("enforcer/enfstop.wav");
	precache_sound2 ("enforcer/sight1.wav");
	precache_sound2 ("enforcer/sight2.wav");
	precache_sound2 ("enforcer/sight3.wav");
	precache_sound2 ("enforcer/sight4.wav");
	precache_sound2 ("enforcer/pain1.wav");
	precache_sound2 ("enforcer/pain2.wav");
	precache_sound2 ("enforcer/death1.wav");
	precache_sound2 ("enforcer/idle1.wav");

	self.nextthink = time + 0.1 + random();
	self.think = noise_think;
};

/*****************
func_togglevisiblewall

A bmodel which you can toggle its visibility. Behaves much like a traditional func_wall in any other way,
but you can target it to toggle visible/invisible.
If the entity has a switchable shadow it also toggles.

spawnflag 1: starts invisible
spawnflag 2: set brush as non-solid

******************/

float TOGGLEVISWALL_STARTOFF = 1;
float TOGGLEVISWALL_NOTSOLID = 2;

void() func_togglevisiblewall_use =
{
	if(!self.state) {
		if(!(self.spawnflags & TOGGLEVISWALL_NOTSOLID)) {
			self.solid = SOLID_BSP;
			self.movetype = MOVETYPE_PUSH;
		}
		setmodel (self, self.origmodel);
		if(self.switchshadstyle) lightstyle(self.switchshadstyle, "a");
		self.state = 1;
	} else {

		self.solid = SOLID_NOT;
		self.movetype = MOVETYPE_NONE;
		setmodel (self, "");
		if(self.switchshadstyle) lightstyle(self.switchshadstyle, "m");
		self.state = 0;
	}

};

void() func_togglevisiblewall =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;

	self.angles = '0 0 0';
	self.use = func_togglevisiblewall_use;

	self.origmodel = self.model;

	if(self.spawnflags & TOGGLEVISWALL_STARTOFF) self.state = 1;
	else self.state = 0;

	if(self.spawnflags & TOGGLEVISWALL_NOTSOLID) {
		self.solid = SOLID_NOT;
		self.movetype = MOVETYPE_NONE;
	}

	func_togglevisiblewall_use();

};

/*****************
func_shadow

An invisible bmodel that can be used to only cast shadows.

******************/

void() func_shadow = {
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;

	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;

	self.modelindex = 0;
	self.model = "";

}

/********************
misc_shadowcontroller

Controls switchable shadows on any bmodel entity (except doors).
Target entity must have set _switchableshadow set to 1.

speed: Controls the time in seconds it takes to fade the shadow in. Default is 0.5, and setting it to -1 disables fading.
speed2: Same as 'speed' but for the fade out animation. If unset it's the same value as 'speed'.
spawnflag 1: target shadow starts as disabled

*********************/

float SHADOWCONTROLLER_STARTOFF = 1;

void() shadow_fade_out =
{
	if (self.count < 0)
		self.count = 0;
	if (self.count > 12)
		self.count = 12;

	dprint(ftos(self.count));dprint("\n");

	lightstyle(self.switchshadstyle, lightstyle_fade_lookup(self.count));
	self.count = self.count + self.dmg;
	if (self.count > 12)
		return;

	self.think = shadow_fade_out;
	self.nextthink = time + self.delay;
};

void() shadow_fade_in =
{
	if (self.count < 0)
		self.count = 0;
	if (self.count > 12)
		self.count = 12;

	dprint(ftos(self.count));dprint("\n");

	lightstyle(self.switchshadstyle, lightstyle_fade_lookup(self.count));
	self.count = self.count - self.dmg;
	if (self.count < 0)
		return;

	self.think = shadow_fade_in;
	self.nextthink = time + self.delay;

};

void(float speed) misc_shadowcontroller_setsteps = {
	// self.delay -> time between steps
	// self.dmg -> step size
	if(speed >= 0.24) {
		self.delay = (speed/12);
		self.dmg = 1;
	}
	else if(speed >= 0.12) {
		self.delay = (speed/6);
		self.dmg = 2;
	}
	else if(speed >= 0.06) {
		self.delay = (speed/3);
		self.dmg = 4;
	}
	else if(speed >= 0.04) {
		self.delay = (speed/2);
		self.dmg = 6;
	}
	else {
		self.delay = 0;
		self.dmg = 12;
	}

}

void() misc_shadowcontroller_use = {

	if(self.shadowoff) {
		dprint("Fade in:\n");

		misc_shadowcontroller_setsteps(self.speed);

		shadow_fade_in();

		self.shadowoff = 0;
	} else {
		dprint("Fade out:\n");

		misc_shadowcontroller_setsteps(self.speed2);

		shadow_fade_out();

		self.shadowoff = 1;
	}
}

void() misc_shadowcontroller = {
	entity t1;

	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;


	// doesn't search for a target if switchshadstyle is already set
	// used for built-in shadow controllers
	if(!self.switchshadstyle) {

		// we need to find only the first target entity with switchable shadows set, since shadow lightstyles are bound by targetname


		t1 = find(world, targetname2, self.target);

		while(t1 != world && !t1.switchshadstyle) {
			t1 = find(t1, targetname2, self.target);
		}

		if(t1 == world) {
			t1 = find(world, targetname, self.target);

			while(t1 != world && !t1.switchshadstyle) {
				t1 = find(t1, targetname, self.target);
			}
		}


		if(t1 == world) {
			dprint("\b[misc_shadowcontroller]\b _switchableshadow not set in target ");dprint(self.target);dprint("\n");
			return;
		}

		self.switchshadstyle = t1.switchshadstyle;
	}

	if(!self.speed) self.speed = 0.5;
	if(!self.speed2) self.speed2 = self.speed;

	if(self.spawnflags & SHADOWCONTROLLER_STARTOFF) {
		lightstyle(self.switchshadstyle, "m");

		self.shadowoff = 1;
		self.count = 12;

		misc_shadowcontroller_setsteps(self.speed2);
	}
	else {
		lightstyle(self.switchshadstyle, "a");
		self.shadowoff = 0;
		self.count = 0;
		misc_shadowcontroller_setsteps(self.speed);
	}

	self.use = misc_shadowcontroller_use;
}

void() unsupported_entity_warning =
{
	print(sprintf("Warning: ignoring unsupported entity '%s' (edict %s at %s)\n",
		self.classname,
		ftos(num_for_edict(self)),
		vtos(self.origin)));
	remove(self);
};

// FTE/QSS call this when a classname has no matching spawn function.
void() SV_OnEntityNoSpawnFunction =
{
	unsupported_entity_warning();
};

// Stub out known unsupported entities so older spawn paths still soft-fail.
void() info_referee =
{
	unsupported_entity_warning();
};
