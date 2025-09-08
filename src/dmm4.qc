//void () write_airshot_gib_stats;
void (float t_statvalue, float t_teamcolor, string t_player) check_player_high_record;
void () dmm4_init_world =
{
	local entity oself;
			
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
    boss.health      	= 250;
    boss.ammo_shells 	= 100;
    boss.ammo_nails  	= 100;
    boss.ammo_rockets	= 100;
    boss.ammo_cells  	= 100;
    boss.items = ((((((((IT_SHOTGUN | IT_AXE) | IT_ROCKET_LAUNCHER) | IT_ARMOR3) | IT_SUPER_SHOTGUN) | IT_NAILGUN) | IT_GRENADE_LAUNCHER) | IT_LIGHTNING) | IT_SUPER_NAILGUN);

    oself = self;
    self = boss;
    self.weapon = IT_ROCKET_LAUNCHER;// W_BestWeapon();
    self = oself;	

	boss.timetofight 	= FALSE;
	boss.next_team 		= world;
	boss.busy			= FALSE;
	boss.aborted 		= FALSE;
	boss.suddendeath 	= FALSE;

	default_timelimit	= cvar("timelimit"); //set default time for timed matches
	ca_mvp_entity		= world;
};

void () dmm4_set_winning_team =
{
	local entity 	pteam;

	team_first_place 	= boss;
	team_second_place 	= boss;

	pteam = boss.next_team;

	while (pteam)
	{
		if (pteam.chain_gang)
		{
			pteam.wins = pteam.chain_gang.frags;

			if ((team_first_place == boss) || (pteam.wins > team_first_place.wins))
			{
				team_second_place = team_first_place;
				team_first_place = pteam;
			}
			else
			{
				if ((team_second_place == boss) || (pteam.wins > team_second_place.wins))
				{
					team_second_place = pteam;
				}
			}
		}
		pteam = pteam.next_team;
	}
};

void () dmm4_report_winner =
{
	local string winnername = "";
	local float winnerteam = 0;
    dmm4_set_winning_team();

	if (team_first_place == world)
		return;
	if (team_first_place.chain_gang != world)
	{
		winnername = team_first_place.chain_gang.netname;
		winnerteam = team_first_place.chain_gang.team2;
	}
	else
	{
		winnername = team_first_place.netname;
	}

	if ((team_first_place.wins > team_second_place.wins))
	{
        bprint2(winnername, " wins the match.\n");
	}
	else
	{
        bprint("The match was a draw\n");
	}
	bprint5("Final score: ", ftos(team_first_place.wins), " - ", ftos(team_second_place.wins), "\n");
	//leave for timed matches ?
	// if (clanring_playmode & CLANRING_AIRSHOT_MODE)
	// {
	// 	new_player_record = 0;
	// 	check_player_high_record(team_first_place.wins, winnerteam, winnername);
	// 	if (new_player_record > 0)
	// 	{
	// 		if (new_player_record == 1)
	// 		{
	// 			bprint(winnername);
	// 			bprint(" set the new \bgib record\b\n");
	// 			sound (self, CHAN_VOICE, "crx/hiscore.wav", 1, ATTN_NORM);
	// 		}
	// 		write_airshot_gib_stats();
	// 	}
	// }
};

void () dmm4_main_loop =
{
	if ((clanring_state & CLANRING_MATCH_PAUSED) && (!boss.unpausing))
	{
		if (time > boss.pauseblink)
		{
			WriteByte (MSG_ALL, SVC_CENTERPRINT);
			WriteString (MSG_ALL, "\n\X90PAUSED\X91\n");
			boss.pauseblink = time + 1.5;
		}
		return;
	}

	if ((boss.busy) || (gameover))
		return;

	if (boss.state == CA_MATCH_PLAYING)
	{
		if (number_teams () > 1)
		{
            arena_timer_think();
            // if (clanring_playmode & CLANRING_AIRSHOT_MODE)
            // {
            // 	if (number_teams_alive () < 2)// in airshot we are just waiting for respawn
            // 	{				
            // 		if (boss.wait == 0)
            // 		{
            // 			boss.wait = (time + 4);
            // 			return;
            // 		}

            // 		if (time > boss.wait)
            // 		{
            // 			boss.wait = 0;
            // 		}
            // 	}
            // }
		}
		else
		{
			gameover = TRUE;
			boss.aborted = TRUE;
			boss.suddendeath = FALSE;
			boss.state = CA_MATCH_OVER;
			arena_match_end ();
		}
	}
	else if ((boss.state == CA_MATCH_ROUNDSTART))
	{
		// local string temp;

		motd_top5 = string_null;
		motd_top6 = string_null;

		if (number_teams () > 1)
		{
			boss.count = (boss.count) - 1;

			if (clanring_request.noise1 == "\bforce match start\b")	//cancel Vote to force
				Request_Poll_Cleanup();

			if (boss.count > 5)
			{
				if (boss.count == 9)
				{
					utils_do_item(SUB_Remove, "item_backpack");
					arena_ready_players ();
				}
				else if (boss.count == 8)
				{
					respawn_teams ();

                    // bprint ("\bround: [");
                    // if (boss.round <= boss.max_rounds)
                    // {
                    //     temp = ftos (boss.round);
                    //     bprint(temp);
                    //     temp = ftos (boss.max_rounds);
                    //     bprint3 (" \bof \b",temp,"\b]\n");
                    // }
                    // else
                    //     bprint ("Overtime\b]\n");
				}
			}
			else
			{
				if (boss.count == 0)
				{
					utils_do_arena_players(arena_restart_player);
					sound (world, CHAN_ITEM, "crx/fight.wav", 1, ATTN_NONE);
					//ctprint ("\bFIGHT!");
					utils_do_arena_players(arena_fight_and_shoot);
					boss.timetofight = TRUE;
					boss.suddendeath = FALSE;
					boss.state = CA_MATCH_PLAYING;
					// Clear leave-me-alone flags for all players
					utils_do_players(match_clear_leavemealone);
                    clanring_timelimit = default_timelimit;
                    boss.lip = clanring_timelimit;
                    boss.count = 0;
                    arena_show_timelimit();

                    stats_matchtype = 1;
                    stats_timelimit = clanring_timelimit;
				}
				else if (boss.count == 1)
				{
					//ctprint ("1");
					sound (world, CHAN_ITEM, "crx/one.wav",1, ATTN_NONE);
				}
				else if (boss.count == 2)
				{
					//ctprint ("2");
					sound (world, CHAN_ITEM, "crx/two.wav", 1, ATTN_NONE);
				}
				else if (boss.count == 3)
				{
					//ctprint("3");
					sound(world, CHAN_ITEM, "crx/three.wav", 1, ATTN_NONE);
				}
				else if (boss.count == 5)
				{
					// reset all items
					utils_do_items(SUB_regen);
					utils_do_weapons(SUB_Remove);
					utils_do_ammo(SUB_Remove);
					utils_do_item(match_reset_powerup, "item_artifact_invulnerability");
					utils_do_item(match_reset_powerup, "item_artifact_super_damage");
					utils_do_item(match_reset_powerup, "item_artifact_envirosuit");
					utils_do_item(match_reset_powerup, "item_artifact_invisibility");

					announce("prepare to fight");					
				}
			}
		}
		else
		{
			gameover = TRUE;
			boss.aborted = TRUE;
			boss.suddendeath = FALSE;
			boss.state = CA_MATCH_OVER;
			arena_match_end();
		}
	}
	else if ((boss.state == CA_MATCH_WAITING))
	{
		if (boss.forced)
		{
			boss.forced 	= FALSE;
			boss.timetofight 	= FALSE;
			boss.count	= 10;
			boss.wait 	= 0;
			boss.state 	= CA_MATCH_ROUNDSTART;

			clanring_timelimit = default_timelimit;

			//sound (world, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NONE);
			sound (world, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NONE);
			announce("Match begins in \b10\b seconds.");
			utils_do_players(reset_frags);
		}
		else if (number_teams () > 1 && boss.allready == TRUE)
		{
			if (boss.wait == 0)
			{
				// No need to force match now.
				if (clanring_request.noise1 == "\bforce match start\b")
				Request_Poll_Cleanup();

				clanring_timelimit = default_timelimit;

				boss.wait = time + 5;
				sound (world, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NONE);
				announce("Match begins in \b15\b seconds.");//boss.wait (5) + countdowntimer (10) = 15 seconds...
			}

			if (time >= boss.wait)
			{
				boss.timetofight	= FALSE;
				boss.count 	= 10;
				boss.wait 	= 0;
				//sound (world, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NONE);
				sound (world, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NONE);
				announce("Match begins in \b10\b seconds.");
				utils_do_players(reset_frags);
				Practice_Object_Remove();
				//TODO: needed?
				//utils_do_items(SUB_Remove);
				boss.state = CA_MATCH_ROUNDSTART;
				pqc_match_reset();
				find_pqc_teamscore_teams();
			}
		}
		else if (number_teams () < 2 || boss.allready == FALSE)
		{
			if (boss.wait)
			{
				announce ("\bResetting \brally\b timer.");
				sound (world, CHAN_VOICE, "doors/drclos4.wav", 1, ATTN_NONE);

				if (number_teams () >= 2)
				bprint("Use \bforce\b to start the match.\n");
			}
			boss.wait = 0;
		}
		boss.allready = TRUE;
	}
	else
	{
		if (boss.state == CA_MATCH_CLEANUP)
		{
			if (boss.wait == 0)
			{
				boss.wait = time + 3;
			}
			if (time > boss.wait)
			{
				boss.wait = 0;
				boss.state = CA_MATCH_WAITING;
			}
		}
	}
};

//
//  A R E N A  S H O W  T I M E L I M I T
//
void() arena_show_timelimit =
{
	local string temp;

	if (!clanring_timelimit)
		return;

	localcmd("timelimit \"");

	if (boss.state != CA_MATCH_PLAYING)
	{
		if (boss.state == CA_MATCH_OVER)
		{
			localcmd("Final Score is ");
			temp = ftos(team_first_place.wins);
			if (team_first_place.wins < 0)
				localcmd("<");
			localcmd(temp);
			if (team_first_place.wins < 0)
				localcmd(">");
			localcmd(" - ");
			if (team_second_place != boss)
			{
				temp = ftos(team_second_place.wins);
				if (team_second_place.wins < 0)
					localcmd("<");
				localcmd(temp);
				if (team_second_place.wins < 0)
					localcmd(">");
			}
			else
				localcmd("???");
			localcmd("\"\n");
		}
		else
		{
			temp = ftos(clanring_timelimit);
			localcmd4(temp, " : Waiting for ", clanring_szteam, "s\"\n");
		}
	}
	else
	{
		if (boss.state != CA_MATCH_PLAYING)
		{
			temp = ftos(clanring_timelimit);
			localcmd2(temp, " : Match Starting\"\n");
		}
		else
		{
			if (boss.lip < 0)
			{
				localcmd("Sudden death\"\n");
			}
			else
			{
				temp = ftos(boss.lip);
				localcmd2(temp, "\"\n");
			}
		}
	}
};

void () arena_timer_think =
{
	local string temp;

	if ((!clanring_timelimit) || (boss.suddendeath))
		return;

	// Do not advance the round clock while the match is paused
	if (clanring_state & CLANRING_MATCH_PAUSED)
	{
		pqc_match_time(boss.lip, boss.count);
		arena_show_timelimit();
		return;
	}

	boss.count -= 1;

	if (boss.count < 0)
	{
		boss.count = 59;
		boss.lip -= 1;
	}

	pqc_match_time(boss.lip, boss.count);

	arena_show_timelimit();

	if (boss.lip)
	{
		if (boss.count)
			return;

		if (boss.lip > 1)
		{
			arena_show_timelimit();
		}
		else
		{
			arena_show_timelimit();
			announce("Match ends in 1 minute");
			if (clanring_playmode & CLANRING_AIRSHOT_MODE)
				sound (world, CHAN_ITEM, "ambience/thunder1.wav", 1, ATTN_NONE);
		}
	}
	else
	{
		if (boss.count == 0)
		{
			dmm4_set_winning_team();
			if (team_first_place.wins == team_second_place.wins)
			{
				announce("Sudden Death!!");
				boss.suddendeath = TRUE;
				boss.lip = -1;
				arena_show_timelimit();
				return;
			}

			boss.busy = TRUE;
			gameover = TRUE;
			arena_show_timelimit();
			arena_match_end();
		}
		else if (boss.count == 30)
		{
			announce("Match ends in 30 seconds");
			if (clanring_playmode & CLANRING_AIRSHOT_MODE)
			{
				announce("\bQuad Juggling\b activated");
				sound (world, CHAN_ITEM, "crx/activate.wav", 1, ATTN_NONE);
			}
			// if (clanring_overtime > 0)
			// {
			// 	temp = ftos(clanring_overtime);
			// 	announce2(temp, " minute overtime in case of tie");
			// }
			// else if (clanring_overtime < 0)
			// 	announce("Sudden death overtime in case of tie");
		}
		else
		{
			if (boss.count <= 10)
			{
				local string plural;
				if (boss.count == 10)
					announce("Match ends in T minus");
				temp = ftos(boss.count);
				plural = strings_szplural(boss.count);
				announce4("  ", temp, " second", plural);
			}
		}
	}
};