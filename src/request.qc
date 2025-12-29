/*
	request.qc

	polling functions - by R00k

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

	See file, 'gnu_gpl.txt', for details.
*/

float VOTE_IN_PROGRESS_SPAM_COOLDOWN = 3; // seconds

void() Request_Poll_Cleanup =
{
	local entity trash_disco;	

	if (clanring_request)
	{
		// Reset these for completeness.
		clanring_request.owner = world;
        strunzone(clanring_request.noise1);
        clanring_request.noise1 = "";
        strunzone(clanring_request.noise2);
        clanring_request.noise2 = "";
		clanring_request.classname = "";
		clanring_request.nextthink = -99;
		clanring_request.think = SUB_Null;
		clanring_request.touch = SUB_Null;
		remove(clanring_request);
		clanring_request = world;
	}

	//Clear out the votes for this request.
	trash_disco = find(world, classname, "player");
	while (trash_disco)
	{
		trash_disco.vote = 0;
		trash_disco = find(trash_disco, classname, "player");
	}
};

float(float ballot) Request_Poll_Votes_Needed =
{
	local entity bingo;
	local float	vcount = 0, pcount = 0, votes_needed = 99;

	bingo = find(world, classname, "player");

	// What we are doing here is tallying up the votes pragmatically.
	// The vote will pass if there is a majority for yes, or no, immediately.
	// This way, we don't have to sit around for 45 seconds waiting for
	// the request to timeout if there is already a majority vote.
	// Although, it doesn't give players much time to change their vote...

	if (ballot == 1)		// yes vote
	{
		while (bingo)
		{
			if (bingo.style & CLANRING_CONNECTED)
			{
				if (bingo.style & CLANRING_AFK_CLIENT)
				{
					if (bingo.vote)	//count players that are afk and already voted 
					{
						pcount += 1;

						if ((bingo.vote == ballot) || (bingo == clanring_request.owner))
							vcount += 1;
					}
				}
				else
				{
					pcount += 1;

					if ((bingo.vote == ballot) || (bingo == clanring_request.owner))
						vcount += 1;
				}
			}
			bingo = find(bingo, classname, "player");
		}
		votes_needed = ceil((pcount * 0.51) - vcount);
	}
	else
	{
		if (ballot == 2)	// no vote
		{
			while (bingo)
			{
				if (bingo.style & CLANRING_CONNECTED)
				{
					if (bingo.style & CLANRING_AFK_CLIENT)
					{
						if (bingo.vote)	//count players that are afk and already voted 
						{
							pcount += 1;
	
							if (bingo.vote == ballot)
								vcount += 1;
						}
					}
					else
					{
						pcount += 1;
	
						if (bingo.vote == ballot)
							vcount += 1;
					}
				}
				bingo = find(bingo, classname, "player");
			}
	 		votes_needed = ceil((pcount * 0.51) - vcount);
	 	}
	 	else
	 		bprint("Request_Poll_Votes_Needed: Invalid Ballot\n");
	 }
	if (votes_needed < 1)
		return 0;
	else
		return votes_needed;
};

void(entity player, float cast) Request_Poll_Vote =
{
	local float votes_needed = 99;

	clear_afk_status(player);	//R00k

    // Suppress per-player vote lines if the caller is no longer connected
    local float player_is_connected;
    player_is_connected = (player.style & CLANRING_CONNECTED) ? 1 : 0;

	if (clanring_request == world)
	{
		sprint(player, "There is nothing to vote on.\n");
		return;
	}

	if (player.vote)
	{
		if (player.vote != cast)											// They changed their mind...
		{
			if (player == clanring_request.owner)							// This person, who changed their mind, also started the request, so just cancel it.
			{
				sound(world, CHAN_AUTO, "misc/menu2.wav", 1, ATTN_NONE);
                if (player_is_connected)
                    bprint(player.netname," cancelled their request.\n");
				Request_Poll_Cleanup();
				return;
			}
			else
			{
                if (player_is_connected)
                    bprint(player.netname, " flipped their vote.\n");
			}
		}
		else
		{
//			if (player != clanring_request.owner)
			{
				if (player.style & CLANRING_ADMINISTRATOR)					// So, an admin already voted, and now wishes to affirm their vote
				{
					bprint("\x90\bAdmin Forced\b\x91 ");
					
					if (cast == 1)
					{
						bprint("Vote passed to ", clanring_request.noise1, clanring_request.noise2, ".\n");
						clanring_request.touch();
						sound(world, CHAN_AUTO, "misc/runekey.wav", 1, ATTN_NONE);
					}
					else
					{
						bprint("The request was declined.\n");
						sound(world, CHAN_AUTO, "misc/menu2.wav", 1, ATTN_NONE);
					}
					Request_Poll_Cleanup();
					return;
				}
				else
				{
					sprint(player, "You already voted.\n");
					return;
				}
			}
		}
	}

	player.vote = cast;

	// Precompute remaining YES votes to pass after this ballot was recorded.
	// Used for the "X more votes needed" suffix in both YES and NO displays.
	local float yes_remaining_after = Request_Poll_Votes_Needed(1);

	if (cast == 1)
	{
        votes_needed = Request_Poll_Votes_Needed(cast); // majority YES check (after this ballot)

        // If this recount was triggered by a disconnect (not a live client),
        // resolve without printing a per-player "voted" line.
        if (!player_is_connected)
        {
            if (votes_needed == 0)
            {
                bprint("Vote passed to ", clanring_request.noise1, clanring_request.noise2, ".\n");
                clanring_request.touch();
                sound(world, CHAN_AUTO, "misc/runekey.wav", 1, ATTN_NONE);
                Request_Poll_Cleanup();
                return;
            }
        }

		if (votes_needed == 0)// majority YES
		{
			// The final (passing) YES ballot: single-line message per request.
			// Example: "woods voted yes. Vote passed."
			bprint(player.netname, " voted \byes\b. \n\nVote passed to ", clanring_request.noise1, clanring_request.noise2, ".\n\n");
			clanring_request.touch();
			sound(world, CHAN_AUTO, "misc/runekey.wav", 1, ATTN_NONE);
			Request_Poll_Cleanup();
			return;
		}
		else
		{			
			if (player != clanring_request.owner)
			{
				if (player.style & CLANRING_ADMINISTRATOR)
				{
					sprint(player,"\x90\bWarning\b\x91: You are an admin, type \byes\b again to force this vote.\n");
				}

				// Single-line "voted yes. X more votes needed."
				bprint(player.netname, " voted \byes\b.");
				if (yes_remaining_after > 0)
				{
					if (yes_remaining_after == 1)
						bprint3(" ", strings_ftos_gold(1), " more vote needed.\n");
					else
						bprint3(" ", strings_ftos_gold(yes_remaining_after), " more votes needed.\n");
				}
				else
					bprint("\n");
			}
			return;
		}
	}
	else
	{
		if (cast == 2)
		{
            votes_needed = Request_Poll_Votes_Needed(cast);

            // Silent resolve for disconnect-triggered recount (no per-player line)
            if (!player_is_connected && (votes_needed == 0))
            {
                bprint("\n");
                sound(world, CHAN_AUTO, "misc/menu2.wav", 1, ATTN_NONE);
                bprint("The request was declined.\n");
                Request_Poll_Cleanup();
                return;
            }
			if (votes_needed == 0) // majority NO
			{
				if (player != clanring_request.owner)
					bprint(player.netname, " voted \bno\b.\n");
				bprint("\n");
				sound(world, CHAN_AUTO, "misc/menu2.wav", 1, ATTN_NONE);
				bprint("The request was declined.\n");
				Request_Poll_Cleanup();
			}
			else if (player.style & CLANRING_ADMINISTRATOR)
			{
				sprint(player,"\x90\bWarning\b\x91: You are an admin, type \bno\b again to cancel this vote.\n");
			}

			// If not resolved, show remaining YES needed to pass, inline with the NO vote line
			if (player != clanring_request.owner)
			{
				bprint(player.netname, " voted \bno\b.");
				if (yes_remaining_after > 0)
				{
					if (yes_remaining_after == 1)
						bprint3(" ", strings_ftos_gold(1), " more vote needed.\n");
					else
						bprint3(" ", strings_ftos_gold(yes_remaining_after), " more votes needed.\n");
				}
				else
					bprint("\n");
			}
		}
	}
	bprint("\n");
};

void() Request_Poll_Announce =
{
	//self is the clanring_request
	self.health -= 10;
	
	if (self.health <= 0)
	{
		self.nextthink = -99;
		self.think = SUB_Null;

		bprint("The request has expired.\n");
		sound(world, CHAN_AUTO, "demon/dland2.wav", 1, ATTN_NONE);//R00k: sounds better.
		Request_Poll_Cleanup();
	}
	else
	{
		sound(world, CHAN_AUTO, "misc/menu1.wav", 1, ATTN_NONE);
		bprint("\n\[ vote request \]\n");
		bprint(" ", self.owner.netname, " requests to ", self.noise1, self.noise2, "\n");

		// Compute YES votes needed to pass
		local float yn;
		yn = Request_Poll_Votes_Needed(1);

		// Show "more vote(s) needed" ONLY if someone (not the requester) actually cast a ballot (.vote != 0)
		local float anyvotes;
		anyvotes = 0;
		local entity tmp = find(world, classname, "player");
		while (tmp)
		{
			// Exclude the request owner and require an explicit ballot (1 or 2)
			if ((tmp.style & CLANRING_CONNECTED) && (tmp != self.owner) && (tmp.vote != 0))
			{
				anyvotes = 1;
				break;
			}
			tmp = find(tmp, classname, "player");
		}

		if (yn > 0)
		{
			bprint("\n Type \byes\b or \bno\b in console to cast your vote.");
			if (anyvotes)
			{
				if (yn == 1)
					bprint3(" ", strings_ftos_gold(yn), " more vote needed.\n\n");
				else
					bprint3(" ", strings_ftos_gold(yn), " more votes needed.\n\n");
			}
			else
			{
				if (yn == 1)
					bprint3(" ", strings_ftos_gold(yn), " vote needed.\n\n");
				else
					bprint3(" ", strings_ftos_gold(yn), " votes needed.\n\n");
			}
		}
		else
		{
			// Already enough to pass; keep line simple (pass will occur upon a YES cast)
			bprint("\n Type \byes\b or \bno\b in console to cast your vote.\n\n");
		}

		if (self.health < 40)	// 30, 20, 10
			bprint(sprintf(" request expires in %s seconds.\n", strings_ftos_gold(self.health)));

		self.nextthink = time + 10;
		self.think = Request_Poll_Announce;	// Doubt we have to refresh this but...
	}
};

float (string captiona, string captionb, void() passfunc, string pollname = "") vote_init =
{
    clear_afk_status(self);	//R00k: (1/3/2022 12:54pm)

	if (clanring_gameconfig & CLANRING_DISABLE_VOTE)
	{
		stuffcmd(self,"play doors/runetry.wav\n");
		sprint(self, "Voting has been disabled.\n");
		return FALSE;
	}

	if (clanring_request != world)
	{
		if (time >= clanring_vote_retry_time)
		{
			bprint("\n\bThere is already a vote in progress to ", clanring_request.noise1, clanring_request.noise2, "\n");
			clanring_vote_retry_time = time + VOTE_IN_PROGRESS_SPAM_COOLDOWN;
		}
		else
		{
			sprint(self, "\n\bThere is already a vote in progress.\n");
		}
		return FALSE;
	}

   	if ((self.style & CLANRING_OBSERVER) && (clanring_state & CLANRING_MATCH_STARTED))//R00k
	{
		stuffcmd(self,"play doors/runetry.wav\n");
		sprint(self, "Observers cannot initiate votes during match.\n");
		return FALSE;
	}
	
	clanring_request = spawn();
	clanring_request.owner = self;
	clanring_request.noise1 = strzone(captiona);
	clanring_request.noise2 = strzone(captionb);
	clanring_request.classname = pollname;			// We can use the classname to determine criteria for certain requests.
	clanring_request.nextthink = time + 10;			// Announce the request every 10 seconds.
	clanring_request.think = Request_Poll_Announce;
	clanring_request.health = 20;					// This will be the time-limit for how long to wait for everyone to cast a vote.
	clanring_request.touch = passfunc;				// Call this function if the poll is positive

	// Safety: clear any stale ballots from prior polls before first announce
	// (prevents "more votes needed" from showing when nobody has voted yet)
	{
		local entity clr = find(world, classname, "player");
		while (clr)
		{
			clr.vote = 0;
			clr = find(clr, classname, "player");
		}
	}

	if ((Request_Poll_Votes_Needed(1) > 0))			// if there is only one player on the server then there is no need to announce the vote.
	{
		sound(world, CHAN_AUTO, "misc/menu1.wav", 1, ATTN_NONE);
		bprint("\n\[ vote request \]\n");
		bprint(" ", clanring_request.owner.netname, " requests to ", clanring_request.noise1, clanring_request.noise2, "\n");

		// Initial line shows "X votes needed" (no one has voted yet)
		local float yn_init;
		yn_init = Request_Poll_Votes_Needed(1);
		bprint("\n Type \byes\b or \bno\b in console to cast your vote.");
		if (yn_init == 1)
			bprint3(" ", strings_ftos_gold(1), " vote needed.\n\n");
		else
			bprint3(" ", strings_ftos_gold(yn_init), " votes needed.\n\n");
	}
	return TRUE;
};

// Recalculate current vote state after roster changes (e.g., disconnects)
// without attributing a new ballot. If a majority is already met,
// resolve the vote silently using the same side effects/messages
// as Request_Poll_Vote would, but without a per-player "voted" line.
void() Request_Poll_Recount =
{
    if (clanring_request == world)
        return;

    // Check majority YES against currently connected voters
    local float yn;
    yn = Request_Poll_Votes_Needed(1);
    if (yn == 0)
    {
        bprint("\nVote passed to ", clanring_request.noise1, clanring_request.noise2, ".\n\n");
        clanring_request.touch();
        sound(world, CHAN_AUTO, "misc/runekey.wav", 1, ATTN_NONE);
        Request_Poll_Cleanup();
        return;
    }

    // Check majority NO against currently connected voters
    local float nn;
    nn = Request_Poll_Votes_Needed(2);
    if (nn == 0)
    {
        sound(world, CHAN_AUTO, "misc/menu2.wav", 1, ATTN_NONE);
        bprint("The request was declined.\n");
        Request_Poll_Cleanup();
        return;
    }
};