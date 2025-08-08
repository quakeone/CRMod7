//
// Motd.qc
//
// Message of the day code.  I created a whole new file so that it would
// be easier to beef up the motd.
//
// All code by J.P. Grossman unless otherwise commented.
//
float (entity team1) number_teammates;
entity (float whichteam) find_team_entity;

string motd_top1;
string motd_top2;
string motd_top3;
string motd_top4;
string motd_top5;
string motd_top6;
string motd_top7;

void ()motd_arena_start;

//
//  I N I T  W O R L D
//
//  Initialize the motd strings
//

void() motd_init_world =
{
	motd_top1   = "\n\n\n\n\x80\x81\x81\x81\x81\x81 \bCRMod\b \x19 \x81\x81\x81\x81\x81\x82\n\n\nClanRing Multiplayer Server\n\n\noriginal works by \nJ.P. Grossman & Dave 'Zoid' Kirsch";
	motd_top2   = "\n\n\n\x80\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x82\n\n\n\n\n\n\n\n";
};

void() motd_think =
{	
	float bail = FALSE;

	if (self.count > 10)
		bail = TRUE;

	if (self.count == 0)
		self.owner.button0 = FALSE;

	if (clanring_state & CLANRING_MATCH_PAUSED)
		bail = TRUE;

	if (self.owner.button0 || self.owner.button2 || vlen(self.owner.movement)) //cancel if they start moving too.
		bail = TRUE;
	
	if ((clanring_state & CLANRING_TIMER_STARTED) && !(clanring_state & CLANRING_MATCH_STARTED))
		bail = TRUE;

	if (intermission_running)
		bail = TRUE;

	if (mode_is_arena())
	{
		// Set up arena menu strings first
		local entity oldself = self;
		self = self.owner;  // Switch context to player for motd_arena_start
		motd_arena_start();
		self = oldself;     // Switch back to motd entity
		
		// Set the flag and bail - don't clear the flag for arena modes
		self.owner.style = self.owner.style | CLANRING_MOTD;
		remove(self);
		return;
	}

	if (bail)
	{
		if (clanring_playmode & CLANRING_MATCH_MODE)
		{
			centerprint (self.owner, "\btype \bred\b or \bblue\b in console to join");
		}
		else if (!(mode_is_arena()))
		{
			centerprint (self.owner, "\btype \bready\b in console to join");
		}

		self.owner.style = self.owner.style - (self.owner.style & CLANRING_MOTD);
		remove(self);
		return;
	}

	self.owner.style = self.owner.style | CLANRING_MOTD;
	centerprint(self.owner, motd_top1,motd_top2);
	self.nextthink = time + 1;
	self.count = self.count + 1;
};

//
//  C R E A T E
//
//  Create an entity to display the MOTD for 5 seconds (plus a bit).
//
void() motd_create =
{
	local entity intro;

	if (clanring_state & CLANRING_MATCH_PAUSED)
	return;

	intro = utils_make_scheduled_event(motd_think, 0.5);
	intro.count = 0;
	intro.cnt = 0;
	intro.lip = 0;
};

void () motd_end =
{
	self.owner.style = self.owner.style - (self.owner.style & CLANRING_MOTD);
	remove (self);
};

void ()motd_print =
{	
	if (self.style & CLANRING_AFK_CLIENT)
		return;//R00k v1.95 save some bandwidth...

	if ((!(self.style & CLANRING_CONNECTED)) || (clanring_state & CLANRING_MATCH_PAUSED))//this deters overflow buffer errors
		return;
		
	if (intermission_running)
		return;

	if ((!(self.oflags & OBSERVER_FLY))&&(!(self.oflags & OBSERVER_WALK)))
	{		
		if ((mode_is_arena()) == FALSE) //in arena modes keep the menu
			self.style = self.style - (self.style & CLANRING_MOTD);
		return;
	}

	if (self.ca_player_flag == PF_PLAYING) //R00k: 6/12/2017 9:50AM (airshot practice)
		return;

	if (mode_is_arena())
	{
		if (boss.state != CA_MATCH_WAITING) //R00k: drop the menu during the match
			return;

		string ts = "choose a team\n\n";
		
		if (self.next_team.team2)
		{
			switch (self.next_team.team2)
			{
				case TEAM_RED:
					ts = "you are on the \bred\b team\n\n";
					break;
				case COLOR_BLUE:
					ts = "you are on the \bblue\b team\n\n";
					break;
				case TEAM_GREEN:
					ts = "you are on the \bgreen\b team\n\n";
					break;
				case TEAM_YELLOW:
					ts = "you are on the \byellow\b team\n\n";
					break;
				case TEAM_SPECTATOR:
					ts = "choose a team\n\n";
					break;
			}
		}
	}
	centerprint7 (self, motd_top1, motd_top2, motd_top3, motd_top4, motd_top5, motd_top6, motd_top7);
};

void () motd_playercount =
{
    local float n;
    local string s;
    local string temp;
    local entity e;

    temp = "\x13 blue   \[B\]\n\x14 red    \[R\]\n\x15 yellow \[Y\]\n\x16 green  \[G\]\n\npress \x17 to uncommit from team\n";

    e = find_team_entity(COLOR_BLUE);
    if (e != world)
    {
        n = number_teammates(e);
        s = ftos(n);
        temp = strreplace("B", s, temp);
    }
    else
    {
        temp = strreplace("B", "0", temp);
    }

    e = find_team_entity(COLOR_RED);
    if (e != world)
    {
        n = number_teammates(e);
        s = ftos(n);
        temp = strreplace("R", s, temp);
    }
    else
    {
        temp = strreplace("R", "0", temp);
    }

    e = find_team_entity(COLOR_YELLOW);
    if (e != world)
    {
        n = number_teammates(e);
        s = ftos(n);
        temp = strreplace("Y", s, temp);
    }
    else
    {
        temp = strreplace("Y", "0", temp);
    }

    e = find_team_entity(COLOR_GREEN);
    if (e != world)
    {
        n = number_teammates(e);
        s = ftos(n);
        temp = strreplace("G", s, temp);
    }
    else
    {
        temp = strreplace("G", "0", temp);
    }
 
    strunzone(motd_top4);
    motd_top4 = strzone(temp);
};

void ()motd_arena_start =
{
	if (self.style & CLANRING_AFK_CLIENT)
		return;//R00k v1.95 save some bandwidth...
		
	if (self.style & CLANRING_MOTD || (!(self.style & CLANRING_CONNECTED)) || clanring_state & CLANRING_MATCH_PAUSED)
		return;	
	
	motd_top1 = "\x80\x81\x81\x81\x81\x81 ClanRing Mod \x81\x81\x81\x81\x81\x82\n";
	motd_top7 = "\n\n\n\n";

	if (clanring_playmode & CLANRING_CA_MODE)
	{
		if (clanring_playmode & CLANRING_WIPEOUT_MODE)
			motd_top2 = "\n\x85Clan Arena (Wipeout)\x85\n\n";
		else
			motd_top2 = "\n\x85Clan Arena\x85\n\n";
		motd_top3 = "\nchoose a team\n\n";
		motd_top4 = "\x13 blue   \n\x14 red    \n\x15 yellow \n\x16 green  \n\npress \x17 to uncommit from team\n";
		motd_playercount();
	}
	else if (clanring_playmode & CLANRING_RA_MODE)
	{
		motd_top2 = "\n\x85Rocket Arena\x85\n\n";
		motd_top3 = "\n1 to join\n\n";
		motd_top4 = "\n2 to leave\n\n";
	}
	else if (clanring_playmode & CLANRING_DMM4_MODE)
	{
		motd_top2 = "\n\x851v1 Duel\x85\n\n";
		motd_top3 = "\n1 to join\n\n";
		motd_top4 = "\n2 to leave\n\n";
	}
	else if (clanring_playmode & CLANRING_AIRSHOT_MODE)
	{
		motd_top2 = "\n\x85Airshot Mode\x85\n\n";
		motd_top3 = "You can only be damaged while in the air.\nThe higher off the ground, the more\ndamage you will take.\n";
		motd_top4 = "\n1 to join\n\n\n2 to leave\n\n";

		if (playerrecord[0].statvalue > 0)
		motd_top5 =	sprintf("\nAir Gib Streak: %s %s", ftos(rint(playerrecord[0].statvalue)), playerrecord[0].player);
		
		if (playerrecord2[0].statvalue > 0)
		motd_top6 = sprintf("\nHighest Gib: %s %s", ftos(rint(playerrecord2[0].statvalue)), playerrecord2[0].player);
	}
	else
		return;

	self.style = self.style | CLANRING_MOTD;
};