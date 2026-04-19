//
// Score.qc
//
// Routines to keep track of team scores in matches.
//
// All code by J.P. Grossman unless otherwise commented
//
// Scoreboard code is incomplete; will be finished for V4.1
//
float () match_count_players;
void () match_end;
void () match_update_score_info;
string (float num) strings_get_colour;

void(string slot) score_clear_persisted_colored_teamscores =
{
	local float color;
	local string key;

	color = 0;
	while (color < 14)
	{
		key = sprintf("%s:%s", slot, strings_get_colour(color));
		if (infokey(world, key) != "")
			forceinfokey(world, key, "");
		color = color + 1;
	}
};

//
//  I N I T
//
//  Reset the score stuff at the start of a match
//
void () score_init = 
{
	clanring_winning_teamname = CLANRING_STRING_TIED;
	clanring_score_number = 0;
	clanring_first_place = clanring_sentinel.next_team;
	clanring_second_place = clanring_first_place.next_team;
};

//
//  I N I T  W O R L D
//
void () score_init_world = 
{
	CLANRING_STRING_TIED = "            Tied at ";
	clanring_score_count = 0;
	// On samelevel/new-game restarts, worldspawn can retain the previous
	// teamscoreN:<color> keys. Clear any carried-over colored slots now, but
	// preserve whether a :none placeholder is already live so match start can
	// blank it before publishing the active team colors.
	score_clear_persisted_colored_teamscores("teamscore1");
	score_clear_persisted_colored_teamscores("teamscore2");
	match_last_ts1_color = (infokey(world, "teamscore1:none") != "") ? -2 : -1;
	match_last_ts2_color = (infokey(world, "teamscore2:none") != "") ? -2 : -1;
};

//
//  C H E C K  S U D D E N  D E A T H
//
void () score_check_sudden_death = 
{
	self.nextthink = -1;
	if (clanring_winning_teamname != CLANRING_STRING_TIED)
		match_end();
	else
		bprint("\x9D\xD0\xEC\xE1\xF9\xA0\xCF\xEE\xA1\x9F\n");
};

//
//  G E T  T O P 2
//
void () score_get_top2 = 
{
	local entity pteam;

	clanring_first_place = clanring_sentinel;
	clanring_second_place = clanring_sentinel;
	pteam = clanring_sentinel.next_team;
	while (pteam)
	{
		if (pteam.frags > clanring_first_place.frags)
		{
			clanring_second_place = clanring_first_place;
			clanring_first_place = pteam;
		}
		else if (pteam.frags > clanring_second_place.frags)
			clanring_second_place = pteam;
		pteam = pteam.next_team;
	}
	if (clanring_first_place.frags > clanring_second_place.frags)
	{
		clanring_score_number = clanring_first_place.frags - clanring_second_place.frags;
		clanring_winning_teamname = strings_get_teamname_up_by(clanring_first_place.height);
	}
	else
	{
		clanring_score_number = clanring_first_place.frags;
		clanring_winning_teamname = CLANRING_STRING_TIED;
	}
};

//
//  F R A G
//
//  Update the team frag count and the winning teamname if necessary.
//  In individual mode pteam points to a player.
//
void (entity pteam, float fragval) score_frag =
{
	if (pteam == world) return; //R00k

	// update the team score
	pteam.frags = pteam.frags + fragval;
	pqc_team_frags(pteam.height, pteam.frags);

	if (fragval > 0)
	{
		if (pteam == clanring_first_place)
		{
			if (clanring_winning_teamname == CLANRING_STRING_TIED)
			{
				clanring_score_number = fragval;//Fixed observer scorebar
				clanring_winning_teamname = strings_get_teamname_up_by(pteam.height);
			}
			else
				clanring_score_number = clanring_score_number + fragval;//fixed
		}
		else
		{
			if (pteam.frags > clanring_second_place.frags)
				clanring_second_place = pteam;

			if (pteam == clanring_second_place)
			{
				if (pteam.frags < clanring_first_place.frags)
					clanring_score_number = clanring_score_number - fragval;
				else if (pteam.frags == clanring_first_place.frags)
				{
					clanring_winning_teamname = CLANRING_STRING_TIED;
					clanring_score_number = pteam.frags;
				}
				else
				{
					clanring_second_place = clanring_first_place;
					clanring_first_place = pteam;
					clanring_score_number = fragval;
					clanring_winning_teamname = strings_get_teamname_up_by(pteam.height);
				}
			}
		}
	}
	else
	{
		if (pteam == clanring_first_place)
		{
			if (pteam.frags > clanring_second_place.frags)
				clanring_score_number = clanring_score_number - fragval;//R00k
			else if (pteam.frags == clanring_second_place.frags) // created a tie
			{
				clanring_winning_teamname = CLANRING_STRING_TIED;
				clanring_score_number = pteam.frags;
			}
			else  // oh-oh
				score_get_top2 ();
		}
		else if (pteam == clanring_second_place) // uh-oh
			score_get_top2();
	}

	if (clanring_match_timer.lip < 0) // Sudden death!
	{
		clanring_sentinel.think = score_check_sudden_death;
		clanring_sentinel.nextthink = time + 1;
	}

	// Refresh worldspawn teamscoreN:<color> infokeys on every score change so
	// external readers (sidebars, scrapers) don't lag the live score by up to
	// the 5-minute match_bprint_score tick.  Gated on MATCH_STARTED so that
	// pre-match warmup kills don't broadcast a stale/uninitialized score.
	if (clanring_state & CLANRING_MATCH_STARTED)
		match_update_score_info();
};
/*
//
//  W R I T E  N A M E
//
//  Update the given client's name to msg_entity
//
void (float client, string name) score_write_name =
{
	WriteByte(MSG_ONE, SVC_UPDATENAME);
	WriteByte(MSG_ONE, client);
	WriteString(MSG_ONE, name);
};

//
//  W R I T E  F R A G S
//
//  Update the given client's frags to msg_entity
//
void (float client, float fragval) score_write_frags =
{
	WriteByte(MSG_ONE, SVC_UPDATEFRAGS);
	WriteByte(MSG_ONE, client);
	WriteShort(MSG_ONE, fragval);
};

//
//  W R I T E  C O L O U R
//
//  Update the given client's colour to msg_entity
//
void (float client, float colour) score_write_colour =
{
	WriteByte(MSG_ONE, SVC_UPDATECOLORS);
	WriteByte(MSG_ONE, client);
	WriteByte(MSG_ONE, colour);
};

//
//  W R I T E  T I M E
//
//  Update 'time remaining" to msg_entity in the given slot
//
void (float client) score_write_time = 
{
	WriteByte(MSG_ONE, SVC_UPDATENAME);
	WriteByte(MSG_ONE, client);
	if (clanring_state & CLANRING_MATCH_OVER)
		WriteString(MSG_ONE, "Match Over");
	else if (clanring_match_timer.lip < 0)
		WriteString(MSG_ONE, "Sudden death");
	else if (clanring_state & CLANRING_MATCH_STARTED)
	{
		local float minutes;
		local float seconds;
		local float temp;

		minutes = clanring_match_timer.lip;
		seconds = clanring_match_timer.count;
		if (minutes > 9)
		{
			temp = floor(minutes / 10);
			minutes = minutes - temp * 10;
			WriteByte(MSG_ONE, 48 + temp);
		}
		WriteByte(MSG_ONE, 48 + minutes);
		WriteByte(MSG_ONE, 58);
		temp = floor(seconds / 10);
		seconds = seconds - temp * 10;
		WriteByte(MSG_ONE, 48 + temp);
		WriteByte(MSG_ONE, 48 + seconds);
		WriteString(MSG_ONE, " remaining");
	}
	else
	{
		local string sz;

		sz = ftos(clanring_match_timer.count);
		WriteByte(MSG_ONE, 84);
		WriteByte(MSG_ONE, 32);
		WriteByte(MSG_ONE, 77);
		WriteByte(MSG_ONE, 105);
		WriteByte(MSG_ONE, 110);
		WriteByte(MSG_ONE, 117);
		WriteByte(MSG_ONE, 115);
		WriteByte(MSG_ONE, 32);
		WriteString(MSG_ONE, sz);
	}
};

//
//  F I X  C O N N E C T
//
//  Called when a new client connects since that will mess up the scoreboard.
//
void () score_fix_connect = 
{
	// find all players looking at scores, and fix the scoreboard
	msg_entity = find(world, classname, "player");
	while(msg_entity)
	{
		if (msg_entity.style & CLANRING_SCOREBOARD)
		{
			if (msg_entity.style & CLANRING_CONNECTED)
			{
				if (self.colormap == msg_entity.timeslot)// .colormap - 1 ??
					score_write_time(msg_entity.timeslot);
				else
					score_write_name(self.colormap - 1, "");//FIXED? (issue #43)
			}
		}
		msg_entity = find(msg_entity, classname, "player");
	}	
	remove(self);
};

//
//  C L I E N T  C O N N E C T
//
//  If someone's looking at teamscores we might need to patch up their scoreboard
//
void () score_client_connect = 
{
	if (!clanring_score_count)
		return;

	local entity e;

	e = utils_make_scheduled_event(score_fix_connect, 0.1);
	e.colormap = self.colormap - 1;
};

//
//  F I X  D I S C O N N E C T
//
//  If a player disconnects, they could mess up the scoreboard if we were
//  using their slot.
// 
void () score_fix_disconnect = 
{
	// find all players looking at scores, and fix the scoreboard
	msg_entity = find(world, classname, "player");
	while(msg_entity)
	{
		if (msg_entity.style & CLANRING_SCOREBOARD)
		{
			if (msg_entity.style & CLANRING_CONNECTED)
			{
				if (self.next_team != world && self.next_team.next_player != world)
				{
					score_write_name(self.next_team.next_player.colormap - 1, self.next_team.mdl);
					score_write_frags(self.next_team.next_player.colormap - 1, self.next_team.frags);
				}
				else if (self.colormap == msg_entity.timeslot)
					score_write_time(msg_entity.timeslot);
			}
		}
		msg_entity = find(msg_entity, classname, "player");
	}	
	remove(self);
};

//
//  C L I E N T  D I S C O N N E C T
//
//  If someone's looking at teamscores we might need to patch up their scoreboard.
//  Also check to see if *they* were looking at the scoreboard.
//
void () score_client_disconnect = 
{
	if (!clanring_score_count)
		return;

	local entity e;

	e = utils_make_scheduled_event(score_fix_disconnect, 0.1);
	e.colormap = self.colormap - 1;

	if (teamplay > 0 && self.next_team.next_player == self)
		e.next_team = self.next_team;
	else
		e.next_team = world;

	if (self.style & CLANRING_SCOREBOARD)
		clanring_score_count = clanring_score_count - 1;
};

//
//  S H O W  T E A M S C O R E S
//
void () score_show_teamscores = 
{
	local entity e;

	if (self.style & CLANRING_SCOREBOARD)
		return;

    if (!(clanring_state & (CLANRING_TIMER_STARTED | CLANRING_MATCH_OVER)))
		return;

	msg_entity = self;
	self.style = self.style | CLANRING_SCOREBOARD;
	clanring_score_count = clanring_score_count + 1;

	// first erase the scoreboard and find a slot for the time remaining
	self.timeslot = -1;
	e = find(world, classname, "player");
	while(e)
	{
		if (e.style & CLANRING_CONNECTED)
		{
			if (teamplay || (e.style & CLANRING_OBSERVER) || !(clanring_state & (CLANRING_MATCH_STARTED | CLANRING_MATCH_OVER)))
				score_write_name(e.colormap - 1, "");
			if ((self.timeslot == -1) && (e.style & CLANRING_OBSERVER))
				self.timeslot = e.colormap - 1;
		}
		else if (self.timeslot == -1)
		{
			self.timeslot = e.colormap - 1;
			score_write_colour(self.timeslot, 0);
			score_write_frags(self.timeslot, -99);
		}
		e = find(e, classname, "player");
	}

	// make sure we have a slot for time
	if (self.timeslot == -1)
	{
		if (match_count_players() < 8)
		{
			// 7 is unused - grab it
			self.timeslot = 7;
			score_write_colour(7, 0);
			score_write_frags(7, -99);
		}
		else if (teamplay > 0)
		{
			// oh well - take what we can get
			e = find(world, classname, "player");
			while (e)
			{
				local float c;

				c = e.colormap - 1;
				if (e.next_team.next_player != e)
				{
					self.timeslot = c;
					score_write_frags(c, -99);
					e = world;
				}
				else
					e = find(e, classname, "player");
			}
		}
	}

	// If we still don't have a timeslot then abort
	if (self.timeslot == -1)
	{
		score_restore_scoreboard();
		return;
	}
	
	// send the teamscores
	if (teamplay && (clanring_state & (CLANRING_MATCH_STARTED | CLANRING_MATCH_OVER)))
	{
		e = clanring_sentinel.next_team;
		while (e)
		{
			if (e.count)
			{
				score_write_name(e.next_player.colormap - 1, e.mdl);
				score_write_frags(e.next_player.colormap - 1, e.frags);
			}
			e = e.next_team;
		}
	}

	// now send the time
	score_write_time(self.timeslot);
};

//
//  R E S T O R E  S C O R E B O A R D
//
//  Restore a client's scoreboard after they finish looking at team scores
//
void () score_restore_scoreboard = 
{
	local entity e;

	if (!(self.style & CLANRING_SCOREBOARD))
		return;

	msg_entity = self;
	self.style = self.style - CLANRING_SCOREBOARD;
	clanring_score_count = clanring_score_count - 1;

	// Clear time remaining seperately since it might not be a client
	score_write_name(self.timeslot, "");

	e = find(world, classname, "player");
	while(e)
	{
		if (e.style & CLANRING_CONNECTED)
		{
			score_write_name(e.colormap - 1, e.netname);
			score_write_frags(e.colormap - 1, e.frags);
		}
		e = find(e, classname, "player");
	}
};

//
//  U P D A T E  F R A G S
//
//  Update frags for everyone who's looking at teamscores
//
void () score_update_frags = 
{
	msg_entity = find(world, classname, "player");
	while(msg_entity)
	{
		if (msg_entity.style & CLANRING_SCOREBOARD)
		{
			if (msg_entity.style & CLANRING_CONNECTED)
				score_write_frags(self.next_team.next_player.colormap - 1, self.next_team.frags);
		}
		msg_entity = find(msg_entity, classname, "player");
	}	
	remove(self);
};

//
//  U P D A T E  T I M E
//
//  Update the time for everyone who's looking at teamscores
//
void () score_update_time = 
{
	if (!clanring_score_count)
		return;

	msg_entity = find(world, classname, "player");
	while(msg_entity)
	{
		if (msg_entity.style & CLANRING_SCOREBOARD)
		{
			if (msg_entity.style & CLANRING_CONNECTED)
				score_write_time(msg_entity.timeslot);
		}
		msg_entity = find(msg_entity, classname, "player");
	}	
};

//
//  R E S E N D  S C O R E B O A R D
//
//  Re-send the scoreboard at the start of a match.
//
void () score_resend_scoreboard = 
{
	local entity oself;

	oself = self;
	self = find(world, classname, "player");
	while (self)
	{
		if (self.style & CLANRING_SCOREBOARD)
		{
			if (self.style & CLANRING_CONNECTED)
			{
				score_restore_scoreboard();
				score_show_teamscores();
			}
		}
		self = find(self, classname, "player");
	}	
	self = oself;
};
*/

//eof
