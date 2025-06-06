void () airshot_init_world =
{
	boss = spawn ();
    boss.max_rounds 	= 1;
    boss.max_players 	= 1;
    boss.start_players	= 2;
    boss.max_teams      = 2;
	boss.round			= 1;
	boss.count 			= 10;
	boss.state 			= CA_MATCH_WAITING;
	boss.wait 			= 0;
	boss.maprecycle		= 0;
	boss.armorvalue  	= 200;
	boss.armortype   	= 80.001;
    boss.health      	= 100;
    boss.ammo_shells 	= 0;
    boss.ammo_nails  	= 0;
    boss.ammo_rockets	= 100;
    boss.ammo_cells     = 0;
    boss.items          = IT_AXE | IT_ROCKET_LAUNCHER | IT_ARMOR3 | IT_GRENADE_LAUNCHER;
    boss.weapon 		= IT_ROCKET_LAUNCHER;
	boss.timetofight 	= FALSE;
	boss.next_team 		= world;
	boss.busy			= FALSE;
	boss.aborted 		= FALSE;
	boss.suddendeath 	= FALSE;
	ca_mvp_entity		= world;
	default_timelimit    = cvar("timelimit");
};

float (entity targ, float damage) airshot_damage_z =
{
	local float		dist;
	local vector 	start, end;
		
	start 	= targ.origin;
	end 	= start;
	end_z 	= targ.origin_z - 2048;
	
	traceline (start, end, TRUE, targ);		
	
	dist = rint(targ.absmin_z - trace_endpos_z);

	if (dist < 1)
		dist = 0;
		
    targ.airborn_pos = dist;            

	if (dist > 45) //player jump height is 45
    {
		if (damage < 100)
		{
			bprint("\x90splash dmg\x91\n");
		}
		else
		{
			if (dist > 128)
			{
				damage = rint((damage + ((dist/128)*damage)));
			}
			else
			{
				damage = rint((damage + ((dist/256)*damage)));
			}
			bprint3(sprintf("\x90height: %g\x91\n\x90\bdamage\b: %g\x91\n",dist,damage));
		}
		return damage;
    }
	return 0;
};

vector (entity e) airshot_droptofloor =
{
	local vector start, end;
		
	start 	= e.origin;
	end 	= e.origin;
	end_z 	= e.origin_z - 2048;
	
	traceline (start, end, TRUE, world);	
	
	if (trace_fraction != 1)
	{
		return trace_endpos + '0 0 45';
	}

	return start;
}

void () AirshotHighScores =
{
	local string s1="",s2="",s3="",s4="",ts1="",ts2="",ts3="";

	if (boss.state == CA_MATCH_PLAYING)
	{
		self.leaderboardtime = 0;
	}
	else
	{	//TODO: update for higher PLAYER_RECORDS_MAX_COUNT?
		if (playerrecord[0].statvalue > 0)
		{
			s1 = sprintf("    \1   %-2s %-16s\n\n", ftos(playerrecord[0].statvalue), playerrecord[0].player);
			if (playerrecord[1].statvalue > 0)
			{
				s2 = sprintf("    \2   %-2s %-16s\n\n", ftos(playerrecord[1].statvalue), playerrecord[1].player);
				if (playerrecord[2].statvalue > 0)
				{
					s3 = sprintf("    \3   %-2s %-16s\n\n", ftos(playerrecord[2].statvalue), playerrecord[2].player);
				}
			}
		}
		else
		{
			s1 = "No streaks set";
		}
		if (playerrecord2[0].statvalue > 0)
		{
			ts1 = sprintf("    \1  %-3s %-16s\n\n", ftos(rint(playerrecord2[0].statvalue)), playerrecord2[0].player);
			if (playerrecord2[1].statvalue > 0)
			{
				ts2 = sprintf("    \2  %-3s %-16s\n\n", ftos(rint(playerrecord2[1].statvalue)), playerrecord2[1].player);
				if (playerrecord2[2].statvalue > 0)
				{
					ts3 = sprintf("    \3  %-3s %-16s\n\n", ftos(rint(playerrecord2[2].statvalue)), playerrecord2[2].player);
				}
			}
			s4 = sprintf("%s%s%s",ts1,ts2,ts3);
		}
		else
		{
			s4 = "No height records set";
		}
		centerprint(self, "\bAir Gib Streak Leaders\b:\n\n", s1, s2, s3, "\bHighest Air Gibs\b:\n\n", s4);
		return;
	}
};