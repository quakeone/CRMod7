/*teamplay.qc

   From
        The Complete Enhanced Teamplay

   John Spickes -- jspickes@eng.umd.edu
*/
void() observer_end;
void() respawn;
void() SetNewParms2;

/*
=======
Teamplay functions
=======
*/

void() teamplay_show_score =
{
	local entity e;
	local float t1frags = 0, t2frags = 0;
	local string scorestr;

	if  (!(teamplay)) return;

	e = find(world, classname, "player");

	while (e)
	{
		if ( (e != world) && (!(e.style & CLANRING_OBSERVER)) )
		{
			if (e.team == BLUE) t1frags = t1frags + e.frags;
			if (e.team == RED)  t2frags = t2frags + e.frags;
		}
		e = find(e, classname, "player");
	}

	if (t1frags > t2frags)
	{

		scorestr = ftos(t1frags);
		if (self.team==BLUE)
		{
			sprint(self,"\x90Blue Score\x91: ");
		}
		else
		{
			sprint(self," Blue Score : ");
		}
		sprint2(self,(scorestr),"\n");

		scorestr = ftos(t2frags);
		if (self.team==RED)
		{
			sprint(self,"\x90Red  Score\x91: ");
		}
		else
		{
			sprint(self," Red  Score : ");
		}
		sprint2(self,(scorestr),"\n");
		return;
	}


	if (t1frags < t2frags)
	{

		scorestr = ftos(t2frags);

		if (self.team==RED)  sprint(self,"\x90Red  Score\x91: ");
		else	         sprint(self," Red  Score : ");
		sprint2(self,(scorestr),"\n");

		scorestr = ftos(t1frags);
		if (self.team==BLUE) sprint(self,"\x90Blue Score\x91: ");
		else		 sprint(self," Blue Score : ");

		sprint2(self,(scorestr),"\n");
		return;
	}

	if (t1frags == t2frags)
	{
		scorestr = ftos(t1frags);
		sprint3(self," \bteams tied : ",(scorestr),"\n");
	}
};

void() teamplay_show_final_score =
{
	local entity e;
	local float t1frags = 0,t2frags = 0;
	local string scorestr;

	e = find(world, classname, "player");

	while (e)
	{
		if ( (e != world) && (!(e.style & CLANRING_OBSERVER)) )
		{
			if (e.team == BLUE) t1frags = t1frags + e.frags;
			if (e.team == RED)  t2frags = t2frags + e.frags;
		}
		e = find(e, classname, "player");
	}

	if (t1frags > t2frags)
	{
		sprint(self,"\n");
		scorestr = ftos(t1frags);
		sprint3(self,"Blue team \bwon\b with ",(scorestr)," frags.\n");
		scorestr = ftos(t2frags);
		sprint3(self,"Red team lost with ",(scorestr)," frags.\n");
		return;
	}

	if (t1frags < t2frags)
	{
		sprint(self,"\n");
		scorestr = ftos(t2frags);
		sprint3(self,"Red team \bwon\b with ",(scorestr)," frags.\n");
		scorestr = ftos(t1frags);
		sprint3(self,"Blue team lost with ",(scorestr), " frags.\n");
		return;
	}

	if (t1frags == t2frags)
	{
		scorestr = ftos(t1frags);
		sprint(self,"\n");
		sprint3(self,"\bTIE GAME\b of ",(scorestr)," frags.\n");
	}
};

void() teamplay_verify_team =
{
	if (self.style & CLANRING_CONNECTED)
	{
		if ((self.style & CLANRING_RED_TEAM))
		{
			setcolour(self,4,4);
			stuffcmd(self,";color 4\n");			
			self.team = RED;
			self.height = self.team - 1;
		}
		else
		{
			if ((self.style & CLANRING_BLUE_TEAM))
			{
				
				setcolour(self,13,13);
				stuffcmd(self,";color 13\n");			
				self.team = BLUE;
				self.height = self.team - 1;
			}
		}
	}
};

void() teamplay_ready_player =
{
	local float 	TEAM1;
	local float 	TEAM2;
	local entity 	p;
	local float 	t1frags,t2frags;
	local float 	goblue;
	
	goblue= FALSE;

	TEAM1 = 0;
	TEAM2 = 0;
	t1frags = 0;
	t2frags = 0;

	p = find(world, classname, "player");

	while (p)
	{
		if (p != self)
		{
			if (p.style & CLANRING_RED_TEAM) 
			{
				TEAM1 = TEAM1 + 1;
				t1frags = t1frags + p.frags;
			}
			else
			{
				if (p.style & CLANRING_BLUE_TEAM) 
				{
					TEAM2 = TEAM2 + 1;
					t2frags = t2frags + p.frags;
				}
			}
		}
		p = find(p, classname, "player");
	}
/*
	Put Players on team with least amount of players.
	If teams are equal amount of members then place new player on
	team with lowest score. If same amount of players, and score
	then just ignore all and put them on the team they chose in 
	the first place.
*/
	if (((TEAM1 > TEAM2) || ((TEAM1 == TEAM2) && (t1frags > t2frags))))		
	{		
		goblue = TRUE;
	}
	else
	{
		if (((TEAM2 > TEAM1) || ((TEAM2 == TEAM1) && (t2frags > t1frags))))	
		{
			goblue = FALSE;
		}
		else
		{
			if (self.team == RED)
			{
				goblue = FALSE;
			}
			else
			{
				if (self.team == BLUE)
				{
					goblue = TRUE;
				}
				else
				{
					goblue = ceil(random());//if error, randomly put on team.
				}
			}			
		}			
	}
	
	if (goblue == TRUE)
	{
		if (self.team == RED)
		{
			bprint(self.netname, " was \bforced\b to the BLUE team.\n");
		}
		else
		{
			bprint(self.netname, " has joined the BLUE team.\n");
		}
		
		self.team	= BLUE;
		self.style	= self.style - (self.style & (CLANRING_RED_TEAM | CLANRING_BLUE_TEAM));
		self.style	= (self.style | CLANRING_BLUE_TEAM);
		self.height = (self.team - 1);
		stuffcmd(self,";color 13\n");		
		
		if (self.style & CLANRING_OBSERVER)
		{
			observer_end();
		}
		else
		{
			self.frags 	= 0;
			self.killed 	= 0;			
			self.movetarget = world;
			stats_reset_player ();
			SetNewParms2 ();	
			PutClientInServer ();	
		}
		//setcolor(self,13,13);		
	}
	else
	{
		if (self.team == BLUE)
		{
			bprint(self.netname, " was \bforced\b to the RED team.\n");
		}
		else
		{
			bprint(self.netname, " has joined the RED team.\n");
		}
		
		self.team  	= RED;
		self.style 	= self.style - (self.style & (CLANRING_RED_TEAM | CLANRING_BLUE_TEAM));
		self.style 	= (self.style | CLANRING_RED_TEAM);
		self.height = (self.team - 1);
		stuffcmd(self,";color 4;\n");
		
		if (self.style & CLANRING_OBSERVER)
		{
			observer_end();
		}
		else
		{
			self.frags 	= 0;
			self.killed 	= 0;			
			self.movetarget = world;
			stats_reset_player ();			
			SetNewParms2 ();	
			PutClientInServer ();	
		}
		//setcolor(self,4,4);		
	}
};

void() teamplay_force_player_ready =
{
	local entity oself;

	oself = self;
	self = self.owner;
	teamplay_ready_player();
	self = oself;
	remove(self);
};

void() teamplay_final_stats =
{
	if (self.style & CLANRING_CONNECTED)
	{
		stats_autodump();
		if (teamplay)						//Pub CTF/TDM use RED vs BLUE
			teamplay_show_final_score();
	}
};

//eof
