//Originally from Zoid's 3Wave

/*********\
* LinkPos *
\*********/
void() LinkPos =
{
	//R00k added
	local vector dir = '0 0 0';

	dir = self.owner.origin - (self.owner.owner.origin + '0 0 16');  
  	self.angles = vectoangles(dir);

	makevectors (self.enemy.angles);
	setorigin(self, self.owner.origin + ( ( ( self.enemy.origin + (v_up * 16 * (!self.enemy.button2)) + (v_forward * 16) ) - self.owner.origin ) * ( self.weapon ) ) );
	self.nextthink = (time + sys_ticrate);
};

/************\
* HookVanish *
\************/
void() HookVanish =
{
	self.owner.hook_out = FALSE;
	self.owner.hook2 = (self.owner.hook2 - (self.owner.hook2 & HOOK_OUT));	

	if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
	{
		sound (self.owner, CHAN_WEAPON, "weapons/bounce2.wav", 1, ATTN_NORM);
	}
	
	do
	{
		if ((self.classname == "hook_chain_link") || (self.classname == "hook_entity"))//sanity check
		{
			remove(self);
		}
		self = self.hookentity;
	} while (self);
};

void() UnHookPlayer =
{
	local entity oself;

	if (self.hook_out)
	{
		oself = self;
		self = self.hookentity;
		HookVanish ();
		self = oself;
	}
};

/**********\
* HookPull *
\**********/
void() HookPull =
{
	local vector vel;
	local float v, dorg, a, b, c;	

	if (clanring_state & CLANRING_MATCH_PAUSED)
	{
		return;
	}

    if (self.owner.teleport_time > time + 0.5) // Woods
    {
        self.owner.attack_finished = time + sys_ticrate;
        HookVanish();
        return;
    }

	if ((!self.owner.button0 && self.owner.weapon == IT_HOOK) || (self.owner.deadflag) || (gameover))
	{
		if (!(self.owner.flags & FL_WATERJUMP))	// R00k: hooking out of water near a wall cancels the hook when waterjump is activated because it sets the teleport_time + 2...
		{
			HookVanish();
			return;
		}
	}
	
	if (self.enemy.style & CLANRING_OBSERVER)
	{
		HookVanish();
		return;
	}
	
	if (self.enemy.solid == SOLID_NOT)
	{
		HookVanish();
		return;
	}

	if (self.enemy.takedamage)
	{
		if (!teamplay || self.enemy.team != self.owner.team)
		{
			if (!CanDamage(self.enemy, self.owner,"hook"))
			{
				HookVanish();
				return;
			}

			self.enemy.deathtype = "hook";

			//R00k: tear-away hook if the chain is pulled too hard...
			
			a = vlen (self.enemy.velocity);
			b = vlen (self.owner.velocity);
			c = (a - b);
			
			if (c > 640)
			{
				sound (self, CHAN_WEAPON, "shambler/smack.wav", 1, ATTN_NORM);
				T_Damage (self.enemy, self, self.owner, 20);//same damage as an AXE hit
				HookVanish();
				return;
			}			

			//T_Damage (self.enemy, self, self.owner, 1);
			//at lower ticrates the hook damage is updated too fast
			//default 200a+100h = 30 seconds to death by hook
			
			self.hookdmg = (self.hookdmg + (sys_ticrate/0.1));

			if (self.hookdmg >= 1)
			{
				sound (self, CHAN_WEAPON, "blob/land1.wav", 1, ATTN_NORM);
				T_Damage (self.enemy, self, self.owner, 1);
				if (self.enemy.classname == "player")
				{
					SpawnBlood (self.origin, self.velocity, 10);
				}
				self.hookdmg = 0.00;
			}

			makevectors (self.v_angle);
		}

		if (self.enemy.classname == "player")
		{			
			setorigin(self, self.enemy.origin + self.enemy.mins + (self.enemy.size * 0.5));
		}
		else
		{
			self.velocity = self.enemy.velocity;
		}
	}
	else
	{
		self.velocity = self.enemy.velocity;
	}

	makevectors (self.owner.v_angle);
	vel = self.origin - ( self.owner.origin + (v_up * 16 * (!self.owner.button2)) + (v_forward * 16));

	v = vlen (vel);

	if (hookspeedpull < 600)
		hookspeedpull = 850;

	if ( v > 100 ) //R00k: we're hitting this 90% of the time
		vel = normalize(vel) * hookspeedpull;
	else
		vel = normalize(vel) * v * 10;


	self.owner.velocity = vel;
	
	if (self.owner.flags & FL_INWATER) //Slow down the hook pull if underwater!!
	{
		self.owner.velocity = ((1 - ((0.8 * self.owner.waterlevel) * frametime)) * self.owner.velocity);
	}

	if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
	{
		dorg = vlen(self.owner.origin - self.dest);

		if (dorg > 10 && self.style == 3)
		{
			sound(self.owner, CHAN_WEAPON, "weapons/chain2.wav", 1, ATTN_NORM);
			self.style = 2;
		}
		else
		{
			if (dorg < 10 && self.style == 2)
			{
				sound(self.owner, CHAN_WEAPON, "weapons/chain3.wav", 1, ATTN_NORM);
				self.style = 3;
			}
		}
	}

	self.dest = self.owner.origin;
	self.nextthink = (time + sys_ticrate);
};

void() T_HookTouch =
{
	if (clanring_state & CLANRING_MATCH_PAUSED)
	return;

	// Prewar: don't latch or cause blood on LMA players
	if (!match_in_progress() && other && other.classname == "player" && other.leavemealone)
		return;

	if (other != self.owner)
	{
		if ((pointcontents(self.origin) == CONTENT_SKY) || (gameover))
		{
			HookVanish ();
			return;
		}
		else
		{
			if (other.solid == SOLID_SLIDEBOX)
			{
				if ((other.team == self.owner.team) && (teamplay))
				{
					self.owner.attack_finished = (time + 0.5);
					HookVanish ();
					return;
				}
				other.axhitme = 1; // make axe noise
			}

			if (other.takedamage)
			{
				T_Damage (other, self, self.owner, 10 );
				//R00k fixed bleeding buttons/triggers
				if (other.classname == "player")
				{
					SpawnBlood (self.origin, self.velocity, 10);
				}
				else
				{	//R00k: hook hits triggers, just show sparks
					WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
					WriteByte(MSG_BROADCAST, TE_GUNSHOT);
					WriteCoord (MSG_BROADCAST, self.origin_x);
					WriteCoord (MSG_BROADCAST, self.origin_y);
					WriteCoord (MSG_BROADCAST, self.origin_z);
				}
			}
			else
			{
				sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
				self.avelocity = '0 0 0';
			}

			if (self.owner.button0)
			{
				if (other.solid == SOLID_SLIDEBOX)
				{
					setorigin(self, other.origin + other.mins + (other.size * 0.5));
					//self.velocity = '0 0 0';					
					self.velocity = other.velocity;
				}
				else
				{
					self.velocity = other.velocity;
				}

				self.weapon = other.nextthink - time;

				if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
				{
					sound (self.owner, CHAN_WEAPON, "weapons/chain2.wav", 1, ATTN_NORM);
				}

				self.style = 3;//was 2 R00k:10-02-07
				self.enemy = other;
				self.owner.ltime = (time + 0.5);
				self.nextthink = (time + sys_ticrate);
				self.think = HookPull;
				self.touch = SUB_Null;		
				self.solid = SOLID_NOT;		
			}
			else
			{
				self.nextthink = (time + sys_ticrate);
				self.think     = HookVanish;
			}
		}
	}
};

void() Hook_Check =
{
	if ((!self.owner.button0 && self.owner.weapon == IT_HOOK) || (self.owner.deadflag) || (gameover))
	{
		HookVanish ();
		return;
	}
	
	if (self)
	{
		self.nextthink = time + sys_ticrate;
		self.think = Hook_Check;
	}
};

//This is a combination of the old 'W_FireChain' and 'MakeChain' functions; removed .goalentity.
void() W_FireHook =
{
	local entity hook = world;
	local float linknum = 0;
	local entity link = world;
	local entity prevlink = world;

	if (clanring_state & CLANRING_MATCH_PAUSED)
	{
		return;
	}

	if (clanring_playmode & CLANRING_NO_HOOK)
	{
		return;
	}

	self.hook_out 	= TRUE;
	hook 			= spawn();
	hook.classname  = "hook_entity";
	hook.owner 		= self;
	self.hookentity = hook;
	hook.movetype 	= MOVETYPE_FLY;
	hook.solid 		= SOLID_BBOX;
	makevectors (self.v_angle);

	if (hookspeedfire < 800)
		hookspeedfire = 1200;

	hook.velocity 	= hookspeedfire * v_forward;
	hook.angles 	= vectoangles (hook.velocity);
	hook.avelocity 	= '0 0 -500';
	hook.touch 		= T_HookTouch;
	//hook.nextthink  = (time + 5);	//This will never occur on any current CTF map..
	//hook.think 	 = HookVanish;
	hook.nextthink 	= time + 0.3;//instead lets check if we let off the button in mid-flight! eh?
	hook.think 		= Hook_Check;

	if (!(clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM))
	{
		setmodel (hook, "progs/v_spike.mdl");
		hook.effects |= EF_NOMODELFLAGS;	// Remove the trail.
	}
	else
	{
		setmodel (hook, "progs/star.mdl");
	}

	setorigin(hook, self.origin + (v_forward*16) + '0 0 16' );
	setsize (hook, '0 0 0', '0 0 0');
		
	if (!(clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM))
	{
		sound (self, CHAN_WEAPON, "hknight/hit.wav", 1, ATTN_NORM);
	}
	else
	{
		sound (self, CHAN_WEAPON, "weapons/chain1.wav", 1, ATTN_NORM);
	}

	linknum = 5;
	prevlink = world;
	while (linknum)
	{
		link = spawn();
		link.classname = "hook_chain_link";
		link.hookentity = prevlink;
		prevlink = link;
		link.owner = hook;
		link.enemy = self;
		link.weapon = (linknum / 6); 
		link.movetype = MOVETYPE_NOCLIP;
		link.solid = SOLID_NOT;
		link.angles = hook.angles;

		if (!(clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM))
		{
			setmodel (link, "progs/s_spike.mdl");
		}
		else
		{
			setmodel (link, "progs/bit.mdl");
		}
		makevectors (self.v_angle);
		setorigin(link, hook.origin + (((self.origin + (v_up * 16 * (!self.button2)) + (v_forward * 16)) - hook.origin) * (link.weapon)));
		setsize (link, '0 0 0', '0 0 0');
		link.nextthink  = (time + sys_ticrate);
		link.think      = LinkPos;
		linknum         = linknum - 1;
	}
	hook.hookentity = link;
};
