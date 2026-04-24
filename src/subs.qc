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

void() SUB_Null = {};

void() SUB_Remove =
{
	if (self.ffa_item_ghost_ent != world)
		ffa_item_clear_respawn_ghost(self);
	remove(self);
};

void() SUB_Freeze = {self.velocity = '0 0 0';}; // ELOHIM_MOD
/*
QuakeEd only writes a single float for angles (bad idea), so up and down are
just constant angles.
*/
void () SetMovedir =
{
	if (self.angles == '0 -1 0')
		self.movedir = '0 0 1';
	else if (self.angles == '0 -2 0')
		self.movedir = '0 0 -1';
	else
	{
		makevectors (self.angles);
		self.movedir = v_forward;
	}
	self.angles = '0 0 0';
};

/*
================
InitTrigger
================
*/
void() InitTrigger =
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	if (self.angles != '0 0 0')
		SetMovedir ();
	self.solid = SOLID_TRIGGER;
	setmodel (self, self.model);	// set size and link into world
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
};

/*
=============
SUB_CalcMove

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
===============
*/
void(entity ent, vector tdest, float tspeed, void() func) SUB_CalcMoveEnt =
{
local entity	stemp;

	stemp = self;
	self = ent;
	SUB_CalcMove (tdest, tspeed, func);
	self = stemp;
};

void(vector tdest, float tspeed, void() func) SUB_CalcMove =
{
local vector	vdestdelta;
local float		len, traveltime;

	if (!tspeed)
		objerror("No speed is defined!");

	self.think1 = func;
	self.finaldest = tdest;
	self.think = SUB_CalcMoveDone;
	if (tdest == self.origin)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

// set destdelta to the vector needed to move
	vdestdelta = tdest - self.origin;
	
// calculate length of vector

	len = vlen (vdestdelta);
// divide by speed to get time to reach dest
	traveltime = len / tspeed;
	if (traveltime < 0.1)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}
// set nextthink to trigger a think when dest is reached
	self.nextthink = self.ltime + traveltime;
// scale the destdelta vector by the time spent traveling to get velocity
	self.velocity = vdestdelta * (1/traveltime);	// qcc won't take vec/float	
};

/*
============
After moving, set origin to exact final destination
============
*/
void()  SUB_CalcMoveDone =
{
	setorigin(self, self.finaldest);
	self.velocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1)
		self.think1();
};

//=============================================================================
void() DelayThink =
{
	activator = self.enemy;
	SUB_UseTargets ();
	remove(self);
};

/* ### (added targets, killtargets, and targetnames)
==============================
SUB_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
or killtarget2, so some events can remove other triggers.

Search for (string)targetname, targetname2, targetname3, and targetname 4
in all entities that match (string)self.target, self.target2, self.target3,
or self.target4 and use their .use function.
==============================
*/
void(string matchstring, .string matchfield) SUB_UseSpecificTarget =
{
	local entity t, stemp, otemp, act;

	act = activator;
	t = find (world, matchfield, matchstring);
	while ( t != world )
	{
		stemp = self;
		otemp = other;
		self = t;
		other = stemp;
		if (self.use != SUB_Null)
		{
			if (self.use)
			{
				lastnameused = matchstring;
				self.use ();
			}
		}
		self = stemp;
		other = otemp;
		activator = act;
		t = find (t, matchfield, matchstring);
	}
};

/*
==============================
SUB_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
and removes them, so some events can remove other triggers.

Search for (string)targetname in all entities that
match (string)self.target and call their .use function

==============================
*/
void() SUB_UseTargets =
{
	local entity t;//, stemp, otemp, act;

	if (self.estate != STATE_ACTIVE) return;
//
// check for a delay
//
	if (self.delay)
	{
	// create a temp object to fire at a later time
		t = spawn();
		t.classname = "DelayedUse";
		t.nextthink = time + self.delay;
		t.think = DelayThink;
		t.enemy = activator;
		t.message = self.message;
		t.killtarget = self.killtarget;
		t.killtarget2 = self.killtarget2;
		t.target = self.target;
		t.target2 = self.target2;
		t.target3 = self.target3;
		t.target4 = self.target4;
		return;
	}
	
	
//
// print the message
//
	if (activator.classname == "player" && self.message != "")
	{
		centerprint (activator, self.message);
		if (!self.noise)
			sound (activator, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NORM);
	}

//
// kill the killtargets
//
	if (self.killtarget != "")
	{
		t = find(world, targetname, self.killtarget);
		while(t != world)
		{
			if(t.switchshadstyle) lightstyle(t.switchshadstyle, "m");
			remove(t);
			t = find(t, targetname, self.killtarget);
		}
		t = find(world, targetname2, self.killtarget);
		while(t != world)
		{
			if(t.switchshadstyle) lightstyle(t.switchshadstyle, "m");
			remove(t);
			t = find(t, targetname2, self.killtarget);
		}
		t = find(world, targetname3, self.killtarget);
		while(t != world)
		{
			if(t.switchshadstyle) lightstyle(t.switchshadstyle, "m");
			remove(t);
			t = find(t, targetname3, self.killtarget);
		}
		t = find(world, targetname4, self.killtarget);
		while(t != world)
		{
			if(t.switchshadstyle) lightstyle(t.switchshadstyle, "m");
			remove(t);
			t = find(t, targetname4, self.killtarget);
		}
	}

//
// kill the killtaget2 entities
//
	if (self.killtarget2 != "")
	{
		t = find(world, targetname, self.killtarget2);
		while(t != world)
		{
			if(t.switchshadstyle) lightstyle(t.switchshadstyle, "m");
			remove(t);
			t = find(t, targetname, self.killtarget2);
		}
		t = find(world, targetname2, self.killtarget2);
		while(t != world)
		{
			if(t.switchshadstyle) lightstyle(t.switchshadstyle, "m");
			remove(t);
			t = find(t, targetname2, self.killtarget2);
		}
		t = find(world, targetname3, self.killtarget2);
		while(t != world)
		{
			if(t.switchshadstyle) lightstyle(t.switchshadstyle, "m");
			remove(t);
			t = find(t, targetname3, self.killtarget2);
		}
		t = find(world, targetname4, self.killtarget2);
		while(t != world)
		{
			if(t.switchshadstyle) lightstyle(t.switchshadstyle, "m");
			remove(t);
			t = find(t, targetname4, self.killtarget2);
		}
	}

//
// fire targets
//
// target 1
	if (self.target != "")
	{
		SUB_UseSpecificTarget(self.target, targetname);
		SUB_UseSpecificTarget(self.target, targetname2);
		SUB_UseSpecificTarget(self.target, targetname3);
		SUB_UseSpecificTarget(self.target, targetname4);
	}

// target 2
	if (self.target2 != "")
	{
		SUB_UseSpecificTarget(self.target2, targetname);
		SUB_UseSpecificTarget(self.target2, targetname2);
		SUB_UseSpecificTarget(self.target2, targetname3);
		SUB_UseSpecificTarget(self.target2, targetname4);
	}

// target 3
	if (self.target3 != "")
	{
		SUB_UseSpecificTarget(self.target3, targetname);
		SUB_UseSpecificTarget(self.target3, targetname2);
		SUB_UseSpecificTarget(self.target3, targetname3);
		SUB_UseSpecificTarget(self.target3, targetname4);
	}

// target 4
	if (self.target4 != "")
	{
		SUB_UseSpecificTarget(self.target4, targetname);
		SUB_UseSpecificTarget(self.target4, targetname2);
		SUB_UseSpecificTarget(self.target4, targetname3);
		SUB_UseSpecificTarget(self.target4, targetname4);
	}
};

/*
================
SUB_UseAndForgetTargets

This calls SUB_UseTargets, then clears all of self's fields that cause
SUB_UseTargets to do things.  The intention is that if SUB_UseTargets
gets called again in the future, it won't do anything.  Call this
function if you want an entity to fire its targets just this once, and
never again.

Note that this function relies on the fact that SUB_UseTargets has
already been modified to work around the engine bug involving tests of
the form 'if (string)', i.e. that the tests in SUB_UseTargets are now of
the form 'if (string != "")'.  -- iw
================
*/
void() SUB_UseAndForgetTargets =
{
	SUB_UseTargets ();

	self.delay = 0;
	self.killtarget = "";
	self.killtarget2 = "";
	self.message = "";
	self.target = "";
	self.target2 = "";
	self.target3 = "";
	self.target4 = "";
};

/*
================
SUB_DislodgeRestingEntities

This clears the FL_ONGROUND flag from any entities that are on top of
self.

The engine does not update the FL_ONGROUND flag automatically in some
cases, with the result that certain types of entities can be left
floating in mid-air if the entity they are resting on is removed from
under them.  This function is intended to be called in the case where
self is going to be removed, to ensure that other entities are not left
floating.  -- iw
================
*/
void() SUB_DislodgeRestingEntities =
{
	local entity e;

	e = nextent (world);
	while (e != world)
	{
		if ((e.flags & FL_ONGROUND) && e.groundentity == self)
			e.flags = e.flags - (e.flags & FL_ONGROUND);
		e = nextent (e);
	}
};
//------------------------------------------------------------------------//
//  Drake -- This makes an entity do a think function right now.
//------------------------------------------------------------------------//
void(entity ent, void() thinkst) SUB_Think =
{
    local   entity  swap;

    swap = self;
    self = ent;
    thinkst ();
    self = swap;
};

/// from Copper -- dumptruck_ds (orginally found in triggers.qc)
/*
================================
CheckValidTouch
health and playerhood checks were duplicated everywhere
added noclip check because Quake's default still-touch-everything noclip is awful
================================
*/
float() CheckValidTouch =
{
	if (ffa_start_lock_active())
		return FALSE;
	if (clanring_state & CLANRING_MATCH_PAUSED)
		return FALSE;
	if (other.classname != "player")
		return FALSE;
	if (other.health <= 0)
		return FALSE;
	if (other.movetype == MOVETYPE_NOCLIP)
		return FALSE;
	if (self.estate != STATE_ACTIVE)
		return FALSE;
	if (other.leavemealone)
		return FALSE;
	return TRUE;
}
float(float a, float b) not = { return a - (a & b); } // fix not issue in client.qc - Copper -- dumptruck_ds

void() SUB_EndWaiting = {
	self.is_waiting = 0;
	self.estate = STATE_ACTIVE;
	if (self.use == SUB_EndWaiting) self.use = self.dormant_use;

	// special case for teleports, makes it ignore the fact that it has a targetname when touched
	if (self.classname == "trigger_teleport") {
		self.is_waiting = -1;
	}
};

void() SUB_CheckWaiting = {
	if (self.is_waiting > 0) {
		self.dormant_use = self.use;
		self.use = SUB_EndWaiting;
		self.estate = STATE_INACTIVE;

		dprint("Spawned a waiting ");
		dprint(self.classname);
		dprint(" with targetname ");
		dprint(self.targetname);
		dprint(" and target ");
		dprint(self.target);
		dprint("\n");
	}
};