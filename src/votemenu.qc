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

string(string maparg) VoteMenu_FormatMapChoice =
{
    string title;

    if (maparg == "")
        return "";

    title = VoteMenu_get_map_by_name(maparg);
    if (title == "" || title == "error" || title == "Error")
        return maparg;

    return sprintf("%s %s",
        strpad(16, substring(maparg, 0, 16)),
        redify(strpad(21, substring(title, 0, 21))));
};

float(string choice) VoteMenu_IsCurrentMap =
{
    if (!choice || choice == "")
        return FALSE;

    tokenize(choice);
    return !strcasecmp(argv(0), clanring_current_mapname());
};

void() VoteMenu_Cleanup =
{
	for (float i = 1; i <= 5; i++)
	{
		if (vote_map_choices[i] != "")
			strunzone(vote_map_choices[i]);
		vote_map_choices[i] = "";

		if (VOTE_MENU_TEXTLINE[i] != "")
			strunzone(VOTE_MENU_TEXTLINE[i]);
		VOTE_MENU_TEXTLINE[i] = "";

		if (VOTE_MENU_TEXTLINE[i + 6] != "")
			strunzone(VOTE_MENU_TEXTLINE[i + 6]);
		VOTE_MENU_TEXTLINE[i + 6] = "";
	}
}

//
//	V O T E   M E N U   I N I T
//
//	Initialize all the wacky strings to construct the menu
//
float () VoteMenu_Init =
{
    string nextmap_textline[6];
    float usedIndices[6];
    float nextlevel, index = 1, canUse = FALSE, show_console_info;

    // Reinitialization can happen when a player repeatedly advances an active
    // nextmap vote. Release the previous menu before replacing its strings.
    VoteMenu_Cleanup();

    show_console_info = utils_show_nextmap_console_info();

    nextlevel = clanring_level;
    if (nextlevel < 1 || nextlevel > clanring_lastcount)
        nextlevel = 1;

    // The rotation index can still point at the map that just ended (for
    // example after a manual map vote). Find the next distinct map instead.
    index = nextlevel;
    for (float offset = 0; offset < clanring_lastcount; offset++)
    {
        if (levels[index] != "" && !VoteMenu_IsCurrentMap(levels[index]))
        {
            nextlevel = index;
            break;
        }

        index++;
        if (index > clanring_lastcount)
            index = 1;
    }

    if (levels[nextlevel] == "")
        nextmap_textline[1] = VoteMenu_FormatMapChoice(default_nextmap);
    else
        nextmap_textline[1] = levels[nextlevel];
    vote_map_choices[1] = strzone(nextmap_textline[1]);
    usedIndices[1] = nextlevel;

    for (float j = 2; j < 6; j++)
    {
        index = floor(random() * clanring_lastcount) + 1;

        // Walk forward from a random starting point. This guarantees that we
        // terminate and that the current map is not offered when alternatives
        // exist, even with a short custom rotation.
        for (float attempts = 0; attempts < clanring_lastcount; attempts++)
        {
            canUse = TRUE;

            if (levels[index] == "" || VoteMenu_IsCurrentMap(levels[index]))
                canUse = FALSE;

            for (float i = 1; i < j; i++)
            {
                if (usedIndices[i] == index)
                {
                    canUse = FALSE;
                    break;
                }
            }

            if (canUse)
                break;

            index++;
            if (index > clanring_lastcount)
                index = 1;
        }

        if (canUse && levels[index] != "")
        {
            usedIndices[j] = index;
            nextmap_textline[j] = levels[index];
            if (show_console_info)
                dprint(nextmap_textline[j], "\n");
            vote_map_choices[j] = strzone(nextmap_textline[j]);
        }
        else
        {
            if (show_console_info)
                dprint("Not enough distinct non-current maps to fill vote menu\n");

            // Keep every menu slot usable without reintroducing the current
            // map. Duplicate slot 1 only for unusually short rotations.
            nextmap_textline[j] = nextmap_textline[1];
            vote_map_choices[j] = strzone(nextmap_textline[j]);
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

	VOTE_MENU_TEXTLINE[1] = strreplace("A", (strpad(38, vote_map_choices[1])), VOTE_MENU_TEXTLINE[1]);
	VOTE_MENU_TEXTLINE[7] = redify(VOTE_MENU_TEXTLINE[1]);

	VOTE_MENU_TEXTLINE[2] = strreplace("A", (strpad(38, vote_map_choices[2])), VOTE_MENU_TEXTLINE[2]);
	VOTE_MENU_TEXTLINE[8] = redify(VOTE_MENU_TEXTLINE[2]);

	VOTE_MENU_TEXTLINE[3] = strreplace("A", (strpad(38, vote_map_choices[3])), VOTE_MENU_TEXTLINE[3]);
	VOTE_MENU_TEXTLINE[9] = redify(VOTE_MENU_TEXTLINE[3]);

	VOTE_MENU_TEXTLINE[4]  = strreplace("A", (strpad(38, vote_map_choices[4])), VOTE_MENU_TEXTLINE[4]);
	VOTE_MENU_TEXTLINE[10] = redify(VOTE_MENU_TEXTLINE[4]);

	VOTE_MENU_TEXTLINE[5]  = strreplace("A", (strpad(38, vote_map_choices[5])), VOTE_MENU_TEXTLINE[5]);
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

    return nextlevel;
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
