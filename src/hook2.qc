void(vector org, vector vel, float damage) SpawnBlood;
float () crandom;

void() HookVanish2 =
{
	if (clanring_use_custom_hook_assets())
	{
		sound (self.owner, CHAN_WEAPON, "weapons/bounce2.wav", 1, ATTN_NORM);
	}

	self.owner.hook2 = (self.owner.hook2 - (self.owner.hook2 & (HOOK_OUT)));// | HOOK_SWING)));
	do
	{
		if ((self.classname == "hook_chain_link") || (self.classname == "hook2_entity"))//sanity check
		{
			remove(self);
		}
		self = self.hookentity;
	} while (self);
};

void() HookPull2 =
{
	local vector vel;//,x,vo,vp;
//local float vpn,vpnmin,xn,xnmin,acc,tmp, 
	local float v, dorg;
	local float a , b , c;
	
	if (self.enemy.takedamage)
	{
		if (!teamplay || self.enemy.team != self.owner.team)
		{
			if (!CanDamage(self.enemy, self.owner,"hook"))
			{
				HookVanish2();
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
				T_Damage (self.enemy, self, self.owner, 20);
				HookVanish2();
				return;
			}			

			//T_Damage (self.enemy, self, self.owner, 1);
			//at lower ticrates the hook damage is updated too fast
			//default 200a+100h = 30 seconds to death by hook
			self.hookdmg = (self.hookdmg + (sys_ticrate/0.1));

			if (self.hookdmg >= 1)
			{
				clanring_play_compat_sound(self, CHAN_WEAPON, "blob/land1.wav", "player/axhit1.wav", 1, ATTN_NORM);
				T_Damage (self.enemy, self, self.owner, 1);
				if (self.enemy.classname == "player")
				{
					SpawnBlood (self.origin, self.velocity, 10);
				}
				self.hookdmg = 0.00;
			}
			makevectors (self.v_angle);
		}

		if (self.enemy.solid == SOLID_SLIDEBOX)
		{
			//self.velocity = '0 0 0';
			self.velocity = self.enemy.velocity;
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

	if ( (!(self.owner.hook2 & HOOK_OUT)) || (self.owner.teleport_time > time ) || (self.owner.deadflag) || (gameover))
	{
		HookVanish2 ();
		return;
	}

	makevectors (self.owner.angles);
	vel = self.origin - ( self.owner.origin + (v_up * 16 * (!self.owner.button2)) + (v_forward * 16));

	v = vlen (vel);
	
	if (hookspeedpull < 600)
		hookspeedpull = 850;

	if ( v > 100 )
	{
		vel = (normalize(vel) * hookspeedpull);
	}
	else
	{
		if (v <= 100)
		{
			vel = ((normalize(vel) * v) * 10);
		}
	}
		
	self.owner.velocity = vel;
	
	if (!(self.owner.flags & FL_WATERJUMP)) //Slow down the hook pull if underwater!!
	{
		self.owner.velocity = ((1 - ((0.8 * self.owner.waterlevel) * frametime)) * self.owner.velocity);
	}

	if (clanring_use_custom_hook_assets())
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
/*

	v   = self.owner.velocity;
	x   = self.origin - (self.owner.origin + '0 0 16');
	xn  = vlen(x);
	x   = normalize(x);

	if (xn>0)
	{
		vp  = x*(v*x);
	}
	else
	{
		vp  = '0 0 0';
	}

	vpn  	= vlen(vp);
	vo  	= v - vp;
	tmp 	= vlen(vo);

	if (tmp > xn +100)
		vo = normalize(vo) * (tmp - 30);

	if (self.owner.hook2 & HOOK_SWING)
	{
		if (xn < 240)
		{
			acc = 2.5*xn;
		}
		else
		{
			acc = 850;
		}
	}
	else
	{
		if (xn < 100)
		{
			acc = 10*xn;
		}
		else
		{
			acc = 850;
			vo = '0 0 0';
		}

		if (xn < 100 && vp*x <= 0)
			self.owner.hook2 = self.owner.hook2 | HOOK_SWING;
	}

	vp = vp + 0.5*x*acc;

	if (vlen(vp) > acc)
		vp = normalize(vp)*acc;

	if (vlen(vo) > 700)
		vo = normalize(vo)*850;

	v = vo + vp;
	self.owner.velocity = v;

	if (self.owner.waterlevel > 2)
	{
		vpnmin = 100; xnmin = 80;
	}
	else
	{
		vpnmin = 500; xnmin = 280;
	}
*/
};

void() T_ChainTouch2 =
{
	if ((!(self.owner.hook2 & HOOK_OUT)) || (gameover))
	{
		HookVanish2 ();
		return;
	}
	if ((pointcontents (self.origin) == CONTENT_SKY))
	{
		HookVanish2 ();
		return;
	}
	if ((((other.classname == "player") && teamplay) && (other.team == self.owner.team)))
	{
		HookVanish2 ();
		return;
	}

	if (other.takedamage)
	{
		other.deathtype = "hook";
		T_Damage (other, self, self.owner, 10);
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

		if (other.solid == SOLID_SLIDEBOX)
		{
			other.axhitme = 1; // make axe noise
			setorigin(self, other.origin + other.mins + (other.size * 0.5));
			self.velocity = '0 0 0';
		}
		else
		{
			self.velocity = '0 0 0';
			self.velocity = other.velocity;
		}
	}
	else
	{
		sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
		self.avelocity = '0 0 0';
	}

	self.style = 3;
	self.enemy = other;
	self.nextthink = (time + sys_ticrate);
	self.think = HookPull2;
	self.touch = SUB_Null;
};

void() Hook_Check2 =
{
	local	vector 	chainvec;
	local 	float	chainlength;

	if ( (!(self.owner.hook2 & HOOK_OUT)) || (self.owner.deadflag) || (gameover))
	{
		HookVanish2 ();
		return;
	}

	chainvec = self.origin - (self.owner.origin + '0 0 16');

	chainlength = vlen (chainvec);

	if (chainlength > 1600)
	{
		self.movetype = MOVETYPE_BOUNCE;
	}

	if (self)
	{
		self.nextthink = time + sys_ticrate;
		self.think = Hook_Check2;
	}
};

void() LinkPos2 =
{
	//R00k added
	local vector dir;
	dir = self.owner.origin - (self.owner.owner.origin + '0 0 16');
  	self.angles = vectoangles(dir);

	setorigin(self, (self.owner.origin + (((self.enemy.origin + '0 0 16') - self.owner.origin) * self.weapon)));
	self.nextthink = (time + sys_ticrate);
};

void(entity myself) W_FireHook2 =
{
	local entity hook;
	local float linknum;
	local entity link = world;
	local entity prevlink;

	if (time < self.attack_finished)
	{
//		stuffcmd(self,";w5;+hook;\n");
		return;
	}
	
	self.hook2 = (self.hook2 | HOOK_OUT);
	self.attack_finished = time + 0.1;

	hook 				= spawn();
	hook.classname  	= "hook2_entity";
	hook.owner 			= myself;
	myself.hookentity 	= hook;
	hook.movetype 		= MOVETYPE_FLY;
	hook.solid 			= SOLID_BBOX;
	
	makevectors (myself.v_angle);
	
	if (hookspeedfire < 800)
		hookspeedfire = 1200;
	
	hook.velocity 		= hookspeedfire * aim (self, hookspeedfire);
	hook.angles 		= vectoangles (hook.velocity);
	hook.avelocity 		= '0 0 -500';
	hook.touch 			= T_ChainTouch2;
	hook.nextthink 		= time + 0.5;// lets check if we let off the button in mid-flight! eh?
	hook.think 			= Hook_Check2;

	setmodel (hook, "progs/v_spike.mdl");

	setsize (hook, '0 0 0', '0 0 0');
	setorigin(hook, myself.origin + (v_forward*16) + '0 0 16' );

		if (!clanring_use_custom_hook_assets())
		{
			clanring_play_compat_sound(self, CHAN_WEAPON, "hknight/hit.wav", "knight/sword1.wav", 1, ATTN_NORM);
		}
		else
		{
			clanring_play_compat_sound(self, CHAN_WEAPON, "weapons/chain1.wav", "knight/sword1.wav", 1, ATTN_NORM);
		}

	linknum = 8;
	prevlink = world;
	while (linknum)
	{
		link = spawn();
		link.classname = "hook_chain_link";
		link.hookentity = prevlink;
		prevlink = link;
		link.owner = hook;
		link.enemy = myself;
		link.weapon = (linknum / 9); //was 0.25);
		link.movetype = MOVETYPE_NOCLIP;
		link.solid = SOLID_NOT;
		/*
		link.angles_z = (31 * linknum);
		link.angles_y = (21 * linknum);
		link.angles_x = (11 * linknum);
		*/
		link.angles = vectoangles(hook.velocity);
		//link.avelocity = '110 210 310';
		setmodel (link, "progs/s_spike.mdl");
		setsize (link, '0 0 0', '0 0 0');
		makevectors (myself.angles);
		setorigin(link, hook.origin + (((myself.origin + (v_up * 16 * (!myself.button2)) + (v_forward * 16)) - hook.origin) * (link.weapon)));
		link.nextthink  = (time + sys_ticrate);
		link.think      = LinkPos2;
		linknum         = linknum - 1;
	}
	hook.hookentity = link;
};

void() SuperDamageSound;
void() HookFire2 =
{
	if (self.style & CLANRING_OBSERVER)
	{
		return;
	}

	if (gameover)
		return;
		
	if (clanring_playmode & CLANRING_MATCH_MODE)
		return;
	
	if (!(self.hook2 & HOOK_OUT))
	{
		W_FireHook2 (self);		
		SuperDamageSound();
		return;
	}
	else
	{		
		HookVanish2();
	}
};

void(entity e) HookOff_e =
{
	local entity this_e, old_self;

	this_e = find(world, classname, "hook2_entity");
	while (this_e)
	{
		if (this_e.owner == e)
		{
			old_self = self;
			self = this_e;
			HookVanish2 ();
			self = old_self;
			return;
		}
		this_e = find(this_e, classname, "hook2_entity");
	}
};

void() HookOff =
{
	HookOff_e (self);
};
