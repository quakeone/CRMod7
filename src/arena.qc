void () observer_start;
void () observer_end;
void () stats_final_summary;
void () stats_reset_player;
void () observer_walk_start;
void () vote_yes;
void () observer_check_demo_end;
void () stats_team_stats;
void () RemoveFromTeam;
void () ra_select_team;
void() Request_Poll_Cleanup;
float (string captiona, string captionb, void() passfunc, string pollname = "") vote_init;
float () W_BestWeapon;
void () SUB_regen;
void (float dm) ThrowHead;
void () match_reset_powerup;
void () arena_show_timelimit;
void () arena_timer_think;
void () GibPlayer;
void () clan_arena_init_world;
void () airshot_init_world;
void () dmm4_init_world;
void () rocket_arena_init_world;
float (float rounddeaths) wipeout_get_respawn;
void () dmm4_report_winner;
void () wipeout_init_teams;
//void () wipeout_try_spawn_quad;
void () wipeout_try_spawn_item;
void () respawn;
void (entity pteam) ra_leave_next_queue;
void (entity pteam) ra_join_next_queue;
void (float nextcolor) ra_next_player_ready;

void () arena_precache =
{
	//arena
    //precache_sound ("ra/1.wav");
	//precache_sound ("ra/2.wav");
	//precache_sound ("ra/3.wav");
	//precache_sound ("ra/fight.wav");
	precache_sound ("crx/one.wav");
	precache_sound ("crx/two.wav");
	precache_sound ("crx/three.wav");
	precache_sound ("crx/fight.wav");
	//precache_sound ("ra/laugh.wav"); Moved to world.qc --R00k
	//precache_sound ("ra/flawless.wav");  //not used
	precache_sound ("ra/outstand.wav");	
	//precache_sound ("ra/excellent.wav");	
	precache_sound ("ra/welldone.wav");
	precache_sound ("ambience/thunder1.wav");
	//airshot
	precache_sound ("crx/activate.wav");
	precache_sound ("crx/gasp.wav");
	precache_sound ("crx/gasp2.wav");
	precache_sound ("crx/space.wav");
	precache_sound ("crx/onfire.wav");
	precache_sound ("crx/kaboom.wav");
	precache_sound ("crx/excell3.wav");
	precache_sound ("crx/superb.wav");
	precache_sound ("crx/onemore.wav");
	precache_sound ("crx/yeah.wav");
	//wipeout
	precache_sound ("crx/lastone.wav");
	//precache_sound ("crx/itembk3.wav");
	precache_sound ("crx/laugh2.wav");
	precache_sound ("crx/laugh4.wav");
	precache_sound ("crx/laugh7.wav");
	//precache_sound ("crx/helpyou.wav");
	//ra
	precache_sound ("crx/excell2.wav");
	precache_sound ("crx/flawless.wav");
}

void () arena_init_world =
{
	if (clanring_playmode & CLANRING_DMM4_MODE)
	{
		dmm4_init_world();
		return;
	}
	else if (clanring_playmode & CLANRING_AIRSHOT_MODE)
	{
		airshot_init_world();
		return;
	}
	else if (clanring_playmode & CLANRING_CA_MODE)
	{
		clan_arena_init_world();
		return;
	}
	else if (clanring_playmode & CLANRING_RA_MODE)
	{
		rocket_arena_init_world();
		return;
	}
};

void () arena_client_disconnect =
{
	if ((clanring_playmode & CLANRING_RA_MODE) && (self.next_team != world))
		ra_leave_next_queue(self.next_team);

	if ((clanring_playmode & CLANRING_WIPEOUT_MODE) && (self.next_team != world))
	{
		self.next_team.teamalive -= 1;
		self.next_team.teamtotal -= 1;
	}

	RemoveFromTeam();//R00k
	self.team2    		= TEAM_SPECTATOR;
	self.frags          = 0;
	//self.lagtimer    	= -30;
	self.state          = 0;	
	self.classname 		= string_null;
	//self.myip			= string_null;
	self.trueip			= string_null;
	self.takedamage 	= DAMAGE_NO;
	self.afk_time		= time;
	self.cc_queue 		= 0;//R00k
	self.cc_queue_vote	= 0;//R00k
	self.ca_player_flag	= PF_WAITING;//v1.97
	self.nextthink		= -1;
	self.think			= SUB_Null;	
	self.solid			= SOLID_NOT;
};

float () mode_is_arena
{
    if 
	(
		(clanring_playmode & CLANRING_CA_MODE) 		||
		(clanring_playmode & CLANRING_WIPEOUT_MODE)	||
		(clanring_playmode & CLANRING_RA_MODE) 		|| 
		(clanring_playmode & CLANRING_DMM4_MODE) 	|| 
		(clanring_playmode & CLANRING_AIRSHOT_MODE)
	)
        return TRUE;
    return FALSE;
}

float (entity e) IS_CA_OBSERVER
{
     if ((e.style & CLANRING_OBSERVER) && (clanring_playmode & CLANRING_CA_MODE))
        return TRUE;
     else
        return FALSE;
}
  
float (entity team1) number_teammates =
{
	local entity e;
	local float n = 0;

	e = team1;

	while (e.chain_gang)
	{
		n = n + 1;
		e = e.chain_gang;
	}
	return n;
};

float (entity team1) number_teammates_alive =
{
	local entity e;
	local float n = 0;

	e = team1;

	while (e.chain_gang)
	{
        if (e.chain_gang.deadflag == DEAD_NO && (IS_CA_OBSERVER(e.chain_gang) == FALSE) && ((e.chain_gang.style & CLANRING_CONNECTED)))
        n = n + 1;
		e = e.chain_gang;
	}
	return n;
};

float () number_teams =
{
	local float n = 0.0;
	local entity e;

	e = boss.next_team;

	while (e)
	{
		n = n + 1;
		e = e.next_team;
	}

	return n;
};

float () number_teams_alive =
{
	local float n = 0;
	local entity e;

	e = boss.next_team;

	while (e)
	{
		if (number_teammates_alive (e))
		n = n + 1;

		e = e.next_team;
	}

	return n;
};

float () number_players_alive =
{
	local float n = 0;
	local entity e;

	e = find (world, classname, "player");

	while (e)
	{
		if (e.ca_player_flag == PF_PLAYING)
		{
			if (e.health > 1)
			n = n + 1;
		}
		e = find (e, classname, "player");
	}

	return n;
};

void () CheckForLastTwoPlayers =
{
	if (number_teams_alive() != 2)
	return;

	if (number_players_alive() > 2)
	return;

	sound (world, CHAN_ITEM, "ambience/thunder1.wav", 1, ATTN_NONE);
}

float () number_total_players =
{
	local float n = 0;
	local entity e;

	e = find (world, classname, "player");

	while (e)
	{
		n = n + 1;
		e = find (e, classname, "player");
	}

	return n;
};

void () cc_queue_reset =
{
	local entity e, oself;

	e = find (world, classname, "player");

	while (e)
	{
		oself = self;
		self = e;
		if ((self.cc_queue) || (self.cc_queue_vote))
		{
			if (self.next_team != world)
				// if (clanring_playmode & CLANRING_CA_MODE)
					RemoveFromTeam();
				// else
				// 	RemoveFromQueue();

			self.cc_queue_vote = 0;
			self.cc_queue = 0;
		}
		self = oself;

		e = find (e, classname, "player");
	}
};

void (string msg) ctprint =
{
	local	entity  e;

	e = find (world, classname, "player");

	while (e != world)
	{
		if (IS_CA_OBSERVER(e) == FALSE)
		centerprint (e, msg);

		e = find (e, classname, "player");
	}
};

// Add player to the beginning of the chain
void(entity list, entity player) add_player_to_chain_pre =
{
	//??? if (list == world) return;
	
	player.chain_gang = list.chain_gang;
	list.chain_gang = player;
};

// Add player to the end of the chain
void (entity list, entity player) add_player_to_chain =
{
	while (list.chain_gang)
	list = list.chain_gang;

	list.chain_gang = player;
	player.chain_gang = world;
};

void (entity list, entity player) remove_player_from_chain =
{
	local   entity  e;

	e = list;
	while (e.chain_gang)
	{
		if (e.chain_gang == player)
		{
			e.chain_gang = player.chain_gang;
			player.chain_gang = world;//v1.5
			return;
		}
		e = e.chain_gang;
	}
};

float (entity list, entity player) ca_check_player_in_list =
{
	local entity e;
	local float check;

	e = list;

	check = 16;//crash test (fixme: change from 16 to SV_MAXPLAYERS) check = max(16, sv_maxplayers);

	while ((e != world) && (e.next_player))
	{
		if (check < 1)
		return FALSE;

		if (e.next_player == player)
		{
			return TRUE;
		}
		check = check - 1;
		e = e.next_player;
	}
	return FALSE;
};

void (entity list, entity player) add_player_to_stat_list =
{
	if (ca_check_player_in_list(list, player) == FALSE)// just incase
	{
		player.next_player = list.next_player;
		list.next_player = player;
	}
};

void (entity list, entity player) remove_player_from_stat_list =
{
	local   entity  e;

	e = list;
	while (e.next_player)
	{
		if (e.next_player == player)
		{
			e.next_player = player.next_player;
			player.next_player = world;
			return;
		}
		e = e.next_player;
	}
};

entity (float whichteam) find_team_entity =
{
	local entity e;

	e = boss.next_team;

	while (e)
	{
		if (e.team2 == whichteam)
		return e;

		e = e.next_team;
	}
	return world;
};

float () high_team =
{
	local entity e;
	local float plr_highest, n;

	e = boss.next_team;
	plr_highest = 1;

	// Find team with most players
	while (e != world)
	{
		n = number_teammates (e);
		if (n > plr_highest)
		plr_highest = n;
		e = e.next_team;
	}

	return (plr_highest);
};

float (float whichteam) lower_team =
{
	local entity pteam;
	local float t,n;

	pteam 	= find_team_entity (whichteam);
	n 	= high_team();
	t 	= number_teammates (pteam);

	if (t < n)
	return TRUE;
	else
	return FALSE;
};

void () find_team_place =
{
	local entity 	pteam;

	team_first_place 	= boss;
	team_second_place 	= boss;
	team_third_place 	= boss;
	//	team_fourth_place	= boss;//unused

	pteam = boss.next_team;

	while (pteam)
	{
		if ((pteam.wins >= team_first_place.wins))
		{
			team_second_place = team_first_place;
			team_first_place = pteam;
		}
		else
		{
			if ((pteam.wins >= team_second_place.wins))
			{
				team_third_place = team_second_place;
				team_second_place = pteam;
			}
			else
			{
				if ((pteam.wins >= team_third_place.wins))
				{
					//	team_fourth_place = team_third_place;
					team_third_place = pteam;
				}
				/*				else
				{
				if ((pteam.wins >= team_fourth_place.wins))
				team_fourth_place = pteam;
				}*/
			}
		}
		pteam = pteam.next_team;
	}
};

void () arena_set_winning_team =
{
	local entity 	pteam;

	team_first_place 	= boss;
	team_second_place 	= boss;
	team_third_place 	= boss;

	pteam = boss.next_team;

	while (pteam)
	{
		if ((pteam.wins > team_first_place.wins))
		{
			team_third_place = team_second_place;
			team_second_place = team_first_place;
			team_first_place = pteam;
		}
		else
		{
			if ((pteam.wins > team_second_place.wins))
			{
				team_third_place = team_second_place;
				team_second_place = pteam;
			}
			else
			{
				if ((pteam.wins >= team_third_place.wins))//R00k: v1.55
				{
					team_third_place = pteam;
				}
			}
		}
		pteam = pteam.next_team;
	}
};

string () report_winning_team =
{
	local float	team_score_number,tnum;
	local string 	tmp="";
	local string	team_winning_teamname="", team_winning_teamname2="", output = "";

	if (boss.round == 1) return string_null; //Match just started we know...

	arena_set_winning_team();

	if ((team_first_place.wins > team_second_place.wins))
	{
		team_score_number = (team_first_place.wins - team_second_place.wins);

		if (clanring_playmode & CLANRING_RA_MODE)
		{
			if (team_first_place.chain_gang != world)
				team_winning_teamname = team_first_place.chain_gang.netname;
		}
		else
			team_winning_teamname = sprintf("The %s", team_first_place.netname);

		tmp = ftos(team_score_number);
		output = (sprintf("\x85%s leads by ",team_winning_teamname));
		output = (strcat(output,tmp));

		if (clanring_playmode & CLANRING_RA_MODE)
			tnum = ra_wins;
		else
			tnum = (ceil(boss.max_rounds / 2));
		team_score_number = (tnum - team_first_place.wins);
		tmp = ftos(team_score_number);

		output = (strcat(output," needs "));
		output = (strcat(output,tmp));
		output = (strcat(output," to win\x85"));
	}
	else
	{
		if ((number_teams () > 2) && ((team_first_place.wins == team_second_place.wins) && (team_first_place.wins > team_third_place.wins)) )
		{
			team_score_number = team_first_place.wins;

			if (clanring_playmode & CLANRING_RA_MODE)
			{
				if (team_first_place.chain_gang != world)
					team_winning_teamname = team_first_place.chain_gang.netname;
				if (team_second_place.chain_gang != world)
					team_winning_teamname2 = team_second_place.chain_gang.netname;
				output = ("\x85");
			}
			else
			{
				team_winning_teamname = team_first_place.netname;
				team_winning_teamname2 = team_second_place.netname;
				output = ("\x85The ");
			}

			tmp = ftos(team_score_number);

			output = (strcat(output,team_winning_teamname));
			output = (strcat(output," and "));
			output = (strcat(output,team_winning_teamname2));
			output = (strcat(output," are tied at "));
			output = (strcat(output,tmp));

			if (clanring_playmode & CLANRING_RA_MODE)
				tnum = ra_wins;
			else
				tnum 	= (ceil(boss.max_rounds / 2));
			team_score_number = (tnum - team_first_place.wins);
			tmp 	= ftos(team_score_number);
			output 	= (strcat(output," need "));
			output 	= (strcat(output,tmp));
			output 	= (strcat(output," to win\x85"));
		}
		else
		{
			team_score_number = team_first_place.wins;

			tmp = ftos(team_score_number);
			output = (strcat("Teams \btied\b at ",tmp));

			if (clanring_playmode & CLANRING_RA_MODE)
				tnum = ra_wins;
			else
				tnum = (ceil(boss.max_rounds / 2));
			team_score_number = (tnum - team_first_place.wins);
			tmp = ftos(team_score_number);
			output = (strcat(output," need "));
			output = (strcat(output,tmp));
			output = (strcat(output," to win\x85"));
		}
	}
	return output;
};

void () arena_ready_players =
{
	local entity pteam, player;

	pteam = boss.next_team;
	while (pteam != world)
	{
		player = pteam.chain_gang;
		while (player != world)
		{
			if (player.style & CLANRING_CONNECTED)
			{
				player.ca_player_flag = PF_READY;
			}
			player = player.chain_gang;
		}
		pteam = pteam.next_team;
	}
};

//BAM: Returns size of linked list.
float (entity list) chain_gang_size =
{
	local entity e;
	local float n = 0;

	e = list.chain_gang;

	while (e)
	{
		n = n + 1;
		e = e.chain_gang;
	}

	return n;
};

//R00k used for debugging: Maybe pre-round onscreen display?
void (entity pteam, entity admin) print_chain_gang =
{
	local entity e;

	e = pteam;

	while (e.chain_gang)
	{
		e = e.chain_gang;
		sprint (admin, e.netname, "\n");
	}
};

//R00k
void (entity pteam) rotate_chain_gang =
{
	local entity e, thedude = world;
	local float n, p;

	p = chain_gang_size (pteam);

	if (p <= boss.start_players)
		return;

	e = pteam;

	for (n = 1; n <= p; n = n + 1)
	{
		e = e.chain_gang;

		if (e.chain_gang == world)//find the end of the chain
		{
			thedude = e;
			break;
		}
	}

	remove_player_from_chain (pteam, thedude);//remove him from the END
	add_player_to_chain_pre (pteam, thedude); //place him at the START
};

void () update_chain_gang =
{
	local entity pteam;

	pteam = boss.next_team;

	while (pteam != world)
	{
		rotate_chain_gang(pteam);
		pteam = pteam.next_team;
	}
};

void () respawn_teams =
{
	local float 	cp = 0;
	local entity 	pteam, player, tmp;

	pteam = boss.next_team;
	player = pteam.chain_gang;

	while (pteam != world)
	{
		while (player != world)
		{
			if (player.cc_queue != 0)//BAM
			{
				bprint4 (player.netname, " \bColor-Changed\b to: ", pteam.netname, "\n");
				player.cc_queue = 0;
				player.cc_queue_vote = 0;
				player.frags = 0;
				player.respawntime = 0;
				player.rounddeaths = 0;
			}

			if (cp < boss.start_players)
			{
				tmp = self;
				self = player;
				observer_end ();
				self = tmp;
			}
			else
			{
				wait_name (player);
				centerprint (player, "you will spawn when a teammate dies");
			}

			player.dmg_given_round = 0;

			player = player.chain_gang;
		}

		pteam = pteam.next_team;
		player = pteam.chain_gang;
	}
};

void (entity pteam) spawn_next_player =
{
	local entity e,tmp;
	local float n;

	//BAM
	if (chain_gang_size (pteam) <= boss.start_players)
		return;

	n = number_teammates (pteam);
	e = pteam.chain_gang;

	while ((e != world) && (n > 0))
	{
		if ((e.style & CLANRING_CONNECTED) && (IS_CA_OBSERVER(e)) && (e.ca_player_flag == PF_READY))
		{
			tmp = self;
			self = e;
			observer_end();
			self = tmp;
			return;
		}
		e = e.chain_gang;
		n = n - 1;
	}
};

void () im_dead_now_what =
{
	local string tmp = "";
	local entity e;
	local float prnd=0;

	if ((clanring_playmode & CLANRING_AIRSHOT_MODE) || (clanring_playmode & CLANRING_DMM4_MODE))
		return;

	if (self.style & CLANRING_CONNECTED)
	{
//		setcolour(self,self.team2,0);
//		tmp = ftos(self.team2);
//		stuffcmd(self,";color ");
//		stuffcmd(self,tmp);
//		stuffcmd(self," 0;\n");
//		self.team2 = 0;
		dead_name();

		self.ca_deathcamtime = time + 4;
		self.ca_player_flag = PF_DEAD;

		if ((clanring_playmode & CLANRING_WIPEOUT_MODE) && (self.next_team != world))
		{
			self.next_team.teamalive -= 1;
			if (self.next_team.teamalive < 1)
			{
				bprint3 ("The ", self.next_team.netname, " has been \bwiped out\b\n");
				prnd = floor(random() * 6) + 1;
				if (prnd == 1)
					sound (world, CHAN_VOICE, "crx/laugh2.wav", 1, ATTN_NONE);
				else if (prnd == 2)
					sound (world, CHAN_VOICE, "crx/laugh3.wav", 1, ATTN_NONE);
				else if (prnd == 3)
					sound (world, CHAN_VOICE, "crx/laugh4.wav", 1, ATTN_NONE);
				else if (prnd == 4)
					sound (world, CHAN_VOICE, "crx/laugh7.wav", 1, ATTN_NONE);
				else
					sound (world, CHAN_VOICE, "ra/laugh.wav", 1, ATTN_NONE); //R00k, this might be annoying?

				e = self.next_team.chain_gang;
				while (e)
				{
					if (e.style & CLANRING_CONNECTED)
						e.respawntime = 0;
					e = e.chain_gang;
				}
			}
			else
			{
				if (self.next_team.teamalive == 1)
				{
					sound(world, CHAN_AUTO, "crx/lastone.wav", 1, ATTN_NONE);
				}

				//set player's respawn and update team nextspawn for huds
				self.rounddeaths = (self.rounddeaths + 1);
				self.respawntime = (time + wipeout_get_respawn(self.rounddeaths));
				if ((self.next_team.nextspawn == 0) || (self.next_team.nextspawn > self.respawntime))
				{
					self.next_team.nextspawn = self.respawntime;
				}
			}
		}
	}
};

void (entity pteam) arena_remove_team =
{
	//local string pstring;
	local entity plast;

	//pstring = (pteam.netname);
	//bprint3 ("Removing the ",(pstring),"\n");

	plast = boss;

	while (plast.next_team)
	{
		if (plast.next_team == pteam)
		{
			plast.next_team = pteam.next_team;
			break;
		}
		plast = plast.next_team;
	}

	remove (pteam);
};

void () RemoveFromTeam =
{
	if (self.next_team == world)
	return;

	if (self.next_team == self)
	return;

	if (!self.cc_queue)
	bprint4 (self.netname, "\b has left the ", self.next_team.netname, "\n");

	if (self.ca_player_flag == PF_PLAYING)
	{
		if (number_teammates_alive (self.next_team))
		spawn_next_player (self.next_team);
	}

	remove_player_from_chain(self.next_team, self);
	remove_player_from_stat_list(self.next_team, self);

	//no players exist on this team, kill the team
	if (number_teammates (self.next_team) == 0)
	{
		pqc_erase_team(self.next_team.team2);
		arena_remove_team(self.next_team);
	}

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

	if (clanring_playmode & CLANRING_CA_MODE)
    	motd_playercount();// R00k

	self.ca_player_flag = PF_WAITING;
	self.movetarget 	= world;
	self.frags 			= -99;
};

void (float response) arena_observer_confirm_leave_response =
{
	self.style = self.style - (self.style & CLANRING_CONFIRM_LEAVE);
	if (response)
	{
		if (self.next_team != world)
		{
			RemoveFromTeam();
			observer_start();
		}
	}
	else
	{
		sprint (self, "Cancelled\n");
	}
};

void () arena_delete_teams =
{
	local entity pteam;

	if (teamplay)
	{
		while (boss.next_team)
		{
			pteam = boss.next_team;
			boss.next_team = pteam.next_team;
			pqc_erase_team(pteam.team2);//R00k v1.82
			remove (pteam);
		}
	}

	boss.next_team 		= world;
	boss.next_player 	= world;
	boss.wait 		= 0;
};

void(float whichteam) Join_Team =
{
	local entity pteam;
	local string tmp;

	if ((boss.state == CA_MATCH_CLEANUP) || (boss.state == CA_MATCH_OVER))
	{
		sprint (self, "Try again in 5 seconds...\n");
		return;
	}

	if (boss.state != CA_MATCH_WAITING)
	{
		sprint(self,"\bYou may not join at this time.\n");
		return;
	}

	if (self.next_team != world)
	{
		sprint(self,"\bYou have already commited to a team.\n");
		return;//already on a team
	}

	if (self.lip > time)//R00k: FIXed?
	{
		sprint(self,"\bYou may not join at this time.\n");
		return;
	}

	self.lip = time + 2; //R00k: two seconds between team choice will stop script spam

	pteam = find_team_entity(whichteam);

	if (pteam == world)
	{
		if (number_teams () < boss.max_teams)
		{
			pteam = spawn();

			pteam.classname 	= "ca_team";
			pteam.team2			= whichteam;
			pteam.wins			= 0;
			pteam.losses 		= 0;
			pteam.armorvalue 	= 0;
			pteam.health		= 0;
			pteam.netname 		= strings_get_teamname (pteam.team2);

			pteam.next_player	= world;//init entity
			pteam.chain_gang 	= world;//init entity

			pteam.next_team   	= boss.next_team;
			boss.next_team    	= pteam;

			//announce2 ("creating the ", pteam.netname);
			announce3 (self.netname, " has joined the ", pteam.netname);
			pqc_new_team (pteam.team2);
		}
		else
		{
			sound (self, CHAN_VOICE, "player/axhit2.wav", 1, ATTN_NORM);
			sprint (self, "The maximum amount of teams exists.\n");
			return;
		}
	}
	else
	{
		if (number_teammates (pteam) == boss.max_players)
		{
			sound (self, CHAN_VOICE, "player/axhit2.wav", 1, ATTN_NORM);
			sprint (self, "That team is \bfull\b.\n");
			return;
		}

		announce3 (self.netname, " has joined the ", pteam.netname);
	}

	self.team2  	= whichteam;
	self.next_team 	= pteam;
	self.frags 		= 0;
	self.respawntime = 0;
	self.rounddeaths = 0;

	add_player_to_stat_list(pteam,self);
	add_player_to_chain(pteam,self);

	tmp = ftos(self.team2);

	setcolour(self,self.team2,self.team2);

	stuffcmd(self,";color ");
	stuffcmd(self,tmp);
	stuffcmd(self,";\n");

	ready_name();

	motd_top5 = string_null;
	motd_top6 = string_null;
	motd_playercount();
	stats_reset_player (); //BAM MOVED

};

float (float n) join_team2 =
{
	local entity pteam;
	local string tmp;

	if (!(self.style & CLANRING_CONNECTED))//fixed (02/24/2022)
		return FALSE;

	if ((boss.state == CA_MATCH_CLEANUP) || (boss.state == CA_MATCH_OVER))
	{
		sprint (self, "Try again in 5 seconds...\n");
		self.cc_queue = 0;
		self.cc_queue_vote = 0;
		return FALSE;
	}

	pteam = find_team_entity (n);

	if (pteam == world)
	{
		pteam = spawn();
		pteam.classname 	= "ca_team";
		pteam.team2		= n;
		pteam.wins		= 0;
		pteam.losses 		= 0;
		pteam.netname 		= strings_get_teamname (pteam.team2);
		pteam.armorvalue	= 0;
		pteam.health		= 0;
		pteam.next_player	= world;//init entity
		pteam.chain_gang 	= world;//init entity
		pteam.next_team   	= boss.next_team;
		boss.next_team    	= pteam;
		pqc_new_team (pteam.team2);
	}

	self.team2 	= TEAM_SPECTATOR;
	self.team 	= ((self.team2) + 1);

	self.ca_player_flag	= PF_WAITING;

	self.next_team 	= pteam;
	add_player_to_stat_list(pteam,self);
	add_player_to_chain(pteam,self);

	tmp = ftos(self.team2);

	setcolour(self,n,0);

	stuffcmd(self,";color ");
	stuffcmd(self,tmp);
	stuffcmd(self," 0;\n");

	motd_top5 = string_null;
	motd_top6 = string_null;
	stats_reset_player ();
	return TRUE;
};

void () ca_cc_vote_join =
{
	local entity pteam, tmp, p;
	local string color;

	p = find (world, classname, "player");

	while (p)
	{
		if (p.cc_queue_vote)
		{
			tmp = self;
			self = p;
			self.cc_queue = self.cc_queue_vote;
			self.cc_queue_vote = 0;

			if (join_team2 (self.cc_queue) == TRUE)
			{
				pteam = find_team_entity (self.cc_queue);
				sprint (self, "In queue to \bColor-Change\b to ", pteam.netname, "...\n");

				color = ftos (self.cc_queue);
				setcolour (self, self.cc_queue, 0);
				stuffcmd (self, ";color ");
				stuffcmd (self, color);
				stuffcmd (self, " 0;\n");
			}

			self = tmp;
		}
		p = find (p, classname, "player");
	}
};

void (float whichteam) Request_Join_Team =
{
	local entity pteam;
//	local string color;

	self.impulse = 0;//R00k

	//already on a team
	if (self.next_team != world)
	return;

	// Already in queue to join a team
	if ((self.cc_queue) || (self.cc_queue_vote))
	{
		sprint (self, "In queue to \bjoin\b team, please wait...\n");
		return;
	}

	pteam = find_team_entity (whichteam);

	if (number_teammates (pteam) >= boss.max_players)
	{
		sprint (self, "That team is \bfull\b.\n");
		return;
	}

	if (pteam == world)
	{
		if (number_teams () >= boss.max_teams)
		{
			sprint (self, "The maximum number of teams already exists.\n");
			return;
		}
	}

	if ((boss.state == CA_MATCH_CLEANUP) || (boss.state == CA_MATCH_OVER))
	{
		sprint (self, "Try again in 5 seconds...\n");
		self.cc_queue = 0;
		self.cc_queue_vote = 0;
		return;
	}

//	if (clanring_playmode & CLANRING_CA_CC_VOTE)//FIXME (22/03/12 10:55am)
	{
		if ((boss.count < 8))// After team line-up / spawns take place!
		{
			if (vote_init("allow new players to join the match.","", ca_cc_vote_join))
			{
				self.cc_queue_vote = whichteam;
				vote_yes();
			}
		}
		else
		{
			sprint (self, "Try again in 5 seconds...\n");
			return;
		}
	}
/*	else
	{
		if ((boss.count < 8))// After team line-up / spawns take place!
		{
			//if (cc_queue_allowed (whichteam))
			{
				self.cc_queue = whichteam;
				if (join_team2(whichteam) == TRUE)
				{
					pteam = find_team_entity (whichteam);
					sprint (self, "In queue to \bColor-Change\b to ", pteam.netname, "...\n");

					color = ftos (self.cc_queue);
					setcolour (self, self.cc_queue, 0);
					stuffcmd (self, ";color ");
					stuffcmd (self, color);
					stuffcmd (self, " 0;\n");
				}
			}
		}
		else
		{
			sprint (self, "Try again in 5 seconds...\n");
			return;
		}
	}*/
};
//---------------------------------------------------------------------------------------------
void () Teamplay_Select_Team =
{
	if (clanring_playmode & CLANRING_RA_MODE)
	{
		ra_select_team();
		return;
	}

	if (!(clanring_playmode & CLANRING_CA_MODE))
	{
		// Teamplay_Join_Queue();
		// return;

		if (self.impulse == 1)
		{
			if (number_teams() < 1)
				self.impulse = 1;
			else
			{
				if (boss.next_team.team2 == COLOR_BLUE)
					self.impulse = 2;
				else
					self.impulse = 1;
			}
		}
		else if (self.impulse == 2)
		{
			self.impulse = 5;
		}
		else
		{
			self.impulse = 0;
			return;
		}
	}

	if (boss.busy == TRUE)
	{
		sprint(self,"Cleaning up match end. Try again in a few seconds...\n");
		self.impulse = 0; //R00k cleanup console spam.
		return;
	}

	clear_afk_status(self);

    if (self.impulse == 1)
    {
        if (boss.state == CA_MATCH_WAITING)
        Join_Team(COLOR_BLUE);
        else
        Request_Join_Team (COLOR_BLUE);
    }
    else if (self.impulse == 2)
    {
        if (boss.state == CA_MATCH_WAITING)
        Join_Team(COLOR_RED);
        else
        Request_Join_Team (COLOR_RED);
    }
    else if (self.impulse == 3)
    {
        if (boss.state == CA_MATCH_WAITING)
        Join_Team(COLOR_YELLOW);
        else
        Request_Join_Team (COLOR_YELLOW);
    }
    else if (self.impulse == 4)
    {
        if (boss.state == CA_MATCH_WAITING)
        Join_Team(COLOR_GREEN);
        else
        Request_Join_Team (COLOR_GREEN);
    }

	// We don't want this team anymore
	if (self.impulse == 5)
	{
		motd_arena_start();	//r00k
		if (self.cc_queue_vote)
		{
			if (/*(clanring_request.classname == "cc_vote") && */(clanring_request.owner == self))//FIXME: clanring_request doesnt have a dynamic classname; this will always be false.
			{
				Request_Poll_Cleanup();
				self.cc_queue_vote = 0;
			}
		}

		//allow player to leave team when they are waiting or between rounds
		if ((self.ca_player_flag == PF_WAITING) || (boss.timetofight == FALSE))
		{
			if (self.next_team != world)
			RemoveFromTeam ();
		}

		if (self.cc_queue)
		{
			if (self.next_team != world)
			RemoveFromTeam ();

			sprint (self, "Cancelling \bColor-Change\b...\n");
			self.cc_queue = 0;
			self.cc_queue_vote = 0;
		}

		//don't change to white if remove didn't work
		if ((self.style & CLANRING_CONNECTED) && (self.next_team == world))
		{
			stuffcmd(self,";color 0;\n");
		}
	}

	self.impulse = 0;
};

//-----------------------------------------------------------------------
void () arena_pause_item =
{
	if ((self.nextthink == CONTENT_EMPTY))
	{
		return;
	}

	self.nextthink = (self.nextthink + 1000000);
	self.clanring_old_velocity = self.velocity;
	self.velocity = '0 0 0';

	if ((self.classname == "grenade"))
	{
		self.movetype = MOVETYPE_FLY;
	}
};

void () arena_pause_player =
{
	if ((IS_CA_OBSERVER(self)) || self.deadflag)
	{
		self.clanring_old_velocity = '0 0 0';
		return;
	}
	self.movetype		= MOVETYPE_FLY;
	self.clanring_old_velocity 	= self.velocity;
	self.velocity 		= '0 0 0';

	if ((self.nextthink == CONTENT_EMPTY))
	{
		return;
	}
	self.nextthink = (self.nextthink + 1000000);
};

void () arena_pause =
{
	if ((boss.state == CA_MATCH_WAITING) || (clanring_state & CLANRING_MATCH_PAUSED) || (gameover))
	{
		return;
	}

	clanring_match_pause_time = time;
	clanring_state = clanring_state | CLANRING_MATCH_PAUSED;
	boss.timetofight = FALSE;//v1.4
	utils_do_projectiles (arena_pause_item);
	utils_do_arena_players (arena_pause_player);
	announce ("game paused");
};

void () arena_unpause_item =
{
	if ((self.nextthink == CONTENT_EMPTY))
	{
		return;
	}
	self.nextthink = ((self.nextthink - 1000000) + clanring_match_pause_time);
	self.velocity = self.clanring_old_velocity;
	if ((self.classname == "grenade"))
	{
		self.movetype = MOVETYPE_BOUNCE;
	}
};

void () arena_unpause_player =
{
	self.pain_finished 	= (self.pain_finished + clanring_match_pause_time);
	self.air_finished 	= (self.air_finished + clanring_match_pause_time);

	if ((IS_CA_OBSERVER(self)) || self.deadflag)
	{
		return;
	}
	self.movetype = MOVETYPE_WALK;
	self.velocity = self.clanring_old_velocity;
	if ((self.nextthink == CONTENT_EMPTY))
	{
		return;
	}
	self.nextthink = ((self.nextthink - 1000000) + clanring_match_pause_time);
};

// This is called at the start of round in all arena modes for all active players
void () arena_fight_and_shoot =
{
	if (!(self.style & CLANRING_OK_TO_SHOOT))
		self.style = self.style | CLANRING_OK_TO_SHOOT;

	self.killstreak = 0;
	self.combo_frags = 0;
	self.combo_time = 0;
	self.arena_packs = 0;

	centerprint(self, "\bFIGHT!");

	clear_name();
};

void () arena_unpause =
{
	if (!(clanring_state & CLANRING_MATCH_PAUSED))
	{
		return;
	}
	clanring_state = clanring_state - (clanring_state & CLANRING_MATCH_PAUSED);
	utils_do_projectiles (arena_unpause_item);
	utils_do_arena_players (arena_unpause_player);
	boss.timetofight = TRUE;//R00k added v1.4
	announce ("game on!");
	WriteByte (MSG_ALL, SVC_CENTERPRINT);
	WriteString (MSG_ALL, " ");
	utils_do_arena_players (arena_fight_and_shoot);
};

//R00k changed:v1.4
void () arena_unpause_countdown_think =
{
	if (self.count == 0)
	{
		boss.unpausing = FALSE;
		arena_unpause ();
		ctprint("\bFIGHT!");
		sound(world, CHAN_AUTO, "crx/fight.wav", 1, ATTN_NONE);
		remove (self);
	}
	else
	{
		if (self.count == 1)
		{
			ctprint("1");
			sound(world, CHAN_AUTO, "crx/one.wav",1, ATTN_NONE);
		}
		else
		{
			if (self.count == 2)
			{
				ctprint("2\n");
				sound(world, CHAN_AUTO, "crx/two.wav", 1, ATTN_NONE);
			}
			else
			{
				if (self.count == 3)
				{
					ctprint("3\n");
					sound(world, CHAN_AUTO, "crx/three.wav", 1, ATTN_NONE);
				}
				else
				{
					if (self.count == 5)
					{
						ctprint("prepare to fight\n");
					}
				}
			}
		}
	}

	self.nextthink = (time + 1);
	self.count = (self.count - 1);
};

void () arena_start_unpause_countdown =
{
	local entity countdown;

	if ((boss.unpausing))
	{
		return;
	}
	boss.unpausing = TRUE;
	countdown = utils_make_scheduled_event (arena_unpause_countdown_think, 1);
	countdown.count = 4;
	announce ("Unpausing match...");
};
//-----------------------------------------------------------------------
//Match is over so reset player
void() arena_reset_player =
{
	if (self.next_team != world)
	remove_player_from_chain(self.next_team,self);

	updatename(self,self.netname);
	self.weaponlevel 	= 0;
	self.next_team 	 	= world;

	//R00K: Only respawn players that hadn't died
	if (self.ca_player_flag == PF_PLAYING)
	{
		self.ca_player_flag = PF_WAITING;
		self.deadflag 	 	= DEAD_DYING;
		self.think 	 		= respawn;
		self.nextthink 	 	= (time + sys_ticrate);
	}

	self.movetarget  	= world;
	self.model 	 		= string_null;
	self.mdl	 		= string_null;
};

void() arena_restart_player =
{
	clear_name();
	self.solid = SOLID_NOT;
	self.model = string_null;
	//spawn_tfog (self.origin);
	self.deadflag = DEAD_DYING;
	self.think = respawn;
	self.nextthink = time + 0.1;
}

//void () execute_changelevel;
void() reset_match =
{
	utils_do_arena_players (arena_reset_player);
	arena_delete_teams();
	boss.busy = FALSE;//triggered TRUE in arena_match_end()

	remove(self);
};

void () report_mvp_game =
{
	local 	entity	current_player;
	local	float 	mvp;
	local	string	name, smvp;

	mvp = 0;
	name = "No one";

	current_player = find(world, classname, "player");

	while (current_player != world)
	{
		if ((current_player.style & CLANRING_CONNECTED) && (current_player.next_team != world))
		{
			if (current_player.dmg_given > mvp)
			{
				mvp = (current_player.dmg_given);
				name = current_player.netname;
			}
		}
		current_player = find(current_player, classname, "player");
	}

	ca_mvp_entity = current_player;//R00k added for MVP Intermission

	smvp = ftos(mvp);
	announce4(name," was the \bmatch\b MVP with ",smvp," points of damage given.");
};

void () arena_match_end =
{
	local string temp, t2="";//, mc;
	local entity pteam;

	boss.busy = TRUE;

	if (boss.aborted == FALSE)
	{
		stats_final_summary();

		if ((clanring_playmode & CLANRING_DMM4_MODE) || (clanring_playmode & CLANRING_AIRSHOT_MODE))
		{
			dmm4_report_winner();
		}
		else
		{
			bprint ("\n");
			pteam = boss.next_team;
		
			for (pteam = boss.next_team; pteam != world; pteam = pteam.next_team)
			{
				t2 = strpad (8, pteam.netname);
				bprint(t2);		
				bprint(" \bwon:\b ");
				t2 = ftos (pteam.wins);
				bprint (t2);
				bprint(" \blost:\b ");
				t2 = ftos (pteam.losses);
				bprint (t2);
				bprint("\n");
				t2 = "";
			}	

			bprint ("\n");	

			if (clanring_playmode & CLANRING_RA_MODE)
			{
				if (team_first_place.chain_gang != world)
					announce2((team_first_place.chain_gang.netname)," has won the match.");

//				report_mvp_game();  Ya, yeah, we know...

				bprint ("The match is over\n");//required for Qrack cl_autodemo 2
	
				if ((!(clanring_gameconfig & CLANRING_ENABLE_MATCHSOUNDS)) || (!clanring_matchsound_count))
					sound (world, CHAN_AUTO, "ra/gong.wav", 1 , ATTN_NONE);
	
				NextLevel();
				return;
			}
			else
				announce2((team_first_place.netname)," has won the match.");	
			bprint ("\n");
		}
		if (number_teammates(team_first_place) > 1)    // Only show MVP for non 1v1 games.
			report_mvp_game();
	}
	else bprint ("Match \baborted\b.\n");//Added v1.4c

	if (clanring_request.noise1 == "allow new players to join the match.")//gameover before a vote to join passed.
		Request_Poll_Cleanup();

	cc_queue_reset (); // Cancel Color-Change

	bprint ("The match is over\n");//required for Qrack cl_autodemo 2

	sound (world, CHAN_AUTO, "ra/gong.wav", 1 , ATTN_NONE);

	// if ((boss.round == 5) && (clanring_playmode & CLANRING_CA_MODE) && (team_first_place != world) && (team_first_place.wins == 5))
	// {
	// 	utils_make_scheduled_event(do_sound_sweep, 2);
	// }
	// else if ((boss.round == 6) && (clanring_playmode & CLANRING_CA_MODE) && (team_first_place != world) && (team_first_place.wins == 5))
	// {
	// 	utils_make_scheduled_event(do_sound_owned, 2);
	// }

	boss.round 		 = 1;
	boss.count 		 = 10;
	boss.wait 		 = 0;
	boss.timetofight = FALSE;
	boss.state 		 = CA_MATCH_CLEANUP;

    gameover = FALSE;

	boss.aborted = FALSE;
	boss.draw = FALSE;

	if (clanring_playmode & CLANRING_RA_MODE)
		ra_initial_rules_shown = FALSE;

	temp = ftos(boss.round);
	localcmd("skill \"", temp, "\"\n");//this still used?    TODO: Replace with infokey

	utils_make_scheduled_event(reset_match, 1);
	pqc_match_time (0, 0);
	pqc_match_reset();
};

//R00k v1.56
//Called at end of rounds...
void() arena_refresh_player =
{
	updatename(self,self.netname);

	if (clanring_playmode & CLANRING_RA_MODE)
		return; //bucksh0t: RA will handle this in ra_spawn_players

	//R00K: Only respawn players that hadn't died
	if (self.ca_player_flag == PF_PLAYING)
	{
		self.ca_player_flag = PF_WAITING;
		self.deadflag 	 	= DEAD_DYING;
		self.think 	 		= respawn;
		self.nextthink 	 	= (time + sys_ticrate);
	}
	self.model  = string_null;
	self.mdl = string_null;
	self.killed	 = FALSE;
	self.respawntime = 0;
	self.rounddeaths = 0;

	// if (clanring_playmode & CLANRING_WIPEOUT_MODE)
	// {
	// 	self.items = self.items - (self.items & IT_QUAD);
	// 	self.super_damage_finished = 0;
	// 	self.super_time = 0;
	// 	if (!self.invincible_finished)
	// 	{
	// 		self.effects = self.effects - (self.effects & EF_DIMLIGHT);
	// 	}
	// 	self.effects = self.effects - (self.effects & EF_BLUE);
	// }
};

void() reset_round =
{
	local string temp;

	if (clanring_playmode & CLANRING_WIPEOUT_MODE)
		utils_do_item(votables_disable_item, "item_artifact_super_damage");

	boss.timetofight = FALSE;
	boss.wait   = 0;
	boss.count  = (clanring_playmode & CLANRING_RA_MODE) ? 6 : 10;
	boss.round  = boss.round + 1;
	temp = ftos(boss.round);
	localcmd("skill \"", temp, "\"\n");

	if (clanring_playmode & CLANRING_RA_MODE)
	{
		if (boss.draw == FALSE)
			ra_next_player_ready(boss.next_color);
		announce("prepare to fight");
	}

	utils_do_arena_players(arena_refresh_player);

	boss.state = CA_MATCH_ROUNDSTART;
	boss.busy = FALSE;
	boss.draw = FALSE;
	remove(self);//delete temp ent that called this function
};

void (float x,float y) announce_winner =
{
	if (x == 200 && y == 100)
	{
		sound(world, CHAN_AUTO, "crx/flawless.wav", 1, ATTN_NONE);// Health = 100 Armor == 200 = 300
		ctprint("Flawless Victory");
	}
	else
	if (x >= 100 && y >= 75)
	{
		sound(world, CHAN_AUTO, "ra/outstand.wav", 1, ATTN_NONE);// Health >= 75 Armor >= 100 = 175
		ctprint("Outstanding");
	}
	else
	if (x >= 75 && y >= 50)
	{
		sound(world, CHAN_AUTO, "crx/excell2.wav", 1, ATTN_NONE);// Health >= 50 Armor >= 75 == 125
		ctprint("Excellent");
	}
	else
	if (x >= 50 && y >= 50)
	{
		sound(world, CHAN_AUTO, "ra/welldone.wav", 1, ATTN_NONE);// Health >=50 Armor >= 50 == 100
		ctprint("Well Done");
	}
};

void () report_mvp_round =
{
	local 	entity	current_player;
	local	float 	mvp;
	local	string	name, smvp;

	mvp = 0;
	name = "No one";

	current_player = find(world, classname, "player");

	while (current_player != world)
	{
		if ((current_player.style & CLANRING_CONNECTED) && (current_player.next_team != world))
		{
			if (current_player.dmg_given_round > mvp)
			{
				mvp = (current_player.dmg_given_round);
				name = current_player.netname;
			}
		}
		current_player = find(current_player, classname, "player");
	}
	smvp = ftos(mvp);
	announce4(name," was the round MVP with ",smvp," points of damage given.");
	bprint("\n");
};

void() round_end =
{
	local entity current_player, wteam = world, lteam;
	local string temp;
	local float prand;

	boss.busy = TRUE;//hold the presses!

	//Look for players alive...

	current_player = find(world, classname, "player");

	while (current_player != world)
	{
		if ((current_player.ca_player_flag == PF_PLAYING) || (current_player.ca_player_flag == PF_READY))
		{
			if ((current_player.health) && (current_player.style & CLANRING_CONNECTED) && (current_player.next_team != world))
			{
				wteam = current_player.next_team;
				wteam.armorvalue = (wteam.armorvalue + current_player.armorvalue);
				wteam.health = (wteam.health + current_player.health);

				bprint3 ("\b[", current_player.netname, " has ");
				temp = ftos (current_player.health);
				bprint2 (temp, " Health ");
				temp = ftos (current_player.armorvalue);
				bprint2 (temp, " Armor\b]\n");
			}
		}
		current_player = find(current_player, classname, "player");
	}

	if (clanring_playmode & CLANRING_RA_MODE)
	{
		if (wteam != world)//ugh lagouts cause all hell
		{
			wteam.wins = wteam.wins + 1;//up team rounds won
			pqc_team_frags(wteam.team2, wteam.wins);

			bprint ("\n");
			if (wteam.chain_gang != world)
			{
				wteam.chain_gang.frags = wteam.wins;
				announce2((wteam.chain_gang.netname)," has won the round.");
				announce_winner(wteam.chain_gang.armorvalue,wteam.chain_gang.health);
			}
		}

		//find team with dead player and put them back in the queue
		lteam = boss.next_team;
		while (lteam != world)
		{
			if (lteam != wteam)
			{
				current_player = lteam.chain_gang;
				if ((current_player != world) && (current_player.ca_player_flag == PF_DEAD))
				{
					lteam.losses = lteam.losses + 1;
					current_player.ca_player_flag = PF_WAITING;
					boss.next_color = lteam.team2;

					prand = floor(random() * 11) + 1;
					if (prand == 4)
						lteam.team2 = COLOR_YELLOW;
					else
						lteam.team2 = prand;
					current_player.team2 = lteam.team2;
					setcolour(current_player,lteam.team2,0);
					temp = ftos(lteam.team2);
					stuffcmd(current_player,";color ");
					stuffcmd(current_player,temp);
					stuffcmd(current_player," 0;\n");

					ra_join_next_queue(lteam);
					break;
				}
			}
			lteam = lteam.next_team;
		}

		if (wteam.wins >= ra_wins)
		{
			team_first_place = wteam;
			gameover = TRUE;
			boss.aborted = FALSE;
			arena_match_end();
			return;
		}
	}
	else
	{
		if (wteam != world)//ugh lagouts cause all hell
		{
			wteam.wins = wteam.wins + 1;//up team rounds won
			pqc_team_frags(wteam.team2, wteam.wins);

			bprint ("\n");
			announce2((wteam.netname)," has won the round.");
		}

		//BAM: Other teams' losses increases by 1.
		lteam = boss.next_team;
		while (lteam != world)
		{
			if (lteam != wteam)
			lteam.losses = lteam.losses + 1;

			lteam = lteam.next_team;
		}

		report_mvp_round();

		if (wteam.wins >= (ceil(boss.max_rounds / 2)))// wins > 50% of rounds wins the match
		{
			team_first_place = wteam;
			gameover = TRUE;
			arena_match_end();
			return;
		}

		if (boss.round >= boss.max_rounds)
		{
			find_team_place();
			if (team_first_place.wins > team_second_place.wins)//Keep playing until there is a winner!
			{
				gameover = TRUE;
				arena_match_end();
				return;
			}
		}

		if (wteam != world)//ugh lagouts cause all hell
		{
			wteam.armorvalue 	= (wteam.armorvalue / number_teammates_alive (wteam));
			wteam.health 	= (wteam.health / number_teammates_alive (wteam));
			announce_winner(wteam.armorvalue,wteam.health);

			wteam.armorvalue 	= 0;//this is not required; it's a local entity.
			wteam.health 	= 0;//this is not required; it's a local entity.
		}
	}
	utils_make_scheduled_event(reset_round, 0.5);
};

//
// 1v1 Mode ***************************************************************
//

void(float whichteam) Join_Queue =
{
	local entity pteam;

	if ((boss.state == CA_MATCH_CLEANUP) || (boss.state == CA_MATCH_OVER))
	{
		sprint (self, "Try again in 5 seconds...\n");
		return;
	}

	if (boss.state != CA_MATCH_WAITING)
	{
		sprint(self,"\bYou may not join at this time.\n");
		return;
	}

	if (self.next_team != world)
	{
		sprint(self,"\bYou have already commited to a team.\n");
		return;//already on a team
	}

	if (self.lip > time)//R00k: FIXed?
	{
		sprint(self,"\bYou may not join at this time.\n");
		return;
	}

	if ((clanring_playmode & CLANRING_AIRSHOT_MODE) || (clanring_playmode & CLANRING_DMM4_MODE))
	{
		if (number_teams() < 1)
			whichteam = 4;
		else
			whichteam = 13;
	}

	self.lip = time + 2; //R00k: two seconds between team choice will stop script spam

	if (number_teams () < boss.max_teams)
	{
		pteam = spawn();

		pteam.classname 	= "ca_team";
		pteam.team2			= whichteam;
		pteam.wins			= 0;
		pteam.losses 		= 0;
		pteam.armorvalue 	= 0;
		pteam.health		= 0;
		pteam.netname 		= self.netname;

		pteam.next_player	= world;//init entity
		pteam.chain_gang 	= world;//init entity

		pteam.next_team   	= boss.next_team;
		boss.next_team    	= pteam;

		//announce2 ("creating the ", pteam.netname);
		announce2 (self.netname, " has joined");
		pqc_new_team (pteam.team2);
	}
	else
	{
		sound (self, CHAN_VOICE, "player/axhit2.wav", 1, ATTN_NORM);
		sprint (self, "The maximum amount of teams exists.\n");
		return;
	}

	self.team2  	= whichteam;
	self.next_team 	= pteam;

	add_player_to_stat_list(pteam,self);
	add_player_to_chain(pteam,self);

	// tmp = ftos(self.team2);

	// setcolour(self,self.team2,self.team2);

	// stuffcmd(self,";color ");
	// stuffcmd(self,tmp);
	// stuffcmd(self,";\n");

	motd_top5 = string_null;
	motd_top6 = string_null;
	stats_reset_player (); //BAM MOVED
};

// not being used?
// void () RemoveFromQueue =
// {
// 	if (self.next_team == world)
// 	return;

// 	if (self.next_team == self)
// 	return;

// 	if (self.ca_player_flag == PF_PLAYING)
// 	return;

// 	if (!self.cc_queue)
// 	bprint4 (self.netname, "\b has left\n");

// 	remove_player_from_chain(self.next_team, self);
// 	remove_player_from_stat_list(self.next_team, self);

// 	pqc_erase_team(self.next_team.team2);

// 	local entity plast = boss;
// 	while (plast.next_team)
// 	{
// 		if (plast.next_team == self.next_team && plast.netname == self.netname)
// 		{
// 			plast.next_team = self.next_team.next_team;
// 			break;
// 		}
// 		plast = plast.next_team;
// 	}
// 	remove (self.next_team);

// 	//reset player
// 	self.team2 	= TEAM_SPECTATOR;
// 	self.team 	= ((self.team2) + 1);//v1.1b fixed
// 	self.next_team 	= world;
// 	self.weaponlevel = 0;

// 	//This is fine dont change this!
// 	if (self.style & CLANRING_CONNECTED)
// 	{
// 		setcolour (self, 0, 0);
// 	}

// 	self.ca_player_flag = PF_WAITING;
// 	self.movetarget 	= world;
// 	self.frags 			= -99;
// };

// not being used?
// void () Teamplay_Join_Queue =
// {
// 	if (boss.busy == TRUE)
// 	{
// 		sprint(self,"Cleaning up match end. Re-join in 3 seconds.\n");		
// 		return;
// 	}

// 	clear_afk_status(self);
		
// 	if (self.impulse == 1 && self.next_team == world)
// 	{
// 		if (boss.state == CA_MATCH_WAITING)
// 			Join_Queue(self.team - 1);
// 	}
	
// 	if (self.impulse == 2 && self.next_team != world)
// 	{
// 		if (self.cc_queue_vote)
// 		{
// 			if ((clanring_request.classname == "cc_vote") && (clanring_request.owner == self))
// 			{
// 				Request_Poll_Cleanup();
// 				self.cc_queue_vote = 0;
// 			}
// 		}
		
// 		if (boss.state == CA_MATCH_WAITING)
// 		{
// 			if (self.next_team != world)
// 				RemoveFromQueue ();
// 		}
		
// 		if (self.cc_queue)
// 		{
// 			if (self.next_team != world)
// 				RemoveFromQueue ();
			
// 			sprint (self, "Cancelling \bColor-Change\b...\n");
// 			self.cc_queue = 0;
// 			self.cc_queue_vote = 0;
// 		}
					
// 		if (self.style & CLANRING_CONNECTED)
// 		{		
// 			stuffcmd(self,";color 0;\n");
// 		}		
// 	}
	
// 	self.impulse = 0;
// };