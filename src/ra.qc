void () rocket_arena_init_world =
{
	boss 				= spawn ();
	boss.max_rounds 	= 1;
	boss.round 			= 1;
	boss.count 			= 10;
	boss.max_players 	= 1;//R00k: changed v1.52
	boss.start_players	= 1;
 	boss.max_teams  	= 13;
	boss.state 			= CA_MATCH_WAITING;
	boss.wait 			= 0;
	boss.maprecycle		= 0;
		
    boss.items = ((((((((IT_SHOTGUN | IT_AXE) | IT_ROCKET_LAUNCHER) | IT_ARMOR3) | IT_SUPER_SHOTGUN) | IT_NAILGUN) | IT_GRENADE_LAUNCHER) | IT_LIGHTNING) | IT_SUPER_NAILGUN);

	boss.health      	= 100;
	boss.armorvalue  	= 200;
	boss.ammo_shells 	= 30;
	boss.ammo_nails  	= 80;
	boss.ammo_rockets	= 30;
	boss.ammo_cells  	= 30;

	boss.weapon      	= IT_ROCKET_LAUNCHER;
	boss.armortype   	= 80.001;
	boss.timetofight 	= FALSE;
	boss.next_team 		= world;
	boss.next_color		= COLOR_RED;

	boss.busy			= FALSE;
	boss.aborted 		= FALSE;

	ra_initial_rules_shown = FALSE;
	ra_wins = 10;
};

string() ra_get_next_map =
{		
	float rnmap = floor((random () * 46));
	switch(rnmap)
	{
		case 0:
			return "23ar-a";
		case 1:
			return "2pyramid";
		case 2:
			return "2towers";
		case 3:
			return "arenarg2";
		case 4:
			return "arenarg4";
		case 5:
			return "arenarg5";
		case 6:
			return "arenarg6";
		case 7:
			return "arenax";
		case 8:
			return "arenazap";
		case 9:
			return "arendm1a";
		case 10:
			return "arenrg3a";
		case 11:
			return "arma4";
		case 12:
			return "barena1";
		case 13:
			return "basarena";
		case 14:
			return "bbarena2";
		case 15:
			return "bunmoo3";
		case 16:
			return "bunski";
		case 17:
			return "chamber1";
		case 18:
			return "crandome";
		case 19:
			return "dm2arena";
		case 20:
			return "dom2_1ra";
		case 21:
			return "egyptra";
		case 22:
			return "football";
		case 23:
			return "gear8";
		case 24:
			return "gnurena";
		case 25:
			return "hill20";
		case 26:
			return "iarena2";
		case 27:
			return "id3";
		case 28:
			return "lowgrav";
		case 29:
			return "marena2";
		case 30:
			return "marena3";
		case 31:
			return "marena4";
		case 32:
			return "mayan1";
		case 33:
			return "nilsrar3";
		case 34:
			return "pen2";
		case 35:
			return "pitarena";
		case 36:
			return "ptucket";
		case 37:
			return "ra_funkf";
		case 38:
			return "rarena3";
		case 39:
			return "rgarden";
		case 40:
			return "soyarena";
		case 41:
			return "terrain2";
		case 42:
			return "uarena1";
		case 43:
			return "unholy";
		case 44:
			return "xarena3";
		default:
			return "yard1";
	}
};

float() ra_map =
{		
	if (mapname == "23ar-a")	return TRUE;
	if (mapname == "2pyramid")  return TRUE;
	if (mapname == "2towers")  	return TRUE;
	if (mapname == "arenarg2")  return TRUE;
	if (mapname == "arenarg4")  return TRUE;
	if (mapname == "arenarg5")  return TRUE;
	if (mapname == "arenarg6")  return TRUE;
	if (mapname == "arenax")  	return TRUE;	
	if (mapname == "arenazap")  return TRUE;
	if (mapname == "arendm1a")  return TRUE;
	if (mapname == "arenrg3a")  return TRUE;
	if (mapname == "arma4")  	return TRUE;
	if (mapname == "barena1") 	return TRUE;	
	if (mapname == "basarena")	return TRUE;
	if (mapname == "bbarena2")	return TRUE;
	if (mapname == "bunmoo3")	return TRUE;
	if (mapname == "bunski")	return TRUE;
	if (mapname == "chamber1")	return TRUE;
	if (mapname == "crandome") 	return TRUE;
	if (mapname == "dm2arena")  return TRUE;
	if (mapname == "dom2_1ra")  return TRUE;
	if (mapname == "egyptra")  	return TRUE;
	if (mapname == "football")  return TRUE;
	if (mapname == "gear8")  	return TRUE;	
	if (mapname == "gnurena")  	return TRUE;
	if (mapname == "hill20")  	return TRUE;
	if (mapname == "iarena2")  	return TRUE;
	if (mapname == "id3")  		return TRUE;
	if (mapname == "lowgrav")  	return TRUE;
	if (mapname == "marena2")  	return TRUE;	
	if (mapname == "marena3")  	return TRUE;	
	if (mapname == "marena4")  	return TRUE;	
	if (mapname == "mayan1")  	return TRUE;
	if (mapname == "nilsrar3")  return TRUE;
	if (mapname == "pen2")  	return TRUE;
	if (mapname == "pitarena")  return TRUE;
	if (mapname == "ptucket")  	return TRUE;
	if (mapname == "ra_funkf")  return TRUE;
	if (mapname == "rarena3")  	return TRUE;
	if (mapname == "rgarden")  	return TRUE;	
	if (mapname == "soyarena")  return TRUE;
	if (mapname == "terrain2")  return TRUE;
	if (mapname == "uarena1")  	return TRUE;
	if (mapname == "unholy")  	return TRUE;
	if (mapname == "xarena3")  	return TRUE;
	if (mapname == "yard1")  	return TRUE;

	return FALSE;
};

//
//Sequential spawns, with telefrag scan.
//
entity() SelectRASpawnPoint =
{
	local entity spot;
	//local entity thing;
	//local float	pcount;
	//local float	n;

	//loop_count = 64;
	
	//pcount = random() * (tele_num_spawns - 0.001);
	//pcount = floor(pcount);
	spot = find(world, classname, "info_teleport_destination");

	if (spot == world)
	{
		spot = find(world, classname, "info_player_deathmatch");
		if (spot == ra_lastspawn)
		{
			spot = find(spot, classname, "info_player_deathmatch");
		}
		return spot;
	}

	if (spot == ra_lastspawn)
	{
		spot = find(spot, classname, "info_teleport_destination");
		if (spot == world)
		{
			spot = find(world, classname, "info_teleport_destination");
			spot.origin = spot.origin + '64 64 64';
		}
	}

	//Check for telefrag
	if (spot != world)
	{
		self.solid = SOLID_NOT;//this will unstick players at spawn
		makevectors(self.v_angle);
		self.velocity = v_forward * (320);//R00k:Nudge them forward
	}

	ra_lastspawn = spot;
	return spot;
};

void (entity pteam) ra_join_next_queue =
{
	pteam.next_queue = boss.next_queue;
	boss.next_queue = pteam;
};

void() ra_join_queue =
{
	local entity pteam;
	local string tmp;
	local float whichteam;

	if ((boss.state == CA_MATCH_CLEANUP) || (boss.state == CA_MATCH_OVER))
	{
		sprint (self, "Try again in 5 seconds...\n");
		return;
	}

	if (self.next_team != world)
	{
		sprint(self,"\bYou have already commited.\n");
		return;//already on a team
	}

	if (self.lip > time)//R00k: FIXed?
	{
		sprint(self,"\bYou may not join at this time.\n");
		return;
	}

	self.lip = time + 2; //R00k: two seconds between team choice will stop script spam

	whichteam = floor(random() * 11) + 1;
	if (whichteam == 4)
		{ whichteam = COLOR_YELLOW; }

	pteam = spawn();
	pteam.classname 	= "ra_team";
	pteam.team2			= whichteam;
	pteam.wins			= 0;
	pteam.losses 		= 0;
	pteam.armorvalue 	= 0;
	pteam.health		= 0;
	//pteam.netname 		= self.netname;

	pteam.next_player	= world;//init entity
	pteam.chain_gang 	= world;//init entity

	pteam.next_team   	= boss.next_team;
	boss.next_team    	= pteam;

	announce2 (self.netname, " has joined the queue");
	//pqc_new_team (pteam.team2);

	self.team2  	= whichteam;
	self.next_team 	= pteam;
	self.frags 		= 0;
	self.respawntime = 0;
	self.rounddeaths = 0;

	add_player_to_stat_list(pteam,self);
	add_player_to_chain(pteam,self);

	ra_join_next_queue(pteam);

	tmp = ftos(self.team2);

	setcolour(self,self.team2,0);

	stuffcmd(self,";color ");
	stuffcmd(self,tmp);
	stuffcmd(self," 0;\n");

	ready_name();

	motd_top5 = string_null;
	motd_top6 = string_null;
	stats_reset_player (); //BAM MOVED
};

void (entity pteam) ra_leave_next_queue =
{
	local entity plast;
	plast = boss;

	while (plast.next_queue)
	{
		if (plast.next_queue == pteam)
		{
			plast.next_queue = pteam.next_queue;
			break;
		}
		plast = plast.next_queue;
	}
};

void () ra_leave_queue =
{
	if (self.next_team == world)
	return;

	if (self.next_team == self)
	return;

	bprint2 (self.netname, "\b has left the queue\n");

	remove_player_from_chain(self.next_team, self);
	remove_player_from_stat_list(self.next_team, self);

	//pqc_erase_team(self.next_team.team2);
	ra_leave_next_queue(self.next_team);
	arena_remove_team(self.next_team);

	//reset player
	self.team2 	= TEAM_SPECTATOR;
	self.team 	= ((self.team2) + 1);//v1.1b fixed
	self.next_team 	= world;
	self.weaponlevel = 0;

	//This is fine dont change this!
	if (self.style & CLANRING_CONNECTED)
	{
		setcolour (self, 0, 0);
	}

	clear_name();

	self.ca_player_flag = PF_WAITING;
	self.movetarget 	= world;
	self.frags 			= -99;
};

void () ra_select_team =
{
	if (boss.busy == TRUE)
	{
		sprint(self, "Try again in a few seconds...\n");
		return;
	}

	clear_afk_status(self);
		
	if (self.impulse == 1)
	{
		ra_join_queue ();
	}

	if (self.impulse == 2)
	{
		if ((self.ca_player_flag == PF_WAITING) && (self.next_team != world))
		{
			ra_leave_queue ();
				
			if ((self.next_team == world) && (self.style & CLANRING_CONNECTED))
			{		
				stuffcmd(self,";color 0;\n");
			}
		}
	}
	
	self.impulse = 0;
};

entity () ra_get_next_player =
{
	local entity e, p;

	if (boss.next_queue == world)
		return world;

	e = boss;
	p = boss.next_queue;

	while (p.next_queue != world)
	{
		e = p;
		p = p.next_queue;
	}

	e.next_queue = world;
	return p;
};

void (float nextcolor) ra_next_player_ready =
{
	local entity pteam, player;
	//local float player_ready = 0;

	pteam = ra_get_next_player ();
	if (pteam != world)
	{
		pteam.team2 = nextcolor;

		player = pteam.chain_gang;
		while (player != world)
		{
			if (player.style & CLANRING_CONNECTED)
			{
				player.ca_player_flag = PF_READY;
				player.team2 = nextcolor;
				//player_ready = 1;
				if (boss.round != 1)
				{
					bprint2 (player.netname, " is the next challenger\n");
				}
			}
			player = player.chain_gang;
		}
	}
	//return player_ready;
};

void () ra_spawn_players =
{
	local entity 	pteam, player, tmp;
	local string tmpc = "";

	pteam = boss.next_team;

	while (pteam != world)
	{
		player = pteam.chain_gang;
		while (player != world)
		{
			if (player.ca_player_flag == PF_READY)
			{
				if (player.style & CLANRING_OBSERVER)
				{
					tmp = self;
					self = player;
					observer_end ();
					self = tmp;
				}
				else
				{
					//if player hasn't been through observer_start yet (1v1) just respawn
					tmp = self;
					self = player;
					respawn();
					setcolour(self,self.team2,self.team2);
					tmpc = ftos(self.team2);
					stuffcmd(self,"color ");
					stuffcmd(self,tmpc);
					stuffcmd(self,";\n");
					self = tmp;
				}
				player.dmg_given_round = 0;
			}
			else if (player.ca_player_flag == PF_PLAYING)
			{
				player.health = boss.health;
				player.armorvalue = boss.armorvalue;
				player.armortype = (boss.armortype * 0.01);
				player.items = boss.items; // woods for ra showing in ra
				player.ammo_shells = boss.ammo_shells;
				player.ammo_nails = boss.ammo_nails;
				player.ammo_rockets = boss.ammo_rockets;
				player.ammo_cells = boss.ammo_cells;
			}
			player = player.chain_gang;
		}

		pteam = pteam.next_team;
	}
};

void() ra_reset_draw_player =
{
	if (self.ca_player_flag == PF_DEAD)
	{
		self.ca_player_flag = PF_READY;
	}
};

float () ra_players_alive =
{
	local float n = 0;
	local entity e, p;

	e = boss.next_team;
	while (e != world)
	{
		p = e.chain_gang;
		while (p != world)
		{
			if ((p.deadflag == DEAD_NO) && (p.ca_player_flag == PF_PLAYING) && (p.style & CLANRING_CONNECTED))
				n = n + 1;
			p = p.chain_gang;
		}

		e = e.next_team;
	}

	return n;
};

float () ra_number_teams =
{
	local float n = 0.0;
	local entity e,p;

	e = boss.next_team;

	while (e)
	{
		p = e.chain_gang;
		while (p)
		{
			if (p.style & CLANRING_CONNECTED)
			{
				n = n + 1;
				break;
			}
			p = p.chain_gang;
		}
		e = e.next_team;
	}

	return n;
};

string (string msg) ra_countdown_message =
{
	local entity myteam, e, p, oppteam;
	local string line;

	// Spectators or no team: no opponent label
	if (self == world)
		return msg;

	myteam = self.next_team;
	if (myteam == world)
		return msg;

	// Find the other team that is actually active (PF_READY or PF_PLAYING)
	oppteam = world;
	e = boss.next_team;
	while (e != world)
	{
		if (e != myteam)
		{
			p = e.chain_gang;
			while (p != world)
			{
				if ((p.ca_player_flag == PF_READY) || (p.ca_player_flag == PF_PLAYING))
				{
					oppteam = e;
					break;
				}
				p = p.chain_gang;
			}
			if (oppteam != world)
				break;
		}
		e = e.next_team;
	}

	if (oppteam == world || oppteam.chain_gang == world)
		return msg;

	line = strcat(oppteam.chain_gang.netname, "\n\n");
	line = strcat(line, msg);
	return line;
};

void RA_CenterprintToAll (string msg)
{
    local entity pl, save;

    pl = nextent(world);          // first client entity
    while (pl != world)
    {
        if (pl.style & CLANRING_CONNECTED)
        {
            save = self;          // remember caller
            self = pl;            // personalise `self`

            msg_entity = pl;      // make sure engine sends to this client
            WriteByte  (MSG_ONE, SVC_CENTERPRINT);
            WriteString(MSG_ONE, ra_countdown_message(msg));

            self = save;          // restore for next loop
        }
        pl = nextent(pl);
    }
}

void () rocket_arena_main_loop =
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
		if (ra_number_teams () > 1)
		{
			if (ra_players_alive () < 2)
			{
				if (boss.wait == 0)
				{
					boss.timetofight = FALSE;
					boss.wait = (time + 4);//slight pause before end of round.					
					return;
				}

				if (time > boss.wait)
				{
					boss.wait = time + 99;//do round end and wait
					if (ra_players_alive () == 0)
					{
						boss.round = (boss.round - 1);// repeat round
						boss.draw = TRUE;
						announce ("round is a \bdraw\b!");
						utils_do_arena_players(ra_reset_draw_player);
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
			

			if (boss.count == 0)
            {
				RA_CenterprintToAll("\bFIGHT!");
				sound (world, CHAN_ITEM, "crx/fight.wav", 1, ATTN_NONE);
				utils_do_arena_players(arena_fight_and_shoot);
				boss.timetofight = TRUE;
				boss.state = CA_MATCH_PLAYING;
				if (boss.round == 1)
					announce("The match has begun!");
            }
            else if (boss.count == 1)
            {
                if ((boss.round > 1) || ra_initial_rules_shown) RA_CenterprintToAll("1");
				sound (world, CHAN_ITEM, "crx/one.wav",1, ATTN_NONE);
            }
            else if (boss.count == 2)
            {
                if ((boss.round > 1) || ra_initial_rules_shown) RA_CenterprintToAll("2");
				sound (world, CHAN_ITEM, "crx/two.wav", 1, ATTN_NONE);
            }
            else if (boss.count == 3)
            {
                if ((boss.round > 1) || ra_initial_rules_shown) RA_CenterprintToAll("3");
				sound(world, CHAN_ITEM, "crx/three.wav", 1, ATTN_NONE);
            }
			else if (boss.count == 4)
			{
				ra_spawn_players ();
				bprint ("\bround:\b ");
				temp = ftos (boss.round);
				bprint2 (temp,"\n");
					
				local string stmp;
				stmp = (report_winning_team());
				bprint2 (stmp, "\n");
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
		if (number_teams () > 1)
		{
			if (boss.wait == 0)
			{
				// No need to force match.
				if (clanring_request.noise1 == "\bforce match start\b")
				Request_Poll_Cleanup();
				
				boss.wait = time + 5;
				sound (world, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NONE);
				announce("Match begins in \b10\b seconds.");//boss.wait (5) + countdowntimer (5) = 10 seconds...
			}

			if (time >= boss.wait)
			{
				boss.timetofight	= FALSE;
				boss.count 	= 5;
				boss.wait 	= 0;
				boss.draw = FALSE;
				boss.busy = FALSE;
				sound (world, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NONE);
				utils_do_players(reset_frags);
				Practice_Object_Remove();
				boss.state = CA_MATCH_ROUNDSTART;
				ra_initial_rules_shown = TRUE;
				ra_next_player_ready(COLOR_BLUE);
				ra_next_player_ready(COLOR_RED);
				//pqc_match_reset();
				//find_pqc_teamscore_teams();
				announce("prepare to fight");		
			}
		}
		else if (number_teams () < 2)
		{
			if (boss.wait)
			{
				announce ("\bResetting \brally\b timer.");
				sound (world, CHAN_VOICE, "doors/drclos4.wav", 1, ATTN_NONE);
			}
			boss.wait = 0;
		}
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