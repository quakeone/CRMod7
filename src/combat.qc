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

.entity oldenemy;
void() T_MissileTouch;
void() info_player_start;
void(entity targ, entity attacker) ClientObituary;
void(entity who) ResistanceSound;
/*
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
*/
//float(entity targ, entity inflictor) CanDamage =
float(entity targ, entity inflictor, string dtype) CanDamage =	// 1998-10-04 Hit outside water by a discharge fix by Maddes
{
	// bmodels need special checking because their origin is 0,0,0
	if (targ.movetype == MOVETYPE_PUSH)
	{
		traceline(inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, self);
		if (trace_fraction == 1)
			return TRUE;
		if (trace_ent == targ)
			return TRUE;
		return FALSE;
	}

	traceline(inflictor.origin, targ.origin, TRUE, self);

	// 1998-10-04 Hit outside water by a discharge fix by Maddes  start
	// this fix only damages players in the water/slime.

	if (dtype == "discharge")
	{
		if (clanring_playmode & CLANRING_NO_SPOOGE)//Admin option set to safe DC for pmode.
		{
			if (targ.waterlevel < 1) //Not in the water.
				return FALSE;	     
			
			if (trace_inopen && trace_inwater)
				return FALSE;			// only entities in the SAME liquid are hit

			// it doesn't matter if water changes into slime as long as they are connected
			if (trace_fraction == 1)//cant hurt thru walls		
				return TRUE;
		}
	}
	// 1998-10-04 Hit outside water by a discharge fix by Maddes  end

	if (trace_fraction == 1)
		return TRUE;

	// 1998-09-16 CanDamage fix by Maddes/Kryten start
	local vector	dif;

	// testing middle of half-size bounding box
	dif_z = 0;

	// ...front right
	dif_y = targ.maxs_y * 0.5;
	dif_x = targ.maxs_x * 0.5;
	//	traceline(inflictor.origin, targ.origin + '15 15 0', TRUE, self);
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	// 1998-09-16 CanDamage fix by Maddes/Kryten end

	if (trace_fraction == 1)
	return TRUE;

	// 1998-09-16 CanDamage fix by Maddes/Kryten start
	// ...front left
	dif_x = targ.mins_x * 0.5;
	//	traceline(inflictor.origin, targ.origin + '-15 -15 0', TRUE, self);
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	// 1998-09-16 CanDamage fix by Maddes/Kryten end
	if (trace_fraction == 1)
	return TRUE;

	// 1998-09-16 CanDamage fix by Maddes/Kryten start
	// ...back left
	dif_y = targ.mins_y * 0.5;
	//	traceline(inflictor.origin, targ.origin + '-15 15 0', TRUE, self);
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	// 1998-09-16 CanDamage fix by Maddes/Kryten end
	if (trace_fraction == 1)
	return TRUE;

	// 1998-09-16 CanDamage fix by Maddes/Kryten start
	// ...back right
	dif_x = targ.maxs_x * 0.5;
	//	traceline(inflictor.origin, targ.origin + '15 -15 0', TRUE, self);
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	// 1998-09-16 CanDamage fix by Maddes/Kryten end
	if (trace_fraction == 1)
	return TRUE;

	// 1998-09-16 CanDamage fix by Maddes/Kryten start
	// testing top of half-sized bounding box
	dif_z = targ.maxs_z * 0.5;

	// ...front right
	dif_y = targ.maxs_y * 0.5;
	dif_x = targ.maxs_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
	return TRUE;

	// ...front left
	dif_x = targ.mins_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
	return TRUE;

	// ...back left
	dif_y = targ.mins_y * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
	return TRUE;

	// ...back right
	dif_x = targ.maxs_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
	return TRUE;

	// testing bottom of half-sized bounding box
	dif_z = targ.mins_z * 0.5;

	// ...front right
	dif_y = targ.maxs_y * 0.5;
	dif_x = targ.maxs_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
	return TRUE;

	// ...front left
	dif_x = targ.mins_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
	return TRUE;

	// ...back left
	dif_y = targ.mins_y * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
	return TRUE;

	// ...back right
	dif_x = targ.maxs_x * 0.5;
	traceline(inflictor.origin, targ.origin + dif, TRUE, self);
	if (trace_fraction == 1)
	return TRUE;
	// 1998-09-16 CanDamage fix by Maddes/Kryten end

	return FALSE;
};

void (entity t, entity e) CheckDefenseBonus =
{
	if ((e == world) || (t == world)) 
		return;

	entity what = findradius(t.origin, 300);
	while (what)
	{
		if (what.touch == weapon_touch)
		{
			if ((what.classname == "weapon_rocketlauncher")||(what.classname == "weapon_lightning"))
				e.stats_defense_weapon += 1;	
			what = world;
		}
		else
		{
			if (what.touch == powerup_touch)
			{
				if ((what.classname == "item_artifact_super_damage")||(what.classname == "item_artifact_invulnerability"))
					e.stats_defense_powerup += 1;
			}
			else
			{
				if (what.touch == armor_touch)
				{
					if ((what.classname == "item_armorInv")||(what.classname == "item_armor2"))
						e.stats_defense_armor += 1;	// TODO: play a sound?
				}
				else
				{
					if (what.touch == BackpackTouch)
					{
						if ((what.items == IT_LIGHTNING) || (what.items == IT_GRENADE_LAUNCHER) || (what.items == IT_ROCKET_LAUNCHER))
						{
							if (t.team != e.team)
							{
								if (what.nextthink - time < 118)	// if the backpack has been sitting here for more than 2 seconds.
								{
									e.stats_defense_backpack += 1;	// attacker gets 1 defense point for defending this backpack.
								}
							}					
						}
					}
				}
			}
		}
		what = what.chain;
	}		
};
/*
============
Killed
============
*/
void(entity targ, entity attacker) Killed =
{
	local entity oself;
	local float rtime, prand, as_sound = 0;

	oself = self;
	self = targ;

	if (self.health < -99)
		self.health = -99;		// don't let sbar look bad if a player

	if (self.movetype == MOVETYPE_PUSH || self.movetype == MOVETYPE_NONE)
	{	// doors, triggers, etc
		self.th_die ();
		self = oself;
		return;
	}

	if (teamplay)
	{ 	// Killed an opponent who was attacking a teammate. 																		 (== attacker.team so CA, with 3 teams, works also).
		if ((targ.enemy_hurt_time > time) && (targ.enemy_target.health) && (targ.enemy_target != attacker) && (targ.enemy_target.team == attacker.team))
		{
			//sound (self, CHAN_VOICE, "crx/defense.wav", 1, ATTN_NORM);
			attacker.stats_defense_teammate += 1;
			bprint(attacker.netname," defends their teammate ",targ.enemy_target.netname,".\n"); // Testing remove this afterwards...
		}
		else
		// Killing an opponent who just killed a teammate.
										 	 // targ.enemy_target.health has a 3 second window before the dead player automatically respawns...
		if ((targ.enemy_hurt_time > time) && ((targ.enemy_target.health < 1)) && (targ.enemy_target != attacker) && (targ.enemy_target.team == attacker.team))
		{
			//sound (self, CHAN_VOICE, "crx/avenger.wav", 1, ATTN_NORM);
			attacker.stats_avenge_teammate +=1;
			bprint(attacker.netname," avenged their teammate ",targ.enemy_target.netname,".\n"); // Commentary for observers only (oprint4)?
		}
	}

	self.enemy = attacker;
	
	if (self.enemy.classname == "player")
		targ.killed = TRUE;//R00k
	
	if (!(clanring_playmode & CLANRING_AIRSHOT_MODE))
	{
		ClientObituary (self, attacker);

		if (self.killstreak > 5)
		{
			bprint4(self.netname, "'s \bkilling spree\b ended at ", ftos(self.killstreak), "\n");

			//TODO: also check at match end
			// new_player_record = 0;
			// check_player_high_record2(self.killstreak, self.team, self.netname);
			// if (new_player_record > 0)
			// {
			// 	if (new_player_record == 1)
			// 	{
			// 		sound (self, CHAN_VOICE, "crx/hiscore.wav", 1, ATTN_NORM);
			// 	}
			// 	write_killstreak_stats();
			// }
		}
	}
	
	self.takedamage = DAMAGE_NO;
	
	self.touch = SUB_Null;
	
	self.th_die ();
	
	if ((clanring_playmode & CLANRING_DMM4_MODE) || (clanring_playmode & CLANRING_AIRSHOT_MODE))
	{
		if ((attacker != world) && (attacker.classname == "player") && (attacker.next_team != world))
		{
			if (targ != attacker)
			{
				if (clanring_playmode & CLANRING_AIRSHOT_MODE)
				{
					attacker.frags += 1;

					if (targ.airborn_pos > 650)
					{
						bprint("\b[\bDEEPˆ‰SPACE\b]\b\n");
						as_sound = 2;
					}
					else if (targ.airborn_pos > 500)
					{
						bprint("\b[\b…Moon…Shot…\b]\b\n");
						as_sound = 3;
					}
					else if (targ.airborn_pos > 300)
					{
						bprint("\b[\bMax Air Gib\b]\b\n");
						as_sound = 4;
					}
					else if (targ.airborn_pos > 200)
					{
						bprint("\b[\bBig Air Gib\b]\b\n");
						as_sound = 5;
					}
					else
					{
						bprint("[Mid Air Gib]\n");
					}

					new_player_record = 0;
					check_player_high_record2(targ.airborn_pos, attacker.team, attacker.netname);
					if (new_player_record > 0)
					{
						if (new_player_record == 1)
						{
							bprint(attacker.netname);
							bprint(" set the new \bhighest gib\b\n");
							as_sound = 6;
						}
						write_airshot_height_stats();
					}

					// only last 30 seconds if timelimit
					if ((!clanring_timelimit) || ((boss.lip < 1) && (boss.count <= 30)))
					{
						if (attacker.super_damage_finished >= time)
						{
							attacker.killstreak += 1;
							if ((attacker.killstreak % 2 == 0) || (as_sound == 0))
								as_sound = 1;
						}
						else
						{
							attacker.killstreak = 1;
						}

						attacker.super_time = 1;
						attacker.super_damage_finished = time + 3;
						attacker.items = attacker.items | IT_QUAD;
					}

					if (as_sound == 1)
					{
						prand = floor(random() * 5) + 1;
						if (prand == 1)
							sound (self, CHAN_VOICE, "crx/onemore.wav", 1, ATTN_NORM);
						else if (prand == 2)
							sound (self, CHAN_VOICE, "misc/power.wav", 1, ATTN_NORM);
						else if (prand == 3)
							sound (self, CHAN_VOICE, "crx/laugh6.wav", 1, ATTN_NORM);
						else if (prand == 4)
							sound (self, CHAN_VOICE, "crx/yeah.wav", 1, ATTN_NORM);
						else
							sound (self, CHAN_VOICE, "crx/onfire.wav", 1, ATTN_NORM);
					}
					else if (as_sound == 2)
						sound (self, CHAN_VOICE, "crx/space.wav", 1, ATTN_NORM);
					else if (as_sound == 3)
						sound (self, CHAN_VOICE, "crx/gasp.wav", 1, ATTN_NORM);
					else if (as_sound == 4)
					{
						prand = floor(random() * 3) + 1;
						if (prand == 1)
							sound (self, CHAN_VOICE, "crx/gasp2.wav", 1, ATTN_NORM);
						else if (prand == 2)
							sound (self, CHAN_VOICE, "crx/kaboom.wav", 1, ATTN_NORM);
						else
							sound (self, CHAN_VOICE, "crx/excell3.wav", 1, ATTN_NORM);
					}
					else if (as_sound == 5)
					{
						prand = floor(random() * 3) + 1;
						if (prand == 1)
							sound (self, CHAN_VOICE, "crx/superb.wav", 1, ATTN_NORM);
						else if (prand == 2)
							sound (self, CHAN_VOICE, "crx/excell2.wav", 1, ATTN_NORM);
						else
							sound (self, CHAN_VOICE, "ra/outstand.wav", 1, ATTN_NORM);
					}
					else if (as_sound == 6)
						sound (self, CHAN_VOICE, "crx/hiscore.wav", 1, ATTN_NORM);
				}
				else
				{
					//dmm4 fraglimit check
					if (((fraglimit) && (self.frags >= fraglimit)) || (boss.suddendeath == TRUE))
					{
						boss.busy = TRUE;
						gameover = TRUE;
						arena_show_timelimit();
						arena_match_end();
					}
				}
			}
			else
			{
				if (boss.suddendeath == TRUE)
				{
					boss.busy = TRUE;
					gameover = TRUE;
					arena_show_timelimit();
					arena_match_end();
				}
			}
			pqc_team_frags(attacker.next_team.team2, attacker.frags);
		}
		if (clanring_playmode & CLANRING_WIPEOUT_MODE)
		{
			if ((targ != world) && (targ.classname == "player") && (targ.next_team != world))
			{
				//TODO: too many messages? or show [rounddeaths] in obituary?
				if (targ.next_team.teamalive > 1)
				{
					rtime = wipeout_get_respawn(targ.rounddeaths);
					bprint4(targ.netname, " will respawn in ", ftos(rtime), " seconds\n");
				}
			}
		}
		else if (clanring_playmode & CLANRING_CA_MODE)
		{
			CheckForLastTwoPlayers();
		}
	}

	self = oself;
};


/*
============
T_Damage

The damage is coming from inflictor, but get mad at attacker
This should be the only function that ever reduces health.
============
*/
void(entity targ, entity inflictor, entity attacker, float damage) T_Damage =
{
	local	vector	dir;
	local 	entity 	oldself;
	local 	float 	save, overkill, take, teamdamage, old_damage = 0, longrange;
	local 	string 	temp;//R00k moved here (combat.qc:509: error: Type mismatch on redeclaration of temp. string, should be __variant)

	if (!targ.takedamage)
		return;
	
	if (clanring_state & CLANRING_MATCH_PAUSED) return;

	// Prewar: no PvP when either party is in leave-me-alone.
	// Exceptions: telefrags still kill; self-damage allowed.
	if (!match_in_progress())
	{
		if (targ.classname == "player" && attacker.classname == "player")
		{
			if (inflictor.classname != "teledeath")
			{
				if (targ != attacker && (targ.leavemealone || attacker.leavemealone))
					return;
			}
		}
	}

	if (mode_is_arena())
	{
		if ((inflictor.classname == "teledeath") && (boss.timetofight == FALSE)) //This is here for pre-game spawn's tdeath_touch to push the player out of the way...
		{
			if (targ.classname == "player")
			{
				makevectors(targ.v_angle);
				targ.velocity = (targ.velocity + ((v_forward * 320) * 8));
				inflictor.owner.velocity = (inflictor.owner.velocity - ((v_forward * 320 ) * 8));
			}
			return;
		}

		if (boss.timetofight == FALSE)
		{
			return;
		}
	}

	if ((targ.plag)&&(attacker.classname=="player"))
	{
		centerprint(attacker,"\bClanring\b Lag Protection \bActivated");
		return;
	}
	
	// ELOHIM_MOD - stats
	if (attacker.classname == "player")
	{
		if ((targ != attacker) && (targ.classname == "player"))
		{
			attacker.clanring_inflicted = targ;  // CRMOD - to see who attacker attacked
			attacker.clanring_did_damage = time;  // CRMOD keep track of last time they hurt someone
						
			if (targ.classname != "player" || attacker.team != targ.team || !teamplay)
			{
				if (inflictor == attacker)
				{
					if (attacker.weapon == IT_SHOTGUN || attacker.weapon == IT_SUPER_SHOTGUN)
					{
						if (targ.classname != "button")					//R00k: dont count button damage in stats.
							attacker.dest2_x = attacker.dest2_x + damage;
					}
					else
					{
						if (attacker.weapon == IT_LIGHTNING)
						{
							if ((attacker.waterlevel <= 1)	// don't count discharges
								&& (targ.classname != "button"))					//R00k: dont count button damage in stats.
								attacker.dest2_z = attacker.dest2_z + damage;
							else
							if ((targ.deathtype == "discharge")&&(targ.team != attacker.team))
								attacker.stats_discharge_kills += 1; // Discharge stats of killed opponents; teammates are recorded in Badstats.
						}
					}
				}
				else
				{
					if (inflictor.classname == "missile" && targ.classname == "player")
					{
						attacker.dest_y = attacker.dest_y + damage;
						inflictor.dmg = TRUE; // flag missile as having done damage
					}
					else
					{
						if (inflictor.classname == "spike")
							attacker.dest2_y = attacker.dest2_y + damage;
						else
						{
							if (inflictor.classname == "grenade")
								attacker.stats_gl_frac = attacker.stats_gl_frac + damage;
						}	
					}
				}
			}
			else
			{
				if (attacker.team == targ.team && teamplay)
				{
					if (inflictor == attacker)
					{
						if (attacker.weapon == IT_SHOTGUN || attacker.weapon == IT_SUPER_SHOTGUN)
						{
							attacker.clanring_badstats_z = attacker.clanring_badstats_z + damage;
						}
						else
						{
							if (attacker.weapon == IT_LIGHTNING)
							{
								if (attacker.waterlevel <= 1)
									attacker.clanring_badstats_z = attacker.clanring_badstats_z + damage;
							}
						}
					}
					else
					{
						if (inflictor.classname == "missile")
						{
							attacker.clanring_badstats_z = attacker.clanring_badstats_z + damage;
							inflictor.dmg = TRUE; // flag missile as having done damage
						}
						else
						{
							if (inflictor.classname == "spike")
								attacker.clanring_badstats_z = attacker.clanring_badstats_z + damage;
						}
					}
				}
			}
		}
		else
		{
			// store damage in the rocket until we know it's not a RJ
			if (inflictor.classname == "missile")
				inflictor.clanring_badstats_y = inflictor.clanring_badstats_y + damage;
		}
	}
	// END_CRMOD  

	// used by buttons and triggers to set activator for target firing
	damage_attacker = attacker;
	
	if ((attacker.classname == "player") && (targ.classname == "player"))
	{
		attacker.enemy_hurt_time = time + 10;	//R00k: Used for stats; this is the bonus-window from last time they hurt/killed your teammate. bonus for killing them within this time. 
		attacker.enemy_target = targ;			//Keep track of who is being hurt
		targ.enemy = attacker;					//R00k: Used for cameras/stats
	}
	
	teamdamage = TRUE;
	
	if ((teamplay == 1) && (targ.team == attacker.team))
	{
		if (targ != attacker)
		{
			if (attacker.classname == "player")
			{
				if (inflictor.classname != "door") 	// because squishing a teammate is still possible
				{
					teamdamage = FALSE;
/*
//Optional: Always damage teammates if discharging. Suggestion by Omicron.
					if (attacker.weapon == IT_LIGHTNING)
					{
							if ((attacker.waterlevel > 1)&&(targ.waterlevel > 1))
							teamdamage = TRUE;
					}
*/
				}
			}
		}
		
		if ((clanring_playmode & CLANRING_CA_MODE) && (targ.team > 0)&&(targ.team == attacker.team))
		{
			teamdamage = FALSE;
		}
	}
	
	if (attacker.player_flag & ITEM_RUNE2_FLAG)
	{
		damage = (damage * 2);
	}

	//Placing Resistance Checking here protects Health and Armor
	if (targ.player_flag & ITEM_RUNE1_FLAG)
	{
		damage = (damage / 2);
		ResistanceSound (targ);
	}

	if ((attacker.super_damage_finished > time) && (inflictor.classname != "door"))	//R00k - doors no quad power fix
	{
		damage = (damage * 4);
		if ((((attacker.classname == "player") && (targ != attacker)) && (inflictor.classname != "grenade")))
		{
			if ((((targ.classname != "player") || (attacker.team != targ.team)) || !teamplay))
			{
				attacker.clanring_qdwep_x = (attacker.clanring_qdwep_x + damage);
			}
		}
	}
	//pent stats
	if ((attacker.invincible_finished > time) && (inflictor.classname != "door"))
	{
		if ((((attacker.classname == "player") && (targ != attacker)) && (inflictor.classname != "grenade")))
		{
			if ((((targ.classname != "player") || (attacker.team != targ.team)) || !teamplay))
			{
				attacker.clanring_ptwep_x = (attacker.clanring_ptwep_x + damage);
			}
		}
	}

	save = 0;

	if (clanring_playmode & CLANRING_AIRSHOT_MODE)
	{
		//BAM: Airshot Mod --R00k rewrote 5/31/2017 12:23AM
		targ.airborn_pos = 0;
		if (targ.waterlevel < 2)
		{		
			old_damage = damage;							// save back the original damage

			damage = airshot_damage_z (targ, old_damage); 	// Modify damage to the target based on the distance they are from the ground; save the height in airborn_pos.

			if (old_damage < 100) 							// Ignore splash damage caused by missing the target and hitting walls.
				damage = 0;

			if (targ.airborn_pos < 45)						// This was 'if (targ.flags & FL_ONGROUND)'; take minimal damage when jumping over rockets, but still kick them up.
			{
				if (targ.classname == "practice_object")
					targ.flags = targ.flags - (targ.flags & FL_ONGROUND);

				dir = targ.origin - ((inflictor.absmin + inflictor.absmax) * 0.5);
				dir = normalize (dir);
				
				targ.velocity = (targ.velocity + ((dir * old_damage) * 10));

				if ((targ != attacker && attacker.classname == "player") && (inflictor.classname == "grenade" || inflictor.classname == "missile"))
				{	
					targ.velocity_z = (targ.velocity_z + (dir_z * old_damage * 6));
				}
				return;
			}
		}
	}
	else if ((damage > 99) && ((inflictor.classname == "missile") || (inflictor.classname == "grenade")))
	{
		if (inflictor.classname == "missile")
		{
			float d = vlen((inflictor.origin - ((targ.absmax + targ.absmin) * 0.5))); // R00k: Shot hits near middle of target
			if (d < 33)
				attacker.direct_hit = attacker.direct_hit + 1;
		}
		else
			attacker.direct_hit = attacker.direct_hit + 1;
	}

	if ((teamdamage)&&(!(match_prewar())))
	{
		if ((targ.deathtype != "drowning") || (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG)))
		{			
			// save damage based on the target's armor level
			save = ceil(targ.armortype * damage);
			if (save >= targ.armorvalue)
			{
				save = targ.armorvalue;// no negative armor values please!
				targ.armortype = 0;
				targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
			}
			targ.armorvalue = targ.armorvalue - save;
		}
	}

	take = ceil(damage - save);
	
	/*Placing Resistance Checking here protects only Health, not Armor.
	if (targ.player_flag & ITEM_RUNE1_FLAG)
	{
		take = (take / 2);
		ResistanceSound (targ);
	}
	*/

	if (take >= targ.health)//R00k: Overkill is used to cap the damage given/taken stats so we dont get overloaded quad damage, discharging, or telefrag values
	{
		overkill=(ceil(targ.health));
	}
	else
	{
		overkill=(ceil(take));
	}

// add to the damage total for clients, which will be sent as a single
// message at the end of the frame
// FIXME: remove after combining shotgun blasts?
	if (targ.flags & FL_CLIENT)
	{
		targ.dmg_take = targ.dmg_take + take;
		targ.dmg_save = targ.dmg_save + save;
		targ.dmg_inflictor = inflictor;
	}

// figure momentum add
	if (((inflictor != world) && (targ.movetype == MOVETYPE_WALK) && (targ.deathtype !="hook")))
	{
		dir = targ.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
		dir = normalize(dir);

		if (targ.player_flag & ITEM_RUNE1_FLAG)
			targ.velocity = targ.velocity + dir * (damage * 2) * 8; //R00k: retain the original kickback
		else
			targ.velocity = targ.velocity + dir * damage * 8;

		if (clanring_playmode & CLANRING_AIRSHOT_MODE)
			targ.velocity_z = (targ.velocity_z + (dir_z * old_damage * 8));
	}

	//no self or team damage in CA
	if ((clanring_playmode & CLANRING_CA_MODE) && (targ.team > 0)&&(targ.team == attacker.team))
	{
        return;
	}

	// *XXX* EXPERT CTF mark players who hurt the flag carrier, so they are worth more points for a while.
	if ((attacker.classname == "player") && (targ.flag_carrier) && (attacker.team != targ.team))
	{
		attacker.last_hurt_carrier = time;
	}

	// ELOHIM_MOD - print info for practice mode; check for pre-match
	if ((clanring_playmode & CLANRING_PRACTICE_MODE) || (clanring_playmode & CLANRING_CA_MODE))
	{
		if (targ.classname == "player" && attacker.classname == "player" && targ != attacker)
		{
			temp = ftos(floor(damage));//R00k: round down
			centerprint4 (attacker, targ.netname, ": ", temp, "\n\n\n\n\n\n\n\n");
		}
	}

	//calculate prewar frags
	if (match_prewar() && attacker.classname == "player" && targ != attacker)
	{
		attacker.dmg_tally += damage;
		if (attacker.dmg_tally >= 300)
		{
			attacker.frags += 1;
			attacker.dmg_tally = attacker.dmg_tally % 300;
		}
	}

	if (clanring_playmode & CLANRING_MATCH_MODE)
	{
		if (!(clanring_state & CLANRING_MATCH_STARTED))
			return;
	}
	// END_MOD

// check for godmode or invincibility
	if ((clanring_playmode & CLANRING_AIRSHOT_MODE) && (attacker.super_damage_finished > time))
	{
		//quad ignores pent protection in airshot, but still play sound
		sound (targ, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM);
	}
	else
	{
		if (targ.invincible_finished >= time)
		{
			if (self.invincible_sound < time)
			{
				sound (targ, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM);
				self.invincible_sound = time + 2;
			}
			return;
		}
	}

// team play damage avoidance
    // ELOHIM_MOD - nested the ifs
	if ((teamplay == 1) && (targ.team > 0) && (targ.team == attacker.team))
	{
		if (targ != attacker)
		{
			if (attacker.classname == "player")
			{
				if (inflictor.classname != "door") 	// because squishing a teammate is still possible
				{
				//	if (!(attacker.weapon == IT_LIGHTNING && targ.waterlevel))//Always damage teammates if discharging.
					{
						return;
					}
				}
			}
		}
	}

	//R00k -stats-
	if ( ((targ.classname == "player") && (attacker.classname == "player")) && (targ != attacker) && ((!teamplay) || (targ.team != attacker.team)) )
	{
		targ.dmg_taken = targ.dmg_taken + save + overkill;
		attacker.dmg_given = attacker.dmg_given + save + overkill;
		if ((targ.items & IT_ROCKET_LAUNCHER) || (targ.items & IT_LIGHTNING))
		{
			attacker.ewep = attacker.ewep + save + overkill;
		}

		if (clanring_playmode & CLANRING_CA_MODE)
		{
			attacker.dmg_given_round = (attacker.dmg_given_round + (save + overkill));
			attacker.dmg_cache = (attacker.dmg_cache + (save + overkill));
			
			while (attacker.dmg_cache >= (boss.health + boss.armorvalue))
			{
				attacker.frags += 1; //give player point for max damage+cache
				attacker.dmg_cache = (attacker.dmg_cache - (boss.health + boss.armorvalue));//leftover damage carries over
			}
		}
	}

	if (clanring_playmode & CLANRING_AIRSHOT_MODE)
		take = damage;
	
	// do the damage
	targ.health = targ.health - take;

	if (targ.health <= 0)
	{
		if (clanring_gameconfig & CLANRING_DROP_DEATH_SHARDS)
		{
			if ((targ.armorvalue)&&(!(clanring_playmode & CLANRING_MATCH_MODE)))
				DropShard(targ.origin, targ.armorvalue);
		}
		// ELOHIM_MOD - print info for practice mode
		if (clanring_playmode & CLANRING_PRACTICE_MODE)
		{
			if (targ.classname == "player" && attacker.classname == "player" && targ != attacker)
			{
//				local string temp;
				temp = ftos(attacker.health);
				centerprint5(targ, "\n\n\n\n", attacker.netname, " has ", temp, " health");
				sprint5(targ, "\n\n\n\n", attacker.netname, " has ", temp, " health\n");
			}
		}
		// END_MOD

		if (teamplay)
			CheckDefenseBonus(targ, attacker); 

		Killed (targ, attacker);

		if (!(clanring_playmode & CLANRING_AIRSHOT_MODE))
		{
			if ((targ.classname == "player") && (inflictor != world) && (inflictor.classname == "missile"))
			{
				if (teamplay && targ.team == attacker.team)
					return;

				longrange = vlen(targ.origin - inflictor.dest1);
				if (longrange >= 800)
				{
					bprint3("\bKill Distance:\b ", ftos(rint(longrange)), "\n");

					// new_player_record = 0;
					// check_player_high_record2(longrange, attacker.team, attacker.netname);
					// if (new_player_record > 0)
					// {
					// 	if (new_player_record == 1)
					// 	{
					// 		sound (self, CHAN_VOICE, "crx/hiscore.wav", 1, ATTN_NORM);
					// 	}
					// 	write_longrange_stats();
					// }
				}
			}
		}

		return;
	}
// react to the damage
	oldself = self;
	self = targ;
	if (self.th_pain)
	{
		self.th_pain();
	}
	self = oldself;
};


/*
============
T_RadiusDamage
============
*/
void(entity inflictor, entity attacker, float damage, entity ignore, string dtype) T_RadiusDamage =
{
	local 	float 	points, dist, radius;
	local 	entity 	head;
	local 	vector 	org;
	local	float	attacker_damaged = FALSE;
	local	float	attacker_points = FALSE;
	local	float	enemy_damaged = FALSE;

	radius = damage + 40;
	
	head = findradius (inflictor.origin, radius);

	while (head)
	{
		if (head != ignore)
		{
			if (head.takedamage)
			{
				// ELOHIM_MOD - this has been optimized
				org = head.origin + (head.mins + head.maxs) * 0.5; //middle of the model				
				dist = vlen(inflictor.origin - org);
				points = 0.5 * dist;

				if (points < 0)
				{
					points = 0;
				}

				points = damage - points;

				if (points > 0)
				{
					if (CanDamage (head, inflictor, dtype))	// 1998-10-04 Hit outside water by a discharge fix by Maddes
					{
						if (head.health)
							head.deathtype = dtype;	// Wrong obituary messages fix

						if ((head.items & IT_SUIT) && (clanring_playmode & CLANRING_NO_SPOOGE) && (dtype == "discharge"))
							points = points * 0.20;//R00k if biosuit can protect the player by 1/5th against lava why not DC too??

						if (head != attacker)
						{
							if (head.classname == "player")
								enemy_damaged = TRUE;
							T_Damage (head, inflictor, attacker, points);
						}
						else
						{
							attacker_damaged = TRUE;
							attacker_points = points * 0.5;
						}
					}
				}
			}
		}
		head = head.chain;
	}
	
	if (attacker_damaged)
	{
		if (clanring_playmode & CLANRING_CA_MODE)
		{
			//R00k(1.95): reduced rl/gl efficiency stats for rocketjumps
			if ((inflictor.classname == "missile") && (inflictor.owner == attacker))
			{				
				if (!enemy_damaged)//only if the damage didnt effect anyone else...
				{
					if (attacker.dest_x >= 120)
						attacker.dest_x = attacker.dest_x - 120;//R00k(8/30/2011 2:14PM)payback the damage incurred when shooting (not 100%)
				}
								
			}				
			else
			{
				if ((inflictor.classname == "grenade") && (inflictor.owner == attacker))
				{
					if (!enemy_damaged)
					{
						if (attacker.stats_gl_tot >= 120)
						attacker.stats_gl_tot = attacker.stats_gl_tot - 120; // payback the damage incurred when shooting...
					}
				}				
			}
		}
		T_Damage (attacker, inflictor, attacker, attacker_points);
	}
};
