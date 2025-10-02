//
// Console.qc
//
// This file contains code to implement server console directives.
//
// All code by J.P. Grossman unless otherwise commented.
//

string (void() function) fnstrings_function;
// constants
float CONSOLE_ENT_YAW   = 1;
float CONSOLE_ENT_PITCH = 2;
float CONSOLE_ENT_ROLL  = 4;

// global variables
vector console_origin;

//
//  S E T  A L I A S E S
//
//  Called once when the server is initialized.
//
void() StartRuneSpawn;
void() DropRune;
void() info_player_team1;
void() info_player_team2;
void() console_set_aliases =
{
    // set  aliases (server console commands)

	// immediate mode commands
	localcmd("alias sping temp1 1\n");
	localcmd("alias time temp1 2\n");
	localcmd("alias s temp1 3\n");
	localcmd("alias debug temp1 4\n");
	localcmd("alias score temp1 5\n");
	localcmd("alias ghostlist temp1 6\n");
	localcmd("alias killstats temp1 7\n");
	localcmd("alias efficiency temp1 8\n");
	localcmd("alias eff temp1 8\n");
	localcmd("alias stats temp1 9\n");
	localcmd("alias commands temp1 10\n");
	localcmd("alias vinfo temp1 11\n");
	localcmd("alias normal temp1 12\n");
	localcmd("alias practice temp1 13\n");
	localcmd("alias match temp1 14\n");
//	localcmd("alias crmod temp1 15\n");
	localcmd("alias quadstats temp1 16\n");
	localcmd("alias badstats temp1 18\n");
	localcmd("alias teamstats temp1 19\n");
	localcmd("alias admins temp1 90\n");
	localcmd("alias settings temp1 17\n");

	// config file commands 
	localcmd("alias safepracticeon \"temp1 20\"\n");
	localcmd("alias safepracticeoff \"temp1 21\"\n");
	localcmd("alias nogibs \"temp1 22\"\n");
	localcmd("alias lowgibs \"temp1 23\"\n");
	localcmd("alias highgibs \"temp1 24\"\n");
	localcmd("alias quadon \"temp1 25\"\n");
	localcmd("alias quadoff \"temp1 26\"\n");
	localcmd("alias penton \"temp1 27\"\n");
	localcmd("alias pentoff \"temp1 28\"\n");
	localcmd("alias ringon \"temp1 29\"\n");
	localcmd("alias ringoff \"temp1 30\"\n");
	localcmd("alias modevoteon \"temp1 31\"\n");
	localcmd("alias modevoteoff \"temp1 32\"\n");
	localcmd("alias obitson \"temp1 33\"\n");
	localcmd("alias obitsoff \"temp1 34\"\n");
	localcmd("alias setovertime \"temp1 36\"\n");
	localcmd("alias maxteams \"temp1 37\"\n");//??
	localcmd("alias faststarton \"temp1 38\"\n");
	localcmd("alias faststartoff \"temp1 39\"\n");
	localcmd("alias freshspawnson \"temp1 40\"\n");
	localcmd("alias freshspawnsoff \"temp1 41\"\n");
	localcmd("alias nopractice \"temp1 42\"\n");
	localcmd("alias autopauseon \"temp1 43\"\n");
	localcmd("alias autopauseoff \"temp1 44\"\n");
	localcmd("alias autostatson \"temp1 45\"\n");
	localcmd("alias autostatsoff \"temp1 46\"\n");
	localcmd("alias runeson \"temp1 47\"\n");
	localcmd("alias runesoff \"temp1 48\"\n");
	
	// entity file commands
	localcmd("alias newspawn \"temp1 50\"\n");
	localcmd("alias newstart \"temp1 51\"\n");
	localcmd("alias killspawn \"temp1 52\"\n");
	localcmd("alias makecam \"temp1 53\"\n");
	localcmd("alias killitem \"temp1 54\"\n");
	localcmd("alias makeitem \"temp1 55\"\n");
	localcmd("alias changeitem \"temp1 56\"\n");
  	
  	localcmd(";alias setafk \"temp1 57\"\n");//Set the amount of time in minutes before a player is marked as 'afk'
  	localcmd(";alias kickafk \"temp1 58\"\n");//Set the amount of time in minutes before an afk player is kicked

	// control commands	  
	localcmd("alias [init] \"temp1 60\"\n");
	localcmd("alias [normal] \"temp1 61\"\n");
	localcmd("alias [practice] \"temp1 62\"\n");
	localcmd("alias [match] \"temp1 63\"\n");
	localcmd("alias [ctf] \"temp1 64\"\n");
	localcmd("alias [done] \"temp1 65\"\n");

	localcmd(";alias dynamichookoff \"temp1 66\"\n");
	localcmd(";alias dynamichookon \"temp1 67\"\n");//speed cap for bunnyhops on landing to mimic 1997s 0.1 ticrate

	localcmd(";alias safedischargeon \"temp1 68\"\n");
	localcmd(";alias safedischargeoff \"temp1 69\"\n");

	localcmd(";alias tossruneoff \"temp1 78\"\n");//78
	localcmd(";alias tossruneon \"temp1 79\"\n");//79

	// undocumented debug commands
	localcmd("alias debugclient temp1 70\n");
	localcmd("alias debugoff temp1 71\n");
	localcmd("alias stuffimpulse temp1 72\n");
	localcmd("alias stuffcolor temp1 73\n");
	localcmd("alias debugcflags temp1 74\n");
	localcmd("alias debugsflags temp1 75\n");
	localcmd("alias debugcinfo temp1 76\n");
	localcmd("alias debughelp temp1 77\n");

	// admin passwords (R00k: FTE has a reserved word 'setpass', changed to setadmin)
	localcmd("alias setadmin \"temp1 80\"\n");
	localcmd("alias setadmin1 \"temp1 81\"\n");
	localcmd("alias setadmin2 \"temp1 82\"\n");
	localcmd("alias setadmin3 \"temp1 83\"\n");
	localcmd("alias setadmin4 \"temp1 84\"\n");
	localcmd("alias setadmin5 \"temp1 85\"\n");
	localcmd("alias setadmin6 \"temp1 86\"\n");
	localcmd("alias setadmin7 \"temp1 87\"\n");
	localcmd("alias setadmin8 \"temp1 88\"\n");
	localcmd("alias setadmin9 \"temp1 89\"\n");
	localcmd(";alias banned \"temp1 91\"\n");
	localcmd("alias modes \"temp1 92\"\n");
	localcmd("alias gameplay \"temp1 93\"\n");
	localcmd("alias watch \"temp1 94\"\n");
	localcmd("alias stat \"temp1 95\"\n");
	localcmd("alias misc \"temp1 96\"\n");
	localcmd("alias modhelp \"temp1 97\"\n");
	localcmd("alias shortcuts \"temp1 98\"\n");
  	//localcmd(";alias * \"temp1 1256;wait\"\n");
};

//
//  P R I N T  P I N G
// 
void(entity player) console_print_ping =
{
	 float p;

	p = floor(stof(infokey(self, INFOKEY_P_PING)));
	if (p < 1000)
		cprint(" ");
	if (p < 100)
		cprint(" ");
	if (p < 10)
		cprint(" ");
	cprint(ftos(p));
};

//
//  P I N G
//
void() console_ping =
{
	 entity player;

	cprint("Client ping times:\n");
	player = find(world, classname, "player");
	while (player)
	{
		if (player.style & CLANRING_CONNECTED)
		{
			console_print_ping(player);
			cprint(" ", player.netname, "\n");
		}
		player = find(player, classname, "player");
	}
};

//
//  S H O W  T I M E
//
//  Show the elapsed time on the server console.
//
void() console_show_time = 
{
     float h, m, s, t;
     string temp;

    h = floor(time / 3600);
    t = time - h * 3600;
    m = floor(t / 60);
    t = t - m * 60;
    s = rint(t);

    cprint("\"time = ");
    if (h > 0)
    {
        temp = ftos(h);
        cprint2(temp, ":");
        if (m < 10)
            cprint("0");
    }
    temp = ftos(m);
    cprint2(temp, ":");
    if (s < 10)
        cprint("0");
    temp = ftos(s);
    cprint2(temp, "\"\n");
};

//
//  S H O W  S T A T U S
//
//  Show the elapsed time and status on the server console.
//
void() console_show_status = 
{
     float mode;
     string szmode;

    cprint("\n");
    mode = options_get_mode();
    szmode = strings_get_mode(mode);
    cprint2(szmode, " mode\n");
    console_show_time();
    localcmd(";status;\n");
	cprint("\n");
};

//
//  S H O W  D E B U G  I N F O
//
//  Used for development.  Similar to clanring_debug_info, but prints to the
//  server console.
//
void() console_show_debug_info =
{
	 entity e;

	cprint("clients:\n");
	e = find(world, classname, "player");
	while (e)
	{
		 string temp;
		temp = ftos(e.colormap);
		if (e.style & CLANRING_CONNECTED)
			cprint4(temp, " \"", e.netname, "\" - Connected\n");
		else
			cprint4(temp, " \"", e.netname, "\" - Disconnected\n");
		e = find(e, classname, "player");
	}
};

//
//  S H O W  S C O R E
//
//  Print the time remaining and the score.
//
void() console_show_score =
{
	 string temp;//R00k moved up here

	if (!(clanring_playmode & CLANRING_MATCH_MODE))
	{
		cprint("Command valid in match mode only\n");
		return;
	}
	if (!(clanring_state & (CLANRING_MATCH_STARTED | CLANRING_MATCH_OVER)))
	{
		if (clanring_state & CLANRING_TIMER_STARTED)
		{
			 string s, pl;
			s = ftos(clanring_match_timer.count);
			pl = strings_szplural(clanring_match_timer.count);
			cprint5("Match begins in ", s, " second", pl, "\n");
		}
		else
			cprint3("Waiting for ", clanring_szteam, "s\n");
		return;
	}
	cprint("\n");
	if (clanring_state & CLANRING_MATCH_OVER)
		cprint("Match over\n");
	else
	{
		if (clanring_match_timer.lip < 0)
			cprint("Sudden death overtime\n");
		else
		{
//			 string temp;
			temp = ftos(clanring_match_timer.lip);
			cprint3("\"Time remaining:  ", temp, ":");
			        temp = ftos(clanring_match_timer.count);
        if (clanring_match_timer.count < 10)
        {
            cprint("0");
        }
        cprint2(temp, "\"\n");
		}
	}

	if (clanring_first_place != clanring_sentinel)
	{
		 string score;
		score = ftos(clanring_first_place.frags);
		temp = strings_szplural(clanring_first_place.frags);
		cprint8("\"", clanring_szthe, clanring_first_place.netname, "\" has ", score, " frag", temp, "\n");
	}
	if (clanring_second_place != clanring_sentinel)
	{
		score = ftos(clanring_second_place.frags);
		temp = strings_szplural(clanring_second_place.frags);
		cprint8("\"", clanring_szthe, clanring_second_place.netname, "\" has ", score, " frag", temp, "\n");
	}
	cprint("\n");
};

//
//  L I S T  G H O S T S
//
void() console_list_ghosts =
{
	 entity e;
	e = find(world, classname, "clanring_ghost");
   if (!e)
    {
        cprint("There are no ghosts\n");
        return;
    }
    cprint("\n");
	if (teamplay)
		cprint("\" code |    team    | frags |      name\"\n");
	else
		cprint("\" code |   colour   | frags |      name\"\n");
    cprint("------+------------+-------+-----------------\n");
    while (e)
    {
         string num, szTeam, pad;
         float frag;
        num = ftos(e.count);
        cprint3("\"  ", num, "  | ");
    
        szTeam = strings_get_teamname2(e.height);
        if (e.owner.owner == e)
            frag = e.owner.frags;
        else
            frag = e.frags;
        if (frag < -99)
            pad = " | ";
        else if (frag < -9)
            pad = " |  ";
        else if (frag < 0)
            pad = " |   ";
        else if (frag < 10)
            pad = " |    ";
        else if (frag < 100)
            pad = " |   ";
        else
            pad = " |  ";
        num = ftos(frag);
        if (e.owner.owner == e)
            cprint6(szTeam, pad, num, "  | ", e.owner.netname, "\"\n");
        else
            cprint4(szTeam, pad, num, "  | Disconnected\"\n");
    
        e = find(e, classname, "clanring_ghost");
    }
    cprint("\n");
};

//
//  S H O W  K I L L S T A T S
//
void() console_show_killstats =
{
	 entity player;
	 float c;

	c = 16;//Workaround for lagout players corrupting the link list...
	
	cprint("\"------------\"\n");
	cprint("\" Kill Stats \"\n");
	cprint("\"------------\"\n");
	cprint("\" frags | enemies | self | teammates | killed | dtk | dgv |     name\"\n");
	cprint(  "-------+---------+------+-----------+--------+-----+-----+-----------------\n");

	if (mode_is_arena())
	{
		if (boss.next_team)
			player = boss.next_team.next_player;
		else
			player = world;
	}
	else
	{
		player = clanring_sentinel.next_player;
	}

	while (player)
	{
		if (c < 1)
			break;
		cprint("\"  ");
		utils_cprint_int3(player.frags);
		cprint("  |   ");
		utils_cprint_int3(((player.true_kills + player.mangle_x) + player.mangle_y));
		cprint("   | ");
		utils_cprint_int3(player.mangle_x);
		cprint("  |    ");
		utils_cprint_int3(player.mangle_y);
		cprint("    |  ");
		utils_cprint_int3(player.mangle_z);
		cprint("   |");
		utils_cprint_damage(player.dmg_taken);   
		cprint("|");
		utils_cprint_damage(player.dmg_given);      		
		cprint3("| ", player.netname, "\"\n");

		if (mode_is_arena())
		{
			if (player.next_player)
				player = player.next_player;
			else if (boss.next_team)
				player = boss.next_team.next_player;
			else
				player = world;
		}
		else
		{
			player = player.next_player;
		}

		c = c - 1;
	}
	cprint("\n");
};

//
//  P R I N T  P E R C E N T 4
//
//  Helper function for console_show_efficiency.  Prints the percentage
//  100 * (frac / tot) as a 4 character integer, or N/A if tot = 0.
//
void(float frac, float tot) console_print_percent4 =
{
    if (tot)
    {
         float n;
         string temp;

        n = floor(100 * frac / tot);
        if (n < 100)
            cprint(" ");
        if (n < 10)
            cprint(" ");
        temp = ftos(n);
        cprint2(temp, "%");
    }
    else
        cprint("N/A ");
};

//
// CRMOD
//  S H O W  Q U A D S T A T S
//		by Paul Baker
//
void() console_show_quadstats =
{
	 entity player, pteam;
	 float useteams;
//	 string teamname;

	if ((clanring_state & (CLANRING_MATCH_STARTED | CLANRING_MATCH_OVER)) && teamplay)
		useteams = TRUE;
	else
		useteams = FALSE;

	cprint("\"------------\"\n");
	cprint("\" Quad Stats \"\n");
	cprint("\"------------\"\n");

	cprint("\" quads | efficiency | enemy | self  | teammates |      name\"\n");
	cprint("-------+------------+-------+-------+-----------+-----------------\n");
	player = clanring_sentinel.next_player;
	pteam = player.next_team;

	while (player)
	{
		cprint("\"  ");
		utils_cprint_int3 (player.clanring_qdwep_z);
		cprint("  |    ");
		console_print_percent4 (player.clanring_qdwep_x, player.clanring_qdwep_y);
		cprint("    |  ");
		utils_cprint_int3 (player.clanring_qdkill_x);
		cprint("  |  ");
		utils_cprint_int3 (player.clanring_qdkill_z);
		cprint("  |    ");
		utils_cprint_int3 (player.clanring_qdkill_y);
		cprint3("    | ", player.netname, "\"\n");
		player = player.next_player;
		if ((useteams && (player.next_team != pteam)))
		{
			cprint("\" [");
			utils_cprint_int3 (pteam.dest2_x);
			cprint3("] |            |       |       |           | ", pteam.netname, "\"\n");
			pteam = player.next_team;
		}
	}
	cprint("\n");
};

void() console_show_pentstats =
{
	 entity player, pteam;
	 float useteams;

	if ((clanring_state & (CLANRING_MATCH_STARTED | CLANRING_MATCH_OVER)) && teamplay)
		useteams = TRUE;
	else
		useteams = FALSE;

	cprint("\"------------\"\n");
	cprint("\" Pent Stats \"\n");
	cprint("\"------------\"\n");

	cprint("\" pents | efficiency | enemy | teammates |      name\"\n");
	cprint("-------+------------+-------+-----------+-----------------\n");
	player = clanring_sentinel.next_player;
	pteam = player.next_team;

	while (player)
	{
		cprint("\"  ");
		utils_cprint_int3 (player.clanring_ptwep_z);
		cprint("  |    ");
		console_print_percent4 (player.clanring_ptwep_x, player.clanring_ptwep_y);
		cprint("    |  ");
		utils_cprint_int3 (player.clanring_ptkill_x);
		cprint("  |    ");
		utils_cprint_int3 (player.clanring_ptkill_y);
		cprint3("    | ", player.netname, "\"\n");
		player = player.next_player;
		if ((useteams && (player.next_team != pteam)))
		{
			cprint("\" [");
			utils_cprint_int3 (pteam.dest2_y);
			cprint3("] |            |       |           | ", pteam.netname, "\"\n");
			pteam = player.next_team;
		}
	}
	cprint("\n");
};

//
//  S H O W  B A D S T A T S
//
void() console_show_badstats =
{
	 entity player;
	 float tot_enemy;
	 float tot_done;

	cprint("\"------------\"\n");
	cprint("\" Bad Stats \"\n");
	cprint("\"------------\"\n");

	cprint("\" paks | self | team | lava | axed | fall |      name\"\n");
	cprint("\"------+------+------+------+------+------+----------------\"\n");
	player = clanring_sentinel.next_player;
	while (player)
	{
		tot_enemy = player.dest2_x + player.dest2_y + player.dest2_z + player.dest_y;
		tot_done = tot_enemy + player.clanring_badstats_y + player.clanring_badstats_z;
		cprint("\"  ");
		utils_cprint_int3(player.clanring_badstats_x);
		cprint(" | ");
		console_print_percent4(player.clanring_badstats_y, tot_done);
		cprint(" | ");
		console_print_percent4(player.clanring_badstats_z, tot_done);
		cprint(" | ");
		utils_cprint_int3(player.clanring_badstats2_x);  // lava deaths
		cprint(" | ");
		utils_cprint_int3(player.clanring_badstats2_y);  // axe deaths
		cprint(" | ");
		utils_cprint_int3(player.clanring_badstats2_z);  // fall deaths
		cprint(" | ");
		cprint2(player.netname, "\"\n");
		player = player.next_player;
	}
	cprint("\n");
};

//
//  S H O W  E F F I C I E N C Y
//
void() console_show_efficiency =
{
	 entity player;
	 float tot_fired, tot_done;
	float fpm;
	
	cprint("\"------------------\"\n");
	cprint("\" Efficiency Stats \"\n");
	cprint("\"------------------\"\n");

	cprint("\" bullets | nails | rockets | lightning | total | fpm |      name\"\n");
	cprint("---------+-------+---------+-----------+-------+-----+-----------------\n");
	player = clanring_sentinel.next_player;
	while (player)
	{
		cprint("\"   ");
		console_print_percent4(player.dest2_x, player.dest1_x);
		cprint("  |  ");
		console_print_percent4(player.dest2_y, player.dest1_y);
		cprint(" |   ");
		console_print_percent4(player.dest_y, player.dest_x);
		cprint("  |    ");
		console_print_percent4(player.dest2_z, player.dest1_z);
		cprint("   |  ");
		tot_fired = player.dest1_x + player.dest1_y + player.dest1_z + player.dest_x;
		tot_done = player.dest2_x + player.dest2_y + player.dest2_z + player.dest_y;
		console_print_percent4(tot_done, tot_fired);
		
		// Calculate fpm (frags per minute)
		if (player.join_time > 0)
			fpm = player.true_kills * 60 / (clanring_sentinel.matchTime - player.join_time);
		else
			fpm = 0;
			
		cprint(" | ");
		if (fpm < 10)
			cprint(" ");
		cprint(sprintf("%.1f", fpm));
		cprint3(" | ", player.netname, "\"\n");
		player = player.next_player;
	}
	cprint("\n");
};

//
//  S H O W  F L A G S T A T S
//
void() console_show_fstats =
{
	 entity player;

	player = find(world, classname, "player");//flagstats in normal mode too

	cprint("\"------------\"\n");
	cprint("\" Flag Stats \"\n");
	cprint("\"-------------------------------------------\"\n");
	cprint("\"flag |  time  |cap|  best  |     name      \"\n");
	cprint("\"-----+--------+---+--------+---------------\"\n");

	while (player)
	{
		if (!(player.style & CLANRING_OBSERVER))
		{
			cprint("\"  ");
			utils_cprint_int3(player.fpickups);
			cprint("|");
			utils_cprint_time(player.fctime);
			cprint("|");
			utils_cprint_int3(player.fcaptures);
			cprint("|");
			utils_cprint_time(player.captime);
			cprint3("| ", player.netname, "\"\n");
		}
		player = find(player, classname, "player");
	}
	cprint("\n");
	cprint("\"-----------------------------------\"\n");
	cprint("\"def|rtn|fcd|fca|fck|     name      \"\n");
	cprint("\"---+---+---+---+---+---------------\"\n");

	while (player)
	{
		if (!(player.style & CLANRING_OBSERVER))
		{
			cprint("\" ");
			cprint("|");
			utils_cprint_int3(player.fdefenses);
			cprint("|");
			utils_cprint_int3(player.freturns);
			cprint("|");
			utils_cprint_int3(player.fcdefenses);
			cprint("|");
			utils_cprint_int3(player.fcassists);
			cprint("|");
			utils_cprint_int3(player.fcfrags);
			cprint3("| ", player.netname, "\"\n");
		}
		player = find(player, classname, "player");
	}
	cprint("\n");
};

//
//  S H O W  S T A T S
//
//  Summary: show kill and weapon efficiency for each player.
//
void() console_show_stats =
{
	 entity player;
	 float wfrac, wtot, kfrac, ktot, useteams;
	 string teamname;

	if ((clanring_state & CLANRING_MATCH_STARTED) && teamplay)
		useteams = TRUE;
	else
		useteams = FALSE;
	
	cprint("\"------------\"\n");
	cprint("\" Skill Stats \"\n");
	cprint("\"------------\"\n");

	if (useteams)
	{
		cprint("\"    team    | kill | weapon |      name\"\n");
		cprint("------------+------+--------+-----------------\n");
	}
	else
	{
		cprint("\" kill | weapon |      name\"\n");
		cprint("------+--------+-----------------\n");
	}
	player = clanring_sentinel.next_player;

	while (player)
	{
		if (useteams)
		{
			teamname = strings_get_teamname2 (player.height);
			cprint3("\" ", teamname, " | ");
		}
		else
			cprint("\" ");

		kfrac = player.frags + player.mangle_x + player.mangle_y;
		ktot = kfrac + player.mangle_x + player.mangle_y + player.mangle_z;
		wtot = player.dest1_x + player.dest1_y + player.dest1_z + player.dest_x;
		wfrac = player.dest2_x + player.dest2_y + player.dest2_z + player.dest_y;
		console_print_percent4(kfrac, ktot);
		cprint(" |  ");
		console_print_percent4(wfrac, wtot);
		cprint3("  | ", player.netname, "\"\n");
		player = player.next_player;
	}
	cprint("\n");
};

//
//  F O R M A T  V E C T O R
//
//  prints xx:yy:zz to self
//
void(vector v) console_format_vector =
{
	 string s;

	cprint("| ");
	if (v_x < 10)
		cprint(" ");
	s = ftos(v_x);
	cprint2(s, " : ");
	if (v_y < 10)
		cprint(" ");
	s = ftos(v_y);
	cprint2(s, " : ");
	if (v_z < 10)
		cprint(" ");
	s = ftos(v_z);
	cprint2(s, " ");
};

//
//  S H O W  T E A M  S T A T S
//
void() console_show_teamstats =
{
	 entity pteam;
	 string s;

	if (!(teamplay && (clanring_playmode & CLANRING_MATCH_MODE)))
	{
		cprint("Teamstats valid in match mode only\n");
		return;
	}
	if (!clanring_sentinel.next_team)
	{
		cprint("No teams\n");
		return;
	}

	cprint("\"------------\"\n");
	cprint("\" Team Stats \"\n");
	cprint("\"------------\"\n");

	cprint("\"               ");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		s = strings_get_teamname2(pteam.height);
		cprint3("|  ", s, "  ");
		pteam = pteam.next_team;
	}
	cprint("\"\n");
	cprint("\"---------------");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		cprint("+--------------");
		pteam = pteam.next_team;
	}
	cprint("\"\n");
	cprint("\"Q : 666 : Ring ");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		console_format_vector(pteam.dest2);
		pteam = pteam.next_team;
	}
	cprint("\"\n");
	cprint("\"RL : LG : GL   ");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		console_format_vector (pteam.dest1);
		pteam = pteam.next_team;
	}
	cprint("\"\n");
	cprint("\"SNG : NG : MH  ");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		console_format_vector(pteam.pos1);
		pteam = pteam.next_team;
	}
	cprint("\"\n");
	cprint("\"RA : YA : GA   ");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		console_format_vector(pteam.dest);
		pteam = pteam.next_team;
	}
	cprint("\"\n");
	cprint("\"+RLPak : -RLPak");
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		cprint("|  ");
		s = ftos(pteam.mangle_y);
		if (pteam.mangle_y < 10)
			cprint(" ");
		cprint3("+", s, "   ");
		s = ftos(pteam.mangle_z);
		if (pteam.mangle_z < 10)
			cprint(" ");
		cprint3("-", s, "   ");
		pteam = pteam.next_team;
	}
	cprint("\"\n");
	cprint("\"Control        ");
	pteam = clanring_sentinel.next_team;

	while (pteam)
	{
		 float f;
		 float control;
		control = 100 * pteam.mangle_x / clanring_sentinel.cnt;
		f = floor(control);
		s = ftos(f);
		cprint2("ü  %", s);
		f = floor((control - f) * 10);
		s = ftos(f);
		cprint3(".", s, " ");
		if (control < 10)
			cprint(" ");
		pteam = pteam.next_team;
	}

	cprint("\"\n");
	cprint("\n");
};

//
//  A U T O D U M P
//
//  Dump statistics if server has autostats enabled.
//
void() console_autodump =
{
	 string temp;
	
//	if ((clanring_playmode & CLANRING_CONSOLE_STATS))
	{
		cprint("\n");
//		cprint3("\"Clanring v", clanring_version_number, " -Match Statistics-\"\n");
		cprint("- CRMod Match Statistics - \n");		
		//Stats header for SQL parser
		/*
		Map: DM3
		Type: 4v4
		Timelimit: 20
		*/
		
		cprint3("\"Map: ",mapname,"\"\n");

		temp = ftos(stats_matchtype);
		cprint5("\"Type: ", temp, "v", temp,"\"\n");

		temp = ftos(stats_timelimit);
		cprint3("\"Timelimit: ", temp,"\"\n");
		
		cprint("\n");
		
		console_show_stats ();

		if (!(clanring_playmode & CLANRING_NO_QUAD))//R00k -added-
			console_show_quadstats ();

		if (!(clanring_playmode & CLANRING_NO_PENT))
			console_show_pentstats ();

		if ((clanring_playmode & CLANRING_MATCH_MODE) && (teamplay == 2))
			console_show_badstats ();

		console_show_efficiency ();
		console_show_killstats ();		
		console_show_teamstats ();
		
		if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
			console_show_fstats ();
		
		//json_post_and_maybe_save(MATCHPOST_DEFAULT_PRETTY, 1, "json/match_last.json", MATCHPOST_DEFAULT_DEFERRED);
	}
};

//
//  C O M M A N D S
//
//  Show a list of valid commands (dedicated only)
//
void() console_commands =
{
	cprint("\n");
	cprint3("\"Clanring v", clanring_version_number, " console commands:\"\n");
	cprint("\n");
	cprint("\"s      - view server status             settings  - view server settings      \"\n");
	cprint("\"vinfo  - version information            ghostlist - view list of ghosts       \"\n");
	cprint("\"sping  - approximate client pings       setadmin  - set admin password (use 'skill')\"\n");
	cprint("\"time   - time elapsed on current map    maxteams  - set maxteams (use 'skill')\"\n");
	cprint("\"score  - match score/time remaining     otset     - set overtime (use 'skill')\"\n");
	cprint("\"admins - list administrators\"\n");
	cprint("\n");
	cprint("\"stats     killstats     efficiency      quadstats     badstats     teamstats\"\n");
	cprint("\n");
	cprint("\"settings:\"\n");
	cprint("\n");
	cprint("\"normal              practice            match               deathmatch\"\n");
	cprint("\"nopractice          highgibs            lowgibs             nogibs\"\n");
	cprint("\"quadon              quadoff             penton              pentoff\"\n");
	cprint("\"ringon              ringoff             freshspawnon        freshspawnoff\"\n");
	cprint("\"faststarton         faststartoff        autopauseon         autopauseoff\"\n");
	cprint("\"modevoteon          modevoteoff         safepracticeon      safepracticeoff\"\n");
	cprint("\"obitson             obitsoff            autostatson         autostatsoff\"\n");
	cprint("\n");
};

//
//  D E B U G  C L I E N T
//
//  Enter debug mode for the client indicated by cvar 'skill'.
//
void() console_debug_client =
{
	 float id;
	 entity client;

	id = cvar ("skill");
	client = find(world, classname, "player");
	while (client)
	{
		if (client.colormap == id)
		{
			clanring_debug_client = client;
			cprint3("\"debugging ", client.netname, "\"\n");
			return;
		}
		client = find(client, classname, "player");
	}
	cprint("client not found\n");
};

//
//  S T U F F  I M P U L S E
//
//  Stuff an impulse into the console of the debug client.
//
void() console_stuff_impulse =
{
	 float temp;
	 string s;

	if (!clanring_debug_client)
	{
		cprint("No debug client\n");
		return;
	}
	temp = cvar ("skill");
	s = ftos(temp);
	stuffcmd(clanring_debug_client, "impulse ");
	stuffcmd(clanring_debug_client, s);
	stuffcmd(clanring_debug_client, "\n");
	cprint3("stuffing impulse ", s, "\n");
};

//
//  S T U F F  C O L O U R
//
//  Stuff a colour into the console of the debug client.
//
void() console_stuff_colour =
{
	 float temp;
	 string s;

	if (!clanring_debug_client)
	{
		cprint("No debug client\n");
		return;
	}
	temp = cvar ("skill");
	s = ftos(temp);
	stuffcmd(clanring_debug_client, "color ");
	stuffcmd(clanring_debug_client, s);
	stuffcmd(clanring_debug_client, "\n");
	cprint3("stuffing color ", s, "\n");
};

//
//  C L I E N T  F L A G S
//
void() console_client_flags =
{
	if (!clanring_debug_client)
	{
		cprint("No debug client\n");
		return;
	}
	cprint("\n");
	cprint3("\"Client flags for ", clanring_debug_client.netname, ":\"\n");
	cprint("\n");
	if (clanring_debug_client.style & CLANRING_NEW_CLIENT)
		cprint("CLANRING_NEW_CLIENT\n");
	if (clanring_debug_client.style & CLANRING_ADMINISTRATOR)
		cprint("CLANRING_ADMINISTRATOR\n");
	if (clanring_debug_client.oflags & OBSERVER_POP_FORWARD)
		cprint("OBSERVER_POP_FORWARD\n");
	if (clanring_debug_client.style & CLANRING_READY)
		cprint("CLANRING_READY\n");
	if (clanring_debug_client.style & CLANRING_YES)
		cprint("CLANRING_YES\n");
	if (clanring_debug_client.style & CLANRING_HEADS_UP)
		cprint("CLANRING_HEADS_UP\n");
	if (clanring_debug_client.style & CLANRING_SETTING_OPTIONS)
		cprint("CLANRING_SETTING_OPTIONS\n");
	if (clanring_debug_client.style & CLANRING_MOTD)
		cprint("CLANRING_MOTD\n");
	if (clanring_debug_client.style & CLANRING_OK_TO_SHOOT)
		cprint("CLANRING_OK_TO_SHOOT\n");
	if (clanring_debug_client.style & CLANRING_KICK_CONFIRM)
		cprint("CLANRING_KICK_CONFIRM\n");
	if (clanring_debug_client.style & CLANRING_CONFIRM_LEAVE)
		cprint("CLANRING_CONFIRM_LEAVE\n");
	if (clanring_debug_client.style & CLANRING_CONNECTED)
		cprint("CLANRING_CONNECTED\n");
	if (clanring_debug_client.style & CLANRING_FOUND_BINDINGS)
		cprint("CLANRING_FOUND_BINDINGS\n");
	if (clanring_debug_client.style & CLANRING_SMART_WEAPON)
		cprint("CLANRING_SMART_WEAPON\n");
	if (clanring_debug_client.style & CLANRING_OBSERVER)
		cprint("CLANRING_OBSERVER\n");
	if (clanring_debug_client.style & CLANRING_SCOREBOARD)
		cprint("CLANRING_SCOREBOARD\n");
	if (clanring_debug_client.style & CLANRING_NO_POST_THINK)
		cprint("CLANRING_NO_POST_THINK\n");
	if (clanring_debug_client.style & CLANRING_WINQUAKE)
		cprint("CLANRING_WINQUAKE\n");
	if (clanring_debug_client.style & CLANRING_GLQUAKE)
		cprint("CLANRING_GLQUAKE\n");
	if (clanring_debug_client.style & CLANRING_CONSOLE_STATS)
		cprint("CLANRING_CONSOLE_STATS\n");

		// CRMOD - change to oflags	
	cprint("\n");
	cprint3("\"Client Observer Flags for ", clanring_debug_client.netname, ":\"\n");
	cprint("\n");
	if (clanring_debug_client.oflags & OBSERVER_WALK)
		cprint("OBSERVER_WALK\n");
	if (clanring_debug_client.oflags & OBSERVER_FLY)
		cprint("OBSERVER_FLY\n");
	if (clanring_debug_client.oflags & OBSERVER_CHASE)
		cprint("OBSERVER_CHASE\n");
	if (clanring_debug_client.oflags & OBSERVER_DEMO)
		cprint("OBSERVER_DEMO\n");
	if (clanring_debug_client.oflags & OBSERVER_CAMERA)
		cprint("OBSERVER_CAMERA\n");
	if (clanring_debug_client.oflags & OBSERVER_AUTO)
		cprint("OBSERVER_AUTO\n");
	if (clanring_debug_client.oflags & OBSERVER_TOURNEY)
		cprint("OBSERVER_TOURNEY\n");
	if (clanring_debug_client.oflags & OBSERVER_GO_AUTO)
		cprint("OBSERVER_GO_AUTO\n");
	if (clanring_debug_client.oflags & OBSERVER_COMMENTARY)
		cprint("OBSERVER_COMMENTARY\n");
	cprint("\n");
};

//
//  S E R V E R  F L A G S
//
void() console_server_flags =
{
    cprint("\n");
	cprint("Server flags:\n");
    cprint("\n");

	// playmode flags
	if (clanring_playmode & CLANRING_MATCH_MODE)
		cprint("CLANRING_MATCH_MODE\n");
	if (clanring_playmode & CLANRING_PRACTICE_MODE)
		cprint("CLANRING_PRACTICE_MODE\n");
	if (clanring_playmode & CLANRING_SERVER_INITIALIZED)
		cprint("CLANRING_SERVER_INITIALIZED\n");
	if (clanring_playmode & CLANRING_NO_GIBS)
		cprint("CLANRING_NO_GIBS\n");
	if (clanring_playmode & CLANRING_LOW_GIBS)
		cprint("CLANRING_LOW_GIBS\n");
	if (clanring_playmode & CLANRING_NO_QUAD)
		cprint("CLANRING_NO_QUAD\n");
	if (clanring_playmode & CLANRING_NO_PENT)
		cprint("CLANRING_NO_PENT\n");
	if (clanring_playmode & CLANRING_NO_RING)
		cprint("CLANRING_NO_RING\n");
	if (clanring_playmode & CLANRING_MODE_VOTE)
		cprint("CLANRING_MODE_VOTE\n");
	if (clanring_playmode & CLANRING_NO_SPOOGE)
		cprint("CLANRING_NO_SPOOGE\n");
	if (clanring_playmode & CLANRING_EXTENDED_OBITS)
		cprint("CLANRING_EXTENDED_OBITS\n");
	if (clanring_playmode & CLANRING_CONSOLE_INITIALIZED)
		cprint("CLANRING_CONSOLE_INITIALIZED\n");
	// if (clanring_playmode & CLANRING_FAST_START)
	// 	cprint("CLANRING_FAST_START\n");
	if (clanring_playmode & CLANRING_AUTO_PAUSE)
		cprint("CLANRING_AUTO_PAUSE\n");

    cprint("\n");

	// state flags
	if (clanring_state & CLANRING_TIMER_STARTED)
		cprint("CLANRING_TIMER_STARTED\n");
	if (clanring_state & CLANRING_MATCH_STARTED)
		cprint("CLANRING_MATCH_STARTED\n");
	if (clanring_state & CLANRING_MATCH_PAUSED)
		cprint("CLANRING_MATCH_PAUSED\n");
	if (clanring_state & CLANRING_MATCH_OVER)
		cprint("CLANRING_MATCH_OVER\n");
	if (clanring_state & CLANRING_MATCH_WAIT)
		cprint("CLANRING_MATCH_WAIT\n");
	if (clanring_state & CLANRING_KICKING)
		cprint("CLANRING_KICKING\n");
	if (clanring_state & CLANRING_NO_PRACTICE)
		cprint("CLANRING_NO_PRACTICE\n");
	if (clanring_state & CLANRING_UNPAUSING)
		cprint("CLANRING_UNPAUSING\n");
	if (clanring_state & CLANRING_AUTO_PAUSED)
		cprint("CLANRING_AUTO_PAUSED\n");
	if (clanring_state & CLANRING_DELAYED_AUTOSS)
		cprint("CLANRING_DELAYED_AUTOSS\n");

    cprint("\n");
};

//
//  D E B U G  H E L P 
//
void() console_debug_help =
{
	cprint("\n");
	cprint("\"debugclient  - select client (use 'skill')\"\n");
	cprint("\"debugoff     - deselect client\"\n");
	cprint("\"stuffimpulse - stuff impulse (use 'skill')\"\n");
	cprint("\"stuffcolor   - stuff colour (use 'skill')\"\n");
	cprint("\"debugcflags  - show client flags\"\n");
	cprint("\"debugcinfo   - show client info\"\n");
	cprint("\"debugsflags  - show server flags\"\n");
	cprint("\n");
};

//
//  C L I E N T  I N F O 
//
void() console_client_info =
{
	 string temp;

	if (!clanring_debug_client)
	{
		cprint("No debug client\n");
		return;
	}
	cprint("\n");
	temp = fnstrings_function (clanring_debug_client.think);
	cprint3("\"think     = ", temp, "\"\n");
	temp = ftos(clanring_debug_client.nextthink);
	cprint3("\"nextthink = ", temp, "\"\n");
	temp = ftos(time);
	cprint3("\"current time = ", temp, "\"\n");
	cprint("\n");
};

//
//  V E R S I O N  I N F O
//
void() console_version_info =
{
	cprint("\n");
	cprint3("\"", clanring_version_info, "\"\n");
	cprint("\n");
};

//
//  G E T  O R I G I N
//
//  Return the vector 'scr_ofsx scr_ofsy scr_ofsz'
//
vector () console_get_origin =
{
     vector v;

    v_x = stof(argv(1));//cvar("scr_ofsx");
    v_y = stof(argv(2));//cvar("scr_ofsy");
    v_z = stof(argv(3));//cvar("scr_ofsz");
    return v;
};

//
//  G E T  A N G L E S
//
//  Return the angles vector 'v_ipitch_level v_iyaw_level v_iroll_level'
//
vector () console_get_angles =
{
     vector v;

    v_x = stof(argv(1));
    v_y = stof(argv(2));
    v_z = stof(argv(3));
    return v;
};

//
//  M A K E  E N T I T Y
//
//  Create a new entity using the origin and angle specified in a
//  configuration file.
//
void(string name, float angleflags) console_make_entity =
{
     entity newent;
     string temp;

    // create entity
    newent = spawn();
    newent.owner = world;
    newent.solid = SOLID_NOT;
    newent.movetype = MOVETYPE_NONE;
    newent.takedamage = DAMAGE_NO;
    newent.fixangle = TRUE;
    newent.classname = name;
    newent.origin = console_get_origin();
    newent.angles = console_get_angles();
	newent.style = CLANRING_MANUAL_SPAWN;
    if (!(angleflags & CONSOLE_ENT_PITCH))
        newent.angles_x = 0;
    if (!(angleflags & CONSOLE_ENT_YAW))
        newent.angles_y = 0;
    if (!(angleflags & CONSOLE_ENT_ROLL))
        newent.angles_z = 0;

    temp = vtos(newent.origin);
    cprint4(name, " created at ", temp, ", ");
    temp = vtos(newent.angles);
    cprint2(temp, "\n");
    if (name == "clanring_camera")
    {
    	newent.nextthink = CLANRING_NEGINF;
    	newent.think = auto_camera_think;
		newent.next_camera = clanring_sentinel.next_camera;
		clanring_sentinel.next_camera = newent;
    }
};

//
//  K I L L  E N T I T Y
//
//  Search for the entity of the given type at origin specified in the
//  configuration file; kill it if it exists.
//
void(string name) console_kill_entity =
{
	 vector location;
	 entity e;
	 string temp;

	location = console_get_origin ();
	temp = vtos (location);

	e = find(world, classname, name);
	while (e)
	{
		if (e.style != CLANRING_MANUAL_SPAWN)
		{
			 vector v;
			v = e.origin - location;
			if (vlen(v) < 20)
			{
				                cprint5("removed ", name, " at ", temp, ", ");
                temp = vtos(e.angles);
                cprint2(temp, "\n");
				remove(e);
				return;
			}
		}
		e = find(e, classname, name);
	}
	cprint5("\"killentity: couldn't find", name, " at ", temp, "\"\n");
};

//
//  K I L L  I T E M
//
//  Kill any respawnable item at the specified location.
//
void() console_kill_item =
{
	 vector v;
	 float dz;

	if (self.style == CLANRING_MANUAL_SPAWN)
		return;

	v = (self.origin - console_origin);
	dz = fabs(v_z);
	v_z = 0;
	if (vlen(v) < 20 && dz < 100)
	{
		 string temp;
		temp = vtos(self.origin);
		cprint5("removed ", self.classname, " at ", temp, "\n");
		remove(self);
	}
};

//
//  M A K E  I T E M
//
//  Create a new item, specified by skill
//
void() console_make_item = 
{
	string item;
	entity oself;
	string temp;

	item = argv(4);//cvar("skill");
	oself = self;

    // create entity
    self = spawn();
    self.owner = world;
    self.takedamage = DAMAGE_NO;
    self.fixangle = TRUE;
    self.origin = console_origin;
    self.angles = '0 0 0';
	self.style = CLANRING_MANUAL_SPAWN;

/*	if (item == "item_health")
	{
		self.classname = "item_health";
		if (item == 1)
			self.spawnflags = H_ROTTEN;
		else if (item == 3)
			self.spawnflags = H_MEGA;
		item_health();
	}
	else if (item == 4)
	{
		self.classname = "item_armor1";
		item_armor1();
	}
	else if (item == 5)
	{
		self.classname = "item_armor2";
		item_armor2();
	}
	else if (item == 6)
	{
		self.classname = "item_armorInv";
		item_armorInv();
	}
	else if (item >= 7 && item <= 14)
	{
		if (!(item & 1))
			self.spawnflags = WEAPON_BIG2;
		
		if (item < 9)
		{
			self.classname = "item_shells";
			item_shells();
		}
		else if (item < 11)
		{
			self.classname = "item_spikes";
			item_spikes();
		}
		else if (item < 13)
		{
			self.classname = "item_rockets";
			item_rockets();
		}
		else
		{
			self.classname = "item_cells";
			item_cells();
		}
	}
	else if (item == 15)
	{
		self.classname = "weapon_supershotgun";
		weapon_supershotgun();
	}
	else if (item == 16)
	{
		self.classname = "weapon_nailgun";
		weapon_nailgun();
	}
	else if (item == 17)
	{
		self.classname = "weapon_supernailgun";
		weapon_supernailgun();
	}
	else if (item == 18)
	{
		self.classname = "weapon_grenadelauncher";
		weapon_grenadelauncher();
	}
	else if (item == 19)
	{
		self.classname = "weapon_rocketlauncher";
		weapon_rocketlauncher();
	}
	else if (item == 20)
	{
		self.classname = "weapon_lightning";
		weapon_lightning();
	}
	else if (item == 21)
	{
		self.classname = "item_artifact_envirosuit";
		item_artifact_envirosuit();
	}
	else if (item == 22)
	{*/
		self.classname = "item_artifact_super_damage";
		item_artifact_super_damage();
/*	}
	else if (item == 23)
	{
		self.classname = "item_artifact_invulnerability";
		item_artifact_invulnerability();
	}
	else if (item == 24)
	{
		self.classname = "item_artifact_invisibility";
		item_artifact_invisibility();
	}
	else
	{
		remove(self);
		self = oself;
		return;
	}
*/
    temp = vtos(self.origin);
    cprint4(self.classname, " created at ", temp, "\n");

	self = oself;
};

//
//  C H A N G E  I T E M
//
//  Kill any respawnable item at the specified location and make a new one
//  in its place.
//
void() console_change_item = 
{
	 vector v;
	 string temp;
	 float dz;

	if (self.style == CLANRING_MANUAL_SPAWN)
		return;

	v = self.origin - console_origin;
	dz = fabs(v_z);
	v_z = 0;
	if (vlen(v) < 20 && dz < 100)
	{
		console_origin = self.origin;
		temp = vtos(console_origin);
		cprint5("removed ", self.classname, " at ", temp, "\n");		
		remove(self);
		console_make_item();
	}
};

//
//  O N O F F
//
void(float val) console_onoff = 
{
	if (val)
		localcmd("on\n");
	else
		localcmd("off\n");
};

//
//  S H O W  S E T T I N G S
//
void() console_show_settings = 
{
	 float temp;
	 string sz;

	cprint("\n");

    temp = options_get_mode();
    sz = strings_get_mode(temp);
    cprint2(sz, " mode\n");

	localcmd("timelimit\n");
	localcmd("fraglimit\n");
	localcmd("teamplay\n");
	localcmd("deathmatch\n");
	localcmd("pausable\n");
	localcmd("sys_ticrate\n");

	cprint("overtime: ");
	if (clanring_overtime == -1)
		localcmd("sudden death\n");
	else if (clanring_overtime == 0)
		localcmd("disabled\n");
	else 
	{
		sz = ftos(clanring_overtime);
		localcmd(sz);
		sz = strings_szplural(clanring_overtime);
		localcmd2(" minute", sz);
	}

	sz = ftos(clanring_maxteams);
	cprint3("maxteams: ", sz, "\n");

	cprint("gibs: ");
	if (clanring_playmode & CLANRING_NO_GIBS)
		localcmd("off\n");
	else if (clanring_playmode & CLANRING_LOW_GIBS)
		localcmd("low\n");
	else
		localcmd("high\n");

	cprint("safe practice: ");
	console_onoff(clanring_playmode & CLANRING_NO_SPOOGE);

	cprint("quad: ");
	console_onoff(CLANRING_NO_QUAD - (clanring_playmode & CLANRING_NO_QUAD));
	cprint("pentagram: ");
	console_onoff(CLANRING_NO_PENT - (clanring_playmode & CLANRING_NO_PENT));
	cprint("ring: ");
	console_onoff(CLANRING_NO_RING - (clanring_playmode & CLANRING_NO_RING));

	cprint("mode voting: ");
	console_onoff(clanring_playmode & CLANRING_MODE_VOTE);
	cprint("extended obituaries: ");
	console_onoff(clanring_playmode & CLANRING_EXTENDED_OBITS);
	// cprint("fast match starts: ");
	// console_onoff(clanring_playmode & CLANRING_FAST_START);
	cprint("fresh spawns: ");
	console_onoff(clanring_playmode & CLANRING_FRESH_SPAWNS);
	cprint("autopausing: ");
	console_onoff(clanring_playmode & CLANRING_AUTO_PAUSE);

	cprint("\n");
};

//
//  S E T  M A X  T E A M S
//
//  Set the maximum number of teams.
//
void(float maxteams) console_set_max_teams = 
{
	maxteams = floor(maxteams);
	if (maxteams >= 2 && maxteams <= 8)
		admin_set_maxteams(maxteams);
};

//
//  A D M I N S
//
//  List the server admins and the codes they used
//
void() console_admins =
{
	 entity e;
	 string s;
	 float found;

	found = 0;
	e = find(world, classname, "player");
	while (e)
	{
		if (e.style & CLANRING_CONNECTED && e.style & CLANRING_ADMINISTRATOR)
			found = 1;
		e = find(e, classname, "player");
	}
	if (!found)
	{
		cprint("There are no administrators\n");
		return;
	}
	cprint("\n");
	cprint("\" Code |      Name\"\n");
	cprint("\"------+-----------------\"\n");
	e = find(world, classname, "player");
	while (e)
	{
		if (((e.style & CLANRING_CONNECTED) && (e.style & CLANRING_ADMINISTRATOR)))
		{
			s = ftos(e.clanring_hack_count);
			cprint5("\"   ", s, "  | ", e.netname, "\"\n");
		}
		e = find(e, classname, "player");
	}
	cprint("\n");
};

//
//  C O M M A N D
//
//  Interpret a console command.  Called from clanring_start_frame.
//
void(float command) console_command =
{
	 float arg;

     dprint(sprintf("%s\n", ftos(command)));

	if (command >= 20 && command <= 48)
	{
		arg = cvar("skill");
		cvar_set("skill", "0");
		if (clanring_state & CLANRING_IGNORE_CONSOLE)
		{
			return;
		}
	}

	if (command >= 80 && command <= 89)
	{
		arg = cvar("skill");
		array_password[command - 80] = arg;
		cvar_set("skill", "0");
		return;
	}

	switch(command)
	{
		case 57:
		{
			arg = cvar("skill");
			clanring_afk_check = (arg * 60);//in seconds
			cvar_set("skill", "0");
			break;
		}
		case 58:
		{
			arg = cvar("skill");
			clanring_afk_timeout = (arg * 60);
			cvar_set("skill", "0");
			break;
		}
// immediate mode commands
		case  1: console_ping();			break;
		case  2: console_show_time();		break;
		case  3: console_show_status();		break;	
		case  4: console_show_debug_info();	break;
		case  5: console_show_score();		break;
		case  6: console_list_ghosts();		break;
		case  7: console_show_killstats();	break;
		case  8: console_show_efficiency();	break;
		case  9: console_show_stats();		break;
		case  10: console_commands();		break;
		case  11: console_version_info();	break;

		case 12:
		case 13:
		case 14: console_show_pentstats();	break;
		case 15:
		{
			votables_request_set_gametype_mode_map(-1, command - 12, 0);
			break;
		}
		case 16: console_show_quadstats();	break;
		case 17: console_show_settings();	break;
		case 18: console_show_badstats();	break;
		case 19: console_show_teamstats();	break;
// config file commands
		case 20:
		{
			if (!(clanring_playmode & CLANRING_NO_SPOOGE))
				utils_toggle_sflag (CLANRING_NO_SPOOGE, "Safe practice mode");
			break;
		}
		case 21:
		{
			if (clanring_playmode & CLANRING_NO_SPOOGE)
				utils_toggle_sflag (CLANRING_NO_SPOOGE, "Safe practice mode");
			break;
		}
		case 22:
		case 23:
		case 24:
		{
			votables_request_set_gibs(command - 22);
			break;
		}
		case 25:
		{
			if (clanring_playmode & CLANRING_NO_QUAD)
				votables_set_quad ();
			break;
		}
		case 26:		
		{
			if (!(clanring_playmode & CLANRING_NO_QUAD))
				votables_set_quad ();
			break;
		}
		case 27:
		{
			if (clanring_playmode & CLANRING_NO_PENT)
				votables_set_pent ();
			break;			
		}
		case 28:
		{
			if (!(clanring_playmode & CLANRING_NO_PENT))
				votables_set_pent ();
			break;
		}
		case 29:
		{
			if (clanring_playmode & CLANRING_NO_RING)
				votables_set_ring ();
			break;
		}
		case 30:
		{
			if (!(clanring_playmode & CLANRING_NO_RING))
				votables_set_ring ();
			break;
		}
		case 31:
		{
			if (!(clanring_playmode & CLANRING_MODE_VOTE))
				utils_toggle_sflag (CLANRING_MODE_VOTE, "Mode voting");
			break;
		}
		case 32:
		{
			if (clanring_playmode & CLANRING_MODE_VOTE)
				utils_toggle_sflag (CLANRING_MODE_VOTE, "Mode voting");
			break;
		}
		case 33:
		{
			if (!(clanring_playmode & CLANRING_EXTENDED_OBITS))
				utils_toggle_sflag (CLANRING_EXTENDED_OBITS, "Extended obituaries");
			break;
		}
		case 34:
		{
			if (clanring_playmode & CLANRING_EXTENDED_OBITS)
				utils_toggle_sflag (CLANRING_EXTENDED_OBITS, "Extended obituaries");
			break;
		}
		case 36:
		{
			votables_request_set_overtime (arg);
			break;
		}
		case 37:
		{
			console_set_max_teams (arg);
			break;
		}
		case 38:
		{
			// if (!(clanring_playmode & CLANRING_FAST_START))
			// 	utils_toggle_sflag (CLANRING_FAST_START, "Fast match starts");
			break;
		}
		case 39: 
		{
			// if (clanring_playmode & CLANRING_FAST_START)
			// 	utils_toggle_sflag (CLANRING_FAST_START, "Fast match starts");
			break;
		}
		case 40:
		case 41:
		{
			break;//console_fresh_spawns ((41 - command));
		}
		case 42:
		{
			clanring_state = (clanring_state | CLANRING_NO_PRACTICE);
			cprint("practice mode disabled\n");
			break;
		}
		case 43:
		{
			if (!(clanring_playmode & CLANRING_AUTO_PAUSE))
			{
				utils_toggle_sflag (CLANRING_AUTO_PAUSE, "Automatic match pausing");
			}
			break;
		}
		case 44:
		{
			if (clanring_playmode & CLANRING_AUTO_PAUSE)
			{
				utils_toggle_sflag (CLANRING_AUTO_PAUSE, "Automatic match pausing");
			}
			break;
		}
		case 45:
		{
			if (!(clanring_playmode & CLANRING_CONSOLE_STATS))
			{
				utils_toggle_sflag (CLANRING_CONSOLE_STATS, "Console autostats");
			}
			break;
		}
		case 46: 
		{
			if (clanring_playmode & CLANRING_CONSOLE_STATS)
			{
				utils_toggle_sflag (CLANRING_CONSOLE_STATS, "Console autostats");
			}
			break;
		}
		case 47:
		{
			if (!(clanring_playmode & CLANRING_RUNES))
			{
				StartRuneSpawn ();
				announce("Runes Enabled");
				clanring_playmode = (clanring_playmode | CLANRING_RUNES);
				utils_set_cvar("samelevel", clanring_playmode);
			}
			break;
		}
		case 48:
		{
			if (clanring_playmode & CLANRING_RUNES)
			{
				utils_do_players(DropRune);
				utils_do_item(SUB_Remove, "item_rune");
				announce("Runes Disabled\n");
				clanring_playmode = (clanring_playmode - (clanring_playmode & CLANRING_RUNES));
				utils_set_cvar("samelevel", clanring_playmode);
			}
			break;
		}
// entity file commands
		case 50:
		{
			console_make_entity("info_player_deathmatch", 1);
			dm_num_spawns += 1;
			break;
		}
		case 51:
		{
			console_make_entity("clanring_start_point", 1);
			clanring_num_starts += 1;
			break;
		}
		case 52: console_kill_entity ("info_player_deathmatch"); break;
		case 53:
		{
			console_make_entity("clanring_camera", (CONSOLE_ENT_PITCH | 1));
			clanring_num_cameras += 1;
			break;
		}
		case 54:
		case 55:
		case 56:
		{
			console_origin = console_get_origin();
			if (command == 54)
				utils_do_items(console_kill_item);
			else if (command == 55)
					console_make_item();
				else
				utils_do_items(console_change_item);
			break;
		}
// control commands
		case 60:
		case 61:
		case 62:
		case 63:
		case 64:
		case 65:		
		{
			if (clanring_state & CLANRING_IGNORE_CONSOLE)
			{
				utils_set_cvar("deathmatch"	, console_deathmatch);
				utils_set_cvar("timelimit"	, console_timelimit);
				utils_set_cvar("fraglimit"	, console_fraglimit);
				utils_set_cvar("pausable"	, console_pausable);
				utils_set_cvar("noexit"		, console_noexit);
			}
			else
			{
				console_deathmatch 	= cvar("deathmatch");
				console_timelimit 	= cvar("timelimit");
				console_fraglimit 	= cvar("fraglimit");
				console_pausable 	= cvar("pausable");
				console_noexit 		= cvar("noexit");
			}

			if (command == 60)
			{
				if (clanring_playmode & CLANRING_CONSOLE_INITIALIZED)
					clanring_state = clanring_state | CLANRING_IGNORE_CONSOLE;
				else
				{
					clanring_playmode = (clanring_playmode | CLANRING_CONSOLE_INITIALIZED);
					utils_set_cvar("samelevel", clanring_playmode);
					clanring_state = clanring_state - (clanring_state & CLANRING_IGNORE_CONSOLE);
				}
			}

			if (command >= 61 && command <= 64)
			{
				if (command - 61 != options_get_mode())
					clanring_state = clanring_state | CLANRING_IGNORE_CONSOLE;
				else
					clanring_state = clanring_state - (clanring_state & CLANRING_IGNORE_CONSOLE);
			}
			if (command == 65)//done		
			{
				cprint("'[done]'.\n");
				clanring_state = clanring_state - (clanring_state & CLANRING_IGNORE_CONSOLE);
				admin_dmset(console_deathmatch);
				votables_request_set_timelimit(console_timelimit);
				clanring_set_fraglimit(console_fraglimit);
				utils_set_cvar("pausable", console_pausable);
				utils_set_cvar("noexit", console_noexit);
			}
			break;
		}

		case 69:
		{
			clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_NO_SPOOGE);
			utils_set_cvar ("samelevel", clanring_playmode);
			break;
		}
		case 68:
		{
			clanring_playmode = (clanring_playmode | CLANRING_NO_SPOOGE);
			utils_set_cvar ("samelevel", clanring_playmode);																											
			break;
		}
// undocumented debug commands
		case 70: console_debug_client(); break;
		case 71: 
		{
			cprint("debugging off\n");
			clanring_debug_client = world;
			break;
		}
		case 72: console_stuff_impulse();	break;
		case 73: console_stuff_colour();	break;
		case 74: console_client_flags();	break;
		case 75: console_server_flags();	break;
		case 76: console_client_info();		break;
		case 77: console_debug_help();		break;
		case 78:
		{
			clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_RUNETOSS);
			utils_set_cvar ("samelevel", clanring_playmode);
			break;
		}
		case 79:
		{
			clanring_playmode = clanring_playmode | CLANRING_RUNETOSS;
			utils_set_cvar ("samelevel", clanring_playmode);
			break;
		}

		case  90: console_admins (); break;
		default: cprint("unknown 'console_command'.\n"); break;
	}
};

// Helper: format ISO8601 -> "MM-DD-YYYY HH:MMAM -0700"
// - replaces 'T' with space
// - removes seconds
// - converts 24h -> 12h with AM/PM (no space before AM/PM)
// - adds a space before timezone
string format_rec_date(string d)
{
    local float tpos, start, pos, lastsign, firstspace, colon1, colon2, hour;
    local string date_iso, timeplus, tz, timepart, ampm;
    local string yyyy, mm, dd;

    if (!d || d == "")
        return d;

    // 1) Split date and the rest (time+tz)
    tpos = strstrofs(d, "T", 0);
    if (tpos >= 0) {
        date_iso = substring(d, 0, 10); // YYYY-MM-DD
        timeplus = substring(d, tpos + 1, strlen(d) - (tpos + 1));
    } else {
        // Fallback: split on first space
        firstspace = strstrofs(d, " ", 0);
        if (firstspace >= 0) {
            date_iso = substring(d, 0, 10);
            timeplus = substring(d, firstspace + 1, strlen(d) - (firstspace + 1));
        } else {
            // Not an ISO-like string; return as-is
            return d;
        }
    }

    // 2) Extract timezone at the end (supports -0700 or -07:00). Prefer last '-' then '+'.
    lastsign = -1;
    start = 0;
    while (1) {
        pos = strstrofs(timeplus, "-", start);
        if (pos < 0) break;
        lastsign = pos;
        start = pos + 1;
    }
    if (lastsign < 0) {
        start = 0;
        while (1) {
            pos = strstrofs(timeplus, "+", start);
            if (pos < 0) break;
            lastsign = pos;
            start = pos + 1;
        }
    }

    if (lastsign >= 0) {
        tz = substring(timeplus, lastsign, strlen(timeplus) - lastsign);
        timepart = substring(timeplus, 0, lastsign);
    } else {
        // No explicit TZ (e.g., ends with 'Z' or nothing). Handle 'Z'.
        pos = strstrofs(timeplus, "Z", 0);
        if (pos >= 0 && pos == strlen(timeplus) - 1) {
            tz = "Z";
            timepart = substring(timeplus, 0, pos);
        } else {
            tz = "";
            timepart = timeplus;
        }
    }

    // Trim seconds from time (drop the second colon and following 2 digits if present)
    colon1 = strstrofs(timepart, ":", 0);
    if (colon1 >= 0) {
        colon2 = strstrofs(timepart, ":", colon1 + 1);
        if (colon2 >= 0 && colon2 + 3 <= strlen(timepart)) {
            timepart = strcat(substring(timepart, 0, colon2),
                              substring(timepart, colon2 + 3, strlen(timepart) - (colon2 + 3)));
        }
    }

    // Convert HH:MM -> 12-hour with AM/PM (no space before AM/PM)
    // Expect timepart like "HH:MM"
    if (strlen(timepart) >= 5) {
        hour = stof(substring(timepart, 0, 2));
        ampm = "AM";
        if (hour == 0) {
            hour = 12;
        } else if (hour == 12) {
            ampm = "PM";
        } else if (hour > 12) {
            hour -= 12;
            ampm = "PM";
        }
        // Keep ":MM"
        timepart = sprintf("%g%s%s", hour, substring(timepart, 2, strlen(timepart) - 2), ampm);
    }

    // Rearrange date YYYY-MM-DD -> MM-DD-YYYY
    if (strlen(date_iso) >= 10) {
        yyyy = substring(date_iso, 0, 4);
        mm   = substring(date_iso, 5, 2);
        dd   = substring(date_iso, 8, 2);
    } else {
        // Fallback if date not as expected
        return strcat(date_iso, " ", timepart, (tz != "" ? strcat(" ", tz) : ""));
    }

    // Rebuild with a space before timezone (if present)
    return strcat(mm, "-", dd, "-", yyyy, " ", timepart, (tz != "" ? strcat(" ", tz) : ""));
}

void () CaptureHighScores_sprint =
{
    string s1 = "", s2 = "", s3 = "", s4 = "", ts1 = "", ts2 = "", ts3 = "";

    if (playerrecord[0].statvalue > 0)
    {
        s1 = sprintf("\1  %s %s %-16s", utils_get_time(playerrecord[0].statvalue), get_team_letter(playerrecord[0].teamcolor), playerrecord[0].player);
        // CRX v2: Add metadata if available (trial record: date only)
        if (playerrecord[0].rec_date != "")
            s1 = sprintf("%s  (%s)", s1, format_rec_date(playerrecord[0].rec_date));
        s1 = strcat(s1, "\n");
        
        if (playerrecord[1].statvalue > 0)
        {
            s2 = sprintf("\2  %s %s %-16s", utils_get_time(playerrecord[1].statvalue), get_team_letter(playerrecord[1].teamcolor), playerrecord[1].player);
            if (playerrecord[1].rec_date != "")
                s2 = sprintf("%s  (%s)", s2, format_rec_date(playerrecord[1].rec_date));
            s2 = strcat(s2, "\n");
            
            if (playerrecord[2].statvalue > 0)
            {
                s3 = sprintf("\3  %s %s %-16s", utils_get_time(playerrecord[2].statvalue), get_team_letter(playerrecord[2].teamcolor), playerrecord[2].player);
                if (playerrecord[2].rec_date != "")
                    s3 = sprintf("%s  (%s)", s3, format_rec_date(playerrecord[2].rec_date));
                s3 = strcat(s3, "\n");
            }
        }
    }
    else
    {
        s1 = "No capture times set\n";
    }

    if (playerrecord2[0].statvalue > 0)
    {
        ts1 = sprintf("\1  %s %s %-16s", utils_get_time(playerrecord2[0].statvalue), get_team_letter(playerrecord2[0].teamcolor), playerrecord2[0].player);
        // CRX v2: Add metadata if available (match record: date + match time remaining)
        if (playerrecord2[0].rec_date != "" || playerrecord2[0].rec_mt_str != "")
        {
            ts1 = sprintf("%s  (%s", ts1, format_rec_date(playerrecord2[0].rec_date));
            if (playerrecord2[0].rec_mt_str != "")
                ts1 = sprintf("%s, at %s remaining", ts1, playerrecord2[0].rec_mt_str);
            ts1 = strcat(ts1, ")");
        }
        ts1 = strcat(ts1, "\n");
        
        if (playerrecord2[1].statvalue > 0)
        {
            ts2 = sprintf("\2  %s %s %-16s", utils_get_time(playerrecord2[1].statvalue), get_team_letter(playerrecord2[1].teamcolor), playerrecord2[1].player);
            if (playerrecord2[1].rec_date != "" || playerrecord2[1].rec_mt_str != "")
            {
                ts2 = sprintf("%s  (%s", ts2, format_rec_date(playerrecord2[1].rec_date));
                if (playerrecord2[1].rec_mt_str != "")
                    ts2 = sprintf("%s, at %s remaining", ts2, playerrecord2[1].rec_mt_str);
                ts2 = strcat(ts2, ")");
            }
            ts2 = strcat(ts2, "\n");
            
            if (playerrecord2[2].statvalue > 0)
            {
                ts3 = sprintf("\3  %s %s %-16s", utils_get_time(playerrecord2[2].statvalue), get_team_letter(playerrecord2[2].teamcolor), playerrecord2[2].player);
                if (playerrecord2[2].rec_date != "" || playerrecord2[2].rec_mt_str != "")
                {
                    ts3 = sprintf("%s  (%s", ts3, format_rec_date(playerrecord2[2].rec_date));
                    if (playerrecord2[2].rec_mt_str != "")
                        ts3 = sprintf("%s, at %s remaining", ts3, playerrecord2[2].rec_mt_str);
                    ts3 = strcat(ts3, ")");
                }
                ts3 = strcat(ts3, "\n");
            }
        }
        s4 = sprintf("%s%s%s", ts1, ts2, ts3);
    }	else
	{
		s4 = "No match capture times set\n";
	}
	sprint(self, sprintf("\bTime Trial Leaders\b for %s:\n", mapname), s1, s2, s3, "\bMatch Times\b:\n", s4, "\n");
	return;
};

void () AirshotHighScores_sprint =
{
	 string s1="",s2="",s3="",s4="",ts1="",ts2="",ts3="";

	//TODO: update for higher PLAYER_RECORDS_MAX_COUNT?
	if (playerrecord[0].statvalue > 0)
	{
		s1 = sprintf("\1   %-2s %-16s\n", ftos(playerrecord[0].statvalue), playerrecord[0].player);
		if (playerrecord[1].statvalue > 0)
		{
			s2 = sprintf("\2   %-2s %-16s\n", ftos(playerrecord[1].statvalue), playerrecord[1].player);
			if (playerrecord[2].statvalue > 0)
			{
				s3 = sprintf("\3   %-2s %-16s\n", ftos(playerrecord[2].statvalue), playerrecord[2].player);
			}
		}
	}
	else
	{
		s1 = "No streaks set\n";
	}
	if (playerrecord2[0].statvalue > 0)
	{
		ts1 = sprintf("\1  %-3s %-16s\n", ftos(rint(playerrecord2[0].statvalue)), playerrecord2[0].player);
		if (playerrecord2[1].statvalue > 0)
		{
			ts2 = sprintf("\2  %-3s %-16s\n", ftos(rint(playerrecord2[1].statvalue)), playerrecord2[1].player);
			if (playerrecord2[2].statvalue > 0)
			{
				ts3 = sprintf("\3  %-3s %-16s\n", ftos(rint(playerrecord2[2].statvalue)), playerrecord2[2].player);
			}
		}
		s4 = sprintf("%s%s%s",ts1,ts2,ts3);
	}
	else
	{
		s4 = "No height records set\n";
	}
	sprint(self, "\bAir Gib Streak Leaders\b:\n", s1, s2, s3, "\bHighest Air Gibs\b:\n", s4, "\n");
	return;
};

//TODO: kill streaks?

void () LongRangeGibs_sprint =
{
	 string s1="",s2="",s3="",s4="";

	//TODO: update for higher PLAYER_RECORDS_MAX_COUNT?
	if (playerrecord2[0].statvalue > 0)
	{
		s1 = sprintf("\1  %-3s %-16s\n", ftos(rint(playerrecord2[0].statvalue)), playerrecord2[0].player);
		if (playerrecord2[1].statvalue > 0)
		{
			s2 = sprintf("\2  %-3s %-16s\n", ftos(rint(playerrecord2[1].statvalue)), playerrecord2[1].player);
			if (playerrecord2[2].statvalue > 0)
			{
				s3 = sprintf("\3  %-3s %-16s\n", ftos(rint(playerrecord2[2].statvalue)), playerrecord2[2].player);
			}
		}
		s4 = sprintf("%s%s%s",s1,s2,s3);
	}
	else
	{
		s4 = "No long range records set\n";
	}
	sprint(self, "\bFurthest Rocket Gibs\b:\n", s4, "\n");
	return;
};