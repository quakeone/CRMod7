//
// vote.qc
//
// This file contains code to implement voting.  All votes consist of an
// initial request followed by a 21 second vote.  clanring_request contains
// the request strings.
//
// For all requests .use points to a function which is called when
// the vote passes, and .th_die points to a function which is called when
// the vote dies.  The die function is optional; the pass function must
// be passed to vote_init.  Sample usage:
//
//    vote_init("change level to ", newmap, admin_change_level);
//    vote_yes();
//
// All code by J.P. Grossman unless otherwise commented.
//
/*
// Function declarations
void() vote_repeat;
void() vote_accept;
void() vote_reject;
void() vote_clear;
float () vote_majority;
//
//  I N I T
//
//  Prints a message composed of strings s1 and s2 and initializes
//  a vote (if one is not already in progress).  'accept' is a
//  function that is called when the vote passes.
//
//  Returns TRUE if successful, FALSE otherwise.
//
float (string s1, string s2, void() accept) vote_init =
{	
	clear_afk_status(self);	//R00k: (1/3/2022 12:54pm)

	// Check to see if there's already a vote in progress
	if (clanring_request)
	{
		sprint(self, "There is already a vote in progress\n");
		return FALSE;
	}
	
	if ((self.style & CLANRING_OBSERVER) && (clanring_state & CLANRING_MATCH_STARTED))//R00k
	{
		sprint(self, "Observers cannot initiate votes during match.\n");
		return FALSE;
	}
	
	clanring_request = spawn();
	clanring_request.classname = "clanring_request";
	clanring_request.th_die = SUB_Null;
	clanring_request.think = vote_repeat;
	clanring_request.use = accept;
	clanring_request.wad = s1;
	clanring_request.map = s2;
	clanring_request.count = 0;
	clanring_request.owner = self;//R00k added
	utils_do_players(vote_clear);

    // If there's only one voter then it will pass as soon as that
    // person votes yes; no need to print the request.
	if (!vote_majority ())
		vote_repeat ();
	return TRUE;
};

//
//  C L E A R
//

void () vote_clear =
{
	self.style = self.style - (self.style & CLANRING_YES);
};

//
//  Y E S
//
//  Called when a player votes yes.
//
void () vote_yes =
{
	clear_afk_status(self);	//R00k: (1/3/2022 12:55pm)

    if (self.style & CLANRING_ADMINISTRATOR)
    {
        // accept immediately
        vote_accept();
        return;
    }

    if (self.style & CLANRING_YES)
    {
        sprint(self, "\nWise man say: \"Vote early, vote often\"\n");
        return;
    }

	if (self != clanring_request.owner)
		bprint(self.netname, " voted.\n");

    self.style = self.style | CLANRING_YES;
    if (vote_majority())
        vote_accept();
};

//
//  N O
//
//  Called when a player votes no.
//
void() vote_no =
{	
	clear_afk_status(self);	//R00k: (1/3/2022 12:55pm)

	if ((self.style & CLANRING_ADMINISTRATOR) || (clanring_request.owner == self))//Admin or person who started the vote
	{
		// reject immediately
		vote_reject ();
		return;
	}
	
	bprint(self.netname, " voted.\n");
	vote_clear ();
};

//
//  M A J O R I T Y
//
//  Return TRUE if the majority of players have responded 'yes',
//  FALSE otherwise.  Observers only get x% of a vote based on number of players.
//
float () vote_majority =
{
	local entity player;
	local float vote_count, players, observers, obs_vote;

    // CRMOD observers weight now 'equals' that of the players
    players = observers = vote_count = 0;                                                
	player = find(world, classname, "player");

	while (player)
	{		
		if ((player.style & CLANRING_CONNECTED) && (!(player.style & CLANRING_AFK_CLIENT)))//R00k
		{
			if (player.style & CLANRING_OBSERVER)
				observers += 1;
			else
				players += 1;
		}
		player = find(player, classname, "player");
	}

	if ((players) && (observers))
	{	
		obs_vote = 100 * players / observers;
		if (obs_vote > 100)
			obs_vote = 100;
	}
	else
		obs_vote = 100;
	
	// CRMOD END
	player = find(world, classname, "player");

	while (player)
	{
		if ((player.style & CLANRING_CONNECTED) && (!(player.style & CLANRING_AFK_CLIENT)))//R00k don't count AFK
		{
            local float vote;
			if (player.style & CLANRING_OBSERVER)
                vote = obs_vote;				// CRMOD
            else
                vote = 100;

            if (player.style & CLANRING_YES || player == self)
                vote_count = vote_count + vote;
            else
                vote_count = vote_count - vote;
        }
        player = find(player, classname, "player");
    }
    if (vote_count > 0)
        return TRUE;
    return FALSE;
};

//
//  R E P E A T
//
//  Print the request; schedule the next automatic action.
//  elohim_request.count counts the number of times the request
//  has been displayed.
//
void() vote_repeat =
{
	bprint5((clanring_request.owner.netname)," \xF2\xE5\xF1\xF5\xE5\xF3\xF4\xF3\xA0\xF4\xEF \b", clanring_request.wad, clanring_request.map, "\n");
	bprint("Type \byes\b or \bno\b in console to vote\n");
	sound (world, CHAN_AUTO, "misc/talk.wav", 1, ATTN_NONE);
	clanring_request.nextthink = time + 7;
	clanring_request.count = clanring_request.count + 1;
	if (clanring_request.count == 3)
		clanring_request.think = vote_reject;
};

//
//  A C C E P T
//

void() vote_accept =
{
	clanring_request.use ();
	remove(clanring_request);
	clanring_request = world;
};

//
//  R E J E C T
//
//  Called when the vote is cancelled by an administrator or
//  21 seconds elapse.
//

void() vote_reject =
{
	bprint("\xD6\xEF\xF4\xE5\xA0\xE3\xE1\xEE\xE3\xE5\xEC\xEC\xE5\xE4\n");
	sound (world, CHAN_AUTO, "misc/talk.wav", 1, ATTN_NONE);
	clanring_request.th_die ();
	remove(clanring_request);
	clanring_request = world;
};
*/
void () vote_yes = {Request_Poll_Vote(self, 1);}
void () vote_no = {Request_Poll_Vote(self, 2);}

//
//  I M P U L S E
//

void() vote_impulse =
{
	if (!clanring_request)
	{
		sprint(self, "Nothing to vote on\n");
		return;
	}
	if (self.impulse == 115)
	    vote_yes();
	else if (self.impulse == 116)
	    vote_no();
};
