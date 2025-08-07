/*
    ---------------------------------------------------
    G A M E O V E R   N E X T M A P   V O T E   M E N U
    ---------------------------------------------------
*/

string VOTE_MENU_TEXTLINE[12];

//
// V o t e M e n u  G e t  M a p   b y   N a m e
//
// returns a string for the title of 'maparg' from the global warpmap array; for example: "The Abandoned Base".
//
string VoteMenu_get_map_by_name(string maparg) =
{
    if (maparg == "")
        return "Error";

	for (float index = 1 ; index < (warpmap.length) ; index++)
	{
		if (warpmap[index].name != "" && warpmap[index].name == maparg)
			return (warpmap[index].title);
	}
	return "error";
};

void() VoteMenu_Cleanup =
{
	strunzone(vote_map_choices[1]);
	strunzone(vote_map_choices[2]);
	strunzone(vote_map_choices[3]);
	strunzone(vote_map_choices[4]);
	strunzone(vote_map_choices[5]);

	strunzone(VOTE_MENU_TEXTLINE[1]);
	strunzone(VOTE_MENU_TEXTLINE[2]);
	strunzone(VOTE_MENU_TEXTLINE[3]);
	strunzone(VOTE_MENU_TEXTLINE[4]);
	strunzone(VOTE_MENU_TEXTLINE[5]);

	strunzone(VOTE_MENU_TEXTLINE[7]);
	strunzone(VOTE_MENU_TEXTLINE[8]);
	strunzone(VOTE_MENU_TEXTLINE[9]);
	strunzone(VOTE_MENU_TEXTLINE[10]);
	strunzone(VOTE_MENU_TEXTLINE[11]);
}

//
//	V O T E   M E N U   I N I T
//
//	Initialize all the wacky strings to construct the menu
//
void () VoteMenu_Init =
{
    string nextmap_textline[6];
    float usedIndices[6];
    float nextlevel, index = 1, canUse = FALSE;

    nextlevel = (clanring_level < 1 ? 1 : clanring_level);

    if (levels[nextlevel] == "")
        levels[nextlevel] = default_nextmap;

    nextmap_textline[1] = levels[nextlevel];
    vote_map_choices[1] = strzone(nextmap_textline[1]);
    usedIndices[1] = nextlevel;

    for (float j = 2; j < 6; j++)
    {
        while (canUse == FALSE)
        {
            index = ceil(random() * clanring_lastcount);

            if (index < 1)
                index = 1; // just in case...

            canUse = TRUE;

            for (float i = 1; i < j; i++)
            {
                if (usedIndices[i] == index)
                {
                    canUse = FALSE;
                    break;
                }
            }
        }

        if (levels[index] != "")
        {
            usedIndices[j] = index;
            nextmap_textline[j] = levels[index]; dprint(nextmap_textline[j], "\n");
            vote_map_choices[j] = strzone(nextmap_textline[j]);
        }
        else
        {
            dprint(sprintf("Skipping invalid level at index %g\n", index));
        }
        canUse = FALSE;
    }

	VOTE_MENU_TEXTLINE[0] = "\(\=\=\=\=\=\= Vote for the Next Map \=\=\=\=\=\=\)\n\n\n";
	VOTE_MENU_TEXTLINE[1] = "\1 A\n\n";
	VOTE_MENU_TEXTLINE[2] = "\2 A\n\n";
	VOTE_MENU_TEXTLINE[3] = "\3 A\n\n";
	VOTE_MENU_TEXTLINE[4] = "\4 A\n\n";
	VOTE_MENU_TEXTLINE[5] = "\5 A\n\n";
	VOTE_MENU_TEXTLINE[6] = "\n\n";

	VOTE_MENU_TEXTLINE[1] = strreplace("A", (strpad(42, vote_map_choices[1])), VOTE_MENU_TEXTLINE[1]);
	VOTE_MENU_TEXTLINE[7] = redify(VOTE_MENU_TEXTLINE[1]);

	VOTE_MENU_TEXTLINE[2] = strreplace("A", (strpad(42, vote_map_choices[2])), VOTE_MENU_TEXTLINE[2]);
	VOTE_MENU_TEXTLINE[8] = redify(VOTE_MENU_TEXTLINE[2]);

	VOTE_MENU_TEXTLINE[3] = strreplace("A", (strpad(42, vote_map_choices[3])), VOTE_MENU_TEXTLINE[3]);
	VOTE_MENU_TEXTLINE[9] = redify(VOTE_MENU_TEXTLINE[3]);

	VOTE_MENU_TEXTLINE[4]  = strreplace("A", (strpad(42, vote_map_choices[4])), VOTE_MENU_TEXTLINE[4]);
	VOTE_MENU_TEXTLINE[10] = redify(VOTE_MENU_TEXTLINE[4]);

	VOTE_MENU_TEXTLINE[5]  = strreplace("A", (strpad(42, vote_map_choices[5])), VOTE_MENU_TEXTLINE[5]);
	VOTE_MENU_TEXTLINE[11] = redify(VOTE_MENU_TEXTLINE[5]);

	VOTE_MENU_TEXTLINE[1] = strzone(VOTE_MENU_TEXTLINE[1]);
	VOTE_MENU_TEXTLINE[2] = strzone(VOTE_MENU_TEXTLINE[2]);
	VOTE_MENU_TEXTLINE[3] = strzone(VOTE_MENU_TEXTLINE[3]);
	VOTE_MENU_TEXTLINE[4] = strzone(VOTE_MENU_TEXTLINE[4]);
	VOTE_MENU_TEXTLINE[5] = strzone(VOTE_MENU_TEXTLINE[5]);

	VOTE_MENU_TEXTLINE[7]  = strzone(VOTE_MENU_TEXTLINE[7]);
	VOTE_MENU_TEXTLINE[8]  = strzone(VOTE_MENU_TEXTLINE[8]);
	VOTE_MENU_TEXTLINE[9]  = strzone(VOTE_MENU_TEXTLINE[9]);
	VOTE_MENU_TEXTLINE[10] = strzone(VOTE_MENU_TEXTLINE[10]);
	VOTE_MENU_TEXTLINE[11] = strzone(VOTE_MENU_TEXTLINE[11]);
};

.float centerTime;

void () VoteMenu_Print =
{
	if (self.style & CLANRING_AFK_CLIENT)
		return;

	// if (!(self.style & CLANRING_CONNECTED))
	// 	return;

	if (self.centerTime <= time)
	{
		pqc_match_time (0, (floor(intermission_exittime - time)));

		centerprint(self, VOTE_MENU_TEXTLINE[0], VOTE_MENU_TEXTLINE[1], VOTE_MENU_TEXTLINE[2], VOTE_MENU_TEXTLINE[3], VOTE_MENU_TEXTLINE[4], VOTE_MENU_TEXTLINE[5], VOTE_MENU_TEXTLINE[6]);

		switch (self.warp_map)
		{
			case 1:
				centerprint(self, VOTE_MENU_TEXTLINE[0], VOTE_MENU_TEXTLINE[7], VOTE_MENU_TEXTLINE[2], VOTE_MENU_TEXTLINE[3], VOTE_MENU_TEXTLINE[4], VOTE_MENU_TEXTLINE[5], VOTE_MENU_TEXTLINE[6]);
				break;
			case 2:
				centerprint(self, VOTE_MENU_TEXTLINE[0], VOTE_MENU_TEXTLINE[1], VOTE_MENU_TEXTLINE[8], VOTE_MENU_TEXTLINE[3], VOTE_MENU_TEXTLINE[4], VOTE_MENU_TEXTLINE[5], VOTE_MENU_TEXTLINE[6]);
				break;
			case 3:
				centerprint(self, VOTE_MENU_TEXTLINE[0], VOTE_MENU_TEXTLINE[1], VOTE_MENU_TEXTLINE[2], VOTE_MENU_TEXTLINE[9], VOTE_MENU_TEXTLINE[4], VOTE_MENU_TEXTLINE[5], VOTE_MENU_TEXTLINE[6]);
				break;
			case 4:
				centerprint(self, VOTE_MENU_TEXTLINE[0], VOTE_MENU_TEXTLINE[1], VOTE_MENU_TEXTLINE[2], VOTE_MENU_TEXTLINE[3], VOTE_MENU_TEXTLINE[10], VOTE_MENU_TEXTLINE[5], VOTE_MENU_TEXTLINE[6]);
				break;
			case 5:
				centerprint(self, VOTE_MENU_TEXTLINE[0], VOTE_MENU_TEXTLINE[1], VOTE_MENU_TEXTLINE[2], VOTE_MENU_TEXTLINE[3], VOTE_MENU_TEXTLINE[4], VOTE_MENU_TEXTLINE[11], VOTE_MENU_TEXTLINE[6]);
				break;
		}
		self.centerTime = time + 1;
	}
}

//eof
