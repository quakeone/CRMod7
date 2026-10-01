float vote_menu_checks;

void(float passed, string description) vote_menu_assert =
{
    if (!passed) error(strcat("VOTE MENU TEST FAILED: ", description));
    vote_menu_checks++;
};

void() worldspawn =
{
    float i, width;
    string name, title, row, expected;

    clanring_lastcount = 5;
    clanring_level = 1;
    for (i = 1; i <= 5; i++)
    {
        switch (i)
        {
            case 1: name = "gworld"; title = "Gloomworld"; break;
            case 2: name = "bravado_halloween"; title = "Bravado Halloween"; break;
            case 3: name = "skull"; title = "Skull Hunt"; break;
            case 4: name = "q30_magenta"; title = "Magenta Monstrosity"; break;
            case 5: name = "brick_b1"; title = "Brick"; break;
        }
        warpmap[i].name = name;
        warpmap[i].title = title;
        levels[i] = strzone(VoteMenu_FormatMapChoice(name));
    }
    VoteMenu_Init();
    width = strlen(VOTE_MENU_TEXTLINE[1]);
    for (i = 1; i <= 5; i++)
    {
        tokenize(vote_map_choices[i]);
        name = argv(0);
        title = VoteMenu_get_map_by_name(name);
        expected = sprintf("%s %s", strpad(17, name), redify(strpad(21, title)));
        row = VOTE_MENU_TEXTLINE[i];
        vote_menu_assert(strlen(row) == width, "all centered rows have equal width");
        vote_menu_assert(substring(row, 2, strlen(expected)) == expected, "titles share a column and names remain complete");
        vote_menu_assert(VOTE_MENU_TEXTLINE[i + 6] == redify(row), "highlight preserves alignment");
    }
    VoteMenu_Cleanup();
    // An unknown map and a name longer than the usual column must still align.
    strunzone(levels[2]);
    levels[2] = strzone("a_very_long_unknown_map_name");
    VoteMenu_Init();
    width = strlen(VOTE_MENU_TEXTLINE[1]);
    for (i = 1; i <= 5; i++)
    {
        vote_menu_assert(strlen(VOTE_MENU_TEXTLINE[i]) == width, "unknown long map rows have equal width");
        tokenize(vote_map_choices[i]);
        name = argv(0);
        if (name == "a_very_long_unknown_map_name")
            vote_menu_assert(substring(VOTE_MENU_TEXTLINE[i], 2, strlen(name)) == name, "unknown map token preserved");
    }
    VoteMenu_Cleanup();
    print(sprintf("VOTE MENU TEST PASSED: %g checks\n", vote_menu_checks));
    localcmd("quit\n");
};
