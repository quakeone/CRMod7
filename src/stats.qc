//
// Stats.qc
//
// Various routines for displaying statistics.
//
// All code by J.P. Grossman unless otherwise commented.
//

//
//  P R O T O T Y P E S
//
void(float frac, float tot) stats_print_percent3;

//
//  R E S E T  P L A Y E R
//
void() stats_reset_player =
{
	self.mangle = self.dest = self.dest2 = self.dest1 = self.clanring_badstats = self.clanring_badstats2 = '0 0 0';
	self.clanring_qdkill = self.clanring_qdwep = self.clanring_ptkill = self.clanring_ptwep = '0 0 0';
	self.stats_gl_frac = 0;
	self.stats_gl_tot = 0;
	self.dmg_taken = 0;
	self.dmg_given = 0;
	self.dmg_given_round = 0;
	self.ewep = 0;
	self.dmg_cache = 0;
	self.dmg_tally = 0;
	self.clanring_did_damage = 0; // CRMOD moved here from put_client_in_server
	self.fpickups = 0;
	self.fcaptures = 0;
	self.fdefenses = 0;
	self.freturns = 0;
	self.fcassists = 0;
	self.fcfrags = 0;
	self.fctime = 0;
	self.captime = 1200;//default time = matchtime;
	self.true_kills = 0;
	self.direct_hit = 0;
	self.killed = FALSE;
	self.stats_item_ssg = 0;
	self.stats_item_ng = 0;
	self.stats_item_sng = 0;
	self.stats_item_gl = 0;
	self.stats_item_rl = 0;
	self.stats_item_lg = 0;
	self.stats_item_shells = 0;
	self.stats_item_nails = 0;
	self.stats_item_rockets = 0;
	self.stats_item_cells = 0;
	self.stats_item_health = 0;
	self.stats_item_mega = 0;
	self.stats_item_biosuit = 0;
	self.stats_item_ring = 0;
	self.stats_item_redarmor = 0;
	self.stats_item_yellowarmor = 0;
	self.stats_item_greenarmor = 0;
	self.stats_item_backpacks = 0;
	self.stats_item_runes = 0;
	self.stats_defense_teammate = 0;
	self.stats_defense_backpack = 0;
	self.stats_defense_dropped_flag = 0;
	self.stats_defense_powerup = 0;
	self.stats_defense_weapon = 0;
	self.stats_defense_armor = 0;
	self.stats_discharge_kills = 0;
	self.stats_avenge_teammate = 0;
	self.stats_defense_powerup = 0;
	self.stats_defense_weapon = 0;
	self.stats_defense_armor = 0;
	self.stats_discharge_kills = 0;
	self.stats_avenge_teammate = 0;
	self.stats_teamkill_quad = 0;
	self.stats_powerup_denial_quad = 0;
	self.strategic_returns = 0;
	self.fcarries_time = 0;
	self.flag_carry_start = 0;
	self.last_carry_pos = '0 0 0';
	self.last_pos_check = 0;
	self.q1_per = 0;
};

//
//  R E S E T  T E A M
//
void (entity pteam) stats_reset_team = 
{
	pteam.dest = pteam.dest1 = pteam.dest2 = pteam.pos1 = pteam.mangle = '0 0 0';
};

//
//  S H O W  B A D S T A T S
//
void() stats_show_badstats =
{
	local entity player;
	local float tot_enemy, tot_done;

	sprint(self, "\n");
	sprint(self, "\bbad stuff\n");
	sprint(self, "\n");

	sprint(self, " paks ü self ü team ü lava ü axe  ü fall ü      name\n");
	sprint(self, "­­­­­­«­­­­­­«­­­­­­«­­­­­­«­­­­­­«­­­­­­«­­­­­­­­­­­­­­­­\n");
	player = clanring_sentinel.next_player;
	while (player)
	{
		tot_enemy = player.dest2_x + player.dest2_y + player.dest2_z + player.dest_y;
		tot_done = tot_enemy + player.clanring_badstats_y + player.clanring_badstats_z;
		if (player == self)
		{
			sprint(self, " \x90");
			utils_print_int3(player.clanring_badstats_x);
			sprint(self, "‘ü \x90");
			stats_print_percent3(player.clanring_badstats_y, tot_done);
			sprint(self, "‘ü \x90");
			stats_print_percent3(player.clanring_badstats_z, tot_done);
			sprint(self, "‘ü \x90");
			utils_print_int3(player.clanring_badstats2_x);
			sprint(self, "‘ü \x90");
			utils_print_int3(player.clanring_badstats2_y);
			sprint(self, "‘ü \x90");
			utils_print_int3(player.clanring_badstats2_z);
			sprint(self, "‘ü ");
		}
		else
		{
			sprint(self, "  ");
			utils_print_int3(player.clanring_badstats_x);
			sprint(self, " ü  ");
			stats_print_percent3(player.clanring_badstats_y, tot_done);
			sprint(self, " ü  ");
			stats_print_percent3(player.clanring_badstats_z, tot_done);
			sprint(self, " ü  ");
			utils_print_int3(player.clanring_badstats2_x);
			sprint(self, " ü  ");
			utils_print_int3(player.clanring_badstats2_y);
			sprint(self, " ü  ");
			utils_print_int3(player.clanring_badstats2_z);
			sprint(self, " ü ");
		}
		sprint2(self, player.netname, "\n");
		player = player.next_player;
	}
	sprint(self, "\n");
};

//
//  S H O W  Q U A D S T A T S
//

void() stats_show_quadstats =
{
    local entity player, pteam;
	local float useteams;
	//local string teamname;

    if (teamplay && ((clanring_state & (CLANRING_MATCH_STARTED | CLANRING_MATCH_OVER)) || clanring_sentinel.owner != clanring_sentinel))
		useteams = TRUE;
	else
		useteams = FALSE;

	sprint(self, "\n");
	sprint(self, "\bquad damage\b\n");
	sprint(self, "\n");
	sprint(self,   "quadsütimeüeffüoppüslfütm ü     name\n");
	sprint(self, "\b-----+----+---+---+---+---+---------------­­­­\n");
	player = clanring_sentinel.next_player;
	pteam = player.next_team;
	while (player)
	{
		if (player == self)
		{
			sprint(self, "\x90");
			utils_print_int3(player.clanring_qdwep_z);
			sprint(self, "‘ü ");
		}
		else
		{
			sprint(self, " ");
			utils_print_int3(player.clanring_qdwep_z);
			sprint(self, " ü ");
		}
		utils_print_int3(player.totalquad);
		sprint(self, "ü");
		stats_print_percent3(player.clanring_qdwep_x, player.clanring_qdwep_y);
		sprint(self, "ü");
		utils_print_int3(player.clanring_qdkill_x);
		sprint(self, "ü");
		utils_print_int3(player.clanring_qdkill_z);
		sprint(self, "ü");
		utils_print_int3(player.clanring_qdkill_y);
		sprint3(self, "ü", player.netname, "\n");
		player = player.next_player;
		if (useteams && (player.next_team != pteam))
		{
			sprint(self, " ");
			utils_print_int3_gold(pteam.dest2_x);
			sprint3(self, " ü    ü   ü   ü   ü   ü", pteam.mdl, "\n");
			pteam = player.next_team;
		}
	}
	sprint(self, "\n");
};

//
//  S H O W  P E N T S T A T S
//

void() stats_show_pentstats =
{
    local entity player, pteam;
	local float useteams;

	if (teamplay && ((clanring_state & (CLANRING_MATCH_STARTED | CLANRING_MATCH_OVER)) || clanring_sentinel.owner != clanring_sentinel))
		useteams = TRUE;
	else
		useteams = FALSE;

	sprint(self, "\n");
	sprint(self, "\bpent protection\b\n");
	sprint(self, "\n");
	sprint(self, "pentsüeffüoppütm ü     name\n");
	sprint(self, "­­­­­«­­­«­­­«­­­«­­­­­­­­­­­­­­­\n");
	player = clanring_sentinel.next_player;
	pteam = player.next_team;
	while (player)
	{
		if (player == self)
		{
			sprint(self, "\x90");
			utils_print_int3(player.clanring_ptwep_z);
			sprint(self, "‘ü");
		}
		else
		{
			sprint(self, " ");
			utils_print_int3(player.clanring_ptwep_z);
			sprint(self, " ü");
		}
		stats_print_percent3(player.clanring_ptwep_x, player.clanring_ptwep_y);
		sprint(self, "ü");
		utils_print_int3(player.clanring_ptkill_x);
		sprint(self, "ü");
		utils_print_int3(player.clanring_ptkill_y);
		sprint3(self, "ü", player.netname, "\n");
		player = player.next_player;
		if (useteams && (player.next_team != pteam))
		{
			sprint(self, " ");
			utils_print_int3_gold(pteam.dest2_y);
			sprint3(self, " ü   ü   ü   ü", pteam.mdl, "\n");
			pteam = player.next_team;
		}
	}
	sprint(self, "\n");
};

void() stats_show_killstats =
{
	local entity player;
	local float c;

	c = 16;//Workaround for lag-out players corrupting the link list...

	sprint(self, "\n");
	sprint(self, "\bkills\b\n");
	sprint(self, "\n");
	sprint(self, "fragsüoppüavngüslfütm ükldü dcü dtk ü dgv ü ewp ü     name\n");
	sprint(self, "\b-----+---+----+---+---+---+---+-----+-----+-----+---------------\n");
	
	player = clanring_sentinel.next_player;

	while (player != world)
	{
		if (c < 1)
		break;
		if (player == self)
		{
			sprint(self, "\x90");
			utils_print_int3(player.frags);
			sprint(self, "‘ü");
		}
		else
		{
			sprint(self, " ");
			utils_print_int3(player.frags);
			sprint(self, " ü");
		}
		utils_print_int3(player.true_kills);
		sprint(self, "ü");
		sprint(self, sprintf("%4g",player.stats_avenge_teammate));
		sprint(self, "ü");
		utils_print_int3(player.mangle_x);
		sprint(self, "ü");
		utils_print_int3(player.mangle_y);//FIXME: teamkills doesnt account for discharging (ctf)
		sprint(self, "ü");
		utils_print_int3(player.mangle_z);//FIXME: killed doesnt account for discharging (ctf)
		sprint(self, "ü");
		utils_print_int3(player.stats_discharge_kills);
		sprint(self, "ü");
		utils_print_damage_gold(player.dmg_taken);
		sprint(self, "ü");
		utils_print_damage_gold(player.dmg_given);
		sprint(self, "ü");
		utils_print_damage_gold(player.ewep);
		sprint3(self, "ü", player.netname, "\n");
		player = player.next_player;
		c -= 1;
	}
	sprint(self, "\n");
};

void (float f) stats_bprint_int3 =
{
	local float n;
	local string s = "";

	n = rint(f);
	if (n < -99)
		n = -99;
	s = ftos(n);
	s = strpad(-3, s);
	bprint(s);
};

//
//  B P R I N T  P E R C E N T 3
//
//  Helper function for stats_show_efficiency.  Prints the percentage
//  100 * (frac / tot) as a 3 character integer, or N/A if tot = 0.
//
void (float frac, float tot) stats_bprint_percent3 =
{
	if (frac > tot)	//R00k
	{
		bprint ("100");
	}
	else
	{
		if (tot)
		{
			local float n;
			local string temp = "";

			n = floor(100 * frac / tot);
			if (n < 10)
				bprint(" ");
			temp = ftos(n);
			bprint(temp);
			if (n < 100)
				bprint("%");
		}
		else
			bprint("N/A");
	}
};

//
//  P R I N T  P E R C E N T 3
//
//  Helper function for stats_show_efficiency.  Prints the percentage
//  100 * (frac / tot) as a 3 character integer, or N/A if tot = 0.
//
void (float frac, float tot) stats_print_percent3 =
{
	if (frac > tot)	//R00k
	{
		sprint (self, "100");
	}
	else
	{
		if (tot)
		{
			local float n;
			local string temp = "";

			n = floor(100 * frac / tot);
			if (n < 10)
				sprint(self, " ");
			temp = ftos(n);
			sprint(self, temp);
			if (n < 100)
				sprint(self, "%");
		}
		else
			sprint(self, "N/A");
	}
};

//
//  S H O W  E F F I C I E N C Y
//
//  Show the weapon efficiency for each player.
//
void () stats_show_efficiency =
{
    local entity player;
    local float tot_fired, tot_done;
    local float fpm;

    sprint(self, "\n");
    sprint(self, "bulünlsüroxülg ütotalüfpm ü     name\n");
    sprint(self, "­­­«­­­«­­­«­­­«­­­­­«­­­­«­­­­­­­­­­­­­­­\n");
    player = find(world,classname, "player");
    while (player)
    {
        if (((mode_is_arena()) && (player.next_team != world)) ||
            (!(mode_is_arena()) && !(player.style & CLANRING_OBSERVER)))
        {
            stats_print_percent3(player.dest2_x, player.dest1_x);
            sprint(self, "ü");
            stats_print_percent3(player.dest2_y, player.dest1_y);
            sprint(self, "ü");
            stats_print_percent3(player.dest_y, player.dest_x);
            sprint(self, "ü");
            stats_print_percent3(player.dest2_z, player.dest1_z);
            sprint(self, "ü");
            tot_fired = player.dest1_x + player.dest1_y + player.dest1_z + player.dest_x;
            tot_done = player.dest2_x + player.dest2_y + player.dest2_z + player.dest_y;
            
			// Calculate KPM (kills per minute)
			if (player.join_time > 0)
				fpm = player.true_kills * 60 / (clanring_sentinel.matchTime - player.join_time);
			else
				fpm = 0;

			if (player == self)
			{
				sprint(self, " ");
				stats_print_percent3(tot_done, tot_fired);
				sprint(self, " ü");
				if (fpm < 10)
					sprint(self, " ");
				sprint(self, sprintf("%.1f", fpm));
				sprint(self, "ü");
			}
			else
			{
				sprint(self, " ");
				stats_print_percent3(tot_done, tot_fired);
				sprint(self, " ü");
				if (fpm < 10)
					sprint(self, " ");
				sprint(self, sprintf("%.1f", fpm));
				sprint(self, "ü");
			}
            sprint2(self, player.netname, "\n");
        }
        player = find(player,classname, "player");
    }
    sprint(self, "\n");
};

//
//  S H O W  F L A G   S T A T S 
//
//  Show various flag statistics for each player.
//
void() stats_show_fstats =
{
	local entity player;
	local entity pteam;
	local float useteams;
	local string mtr = "";	//match-time record
	local string ttr = "";	//time-trial record	

	if (clanring_state & (CLANRING_MATCH_STARTED | CLANRING_MATCH_OVER) && teamplay)
		useteams = TRUE;
	else
		useteams = FALSE;

	sprint(self, "\n");
	sprint(self, "\bctf related\b\n");
	sprint(self, "\n");
	sprint(self, "\bflag |  time  |cap|  best  |def|rtn|fcd|fca|fck|     name      \b\n");
	sprint(self, "\b-----+--------+---+--------+---+---+---+---+---+---------------\b\n");

	player = clanring_sentinel.next_player;
	pteam = player.next_team;
	while (player)
	{
		if (!(player.style & CLANRING_OBSERVER))
		{
			if (player == self)
			{
				sprint(self, "\x90");
				utils_print_int3(player.fpickups);//pickups
				sprint(self, "\x91\b|");
			}
			else
			{
				sprint(self, " ");
				utils_print_int3(player.fpickups);
				sprint(self, " \b|");
			}
			utils_sprint_stat_time(self,(player.fctime));
			sprint(self, "\b|");
			utils_print_int3(player.fcaptures);
			sprint(self, "\b|");
			if (player.captime == 1200)
				utils_sprint_stat_time(self,(0));
			else
				utils_sprint_stat_time(self,(player.captime));
			sprint(self, "\b|");
			utils_print_int3(player.fdefenses);
			sprint(self, "\b|");
			utils_print_int3(player.freturns);
			sprint(self, "\b|");
			utils_print_int3(player.fcdefenses);
			sprint(self, "\b|");
			utils_print_int3(player.fcassists);
			sprint(self, "\b|");
			utils_print_int3(player.fcfrags);			
			if (player == self)
			{
				sprint(self, "\b|\b\x90");
				sprint(self, player.netname);
				sprint(self, "\x91\n");
			}
			else
			{
				sprint(self, "\b| ");
				sprint(self, player.netname);
				sprint(self, "\n");
			}

		}
		player = player.next_player;
		if (useteams && (player.next_team != pteam))
		{
			sprint3(self, "\b     |        |   |        |   |   |   |   |   |\b", pteam.mdl, "\n");
			pteam = player.next_team;
		}
	}
	sprint(self,"\n");
	mtr = sprintf("%s %s %-16s\n", utils_get_time(playerrecord2[0].statvalue), get_team_letter(playerrecord2[0].teamcolor), playerrecord2[0].player);
	sprint(self, mapname, " match capture-time record: ", mtr);
	ttr = sprintf("%s %s %-16s\n", utils_get_time(playerrecord[0].statvalue), get_team_letter(playerrecord[0].teamcolor), playerrecord[0].player);
	sprint(self, mapname, " trial capture-time record: ", ttr);
	sprint(self,"\n");
};

void () stats_team_stats =
{
	local entity e;
	local string t2;
	
	bprint ("\n");
	e = boss.next_team;
	
	while (e != world)
	{
		t2 = strpad (8, e.netname);
		bprint(t2);		
		t2 = "";//testing (second team goes way off the screen)
		bprint(" \bwon:\b ");				
		t2 = ftos (e.wins);
		bprint (t2);
		t2 = "";//testing (second team goes way off the screen)
		bprint(" \blost:\b ");
		t2 = ftos (e.losses);
		bprint (t2);		
		t2 = "";//testing (second team goes way off the screen)
		bprint("\n");
		e = e.next_team;
	}			
	bprint ("\n");
	remove(self);//kill temp ent that called this function.
};

//  S H O W  S U M M A R Y
//
//  Show kill and weapon efficiency for each player.
//
void () stats_show_summary =
{
    local entity player;
    local float wfrac, wtot, kfrac, ktot, useteams;
	local string teamname;

	if ((clanring_state & CLANRING_MATCH_STARTED) && teamplay)
		useteams = TRUE;
	else
		useteams = FALSE;

	sprint(self, "\n");
	sprint(self, "\befficiency\b\n");
	sprint(self, "\n");
	if (useteams)
	{
		sprint(self, "   team  ükill üweapnü     name\n");
		sprint(self, "­­­­­­­­­«­­­­­«­­­­­«­­­­­­­­­­­­­­­\n");
	}
	else
	{
		sprint(self, "kill üweapnü     name\n");
		sprint(self, "­­­­­«­­­­­«­­­­­­­­­­­­­­­\n");
	}

	if (mode_is_arena())
	{
		player = find(world,classname, "player");
	}
	else
	{
		player = clanring_sentinel.next_player;
	}

	while (player != world)
	{
		if (!(mode_is_arena()) || ((mode_is_arena()) && player.next_team != world))
		{
			if (useteams)
			{
				teamname = strings_get_teamname3(player.height);
				sprint2(self, teamname, " ü");
			}
			kfrac = player.true_kills;
			ktot = kfrac + player.mangle_z;
			wtot = player.dest1_x + player.dest1_y + player.dest1_z + player.dest_x;
			wfrac = player.dest2_x + player.dest2_y + player.dest2_z + player.dest_y;
			if (player == self)
			{
				sprint(self, "\x90");
				stats_print_percent3(kfrac, ktot);
				sprint(self, "‘ü\x90");
				stats_print_percent3(wfrac, wtot);
				sprint(self, "‘ü");
			}
			else
			{
				sprint(self, " ");
				stats_print_percent3(kfrac, ktot);
				sprint(self, " ü ");
				stats_print_percent3(wfrac, wtot);
				sprint(self, " ü");
			}
			sprint2(self, player.netname, "\n");
		}

		if (mode_is_arena())
		{
			player = find(player,classname, "player");
		}
		else
		{
			player = player.next_player;
		}
	}
	sprint(self, "\n");
};


void () stats_final_summary =
{
	local entity	player;
	local float 	wfrac, wtot, kfrac, ktot, tot_tot, tot_frac;
	local string 	t2 = "", teamname = "";
	local float 	n;

	bprint ("\b-----------------------------------------------------------\n");
	bprint ("  team   \b|\bopp\b|\bdth\b|\bkill%\b|\bweap%\b|\bdmgTk\b|\bdmgGv\b|\b      player     \n");
	bprint ("\b---------+---+---+-----+-----+-----+-----+-----------------\n");

	n = 0;
	player = find (world,classname, "player");
	
	while (player != world)
	{
		n = n + 1;
		if ((player.style & CLANRING_CONNECTED) && (player.next_team != world))
		{
			teamname = strings_get_teamname3 (player.next_team.team2);
			bprint2 ( teamname, " \b|\b");			
			stats_bprint_int3 (player.true_kills);
			bprint ( "\b|\b");
			stats_bprint_int3 (player.mangle_z);//killed
			bprint ( "\b|\b");

			//Kill % stats
			kfrac = (player.frags);
			ktot = (kfrac + player.mangle_z);
			//Weapon % stats
			wtot = player.dest1_x + player.dest1_y + player.dest1_z + player.dest_x + player.stats_gl_tot;
			wfrac = player.dest2_x + player.dest2_y + player.dest2_z + player.dest_y + player.stats_gl_frac;

			bprint ( " ");
			stats_bprint_percent3 (kfrac, ktot);
			bprint ( " \b|\b ");
			stats_bprint_percent3 (wfrac, wtot);
			bprint ( " \b|\b");
			utils_bprint_damage_gold(player.dmg_taken);
			bprint ( "\b|\b");
			utils_bprint_damage_gold(player.dmg_given);
			bprint ("\b|\b");							
			bprint3 (" ",player.netname, "\n");
		}
		if (n > 16)
			break;
		player = find (player, classname, "player");
	}
/*
	bprint ("\n\n");
	bprint ( "bul \b-\b bullet \b\n");
	bprint ( "nls \b-\b nail   \n");
	bprint ( "rox \b-\b rocket \n");
	bprint ( "gl  \b-\b grenade\n");
	bprint ( "lg  \b-\b lightning gun \n");
	bprint ( "dhit\b-\b rl/gl direct hits\n");
*/
	bprint ( "\b-----------------------------------------------------------\n");
	bprint ( "  team   \b|\bbul\b|\bnls\b|\brox\b|\bgl \b|\blg \b|\bdhit \b|\btotal\b|\b     EFFICIENCY\n");
	bprint ( "\b---------+---+---+---+---+---+-----+-----+-----------------\n");

	n = 0;
	player = find (world,classname, "player");

	while (player != world)
	{
		n += 1;
		if ((player.style & CLANRING_CONNECTED) && (player.next_team != world))
		{			
			teamname = strings_get_teamname3 (player.next_team.team2);
			bprint2 ( teamname, " \b|\b");			
			stats_bprint_percent3(player.dest2_x, player.dest1_x);
			bprint ( "\b|\b");
			stats_bprint_percent3(player.dest2_y, player.dest1_y);
			bprint ( "\b|\b");
			stats_bprint_percent3 (player.dest_y, player.dest_x); // rox
			bprint ( "\b|\b");
			stats_bprint_percent3(player.stats_gl_frac, player.stats_gl_tot); // grenades
			bprint ( "\b|\b");
			stats_bprint_percent3 (player.dest2_z, player.dest1_z); // lg
			bprint ( "\b|\b");
			utils_bprint_damage_gold(player.direct_hit);
			bprint ( "\b|\b");

			tot_tot = player.dest1_x + player.dest1_y + player.dest1_z + player.dest_x + player.stats_gl_tot;
			tot_frac = player.dest2_x + player.dest2_y + player.dest2_z + player.dest_y + player.stats_gl_frac;

			bprint (" ");
			stats_bprint_percent3(tot_frac, tot_tot);
			bprint (" ");				
			bprint ("\b|\b");							
			bprint3 (" ",player.netname, "\n");
		}
		if (n >16)
			break;
		player = find (player, classname, "player");
	}
};

//
//  F O R M A T  V E C T O R
//
//  prints xx:yy:zz to self
//
void (vector v) stats_format_vector = 
{
	local string s;

	sprint(self, "ü");
	if (v_x < 10)
		sprint(self, " ");
	s = ftos(v_x);
	sprint(self, s, "Ž");
	if (v_y < 10)
		sprint(self, " ");
	s = ftos(v_y);
	sprint(self, s, "Ž");
	if (v_z < 10)
		sprint(self, " ");
	s = ftos(v_z);
	sprint(self, s);
};

//
//  S H O W  T E A M  S T A T S
//
void() stats_show_teamstats =
{
	local entity pteam;
	local string s;

    if (!(teamplay && (clanring_playmode & CLANRING_MATCH_MODE)))
    {
        local float mode; local string szmode;
        mode = options_get_mode();
        szmode = strings_get_mode(mode);
        sprint(self, sprintf("Teamstats valid in match mode only (current: %s)\n", szmode));
        return;
    }
	if (!clanring_sentinel.next_team)
	{
		sprint(self, "No teams\n");
		return;
	}
	if ((clanring_state & CLANRING_MATCH_STARTED) && !(self.style & CLANRING_OBSERVER))
	{
		sprint(self, "Teamstats available to observers only\n");
		return;
	}
	sprint(self, "\n");
	sprint(self, "\bteam related\b\n");
	sprint(self, "\n");
	sprint(self, "          ");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		s = strings_get_teamname3(pteam.height);
		sprint2(self, "ü", s);
		pteam = pteam.next_team;
	}
	sprint(self, "\n­­­­­­­­­­");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		sprint(self, "«­­­­­­­­");
		pteam = pteam.next_team;
	}
	sprint(self, "\nQŽ˜˜˜Žring");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		stats_format_vector(pteam.dest2);
		pteam = pteam.next_team;
	}
	sprint(self, "\nRLŽLGŽGL  ");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		stats_format_vector(pteam.dest1);
		pteam = pteam.next_team;
	}
	sprint(self, "\nSNGŽNGŽMH ");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		stats_format_vector(pteam.pos1);
		pteam = pteam.next_team;
	}
	sprint(self, "\nRAŽYAŽGA  ");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		stats_format_vector(pteam.dest);
		pteam = pteam.next_team;
	}
	sprint(self, "\nrlpak +/- ");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		sprint(self, "ü");
		s = ftos(pteam.mangle_y);
		if (pteam.mangle_y < 10)
			sprint(self, " ");
		sprint3(self, "«", s, " ");
		s = ftos(pteam.mangle_z);
		if (pteam.mangle_z < 10)
			sprint(self, " ");
		sprint3(self, "­", s, " ");
		pteam = pteam.next_team;
	}

	sprint(self, "\ncontrol   ");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		local float f, control;
		control = 100 * pteam.mangle_x / clanring_sentinel.cnt;
		f = floor(control);
		s = ftos(f);
		sprint2(self, "ü  %", s);
		f = floor((control - f) * 10);
		s = ftos(f);
		sprint3(self, ".", s, " ");
		if (control < 10)
			sprint(self, " ");
		pteam = pteam.next_team;
	}
	sprint(self, "\n");
	sprint(self, "\n");
};

//
//    S H O W  P L A Y E R  W E A P O N  I T E M S  T A K E N  S T A T S 
//
void( entity p ) stats_show_player_weapon_items_taken_stats =
{
    //sprint(self, " ", strpad(15, p.netname),"\b|\b");
    sprint(self, sprintf("%3g\b|\b",p.stats_item_ssg));
    sprint(self, sprintf("%3g\b|\b",p.stats_item_ng));
    sprint(self, sprintf("%3g\b|\b",p.stats_item_sng));
    sprint(self, sprintf("%3g\b|\b",p.stats_item_gl));
    sprint(self, sprintf("%3g\b|\b",p.stats_item_rl));
    sprint(self, sprintf("%3g\b|\b",p.stats_item_lg));
    sprint(self, sprintf("%3g\b|\b",p.stats_item_shells));
    sprint(self, sprintf("%3g\b|\b",p.stats_item_nails));
    sprint(self, sprintf("%3g\b|\b",p.stats_item_rockets));
    sprint(self, sprintf("%3g\b|\b",p.stats_item_cells));
    sprint(self, " ",p.netname,"\n");
};

//
//    S H O W  P L A Y E R  I T E M S  T A K E N  S T A T S 
//
void( entity p ) stats_show_player_items_taken_stats =
{
    sprint(self, sprintf("%4g\b|\b",p.stats_item_health));
    sprint(self, sprintf("%4g\b|\b",p.stats_item_mega));
    sprint(self, sprintf("%4g\b|\b",p.stats_item_biosuit));
//	sprint(self, sprintf("%4g\b|\b",p.stats_item_ring)); // TODO
    sprint(self, sprintf("%3g\b|\b",p.stats_item_greenarmor));
    sprint(self, sprintf("%3g\b|\b",p.stats_item_yellowarmor));
    sprint(self, sprintf("%3g\b|\b",p.stats_item_redarmor));
    sprint(self, sprintf("%4g\b|\b",p.stats_item_backpacks));
//    sprint(self, sprintf("%3g\b|\b",p.stats_item_runes));
    sprint(self, " ",p.netname,"\n");
};

//
//    S H O W  W E A P O N  I T E M S  T A K E N  S T A T S 
//
void() stats_show_weapon_items_taken_stats =
{
    local entity e;
    
    sprint(self, "\n");
    sprint(self, "\bweapon items taken stats\n\n");
    sprint(self, "\b     weapons taken        ammo taken\n");
    sprint(self, "ssg\b|\b ng\b|\bsng\b|\b gl\b|\b rl\b|\b lg\b|\bshl\b|\bnls\b|\brox\b|\bcls\b|\b name\n");
    sprint(self, "\b---+---+---+---+---+---+---+---+---+---+---------------\n");
	
	if (clanring_playmode & CLANRING_MATCH_MODE)
		e = clanring_sentinel.next_player;
	else	
		e = find(world,classname, "player");
	
	while (e)
	{
		if (!(e.style & CLANRING_OBSERVER))
			stats_show_player_weapon_items_taken_stats(e);

		if (clanring_playmode & CLANRING_MATCH_MODE)
		{
			e = e.next_player;
		}
		else
		{
			e = find(e,classname, "player");			
		}
	}
	sprint(self, "\n");
};

//
//    S H O W  I T E M S  T A K E N  S T A T S 
//
void() stats_show_items_taken_stats =
{
    local entity e;
    
    sprint(self, "\n");
    sprint(self, "\bitems taken stats\n");
    sprint(self, "\n");
    
    sprint(self, "hlth\b|\bmega\b|\bsuit\b|\b GA\b|\b YA\b|\b RA\b|\bbkpk\b|\b name\n");
    sprint(self, "\b----+----+----+---+---+---+----+---------------\n");
	
	if (clanring_playmode & CLANRING_MATCH_MODE)
		e = clanring_sentinel.next_player;
	else	
		e = find(world,classname, "player");
	
	while (e)
	{
		if (!(e.style & CLANRING_OBSERVER))
			stats_show_player_items_taken_stats(e);

		if (clanring_playmode & CLANRING_MATCH_MODE)
		{
			e = e.next_player;
		}
		else
		{
			e = find(e,classname, "player");			
		}
	}
	sprint(self, "\n");
};

//
//    S H O W  D E F E N S E  S T A T S 
//
void() stats_show_defense_stats =
{
    local entity e;
    
    sprint(self, "\n");
    sprint(self, "\bdefense stats\n");
    sprint(self, "\n");

	if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
	{
    	sprint(self, "teammate\b|\bflag\b|\bbackpack\b|\bpowerup\b|\bweapon\b|\barmor\b|\b name\n");
    	sprint(self, "\b--------+----+--------+-------+------+-----+-----------\n");
	}
	else
	{
    	sprint(self, "teammate\b|\bbackpack\b|\bpowerup\b|\bweapon\b|\barmor\b|\b name\n");
    	sprint(self, "\b--------+--------+-------+------+-----+-----------\n");
	}
	
	if (clanring_playmode & CLANRING_MATCH_MODE)
		e = clanring_sentinel.next_player;
	else	
		e = find(world,classname, "player");
	
	while (e)
	{
		if (!(e.style & CLANRING_OBSERVER))
		{
			sprint(self, sprintf("%8g\b|\b",e.stats_defense_teammate));
			if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
				sprint(self, sprintf("%4g\b|\b",e.stats_defense_dropped_flag));
			sprint(self, sprintf("%8g\b|\b",e.stats_defense_backpack));
			sprint(self, sprintf("%7g\b|\b",e.stats_defense_powerup));
			sprint(self, sprintf("%6g\b|\b",e.stats_defense_weapon));
			sprint(self, sprintf("%5g\b|\b",e.stats_defense_armor));
			sprint(self, " ",e.netname,"\n");
		}

		if (clanring_playmode & CLANRING_MATCH_MODE)
		{
			e = e.next_player;
		}
		else
		{
			e = find(e,classname, "player");			
		}
	}
	sprint(self, "\n");
};

//
// P L A Y E R   E F F I C I E N C Y   R A T I N G
//
// helper function (round to 2 decimals)
float(float x) round2d =
{
  return floor(x * 100 + 0.5) / 100;
}

// Separated fields for tracking contribution per player by type (add to p entity)
.float per_combat, per_resources, per_objectives, per_penalties;

//
//  PLAYER EFFICIENCY RATINGS
//
//  Q1 PER is a "combined stat" tracking overall contribution to the outcome of games.  
//  It is broken down as follows:
//
//  * Combat            kill-death spread + damage spread + "hard to kill" bonus + Quad Kill (enemy) bonus
//  * Resources         powerup pickups + armour/mega taken + weapon pickups
//  * Objectives (CTF)  captures, carries time, base/carrier defense, returns
//  * Penalties         Teamkills, team?damage, dropped RL/LG paks, extra pen. for Quad-TK
//
float (entity p) Q1_PER_Calc_Eff =
{
    float kd_spread, dmg_spread, dmg_tokill, dmg_min, resilience, res_coeff, res_term;
    float combat_raw, resources_raw, objectives_raw, penalties_raw;
    
    // Combat (Kills/Deaths, Damage, Resilience, and bonuses)
    // ======================================================

    // players spawn in CTF with 50 GA (absorbs 30% of damage)
    dmg_min = (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) ? 142 : 100;

    // adjust resilience coefficient for TDM/CTF (easier to survive in CTF with hook, and higher min damage)
    res_coeff = (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) ? 10: 13;

    kd_spread  = p.true_kills - p.mangle_z;
    dmg_spread = p.dmg_given - p.dmg_taken;
    // Average damage to kill per life. If no deaths, use total damage (can be 0).
    // We'll treat resilience as *bonus-only*: no penalty for being below baseline.
    dmg_tokill = (p.mangle_z > 0) ? (p.dmg_taken / p.mangle_z) : p.dmg_taken;
    resilience = dmg_tokill / dmg_min;  // 1.0 == baseline 'took about enough damage to die once'
    res_term  = res_coeff * max(0, pow(resilience, 1.2) - 1);

    combat_raw =
        0.9 * kd_spread * pow(fabs(kd_spread), 0.1125)  // killstats: kills-deaths, using a 0.9 multiplier, and super-linearly scaled @ ^1.1125
      + 0.6 * (dmg_spread / dmg_min)                    // damagestats: given-taken, divided by minimum damage to kill
      + 2.5 * p.stats_powerup_denial_quad               // Bonus for enemy Quads killed
      + res_term;                                       // Bonus-only survivability (never negative on zero activity)


    // Resources (powerups and item/weapon pickups)
    // ============================================
   
    resources_raw =
        2.0 * p.totalquad
      + 5.0 * p.clanring_ptwep_z                  // Pents taken
      + 1.0 * p.stats_item_ring
      + 0.30 * p.stats_item_redarmor
      + 0.10 * p.stats_item_yellowarmor
      + 0.15 * p.stats_item_mega
      + 0.20 * p.stats_item_rl        
      + 0.20 * p.stats_item_lg;


    // Objectives (CTF)
    // ================
 
    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
    {
		objectives_raw =
          2.5 * p.fcaptures + 0.55 * pow(p.fcaptures, 1.125)    // slight super-linear scaling of flag captures as the # increases, extra reward for many caps - balanced with secondary coefficient (+0.55) 
        + 5.0 * pow(p.fcarries_time / 60, 0.9)                  // sub-linear scaling, value of holding flag decreases slightly over time (prevent runaway stats from eg. hiding in ctf2m8)
        + 1.5 * p.fcfrags                                       // killing flag carrier has ~equivalent value to a capture (add ~+1 for the kill - combat stat)
        + 0.25 * p.freturns                                      // return alone has low value
        + 2.25 * p.strategic_returns                             // return resulting in a capture has equivalent value to a capture
        + (1.0 * p.fdefenses + 0.23 * pow(p.fdefenses, 1.10))   // base/flag defense bonus grows over time on a very slight super-linear curve, offering extra points to players who lock down their base well
        + 1.0 * p.fcdefenses;                                   // flag carrier defenses do not grow/scale (linear)
    }
    else
    {
		objectives_raw = 0;
    }


    // Penalties
    // =========
    
    penalties_raw = 
        1.0 * p.mangle_y                          // teamkills
      + 1.0 * p.clanring_badstats_x               // rls dropped
      + 1.0 * p.clanring_badstats2_x              // lgs dropped
      + 0.15 * (p.clanring_badstats_z / dmg_min)  // team damage - 25% penalty (compared to damage values in combat group)
      + 2.5 * p.stats_teamkill_quad;              // quad TKs

  
    // Final PER calculations
    // ======================

	p.per_combat = round2d(combat_raw);
	p.per_resources = round2d(resources_raw);
	p.per_objectives = round2d(objectives_raw);
	// Store as negative so a quick dump shows deductions clearly
	p.per_penalties = round2d(-penalties_raw);
	
	return max(0, round2d(combat_raw + resources_raw + objectives_raw - penalties_raw));
};

// ---------------------------------------------
// Helper: did this player do anything meaningful?
// (used to suppress printing on 0:00/no-activity)
// ---------------------------------------------
float(entity p) PER_HasNontrivialActivity =
{
	// Core combat/damage
	if (p.true_kills) return TRUE;
	if (p.mangle_z) return TRUE;       // deaths
	if (p.dmg_given) return TRUE;
	if (p.dmg_taken) return TRUE;

	// Powerups/items (resource control)
	if (p.totalquad) return TRUE;
	if (p.clanring_ptwep_z) return TRUE; // pents
	if (p.stats_item_ring) return TRUE;
	if (p.stats_item_redarmor) return TRUE;
	if (p.stats_item_yellowarmor) return TRUE;
	if (p.stats_item_mega) return TRUE;
	if (p.stats_item_rl) return TRUE;
	if (p.stats_item_lg) return TRUE;

	// Objectives (CTF)
	if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) &&
	    (p.fcaptures || p.fcarries_time || p.fcfrags || p.freturns || p.strategic_returns || p.fdefenses || p.fcdefenses)) return TRUE;
	return FALSE;
};

// ---------------------------------------------------------
// Helper: print top-3 contributing reasons for player's PER
// (normalized per minute, so it aligns with the table)
// ---------------------------------------------------------
void(entity towhom, entity p, float mins_norm) PER_PrintTop3Reasons =
{
	local float dmg_min, res_coeff, kd_spread, dmg_spread, dmg_tokill, resilience, res_term;
	local float v, top1, top2, top3;
	local string r1, r2, r3;
	local float min_show; // ignore tiny noise terms
	local float carry_sec, cm;

	if (mins_norm <= 0) mins_norm = 1;
	min_show = 0.25; // ~0.25 PER/min threshold to avoid spammy reasons

	// ---- recompute terms (mirror Q1_PER_Calc_Eff) ----
	dmg_min   = (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) ? 142 : 100;
	res_coeff = (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) ? 10  : 13;

	kd_spread  = p.true_kills - p.mangle_z;
	dmg_spread = p.dmg_given - p.dmg_taken;
	dmg_tokill = (p.mangle_z > 0) ? (p.dmg_taken / p.mangle_z) : p.dmg_taken;
	resilience = dmg_tokill / dmg_min;
	res_term   = res_coeff * max(0, pow(resilience, 1.2) - 1);

	// insertion helper (inline) — maintain top1/top2/top3 by value
	#define TRY_PUSH(_val, _label) \
		do { \
			v = (_val) / mins_norm; \
			if (v > min_show) { \
				if (v > top1) { top3 = top2; r3 = r2; top2 = top1; r2 = r1; top1 = v; r1 = (_label); } \
				else if (v > top2) { top3 = top2; r3 = r2; top2 = v; r2 = (_label); } \
				else if (v > top3) { top3 = v; r3 = (_label); } \
			} \
		} while(0)

	top1 = top2 = top3 = -9999;
	r1 = r2 = r3 = "";

	// ---- Combat atomic terms ----
	TRY_PUSH( 0.9 * kd_spread * pow(fabs(kd_spread), 0.1125),
	          sprintf("big KD spread (%g-%g)", p.true_kills, p.mangle_z) );
	TRY_PUSH( 0.6 * (dmg_spread / dmg_min),
	          sprintf("damage advantage (+%g)", dmg_spread) );
	TRY_PUSH( res_term,
	          sprintf("hard-to-kill bonus (~%g dmg/life)", round2d(dmg_tokill)) );
	TRY_PUSH( 2.5 * p.stats_powerup_denial_quad,
	          sprintf("enemy Quad kills (%g)", p.stats_powerup_denial_quad) );

	// ---- Resources atomic terms ----
	TRY_PUSH( 2.0 * p.totalquad,
	          sprintf("Quad control time (%gs total; %g quad pickups)", floor(p.totalquad + 0.5), p.clanring_qdwep_z) );
	TRY_PUSH( 5.0 * p.clanring_ptwep_z,
	          sprintf("Pents taken (%g)", p.clanring_ptwep_z) );
	TRY_PUSH( 1.0 * p.stats_item_ring,
	          sprintf("Rings taken (%g)", p.stats_item_ring) );
	TRY_PUSH( 0.30 * p.stats_item_redarmor,
	          sprintf("RA control (%g)", p.stats_item_redarmor) );
	TRY_PUSH( 0.10 * p.stats_item_yellowarmor,
	          sprintf("YA pickups (%g)", p.stats_item_yellowarmor) );
	TRY_PUSH( 0.15 * p.stats_item_mega,
	          sprintf("Megas taken (%g)", p.stats_item_mega) );
	TRY_PUSH( 0.20 * p.stats_item_rl,
	          sprintf("RL pickups (%g)", p.stats_item_rl) );
	TRY_PUSH( 0.20 * p.stats_item_lg,
	          sprintf("LG pickups (%g)", p.stats_item_lg) );

	// ---- Objectives atomic terms (CTF only) ----
	if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
	{
		TRY_PUSH( 2.5 * p.fcaptures + 0.55 * pow(p.fcaptures, 1.125),
		          sprintf("flag captures (%g)", p.fcaptures) );
		// carry time nice-ish label
		carry_sec = p.fcarries_time;
		cm = floor(carry_sec / 60);
		TRY_PUSH( 5.0 * pow(p.fcarries_time / 60, 0.9),
		          sprintf("long flag holds (%g:%02g)", cm, carry_sec - cm*60) );
		TRY_PUSH( 1.5 * p.fcfrags,
		          sprintf("carrier kills (%g)", p.fcfrags) );
		TRY_PUSH( 0.25 * p.freturns,
		          sprintf("returns (%g)", p.freturns) );
		TRY_PUSH( 2.25 * p.strategic_returns,
		          sprintf("strategic returns (%g)", p.strategic_returns) );
		TRY_PUSH( 1.0 * p.fdefenses + 0.23 * pow(p.fdefenses, 1.10),
		          sprintf("base defenses (%g)", p.fdefenses) );
		TRY_PUSH( 1.0 * p.fcdefenses,
		          sprintf("carrier defenses (%g)", p.fcdefenses) );
	}

	#undef TRY_PUSH

	// ---- Fallbacks: if fewer than 3 passed threshold, use category totals ----
	if (r1 == "")
	{
		// Compute group totals again and push them if useful
		local float combat_raw, resources_raw, objectives_raw;
		combat_raw =
			  0.9 * kd_spread * pow(fabs(kd_spread), 0.1125)
			+ 0.6 * (dmg_spread / dmg_min)
			+ 2.5 * p.stats_powerup_denial_quad
			+ res_term;
		resources_raw =
			  2.0 * p.totalquad
			+ 5.0 * p.clanring_ptwep_z
			+ 1.0 * p.stats_item_ring
			+ 0.30 * p.stats_item_redarmor
			+ 0.10 * p.stats_item_yellowarmor
			+ 0.15 * p.stats_item_mega
			+ 0.20 * p.stats_item_rl
			+ 0.20 * p.stats_item_lg;
		objectives_raw = 0;
		if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
			objectives_raw =
				  (2.5 * p.fcaptures + 0.55 * pow(p.fcaptures, 1.125))
				+ 5.0 * pow(p.fcarries_time / 60, 0.9)
				+ 1.5 * p.fcfrags
				+ 0.25 * p.freturns
				+ 2.25 * p.strategic_returns
				+ (1.0 * p.fdefenses + 0.23 * pow(p.fdefenses, 1.10))
				+ 1.0 * p.fcdefenses;

		// push the three category totals (largest first naturally by value)
		// (not thresholded—these are intentional fallbacks)
		top1 = combat_raw / mins_norm; r1 = "combat impact";
		top2 = resources_raw / mins_norm; r2 = "resource control";
		top3 = objectives_raw / mins_norm; r3 = "objectives";
	}

	// ---- Print reasons ----
	sprint(towhom, sprintf("  why %s led PER:\n", p.netname));
	if (r1 != "") sprint(towhom, sprintf("    1) %s (+%3.1f/min)\n", r1, top1));
	if (r2 != "") sprint(towhom, sprintf("    2) %s (+%3.1f/min)\n", r2, top2));
	if (r3 != "") sprint(towhom, sprintf("    3) %s (+%3.1f/min)\n", r3, top3));
	sprint(towhom, "\n");
};


void() stats_show_per =
{
    local entity p;
    local float match_secs, mins_norm;
    local entity bestp;
    local float best_per_min, best_mins_norm;
    local float best_is_valid; // 0/1 — only show reasons if leader wasn't short+empty
    local float short_and_empty;

    // Header
    sprint(self, "\bplayer efficiency rating (PER)\b\n");
    sprint(self, "\n");
    sprint(self, "  PER       name\n");
    sprint(self, "\n\n");

    // Start at first player depending on match-mode list handling
    if (clanring_playmode & CLANRING_MATCH_MODE)
        p = clanring_sentinel.next_player;
    else
        p = find(world, classname, "player");

    // Track top PER/min
    bestp = world;
    best_per_min = -9999;
    best_mins_norm = 1;
    best_is_valid = 0;

    while (p)
    {
        if (!(p.style & CLANRING_OBSERVER) && p.join_time > 0)
        {
            local float final_per;

            match_secs = time - p.join_time;
            // Normalize to PER/minute with a 1-minute floor so very short aborts don't blow up values.
            mins_norm = max(1, match_secs / 60);
            // Mirror your "don't show PER on short (0:00) + no activity"
            short_and_empty = (match_secs < 60) && (!PER_HasNontrivialActivity(p));

            final_per = Q1_PER_Calc_Eff(p) / mins_norm;

            if (p == self)
                sprint(self, sprintf("\x90%5.1f\x91 ü %s\n", final_per, p.netname));
            else
                sprint(self, sprintf(" %5.1f  ü %s\n", final_per, p.netname));

            // Track top PER/min player
            // Only consider as a valid "leader" if not a short+empty stint.
            // This keeps the reasons hidden for aborted 0:00/no-activity runs.
            if ((!short_and_empty) && (final_per > best_per_min))
            {
                best_per_min = final_per;
                bestp = p;
                best_mins_norm = mins_norm;
                best_is_valid = 1;
            }
        }

        if (clanring_playmode & CLANRING_MATCH_MODE)
            p = p.next_player;
        else
            p = find(p, classname, "player");
    }

    sprint(self, "\n");

    // Print dynamic top-3 reasons under the table
    // Only if the leader was NOT short+empty (same rule as hiding PER).
    if (best_is_valid && bestp)
    {
        PER_PrintTop3Reasons(self, bestp, best_mins_norm);
    }
};

//
//  A U T O D U M P
//
//  Dump statistics if player has autostats enabled.
//
void() stats_autodump =
{
		sprint(self, "\n");
		sprint(self, "\n");
		sprint(self, "\bmatch statistics\n");
		sprint(self, "\n");		
		sprint(self, sprintf("map: %s\n",mapname));
		string date = strftime(TRUE, "%m-%d-%Y %H:%M");
		
		local string hname = infokey(world,"hostname");
		sprint(self, sprintf("%s\n%s\n",date,hname));

		stats_show_summary ();
		//sprint(self, "\n");

		stats_show_efficiency();
		//sprint(self, "\n");

		if (!(mode_is_arena()) || 
			(clanring_playmode & CLANRING_CA_MODE) || 
			(clanring_playmode & CLANRING_WIPEOUT_MODE))
		{
			stats_show_killstats();
			//sprint(self, "\n");
		}

		if (!(clanring_playmode & CLANRING_NO_QUAD) && !(mode_is_arena()))//R00k -added-
		{
			if (clanring_quad != world)	//No quad on the map
				stats_show_quadstats ();
			//sprint(self, "\n");
		}

		if (!(clanring_playmode & CLANRING_NO_PENT) && !(mode_is_arena()))
		{
			if (clanring_pent != world) //No Pent on the map.
				stats_show_pentstats ();
			//sprint(self, "\n");
		}

		if (!(mode_is_arena()) || 
			(clanring_playmode & CLANRING_CA_MODE) || 
			(clanring_playmode & CLANRING_WIPEOUT_MODE))
		{
			stats_show_badstats();
		}

		if (teamplay)
		{
			stats_show_teamstats();
			//sprint(self, "\n");
		}

		if (!(mode_is_arena()))
		{
			//Only display these at the end.
			if ((gameover)||(clanring_state & CLANRING_MATCH_OVER))
			{
				stats_show_items_taken_stats();
				stats_show_weapon_items_taken_stats();
			}
		}

		if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
		{
			stats_show_fstats();
			if (clanring_new_record_player != "")
			{
				sprint(self,sprintf("%s set a new match capture record!\n", clanring_new_record_player));
			}
			//sprint(self, "\n");
		}
		sprint(self, "\n");

		if (!(mode_is_arena()))
		{
			stats_show_per();
		}

		// -------------------------------------------------
        // Build a concise Discord header and send via webhook
        // (Full text capture can be added later by routing
        // the stats_prints through a capture helper.)
        // -------------------------------------------------
        local string modes, tplay, msg;

        modes = "";
        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) modes = strcat(modes, "[CTF] ");
        if (clanring_playmode & CLANRING_CA_MODE)          modes = strcat(modes, "[CA] ");
        if (clanring_playmode & CLANRING_WIPEOUT_MODE)     modes = strcat(modes, "[Wipeout] ");
        if (mode_is_arena())                               modes = strcat(modes, "[Arena] ");
        if (modes == "")                                   modes = "[Std] ";

        tplay = teamplay ? "on" : "off";

        // Compact, Discord-friendly header; you can add more lines here anytime.
        msg = sprintf("**Match statistics**\n%s\n%s\nMap: %s\nTeamplay: %s\nModes: %s\n",
                      date, hname, mapname, tplay, modes);

        if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (clanring_new_record_player != ""))
            msg = strcat(msg, sprintf("%s set a new match capture record!\n", clanring_new_record_player));

        // Defer the post: PREP = webhook_stats_info, CONTENT = msg
        webhook_post_deferred(webhook_stats_info, msg);

};

//
//  H E L P
//
void () stats_help =
{
	sprint(self, "\n");
	sprint(self, "\bweapon efficiency\b\n");
	sprint(self, "\n");
	sprint(self, "bul - bullet efficiency\n");
	sprint(self, "nls - nail efficiency\n");
	sprint(self, "rox - rocket efficiency\n");
	sprint(self, "lg  - lightning gun efficiency\n");

	sprint(self, "\n");

	sprint(self, "\n");
	sprint(self, "\bkills\b\n");
	sprint(self, "\n");
	sprint(self, "opp - number of opponents killed\n");
	sprint(self, "slf - number of times killed self\n");
	sprint(self, "tm  - teammates killed\n");
	sprint(self, "kld - times killed by enemy\n");
	sprint(self, "dtk - damage taken\n");
	sprint(self, "dgv - damage given\n");
	

	sprint(self, "\n");

	sprint(self, "\n");
	sprint(self, "\bquad damage\b\n");
	sprint(self, "\n");
	sprint(self, "quads - quads picked up\n");
	sprint(self, "eff   - quad weapon efficiency\n");
	sprint(self, "opp   - opponents killed\n");
	sprint(self, "slf   - killed self\n");
	sprint(self, "tm    - teammates killed\n");

	sprint(self, "\n");

	sprint(self, "\n");
	sprint(self, "\bbad stuff\n");
	sprint(self, "\n");
	sprint(self, "paks - number of RL paks given away\n");
	sprint(self, "self - percent damage done to self\n");
	sprint(self, "team - percent damage done to team\n");
	
	sprint(self, "\n");

	sprint(self, "\n");
	sprint(self, "\bctf related\b\n");
	sprint(self, "\n");
	sprint(self, "flag - pickups\n");
	sprint(self, "cap  - captures\n");
	sprint(self, "def  - defenses\n");
	sprint(self, "rtn  - returns\n");
	sprint(self, "fcd  - carrier defenses\n");
	sprint(self, "fca  - carrier assists\n");
	sprint(self, "fck  - flag carriers killed\n");
	sprint(self, "time - best capture time\n");

	sprint(self, "\n");

};

//
//  I M P U L S E
//
void () stats_impulse =
{
	switch (self.impulse)
	{
		case 169: stats_show_pentstats();	break;
		case 170: stats_show_killstats();	break;	
		case 171: stats_show_efficiency();	break;
		case 172: stats_autodump();			break;
		case 173: stats_show_quadstats();	break;
		case 174: stats_show_badstats();	break;
		case 175: stats_show_teamstats();	break;
		case 176: stats_show_fstats();		break;
		case 178: utils_toggle_flag(CLANRING_AUTOSTATS, "Autostats"); break;
		case 179: stats_help(); 			break;
	}
};

//
//  C O P Y  S T A T I S T I C S
//
//  Copy all statistics at the end of a match so that they don't go away.
//
void() stats_copy_statistics = 
{
	return;//FIXME this is broken...
/*
	local entity s, p;

	if (clanring_sentinel == world)//testing
	{
		cprint("stats_copy_statistics: clanring_sentinel == world\n");
		return;
	}

	s = spawn();
	s.classname = "stats_copy";
	s.next_team = clanring_sentinel.next_team;
	clanring_sentinel.owner = s;
	p = clanring_sentinel.next_player;

	while (p)
	{
		s.next_player = p.owner;
		if (!teamplay)
			s.next_team = p.owner;
		s = p.owner;
		if (teamplay)
			s.next_team = p.next_team;
		p.owner = world;

		s.height = p.height;
		s.frags = p.frags;
		s.dest1 = p.dest1;
		s.dest2 = p.dest2;
		s.dest = p.dest;
		s.mangle = p.mangle;
		s.clanring_qdwep = p.clanring_qdwep;
		s.clanring_qdkill = p.clanring_qdkill;
		s.clanring_badstats = p.clanring_badstats;
		s.netname = p.netname;
		s.dmg_taken	= p.dmg_taken;
		s.dmg_given	= p.dmg_given;
		s.fpickups = p.fpickups;
		s.fcaptures = p.fcaptures;
		s.fdefenses = p.fdefenses;
		s.freturns = p.freturns;
		s.fcassists = p.fcassists;
		s.fcfrags = p.fcfrags;
		s.captime = p.captime;
		s.true_kills = p.true_kills;
		p = p.next_player;
	}
	s.next_player = world;
	if (teamplay)
	{
		p = clanring_sentinel.next_team;
		while(p)
		{
			p.next_player = p.next_player.owner;
			p.classname = "stats_copy";
			p = p.next_team;
		}
	}
	clanring_sentinel.next_player = world;
	clanring_sentinel.next_team = world;
	*/
};

//
//  D E L E T E  C O P I E S
//
void() stats_delete_copies = 
{	
//	utils_do_item(SUB_Remove, "stats_copy");
//	clanring_sentinel.owner = clanring_sentinel;
};

void reset_records(float which) {
	float i;
	if (which == 2) for (i=0;i<PLAYER_RECORDS_MAX_COUNT;i++){
		if (playerrecord2[i].player!="")     strunzone(playerrecord2[i].player);
		if (playerrecord2[i].rec_date!="")   strunzone(playerrecord2[i].rec_date);
		if (playerrecord2[i].rec_mt_str!="") strunzone(playerrecord2[i].rec_mt_str);
		playerrecord2[i].player=playerrecord2[i].rec_date=playerrecord2[i].rec_mt_str="";
		playerrecord2[i].statvalue=0; playerrecord2[i].teamcolor=0; playerrecord2[i].rec_mt_remain=-1;
	} else for (i=0;i<PLAYER_RECORDS_MAX_COUNT;i++){
		if (playerrecord[i].player!="")   strunzone(playerrecord[i].player);
		if (playerrecord[i].rec_date!="") strunzone(playerrecord[i].rec_date);
		if (playerrecord[i].rec_mt_str!="") strunzone(playerrecord[i].rec_mt_str);
		playerrecord[i].player=playerrecord[i].rec_date=playerrecord[i].rec_mt_str="";
		playerrecord[i].statvalue=0; playerrecord[i].teamcolor=0; playerrecord[i].rec_mt_remain=-1;
	}
}

//Check if a cap time is in the top records, then set it and return the rank or return 0 if not
//TODO:refactor all these into one, just check high/low and pass struct array? 
void (float t_statvalue, float t_teamcolor, string t_player) check_player_low_record =
{
	local float i=0,j=0, tmp = 0;
	while ((i < PLAYER_RECORDS_MAX_COUNT) && (tmp == 0))
	{
		if (playerrecord[i].statvalue == 0)
		{
			// before writing into slot i, free old strings (if any)
			if (playerrecord[i].player     != "") strunzone(playerrecord[i].player);
			if (playerrecord[i].rec_date   != "") strunzone(playerrecord[i].rec_date);
			if (playerrecord[i].rec_mt_str != "") strunzone(playerrecord[i].rec_mt_str);

			playerrecord[i].statvalue = t_statvalue;
			playerrecord[i].teamcolor = t_teamcolor;
			playerrecord[i].player = strzone(t_player);
			// CRX v2: attach metadata from globals (trial record: date only)
			playerrecord[i].rec_date  = (crx_meta_date != "") ? strzone(crx_meta_date) : "";
			playerrecord[i].rec_mt_remain = -1;
			playerrecord[i].rec_mt_str = "";
			tmp = (i+1);
			break;
		}
		else if ((playerrecord[i].statvalue > 0) && (t_statvalue < playerrecord[i].statvalue))
		{
			j = (PLAYER_RECORDS_MAX_COUNT - 1);
			while (j > i)
			{
				playerrecord[j].statvalue = playerrecord[(j-1)].statvalue;
				playerrecord[j].teamcolor = playerrecord[(j-1)].teamcolor;

				if (playerrecord[j].player     != "") strunzone(playerrecord[j].player);
				if (playerrecord[j].rec_date   != "") strunzone(playerrecord[j].rec_date);
				if (playerrecord[j].rec_mt_str != "") strunzone(playerrecord[j].rec_mt_str);

				playerrecord[j].player      = (playerrecord[j-1].player   != "") ? strzone(playerrecord[j-1].player)   : "";
				playerrecord[j].rec_date    = (playerrecord[j-1].rec_date != "") ? strzone(playerrecord[j-1].rec_date) : "";
				playerrecord[j].rec_mt_str  = "";
				playerrecord[j].rec_mt_remain = -1;

				j -= 1;
			}
			// before writing into slot i, free old strings (if any)
			if (playerrecord[i].player     != "") strunzone(playerrecord[i].player);
			if (playerrecord[i].rec_date   != "") strunzone(playerrecord[i].rec_date);
			if (playerrecord[i].rec_mt_str != "") strunzone(playerrecord[i].rec_mt_str);

			playerrecord[i].statvalue = t_statvalue;
			playerrecord[i].teamcolor = t_teamcolor;
			playerrecord[i].player = strzone(t_player);
			playerrecord[i].rec_date  = (crx_meta_date != "") ? strzone(crx_meta_date) : "";
			playerrecord[i].rec_mt_remain = -1;
			playerrecord[i].rec_mt_str = "";
			tmp = (i+1);
			break;
		}
		i += 1;
	}
	if (tmp > 0)
	{
		//strunzone(tt_netname);
	}
	new_player_record = tmp;
	//return tmp;
};
void (float t_statvalue, float t_teamcolor, string t_player) check_player_low_record2 =
{
	local float i=0,j=0, tmp = 0;
	while ((i < PLAYER_RECORDS_MAX_COUNT) && (tmp == 0))
	{
		if (playerrecord2[i].statvalue == 0)
		{
			// before writing into slot i, free old strings (if any)
			if (playerrecord2[i].player     != "") strunzone(playerrecord2[i].player);
			if (playerrecord2[i].rec_date   != "") strunzone(playerrecord2[i].rec_date);
			if (playerrecord2[i].rec_mt_str != "") strunzone(playerrecord2[i].rec_mt_str);

			playerrecord2[i].statvalue = t_statvalue;
			playerrecord2[i].teamcolor = t_teamcolor;
			playerrecord2[i].player = strzone(t_player);
			// CRX v2: match metadata (date + match time remaining)
			playerrecord2[i].rec_date      = (crx_meta_date != "")   ? strzone(crx_meta_date)   : "";
			playerrecord2[i].rec_mt_remain = crx_meta_mt_remain;
			playerrecord2[i].rec_mt_str    = (crx_meta_mt_str != "") ? strzone(crx_meta_mt_str) : "";
			tmp = (i+1);
			break;
		}
		else if ((playerrecord2[i].statvalue > 0) && (t_statvalue < playerrecord2[i].statvalue))
		{
			j = (PLAYER_RECORDS_MAX_COUNT - 1);
			while (j > i)
			{
				playerrecord2[j].statvalue = playerrecord2[(j-1)].statvalue;
				playerrecord2[j].teamcolor = playerrecord2[(j-1)].teamcolor;

				if (playerrecord2[j].player     != "") strunzone(playerrecord2[j].player);
				if (playerrecord2[j].rec_date   != "") strunzone(playerrecord2[j].rec_date);
				if (playerrecord2[j].rec_mt_str != "") strunzone(playerrecord2[j].rec_mt_str);

				playerrecord2[j].player      = (playerrecord2[j-1].player   != "") ? strzone(playerrecord2[j-1].player)   : "";
				playerrecord2[j].rec_date    = (playerrecord2[j-1].rec_date != "") ? strzone(playerrecord2[j-1].rec_date) : "";
				playerrecord2[j].rec_mt_remain = playerrecord2[(j-1)].rec_mt_remain;
				playerrecord2[j].rec_mt_str  = (playerrecord2[j-1].rec_mt_str != "") ? strzone(playerrecord2[j-1].rec_mt_str) : "";

				j -= 1;
			}
			// before writing into slot i, free old strings (if any)
			if (playerrecord2[i].player     != "") strunzone(playerrecord2[i].player);
			if (playerrecord2[i].rec_date   != "") strunzone(playerrecord2[i].rec_date);
			if (playerrecord2[i].rec_mt_str != "") strunzone(playerrecord2[i].rec_mt_str);

			playerrecord2[i].statvalue = t_statvalue;
			playerrecord2[i].teamcolor = t_teamcolor;
			playerrecord2[i].player = strzone(t_player);
			playerrecord2[i].rec_date      = (crx_meta_date != "")   ? strzone(crx_meta_date)   : "";
			playerrecord2[i].rec_mt_remain = crx_meta_mt_remain;
			playerrecord2[i].rec_mt_str    = (crx_meta_mt_str != "") ? strzone(crx_meta_mt_str) : "";
			tmp = (i+1);
			break;
		}
		i += 1;
	}
	if (tmp > 0)
	{
		//strunzone(tt_netname);
	}
	new_player_record = tmp;
	//return tmp;
};
void (float t_statvalue, float t_teamcolor, string t_player) check_player_high_record =
{
	local float i=0,j=0, tmp = 0;
	while ((i < PLAYER_RECORDS_MAX_COUNT) && (tmp == 0))
	{
		if (playerrecord[i].statvalue == 0)
		{
			// before writing into slot i, free old strings (if any)
			if (playerrecord[i].player     != "") strunzone(playerrecord[i].player);
			if (playerrecord[i].rec_date   != "") strunzone(playerrecord[i].rec_date);
			if (playerrecord[i].rec_mt_str != "") strunzone(playerrecord[i].rec_mt_str);

			playerrecord[i].statvalue = t_statvalue;
			playerrecord[i].teamcolor = t_teamcolor;
			playerrecord[i].player = strzone(t_player);
			playerrecord[i].rec_date  = (crx_meta_date != "") ? strzone(crx_meta_date) : "";
			playerrecord[i].rec_mt_remain = -1;
			playerrecord[i].rec_mt_str = "";
			tmp = (i+1);
			break;
		}
		else if ((playerrecord[i].statvalue > 0) && (t_statvalue > playerrecord[i].statvalue))
		{
			j = (PLAYER_RECORDS_MAX_COUNT - 1);
			while (j > i)
			{
				playerrecord[j].statvalue = playerrecord[(j-1)].statvalue;
				playerrecord[j].teamcolor = playerrecord[(j-1)].teamcolor;

				if (playerrecord[j].player     != "") strunzone(playerrecord[j].player);
				if (playerrecord[j].rec_date   != "") strunzone(playerrecord[j].rec_date);
				if (playerrecord[j].rec_mt_str != "") strunzone(playerrecord[j].rec_mt_str);

				playerrecord[j].player      = (playerrecord[j-1].player   != "") ? strzone(playerrecord[j-1].player)   : "";
				playerrecord[j].rec_date    = (playerrecord[j-1].rec_date != "") ? strzone(playerrecord[j-1].rec_date) : "";
				playerrecord[j].rec_mt_str  = "";
				playerrecord[j].rec_mt_remain = -1;

				j -= 1;
			}
			// before writing into slot i, free old strings (if any)
			if (playerrecord[i].player     != "") strunzone(playerrecord[i].player);
			if (playerrecord[i].rec_date   != "") strunzone(playerrecord[i].rec_date);
			if (playerrecord[i].rec_mt_str != "") strunzone(playerrecord[i].rec_mt_str);

			playerrecord[i].statvalue = t_statvalue;
			playerrecord[i].teamcolor = t_teamcolor;
			playerrecord[i].player = strzone(t_player);
			playerrecord[i].rec_date  = (crx_meta_date != "") ? strzone(crx_meta_date) : "";
			playerrecord[i].rec_mt_remain = -1;
			playerrecord[i].rec_mt_str = "";
			tmp = (i+1);
			break;
		}
		i += 1;
	}
	if (tmp > 0)
	{
		//strunzone(tt_netname);
	}
	new_player_record = tmp;
	//return tmp;
};
void (float t_statvalue, float t_teamcolor, string t_player) check_player_high_record2 =
{
	local float i=0,j=0, tmp = 0;
	while ((i < PLAYER_RECORDS_MAX_COUNT) && (tmp == 0))
	{
		if (playerrecord2[i].statvalue == 0)
		{
			// before writing into slot i, free old strings (if any)
			if (playerrecord2[i].player     != "") strunzone(playerrecord2[i].player);
			if (playerrecord2[i].rec_date   != "") strunzone(playerrecord2[i].rec_date);
			if (playerrecord2[i].rec_mt_str != "") strunzone(playerrecord2[i].rec_mt_str);

			playerrecord2[i].statvalue = t_statvalue;
			playerrecord2[i].teamcolor = t_teamcolor;
			playerrecord2[i].player = strzone(t_player);
			playerrecord2[i].rec_date      = (crx_meta_date != "")   ? strzone(crx_meta_date)   : "";
			playerrecord2[i].rec_mt_remain = crx_meta_mt_remain;
			playerrecord2[i].rec_mt_str    = (crx_meta_mt_str != "") ? strzone(crx_meta_mt_str) : "";
			tmp = (i+1);
			break;
		}
		else if ((playerrecord2[i].statvalue > 0) && (t_statvalue > playerrecord2[i].statvalue))
		{
			j = (PLAYER_RECORDS_MAX_COUNT - 1);
			while (j > i)
			{
				playerrecord2[j].statvalue = playerrecord2[(j-1)].statvalue;
				playerrecord2[j].teamcolor = playerrecord2[(j-1)].teamcolor;

				if (playerrecord2[j].player     != "") strunzone(playerrecord2[j].player);
				if (playerrecord2[j].rec_date   != "") strunzone(playerrecord2[j].rec_date);
				if (playerrecord2[j].rec_mt_str != "") strunzone(playerrecord2[j].rec_mt_str);

				playerrecord2[j].player      = (playerrecord2[j-1].player   != "") ? strzone(playerrecord2[j-1].player)   : "";
				playerrecord2[j].rec_date    = (playerrecord2[j-1].rec_date != "") ? strzone(playerrecord2[j-1].rec_date) : "";
				playerrecord2[j].rec_mt_remain = playerrecord2[(j-1)].rec_mt_remain;
				playerrecord2[j].rec_mt_str  = (playerrecord2[j-1].rec_mt_str != "") ? strzone(playerrecord2[j-1].rec_mt_str) : "";

				j -= 1;
			}
			// before writing into slot i, free old strings (if any)
			if (playerrecord2[i].player     != "") strunzone(playerrecord2[i].player);
			if (playerrecord2[i].rec_date   != "") strunzone(playerrecord2[i].rec_date);
			if (playerrecord2[i].rec_mt_str != "") strunzone(playerrecord2[i].rec_mt_str);

			playerrecord2[i].statvalue = t_statvalue;
			playerrecord2[i].teamcolor = t_teamcolor;
			playerrecord2[i].player = strzone(t_player);
			playerrecord2[i].rec_date      = (crx_meta_date != "")   ? strzone(crx_meta_date)   : "";
			playerrecord2[i].rec_mt_remain = crx_meta_mt_remain;
			playerrecord2[i].rec_mt_str    = (crx_meta_mt_str != "") ? strzone(crx_meta_mt_str) : "";
			tmp = (i+1);
			break;
		}
		i += 1;
	}
	if (tmp > 0)
	{
		//strunzone(tt_netname);
	}
	new_player_record = tmp;
	//return tmp;
};