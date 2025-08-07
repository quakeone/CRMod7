float clanring_map_has_runes;
void() teamplay_show_score;
void() StartItem;
void() vote_impulse;
void() votables_disable_item;
void() hurt_touch;
void(entity client, float fragval) client_frag;
void () write_capture_stats;
void () write_capture_stats_match;
void (float t_statvalue, float t_teamcolor, string t_player) check_player_low_record;
void (float t_statvalue, float t_teamcolor, string t_player) check_player_low_record2;
void() match_bprint_score;

void(entity flg) RegenFlag =
{
	if (flg == world) return;
	
	flg.movetype  	= MOVETYPE_TOSS;
	flg.solid     	= SOLID_TRIGGER;

	if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
	{			
		flg.mins 	= '-16 -16 0';
		flg.maxs	= '16 16 74';		
	}
	else 
	{
		flg.effects = flg.effects - (flg.effects & EF_NOMODELFLAGS);
		flg.mins 	= '-16 -16 -24';
		flg.maxs	= '16 16 32';
	}		
		
	setorigin(flg, flg.oldorigin);			//original spawn position
	setsize (flg, flg.mins, flg.maxs);		//Hopefully this will reset the flag's bounding box after it got squished by bsp								
							
	sound(flg, CHAN_AUTO, "items/itembk2.wav", 1, ATTN_NORM);
	flg.angles    	= flg.mangle;
	flg.cnt       	= FLAG_AT_BASE; 

	if ((flg.team == RED))
		forceinfokey (world, "red flag","at base");
	else
		forceinfokey (world, "blue flag","at base");

	if (flg.owner != world)
		flg.owner.items = flg.owner.items - (flg.owner.items & (IT_KEY1 | IT_KEY2));
		
	flg.owner     	= world;
	flg.nextthink 	= (time + sys_ticrate);
	flg.flags 	= FL_ITEM; 			// clear FL_ONGROUND and any other junk

//R00k: I swear I've heard the flag make an 'out of water' sound when it respawned...
	flg.watertype	= CONTENT_EMPTY;
	flg.waterlevel	= 0;
};

void(entity flg) TeamCaptureReturnFlag =
{
	RegenFlag (flg);

//	if (!(clanring_playmode & CLANRING_MATCH_MODE))	//  Only show newbie messages in newbie mode.
	{
		local entity p;
		p = find(world, classname, "player");

		while (p != world)
		{		
			if ((p.style & CLANRING_OBSERVER) && (flg.team == RED))
			{
				centerprint(p, "\bRED\b flag has been returned to base!\n");
			}
			else
			{			
				if ((p.style & CLANRING_OBSERVER) && (flg.team == BLUE))
				{
					centerprint(p, "\bBLUE\b flag has been returned to base!\n");
				}
				else
				{
					if (!(clanring_playmode & CLANRING_MATCH_MODE))	//  Only show newbie messages in newbie mode.
					{
						if (p.team != flg.team)
						{
							centerprint(p, "Enemy \bflag\b has been returned to base!");
						}
						else
						{
							if (p.team == flg.team)
							{
								centerprint (p, "Your \bflag\b has been returned to base!");	
							}
						}
					}
				}
			}
			p = find(p, classname, "player");
		}
	}
	sound (world, CHAN_AUTO, self.noise1, 1, ATTN_NONE);
};

void() TeamCaptureRegenFlags =
{
	local entity f;

	f = find(world, classname, "item_flag_team1");
	
	if (f != world)	
	{
		if (f.owner.classname == "player")		
			f.owner.items = f.owner.items - (f.owner.items & IT_KEY1);
		RegenFlag(f);
	}	
	
	f = find(world, classname, "item_flag_team2");	
	
	if (f != world)
	{
		if (f.owner.classname == "player")		
			f.owner.items = f.owner.items - (f.owner.items & IT_KEY2);
		RegenFlag(f);
	}
};

void(entity flg) TeamDropFlag =
{
	local entity p;
	
	if (!flg.owner)
	{
		dprint("FLAG: drop - no owner?!?!\n");
		return;
	}

	p = flg.owner;
	
	if (p == world)
		return; //already done.
		
	if (p.team == RED)
	{
		announce2(p.netname," ÏÔÛÙ the ¬Ã’≈ flag!"); // blue
	}
	else
	{
		announce2(p.netname," ÏÔÛÙ the “≈ƒ flag!"); // red
	}

	p.fctime += (time - p.flag_since);

//	if (clanring_playmode & CLANRING_MATCH_MODE)
	//	p.next_team.fctime += (time - p.flag_since);
	flg.owner      	= world;
	flg.origin     	= p.origin - '0 0 16';	
	flg.cnt        	= FLAG_DROPPED;
	flg.velocity_z 	= 300;
	flg.velocity_x 	= 0;
	flg.velocity_y 	= 0;
	flg.flags      	= FL_ITEM;
	flg.solid      	= SOLID_TRIGGER;
	flg.movetype   	= MOVETYPE_TOSS;

	if ((flg.team == RED))
		forceinfokey (world, "red flag","dropped");
	else
		forceinfokey (world, "blue flag","dropped");

	sound(flg, CHAN_AUTO, "misc/basekey.wav", 1, ATTN_NONE);
	
	if (!(clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM))
	{
		flg.angles = flg.angles + '0 0 180';
	}

	if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
	setsize (flg, '-16 -16 0', '16 16 74');
	else
	setsize(flg, '-16 -16 -24', '16 16 32');

	// return it after so long
	flg.super_time = time + TEAM_CAPTURE_FLAG_RETURN_TIME;
};

void(entity player, float reset) TeamCaptureDropFlagOfPlayer =
{
	local entity e;

	if (player.classname != "player")
		return;//sanity check from lagouts
	
	e = find(world, classname, "item_flag_team1");	
	
	if ((e != world) && (e.owner != player))
	{	
		e = find(world, classname, "item_flag_team2");	
		if ((e != world) && (e.owner != player))
		{
			return;
		}	
	}	
	
	player.flag_carrier = FALSE;		
	player.items = player.items - (player.items & (IT_KEY1 | IT_KEY2));
	
	// Reset flag carry tracking when flag is dropped
	player.flag_carry_start = 0;

	if (reset) 
	{
		RegenFlag(e);
	}
	else
	{
		if (e != world)	
		{
			TeamDropFlag(e);
		}
	}
};

void() TeamCaptureFlagTouch =
{
	local entity p;
	local float compare, i=0,j=0;

	if (clanring_state & CLANRING_MATCH_PAUSED)
		return;

	if (other.solid == SOLID_BSP)
	{
		if (self.cnt == FLAG_AT_BASE) 
		{
			setorigin(self, self.oldorigin);	// E1M3 squish BLUE flag bug fix!!
			if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
			setsize (self, '-16 -16 0', '16 16 74');
			else
			setsize(self, '-16 -16 -24', '16 16 32');
		}
		return;
	}
		
	if (other.solid == SOLID_TRIGGER)
	{
		if (self.cnt == FLAG_DROPPED) 
		{
			if (other.touch == hurt_touch)		// if flag lands on a trigger_hurt return it to base...
			{
				if (other.dmg > 10)
				{
					self.super_time = time - 30;	// just reset the respawn time and let						    		
				}					// the think routine control the return...
			}		
		}		
	}

	if (clanring_state & CLANRING_NULL_FLAG)
		return;
		
	if (other.classname != "player")
		return;

	if (other.health <= 0)
		return;

	if (other.style & CLANRING_OBSERVER)
		return;

	if (clanring_playmode & CLANRING_PRACTICE_MODE)
	{
		centerprint (other, "Flags are \binactive\b in practice mode.\n");
		return;
	}

	if ((other.team != RED) && (other.team != BLUE))
		return;

	//--------------------------------------------------	
	if (self.team == other.team)
	{
		if (self.cnt == FLAG_AT_BASE)
		{
			if (other.flag_carrier==TRUE)
			{				
				if (other.team == RED)
					announce2(other.netname," „·ÙıÚÂ‰ the ¬Ã’≈ ∆Ã¡«!");
				else
					announce2(other.netname," „·ÙıÚÂ‰ the “≈ƒ ∆Ã¡«!");

				compare = (time - other.lefty);//stop the clock
				if (other.lefty > 0)
				{
					bprint("\bcapture time \x90");
					utils_bprint_time (compare);
					bprint("\x91\n");					
					if (compare < other.captime) other.captime = compare;

					if (clanring_playmode & CLANRING_MATCH_MODE)
					{
						new_player_record = 0;
						if (!(clanring_state & CLANRING_MATCH_STARTED))
						{
							check_player_low_record(compare, other.team, other.netname);
							if (new_player_record > 0)
							{
								if (new_player_record == 1)
								{
									sound(world,CHAN_AUTO,"crx/congrats.wav",1,ATTN_NONE);
									clanring_new_record_player = other.netname;
								}									
								else if ((new_player_record == 2) || (new_player_record == 3))
									sound(world,CHAN_AUTO,"crx/goodstat.wav",1,ATTN_NONE);
								write_capture_stats();
							}
							//else sound(world,CHAN_AUTO,"crx/capreg.wav",1,ATTN_NONE);
						}
						else
						{
							if (clanring_maxsize > 1)
							{
								check_player_low_record2(compare, other.team, other.netname);
								if (new_player_record > 0)
								{
									new_player_record_match = new_player_record;
									write_capture_stats_match();
								}
							}
						}
					}
				}
				other.fctime += (time - other.flag_since);

				other.items = other.items - (other.items & (IT_KEY1 | IT_KEY2));
				last_flag_capture = time;
				last_capture_team = other.team;

				// no score/stats from prematch capture practice
				if (((clanring_playmode & CLANRING_MATCH_MODE) && (clanring_state & CLANRING_MATCH_STARTED))
					|| (clanring_playmode & CLANRING_NORMAL_MODE))
				{
					sound (world, CHAN_AUTO, self.noise2, 1, ATTN_NONE);
					
					client_frag(other, TEAM_CAPTURE_CAPTURE_BONUS);//score for capture
					other.fcaptures = (other.fcaptures + 1);//fstats

					// Check if there was a recent strategic return by a teammate
					local entity returner;
					if (other.team == RED)
						returner = last_red_returner;
					else
						returner = last_blue_returner;

					if (returner && returner != other && (time - last_return_time < 5)) // 5 second window
					{
						returner.strategic_returns = returner.strategic_returns + 1;
					}

					// R00k: update scores for console and infokeys
					if (clanring_playmode & CLANRING_MATCH_MODE)
						match_bprint_score();

					// Ok, let's do the player loop, hand out the bonuses
					p = find(world, classname, "player");
					while (p != world)
					{
						if (!(clanring_playmode & CLANRING_MATCH_MODE))
						{
							if ((p.style & CLANRING_OBSERVER) && (other.team == RED))
							{
								centerprint(p, "\bRED\b TEAM captured the blue flag!\n");
							}
							else
							{			
								if ((p.style & CLANRING_OBSERVER) && (other.team == BLUE))
								{
									centerprint(p, "\bBLUE\b TEAM captured the red flag!\n");
								}
							}
						}

						p.killed = FALSE;
						
						if (p.team == other.team)
						{
							if (!(clanring_playmode & CLANRING_MATCH_MODE))
								centerprint(p, "Your team captured the flag!\n");
							
							client_frag(p, TEAM_CAPTURE_TEAM_BONUS); //team score for capture
							
							if ((p.last_returned_flag + TEAM_CAPTURE_RETURN_FLAG_ASSIST_TIMEOUT) > time)
							{
								announce2(p.netname," gets an assist for returning the ∆Ã¡«!");
								client_frag(p, TEAM_CAPTURE_RETURN_FLAG_ASSIST_BONUS);// awarded for returning a flag that causes a capture to happen almost immediately
								p.fcassists = (p.fcassists + 1);//fstat
							}
							
							if ((p.last_fragged_carrier + TEAM_CAPTURE_FRAG_CARRIER_ASSIST_TIMEOUT) > time)
							{								
								announce2(p.netname," gets an assist for fragging the ∆Ã¡« carrier!");
								client_frag(p, TEAM_CAPTURE_FRAG_CARRIER_ASSIST_BONUS);// award for fragging a flag carrier if a capture happens almost immediately
								p.fcassists = (p.fcassists + 1);//fstat
							}
						}
						else
						{
							if (!(clanring_playmode & CLANRING_MATCH_MODE))
								centerprint(p, "Your flag was captured!\n");
							p.last_hurt_carrier = -5;
						}
						
						p = find(p, classname, "player");
					}
				}
				else if ((clanring_playmode & CLANRING_MATCH_MODE) && !(clanring_state & CLANRING_MATCH_STARTED))
				{
					other.leaderboardtime = time + 5;
				}

				other.flag_carrier = FALSE;// doesnt have a flag anymore.

				// Reset flag carry tracking when flag is captured
				other.flag_carry_start = 0;

				TeamCaptureRegenFlags ();// respawn flags
				return;
			}
			return;
		}//end flag was at base

		//--begin flag laying on the field...
		if (other.team == RED)
			announce2(other.netname," ÚÂÙıÚÓÂ‰ the “≈ƒ ∆Ã¡«!");
		else
			announce2(other.netname," ÚÂÙıÚÓÂ‰ the ¬Ã’≈ ∆Ã¡«!");

		if (!(clanring_playmode & CLANRING_MATCH_MODE) || (clanring_state & CLANRING_MATCH_STARTED))
		{
			client_frag(other, TEAM_CAPTURE_RECOVERY_BONUS);		
			other.freturns = (other.freturns + 1);//fstats		
			other.last_returned_flag = time;

			// Store who returned the flag for strategic return tracking
			if (other.team == RED)
				last_red_returner = other;
			else
				last_blue_returner = other;
    
			last_return_time = time;

		}
		TeamCaptureReturnFlag (self);//send it back home
		return;
	}//end we touched our own flag

	//begin take flag thats not ours!
	if (self.team == RED)
	{
		announce2(other.netname," ÁÔÙ the “≈ƒ ∆Ã¡«!");
	}
	else
	{
		announce2(other.netname," ÁÔÙ the ¬Ã’≈ ∆Ã¡«!");
	}
	//newbie message removed:
	//YOU GOT THE ENEMY FLAG
	//RETURN TO BASE
	//centerprint(other, "Ÿœ’ «œ‘ ‘»≈ ≈Œ≈ÕŸ ∆Ã¡«\n\n“≈‘’“Œ ‘œ ¬¡”≈\n");
	if ((clanring_playmode & CLANRING_MATCH_MODE) && (!(clanring_state & CLANRING_MATCH_STARTED)))
	{
		centerprint(other, "éématch has not begunéé\n\x80\x81\bcapture time trials\b\x81\x82");
	}

	if ((!(clanring_playmode & CLANRING_MATCH_MODE)) || (clanring_state & CLANRING_MATCH_STARTED))
	{
		sound (world, CHAN_AUTO, self.noise, 1, ATTN_NONE);
		other.fpickups	= (other.fpickups + 1);//fstat
	}

	// Start tracking flag carry time for non-camping measurement
	other.flag_carry_start = time;
	other.last_carry_pos = other.origin;
	other.last_pos_check = time;

	other.flag_carrier	= TRUE;
	other.items        	= (other.items | self.items);
	other.flag_since   	= time;
	
	//pickup time only when taken from base
	if (self.cnt == FLAG_AT_BASE)
	{
		other.lefty = time;//captime
	}
	else
	{
		other.lefty = 0;
	}

	self.cnt		= FLAG_CARRIED;
	self.movetype	= MOVETYPE_NOCLIP;
	self.solid		= SOLID_NOT;
	self.owner		= other;
	self.effects |= EF_NOMODELFLAGS;

	if ((self.team == RED))
		forceinfokey (world, "red flag","carried");
	else
		forceinfokey (world, "blue flag","carried");


	if (!(clanring_playmode & CLANRING_MATCH_MODE))
	{
		p = find(world, classname, "player");
	
		while (p != world)
		{
			if (p != other)
			{
				if (p.style & CLANRING_OBSERVER)
				{
					if (self.team == RED)
					{
						centerprint (p, "“≈ƒ flag has been taken");
					}
					else
					{
						if (self.team == BLUE)
						{
							centerprint (p, "¬Ã’≈ flag has been taken");
						}
					}
				}
				else
				{
					if (p.team != other.team)
					{
						centerprint (p, "Your ∆Ã¡« has been taken!");
					}
					else
					{
						centerprint (p, "Your team has the enemy ∆Ã¡«!");
					}
				}
			}
			p = find(p, classname, "player");
		}
	}
};

void() flag_check_size =
{
	if ((self.maxs_x < 16) || (self.maxs_y < 16))
	{
		if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
		{			
			self.mins 	= '-16 -16 0';
			self.maxs	= '16 16 74';		
		}
		else 
		{
			self.mins 	= '-16 -16 -24';
			self.maxs	= '16 16 32';
		}		
		
		setsize (self, self.mins, self.maxs);		//Hopefully this will reset flag's bounding box after it got squished by bsp
		
		//Fell off the map return now!
		TeamCaptureReturnFlag (self);
	}	
};

void() TeamCaptureFlagThink =
{
	local entity e;
	local vector v;
	local float f;

	if (clanring_playmode & CLANRING_PRACTICE_MODE)
		return;

	if (clanring_state & CLANRING_MATCH_PAUSED)
		return;		

	self.nextthink = (time + sys_ticrate);
	
	if (self.cnt == FLAG_AT_BASE)
	{			
		self.solid = SOLID_TRIGGER;//just to make sure		
		return;
	}	
	
	if (self.cnt == FLAG_DROPPED)
	{
		flag_check_size ();			
//		if (!(clanring_state & CLANRING_MATCH_PAUSED))//3.19k
		{
			if ((time - self.super_time) > 30)
				TeamCaptureReturnFlag (self);
			return;
		}
	}

	if (self.cnt != FLAG_CARRIED)
		objerror ("Flag in invalid state\n");
	
	e = self.owner;
	
	if (e.deadflag)
	{
		TeamDropFlag (self);
		return;
	}	
	
	makevectors (e.angles);
	v = v_forward;
	v_z = (-1 * v_z);
	f = 14;
	
	if (self.owner.frame >= 29 && self.owner.frame <= 40) 
	{
		if (self.owner.frame >= 29 && self.owner.frame <= 34)  //axpain
		{
			if 		(self.owner.frame == 29) f = f + 2; 			
			else if (self.owner.frame == 30) f = f + 8;				 
			else if (self.owner.frame == 31) f = f + 12;				 
			else if (self.owner.frame == 32) f = f + 11;
			else if (self.owner.frame == 33) f = f + 10;
			else if (self.owner.frame == 34) f = f + 4;
		} 
		else 
		if (self.owner.frame >= 35 && self.owner.frame <= 40) // pain
		{ 
			if		(self.owner.frame == 35) f = f + 2; 
			else if (self.owner.frame == 36) f = f + 10;
			else if (self.owner.frame == 37) f = f + 10;
			else if (self.owner.frame == 38) f = f + 8;
			else if (self.owner.frame == 39) f = f + 4;
			else if (self.owner.frame == 40) f = f + 2;
		}
	}	 
	else 	
	if (self.owner.frame >= 103 && self.owner.frame <= 118) 
	{
		if      (self.owner.frame >= 103 && self.owner.frame <= 104) f = f + 6;  //nailattack
		else if (self.owner.frame >= 105 && self.owner.frame <= 106) f = f + 6;  //light 
		else if (self.owner.frame >= 107 && self.owner.frame <= 112) f = f + 7;  //rocketattack
		else if (self.owner.frame >= 112 && self.owner.frame <= 118) f = f + 7;  //shotattack
	}
	
	self.angles = e.angles;
	
	self.angles = e.angles + '0 0 -45';
	self.origin = e.origin + '0 0 -16' - f*v + v_right * 22;
	
	if (self.mdl == "progs/flag.mdl")		
	{			
		setsize (self, '-16 -16 0', '16 16 74');
	}
	else 
	{
		setsize(self, '-16 -16 -24', '16 16 32');
	}		
	setorigin(self, self.origin);	//required
	self.nextthink = (time + sys_ticrate);
};

// *Capture The Flag - Status report by Wonko
// modified
void() TeamFlagStatusReport =
{
	local entity flag1, flag2, p;

	flag1 = find(world, classname, "item_flag_team1");
	flag2 = find(world, classname, "item_flag_team2");
	
	if ((self.team != RED) && (!(self.style & CLANRING_OBSERVER)))
	{
        p = flag1;
		flag1 = flag2;
		flag2 = p;
	}
	
	if ((flag1 == world) && (flag2 == world))
	{
		sprint(self, "Flags are missing\n");
		return;
	}
	
	if ((flag1 != world) && (flag1.cnt == FLAG_CARRIED))
	{                		
		if (flag1.team == BLUE)
		{
			sprint(self,"\x90blue flag\x91 \b: carried by ");		                             
		}
		else
		{
			sprint(self,"\x90red flag\x91  \b: carried by ");
		}                 
		sprint2(self, flag1.owner.netname,"\n");	
	}
	else
	{
		if (flag1.team == BLUE)
		{
			sprint(self,"\x90blue flag\x91 \b:");
		}                 
		else
		{
			sprint(self,"\x90red flag\x91  \b:");
		} 		     
		
		if (flag1 == world)
		{
			sprint(self, " missing\n");
		}
		else
		{
			if (flag1.cnt == FLAG_AT_BASE)
			{
				sprint(self, " at base\n");
			}
			else
			{
				if (flag1.cnt == FLAG_DROPPED)
				{
					sprint(self, " on the field\n");
				}
				else
				{				
					sprint(self, " lost\n");				
				}
			}
		}
	}
	//--------------------------------------------------------
	if ((flag2 != world) && (flag2.cnt == FLAG_CARRIED))
	{                			
		if (flag2.team == BLUE)
		{
			sprint(self," blue flag  \b: carried by ");
		}                 
		else
		{
			sprint(self," red flag   \b: carried by ");
		}                 
	   sprint2(self, flag2.owner.netname,"\n");	
	}
	else
	{
		if (flag2.team == BLUE)
		{
			sprint(self," blue flag  \b:");
		}
		else
		{
			sprint(self," red flag   \b:");
		} 		     
		
		if (flag2 == world)
		{
			sprint(self, " missing\n");
		}
		else
		if (flag2.cnt == 0)
		{
			sprint(self, " at base\n");
		}
		else
		{
			if (flag2.cnt == FLAG_DROPPED)
			{
				sprint(self, " on field\n");
			}
			else
			{
				sprint(self, " lost\n");

			}
		}
	}
	if (!(clanring_playmode & CLANRING_MATCH_MODE))
	{
		teamplay_show_score();
	}
};

void() place_flag =
{
	self.mdl       = self.model;
	self.flags     = FL_ITEM;
	self.solid     = SOLID_TRIGGER;
	self.movetype  = MOVETYPE_TOSS;
	self.velocity  = VEC_ORIGIN;	
	self.effects   = self.effects | EF_DIMLIGHT;		
	self.origin_z  = self.origin_z + 6;
	self.think     = TeamCaptureFlagThink;
	self.touch     = TeamCaptureFlagTouch;
	self.nextthink = time + (sys_ticrate);
	self.cnt       = FLAG_AT_BASE;
	self.mangle    = self.angles;	

	self.watertype	= CONTENT_EMPTY;
	self.waterlevel	= 0;

	if (!droptofloor())
	{
		dprint ("Flag fell out of level at ");
		dprint (vtos (self.origin));
		dprint ("\n");
		remove(self);
		return;
	}	

	if ((self.team == RED))
		forceinfokey (world, "red flag","at base");
	else
		forceinfokey (world, "blue flag","at base");

	self.oldorigin = self.origin;//base position
};

void() item_flag_team1 =
{
	if (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))
	{
		remove(self);
		return;
	}

	self.team      = 5;	
	self.items     = IT_KEY2;	
	self.owner     = world;		
	self.effects   = self.effects | EF_RED;

	forceinfokey (world, "red flag","at base");
	
	if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
	{
		self.skin      	= 0;				
		precache_model 	("progs/flag.mdl");		
		setmodel (self, "progs/flag.mdl");
		self.mdl       	= "progs/flag.mdl";			
		precache_sound 	("misc/flagtk.wav");			// flag taken
		precache_sound 	("misc/flagcap.wav");			// flag capture
		precache_sound 	("doors/runetry.wav");
		self.noise     	= "misc/flagtk.wav";
		self.noise1    	= "doors/runetry.wav";
		self.noise2    	= "misc/flagcap.wav";//added noise2
		//self.noise3
		self.mins 	= '-16 -16 0';
		self.maxs	= '16 16 74';
		setsize (self, self.mins, self.maxs);	
	}
	else
	{
		self.origin_z  = self.origin_z + 24;// dont let it spawn in map
		precache_model ("progs/w_g_key.mdl");
		setmodel       (self, "progs/w_g_key.mdl");
		self.mdl       = "progs/w_g_key.mdl";	
		self.skin      = 0;					
		precache_sound ("misc/medkey.wav");
		precache_sound ("doors/meduse.wav");
		precache_sound ("doors/runetry.wav");
		self.noise     = "shambler/ssight.wav";//take
		self.noise1    = "doors/runetry.wav";//return				
		self.noise2    = "boss2/pop2.wav";//cap//added noise2
		//self.noise3
		self.mins 	= '-16 -16 -24';
		self.maxs	= '16 16 32';
		setsize (self, self.mins, self.maxs);		
	}
	self.classname = "item_flag_team1";		
	self.think     = place_flag;
	self.nextthink = (time + 0.2);	
};

void() item_flag_team2 =
{
	if (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))
	{
		remove(self);
		return;
	}
		
	self.team      = 14;	
	self.items     = IT_KEY1;	
    self.owner     = world;	        
	self.effects   = self.effects | EF_BLUE;

	forceinfokey (world, "blue flag","at base");
	
	if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
	{		
		precache_model ("progs/flag.mdl");
		setmodel (self, "progs/flag.mdl");
		self.mdl       = "progs/flag.mdl";
		self.skin      = 1;					
		precache_sound ("misc/flagtk.wav");			// flag taken
		precache_sound ("misc/flagcap.wav");			// flag capture
		precache_sound ("doors/runetry.wav");
		self.noise     = "misc/flagtk.wav";
		self.noise1    = "doors/runetry.wav";
		self.noise2    = "misc/flagcap.wav";//added noise2
		//self.noise3
		//setsize (self, '-16 -16 0', '16 16 74');       		
		self.mins 	= '-16 -16 0';
		self.maxs	= '16 16 74';
		setsize (self, self.mins, self.maxs);	
	}
	else
	{		
		self.origin_z = self.origin_z + 24;
		precache_model ("progs/w_s_key.mdl");
		setmodel (self, "progs/w_s_key.mdl");
		self.mdl       = "progs/w_s_key.mdl";	
		self.skin      = 0;					
		precache_sound ("misc/medkey.wav");
		precache_sound ("doors/meduse.wav");
		precache_sound ("doors/runetry.wav");
		//self.noise     = "misc/medkey.wav";//take
		self.noise     = "shambler/ssight.wav";//take
		self.noise1    = "doors/runetry.wav";//return				
		self.noise2    = "boss2/pop2.wav";//cap//added noise2
		//self.noise3
		//setsize(self, '-16 -16 -24', '16 16 32');
		self.mins 	= '-16 -16 -24';
		self.maxs	= '16 16 32';
		setsize (self, self.mins, self.maxs);		
	}	
	self.classname = "item_flag_team2";
	self.think     = place_flag;
	self.nextthink = (time + 0.2);	
};

void() func_clanring_wall =
{
	self.angles   = '0 0 0';
	self.movetype = MOVETYPE_PUSH;
	self.solid    = SOLID_BSP;
	setmodel (self, self.model);
};

//--Runes Code Based from ZOID's 3WAVE CTF
//------------------------------------------

void(float flag) Do_DropRune;
//https://github.com/quakeone/CRx/pull/85 
void() item_rune_res =
{
	self.player_flag = ITEM_RUNE1_FLAG;
	clanring_map_has_runes = TRUE;
}

void() item_rune_str =
{
	self.player_flag = ITEM_RUNE2_FLAG;
	clanring_map_has_runes = TRUE;
}

void() item_rune_hst =
{
	self.player_flag = ITEM_RUNE3_FLAG;
	clanring_map_has_runes = TRUE;
}

void() item_rune_rgn =
{
	self.player_flag = ITEM_RUNE4_FLAG;
	clanring_map_has_runes = TRUE;	//This flag is set FALSE by default to spawn dynamic runes if the map does not have spawnpoints already defined.
}

entity () SelectRuneSpawnPoint =
{
	runespawn = find(runespawn, classname, "info_player_deathmatch");
	if (runespawn == world)
	{
		runespawn = find(runespawn, classname, "info_player_deathmatch");
	}
	if (runespawn == world)
	{
		error ("no info_player_deathmatch to spawn rune");
	}
	return (runespawn);
};

void() RuneTouch =
{
	if ((clanring_playmode & CLANRING_MATCH_MODE) && !(clanring_state & CLANRING_MATCH_STARTED))
	{
		return;
	}

	if (other.classname != "player") return;

	if (other.health <= 0) return;

	if (self.style & CLANRING_OBSERVER)  return;

	if ((other == self.owner) && (self.nextthink > time + 119))
		return;

	if (other.classname == "trigger_hurt")
	{
		self.nextthink = time;	// just reset the respawn time and let the think function control the return...
		return;
	}

	if (other.player_flag & ITEM_RUNE_MASK)
	{
		centerprint(other, "You already have a rune.\n");
		return;
	}

	other.player_flag = (other.player_flag | self.player_flag);
	other.stats_item_runes +=1;
	
	if (other.player_flag & ITEM_RUNE1_FLAG)//Rune 1 - Earth Magic(resistance)
	{
		other.items2 = (other.items2 | IT2_SIGIL1);
		sprint(other,"you got the rune of ≈·ÚÙË Õ·ÁÈ„!    \b[resistance]\n");
	}
	else
	{
		if (other.player_flag & ITEM_RUNE2_FLAG)//Rune 2 - Black Magic(strength)
		{
			other.items2 = (other.items2 | IT2_SIGIL2);			
			sprint(other,"you got the rune of ¬Ï·„Î Õ·ÁÈ„!    \b[strength]\n");			
		}
		else
		{
			if (other.player_flag & ITEM_RUNE3_FLAG)
			{
				other.items2 = (other.items2 | IT2_SIGIL3);
				sprint(other,"you got the rune of »ÂÏÏ Õ·ÁÈ„!    \b[haste]\n");//Rune 3 - Hell Magic(haste)				
			}
			else
			{
				if (other.player_flag & ITEM_RUNE4_FLAG)//Rune 4 - Elder Magic(regeneration)
				{
					other.items2 = (other.items2 | IT2_SIGIL4);					
					sprint(other,"you got the rune of ≈Ï‰ÂÚ Õ·ÁÈ„!    \b[regeneration]\n");					
					other.max_health = 150;
				}
			}
		}
	}
	sound (other, CHAN_ITEM, "misc/runekey.wav", 1, ATTN_NORM);
	remove(self);
};

void() RuneRespawn =
{
	local entity oself;

	oself = self;
	self = SelectRuneSpawnPoint ();
	Do_DropRune (oself.player_flag);
	remove(oself);
};

void(float flag) Do_DropRune =
{
	local entity item;

	item = spawn();
	item.owner = item;
	item.origin = (self.origin - '0 0 24');	
	item.player_flag = flag;
	if (clanring_map_has_runes == FALSE)
	{
		item.velocity_z = 400;
		item.velocity_x = (-500 + (random () * 1000));
		item.velocity_y = (-500 + (random () * 1000));
	}
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;

	if (flag & ITEM_RUNE1_FLAG)
	{
		setmodel (item, "progs/end1.mdl");
	}
	else
	{
		if (flag & ITEM_RUNE2_FLAG)
		{
			setmodel (item, "progs/end2.mdl");
		}
		else
		{
			if (flag & ITEM_RUNE3_FLAG)
			{
				setmodel (item, "progs/end3.mdl");
			}
			else
			{
				if (flag & ITEM_RUNE4_FLAG)
				{
					setmodel (item, "progs/end4.mdl");
				}
			}
		}
	}
	setsize (item, '-16 -16 0', '16 16 56');
	item.touch = RuneTouch;
	item.nextthink = (time + 120);
	item.think = RuneRespawn;
	item.classname = "item_rune";
};
//void() RuneRotHealthThink;

void() DropRune =
{
//	local entity e;

	if (self.player_flag & ITEM_RUNE1_FLAG)
	{
		self.items2 = self.items2 - (self.items2 & IT2_SIGIL1);
		Do_DropRune (ITEM_RUNE1_FLAG);
	}
	else
	if (self.player_flag & ITEM_RUNE2_FLAG)
	{
		self.items2 = self.items2 - (self.items2 & IT2_SIGIL2);
		Do_DropRune (ITEM_RUNE2_FLAG);
	}
	else
	if (self.player_flag & ITEM_RUNE3_FLAG)
	{
		self.items2 = self.items2 - (self.items2 & IT2_SIGIL3);
		Do_DropRune (ITEM_RUNE3_FLAG);
	}
	else
	if (self.player_flag & ITEM_RUNE4_FLAG)
	{		
		self.items2 = self.items2 - (self.items2 & IT2_SIGIL4);
		self.regen_time = 0;
		Do_DropRune (ITEM_RUNE4_FLAG);
		/*
		if (!(self.style & CLANRING_OBSERVER))
		{
			e = spawn();
			e.nextthink = time + 5;
			e.think = RuneRotHealthThink;
			e.owner = self;
		}*/
	}
	self.player_flag = (self.player_flag - (self.player_flag & ITEM_RUNE_MASK));
};

void() SpawnRunes =
{
	local entity oself;
	local float i;

	oself = self;
	if (clanring_map_has_runes == FALSE)
	{
		i = (random() * 10);
		while (i > 0)
		{
			self = SelectRuneSpawnPoint ();
			i = i - 1;
		}
		self = SelectRuneSpawnPoint ();
		Do_DropRune (ITEM_RUNE1_FLAG);
		self = SelectRuneSpawnPoint ();
		Do_DropRune (ITEM_RUNE2_FLAG);
		self = SelectRuneSpawnPoint ();
		Do_DropRune (ITEM_RUNE3_FLAG);
		self = SelectRuneSpawnPoint ();
		Do_DropRune (ITEM_RUNE4_FLAG);
	}
	else
	{
		self = find(world,classname,"item_rune_res");
		Do_DropRune (ITEM_RUNE1_FLAG);
		self = find(world,classname,"item_rune_str");
		Do_DropRune (ITEM_RUNE2_FLAG);
		self = find(world,classname,"item_rune_hst");
		Do_DropRune (ITEM_RUNE3_FLAG);
		self = find(world,classname,"item_rune_rgn");
		Do_DropRune (ITEM_RUNE4_FLAG);
	}
	remove(oself);
};

void() StartRuneSpawn =
{
	local entity rspawn;

	rspawn = spawn();
	rspawn.nextthink = time + 0.1;
	rspawn.think = SpawnRunes;
};

void()StartRuneSpawnStart =
{
	if (!(clanring_playmode & CLANRING_RUNES))
	{
		remove(self);
		return;
	}
	utils_do_item(votables_disable_item, "item_rune");//?
	StartRuneSpawn ();
	remove(self);
};

/*
void() RuneRotHealthThink =
{
	other = self.owner;

	if ((((other.health <= 100) || (other.player_flag & ITEM_RUNE4_FLAG)) || (other.items & IT_SUPERHEALTH)))
	{
		remove(self);
		return;
	}

	other.health = (other.health - 1);
	self.think = RuneRotHealthThink;
	self.nextthink = (time + 1);
};
*/
void() TossRune =
{
	local entity item;
//	local entity e;

	if (self.style & CLANRING_OBSERVER)
		return;

	if (!(clanring_playmode & CLANRING_RUNETOSS))
		return;
		
	if ((self.player_flag & ITEM_RUNE_MASK) == FALSE)
		return;

	item = spawn();
	item.owner = self;
	makevectors (self.v_angle);
	setorigin(item, (self.origin + '0 0 20'));
	item.velocity = aim (self, 1000);
	item.velocity = (item.velocity * 600);
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_BOUNCE;
	
	if (self.player_flag & ITEM_RUNE1_FLAG)
	{
		item.player_flag = ITEM_RUNE1_FLAG;
		setmodel (item, "progs/end1.mdl");
		self.items2 = self.items2 - (self.items2 & IT2_SIGIL1);
	}
	else
	{
		if (self.player_flag & ITEM_RUNE2_FLAG)
		{
			self.items2 = self.items2 - (self.items2 & IT2_SIGIL2);
			item.player_flag = ITEM_RUNE2_FLAG;
			setmodel (item, "progs/end2.mdl");
		}
		else
		{
			if (self.player_flag & ITEM_RUNE3_FLAG)
			{
				item.player_flag = ITEM_RUNE3_FLAG;
				setmodel (item, "progs/end3.mdl");
				self.items2 = self.items2 - (self.items2 & IT2_SIGIL3);				
			}
			else
			{
				if (self.player_flag & ITEM_RUNE4_FLAG)
				{
					item.player_flag = ITEM_RUNE4_FLAG;
					setmodel (item, "progs/end4.mdl");
					self.items2 = self.items2 - (self.items2 & IT2_SIGIL4);
					self.max_health = 100;//R00k v3.3
				}
			}
		}
	}
	setsize (item, '-16 -16 0', '16 16 56');
	item.touch = RuneTouch;
	item.nextthink = (time + 120);
	item.think = RuneRespawn;
	self.player_flag = (self.player_flag - (self.player_flag & ITEM_RUNE_MASK));
	item.classname = "item_rune";
};
