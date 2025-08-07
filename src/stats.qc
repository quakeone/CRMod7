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
		sprint(self, "Teamstats valid in match mode only\n");
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
float (entity p) Q1_PER_Calc_Raw =
{
    local float eff_raw;

    // Return 0 if no kills or deaths (no combat engagement)
    if (p.true_kills == 0 && p.mangle_z == 0)
        return 0;

    // Kills / Deaths
    eff_raw = eff_raw + (1.00 * p.true_kills);
    eff_raw = eff_raw - (1.00 * p.mangle_z);

	// Teamkills

	if (deathmatch == 3)
		eff_raw = eff_raw - (0.50 * p.mangle_y); // Reduced teamkill penalty for non-team modes
	else
		eff_raw = eff_raw - (2.00 * p.mangle_y); // Full teamkill penalty for team modes

	eff_raw = eff_raw - (3.00 * p.stats_teamkill_quad); // Penalty for killing quadded teammate

	// Resilience (average damage taken per death)
	if (p.mangle_z > 0)
    	eff_raw = eff_raw + (0.01 * (p.dmg_taken / p.mangle_z)); // harder to finish off
	else
    	eff_raw += 6; // flat reward for flawless run (never dying)

    // Power-ups
    eff_raw = eff_raw + (0.50 * p.totalquad);
    eff_raw = eff_raw + (0.90 * p.clanring_ptwep_z); // Pent pickups

    // Item Pickups
    eff_raw = eff_raw + (0.30 * p.stats_item_redarmor) + (0.20 * p.stats_item_yellowarmor);
	eff_raw = eff_raw + (0.30 * p.stats_item_mega);

    // CTF Objectives
    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
    {
        eff_raw = eff_raw + (3.0 * p.fcaptures); // Flag captures - primary objective
        eff_raw = eff_raw + (0.2 * p.freturns); // Regular flag returns - basic defensive play
		eff_raw = eff_raw + (2.5 * p.strategic_returns); // Strategic returns - returns followed by team capture within 5s
        eff_raw = eff_raw + (1.0 * p.fdefenses); // Flag defenses - protecting home base
        eff_raw = eff_raw + (1.0 * p.fcdefenses); // Flag carrier defenses - protecting teammate
		eff_raw = eff_raw + (1.5 * p.fcfrags);  // Flag carrier kills
		eff_raw = eff_raw + (0.01 * p.fcarries_time); // Active flag carry time - distance/time control
    }

    // Weapon Losses (not applicable in dmm3)
    if (deathmatch != 3)
    {
        eff_raw = eff_raw - (0.50 * p.clanring_badstats_x);   // RL Paks lost
        eff_raw = eff_raw - (0.50 * p.clanring_badstats2_x);  // LG Paks lost
    }

	// Team Damage (non-CTF modes)
    if (teamplay && !(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))
        eff_raw = eff_raw - (0.0020 * p.clanring_badstats_z);

	eff_raw = eff_raw + (3.0 * p.stats_powerup_denial_quad); // Bonus for denying enemy quad

    return eff_raw;
};

void() stats_show_per =
{
    local entity p;
    local float match_secs;

    // Display the PER for each player
    sprint(self, "\bplayer efficiency rating (PER)\b\n");
    sprint(self, "\n");
    sprint(self, "  PER       name\n");
    sprint(self, "\n\n");

	if (clanring_playmode & CLANRING_MATCH_MODE)
		p = clanring_sentinel.next_player;
	else	
		p = find(world,classname, "player");
        
    while(p)
    {
        if (!(p.style & CLANRING_OBSERVER) && p.join_time > 0)
        {
            local float final_per;
            
            match_secs = time - p.join_time;
            if (match_secs > 1)
            {
                final_per = Q1_PER_Calc_Raw(p) / (match_secs / 60); // Direct efficiency per minute
            }
            else
            {
                final_per = 0;
            }

            if (p == self)
                sprint(self, sprintf("\x90%5.1f\x91 ü %s\n", final_per, p.netname));
            else
                sprint(self, sprintf(" %5.1f  ü %s\n", final_per, p.netname));
        }
		if (clanring_playmode & CLANRING_MATCH_MODE)
			p = p.next_player;
		else
			p = find(p,classname, "player");			
    }
    sprint(self, "\n");
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

//Check if a cap time is in the top records, then set it and return the rank or return 0 if not
//TODO:refactor all these into one, just check high/low and pass struct array? 
void (float t_statvalue, float t_teamcolor, string t_player) check_player_low_record =
{
	local float i=0,j=0, tmp = 0;
	while ((i < PLAYER_RECORDS_MAX_COUNT) && (tmp == 0))
	{
		if (playerrecord[i].statvalue == 0)
		{
			playerrecord[i].statvalue = t_statvalue;
			playerrecord[i].teamcolor = t_teamcolor;
			playerrecord[i].player = strzone(t_player);
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
				playerrecord[j].player = playerrecord[(j-1)].player;
				j -= 1;
			}
			playerrecord[i].statvalue = t_statvalue;
			playerrecord[i].teamcolor = t_teamcolor;
			playerrecord[i].player = strzone(t_player);
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
			playerrecord2[i].statvalue = t_statvalue;
			playerrecord2[i].teamcolor = t_teamcolor;
			playerrecord2[i].player = strzone(t_player);
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
				playerrecord2[j].player = playerrecord2[(j-1)].player;
				j -= 1;
			}
			playerrecord2[i].statvalue = t_statvalue;
			playerrecord2[i].teamcolor = t_teamcolor;
			playerrecord2[i].player = strzone(t_player);
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
			playerrecord[i].statvalue = t_statvalue;
			playerrecord[i].teamcolor = t_teamcolor;
			playerrecord[i].player = strzone(t_player);
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
				playerrecord[j].player = playerrecord[(j-1)].player;
				j -= 1;
			}
			playerrecord[i].statvalue = t_statvalue;
			playerrecord[i].teamcolor = t_teamcolor;
			playerrecord[i].player = strzone(t_player);
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
			playerrecord2[i].statvalue = t_statvalue;
			playerrecord2[i].teamcolor = t_teamcolor;
			playerrecord2[i].player = strzone(t_player);
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
				playerrecord2[j].player = playerrecord2[(j-1)].player;
				j -= 1;
			}
			playerrecord2[i].statvalue = t_statvalue;
			playerrecord2[i].teamcolor = t_teamcolor;
			playerrecord2[i].player = strzone(t_player);
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