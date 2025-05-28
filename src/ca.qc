void () Practice_Object_Remove;

void () clan_arena_init_world =
{
	boss = spawn ();
    boss.max_rounds 	= 9;
    boss.max_players 	= 8;//R00k: changed v1.52
    boss.start_players	= 3;
    boss.max_teams  	= 4;
	boss.round			= 1;
	boss.count 			= 10;
	boss.state 			= CA_MATCH_WAITING;
	boss.wait 			= 0;
	boss.maprecycle		= 0;
	boss.armorvalue  	= 200;
	boss.armortype   	= 80.001;
    boss.health      	= 100;
    boss.ammo_shells 	= 100;
    boss.ammo_nails  	= 100;
    boss.ammo_rockets	= 50;
    boss.ammo_cells  	= 30;
    boss.items = ((((((((IT_SHOTGUN | IT_AXE) | IT_ROCKET_LAUNCHER) | IT_ARMOR3) | IT_SUPER_SHOTGUN) | IT_NAILGUN) | IT_GRENADE_LAUNCHER) | IT_LIGHTNING) | IT_SUPER_NAILGUN);
    boss.weapon = IT_ROCKET_LAUNCHER;// W_BestWeapon();

	boss.timetofight 	= FALSE;
	boss.next_team 		= world;
	boss.busy			= FALSE;
	boss.aborted 		= FALSE;
	ca_mvp_entity		= world;
};

void () arena_main_loop =
{
	if ((clanring_state & CLANRING_MATCH_PAUSED) && (!boss.unpausing))
	{
		if (time > boss.lip)
		{
			WriteByte (MSG_ALL, SVC_CENTERPRINT);
			WriteString (MSG_ALL, "\n\X90PAUSED\X91\n");
			boss.lip = time + 1.5;
		}
		return;
	}

	if ((boss.busy) || (gameover))
		return;

	if (boss.state == CA_MATCH_PLAYING)
	{
		if (number_teams () > 1)
		{
			local float round_is_over = FALSE;
			local float team_alive = 0;
			local entity e;

			if (clanring_playmode & CLANRING_WIPEOUT_MODE)
			{
				e = boss.next_team;
				while (e != world)
				{
					if (e.teamalive > 0)
					{
						team_alive += 1;

						// if (e.teamalive == 1 && e.teamtotal > 1)
						// 	spawn_quad = TRUE;
					}
					e = e.next_team;
				}

				if (team_alive < 2)
					round_is_over = TRUE;
				else
				{
					wipeout_try_spawn_item();
				}
			}
			else 
			{
				if (number_teams_alive () < 2)
					round_is_over = TRUE;
			}

			if (round_is_over)
			{
				if (boss.wait == 0)
				{
					boss.wait = (time + 4);//slight pause before end of round.
					return;
				}

				if (time > boss.wait)
				{
					boss.wait = time + 99;//do round end and wait
					if (number_teams_alive () == 0)
					{
						boss.round = (boss.round - 1);// repeat round
						announce ("round is a \bdraw\b!");
						utils_make_scheduled_event(reset_round,0.5);//fixed v.0.94b
						return;
					}
					round_end();
				}
			}
		}
		else
		{
			gameover = TRUE;
			boss.aborted = TRUE;
			boss.state = CA_MATCH_OVER;
			arena_match_end ();
		}
	}
	else if ((boss.state == CA_MATCH_ROUNDSTART))
	{
		local string temp;

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
					//refresh_observers();//TODO: force observers into chasemode/eyecam+

					if (clanring_playmode & CLANRING_WIPEOUT_MODE)
						wipeout_init_teams();

					bprint ("\bround: [");
					if (boss.round <= boss.max_rounds)
					{
						temp = ftos (boss.round);
						bprint(temp);
						temp = ftos (boss.max_rounds);
						bprint3 (" \bof \b",temp,"\b]\n");
					}
					else
						bprint ("Overtime\b]\n");

					local string stmp;
					stmp = (report_winning_team());
					bprint2 (stmp, "\n");
				}
			}
			else
			{
				if (boss.count == 0)
				{
					sound (world, CHAN_AUTO, "crx/fight.wav", 1, ATTN_NONE);
					ctprint ("\bFIGHT!");
					utils_do_arena_players(arena_fight_and_shoot);
					boss.timetofight = TRUE;
					boss.state = CA_MATCH_PLAYING;
					if (boss.round == 1)
						announce("The match has begun!");
				}

				if (boss.count == 1)
				{
					if (boss.round > 1) ctprint ("1");
					sound (world, CHAN_AUTO, "crx/one.wav",1, ATTN_NONE);
				}
				else if (boss.count == 2)
				{
					if (boss.round > 1) ctprint ("2");
					sound (world, CHAN_AUTO, "crx/two.wav", 1, ATTN_NONE);
				}
				else if (boss.count == 3)
				{
					if (boss.round > 1) ctprint("3");
					sound(world, CHAN_AUTO, "crx/three.wav", 1, ATTN_NONE);
				}
				else if (boss.count == 5)
				{
					if (boss.round > 1) 
						announce("prepare to fight");					
					//sound(world, CHAN_ITEM, "crx/prepare.wav", 1, ATTN_NONE);
				}
			}
		}
		else
		{
			gameover = TRUE;
			boss.aborted = TRUE;
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

			//sound (world, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NONE);
			sound (world, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NONE);
			//announce("Match begins in \b10\b seconds.");
			utils_do_players(reset_frags);
		}
		else if (number_teams () > 1 && boss.allready == TRUE)
		{
			if (boss.wait == 0)
			{
				// No need to force match now.
				if (clanring_request.noise1 == "\bforce match start\b")
				Request_Poll_Cleanup();

				boss.wait = time + 5;
				sound (world, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NONE);
				announce("Match begins in \b15\b seconds.");//boss.wait (5) + countdowntimer (10) = 15 seconds...
			}

			if (time >= boss.wait)
			{
				boss.timetofight	= FALSE;
				boss.count 	= 10;
				boss.wait 	= 0;
				sound (world, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NONE);
				//sound (world, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NONE);
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
				boss.wait = 0;
				if (number_teams () >= 2)
				bprint("Use \bforce\b to start the match.\n");
			}
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