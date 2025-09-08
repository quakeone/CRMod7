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
void()W_ChangeWeapon;
void() player_run;
void(vector org, vector vel, float damage) SpawnBlood;
void() SuperDamageSound;
void() HasteSound;
void()	player_hook4;

// called by worldspawn
void() W_Precache =
{
	precache_sound ("weapons/r_exp3.wav");		// new rocket explosion
	precache_sound ("weapons/rocket1i.wav");	// spike gun
	precache_sound ("weapons/sgun1.wav");
	precache_sound ("weapons/guncock.wav");		// player shotgun
	precache_sound ("weapons/ric1.wav");		// ricochet (used in c code)
	precache_sound ("weapons/ric2.wav");		// ricochet (used in c code)
	precache_sound ("weapons/ric3.wav");		// ricochet (used in c code)
	precache_sound ("weapons/spike2.wav");		// super spikes
	precache_sound ("weapons/tink1.wav");		// spikes tink (used in c code)
	precache_sound ("weapons/grenade.wav");		// grenade launcher
	precache_sound ("weapons/bounce.wav");		// grenade bounce
	precache_sound ("weapons/shotgn2.wav");		// super shotgun
	precache_sound ("knight/sword1.wav");		//server modules hook
	precache_sound ("shambler/smack.wav");  	// hook tear

	if ((clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM) || (mode_is_arena())) //FIXME: Forcing these precaches requires all connecting clients to have these assets, even in pub modes :|
	{		
		precache_sound ("weapons/chain1.wav");
		precache_sound ("weapons/chain2.wav");
		precache_sound ("weapons/chain3.wav");
		precache_sound ("weapons/bounce2.wav");
		precache_model ("progs/star.mdl");
		precache_model ("progs/bit.mdl");
		precache_model ("progs/v_star.mdl");			
		precache_sound ("rune/rune1.wav");
		precache_sound ("rune/rune2.wav");
		precache_sound ("rune/rune22.wav"); // special rune and quad combo
		precache_sound ("rune/rune3.wav");
		precache_sound ("rune/rune4.wav");
	}
};

float() crandom =
{
	return 2*(random() - 0.5);
};

void () Practice_Object_Remove =
{
	local entity e;
	
	e = find (world, classname, "practice_object");
		
	if (e != world)
	{
		remove (e);
	}
};

/*
================
W_FireAxe
================
*/
void() W_FireAxe =
{
	local	vector	source;
	local	vector	org;

	makevectors (self.v_angle);
	source = self.origin + '0 0 16';
	traceline (source, source + v_forward*64, FALSE, self);

	if (trace_fraction == 1.0)
		return;
	
	// Prewar: ignore LMA players (and skip visuals)
	if (!match_in_progress() && trace_ent && trace_ent.classname == "player" && trace_ent.leavemealone)
		return;
	
	org = trace_endpos - v_forward*4;

	if (trace_ent.takedamage)
	{
		trace_ent.axhitme = 1;

		if (trace_ent.classname =="player")
		{
			SpawnBlood (org, '0 0 0', 20);//only players bleed
		}
		else
		{ // R00k: triggers get smacked
			sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
			WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
			WriteByte(MSG_BROADCAST, TE_GUNSHOT);
			WriteCoord (MSG_BROADCAST, org_x);
			WriteCoord (MSG_BROADCAST, org_y);
			WriteCoord (MSG_BROADCAST, org_z);
		}
		if (clanring_playmode & CLANRING_CA_MODE)
			T_Damage (trace_ent, self, self, 80);//CAx is x4 axe damage
		else
			T_Damage (trace_ent, self, self, 20);//still do the damage
	}
	else
	{	// hit wall
		sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};

//============================================================================

vector() wall_velocity =
{
	local vector	vel;
	
	vel = normalize (self.velocity);
	vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;
	
	return vel;
};

/*
================
SpawnMeatSpray
================
*/
void(vector org, vector vel) SpawnMeatSpray =
{
	local entity missile;

	missile = spawn();
	missile.classname = "gibs";
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_NOT;
	makevectors (self.angles);
	missile.velocity = vel;
	missile.velocity_z = missile.velocity_z + 250 + 50*random();
	missile.avelocity = '3000 1000 2000';
// set missile duration
	missile.nextthink = time + 1;
	missile.think = SUB_Remove;
	setmodel (missile, "progs/zom_gib.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin(missile, org);
};

/*
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{
	particle (org, vel*0.1, 73, damage*2);
};

/*
================
spawn_touchblood
================
*/
void(float damage) spawn_touchblood =
{
	local vector	vel;

	vel = wall_velocity () * 0.2;
	SpawnBlood (self.origin + vel*0.01, vel, damage);
};

/*
================
SpawnChunk
================
*/
void(vector org, vector vel) SpawnChunk =
{
	particle (org, vel*0.02, 0, 10);
};

/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/
//--------------------------
// Orion's Multi_Damage Fix
//--------------------------
// http://forums.insideqc.com/viewtopic.php?f=2&t=4856&p=44344&hilit=multi_damage#p44276
/*
	You know that originally the multi damage for the shotguns only applies damage to a single entity, 
	even if the pellets spread hitting two or more entities, and the last entity it hits gets the full damage, while the others take no damage at all.
	That's not a hard fix, but for those who haven't found a way yet, here's my solution:
	
	AddMultiDamage() was removed, because a single line in TraceAttack() will do the same job, as I turned multi_damage into a .float (field) instead of a global.
	TraceAttack() will now add the multi damage to individual trace_ents. 
	FireBullets() remains unchanged, so I didn't need to post it here. 
	ClearMultiDamage() simply cycles through all entites in the world and resets their .multi_damage value to zero. 
	ApplyMultiDamage() is called in FireBullets() after the while() loop, which also cycles through all entites, checks if there are entities with .multi_damage > 0, and applies the damage accordingly.
*/
.float multi_damage;
void() ApplyMultiDamage =
{
	local entity e;
	
	e = nextent(world);
	
	while (e != world)
	{
		if (e.multi_damage)
		{
			if (e.health > 0)
		 		T_Damage (e, self, self, e.multi_damage);
			e.multi_damage = 0;         
		}
		e = nextent(e);
	}
};
/*
==============================================================================

BULLETS

==============================================================================
*/

/*
================
TraceAttack
================
*/
void(float damage, vector dir) TraceAttack =
{
	local	vector	vel = '0 0 0', org = '0 0 0';

	// Prewar: ignore LMA players (and skip visuals)
	if (!match_in_progress())
	{
		if (trace_ent && trace_ent.classname == "player" && trace_ent.leavemealone)
			return;
	}

	org = (trace_endpos - (dir * 4));

	if (trace_ent.takedamage)
	{
		if (trace_ent.classname == "player") 
		{
			vel = normalize(dir + v_up*crandom() + v_right*crandom());
			vel = vel + 2*trace_plane_normal;
			vel = vel * 200;
			SpawnBlood (org, (vel * 0.2), damage);
		}
		else
		{ //R00k: triggers get smacked
			WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
			WriteByte(MSG_BROADCAST, TE_GUNSHOT);
			WriteCoord (MSG_BROADCAST, org_x);
			WriteCoord (MSG_BROADCAST, org_y);
			WriteCoord (MSG_BROADCAST, org_z);
		}
		trace_ent.multi_damage = trace_ent.multi_damage + damage;//Orion
	}
	else
	{
		if (trace_ent.solid)
		{
			WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
			WriteByte(MSG_BROADCAST, TE_GUNSHOT);
			WriteCoord (MSG_BROADCAST, org_x);
			WriteCoord (MSG_BROADCAST, org_y);
			WriteCoord (MSG_BROADCAST, org_z);
		}
	}
};

/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(float shotcount, vector dir, vector spread) FireBullets =
{
	local vector direction;
	local vector src;

	self.dest1_x = self.dest1_x + 4 * shotcount;// ELOHIM_MOD - stats

	// CRMOD - count damage fired with quad    
	if (self.super_damage_finished > time)			// CRMOD - stats
		self.clanring_qdwep_y = self.clanring_qdwep_y + 16 * shotcount;// CRMOD - stats
	if (self.invincible_finished > time)
		self.clanring_ptwep_y = self.clanring_ptwep_y + 4 * shotcount;

	makevectors(self.v_angle);
	src = self.origin + v_forward * 10;
	src_z = self.absmin_z + self.size_z * 0.7;

	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;
		traceline (src, src + direction * 2048, FALSE, self);
		if (trace_fraction != 1.0)
			TraceAttack (4, direction);

		shotcount -= 1;
	}
	ApplyMultiDamage ();
};

/*
================
W_FireShotgun
================
*/
void() W_FireShotgun =

{
	local vector dir;

	sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);

//	self.punchangle_x = -2;

	// ELOHIM_MOD - infinite ammo in practice mode
	if (!(ammo_is_infinite()))
	self.currentammo = self.ammo_shells = self.ammo_shells - 1;
	makevectors(self.v_angle); // ELOHIM_MOD - added this
	dir = v_forward; // R00k: removed autoaim support 	
	FireBullets (6, dir, '0.04 0.04 0');
};

/*
================
W_FireSuperShotgun
================
*/
void() W_FireSuperShotgun =
{
	local vector dir;

	if (self.currentammo == 1)
	{
		W_FireShotgun ();
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);

//	self.punchangle_x = -4;
    // ELOHIM_MOD - infinite ammo in practice mode
	if (!(ammo_is_infinite()))
		self.currentammo = self.ammo_shells = self.ammo_shells - 2;
    // END_MOD
    makevectors(self.v_angle); // ELOHIM_MOD - added this
	dir = v_forward; // R00k: removed autoaim support 	
	FireBullets (14, dir, '0.14 0.08 0');
};

/*
==============================================================================

ROCKETS

==============================================================================
*/

void()	s_explode1	=	[0,		s_explode2] {};
void()	s_explode2	=	[1,		s_explode3] {};
void()	s_explode3	=	[2,		s_explode4] {};
void()	s_explode4	=	[3,		s_explode5] {};
void()	s_explode5	=	[4,		s_explode6] {};
void()	s_explode6	=	[5,		SUB_Remove] {};

void() BecomeExplosion =
{
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};
void() T_MissileTouch =
{
	local float damg;

	if (other == self.owner)
		return;		// don't explode on owner

	// Prewar: don't detonate on LMA players
	if (!match_in_progress() && other && other.classname == "player" && other.leavemealone)
		return;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 100 + random()*20;

	self.dmg = FALSE;  // ELOHIM_MOD - used to flag 0 damage rockets
	self.clanring_badstats_y = 0; // ELOHIM_MOD - damage done to self

	if (other.health)
	{
		other.deathtype = "rocket";	// R00k - wrong obituary messages fix	
		T_Damage (other, self, self.owner, damg);
	}
	
	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self.owner, 120, other,"rocket");
	
	// ELOHIM_MOD - if rocket did damage or came close then add to stats
	local entity head;
	if (!self.dmg)
	{
		// check a larger radius for enemies
		head = findradius(self.origin, 300);
		while (head)
		{
			if ((head.classname == "player") && (head != self.owner) &&	(!teamplay || (head.team != self.owner.team)))
			{
				self.dmg = TRUE;
				head = world;
			}
			else
				head = head.chain;
		}
	}

	if (!self.dmg)
	{
		// check around the person who fired for enemies
		head = findradius(self.owner.origin, 300);
		while (head)
		{
			if ((head.classname == "player") && (head != self.owner) && (!teamplay || (head.team != self.owner.team)))
			{
				self.dmg = TRUE;
				head = world;
			}
			else
				head = head.chain;
		}
	}
	
	if (self.dmg)
	{		
		self.owner.dest_x = self.owner.dest_x + 120;
		if (!self.state && (self.owner.invincible_finished < time))
			self.owner.clanring_badstats_y = self.owner.clanring_badstats_y + self.clanring_badstats_y;
		if (self.owner.super_damage_finished > time)
			self.owner.clanring_qdwep_y = self.owner.clanring_qdwep_y + 480;
		if (self.owner.invincible_finished > time)
			self.owner.clanring_ptwep_y = self.owner.clanring_ptwep_y + 120;
	}
	// END_MOD

//	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);
	WriteByte  (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte  (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	BecomeExplosion ();
};

/*
================
W_FireRocket
================
*/
void() W_FireRocket =
{
	local entity missile;

    // ELOHIM_MOD - infinite ammo in practice mode
	if (!(ammo_is_infinite()))
		self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	// END_MOD
	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
//	self.punchangle_x = -2;
	missile = spawn();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "missile";
	missile.dest1 = self.origin;	//Starting point for rockets shot for distance stats

// set missile speed		
	makevectors (self.v_angle);

	missile.velocity = (v_forward * 1000);
	missile.angles = vectoangles(missile.velocity);
	missile.touch = T_MissileTouch;

// set missile duration
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;
	setmodel (missile, "progs/missile.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin(missile, self.origin + v_forward*8 + '0 0 16');

    // ELOHIM_MOD - check for rocket jump
	missile.state = 1;
	if (!(self.flags & (FL_ONGROUND | FL_JUMPRELEASED)))
	{
		if (missile.velocity_z < -500)
		{
			traceline (missile.origin, missile.origin + missile.velocity, FALSE, self);
			if (trace_fraction > 0.09 || trace_plane_normal_z < 0.9)
				missile.state = 0;
		}
	}
	else
		missile.state = 0;
	// END_MOD
};

/*
===============================================================================

LIGHTNING

===============================================================================
*/

/*
=================
LightningDamage
=================
*/
//R00k: simplified this function to just do the middle traceline, as it was the only one that EVER worked.
//The original code had bad maths for two additional tracelines; originally meant to have three 'logical' bolts thus making the beam wider.
//But, since the code was bugged the two outer bolts went in obscure angles while the center bolt was the only one that was true to the aim.
//Fixing the math, and considering the player's view angles (up/down too), would only result in a fatter bolt and would cause more damage as well.
//So since, for the past 25+ years only the middle traceline worked, why buff it?
void(vector p1, vector p2, entity from, float damage) LightningDamage =
{
	traceline (p1, p2, FALSE, self);

	// Prewar: ignore LMA players (and skip visuals)
	if (!match_in_progress() && trace_ent && trace_ent.classname == "player" && trace_ent.leavemealone)
		return;

	if (trace_ent.takedamage)
	{
		if (trace_ent.classname != "player")
		{
			WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
			WriteByte(MSG_BROADCAST, TE_GUNSHOT);
			WriteCoord (MSG_BROADCAST, trace_endpos_x);
			WriteCoord (MSG_BROADCAST, trace_endpos_y);
			WriteCoord (MSG_BROADCAST, trace_endpos_z);
		}
		else
		{
			particle (trace_endpos, '0 0 100', 225, damage*4);
		}
		T_Damage (trace_ent, from, from, damage);
	}
};

void() W_FireLightning =
{
	local	vector		org;
	local	float		cells;

	if (self.delayed_impulse)
	{
		self.impulse = self.delayed_impulse;

		if ((self.impulse >= 1 && self.impulse <= 8))
		{
			self.delayed_impulse = 0;
			W_ChangeWeapon ();
			return;
		}
	}

	if (self.ammo_cells < 1)
	{
		if (self.style & CLANRING_SMART_WEAPON)
		{
			self.weapon = W_BestWeapon();
			W_SetCurrentAmmo();
		}
		self.weaponframe = 0;
		return;
	}

// explode if under water
	if (self.waterlevel > 2)
	{
		cells = self.ammo_cells;
		self.ammo_cells = 0;
		W_SetCurrentAmmo();

		if (mode_is_arena())
		{
			T_RadiusDamage(self, self, cells, world, "discharge");
			WriteByte  (MSG_BROADCAST, SVC_TEMPENTITY);
			WriteByte  (MSG_BROADCAST, TE_TAREXPLOSION);
			WriteCoord (MSG_BROADCAST, self.origin_x);
			WriteCoord (MSG_BROADCAST, self.origin_y);
			WriteCoord (MSG_BROADCAST, self.origin_z);
			self.items = self.items - (self.items & IT_LIGHTNING);
			return;
		}

		// CLANRING_MOD - check for nospooge in practice mode
		if ((clanring_playmode & CLANRING_PRACTICE_MODE) &&	(clanring_playmode & CLANRING_NO_SPOOGE))
			T_Damage (self, self, self, 35 * cells);
		else
			T_RadiusDamage(self, self, 35 * cells, world, "discharge"); // R00k - wrong obituary messages fix
		// END_MOD
		return;
	}

	if (self.t_width < time)
	{
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}
	//self.punchangle_x = -2;

    // ELOHIM_MOD - infinite ammo in practice mode
	if (!(ammo_is_infinite()))
        self.currentammo = self.ammo_cells = self.ammo_cells - 1;
    // END_MOD

	org = self.origin + '0 0 16';

	makevectors (self.v_angle);
	traceline (org, org + v_forward * 600, TRUE, self);
	
	//R00k Added
	//feet in water, and shooting the liquid = DC
	local float pcnt;
	pcnt = pointcontents(trace_endpos);

	if ((pcnt == CONTENT_WATER || pcnt == CONTENT_SLIME) && self.waterlevel)
	{
		cells = self.ammo_cells;		
	  	self.ammo_cells = 0;	  
		W_SetCurrentAmmo();

		if (mode_is_arena())
		{
			T_RadiusDamage(self, self, cells, world, "discharge");
			WriteByte  (MSG_BROADCAST, SVC_TEMPENTITY);
			WriteByte  (MSG_BROADCAST, TE_TAREXPLOSION);
			WriteCoord (MSG_BROADCAST, self.origin_x);
			WriteCoord (MSG_BROADCAST, self.origin_y);
			WriteCoord (MSG_BROADCAST, self.origin_z);
			self.items = self.items - (self.items & IT_LIGHTNING);
			return;
		}
		
		if (clanring_playmode & CLANRING_NO_SPOOGE)
			T_Damage (self, self, self, 35 * cells);
		else
			T_RadiusDamage(self, self, 35 * cells, world, "discharge"); // R00k - wrong obituary messages fix
		return;
	}
	
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);
	self.dest1_z = self.dest1_z + 30;// ELOHIM_MOD - stats
	// CRMOD - count damage fired with quad.
    if (self.super_damage_finished > time)                     // ELOHIM_MOD - stats
    	self.clanring_qdwep_y = self.clanring_qdwep_y + 120;   
    if (self.invincible_finished > time)
    	self.clanring_ptwep_y = self.clanring_ptwep_y + 30;
	LightningDamage (org, trace_endpos + v_forward * 4, self, 30);
};

//=============================================================================
void() GrenadeExplode =
{
	T_RadiusDamage (self, self.owner, 120, world, "grenade");// R00k - wrong obituary messages fix

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	BecomeExplosion ();
};

void() GrenadeTouch =
{
	// Prewar: don't detonate on LMA players
	if (!match_in_progress() && other && other.classname == "player" && other.leavemealone)
		return;

	if (other == self.owner)
		return;		// don't explode on owner

	if (other.takedamage == DAMAGE_AIM)
	{
		GrenadeExplode ();
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);	// bounce sound
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

/*
================
W_FireGrenade
================
*/

void() W_FireGrenade =
{
	local	entity missile;

	// ELOHIM_MOD - infinite ammo in practice mode unless safepractice is on
	if (!(ammo_is_infinite()))
		self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;		
	//else //allow no spooge in match mode
	if (clanring_playmode & CLANRING_NO_SPOOGE)
	{
		self.lip = self.lip + 1;
		if (self.lip >= 4)
		{
			self.items = self.items - (self.items & IT_GRENADE_LAUNCHER);
			self.weapon = IT_AXE;//W_BestWeapon ();
			W_SetCurrentAmmo();
			sprint(self, "\b\< Grenade spam protection activated \>\n");
			return;
		}
	}
    // END_MOD

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	//self.punchangle_x = -2;

	missile = spawn();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "grenade";

// set missile speed	
	makevectors (self.v_angle);
	if (self.v_angle_x)
		missile.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		missile.velocity = aim(self, 10000);
		missile.velocity = missile.velocity * 600;
		missile.velocity_z = 200;
	}
	missile.avelocity = '300 300 300';
	missile.angles = vectoangles(missile.velocity);
	missile.touch = GrenadeTouch;

// set missile duration
	missile.nextthink = time + 2.5;
	missile.think = GrenadeExplode;
	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin);
	self.stats_gl_tot = self.stats_gl_tot + 120; // stats
};


//=============================================================================

void() spike_touch;
void() superspike_touch;

/*
===============
launch_spike

Used for both the player and the ogre
===============
*/
void(vector org, vector dir, float spd) launch_spike =
{
	newmis 			= spawn();
	newmis.owner 	= self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid 	= SOLID_BBOX;
	newmis.angles 	= vectoangles(dir);
	
	newmis.touch 	 = spike_touch;
	newmis.classname = "spike";
	newmis.think 	 = SUB_Remove;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin(newmis, org);
//	if (newmis.owner.items & IT_QUAD) newmis.effects = newmis.effects | EF_BLUE;

	//newmis.velocity = dir * 1000;
	newmis.velocity = (dir * spd);
};

void() W_FireSuperSpikes =
{
	local vector	dir;
//	local entity	old;

	if (self.delayed_impulse)
	{
		self.impulse = self.delayed_impulse;

		if ((self.impulse >= 1 && self.impulse <= 8))
		{
			self.delayed_impulse = 0;
			W_ChangeWeapon ();
			return;
		}
	}

	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	
	// ELOHIM_MOD - infinite ammo in practice mode
	if (!(ammo_is_infinite()))
		self.currentammo = self.ammo_nails = self.ammo_nails - 2;		
	// END_MOD

	makevectors(self.v_angle); // ELOHIM_MOD - added this

	self.dest1_y = self.dest1_y + 18; // ELOHIM_MOD - stats
	// CRMOD - count damage fired with quad.
	if (self.super_damage_finished > time)
		self.clanring_qdwep_y = (self.clanring_qdwep_y + 72);// ELOHIM_MOD - stats
	if (self.invincible_finished > time)
		self.clanring_ptwep_y = (self.clanring_ptwep_y + 18);

	if (self.player_flag & ITEM_RUNE3_FLAG)
	{
		HasteSound ();
		dir = aim (self, 2000);
		launch_spike (self.origin + '0 0 16', dir, 2000);
	}
	else
	{
		dir = aim (self, 1000);
		launch_spike (self.origin + '0 0 16', dir, 1000);
	}

	newmis.touch = superspike_touch;
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	//self.punchangle_x = -2;
};

void(float ox) W_FireSpikes =
{
	local vector	dir;
//	local entity	old;

	if (self.delayed_impulse)
	{
		self.impulse = self.delayed_impulse;

		if ((self.impulse >= 1 && self.impulse <= 8))
		{
			self.delayed_impulse = 0;
			W_ChangeWeapon ();
			return;
		}
	}

	makevectors (self.v_angle);

	if (self.ammo_nails >= 2 && self.weapon == IT_SUPER_NAILGUN)
	{
		W_FireSuperSpikes ();
		return;
	}

	if (self.ammo_nails < 1)
	{
		if (self.style & CLANRING_SMART_WEAPON)
		{
			self.weapon = W_BestWeapon();
			W_SetCurrentAmmo();
		}
		self.weaponframe = 0;
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;

    // ELOHIM_MOD - infinite ammo in practice mode
	if (!(ammo_is_infinite()))
		self.currentammo = self.ammo_nails = self.ammo_nails - 1;
    // END_MOD

	if (self.player_flag & ITEM_RUNE3_FLAG)
	{
		HasteSound ();
		dir = aim (self, 2000);
		launch_spike (self.origin + '0 0 16' + v_right*ox, dir, 2000);
	}
	else
	{
		dir = aim (self, 1000);
		launch_spike (self.origin + '0 0 16' + v_right*ox, dir, 1000);
	}
	self.dest1_y = (self.dest1_y + 9);// CRMOD - stats
	// CRMOD - count damage fired with quad.
	if (self.super_damage_finished > time)// CRMOD - stats
		self.clanring_qdwep_y = self.clanring_qdwep_y + 36;// CRMOD - stats
	if (self.invincible_finished > time)
		self.clanring_ptwep_y = self.clanring_ptwep_y + 9;
	//self.punchangle_x = -2;
};

//.float hit_z;	// ELOHIM_MOD - hit_z is never used

void() spike_touch =
{
	if (other == self.owner)
		return;

	// Prewar: pass through LMA players
	if (!match_in_progress() && other && other.classname == "player" && other.leavemealone)
		return;

	if (other.solid == SOLID_TRIGGER)
		return; // trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
// hit something that bleeds
	if (other.takedamage)
	{
		if (other.classname == "player") //R00k
			spawn_touchblood (9);

		other.deathtype = "nail";// R00k - wrong obituary messages fix
		T_Damage (other, self, self.owner, 9);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		if (self.classname == "wizspike")
			WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
		else if (self.classname == "knightspike")
			WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE);
		else
			WriteByte (MSG_BROADCAST, TE_SPIKE);

		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}
	remove(self);
};

void() superspike_touch =
{
	if (other == self.owner)
		return;

	// Prewar: pass through LMA players
	if (!match_in_progress() && other && other.classname == "player" && other.leavemealone)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

// hit something that bleeds
	if (other.takedamage)
	{
		if (other.classname == "player") //R00k
			spawn_touchblood (18);
		other.deathtype = "supernail";// R00k - wrong obituary messages fix by Zoid
		T_Damage (other, self, self.owner, 18);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}
	remove(self);
};

/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/


void W_SetCurrentAmmo(void) =
{
	if (self.health <= 0) // bug fix (thanks to QIP [www.inside3d.com/qip]
		return;

	player_run ();		// get out of any weapon firing states
	self.weaponframe = 0;	

	self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS) );

	if (self.weapon == IT_HOOK)
	{
		self.currentammo = 0;
		if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
			self.weaponmodel = "progs/v_star.mdl";
		else
			self.weaponmodel = "progs/v_axe.mdl";
	}
	else
	if (self.weapon == IT_AXE)
	{
		self.currentammo = 0;
		self.weaponmodel = "progs/v_axe.mdl";
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot.mdl";
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot2.mdl";
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail.mdl";
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail2.mdl";
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock.mdl";
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock2.mdl";
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		self.currentammo = self.ammo_cells;
		self.weaponmodel = "progs/v_light.mdl";
		self.items = self.items | IT_CELLS;
	}
	else
	{
		self.currentammo = 0;
		self.weaponmodel = "";
	}	
};

float() W_BestWeapon =
{
	float it = self.items;

	if (self.waterlevel <= 2 && self.ammo_cells >= 1 && (it & IT_LIGHTNING))
		return IT_LIGHTNING;
	if ((self.ammo_rockets >= 1 && (it & IT_ROCKET_LAUNCHER))&&(self.currentammo))//Don't switch to RL if we ran out of ammo with current gun
	 	return IT_ROCKET_LAUNCHER;
	if(self.ammo_nails >= 2 && (it & IT_SUPER_NAILGUN))
		return IT_SUPER_NAILGUN;
	if(self.ammo_shells >= 2 && (it & IT_SUPER_SHOTGUN))
		return IT_SUPER_SHOTGUN;
	if(self.ammo_nails >= 1 && (it & IT_NAILGUN))
		return IT_NAILGUN;
	if(self.ammo_shells >= 1 && (it & IT_SHOTGUN))
		return IT_SHOTGUN;
	return IT_AXE;
};

/*
============
W_Attack

An attack impulse can be triggered now
============
*/

void() player_axe1;
void() player_axeb1;
void() player_axec1;
void() player_axed1;
void() player_shot1;
void() player_nail1;
void() player_light1;
void() player_rocket1;
void() player_hook1;
void() player_hook3;

void() W_Attack =
{
	local float r;

	self.plag = FALSE;

//autoswitch when letting off the fire button, unless SmartWeapon enabled.
	if ((self.weapon != IT_HOOK) && (self.weapon != IT_AXE))
	{
		if (self.currentammo < 1)		
		{
			self.attack_finished = time + 0.5;
			if (self.style & CLANRING_SMART_WEAPON)
			{
				self.weapon = W_BestWeapon();
				W_SetCurrentAmmo();
			}
			else
			{
				stuffcmd(self,";play weapons/g_click;\n");	// Don't require everyone to precache this.

				if (self.currentammo <= 0)
				{					
					self.currentammo = 0.6;
				}
				else
					self.currentammo -= 0.03;

				self.weaponframe = 0;
				return;
			}
		}
	}

	makevectors (self.v_angle);	// calculate forward angle for velocity
	self.show_hostile = time;	// FIXME: Use this for something...(last fired shot?)

	// CRMOD - check for live players
	if (self.weapon != IT_AXE)  // A player can type +attack and idle but eventually he will run out of ammo and just be swinging the axe...
		self.finaldest_x = time;
	// END_MOD

	if (self.weapon == IT_AXE)
	{
		sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);
		r = random();
		if (r < 0.25)
			player_axe1 ();
		else if (r<0.5)
			player_axeb1 ();
		else if (r<0.75)
			player_axec1 ();
		else
			player_axed1 ();
		
		if (self.player_flag & ITEM_RUNE3_FLAG)
		{
			HasteSound ();
			self.attack_finished = time + 0.3;			
		}
		else
			self.attack_finished = time + 0.5;
	}
	else if (self.weapon == IT_HOOK)
	{			
		if (!self.hook_out)
			player_hook1();
		else
			player_hook3();				

		self.attack_finished = time + 0.1;
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		player_shot1 ();
		W_FireShotgun ();
		
		if (self.player_flag & ITEM_RUNE3_FLAG)
		{	
			self.attack_finished = time + 0.3;
			HasteSound ();
		}
		else
			self.attack_finished = time + 0.5;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		player_shot1 ();
		W_FireSuperShotgun ();
		if (self.player_flag & ITEM_RUNE3_FLAG)
		{
			HasteSound ();
			self.attack_finished = time + 0.42;
		}
		else
			self.attack_finished = time + 0.7;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		player_rocket1 ();
		W_FireGrenade ();
		
		if (self.player_flag & ITEM_RUNE3_FLAG)
		{
			HasteSound ();
			self.attack_finished = time + 0.36;
		}	
		else
			self.attack_finished = time + 0.6;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		player_rocket1 ();
		W_FireRocket ();
		
		if (self.player_flag & ITEM_RUNE3_FLAG)
		{
			HasteSound ();
			self.attack_finished = time + 0.48;
		}	
		else
			self.attack_finished = time + 0.8;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		player_light1 ();
		self.attack_finished = time + 0.1;	//R00k not sure why iD decided to add this when player_light1 updates the nextthink to 0.2... ?
		sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
	}
};

/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
	local	float	it = 0,  am = 0, fl = 0;

	it = self.items;
	am = 0;

	if (self.impulse == 22)
	{
		if (clanring_playmode & CLANRING_NO_HOOK)
		{
			sprint(self, "hook has been disabled.\n use \bsethook\b to vote hook.\n");
			self.impulse = 0;
			return;
		}
		fl = IT_HOOK;
	}
	else if (self.impulse == 7)
	{
		fl = IT_ROCKET_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 8)
	{
		fl = IT_LIGHTNING;
		if (self.ammo_cells < 1)
			am = 1;
	}
	else if (self.impulse == 5)
	{
		fl = IT_SUPER_NAILGUN;
		if (self.ammo_nails < 2)
			am = 1;
	}
	else if (self.impulse == 6)
	{
		fl = IT_GRENADE_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 4)
	{
		fl = IT_NAILGUN;
		if (self.ammo_nails < 1)
			am = 1;
	}
	else if (self.impulse == 2)
	{
		fl = IT_SHOTGUN;
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if (self.impulse == 3)
	{
		fl = IT_SUPER_SHOTGUN;
		if (self.ammo_shells < 2)
			am = 1;
	}
	else if (self.impulse == 1) //low priority
	{
		if (clanring_playmode & CLANRING_NO_HOOK)
		{
			fl = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
			fl = IT_HOOK;
		}
		else
			fl = IT_AXE;
	}
	self.impulse = 0;

	if (!(self.items & fl))
	{	// don't have the weapon or the ammo
		//sprint (self, "no weapon.\n");
		return;
	}

	if (am)
	{	// don't have the ammo
		sprint (self, "not enough ammo.\n");
		return;
	}

//
// set weapon, set ammo
//
	if (self.weapon != IT_HOOK || fl != IT_HOOK)
		self.previous_weapon = self.weapon;
	
	self.weapon = fl;

	W_SetCurrentAmmo();
};


/*
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void() CycleWeaponCommand =
{
	local	float	it, am;

	it = self.items;
	self.impulse = 0;
	self.previous_weapon = self.weapon;

	while (1)
	{
		am = 0;

		if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
			if (clanring_playmode & CLANRING_NO_HOOK)
			{
				self.weapon = IT_SHOTGUN;
				if (self.ammo_shells < 1) 
					am = 1;
			}
			else
			{
				self.weapon = IT_HOOK;
			}
		}
		else if (self.weapon == IT_HOOK)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}

		if ( (it & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo();
			return;
		}
	}
};

/*
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
*/
void() CycleWeaponReverseCommand =
{
	local	float	it, am;

	it = self.items;
	self.impulse = 0;
	self.previous_weapon = self.weapon;

	while (1)
	{
		am = 0;

		if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}		
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN)
		{
			if (clanring_playmode & CLANRING_NO_HOOK)
				self.weapon = IT_AXE;
			else
				self.weapon = IT_HOOK;
		}
		else if (self.weapon == IT_HOOK)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}

		if ( (it & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo();
			return;
		}
	}
};

void() PreviousWeaponCommand =
{
	local float fl;
	local float am;

	self.impulse = 0;
	am = 0;

	if (!(self.items & self.previous_weapon))
	{
		//sprint(self, "no weapon.\n");
		return;
	}

	fl = self.weapon;
	self.weapon = self.previous_weapon;
	self.previous_weapon = fl;

	if ((self.weapon == IT_SHOTGUN) || (self.weapon == IT_SUPER_SHOTGUN))
	{
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if ((self.weapon == IT_NAILGUN) || (self.weapon == IT_SUPER_NAILGUN))
	{
		if (self.ammo_nails < 1)
			am = 1;
	}
	else if ((self.weapon == IT_GRENADE_LAUNCHER) || (self.weapon == IT_ROCKET_LAUNCHER))
	{
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		if (self.ammo_cells < 1)
			am = 1;
	}

	if (am)
		self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo();
};

/*

============
ImpulseCommands
============
*/
void() ImpulseCommands =
{
	if (self.impulse == 22)
		W_ChangeWeapon ();
	else 
	if (self.impulse >= 1 && self.impulse <= 8)
		W_ChangeWeapon ();
	else if (self.impulse == 10)
		CycleWeaponCommand ();
	else if (self.impulse == 12)
		CycleWeaponReverseCommand ();
	self.impulse = 0;
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/

void() W_WeaponFrame =
{	
	// ELOHIM_MOD - added self.delayed_impulse to prevent weapon
	//              changing impulses from being nuked by pings

	// ELOHIM_MOD - moved to PlayerPostThink
	//if (time < self.attack_finished)
	//	return;

	// END_MOD

	if (self.deadflag)
		return;
	
    if (self.delayed_impulse)
	{
		self.impulse = self.delayed_impulse;
		self.delayed_impulse = 0;
		ImpulseCommands ();
	}
	
	if (((mode_is_arena() == TRUE) && (boss.timetofight == FALSE)))
		return;

	//BuckSh0t: stop firing during timer countdown
	if ((match_prewar()) && (clanring_state & CLANRING_TIMER_STARTED))
	{
		if (self.weapon != IT_HOOK) //R00k: allow them to finish their capture time trial
			return;
	}

// check for attack
    // ELOHIM_MOD - don't fire unless ELOHIM_OK_TO_SHOOT is set
	if (self.button0)
	{
		if (self.style & CLANRING_OK_TO_SHOOT)
		{
			W_Attack ();			
			SuperDamageSound();		
			clear_afk_status(self);	//R00k:	
		}
	}
	else
	{
		if ((self.weapon != IT_HOOK)&&(self.weapon != IT_AXE))
		{
			if (self.currentammo < 1)
			{
				if (self.style & CLANRING_SMART_WEAPON)
				{
					self.weapon = W_BestWeapon();
					W_SetCurrentAmmo();
				}
				self.weaponframe = 0;
			}
		}
		self.style = self.style | CLANRING_OK_TO_SHOOT;
	}
};

/*
========
SuperDamageSound

Plays sound if needed
========
*/

void() SuperDamageSound =
{
	if ((self.weapon == IT_HOOK) || (self.hook2 & HOOK_OUT))
	{
		if (self.player_flag & ITEM_RUNE2_FLAG)
		{
			if (self.super_damage_finished < time)
				return;
		}
	}//if hooking with strength rune, but not quad, then dont make the sound.
		
	if ((self.super_damage_finished > time) || (self.player_flag & ITEM_RUNE2_FLAG))
	{
		if (self.super_sound < time)
		{
			self.super_sound = time + 1;
			if (!(clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM))
			{			
				sound (self, CHAN_BODY, "items/damage3.wav", 0.8, ATTN_NORM);// quad only
			}
			else
			{
				if ((self.super_damage_finished > time) && (self.player_flag & ITEM_RUNE2_FLAG))
				{
					sound (self, CHAN_BODY, "rune/rune22.wav", 1, ATTN_NORM);// quad and str
				}
				else
				{
					if (self.player_flag & ITEM_RUNE2_FLAG)
					{
						sound (self, CHAN_BODY, "rune/rune2.wav", 1, ATTN_NORM);//str only
					}
					else
					{					
						sound (self, CHAN_BODY, "items/damage3.wav", 0.8, ATTN_NORM);//default
					}
				}
			}			
		}
	}	
};

void() RegenerationSound =
{
	if (self.player_flag & ITEM_RUNE4_FLAG)
	{
		if (self.regeneration_sound < time)
		{
			self.regeneration_sound = time + 1;
			if (!(clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM))
				sound (self, CHAN_BODY, "items/r_item1.wav", 1, ATTN_NORM);
			else
				sound(self, CHAN_BODY, "rune/rune4.wav", 1, ATTN_NORM);			
		}
	}
};

void(entity who) ResistanceSound =
{
	if (who.player_flag & ITEM_RUNE1_FLAG)
	{
		if (who.invincible_sound < time)
		{
			who.invincible_sound = time + 1;
			if (!(clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM))
				sound (who, CHAN_BODY, "items/protect3.wav", 1, ATTN_NORM);			
			else
				sound (who, CHAN_BODY, "rune/rune1.wav", 1, ATTN_NORM);
		}
	}
};

void() HasteSound =
{
	if (self.player_flag & ITEM_RUNE3_FLAG)
	{
		if (self.haste_sound < time)
		{
 			self.haste_sound = time + 0.9;
 			if (!(clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM))
 				sound (self, CHAN_BODY, "boss1/sight1.wav", 1, ATTN_NORM);
 			else
 				sound(self, CHAN_BODY, "rune/rune3.wav", 1, ATTN_NORM);
		}
	}
};

// ELOHIM_MOD - moved laser stuff from Enforcer.qc to here, used for maps like E2M1's exit.
/*
============
Laser_Touch
============
*/
void() Laser_Touch =
{
	local vector org;
	
	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
	sound (self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC);
	org = self.origin - 8*normalize(self.velocity);

	if (other.health)
	{
		SpawnBlood (org, self.velocity*0.2, 15);
		T_Damage (other, self, self.owner, 15);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
	
	remove(self);	
};

/*
============
LaunchLaser
============
*/
void(vector org, vector vec) LaunchLaser =
{
//	local	vector	vec;
		
	if (self.classname == "monster_enforcer")
		sound (self, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM);

	vec = normalize(vec);
	
	newmis = spawn();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX;
	newmis.effects = EF_DIMLIGHT;

	setmodel (newmis, "progs/laser.mdl");
	setsize (newmis, '0 0 0', '0 0 0');		

	setorigin (newmis, org);

	newmis.velocity = vec * 600;
	newmis.angles = vectoangles(newmis.velocity);

	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;
	newmis.touch = Laser_Touch;
};

// END MOD
