//
// match.qc
//
// This file contains code for the elohim server match (tournament) mode.
//
// Fields used:
//
// .height          - used to store player team
//
// In elohim_match_timer:
//
// lip 		- minutes left
// count 	- seconds left
// dest 	- checkpoint times for countdown
//
// All code by J.P. Grossman unless otherwise commented.
//
// In both match modes the ready players are stored in a linked list with head
// elohim_sentinel.next_player and linked by .next_player.
//
// In team mode, the list is orgainized by teams (i.e. all players in one team
// appear consecutively), and each team points to the first player
// in the team via pteam.next_player.  The teams are stored in a linked list
// with head elohim_sentinel.next_team and linked by .next_team.  Finally,
// each player points to his team via player.next_team.
//
// In individual mode, .next_player and .next_team are always the same.  i.e.
// each player has 2 copies of the exact same pointer, pointing to the next
// player; this is done for simplicity so that match mode and individual mode
// can use the same code.
//

// Function declarations
void() match_timer_think2;
void() match_list_ghosts;
void() match_enter_ghost_code;
void() match_start_unpause_countdown;
void() match_unpause;
void(entity ghostent) match_restore_ghost;
float() match_is_imbalanced;
void() spawns_restore_model;
void() votables_disable_item;
void () votables_force_start;
void() console_show_score;
void() console_autodump;
void() admin_dm3_screenshot_setup;
void() StartRuneSpawn;
void() GibPlayer;
void() quaketag_clear;
void(entity player) quaketag_disconnect_notify;
void() PlayerDead;
void() weapon_prewar_cleanup;
void() weapon_prewar_animate_think;
void() weapon_prewar_setup;
float() match_aborted_too_early;
// Random Pickup (reshuffle teams without repeats per roster)
void() match_rpickup;
void() match_request_rpickup;
// Utility: remove a player from lists without announcements
void(entity player) match_remove_player_silent;
// Utility: add a player to a team without announcements
void(entity player, float targetColor) match_add_player_silent;

void() match_clear_leavemealone =
{
    self.leavemealone = FALSE;
    if (self.solid == SOLID_TRIGGER)
        self.solid = SOLID_SLIDEBOX;
    setorigin(self, self.origin);
};

// Only allow leave-me-alone during DM/CTF match prewar (non-arena)
float() leavemealone_mode_allows =
{
    if (!(clanring_playmode & CLANRING_MATCH_MODE))
        return FALSE;
    if (clanring_state & CLANRING_MATCH_STARTED)
        return FALSE;
    if (mode_is_arena())
        return FALSE;
    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
        return TRUE;

    // Disallow in other specialized match types
    if (clanring_playmode & (CLANRING_AIRSHOT_MODE | CLANRING_DMM4_MODE | CLANRING_WIPEOUT_MODE | CLANRING_CA_MODE | CLANRING_RA_MODE))
        return FALSE;

    // Base DM match prewar
    return TRUE;
};

//TODO: Make this dynamic
static string pausehint[6] =
{
    "Hint: A health pack respawns every 20 seconds",
    "Hint: End your pent or quad at an armor",
    "Hint: don't walk around with your best weapon out",
    "Hint: communicate with your team about enemy positions and important items on the map",
    "Hint: megahealth respawns at most 125 seconds after being taken.",
    "Hint: Leave backpack for teammates; communicate location"
};

// ============================================================
// Random pickup deck (global state) - cycles all unique assignments
// for the current roster & team-size distribution before repeat.
// ============================================================
float rs_valid;                    // 1 if a deck is built for current roster
float rs_N;                        // number of committed players (READY, non-observer)
float rs_T;                        // number of teams present in roster
float rs_counts[8];                // team sizes aligned with rs_colors
float rs_colors[8];                // team identifiers (height), sorted asc
entity rs_plist[32];               // fixed player order for this deck
float rs_labels[32];               // current multiset permutation labels (0..rs_T-1)
float rs_used_in_cycle;            // how many permutations yielded in this cycle
float rs_total_perms;              // multinomial count of unique assignments
float rs_start_offset;             // random start offset within the cycle
float rs_work_counts[8];           // scratch counts for unranking
// Suppress client "cannot change color" prints during server-driven reshuffles
float rs_silence_until;            // absolute time until which color-change prints are muted
void()  rs_enforce_balanced_counts; // force balanced team-size targets for rpickup

// Forward decls for deck helpers
float() rs_build_or_refresh;
void()  rs_build_deck_from_roster;
float() rs_same_roster;
float() rs_next_labels;
float(float n, float k) rs_choose;
void()  rs_enforce_balanced_counts;
float() rs_multinomial_total;
void(float rank) rs_unrank_into_labels;
float(float remN, float dec_idx) rs_multinomial_with_dec_from_work;
// ============================================================


//
//  I N I T  W O R L D
//
void() match_init_world =
{
    clanring_numteams = 0;
    clanring_match_aborted = FALSE;
    clanring_sentinel.next_team = world;
    clanring_sentinel.movetarget = world;
    clanring_sentinel.frags = CLANRING_NEGINF;
    if (cvar("teamplay"))
    {
        clanring_szthe = "The ";
        clanring_szteam = "team";
    }
    else
    {
        clanring_szthe = "";
        clanring_szteam = "player";
    }
};

float() match_prewar =
{
    if (!(clanring_playmode & CLANRING_MATCH_MODE))	//Fixed non matchmode unlimited ammo
    
        return FALSE;

    if ((clanring_playmode & CLANRING_MATCH_MODE)&&((clanring_state & CLANRING_MATCH_STARTED)))
        return FALSE;
    else
        return TRUE;
};

//
//  S H O W  T I M E L I M I T
//
//  Set the console variable 'timelimit' to show relevant match
//  information.
//
void() match_show_timelimit =
{
    local string temp;

    localcmd("timelimit \"");

    if (!(clanring_state & CLANRING_TIMER_STARTED))
    {
        if (clanring_state & CLANRING_MATCH_OVER)
        {
            localcmd("Final Score is ");
            temp = ftos(clanring_first_place.frags);
            if (clanring_first_place.frags < 0)
                localcmd("<");
            localcmd(temp);
            if (clanring_first_place.frags < 0)
                localcmd(">");
            localcmd(" - ");
            if (clanring_second_place != clanring_sentinel)
            {
                temp = ftos(clanring_second_place.frags);
                if (clanring_second_place.frags < 0)
                    localcmd("<");
                localcmd(temp);
                if (clanring_second_place.frags < 0)
                    localcmd(">");
            }
            else
                localcmd("???");
            localcmd("\"\n");
        }
        else
        {
            temp = ftos(clanring_timelimit);
            localcmd4(temp, " : Waiting for ", clanring_szteam, "s\"\n");
        }
    }
    else
    {
        if (!(clanring_state & CLANRING_MATCH_STARTED))
        {
            temp = ftos(clanring_timelimit);
            localcmd2(temp, " : Match Starting\"\n");
        }
        else
        {
            if (clanring_match_timer.lip < 0)
            {
                localcmd("Sudden death\"\n");
            }
            else
            {
                temp = ftos(clanring_match_timer.lip);
                localcmd2(temp, "\"\n");
            }
        }
    }
};

//
//  I T E M  R E S E T
//
//  Prevent an item from respawning.
//
void() match_item_reset =
{
    self.nextthink = -1;
};

//
//  I N I T  P L A Y E R
//
//  Initialize a player in match mode and make him an observer.
//
void() match_init_player =
{
    self.style = self.style - (self.style & CLANRING_READY);
    self.finaldest_x = time; // So we don't get autokickedd!!
    observer_start ();
    clear_name();
};

//
//  U N R E A D Y  P L A Y E R
//
void() match_unready_player =
{
    self.style = self.style - (self.style & CLANRING_READY);
    clear_name();
};

//
//  R E S E T
//
void() match_reset =
{
    clanring_state = clanring_state - (clanring_state & CLANRING_MATCH_WAIT);
    clanring_state = clanring_state - (clanring_state & CLANRING_NULL_FLAG);
    clanring_match_aborted = FALSE;

    // prevent items from respawning
    utils_do_items(match_item_reset);

    // stop weapon animations
    utils_do_weapons(weapon_prewar_cleanup);

    // remove all backpacks
    utils_do_item(SUB_Remove, "item_backpack");

    // unready all players
    utils_do_players(match_unready_player);

    // remove all ghosts
    utils_do_item(SUB_Remove, "clanring_ghost");
    if (teamplay)
        announce("No teams present");

    if (self.classname == "clanring_match_timer")
        remove(self);

    pqc_match_time (0, 0);
    //reset between matches in case of overtime or interrupted match abort (fixme)
/*
    clanring_timelimit = default_timelimit;
    utils_set_cvar ("timelimit", clanring_timelimit);
    timelimit = (cvar ("timelimit") * 60);
*/
    pqc_match_reset ();
};

//
//  G I B  P L A Y E R
//
//  Gib players; set observers to colour 0.  Called at start
//  and end of match.
//
void() match_gib_player =
{
    if (self.style & CLANRING_OBSERVER)
    {
        stuffcmd(self, "color 0\n");
        clear_name();
    }
    else
    {
        if (!(self.style & CLANRING_READY))
        {
            observer_start ();
        }
        else
        {
            clear_name();
            self.health = -99;
            GibPlayer ();
            self.deadflag = DEAD_DYING;

            self.think = respawn;
            self.nextthink = time + 1;

            if (clanring_state & CLANRING_MATCH_STARTED)
            {
                // start of match
                self.frags = 0;
                self.totalquad = 0;
                stats_reset_player ();
                self.join_time = time;    //Woods FPM stats
            }
            else
            {
                //bucksh0t: add time if player had quad when match ended
                if ((self.super_damage_finished >= time) && (self.items & IT_QUAD))
                {
                    self.totalquad += (time - self.quadtime);
                }

                // end of match
                remove(self.owner);
                self.owner = world;
            }
        }
    }
};

void() match_update_score_info =
{
    local string score;
    local string temp, tc = "";

    if (clanring_first_place != clanring_sentinel)
    {
        score = ftos(clanring_first_place.frags);
        tc = strings_get_colour(clanring_first_place.height);
        temp = sprintf("teamscore1:%s ",tc);

        forceinfokey (world, temp, score);

        if (clanring_second_place != clanring_sentinel)
        {
            score = ftos(clanring_second_place.frags);
            tc = strings_get_colour(clanring_second_place.height);
            temp = sprintf("teamscore2:%s ",tc);
            forceinfokey (world, temp, score);
        }
        else
        {
            forceinfokey (world, "teamscore2:none","0");
        }
    }
    else
    {
        forceinfokey (world, "teamscore1:none","0");
        forceinfokey (world, "teamscore2:none","0");
    }
};

//
//  B P R I N T  S C O R E
//
void() match_bprint_score =
{
    local string score;
    local string temp;

    score = ftos(clanring_first_place.frags);
    temp = strings_szplural(clanring_first_place.frags);
    announce6(clanring_szthe, clanring_first_place.netname, " has ", score, " frag", temp);
    if (clanring_second_place != clanring_sentinel)
    {
        score = ftos(clanring_second_place.frags);
        temp = strings_szplural(clanring_second_place.frags);
        announce6(clanring_szthe, clanring_second_place.netname, " has ", score, " frag", temp);
    }
    match_update_score_info();
};

// Decide whether an aborted match ended before enough time elapsed to log lastscores
float() match_aborted_too_early =
{
    local float total_secs, remaining_secs, elapsed_secs, quarter_secs;

    if (!clanring_match_aborted)
        return FALSE;

    // Only treat matches with an active timer as "timed" for this guard
    if (clanring_match_timer == world)
        return FALSE;

    total_secs = clanring_timelimit * 60;
    if (total_secs <= 0)
        return FALSE;

    remaining_secs = 0;
    if (clanring_match_timer != world)
    {
        remaining_secs = (clanring_match_timer.lip * 60) + clanring_match_timer.count;
        if (remaining_secs < 0)
            remaining_secs = 0;
    }

    elapsed_secs = total_secs - remaining_secs;
    if (elapsed_secs < 0)
        elapsed_secs = 0;

    quarter_secs = total_secs * 0.25;
    if (quarter_secs <= 0)
        return FALSE;

    return (elapsed_secs < quarter_secs);
};

//
//  Log final scores for lastscores command (disk-only JSON)
//
void() match_log_score =
{
    // Hoisted locals to satisfy QC and avoid duplicate-definition warnings
    local string entry, nameA, nameB, tn, pn, s;
    local entity teamA, teamB, p, A, B, t;
    local entity top1t, top2t, top3t, top4t;
    local float w1, w2, w3, w4, w, len;

    // --- NEW: scratch for team sorting (safe upper bound)
    local string namesA[32], namesB[32];
    local float  fragsA[32], fragsB[32];
    local float  na, nb, i, j, best, tf;
    local string ts;

    // ---------- 1v1 arena summary (DMM4 & AIRSHOT) ----------
    if (clanring_playmode & (CLANRING_DMM4_MODE | CLANRING_AIRSHOT_MODE))
    {
        dmm4_set_winning_team(); // populates team_first_place / team_second_place

        A = team_first_place;
        B = team_second_place;

        // Fallbacks if unset
        if (A == boss || A == world)
        {
            A = boss;
            for (t = boss.next_team; t != world; t = t.next_team)
                if (t.wins >= A.wins) A = t;
        }
        if (B == boss || B == world)
        {
            B = world;
            for (t = boss.next_team; t != world; t = t.next_team)
                if (t != A) { B = t; break; }
        }

        nameA = (A.chain_gang != world && A.chain_gang.netname && A.chain_gang.netname != "")
                ? A.chain_gang.netname : A.netname;
        nameB = (B != world && B.chain_gang != world && B.chain_gang.netname && B.chain_gang.netname != "")
                ? B.chain_gang.netname : (B != world ? B.netname : "Opponent");
        if (!nameA || nameA == "") nameA = "Player1";
        if (!nameB || nameB == "") nameB = "Player2";

        entry = sprintf("%s %s - %s %s", nameA, ftos(A.wins), nameB, ftos(B.wins));
        json_append_lastscores(entry);
        return;
    }

    // ---------- CLAN ARENA & WIPEOUT (same handling) ----------
    if (clanring_playmode & (CLANRING_CA_MODE | CLANRING_WIPEOUT_MODE))
    {
        if (boss == world) return;
        if (boss.next_team == world) return;

        // Rank up to 4 teams by wins (descending)
        top1t = top2t = top3t = top4t = world;
        w1 = w2 = w3 = w4 = -99999;

        for (t = boss.next_team; t != world; t = t.next_team)
        {
            w = t.wins;
            if (w > w1) { w4 = w3; top4t = top3t; w3 = w2; top3t = top2t; w2 = w1; top2t = top1t; w1 = w; top1t = t; }
            else if (w > w2) { w4 = w3; top4t = top3t; w3 = w2; top3t = top2t; w2 = w; top2t = t; }
            else if (w > w3) { w4 = w3; top4t = top3t; w3 = w; top3t = t; }
            else if (w > w4) { w4 = w; top4t = t; }
        }

        // Build headline (strip trailing " team")
        entry = "";

        if (top1t != world)
        {
            tn = (top1t.netname && top1t.netname != "") ? top1t.netname : utils_rstrip(strings_get_teamname2(top1t.height));
            if (tn && tn != "") { len = strlen(tn); if (len >= 5 && substring(tn, len-5, 5) == " team") tn = substring(tn, 0, len-5); }
            if (!tn || tn == "") tn = "Team";
            entry = strcat(entry, tn, " ", ftos(w1));
        }
        if (top2t != world)
        {
            tn = (top2t.netname && top2t.netname != "") ? top2t.netname : utils_rstrip(strings_get_teamname2(top2t.height));
            if (tn && tn != "") { len = strlen(tn); if (len >= 5 && substring(tn, len-5, 5) == " team") tn = substring(tn, 0, len-5); }
            if (!tn || tn == "") tn = "Team";
            entry = strcat(entry, " - ", tn, " ", ftos(w2));
        }
        if (top3t != world)
        {
            tn = (top3t.netname && top3t.netname != "") ? top3t.netname : utils_rstrip(strings_get_teamname2(top3t.height));
            if (tn && tn != "") { len = strlen(tn); if (len >= 5 && substring(tn, len-5, 5) == " team") tn = substring(tn, 0, len-5); }
            if (!tn || tn == "") tn = "Team";
            entry = strcat(entry, " - ", tn, " ", ftos(w3));
        }
        if (top4t != world)
        {
            tn = (top4t.netname && top4t.netname != "") ? top4t.netname : utils_rstrip(strings_get_teamname2(top4t.height));
            if (tn && tn != "") { len = strlen(tn); if (len >= 5 && substring(tn, len-5, 5) == " team") tn = substring(tn, 0, len-5); }
            if (!tn || tn == "") tn = "Team";
            entry = strcat(entry, " - ", tn, " ", ftos(w4));
        }

        if (entry == "") return;

        // Per-team player rows (same ranked order), names from chain_gang
        // top1
        entry = strcat(entry, "\n");
        if (top1t != world)
        {
            tn = (top1t.netname && top1t.netname != "") ? top1t.netname : utils_rstrip(strings_get_teamname2(top1t.height));
            if (tn && tn != "") { len = strlen(tn); if (len >= 5 && substring(tn, len-5, 5) == " team") tn = substring(tn, 0, len-5); }
            if (!tn || tn == "") tn = "Team";
            entry = strcat(entry, tn, ": ");
            p = top1t.chain_gang;
            while (p != world)
            {
                pn = (p.netname && p.netname != "") ? p.netname : "Player";
                entry = strcat(entry, pn, " ", ftos(p.frags));
                p = p.chain_gang;
                if (p != world) entry = strcat(entry, ", ");
            }
        }
        // top2
        if (top2t != world)
        {
            entry = strcat(entry, "\n");
            tn = (top2t.netname && top2t.netname != "") ? top2t.netname : utils_rstrip(strings_get_teamname2(top2t.height));
            if (tn && tn != "") { len = strlen(tn); if (len >= 5 && substring(tn, len-5, 5) == " team") tn = substring(tn, 0, len-5); }
            if (!tn || tn == "") tn = "Team";
            entry = strcat(entry, tn, ": ");
            p = top2t.chain_gang;
            while (p != world)
            {
                pn = (p.netname && p.netname != "") ? p.netname : "Player";
                entry = strcat(entry, pn, " ", ftos(p.frags));
                p = p.chain_gang;
                if (p != world) entry = strcat(entry, ", ");
            }
        }
        // top3
        if (top3t != world)
        {
            entry = strcat(entry, "\n");
            tn = (top3t.netname && top3t.netname != "") ? top3t.netname : utils_rstrip(strings_get_teamname2(top3t.height));
            if (tn && tn != "") { len = strlen(tn); if (len >= 5 && substring(tn, len-5, 5) == " team") tn = substring(tn, 0, len-5); }
            if (!tn || tn == "") tn = "Team";
            entry = strcat(entry, tn, ": ");
            p = top3t.chain_gang;
            while (p != world)
            {
                pn = (p.netname && p.netname != "") ? p.netname : "Player";
                entry = strcat(entry, pn, " ", ftos(p.frags));
                p = p.chain_gang;
                if (p != world) entry = strcat(entry, ", ");
            }
        }
        // top4
        if (top4t != world)
        {
            entry = strcat(entry, "\n");
            tn = (top4t.netname && top4t.netname != "") ? top4t.netname : utils_rstrip(strings_get_teamname2(top4t.height));
            if (tn && tn != "") { len = strlen(tn); if (len >= 5 && substring(tn, len-5, 5) == " team") tn = substring(tn, 0, len-5); }
            if (!tn || tn == "") tn = "Team";
            entry = strcat(entry, tn, ": ");
            p = top4t.chain_gang;
            while (p != world)
            {
                pn = (p.netname && p.netname != "") ? p.netname : "Player";
                entry = strcat(entry, pn, " ", ftos(p.frags));
                p = p.chain_gang;
                if (p != world) entry = strcat(entry, ", ");
            }
        }

        json_append_lastscores(entry);
        return;
    }

    // ---------- ROCKET ARENA ----------
    if (clanring_playmode & CLANRING_RA_MODE)
    {
        arena_set_winning_team(); // fills team_first_place / team_second_place

        A = team_first_place; B = team_second_place;

        // Fallbacks
        if (A == boss || A == world)
        {
            A = boss;
            for (t = boss.next_team; t != world; t = t.next_team)
                if (t.wins >= A.wins) A = t;
        }
        if (B == boss || B == world)
        {
            B = world;
            for (t = boss.next_team; t != world; t = t.next_team)
                if (t != A) { B = t; break; }
        }

        nameA = (A.chain_gang != world && A.chain_gang.netname && A.chain_gang.netname != "")
                ? A.chain_gang.netname : A.netname;
        nameB = (B != world && B.chain_gang != world && B.chain_gang.netname && B.chain_gang.netname != "")
                ? B.chain_gang.netname : (B != world ? B.netname : "Opponent");
        if (!nameA || nameA == "") nameA = "Player1";
        if (!nameB || nameB == "") nameB = "Player2";

        entry = sprintf("%s %s - %s %s", nameA, ftos(A.wins), nameB, ftos(B.wins));
        json_append_lastscores(entry);
        return;
    }

    // ---------- TEAM MODES (e.g., CTF/DM) ----------
    if (teamplay)
    {
        teamA = clanring_sentinel.next_team; if (!teamA) return;
        teamB = teamA.next_team;             if (!teamB) return;

        nameA = utils_rstrip(strings_get_teamname2(teamA.height));
        nameB = utils_rstrip(strings_get_teamname2(teamB.height));

        // strip trailing " team"
        if (nameA && nameA != "") { len = strlen(nameA); if (len >= 5 && substring(nameA, len-5, 5) == " team") nameA = substring(nameA, 0, len-5); }
        if (nameB && nameB != "") { len = strlen(nameB); if (len >= 5 && substring(nameB, len-5, 5) == " team") nameB = substring(nameB, 0, len-5); }
        if (!nameA || nameA == "") nameA = "TeamA";
        if (!nameB || nameB == "") nameB = "TeamB";

        // Ensure the winning team (higher frags) is listed first
        if (teamB.frags > teamA.frags)
        {
            // swap teams
            t = teamA; teamA = teamB; teamB = t;
            // swap display names to match
            s = nameA; nameA = nameB; nameB = s;
        }

        entry = sprintf("%s %s - %s %s\n", nameA, ftos(teamA.frags), nameB, ftos(teamB.frags));

        // ---- NEW: collect and sort Team A members by frags (desc)
        na = 0;
        p = teamA.next_player;
        while (p && p.next_team == teamA)
        {
            pn = (p.netname && p.netname != "") ? p.netname : "Player";
            if (na < 32)
            {
                namesA[na] = strzone(pn);
                fragsA[na] = p.frags;
                na = na + 1;
            }
            p = p.next_player;
        }
        // selection sort (desc by frags)
        for (i = 0; i < na - 1; i = i + 1)
        {
            best = i;
            for (j = i + 1; j < na; j = j + 1)
                if (fragsA[j] > fragsA[best]) best = j;
            if (best != i)
            {
                tf = fragsA[i]; fragsA[i] = fragsA[best]; fragsA[best] = tf;
                ts = namesA[i]; namesA[i] = namesA[best]; namesA[best] = ts;
            }
        }
        entry = strcat(entry, nameA, ": ");
        for (i = 0; i < na; i = i + 1)
        {
            entry = strcat(entry, namesA[i], " ", ftos(fragsA[i]));
            if (i + 1 < na) entry = strcat(entry, ", ");
        }
        for (i = 0; i < na; i = i + 1) if (namesA[i]) strunzone(namesA[i]);

        // ---- NEW: collect and sort Team B members by frags (desc)
        nb = 0;
        p = teamB.next_player;
        while (p && p.next_team == teamB)
        {
            pn = (p.netname && p.netname != "") ? p.netname : "Player";
            if (nb < 32)
            {
                namesB[nb] = strzone(pn);
                fragsB[nb] = p.frags;
                nb = nb + 1;
            }
            p = p.next_player;
        }
        // selection sort (desc by frags)
        for (i = 0; i < nb - 1; i = i + 1)
        {
            best = i;
            for (j = i + 1; j < nb; j = j + 1)
                if (fragsB[j] > fragsB[best]) best = j;
            if (best != i)
            {
                tf = fragsB[i]; fragsB[i] = fragsB[best]; fragsB[best] = tf;
                ts = namesB[i]; namesB[i] = namesB[best]; namesB[best] = ts;
            }
        }
        entry = strcat(entry, "\n", nameB, ": ");
        for (i = 0; i < nb; i = i + 1)
        {
            entry = strcat(entry, namesB[i], " ", ftos(fragsB[i]));
            if (i + 1 < nb) entry = strcat(entry, ", ");
        }
        for (i = 0; i < nb; i = i + 1) if (namesB[i]) strunzone(namesB[i]);

        json_append_lastscores(entry);
        return;
    }

    // ---------- FFA ----------
    if (clanring_second_place == clanring_sentinel) return;

    entry = sprintf("%s %s - %s %s",
        clanring_first_place.netname, ftos(clanring_first_place.frags),
        clanring_second_place.netname, ftos(clanring_second_place.frags));

    json_append_lastscores(entry);
};

//
//  M A T C H  B P R I N T  T I M E
//
void() match_bprint_time =
{
    if (clanring_match_timer.lip < 0)
        announce("Sudden death overtime");
    else
    {
        local string temp;
        temp = ftos(clanring_match_timer.lip);
        bprint3("Time remaining:  ", temp, ":");
        cprint3("\"Time remaining:  ", temp, ":");
        temp = ftos(clanring_match_timer.count);
        if (clanring_match_timer.count < 10)
        {
            bprint("0");
            cprint("0");
        }
        bprint2(temp, "\n");
        localcmd2(temp, "\"\n");
    }
};

//
//  S P R I N T  S T A T U S
//
//  Print the time remaining and the score.
//
void() match_sprint_status =
{
    local string temp, score;

    if (!(clanring_state & (CLANRING_MATCH_STARTED | CLANRING_MATCH_OVER)))
    {
        if (clanring_state & CLANRING_TIMER_STARTED)
        {
            local string s, pl;
            s = ftos(clanring_match_timer.count);
            pl = strings_szplural(clanring_match_timer.count);
            sprint5(self, "Match begins in ", s, " second", pl, "\n");
        }
        else
        {
            sprint3(self, "Waiting for ", clanring_szteam, "s\n");
        }
        return;
    }

    if (clanring_state & CLANRING_MATCH_OVER)
    {
        sprint(self, "Match over\n");
    }
    else
    {
        if (clanring_match_timer.lip < 0)
        {
            sprint(self, "Sudden death overtime\n");
        }
        else
        {
            temp = ftos(clanring_match_timer.lip);
            sprint3(self, "Time remaining:  ", temp, ":");
            temp = ftos(clanring_match_timer.count);
            if (clanring_match_timer.count < 10)
            {
                sprint(self, "0");
            }
            sprint2(self, temp, "\n");
        }
    }
    if (clanring_first_place != clanring_sentinel)
    {
        score = ftos(clanring_first_place.frags);
        temp = strings_szplural(clanring_first_place.frags);
        if (!(clanring_state & CLANRING_MATCH_OVER))
            sprint7(self, clanring_szthe, clanring_first_place.netname, " has ", score, " frag", temp, "\n");
        else
            sprint7(self, clanring_szthe, clanring_first_place.netname, " had ", score, " frag", temp, "\n");
    }
    if (clanring_second_place != clanring_sentinel)
    {
        score = ftos(clanring_second_place.frags);
        temp = strings_szplural(clanring_second_place.frags);
        if (!(clanring_state & CLANRING_MATCH_OVER))
            sprint7(self, clanring_szthe, clanring_second_place.netname, " has ", score, " frag", temp, "\n");
        else
            sprint7(self, clanring_szthe, clanring_second_place.netname, " had ", score, " frag", temp, "\n");
    }
};

//
//  C H E C K  A U T O S S
//
//  Check to see if there is a delayed autoss that needs to be taken.
//
void() match_check_autoss =
{
    if (clanring_state & CLANRING_DELAYED_AUTOSS)
    {
        admin_dm3_screenshot_setup();
        clanring_state = clanring_state - (clanring_state & CLANRING_DELAYED_AUTOSS);
    }
    clanring_match_timer.think = match_reset;
    clanring_match_timer.nextthink = time + 2;
};

void(float score_diff) match_postgame_sound =
{
    local float prnd;

    if ((!(clanring_gameconfig & CLANRING_ENABLE_MATCHSOUNDS))||(!(clanring_matchsound_count)))
        return;

    prnd = random();
    if (prnd < .8)
    {
        if (((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (score_diff > 200)) ||
            (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (score_diff > 40)))	//Change these to percentile score1/(score1+score2)
        {
            if (clanring_matchsound_blowout_count)
            {
                prnd = floor(random() * clanring_matchsound_blowout_count);
                if (matchsound_blowout[prnd] != "")
                {
                    sound (world, CHAN_AUTO, matchsound_blowout[prnd], 1, ATTN_NONE);
                    return;
                }
            }
        }
        else if (((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (score_diff < 50)) ||
            (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (score_diff < 10)))
        {
            if (clanring_matchsound_rematch_count)
            {
                prnd = floor(random() * clanring_matchsound_rematch_count);
                if (matchsound_rematch[prnd] != "")
                {
                    sound (world, CHAN_AUTO, matchsound_rematch[prnd], 1, ATTN_NONE);
                    return;
                }
            }
        }
        else
        {
            if (clanring_matchsound_count)
            {
                prnd = floor(random() * clanring_matchsound_count);
                if (matchsound[prnd] != "")
                {
                    sound (world, CHAN_AUTO, matchsound[prnd], 1, ATTN_NONE);
                    return;
                }
            }
        }
    }
    sound (world, CHAN_AUTO, "ra/gong.wav", 1 , ATTN_NONE);
};

//
//  E N D
//
//  Called to end the match when the timer runs out or an administrator
//  aborts the match.
//
void() match_end =
{
    if (self.classname == "clanring_match_timer")
    {
        // Regular match end (timer ran out)
        if ((clanring_first_place.frags == clanring_second_place.frags) && clanring_overtime)
        {
            clanring_timelimit = clanring_overtime;//R00k OT bug fix
            timelimit = (clanring_timelimit * 60);//fixme??
            // go into overtime
            self.lip = clanring_timelimit;
            self.count = 0;
            match_show_timelimit();

            if (clanring_overtime > 0)
            {
                local string temp;
                announce("Match tied - Overtime!!");

                temp = ftos(clanring_overtime);
                announce2(temp, " minutes remaining");

                self.think = match_timer_think2;
                self.nextthink = time + 1;
                match_timer_think2();
            }
            else
            {
                announce("Match tied - Sudden Death Overtime!!");
            }
            return;
        }
    }
    else
    {
        // Administrator aborted the match
        if (!(clanring_state & CLANRING_MATCH_STARTED))
        {
            sprint(self, "No match in progress\n");
            return;
        }
        clanring_match_aborted = TRUE;
        match_unpause();
        clanring_numteams = 0;
    }
    clanring_state = clanring_state - (clanring_state & CLANRING_MATCH_STARTED);
    clanring_state = clanring_state - (clanring_state & CLANRING_TIMER_STARTED);
    clanring_state = ((clanring_state | CLANRING_MATCH_OVER) | CLANRING_MATCH_WAIT);
    utils_do_players(match_gib_player);
    match_show_timelimit();
    match_bprint_score();

    if (clanring_first_place.frags == clanring_second_place.frags)
        announce("Tie game!");
    else
    {
        announce3(clanring_szthe, clanring_first_place.netname, " has won");

        //play post-match sound sometimes
        match_postgame_sound((clanring_first_place.frags - clanring_second_place.frags));
    }

    local string record_time, team_letter;
    
    if (new_player_record_match == 1)
    {
        bprint("\n\bNew 1st place match captime record was set!\b\n");
        if (playerrecord2[0].statvalue > 0)
        {
            record_time = utils_get_time(playerrecord2[0].statvalue);
            team_letter = get_team_letter(playerrecord2[0].teamcolor);
            bprint4(playerrecord2[0].player, " - ", record_time, " ");
            bprint2(team_letter, "\n");
        }
        sound(world, CHAN_AUTO, "crx/congrats.wav", 1, ATTN_NONE);
    }
    else if (new_player_record_match == 2)
    {
        bprint("\n\bNew 2nd place match captime!\b\n");
        if (playerrecord2[1].statvalue > 0)
        {
            record_time = utils_get_time(playerrecord2[1].statvalue);
            team_letter = get_team_letter(playerrecord2[1].teamcolor);
            bprint4(playerrecord2[1].player, " - ", record_time, " ");
            bprint2(team_letter, "\n");
        }
        sound(world, CHAN_AUTO, "crx/goodstat.wav", 1, ATTN_NONE);
    }
    else if (new_player_record_match == 3)
    {
        bprint("\n\bNew 3rd place match captime!\b\n");
        if (playerrecord2[2].statvalue > 0)
        {
            record_time = utils_get_time(playerrecord2[2].statvalue);
            team_letter = get_team_letter(playerrecord2[2].teamcolor);
            bprint4(playerrecord2[2].player, " - ", record_time, " ");
            bprint2(team_letter, "\n");
    }
        sound(world, CHAN_AUTO, "crx/goodstat.wav", 1, ATTN_NONE);
    }

    console_show_score();
    clanring_match_timer.think = match_check_autoss;
    clanring_match_timer.nextthink = time + 3;
    clanring_numteams = 0;
    clanring_sentinel.movetarget = world;

    // Dump statistics for anyone who has autostats set
    utils_do_players(stats_autodump);
    console_autodump();//fixme
    announce("The match is over");//used for cl_autodemo 2, stop the demo after stats_autodump.
    // Backup all statistics so that they don't go away
    //stats_copy_statistics();
    match_bprint_score();//R00k adding here again, this will be closest to their cursor so it will be the first thing they want to read.
    if (!match_aborted_too_early())
        match_log_score();   // persist a compact summary for /lastscores
    utils_do_match_spawns(spawns_restore_model);
    utils_do_items(SUB_regen);// respawn all items (R00k:9/1/2024)

    // Start weapon animations again if in match mode and weaponstay is off
    if ((clanring_playmode & CLANRING_MATCH_MODE) && deathmatch < 3)
    {
        utils_do_weapons(weapon_prewar_setup);
    }

};

//
//  T I M E R  T H I N K 2
//
//  Match timer think function.
//
//  self.count gives the number of seconds remaining in the match.
//
void() match_timer_think2 =
{
    local string temp;

    if (!(clanring_state & CLANRING_MATCH_PAUSED))
        pqc_match_time(self.lip, self.count);

    self.count -= 1;

    if (self.count < 0)
    {
        self.count = 59;
        self.lip -= 1;
    }

    self.nextthink = time + 1;

    // control stats
    if (clanring_sentinel.movetarget)
        clanring_sentinel.movetarget.mangle_x += 1;

    clanring_sentinel.cnt += 1;

    if (self.lip)
    {
        if (self.count)
            return;

        if (self.lip > 1)
        {
//			temp = ftos(self.lip);
            match_show_timelimit();
//			announce3("Match ends in ", temp, " minutes");
            if (self.lip == 5 * floor(self.lip / 5))
                match_bprint_score();
        }
        else
        {
            match_show_timelimit();
            announce("Match ends in 1 minute");
            match_bprint_score();
        }
    }
    else
    {
        if (self.count == 30)
        {
            announce("Match ends in 30 seconds");
            if (clanring_overtime > 0)
            {
                temp = ftos(clanring_overtime);
                announce2(temp, " minute overtime in case of tie");
            }
            else if (clanring_overtime < 0)
                announce("Sudden death overtime in case of tie");
        }
        else
        {
            if (self.count <= 10)
            {
                local string plural;
                if (self.count == 10)
                    announce("Match ends in T minus");
                temp = ftos(self.count);
                plural = strings_szplural(self.count);
                announce4("  ", temp, " second", plural);
                if (self.count == 1)
                    self.think = match_end;
            }
        }
    }
};

//
//  A D D  S P A W N
//
//  Turn this extra start point into a spawn point for the match start
//
void() match_add_spawn =
{
    self.mdl = "clanring_start_point";
    self.classname = "info_player_deathmatch";
};

//
//  R E M O V E  S T A R T
//
//  Turn this extra start point back into a start point 2 seconds into
//  the match.
//
void() match_remove_start =
{
    if (self.mdl == "clanring_start_point")
        self.classname = self.mdl;
};

//
//  R E M O V E  S T A R T S
//
//  2 seconds into the match all spawn points revert to start points.
//
void() match_remove_starts =
{
    utils_do_item(match_remove_start, "info_player_deathmatch");
    dm_num_spawns = dm_num_spawns - clanring_num_starts;
    remove(self);
};

//
//  C O U N T  P L A Y E R S
//
float () match_count_players =
{
    local entity pteam;
    local float numplayers;

    if (!teamplay)
        return clanring_numteams;

    numplayers = 0;
    pteam = clanring_sentinel.next_team;
    while (pteam)
    {
        numplayers = numplayers + pteam.count;
        pteam = pteam.next_team;
    }
    return numplayers;
};

//
//  G E T  M A X S I Z E
//
float () match_get_maxsize =
{
    local entity pteam;

    if (!teamplay)
        return clanring_numteams;

    clanring_maxsize = 0;
    pteam = clanring_sentinel.next_team;
    while (pteam)
    {
        clanring_maxsize = utils_max(clanring_maxsize, pteam.count);
        pteam = pteam.next_team;
    }
    return clanring_maxsize;
};

// Returns TRUE when any teams have different counts (match-mode imbalance)
float() match_is_imbalanced =
{
    local entity pteam;
    local float found, baseline;

    if (!teamplay)
        return FALSE;

    pteam = clanring_sentinel.next_team;
    while (pteam)
    {
        if (pteam.count > 0)
        {
            if (!found)
            {
                found = TRUE;
                baseline = pteam.count;
            }
            else if (pteam.count != baseline)
                return TRUE;
        }
        pteam = pteam.next_team;
    }

    return FALSE;
};

//
//  R E S E T  O W N E R
//
void() match_reset_owner =
{
    self.owner = world;
};

//
// S P A W N S  R E M O V E  M O D E L
//
void() spawns_remove_model =
{
    self.model = string_null;
    self.modelindex = 0;
}

void() spawns_restore_model =
{
    setmodel (self, self.mdl);
    setsize(self,'-16 -16 -24','16 16 24'); // Must call setsize after setmodel
};

void() match_updatestat_matchstarttime =
{//R00k: support for QW clients
    WriteByte(MSG_MULTICAST, SVC_UPDATESTAT);
    WriteByte(MSG_MULTICAST, 18);// STAT_MATCHSTARTTIME
    WriteLong(MSG_MULTICAST,(time * 1000));
    multicast('0 0 0', MULTICAST_ONE_R);
}

//
//  B E G I N
//
//  Gib all players and start the match.
//
void() match_begin =
{
    local string temp;

    clanring_state = clanring_state - (clanring_state & CLANRING_NULL_FLAG);

    // Remove the spawnpoints' visible models
    utils_do_match_spawns(spawns_remove_model);

    find_pqc_teamscore_teams();// R00k: make sure everyone has the teamscores teams.
    
    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
    {
        TeamCaptureRegenFlags ();// respawn flags just to make sure
        new_player_record_match = 0;
    }

    if (clanring_request != world)	//Remove any active requests
        Request_Poll_Cleanup();

    clanring_state = clanring_state | CLANRING_MATCH_STARTED;

    // Clear leave-me-alone flags for all players
    utils_do_players(match_clear_leavemealone);

    // Stop weapon animations now that match has started
    utils_do_weapons(weapon_prewar_cleanup);

    announce("The match has begun!");//Moved up here for autodemo
    utils_do_players(match_gib_player);//r00k after additional spawns...

    clanring_new_record_player = "";	// .netname of the person who set the current top record.(only used in stats output)
    utils_do_projectiles(SUB_Remove);

    utils_do_item(SUB_Remove, "item_backpack");
    utils_do_arena_players(arena_fight_and_shoot);
    
    // Set the team size so that unwanted A-holes can't join in
    match_get_maxsize();
    //temp = ftos(clanring_maxsize);
    //if (teamplay)
    //announce4("Match is ", temp, "v", temp);
    temp = ftos(clanring_timelimit);
    announce2(temp, " minutes remaining");
    forceinfokey(world, "matchtime", ftos(clanring_timelimit));//R00k: requested by Woods.
    stats_matchtype = clanring_maxsize;	//3/6/2017 6:14AM added for stats header output, this will be incorrect if the game is unlocked.(fixme)
    stats_timelimit = clanring_timelimit;

    self.think = match_timer_think2;
    self.nextthink = time + 1;
    self.lip = clanring_timelimit;
    self.count = 0;

    match_updatestat_matchstarttime();//R00k: send the match time to QW players.
    pqc_match_time(clanring_timelimit, 0);//show the match timelimit (this is displayed right at the end of clanring_show_rules_prematch, when the timer shows 00:01)
    match_show_timelimit();//This updates the server's TIMELIMIT cvar with match information that is used on the CCREQ_RULE_INFO for the web server browser.

    // reset rocket launcher count
    clanring_sentinel.ammo_rockets = 0;
    clanring_sentinel.cnt = 0;

    // reset quad, pent counts
    utils_do_item(match_reset_owner, "item_artifact_invulnerability");
    utils_do_item(match_reset_owner, "item_artifact_super_damage");
    // Reset per-player quad control announcement flag and cached spawner count
    local entity pl;
    g_quad_spawner_count = 0;
    pl = find(world, classname, "player");
    while (pl)
    {
        pl.quad_majority_announced = 0;
        pl = find(pl, classname, "player");
    }

    // Temporarily turn the extra start points into spawn points if necessary
    if (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))
    {
        if (match_count_players() > dm_num_spawns)
        {
            utils_do_item(match_add_spawn, "clanring_start_point");
            dm_num_spawns = dm_num_spawns + clanring_num_starts;
            utils_make_scheduled_event(match_remove_starts, 2);
        }
    }
    // Initialize the score module
    score_init();
//	stats_delete_copies();//(todo)
    match_update_score_info(); //R00k: OCT'24
};

//
//  B P R I N T  T I M E L I M I T
//
//  Print out the timelimit in bronze and gold
//
void() match_bprint_timelimit =
{
    local string digit;
    local float temp;

    bprint("\bTimelimit is\b ");
    temp = floor(clanring_timelimit / 10);
    if (temp)
    {
        digit = strings_ftos_gold(temp);
        bprint(digit);
    }
    temp = clanring_timelimit - 10 * temp;
    digit = strings_ftos_gold(temp);
    bprint2(digit, "\n");
};

//
//  R E S E T  P O W E R U P
//
void () match_reset_powerup = 
{
    self.count = self.cnt = 0;		
    self.owner = world;				
    self.height = 0;				
};

//
//  T I M E R  T H I N K 1
//
//  Pre-match timer think function.
//
//  self.count gives the number of seconds until the match begins.
//
void() match_timer_think1 =
{
    //local string temp;

   pqc_match_time (0, self.count-1);

    self.count -= 1;
    if (self.count < 0)
    {
        self.count = 59;
        self.lip -= 1;
    }
    self.nextthink = time + 1;

    if (self.count == self.dest_x)
    {
        if (self.count != 5)
        {
            match_bprint_timelimit();
            bprint("Use '\btimeset\b' to change timelimit\n");
        }

        // respawn all items; reset information
        utils_do_items(SUB_regen);
        utils_do_item(match_reset_powerup, "item_artifact_invulnerability");
        utils_do_item(match_reset_powerup, "item_artifact_super_damage");

        // Setup weapon animations if weaponstay is off
        utils_do_weapons(weapon_prewar_setup);

        //announce("All items have respawned");

        if (clanring_playmode & CLANRING_NO_QUAD)
        {
            utils_do_item(votables_disable_item, "item_artifact_super_damage");
        }
        if (clanring_playmode & CLANRING_NO_PENT)
        {
            utils_do_item(votables_disable_item, "item_artifact_invulnerability");
        }
        if (clanring_playmode & CLANRING_NO_RING)
        {
            utils_do_item(votables_disable_item, "item_artifact_invisibility");
        }
        if (self.count == 30)
            announce("Match begins in 30 seconds");
    }
    else
    {
        if (self.count == self.dest_y)
        {
            match_get_maxsize();
            //temp = ftos(clanring_maxsize);
            //if (teamplay)
                //announce4("Match is currently ", temp, "v", temp);
            if (self.count == 20)
                announce("Match begins in 20 seconds");
        }
        else
        {
            if (self.count <= 10)
            {
                if (self.count <= 3)
                    sound (world, CHAN_AUTO, "buttons/switch04.wav", 1, ATTN_NONE);

                if (self.count == 1)
                {
                    self.think = match_begin;
                }
                else
                {
                    if (self.count == 10)
                    {
                        //announce("Match begins in T minus");
                        sound (world, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NONE);
                        quaketag_clear();
                        if (clanring_playmode & CLANRING_RUNES)
                        {
                            utils_do_item(SUB_Remove, "item_rune");
                            StartRuneSpawn();// Spawn runes now so they have a chance to migrate away from the spawnpoint.
                        }
                    }
                    else if (self.count == 9)
                    {
                        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
                            TeamCaptureRegenFlags();// respawn flags

                        clanring_state = clanring_state | CLANRING_NULL_FLAG;
                    }
                }
            }
        }
    }
};

//
//  D E L E T E  T E A M S
//
void() match_delete_teams =
{
    local entity pteam;

    if (teamplay)
    {
        while (clanring_sentinel.next_team)
        {
            pteam = clanring_sentinel.next_team;
            clanring_sentinel.next_team = pteam.next_team;
            pqc_erase_team(pteam.height);
            remove(pteam);
        }
    }
    clanring_numteams = 0;
    clanring_sentinel.next_team = world;
    clanring_sentinel.next_player = world;
};

//
//  P U T  P L A Y E R  I N  T E A M
//
//  Try to put a player into the team that he has chosen.  Called
//  when a player enters 'ready' in the console.  Returns TRUE if
//  successful, FALSE otherwise.
//
float () match_put_player_in_team =
{
    local entity pteam;
    local string temp;

    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
    {
        if ((self.team != RED) && (self.team != BLUE))
        {
            if (!(clanring_state & CLANRING_MATCH_STARTED))
            {
                sprint(self, "Invalid pants color\n");
                sprint(self, "type \bRED\b or \bBLUE\b to join match\n");
            }
            else 
                sprint(self,"A match is already playing; you may not join at this time.\n");
            return FALSE;
        }
    }
    else
    {
        if (self.team <= 1)
        {
            sprint(self, "Invalid pants color\n");	
            return FALSE;
        }
    }
    
    if (clanring_state & CLANRING_MATCH_OVER)
    {
        clanring_state = clanring_state - (clanring_state & CLANRING_MATCH_OVER);
        match_delete_teams();
        match_update_score_info();
        // Now that MATCH_OVER is cleared, reset HUD teamscores
        pqc_match_reset();
    }

    self.height = self.team - 1;

// Individual mode 		(R00k: removed)

    // find the team
    pteam = clanring_sentinel.next_team;
    
    while (pteam)
    {
        if (pteam.height == self.height)
        {
            // can we add to the team?
            if (clanring_state & CLANRING_MATCH_STARTED)
            {
                if (clanring_maxsize != 16) // if locked
                    match_get_maxsize();    // update to current max size

                if (pteam.count == clanring_maxsize)
                {
                    sprint(self, "Team full.  A player must enter\n");
                    sprint(self, "'unlock' in console to let you join\n");
                    return FALSE;
                }
            }

            // add to the team
            pteam.count = pteam.count + 1;
            
            if (pteam.count > 1)
            {
                self.next_player = pteam.next_player.next_player;
                pteam.next_player.next_player = self;
            }
            else
            {
                self.next_player = clanring_sentinel.next_player;
                clanring_sentinel.next_player = self;
                pteam.next_player = self;
            }

            self.next_team = pteam;

            announce3(self.netname, " has joined the ", pteam.netname);

            if (clanring_numteams == 1)
                announce("Only one team present");
            
            if ((self.height + 1) == RED)
            {
                self.style = (self.style | CLANRING_RED_TEAM);
                if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
                    self.skin = 1;
            }
            else
            {
                if ((self.height + 1) == BLUE)
                {
                    self.style = (self.style | CLANRING_BLUE_TEAM);
                    if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
                         self.skin = 3;
                }
            }
            return TRUE;
        }
        pteam = pteam.next_team;
    }
    
    // can we create a team?
    if (clanring_numteams >= clanring_maxteams)
    {
        temp = ftos(clanring_maxteams);
        sprint3(self, "There are already ", temp, " teams:\n");
        pteam = clanring_sentinel.next_team;
        while (pteam)
        {
            temp = ftos(pteam.height);
            sprint4(self, pteam.netname, " (color ", temp, ")\n");
            pteam = pteam.next_team;
        }
        return FALSE;
    }
    
    // create the team
    pteam 							= spawn();
    pteam.classname 				= "clanring_team";
    pteam.next_team 				= clanring_sentinel.next_team;
    clanring_sentinel.next_team 	= pteam;
    self.next_player 				= clanring_sentinel.next_player;
    pteam.next_player 				= self;
    clanring_sentinel.next_player 	= self;
    self.next_team 					= pteam;
    pteam.count 					= 1; 
    pteam.height 					= self.height;
    
    setcolour(self, pteam.height, pteam.height);    // disallow colors 14/15

    //refresh skins
    if ((self.height + 1) == RED)
    {		
        self.style 	= (self.style | CLANRING_RED_TEAM);
        if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
            self.skin = 1;
    }
    else
    {
        if ((self.height + 1) == BLUE)
        {
            self.style 	= (self.style | CLANRING_BLUE_TEAM);
            if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)
                 self.skin = 3;
        }
    }
    
    pteam.frags 		= 0;
    pteam.netname 		= strings_get_teamname(pteam.height);
    pteam.mdl 			= strings_get_teamname_bronze(pteam.height);
    pteam.ammo_rockets 	= 0;
    clanring_numteams 	= clanring_numteams + 1;
    
    stats_reset_team(pteam);

    announce2(pteam.netname, " created");
    announce3(self.netname, " has joined the ", pteam.netname);

    pqc_new_team(pteam.height);

     if (clanring_numteams == 1)
        announce("Only one team present");

    return TRUE;
};

//
//  A L L  R E A D Y
//
//  Returns TRUE if all non-observers are ready, FALSE otherwise.
//
float () match_all_ready =
{
    local entity player;

    player = find(world, classname, "player");
    while (player)
    {        
        if (!(player.style & CLANRING_OBSERVER))
        if (player.next_team != world) // if they're on a team and afk
        {
            if (player.style & CLANRING_AFK_CLIENT) 
            {
                bprint (sprintf("\n%s is currently AFK!\n\nMatch Start delayed...\n",player.netname));
                return FALSE;
            }

            if (!(player.style & CLANRING_READY))
                return FALSE;
        }
        player = find(player, classname, "player");
    }
    return TRUE;
};

//
//  S T A R T  T I M E R
//
//  Starts the timer.
//
void() match_start_timer =
{
    if (clanring_state & CLANRING_TIMER_STARTED)
        return;

    clanring_match_aborted = FALSE;

    clanring_match_timer = spawn();
    clanring_match_timer.classname = "clanring_match_timer";
    clanring_match_timer.think = match_timer_think1;
    clanring_match_timer.nextthink = time + 1;

    clanring_state = clanring_state | CLANRING_TIMER_STARTED;
    match_show_timelimit();

    // Let's GO!!!
    // if (clanring_playmode & CLANRING_FAST_START)
    // {
        clanring_match_timer.dest 	= '5 11 0';
        clanring_match_timer.count 	= 12;
    // }
    // else
    // {
    // 	clanring_match_timer.dest 	= '55 20 0';
    // 	clanring_match_timer.count 	= 59;
    // 	announce("Match begins in 1 minute");
    // }
};

//
//  F I N D  G H O S T
//
//  Finds a ghost from a ghost code; returns world if the ghost doesn't
//  exist.
//
entity (float code) match_find_ghost =
{
    local entity e;

    e = find(world, classname, "clanring_ghost");
    while ((e != world) && (e.count != code))
        e = find(e, classname, "clanring_ghost");
    return e;
};

//
//  S E N D  G H O S T  A L I A S E S
//
//  Send the ghost aliases, e.g.
//
//  alias ghostcode echo Your ghostcode is 29
//  alias ghost "impulse 127;w5;impulse 232;w5;impulse 239"
//
void () match_send_ghost_aliases = 
{
    local string temp;
    local float digit;
    temp = ftos(self.owner.count);
    stuffcmd(self, "alias ghostcode echo Your ghost code is ");
    stuffcmd(self, temp);
    stuffcmd(self, "\n");
    stuffcmd(self, "alias ghost \"impulse 127;w5;impulse ");
    digit = floor(self.owner.count / 10);
    temp = ftos(digit + 230);
    stuffcmd(self, temp);
    stuffcmd(self, ";w5;impulse ");
    digit = self.owner.count - 10 * digit;
    temp = ftos(digit + 230);
    stuffcmd(self, temp);
    stuffcmd(self, "\n");
};

//
//  M A K E  G H O S T
//
//  Create a ghost for the player (if does not already have one)
//  and tell him what his ghost code is.
//
void () match_make_ghost =
{
    // can't have two ghosts
    if (self.owner)
        remove(self.owner);

    // create ghost code
    local float ghostcode;
    ghostcode = 10 + floor(89.99 * random());
    while (match_find_ghost(ghostcode))
        ghostcode = 10 + floor(89.99 * random());

    // initialize ghost
    self.owner = spawn();
    self.owner.classname = "clanring_ghost";
    self.owner.owner = self;
    self.owner.frags = 0;
    self.owner.height = self.height;
    self.owner.count = ghostcode;
    self.owner.state = 0;
    self.owner.statstate = self.statstate;
    self.owner.mangle = self.mangle;	// killstats
    self.owner.movetype = MOVETYPE_NONE;
    self.owner.finaldest_y = MOVETYPE_NONE;
    match_send_ghost_aliases ();
    stuffcmd(self, "ghostcode\n");
};

//
//  R E Q U E S T  R E S T O R E  G H O S T
//
//  Request to be restored from a ghost.  The player is prompted
//  to enter his three digit ghost code.
//
void () match_request_restore_ghost =
{
    if (!(clanring_state & CLANRING_MATCH_STARTED))
    {
        sprint(self, "There is no match in progress\n");
        return;
    }

    // only uncomitted players can ghost themselves
    if (self.style & CLANRING_READY)
    {
        sprint(self, "You are already in the match\n");
        return;
    }

    sprint(self, "Enter the first ghost code digit:\n");
    self.count = 0;
    self.use = match_enter_ghost_code;
};

//
//  E N T E R  G H O S T  C O D E
//
//  Enter another ghost code digit.  The digit is stored in
//  self.finaldest_z.
//
void () match_enter_ghost_code =
{
    if (self.finaldest_z > 9)
        return;
    self.count = self.count * 10 + self.finaldest_z;
    if (!self.count)
        return;

    if (self.count < 10)
        sprint(self, "Enter the second ghost code digit:\n");
    else
    {
        // ghost code has been entered
        local entity e;

        e = match_find_ghost(self.count);
        if (!e)
            sprint(self, "Ghost not found\n");
        else
        {
            // Check to make sure the client is gone
            if (e.owner.owner == e)
                sprint2(self, e.owner.netname, " owns this ghost\n");
            else
                match_restore_ghost(e);
        }
        self.use = SUB_Null;
    }
};

//
//  R E S T O R E  G H O S T
//
//  Restore a player from their ghost after they've entered their
//  ghost code.  Note that the only way for this function to be
//  called is if there is a match in progress and the player entering
//  the ghostcode is an uncommitted observer.
//
void(entity ghostent) match_restore_ghost =
{
    local string temp;
    local string plural;

    local float col = bound(0, ghostent.height, 13);
    local entity pteam;

    self.team = col + 1;
    self.style = self.style | ghostent.style | CLANRING_READY;
    
    temp = ftos(col);
    stuffcmd(self, "color ");
    stuffcmd(self, temp);
    stuffcmd(self, "\n");
    
    if (!match_put_player_in_team())    // self.height is set in here
    {
        stuffcmd(self, "color 0\n");
        clear_name();
        return;
    }

    // Must ready before observer_end, or will be made observer again
    // Must observer_end before setting frags, or frags will be set to 0
    observer_end();

    // Force server-side colours immediately (shirt & pants)
    setcolour(self, col, col);
    self.height = col;  // keep server bookkeeping consistent

    // copy always data
    self.frags = ghostent.frags;
    self.dest = ghostent.dest;
    self.dest1 = ghostent.dest1;
    self.dest2 = ghostent.dest2;
    self.mangle = ghostent.mangle;
    self.statstate = ghostent.statstate;
    self.clanring_badstats = ghostent.clanring_badstats;
    self.clanring_qdwep	= ghostent.clanring_qdwep;
    self.clanring_qdkill = ghostent.clanring_qdkill;
    self.clanring_ptwep = ghostent.clanring_ptwep;
    self.clanring_ptkill = ghostent.clanring_ptkill;
    self.clanring_hack_count = ghostent.clanring_hack_count;	// clanring
    self.true_kills = ghostent.true_kills;
    self.pos1_x	= ghostent.pos1_x;
    self.pos1_y	= ghostent.pos1_y;
    self.pos1_z	= ghostent.pos1_z;
    self.pos2_y	= ghostent.pos2_y;
    self.pos2_z	= ghostent.pos2_z;
    self.captime = ghostent.captime;
    self.dmg_taken = ghostent.dmg_taken;
    self.dmg_given = ghostent.dmg_given;
    self.ewep = ghostent.ewep;
    self.fpickups = ghostent.fpickups;
    self.fcaptures = ghostent.fcaptures;
    self.fdefenses = ghostent.fdefenses;
    self.freturns = ghostent.freturns;
    self.fcassists = ghostent.fcassists;
    self.fcfrags = ghostent.fcfrags;
    self.captime = ghostent.captime;
    
    self.killed = ghostent.killed;

    // check for copy-on-pause data
    if (ghostent.state)
    {
        setorigin(self, ghostent.origin);
        self.frame = ghostent.frame;
        self.effects = self.effects | ghostent.effects;
        self.angles = ghostent.angles;
        self.waterlevel = ghostent.waterlevel;
        self.watertype = ghostent.watertype;
        self.clanring_old_velocity = ghostent.clanring_old_velocity;
        self.punchangle = ghostent.punchangle;
        self.nextthink = ghostent.nextthink - 1000000;
        self.think = ghostent.think;
        self.health = ghostent.health;
        self.items = (self.items | ghostent.items);
        if (self.items & IT_QUAD)
            sprint(self, "You regained your Quad\n");
        self.armortype = ghostent.armortype;
        self.armorvalue = ghostent.armorvalue;
        self.weapon = ghostent.weapon;
        self.weaponmodel = ghostent.weaponmodel;
        self.weaponframe = ghostent.weaponframe;
        self.currentammo = ghostent.currentammo;
        self.ammo_shells = ghostent.ammo_shells;
        self.ammo_nails = ghostent.ammo_nails;
        self.ammo_rockets = ghostent.ammo_rockets;
        self.ammo_cells = ghostent.ammo_cells;
        self.flags = self.flags | ghostent.flags;
        self.walkframe = ghostent.walkframe;
        self.attack_finished = ghostent.attack_finished;
        self.pain_finished = ghostent.pain_finished;
        self.air_finished = ghostent.air_finished;
        self.invincible_time = ghostent.invincible_time;
        self.invincible_finished = ghostent.invincible_time;
        self.invisible_time = ghostent.invisible_time;
        self.invisible_finished = ghostent.invisible_time;
        self.super_time = ghostent.super_time;
        self.super_damage_finished = ghostent.super_time;
        self.rad_time = ghostent.rad_time;
        self.radsuit_finished = ghostent.rad_time;
        self.show_hostile = ghostent.show_hostile;
        self.jump_flag = ghostent.jump_flag;
        self.swim_flag = ghostent.swim_flag;
        self.bubble_count = ghostent.bubble_count;
        self.fixangle = 1;
        self.movetype = MOVETYPE_FLY;
        self.finaldest_y = MOVETYPE_FLY;
        self.view_ofs = '0 0 22';//r00k: testing... sometimes view is tilted on restore.

        // check eyes
        if (self.invisible_finished)
            self.modelindex = modelindex_eyes;

        // check mega healths
        local entity mh;
        mh = find(world, classname, "item_health");
        while (mh)
        {
            if ((mh.healtype == 2) && (mh.owner == ghostent))
                mh.owner = self;
            mh = find(mh, classname, "item_health");
        }
        // check rocket launcher
        if (self.items & IT_ROCKET_LAUNCHER)
            quaketv_obtained_rl(self);
        ghostent.state = 0;
    }
    self.owner = ghostent;
    ghostent.owner = self;
    temp = ftos(self.height);
    stuffcmd(self, "color ");
    stuffcmd(self, temp);
    stuffcmd(self, "\n");
    match_send_ghost_aliases();
    temp = ftos(self.frags);
    plural = strings_szplural(self.frags);
    announce5(self.netname, " restored from ghost with ", temp, " frag", plural);
    // check to see if they're top 2
    if (!teamplay)//remove 'cause indv mode no longer exists?
    {
        if (self.frags > clanring_first_place.frags)
        {
            clanring_second_place = clanring_first_place;
            clanring_first_place = self;
        }
        else
        {
            if (self.frags > clanring_second_place.frags)
                clanring_second_place = self;
        }
    }

    self.style = self.style - (self.style & CLANRING_OBSERVER);//R00k bugfix

    if ((clanring_request != world) || (!(clanring_state & CLANRING_MATCH_PAUSED)) || (clanring_state & CLANRING_UNPAUSING) || (!teamplay))
        return;

    pteam = clanring_sentinel.next_team;
    while (pteam)
    {
        if (pteam.count != self.next_team.count)
            return;

        pteam = pteam.next_team;
    }

    if (vote_init("\bunpause the match\b", "", match_start_unpause_countdown))
        vote_yes();
};

void() match_no_ring_check = 
{
    // Honor forced ring state from config
    if (clanring_force_ring == 1)
    {
        if (clanring_playmode & CLANRING_NO_RING)
        {
            utils_do_item(SUB_regen, "item_artifact_invisibility");
            announce("Ring of shadows enabled (forced)");
            clanring_playmode = clanring_playmode - CLANRING_NO_RING;
            utils_set_cvar("samelevel", clanring_playmode);
        }
        return;
    }
    if (clanring_force_ring == -1)
    {
        if (!(clanring_playmode & CLANRING_NO_RING))
        {
            utils_do_item(votables_disable_item, "item_artifact_invisibility");
            announce("Ring of shadows disabled (forced)");
            clanring_playmode = clanring_playmode | CLANRING_NO_RING;
            utils_set_cvar("samelevel", clanring_playmode);
        }
        return;
    }

    if (clanring_maxsize < 3) // if less than 3 members per team...
    {
        if (!(clanring_playmode & CLANRING_NO_RING)) // If ring is on...	disable now.
        {
            utils_do_item(votables_disable_item, "item_artifact_invisibility");
            announce("Ring of shadows disabled");
            clanring_playmode = clanring_playmode | CLANRING_NO_RING; // This change will not be perminent.
        }
    }
    else
    {
        if (clanring_playmode & CLANRING_NO_RING)	// Turn back on if it was voted or set in the config...
        {
            clanring_playmode = clanring_playmode  - CLANRING_NO_RING;
            clanring_playmode = clanring_playmode | (cvar("samelevel") & CLANRING_NO_RING);
            if (!(clanring_playmode & CLANRING_NO_RING))
                announce("Ring of shadows enabled");
        }
    }	
}

float request_timelimit;
//
//  R E A D Y
//
//  Called when a player enters 'ready' in the console.
//
void() match_ready =
{
    if (clanring_state & CLANRING_MATCH_WAIT)
    {
        sprint(self, "Try again in 5 seconds\n");
        return;
    }
    if (self.style & CLANRING_READY)
    {
        sprint(self, "You are already committed\n");
        return;
    }

    // can't commit while entering ghost code
    if (self.use == match_enter_ghost_code)
    {
        sprint(self, "Finish entering the ghost code\n");
        return;
    }

    // Try to add the player; colour him white if unsuccessful
    if (!match_put_player_in_team())
    {
        stuffcmd(self, "color 0\n");
        clear_name();
        return;
    }

    if (!(clanring_state & CLANRING_MATCH_STARTED))
    {
        TeamCaptureDropFlagOfPlayer(self, 1);
    }

    self.style = self.style | CLANRING_READY;
    
    if (!(clanring_state & CLANRING_MATCH_STARTED))
    {
        match_get_maxsize();
        // If a map cfg forced a timelimit, keep it; else apply auto based on team size
        if (!clanring_force_timelimit)
        {
            if (clanring_timelimit != request_timelimit)
            {
                clanring_timelimit = (clanring_maxsize > 2) ? 20 : 10;
                forceinfokey(world, "matchtime", ftos(clanring_timelimit));
                match_show_timelimit();
            }
        }
        match_no_ring_check();												// R00k: disable invisibility for smaller games automatically.

        // Start weapon animations when in prewar with weaponstay off
        if (!(clanring_state & CLANRING_TIMER_STARTED) && deathmatch < 3)
        {
            utils_do_weapons(weapon_prewar_setup);
        }

    }
    
    // check to see if we need to start the timer
    if (clanring_numteams > 1 && !(clanring_state & CLANRING_TIMER_STARTED) && match_all_ready())
    {
        match_start_timer ();
    }
    // Give the player a ghost
    match_make_ghost ();

    self.oflags = self.oflags - (self.oflags & OBSERVER_QUAKETV);	//Sputnik
    observer_end ();
    ready_name();
};

//
//  R E M O V E  P L A Y E R
//
void(entity player) match_remove_player =
{
    local entity plast;
    local string teamname;
    local entity pteam;
    local float player_still_on_team;

    if (player.next_team == world)
        return;

    teamname = player.next_team.netname;

   // Check if player is becoming an observer or disconnecting
   if ((player.style & CLANRING_OBSERVER) || (player.team == 0))
   {
       // Player is becoming observer or disconnecting - print leaving message
       if (teamname == "")          // ---- player had no team ----
           announce2(player.netname, " left the game.");   // 2-piece print
       else                         // ---- normal team message ----
           announce4(player.netname, " left the ", teamname, ".");
   }
   else
   {
       // Check if player is still using a color that matches an active team
       player_still_on_team = FALSE;
       pteam = clanring_sentinel.next_team;
       while (pteam)
       {
           if (pteam.height == player.height)
           {
               player_still_on_team = TRUE;
               break;
           }
           pteam = pteam.next_team;
       }

       // Only print leaving message if player is not staying on a team
       if (!player_still_on_team)
       {
           if (teamname == "")          // ---- player had no team ----
               announce2(player.netname, " left the game.");   // 2-piece print
           else                         // ---- normal team message ----
               announce4(player.netname, " left the ", teamname, ".");
       }
   }

    // remove from team & linked list
    plast = clanring_sentinel;
    while (plast.next_player != player) // findprevious player in list
    {
        plast = plast.next_player;
        if (!plast)
            return;  // player isn't in the list
    }
    plast.next_player = player.next_player;  // fix list
    if (teamplay)
    {
        if (player.next_team.next_player == player)	// fix team player pointer if necessary
            player.next_team.next_player = player.next_player;

        if (player.next_team != world)
            player.next_team.count = player.next_team.count - 1;

        if ((player.items & IT_ROCKET_LAUNCHER) && (clanring_state & CLANRING_MATCH_STARTED) && (!(player.deadflag)))
            quaketv_lost_rl (player);
    }
    else
    {
        plast.next_team = player.next_team;
        clanring_numteams = clanring_numteams - 1;
    }

    if (!(clanring_state & CLANRING_MATCH_STARTED))
    {		
        match_get_maxsize();

        // If a map cfg forced a timelimit, keep it; else apply auto based on team size
        if (!clanring_force_timelimit)
        {
            if (clanring_timelimit != request_timelimit)
            {
                clanring_timelimit = (clanring_maxsize > 2) ? 20 : 10;
                match_show_timelimit();
            }
        }
        match_no_ring_check();										// R00k: disable invisibility for smaller games automatically.
    }
};

// ---------------------------------------------
//  S I L E N T   R E M O V E   (no announcements)
//  Unlinks a player from team/global lists without prints.
// ---------------------------------------------
void(entity player) match_remove_player_silent =
{
    local entity plast;
    if (player.next_team == world)
        return;

    // unlink from global player list
    plast = clanring_sentinel;
    while (plast.next_player != player)
    {
        plast = plast.next_player;
        if (!plast) return; // not found
    }
    plast.next_player = player.next_player;

    if (teamplay)
    {
        // fix team-first-player pointer if needed
        if (player.next_team.next_player == player)
            player.next_team.next_player = player.next_player;

        if (player.next_team != world)
            player.next_team.count = player.next_team.count - 1;
    }
    else
    {
        plast.next_team = player.next_team;
        clanring_numteams = clanring_numteams - 1;
    }

    player.next_player = world;
    player.next_team   = world;
};

// ---------------------------------------------
//  S I L E N T   A D D   (no announcements)
//  Re-links a player into the target team/global lists quietly.
//  Assumes match is NOT started (reshuffle is pre-match) and that
//  target team exists (created automatically if missing).
// ---------------------------------------------
void(entity player, float targetColor) match_add_player_silent =
{
    local entity pteam;

    // locate (or create) the team with this color
    pteam = clanring_sentinel.next_team;
    while (pteam)
    {
        if (pteam.height == targetColor) break;
        pteam = pteam.next_team;
    }
    if (!pteam)
    {
        // create minimal team silently (rare: if colors changed)
        pteam                      = spawn();
        pteam.classname            = "clanring_team";
        pteam.next_team            = clanring_sentinel.next_team;
        clanring_sentinel.next_team= pteam;
        pteam.count                = 0;
        pteam.height               = targetColor;
        pteam.frags                = 0;
        pteam.netname              = strings_get_teamname(pteam.height);
        pteam.mdl                  = strings_get_teamname_bronze(pteam.height);
        pteam.ammo_rockets         = 0;
        clanring_numteams          = clanring_numteams + 1;
        pqc_new_team(pteam.height);
        stats_reset_team(pteam);
    }

    // insert into global player list and team block
    if (pteam.count > 0)
    {
        // append directly after the team's head player so the team's block stays contiguous
        player.next_player             = pteam.next_player.next_player;
        pteam.next_player.next_player  = player;
    }
    else
    {
        // first player for this team: push to global head and mark team head
        player.next_player             = clanring_sentinel.next_player;
        clanring_sentinel.next_player  = player;
        pteam.next_player              = player;
    }

    // link back-pointers & counters
    player.next_team = pteam;
    pteam.count      = pteam.count + 1;

    // enforce colors/skins and style flags
    player.team   = targetColor + 1;
    player.height = targetColor;
    setcolour(player, targetColor, targetColor);
    if ((targetColor + 1) == RED)  { player.style = (player.style | CLANRING_RED_TEAM);  if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM) player.skin = 1; }
    if ((targetColor + 1) == BLUE) { player.style = (player.style | CLANRING_BLUE_TEAM); if (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM) player.skin = 3; }
};


//
//  R E M O V E  T E A M
//
void(entity pteam) match_remove_team =
{
    local entity plast;

    plast = clanring_sentinel;
    while (plast.next_team != pteam) // find previous team in list
        plast = plast.next_team;
    plast.next_team = pteam.next_team;  // fix list
    pqc_erase_team(pteam.height);
    remove(pteam);
    clanring_numteams = clanring_numteams - 1;
};

//
//  N O T  R E A D Y
//
//  Called when a player enters 'notready' in the console.
//
void() match_notready =
{
    if (clanring_state & CLANRING_MATCH_WAIT)
    {
        sprint(self, "Try again in 5 seconds\n");
        return;
    }
    if (!(self.style & CLANRING_READY))
    {
        sprint(self, "You have not yet committed\n");
        return;
    }
    if (clanring_state & CLANRING_MATCH_STARTED)
    {
        sprint(self, "Cannot uncommit during match\n");
        sprint(self, "Type 'observer' to leave match\n");
        return;
    }

    self.style = self.style - (self.style & CLANRING_READY);

    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
        TeamCaptureDropFlagOfPlayer (self, 1);
        
    clear_name();

    announce2(self.netname, " is not ready");
    
    // He was ready but the match hadn't started, so remove his ghost
    remove(self.owner);
    self.owner = world;
    
    stuffcmd(self, "alias ghostcode echo You do not have a ghost\n");
    stuffcmd(self, "alias ghost impulse 127\n");
    
    match_remove_player(self);
    
    if (teamplay && !self.next_team.count)
        match_remove_team(self.next_team);
    
    if (clanring_numteams == 1)
        announce3("Only one ", clanring_szteam, " present");
    else
    if (!clanring_numteams)
        announce3("No ", clanring_szteam, "s present");
    
    if (clanring_state & CLANRING_TIMER_STARTED)
    {
        announce("Timer stopped");
        remove(clanring_match_timer);
        pqc_match_time(0, 0);//fixed
        clanring_state = clanring_state - (clanring_state & CLANRING_TIMER_STARTED);
        clanring_state = clanring_state - (clanring_state & CLANRING_NULL_FLAG);
        match_show_timelimit();
    }

    // Stop weapon animations if not enough players/teams ready
    if (clanring_numteams < 2 && !(clanring_state & CLANRING_TIMER_STARTED))
    {
        utils_do_weapons(weapon_prewar_cleanup);
    }

};

//
//  U N L O C K
//
//  Allow new players to joing the match.
//
void() match_unlock =
{
    clanring_maxsize = 16;
    announce("Match has been unlocked");
    announce("New players may join at will");
};

//
//  R E Q U E S T  U N L O C K
//
//  Request to allow new players to join the match.
//
void() match_request_unlock =
{
    if (!(clanring_state & CLANRING_MATCH_STARTED))
    {
        sprint(self, "No match in progress\n");
        return;
    }
    if (clanring_maxsize == 16)
    {
        sprint(self, "Match is already unlocked\n");
        return;
    }

    // Admins unlock immediately
    if (self.style & CLANRING_ADMINISTRATOR)
    {
        match_unlock();
        return;
    }

    // Auto-approve unlock requests when teams are imbalanced
    if (teamplay && match_is_imbalanced())
    {
        if (self.style & CLANRING_READY)
        {
            announce("Teams imbalanced; unlocking match");
            match_unlock();
        }
        else
        {
            sprint(self, "unlock comand available to match\n");
            sprint(self, "participants and administrators only\n");
        }
        return;
    }

    // Otherwise, run the normal vote path
    if (self.style & CLANRING_READY)
    {
        if (vote_init("\ballow new players to join\b", "", match_unlock))
            vote_yes();
    }
    else
    {
        sprint(self, "unlock comand available to match\n");
        sprint(self, "participants and administrators only\n");
    }
};

//
//  L O C K
//
//  Re-cap the team size.
//
void() match_lock =
{
    local string s;

    match_get_maxsize();
    announce("Match has been locked");
    s = ftos(clanring_maxsize);
    if (teamplay)
        announce2("Max teamsize set to ", s);
    else
        announce2("Max number of players set to ", s);

    stats_matchtype = clanring_maxsize;//3/6/2017 6:16AM added for stats header output 
};

//
//  R E Q E S T  L O C K
//
//  Request to re-cap the team size.
//
void() match_request_lock =
{
    local float temp;

    if (!(clanring_state & CLANRING_MATCH_STARTED))
    {
        sprint(self, "No match in progress\n");
        return;
    }
    temp = clanring_maxsize;
    match_get_maxsize();
    if (clanring_maxsize == temp)
    {
        sprint(self, "Match is already locked\n");
        return;
    }
    clanring_maxsize = temp;

    // Do it right away if we're an administrator, otherwise vote
    if (self.style & CLANRING_ADMINISTRATOR)
        match_lock ();
    else
    {
        if (self.style & CLANRING_READY)
        {
            if (vote_init("\block the match\b", "", match_lock))
                vote_yes();
        }
        else
        {
            sprint(self, "lock comand available to match\n");
            sprint(self, "participants and administrators only\n");
        }
    }
};




// ---------------------------------------------
//  R P I C K U P   D E C K   H E L P E R S
// ---------------------------------------------
float(float n, float k) rs_choose =
{
    local float i, r, kk;
    if (k < 0 || k > n) return 0;
    kk = (k > (n - k)) ? (n - k) : k;
    r = 1;
    for (i = 1; i <= kk; i = i + 1)
    {
        // r *= (n - kk + i) / i;
        r = r * (n - kk + i) / i;
    }
    return r;
};

float() rs_multinomial_total =
{
    local float total, rem, t;
    total = 1;
    rem = rs_N;
    for (t = 0; t < rs_T; t = t + 1)
    {
        total = total * rs_choose(rem, rs_counts[t]);
        rem = rem - rs_counts[t];
    }
    return total;
};

// Count permutations of remaining multiset if we place label 'dec_idx' now.
// Uses rs_work_counts[] as the current remaining counts.
float(float remN, float dec_idx) rs_multinomial_with_dec_from_work =
{
    local float total, rem, t, c;
    if (remN <= 0) return 0;
    rem = remN - 1;
    total = 1;
    for (t = 0; t < rs_T; t = t + 1)
    {
        c = rs_work_counts[t];
        if (t == dec_idx) c = c - 1;
        if (c < 0) return 0;
        total = total * rs_choose(rem, c);
        rem = rem - c;
    }
    return total;
};

// ---------------------------------------------------------
// Enforce BALANCED team sizes for rpickup (2-team modes only)
// Even N  -> N/2 vs N/2
// Odd  N  -> ceil(N/2) vs floor(N/2)
// The +1 (when odd) goes to the team that currently has fewer
// committed players to avoid bias over repeated reshuffles.
// ---------------------------------------------------------
void() rs_enforce_balanced_counts =
{
    local float base, extra, a_old, b_old;

    // Only enforce for classic 2-team modes (CTF/DM, etc.)
    if (rs_T != 2) return;
    if (rs_N <= 1) return;

    // Keep prior counts to decide where the +1 should go if odd
    a_old = rs_counts[0];
    b_old = rs_counts[1];

    base  = floor(rs_N / 2);
    extra = rs_N - base * 2; // 0 or 1

    if (extra == 0)
    {
        rs_counts[0] = base;
        rs_counts[1] = base;
        return;
    }

    // extra == 1: give +1 to the team that currently has fewer players
    if (a_old < b_old)
    {
        rs_counts[0] = base + 1; rs_counts[1] = base;
    }
    else if (b_old < a_old)
    {
        rs_counts[0] = base;     rs_counts[1] = base + 1;
    }
    else { rs_counts[0] = base + 1; rs_counts[1] = base; }
};

// Direct combinatorial unranking: fill rs_labels[] for the given rank.
void(float rank) rs_unrank_into_labels =
{
    local float pos, t, ways, remN;

    // copy counts into work buffer
    for (t = 0; t < rs_T; t = t + 1)
        rs_work_counts[t] = rs_counts[t];

    remN = rs_N;
    for (pos = 0; pos < rs_N; pos = pos + 1)
    {
        for (t = 0; t < rs_T; t = t + 1)
        {
            if (rs_work_counts[t] <= 0) continue;
            ways = rs_multinomial_with_dec_from_work(remN, t);
            if (rank >= ways) { rank = rank - ways; continue; }
            rs_labels[pos] = t; rs_work_counts[t] = rs_work_counts[t] - 1; remN = remN - 1; break;
        }
    }
};

// Build rs_plist/rs_colors/rs_counts/rs_labels (canonical sorted start)
void() rs_build_deck_from_roster =
{
    local entity p;
    local float i, j, col, idx, nplayers, nteams, k;

    // Collect committed players
    nplayers = 0; nteams = 0;
    p = clanring_sentinel.next_player;
    while (p)
    {
        if (!(p.style & CLANRING_OBSERVER) && (p.style & CLANRING_READY) && (p.next_team != world))
        {
            // Record team colour and grow counts
            col = p.next_team.height;
            idx = -1;
            for (i = 0; i < nteams; i = i + 1) if (rs_colors[i] == col) { idx = i; break; }
            if (idx < 0) { rs_colors[nteams] = col; rs_counts[nteams] = 0; idx = nteams; nteams = nteams + 1; }
            rs_counts[idx] = rs_counts[idx] + 1;

            if (nplayers < 32) { rs_plist[nplayers] = p; nplayers = nplayers + 1; }
        }
        p = p.next_player;
    }

    rs_N = nplayers;
    rs_T = nteams;

    // Sort colours ascending and keep counts aligned (selection sort)
    for (i = 0; i < rs_T - 1; i = i + 1)
    {
        idx = i;
        for (j = i + 1; j < rs_T; j = j + 1) if (rs_colors[j] < rs_colors[idx]) idx = j;
        if (idx != i)
        {
            col = rs_colors[i]; rs_colors[i] = rs_colors[idx]; rs_colors[idx] = col;
            k   = rs_counts[i]; rs_counts[i] = rs_counts[idx]; rs_counts[idx] = k;
        }
    }

    // Force rpickup to operate over *balanced* team-size targets
    // (ignores current roster skew like 3:1 and builds a 2:2 deck for N=4)
    rs_enforce_balanced_counts();

    // Canonical start labels: [0..0, 1..1, 2..2, ...]
    nplayers = 0;
    for (i = 0; i < rs_T; i = i + 1)
        for (j = 0; j < rs_counts[i]; j = j + 1)
            rs_labels[nplayers++] = i;

    rs_total_perms    = rs_multinomial_total();
    rs_used_in_cycle  = 0;
    rs_start_offset   = floor(random() * rs_total_perms);
    rs_valid          = TRUE;
};

// Compare current roster/distribution against deck's
float() rs_same_roster =
{
    local entity seen[32];
    local entity p;
    local float i, j, ncur, matchcount, col, idx, curT;
    local float curColors[8], curCounts[8];

    // Build current committed set
    ncur = 0; curT = 0;
    p = clanring_sentinel.next_player;
    while (p)
    {
        if (!(p.style & CLANRING_OBSERVER) && (p.style & CLANRING_READY) && (p.next_team != world))
        {
            if (ncur < 32) { seen[ncur] = p; ncur = ncur + 1; }

            col = p.next_team.height; idx = -1;
            for (i = 0; i < curT; i = i + 1) if (curColors[i] == col) { idx = i; break; }
            if (idx < 0) { curColors[curT] = col; curCounts[curT] = 0; idx = curT; curT = curT + 1; }
            curCounts[idx] = curCounts[idx] + 1;
        }
        p = p.next_player;
    }

    if (ncur != rs_N) return FALSE;
    if (curT != rs_T) return FALSE;

    // colours & counts (order-insensitive)
    for (i = 0; i < rs_T; i = i + 1)
    {
        idx = -1;
        for (j = 0; j < curT; j = j + 1) if (curColors[j] == rs_colors[i]) { idx = j; break; }
        if (idx < 0) return FALSE;
        if (curCounts[idx] != rs_counts[i]) return FALSE;
    }

    // membership set equality
    matchcount = 0;
    for (i = 0; i < rs_N; i = i + 1)
        for (j = 0; j < ncur; j = j + 1)
            if (rs_plist[i] == seen[j]) { matchcount = matchcount + 1; break; }

    return (matchcount == rs_N);
};

// Lexicographic next_permutation over rs_labels[0..rs_N-1]
float() rs_next_labels =
{
    local float i, j, l, r, tmp;

    if (rs_N <= 1) return FALSE;

    i = rs_N - 2;
    while ((i >= 0) && (rs_labels[i] >= rs_labels[i + 1])) i = i - 1;
    if (i < 0) return FALSE; // last permutation

    j = rs_N - 1;
    while (rs_labels[j] <= rs_labels[i]) j = j - 1;

    // swap i <-> j
    tmp = rs_labels[i]; rs_labels[i] = rs_labels[j]; rs_labels[j] = tmp;

    // reverse suffix [i+1 .. end]
    l = i + 1; r = rs_N - 1;
    while (l < r)
    {
        tmp = rs_labels[l]; rs_labels[l] = rs_labels[r]; rs_labels[r] = tmp;
        l = l + 1; r = r - 1;
    }
    return TRUE;
};

// Ensure deck matches current roster; rebuild if needed
float() rs_build_or_refresh =
{
    if (!rs_valid || !rs_same_roster())
    {
        rs_build_deck_from_roster();
        // rs_start_offset is set inside rs_build_deck_from_roster()
    }
    return rs_valid;
};

// ---------------------------------------------
//  R P I C K U P   (core; decked, no repeats)
// ---------------------------------------------
void() match_rpickup =
{
    local float i;

    if (!teamplay)
    {
        local float mode; local string szmode;
        mode = options_get_mode(); szmode = strings_get_mode(mode);
        sprint(self, sprintf("Command valid in team modes only (current: %s)\n", szmode));
        return;
    }
    if (clanring_state & CLANRING_MATCH_STARTED)
    { sprint(self, "Cannot reshuffle during a live match\n"); return; }

    if (!rs_build_or_refresh())
    { sprint(self, "Unable to build reshuffle deck\n"); return; }

    // Choose the next configuration by direct unranking
    // rank = (rs_start_offset + rs_used_in_cycle) % rs_total_perms (safe wrap without long loops)
    local float rank;
    rank = rs_start_offset + rs_used_in_cycle;
    if (rs_total_perms > 0)
        rank = rank - rs_total_perms * floor(rank / rs_total_perms);
    rs_unrank_into_labels(rank);

    if (rs_T < 2 || rs_N < 2)
    { sprint(self, "Reshuffle requires at least two teams and two committed players\n"); return; }

    // Mute verify-team color-change complaints briefly while we relink players
    rs_silence_until = time + 1;

    // Unlink all committed players silently (use deck order)
    for (i = 0; i < rs_N; i = i + 1)
        match_remove_player_silent(rs_plist[i]);

    // Apply labels -> assign players to target team colours (silently)
    for (i = 0; i < rs_N; i = i + 1)
    {
        match_add_player_silent(rs_plist[i], rs_colors[ rs_labels[i] ]);
    }

    // (keep silence window a little longer to cover client 'color' echoes)
    rs_silence_until = time + 1;
    announce("Teams reshuffled");

    local float idx, total;
    local string sx, sy;
    total = (rs_total_perms > 0) ? rs_total_perms : 1;
    // used_in_cycle is 0-based; display as 1-based within the current cycle
    idx   = ((rs_used_in_cycle % total) + 1);
    sx = ftos(idx);
    sy = ftos(total);
    bprint4("cycle ", sx, " of ", sy);
    bprint(" possibilities\n");
    

    match_update_score_info();

    rs_used_in_cycle = rs_used_in_cycle + 1;
};

// Vote/Admin entry point
void() match_request_rpickup =
{
    if (!teamplay) { local float m; local string sm; m = options_get_mode(); sm = strings_get_mode(m); sprint(self, sprintf("Command valid in team modes only (current: %s)\n", sm)); return; }
    if (clanring_state & CLANRING_MATCH_STARTED)
    { sprint(self, "Cannot reshuffle during a live match\n"); return; }

    // Pre-check roster; do not start a vote if conditions aren't met
    if (!rs_build_or_refresh()) { sprint(self, "Unable to build reshuffle deck\n"); return; }
    if (rs_T < 2 || rs_N < 2) { sprint(self, "Reshuffle requires at least two teams and two committed players\n"); return; }

    if (self.style & CLANRING_ADMINISTRATOR)
        match_rpickup();
    else if (vote_init("\brandomly reshuffle the teams\b", "", match_rpickup))
        vote_yes();
};

//
//  H E L P
//
void() match_help =
{
    sprint(self, "Match commands (for match mode only):\n");
    sprint(self, " ready       - \bcommit to a team\n");
    sprint(self, " notready    - \buncommit yourself\n");
    sprint(self, " otset       - \bchange overtime\n");
    sprint(self, " timeset     - \bchange timelimit\n");
    sprint(self, " ready?      - \bfindout who is not ready\n");
    sprint(self, " unlock      - \ballow new players to join\n");
    sprint(self, " lock        - \bre-cap the team size\n");
    sprint(self, " timerstop   - \bpause the match\n");
    sprint(self, " timerstart  - \bstart/restart the timer\n");
    sprint(self, " ghostcode   - \bview your ghost code\n");
    sprint(self, " ghostlist   - \blist ghost codes of your teammates\n");
    sprint(self, " ghost       - \brestore yourself from ghost\n");
    sprint(self, " score       - \bshow time left and score\n");
    sprint(self, " +teamscores - \bbind this to a key\n");
    sprint(self, " rockets     - \bshows who has an RL\n");
};

//
//  S H O W  N O T  R E A D Y
//
//  Prints a list of players who are not ready.
//
void() match_show_not_ready =
{
    // Check cooldown (5 seconds)
    if (time - self.ready_check_time < 5)
    {
        sprint(self, "You must wait ");
        sprint(self, ftos(ceil(5 - (time - self.ready_check_time))));
        sprint(self, " seconds before using ready? again\n");
        return;
    }
    
    // Update the timestamp
    self.ready_check_time = time;
    
    if (match_all_ready())
    {
        if (!clanring_numteams)
            sprint3(self, "No ", clanring_szteam, "s present\n");
        else
        {
            sprint(self, "All players are ready\n");
            if (clanring_numteams == 1)
                sprint3(self, "Only one ", clanring_szteam, " present\n");
        }
    }
    else
    {
        local entity player;
        bprint("The following players are \bnot\b ready:\n");
        player = find(world, classname, "player");
while (player)
        {
            if (!(player.style & (CLANRING_OBSERVER | CLANRING_READY)) && (player.style & CLANRING_CONNECTED))
            {
                if (player == self)
                    bprint3(" ", player.netname, "\n");
                else
                    bprint3("  ", player.netname, "\n");
            }
            player = find(player, classname, "player");
        }
    }
};


//
//  P A U S E  I T E M
//
void () match_pause_item =
{
    if (self.nextthink == -1)
        return;
    self.nextthink = self.nextthink + 1000000;
    self.clanring_old_velocity = self.velocity;
    self.velocity = '0 0 0';

    if (self.classname == "grenade")
        self.movetype = MOVETYPE_FLY;
};


//
//  P A U S E  P L A Y E R
//
void() match_pause_player =
{
    if ((self.style & CLANRING_OBSERVER) || self.deadflag)
    {
        self.clanring_old_velocity = '0 0 0';
        return;
    }
    self.style = self.style - (self.style & CLANRING_OK_TO_SHOOT);
    self.movetype = MOVETYPE_FLY;

    self.clanring_old_velocity = self.velocity;
    self.velocity = VEC_ORIGIN;
    if (self.nextthink == -1)
        return;
    self.nextthink = self.nextthink + 1000000;
};

void()match_abort_pause_timeout;
//
//  S H O W  P A U S E
//
//  Centerprint "Paused" to all clients.
//
void() match_show_pause =
{
    local entity oldself;
//TODO:Detect afk players to lessen the time to abort
    if ((time - clanring_match_pause_time) > 600)	//R00k: Abort a match that has been paused for 10 minutes.
    {
        match_abort_pause_timeout();
        return;
    }

    oldself = self;
    self = find(world, classname, "player");

    while (self)
    {			
        centerprint(self, "\n\n\n\n\[\bPAUSED\b\]");
        self = find(self, classname, "player");
    }
    self = oldself;

    clanring_match_timer.nextthink = time + 1.5;
    clanring_match_timer.think = match_show_pause;
};

//
//  P A U S E
//
//  Called after the request to pause has passed.
//
void() match_pause =
{
    if (mode_is_arena())
    {
        arena_pause();
        return;
    }
    if (!(clanring_state & CLANRING_MATCH_STARTED) || (clanring_state & CLANRING_MATCH_PAUSED))
        return;

    clanring_state = clanring_state | CLANRING_MATCH_PAUSED;
    clanring_match_pause_time = time;
    utils_do_items(match_pause_item);
    utils_do_item(match_pause_item, "item_backpack");
    //R00k added -start
    utils_do_flags(match_pause_item);
    utils_do_hook(match_pause_item);
    utils_do_item(match_pause_item, "item_rune");
    //R00k added -end
    utils_do_projectiles(match_pause_item);
    utils_do_players(match_pause_player);
    announce("Match paused");
    match_bprint_time();
    match_bprint_score();
    clanring_match_timer.think1 = clanring_match_timer.think;
    clanring_match_timer.cnt = clanring_match_timer.nextthink;
    match_show_pause();
};

//  C O U N T D O W N  P A U S E
// 
//
void() match_countdown_pause =
{
    if (self.owner.next_team.pausetime > 3)
    {
        remove(self);		
        match_pause();
        return;
    }
    bprint(sprintf("\[%g\]\n", (4 - self.owner.next_team.pausetime)));
    if ((4 - self.owner.next_team.pausetime) <= 3)
        sound (world, CHAN_AUTO, "buttons/switch04.wav", 1, ATTN_NONE);
    self.owner.next_team.pausetime += 1;
    self.nextthink = time + 1;
};

//
//  R E Q U E S T  P A U S E
//
void() match_request_pause =
{
    if (!(mode_is_arena()))
    {
        if (!(clanring_state & CLANRING_MATCH_STARTED))
        {
            sprint(self, "No match in progress\n");
            return;
        }
    }
    else
    {
        // In Clan Arena modes, block pausing during countdown phases
        // Allow pause only once the round is actively playing
        if (boss.state != CA_MATCH_PLAYING)
        {
            sprint(self, "Cannot pause during countdown\n");
            return;
        }
    }
    if (clanring_state & CLANRING_MATCH_PAUSED)
    {
        sprint(self, "Match is already paused\n");
        return;
    }

    if ((self.next_team != world)&&(!(self.style & CLANRING_OBSERVER)))
    {
        if (self.next_team.pausetime == FALSE)//give the team one free match pause...
        {
            bprint(sprintf("%s used the %s's \bone\b free match pause.\n", self.netname, self.next_team.netname));
            self.next_team.pausetime = TRUE;
            utils_make_scheduled_event(match_countdown_pause, 1);
            return;
        }
    }

    // Do it right away if we're an administrator, otherwise vote
    if (self.style & CLANRING_ADMINISTRATOR)
        match_pause();
    else if (vote_init("\bpause the match\b", (""), match_pause,"match_pause"))
        vote_yes();
};

//
//  U N P A U S E  I T E M
//
void() match_unpause_item =
{
    if (self.nextthink == -1)
        return;

    self.nextthink = self.nextthink - 1000000 + clanring_match_pause_time;
    self.velocity = self.clanring_old_velocity;
    if (self.classname == "grenade")
        self.movetype = MOVETYPE_BOUNCE;
    if ((self.classname == "item_flag_team1")||(self.classname == "item_flag_team2"))
        self.super_time = self.super_time + clanring_match_pause_time;
};

//
//  U N P A U S E  P L A Y E R
//
void() match_unpause_player =
{
    if (self.super_damage_finished)
    self.super_damage_finished 		= self.super_damage_finished + clanring_match_pause_time;
    if (self.invisible_finished)
    self.invisible_finished 		= self.invisible_finished + clanring_match_pause_time;
    if (self.invincible_finished)
    self.invincible_finished 		= self.invincible_finished + clanring_match_pause_time;
    if (self.radsuit_finished)
    self.radsuit_finished 			= self.radsuit_finished + clanring_match_pause_time;
    self.air_finished 				= self.air_finished + clanring_match_pause_time;
    self.pain_finished 				= self.pain_finished + clanring_match_pause_time;

    if ((self.style & CLANRING_OBSERVER) || self.deadflag)
        return;
    
    self.style = self.style | CLANRING_OK_TO_SHOOT;
        
    //R00k ADDED...
    self.lefty 				= (self.lefty + clanring_match_pause_time);				// paused match reset captime
    self.flag_since         = (self.flag_since + clanring_match_pause_time);        // flag carry time
    self.last_hurt_carrier 	= (self.last_hurt_carrier + clanring_match_pause_time);	// paused match reset last hurt flag carrier

    self.movetype 		= MOVETYPE_WALK;
    self.finaldest_y 	= MOVETYPE_WALK;
    self.velocity 		= self.clanring_old_velocity;

    if (self.nextthink == -1)
        return;

    self.nextthink = self.nextthink - 1000000 + clanring_match_pause_time;
};

//
//  U N P A U S E  G H O S T
//
void() match_unpause_ghost =
{
    self.state = 0;
};

// 
// P A U S E  T I M E O U T
// 
// Called when the match is left in a paused state for too long.
//
void() match_abort_pause_timeout = 
{
    announce ("\[\bAuto Match Abort Activated\b\]\n");
    announce ("Match was paused for too long.");
    announce ("The match is over");//used for cl_autodemo 2, stop the demo before stats_autodump.

    if (clanring_request != world)    //Remove any active requests
        Request_Poll_Cleanup();

    clanring_state = (clanring_state - (clanring_state & CLANRING_MATCH_PAUSED));
    clanring_state = (clanring_state - (clanring_state & CLANRING_AUTO_PAUSED));
    clanring_match_pause_time = time - clanring_match_pause_time;

    utils_do_items(match_unpause_item);
    utils_do_item(match_unpause_item, "item_backpack");
    utils_do_flags (match_unpause_item);
    utils_do_hook (match_unpause_item);
    utils_do_item(match_unpause_item, "item_rune");
    utils_do_projectiles(match_unpause_item);
    utils_do_players(match_unpause_player);
    utils_do_item(match_unpause_ghost, "clanring_ghost");
    utils_do_players(match_gib_player);
    match_reset();
    match_delete_teams();
    remove(clanring_match_timer);
    clanring_state = clanring_state - (clanring_state & CLANRING_TIMER_STARTED);
    clanring_state = clanring_state - (clanring_state & CLANRING_MATCH_STARTED);
    clanring_state = (clanring_state | CLANRING_MATCH_OVER);
    //TODO: Play some custom sound here... 
    clanring_sentinel.movetarget = world;
    utils_do_match_spawns(spawns_restore_model);
}

//
//  U N P A U S E
//
//  Called after the request to unpause has passed.
//
void() match_unpause =
{
    if (!(clanring_state & CLANRING_MATCH_PAUSED))
    {
        return;
    }

    if (clanring_request != world)    //Remove any active requests
        Request_Poll_Cleanup();

    clanring_state = (clanring_state - (clanring_state & CLANRING_MATCH_PAUSED));
    clanring_state = (clanring_state - (clanring_state & CLANRING_AUTO_PAUSED));
    clanring_match_pause_time = time - clanring_match_pause_time;
    utils_do_items(match_unpause_item);
    utils_do_item(match_unpause_item, "item_backpack");

    //R00k added -start
    utils_do_flags (match_unpause_item);
    utils_do_hook (match_unpause_item);
    utils_do_item(match_unpause_item, "item_rune");
    //R00k added -end

    utils_do_projectiles(match_unpause_item);
    utils_do_players(match_unpause_player);
    utils_do_item(match_unpause_ghost, "clanring_ghost");
    announce("Match unpaused");

    match_bprint_time();
    match_bprint_score();
    clanring_match_timer.nextthink = clanring_match_timer.cnt + clanring_match_pause_time;
    clanring_match_timer.think = clanring_match_timer.think1;
    WriteByte(MSG_ALL, SVC_CENTERPRINT);
    WriteString(MSG_ALL, " ");
};

//
//  U N P A U S E  C O U N T D O W N  T H I N K
//
void() match_unpause_countdown_think =
{
    local string sz;

    if (self.count > 0)
    {
        sz = ftos(self.count);
        announce2(" ", sz);
        if (self.count <= 3)
            sound (world, CHAN_AUTO, "buttons/switch04.wav", 1, ATTN_NONE);
        self.nextthink = time + 1;
        self.count = self.count - 1;
    }
    else
    {
        clanring_state = (clanring_state - (clanring_state & CLANRING_UNPAUSING));
        match_unpause();
        remove(self);
    }
};

//
//  S T A R T  U N P A U S E  C O U N T D O W N
//

void() match_start_unpause_countdown =
{
    if (mode_is_arena())
    {
        arena_start_unpause_countdown();
        return;
    }

    local entity countdown;

    if (clanring_state & CLANRING_UNPAUSING)
        return;

    clanring_state = clanring_state | CLANRING_UNPAUSING;
    countdown = utils_make_scheduled_event(match_unpause_countdown_think, 1);
    countdown.count = 4;
    announce("Match restarts in T minus");
    announce(" 5");
};

//
//  R E Q U E S T  U N P A U S E
//
//  Request to start/restart the timer
//
void() match_request_unpause =
{
    if (clanring_state & CLANRING_UNPAUSING)
        return;

    if (!(mode_is_arena()))
    if (!(clanring_state & CLANRING_MATCH_STARTED))
    {
        if (clanring_state & CLANRING_TIMER_STARTED)
        {
            sprint(self, "Timer has already started\n");
            return;
        }
        if (clanring_numteams < 2)
        {
            if (!clanring_numteams)
                sprint3(self, "There are no ", clanring_szteam, "s present\n");
            else
                sprint3(self, "There is only one ", clanring_szteam, " present\n");
            return;
        }

        // request to force the timer to start.
        // Do it right away if we're an administrator, otherwise vote
        if (self.style & CLANRING_ADMINISTRATOR)
            match_start_timer ();
        else
        if (vote_init("\bstart the timer\b", "", match_start_timer))
            vote_yes();

        return;
    }

    if (!(clanring_state & CLANRING_MATCH_PAUSED))
    {
        sprint(self, "Match is not paused\n");
        return;
    }

    // Do it right away if we're an administrator, otherwise vote
    if (self.style & CLANRING_ADMINISTRATOR)
        match_start_unpause_countdown ();
    else
    if (vote_init("\bunpause the match\b", "", match_start_unpause_countdown))
        vote_yes();
};

//
//  S H O W  R O C K E T S
//
//  For observers, list the players that have an RL
//
void() match_show_rockets =
{
    local entity player;

    if (!teamplay)
    {
        local float mode; local string szmode;
        mode = options_get_mode(); szmode = strings_get_mode(mode);
        sprint(self, sprintf("Command valid in match mode only (current: %s)\n", szmode));
        return;
    }
    if (!(self.style & CLANRING_OBSERVER))
        return;

    if (!(clanring_state & CLANRING_MATCH_STARTED))
    {
        sprint(self, "No match in progress\n");
        return;
    }
    if (clanring_sentinel.ammo_rockets)
    {
        sprint(self, "The following players have RLs:\n");
        player = clanring_sentinel.next_player;
        while (player)
        {
            if (player.items & IT_ROCKET_LAUNCHER)
                sprint2(self, player.netname, "\n");
            player = player.next_player;
        }
    }
    else
    {
        sprint(self, "Nobody has a rocket launcher\n");
    }
};

//
//  I M P U L S E
//
void() match_impulse =
{
    if (clanring_state & CLANRING_TAKING_AUTOSS)
        return;

    if (self.impulse == 129)
        match_help ();

    if (mode_is_arena())
    {
        switch (self.impulse)
        {
//TODO: arena_match_impulse();
            case (120):
            {
                //TODO: allow any mode to choose color and set team size to 1
                if (clanring_playmode & CLANRING_CA_MODE)
                {
                    if (self.team == 14)
                        self.impulse = 1;
                    else if (self.team == 5)
                        self.impulse = 2;
                    else if (self.team == 13)
                        self.impulse = 3;
                    else if (self.team == 3)
                        self.impulse = 4;
                    else
                    {
                        sprint(self, "Invalid pants color\n");
                        self.impulse = 0;
                        break;
                    }
                }
                else
                {
                    self.impulse = 1;
                }
                Teamplay_Select_Team();

                self.impulse = 0;
                break;
            }
            case (121):
            {
                if (clanring_playmode & CLANRING_CA_MODE)
                    self.impulse = 5;
                else
                    self.impulse = 2;
                Teamplay_Select_Team();
                self.impulse = 0;
                break;
            }
            case (124):
            {
                match_request_pause();
                break;
            }
            case (125):
            {
                // In Clan Arena: if still waiting (no round timer), use force start; else unpause
                if ((clanring_playmode & CLANRING_CA_MODE) && (boss.state == CA_MATCH_WAITING))
                    votables_force_start();
                else
                    match_request_unpause();
                break;
            }
        }
        return;
    }

    if (!(clanring_playmode & CLANRING_MATCH_MODE))
    {
        if (self.impulse == 120)
        {
            if (self.style & CLANRING_OBSERVER)
            {
                if (clanring_client_ready() == TRUE)
                    return;

                if (teamplay)
                {
                    teamplay_ready_player();//Classic CTF
                }
                else
                {
                    self.oflags = self.oflags - (self.oflags & OBSERVER_QUAKETV);	//Sputnik
                    observer_end();
                }
            }
            else
                sprint(self, "You are not an observer\n");
        }
        else
        {
            sprint(self, "Command valid in match mode only\n");
        }
        return;
    }

    switch (self.impulse)
    {
        case (120):
        {
            match_ready();
            break;
        }
        case (121):
        {
            match_notready();
            break;
        }
        case (122):
        {
            match_request_unlock();
            break;
        }
        case (123):
        {
            match_show_not_ready();
            break;
        }
        case (124):
        {
            match_request_pause();
            break;
        }
        case (125):
        {
            // In Clan Arena: if still waiting (no round timer), use force start; else unpause
            if ((clanring_playmode & CLANRING_CA_MODE) && (boss.state == CA_MATCH_WAITING))
                votables_force_start();
            else
                match_request_unpause();
            break;
        }
        case (126):
        {
            match_list_ghosts();
            break;
        }
        case (127):
        {
            match_request_restore_ghost();
            break;
        }
        case (128):
        {
            match_sprint_status();
            break;
        }
        case (130):
        {
            match_request_lock();
            break;
        }
        case (133):
        {
            match_show_rockets();
            break;
        }
        case (134):
        {
            match_request_rpickup();
            break;
        }
    }
};

//
//  V E R I F Y  T E A M
//
//  Called whenever self.height != self.team
//
void() match_verify_team =
{
    local string temp;

    if (!(clanring_playmode & CLANRING_MATCH_MODE))
    {
        if (teamplay)
            teamplay_verify_team();
        return;
    }

    if (!(self.style & CLANRING_CONNECTED))
    {
        self.height	= 0;
        self.team 	= 0;
        return;
    }

    if (!(self.style & CLANRING_READY))
    {
        self.height = (self.team - 1);
        //R00k Feeble attempt to deter observers using teamcolors to send mm2 messages
        //to playing clients. IE Coaching
        if (clanring_state & CLANRING_MATCH_STARTED)
        {
            if (clanring_maxsize != 16)
            {
                setcolour(self,0,0);
                stuffcmd(self,";color 0;\n");
//				sprint(self, "Match is LOCKED\n");
                return;
            }
        }

        if (self.height && (clanring_state & CLANRING_MATCH_STARTED))
        {
            temp = strings_get_colour(self.height);
            announce3(self.netname, " has become ", temp);
        }
        return;
    }

    temp = ftos(self.height);
    stuffcmd(self, "color ");
    stuffcmd(self, temp);
    stuffcmd(self, "\n");

    self.team = self.height + 1;
    if (clanring_state & CLANRING_MATCH_STARTED)
        announce2(self.netname, " tried to change color");
    else
    {
        // Suppress this message if we're in a server-driven reshuffle window
        if (time >= rs_silence_until)
            sprint(self, "You cannot change color after you have committed\n");
    }
};

//
//  D I S C O N N E C T  N O T I F Y
//
//  Called when a player disconnects from the server or enters
//  observer mode.
//
void(entity player) match_disconnect_notify =
{
    quaketag_disconnect_notify (player);

    if (!(player.style & CLANRING_OBSERVER))
        match_remove_player (player);

    //A player readies up, types notready, then disconnects; which causes the match_start_timer to halt.
    //We want to proceed with match_start_timer if there are enough players.	
    if (!(player.style & CLANRING_READY))
    {
        // Check to see if we need to start the timer
        if (!(clanring_state & CLANRING_MATCH_WAIT))
        {
            if (!(clanring_state & CLANRING_TIMER_STARTED))
            {
                if (clanring_numteams > 1)
                {
                    if (match_all_ready())
                        match_start_timer();
                }
            }
        }
        return;
    }

    player.style = player.style - (player.style & CLANRING_READY);

    // Check to see if we need to stop the match
    if (clanring_state & CLANRING_MATCH_STARTED)
    {
        // Copy his info to his ghost
        if (!self.owner)// Sanity check added 2/6/99
        {
            cprint("Internal error #3.\n");
        }
        else
        {
            if (!(self.style & CLANRING_OBSERVER))
            {
                // copy always
                self.owner.frags 		= self.frags;
                self.owner.dest 		= self.dest;
                self.owner.dest1 		= self.dest1;
                self.owner.dest2 		= self.dest2;
                self.owner.mangle 		= self.mangle;
                self.owner.clanring_qdwep 		= self.clanring_qdwep;
                self.owner.clanring_qdkill 		= self.clanring_qdkill;
                self.owner.clanring_ptwep 		= self.clanring_ptwep;
                self.owner.clanring_ptkill 		= self.clanring_ptkill;
                self.owner.clanring_hack_count 	= self.clanring_hack_count;
                self.owner.style 		= self.style & (CLANRING_ADMINISTRATOR | CLANRING_HEADS_UP | CLANRING_SMART_WEAPON | CLANRING_AUTOSTATS);
                self.owner.true_kills 	= self.true_kills;
                self.owner.pos1_x 		= self.pos1_x;
                self.owner.pos1_y 		= self.pos1_y;
                self.owner.pos1_z 		= self.pos1_z;
                self.owner.pos2_y 		= self.pos2_y;
                self.owner.pos2_z 		= self.pos2_z;
                self.owner.captime 		= self.captime;
                self.owner.dmg_taken	= self.dmg_taken;
                   self.owner.dmg_given	= self.dmg_given;
                self.owner.ewep			= self.ewep;
                 self.owner.statstate 	= self.statstate;
                           
                self.owner.clanring_badstats = self.clanring_badstats;
                
                self.owner.fpickups		= self.fpickups;
                self.owner.fcaptures	= self.fcaptures;
                self.owner.fdefenses	= self.fdefenses;
                self.owner.freturns 	= self.freturns;
                self.owner.fcassists 	= self.fcassists;
                self.owner.fcfrags   	= self.fcfrags;
                self.owner.captime   	= self.captime;
                
                // check autopause
                if (clanring_playmode & CLANRING_AUTO_PAUSE)
                {
                    match_pause();
                    if ((clanring_request != world)&&(clanring_request.classname == "match_pause"))	//Remove active request to pause
                        Request_Poll_Cleanup();
                    bprint("\bClanring autopause activated\n");
                    cprint("Clanring autopause activated\n");
                    bprint("\bType '\btimerstart\b' to restart match\n");
                    clanring_state = clanring_state | CLANRING_AUTO_PAUSED;
                    match_pause_player();
                }

                // copy on pause
                if ((clanring_state & CLANRING_MATCH_PAUSED) && (self.deadflag == DEAD_NO))
                {
                    // mark data as valid
                    self.owner.state = 1;
                    self.owner.frame = self.frame;
                    self.owner.effects = self.effects;					
                    self.owner.origin = self.origin;
                    self.owner.angles = self.angles;
                    self.owner.waterlevel = self.waterlevel;
                    self.owner.watertype = self.watertype;
                    self.owner.clanring_old_velocity = self.clanring_old_velocity;
                    self.owner.punchangle = self.punchangle;
                    self.owner.nextthink = self.nextthink + 1000000;
                    self.owner.think = self.think;
                    self.owner.health = self.health;
                    self.owner.items = self.items;
                    self.owner.items = self.items - (self.items & (IT_KEY1 | IT_KEY2));//just in case.
                    self.owner.armortype = self.armortype;
                    self.owner.armorvalue = self.armorvalue;
                    self.owner.weapon = self.weapon;
                    self.owner.weaponmodel = self.weaponmodel;
                    self.owner.weaponframe = self.weaponframe;
                    self.owner.currentammo = self.currentammo;
                    self.owner.ammo_shells = self.ammo_shells;
                    self.owner.ammo_nails = self.ammo_nails;
                    self.owner.ammo_rockets = self.ammo_rockets;
                    self.owner.ammo_cells = self.ammo_cells;
                    self.owner.flags = self.flags;
                    self.owner.walkframe = self.walkframe;
                    self.owner.attack_finished = self.attack_finished;
                    self.owner.pain_finished = self.pain_finished;
                    self.owner.air_finished = self.air_finished;
                    self.owner.invincible_finished = self.invincible_finished;
                    self.owner.invisible_finished = self.invisible_finished;
                    self.owner.super_damage_finished = self.super_damage_finished;
                    self.owner.radsuit_finished = self.radsuit_finished;
                    self.owner.invincible_time = self.invincible_finished - time; // R00k: how many seconds remain
                    self.owner.invisible_time = self.invisible_finished - time;
                    self.owner.super_time = self.super_damage_finished - time;
                    self.owner.rad_time = self.radsuit_finished - time;
                    self.owner.show_hostile = self.show_hostile;
                    self.owner.jump_flag = self.jump_flag;
                    self.owner.swim_flag = self.swim_flag;
                    self.owner.bubble_count = self.bubble_count;

                    // check mega healths
                    local entity mh;
                    mh = find(world, classname, "item_health");
                    while (mh)
                    {
                        if ((mh.healtype == 2) && (mh.owner == self))
                            mh.owner = self.owner;
                        mh = find(mh, classname, "item_health");
                    }
                }
            }
        }

        // if he's turned himself into an observer, then get rid of his ghost
        if (self.style & CLANRING_OBSERVER)
        {
            if (self.owner)
                remove(self.owner);
            else	// Sanity check added 5/15/98
                cprint("Internal error #1.\n");

            stuffcmd(self, "alias ghostcode echo You do not have a ghost\n");
            stuffcmd(self, "alias ghost impulse 127\n");
        }

        self.owner = world;

/*R00k: removed
        // check to see if he was top 2 in individual mode
        if ((!teamplay && ((self == clanring_first_place) || (self == clanring_second_place))))
        {
            score_get_top2 ();
        }
*/
        if (!match_count_players())
        {
            match_unpause();
            match_reset();
            match_delete_teams();
            announce("Match aborted");
            remove(clanring_match_timer);
            clanring_state = clanring_state - (clanring_state & CLANRING_TIMER_STARTED);
            clanring_state = clanring_state - (clanring_state & CLANRING_MATCH_STARTED);
            match_show_timelimit();
            match_update_score_info(); //R00k: OCT'24
            utils_do_match_spawns(spawns_restore_model);	//R00k
        }
        return;
    }
    else
    {
        if ((teamplay > 0) && (player.next_team.count == 0))
            match_remove_team (player.next_team);
    }

    // JP - 5/15/98
    // Bug fix for players falling out of map.
    // For the 5 seconds after a match ends, players are "ready" but they
    // have no ghost.  So let's return before we remove world, okay? :p
    // That's what was causing it!
    if (clanring_state & CLANRING_MATCH_WAIT)
        return;

    // He was ready but the match hadn't started, so remove his ghost
    if (self.owner)
        remove(self.owner);
    else	// Sanity check added 5/15/98
        cprint("Internal error #2.\n");

    self.owner = world;
    stuffcmd(self, "alias ghostcode echo You do not have a ghost\n");
    stuffcmd(self, "alias ghost impulse 127\n");

    // Check to see if we need to stop the timer
    if ((clanring_state & CLANRING_TIMER_STARTED) && (clanring_numteams < 2))
    {
        announce3("Only one ", clanring_szteam, " present");
        announce("Timer stopped");		
        remove(clanring_match_timer);
        pqc_match_time(0, 0);//fixed
        clanring_state = (clanring_state - (clanring_state & CLANRING_TIMER_STARTED));
        clanring_state = clanring_state - (clanring_state & CLANRING_NULL_FLAG);
        match_show_timelimit();
    }
    if (!clanring_numteams)
        announce3("No ", clanring_szteam, "s present");
};

//
//  L I S T  G H O S T S
//
void() match_list_ghosts =
{
    local entity e;
    local string num, tname, pname, pad;

    if (self.next_team == world)
    {
        sprint(self, "You are not on a team.\n");
        return;
    }
    e = find(world, classname, "clanring_ghost");
    if (!e)
    {
        sprint(self, "There are no ghosts\n");
        return;
    }

    tname = strings_get_teamname(self.next_team.height);
    sprint(self,"\nGhost codes for the ", tname,"\n");
    while (e)
    {
        if (e.height == self.next_team.height)	// Only list ghostcodes for your team
        {
            sprint(self, "\b----------------+----\n");
            num = strings_ftos_gold(e.count);
            if (e.owner.owner == e)
                pname = e.owner.netname;
            else
                pname = "Disconnected";
            pad = strpad(15, pname);
            sprint(self, pad," \b|\b ", num,"\n");
            pad = ""; num = "";
        }
        e = find(e, classname, "clanring_ghost");
    }
    sprint(self, "\n");
};

//
//  W E A P O N  P R E W A R  A N I M A T E  T H I N K
//
//  Think function for weapons during prewar when weaponstay is off.
//  Smoothly fades weapon opacity from 1.0 to 0.0 and back to indicate no weaponstay.
//  Active during entire prewar period (before timer starts and during countdown).
//
void() weapon_prewar_animate_think =
{
    // Only animate in DM prewar (match mode, before match starts, not CTF, weaponstay off)
    if ((clanring_playmode & CLANRING_MATCH_MODE) && 
        (!(clanring_state & CLANRING_MATCH_STARTED)) &&
        (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG)) &&
        deathmatch < 3)
    {
        // We're in DM prewar with weaponstay off - do the animation
    }
    else
    {
        // All other cases - clean up and exit
        weapon_prewar_cleanup();
        return;
    }

    // Calculate fade direction and alpha value
    // Use a sine wave for smooth fading: sin((time * speed) * 2 * PI)
    local float fade_speed = 0.1; // Controls animation speed
    local float alpha_value = (sin(time * fade_speed * 2 * 3.14159) + 1) * 0.5;
    
    // Set alpha (0.1 minimum so weapons don't completely disappear, 0.99 maximum)
    self.alpha = 0.1 + (alpha_value * 0.89);
    
    self.nextthink = time + 0.05; // Update 20 times per second for smooth animation
};

//
//  W E A P O N  P R E W A R  S E T U P
//
//  Sets up weapon animation for all weapons when entering prewar with weaponstay off.
//
void() weapon_prewar_setup =
{
    // Only setup if weaponstay is off (deathmatch < 3)
    if (deathmatch >= 3)
        return;
        
    if (self.classname == "weapon_supershotgun" ||
        self.classname == "weapon_nailgun" ||
        self.classname == "weapon_supernailgun" ||
        self.classname == "weapon_grenadelauncher" ||
        self.classname == "weapon_rocketlauncher" ||
        self.classname == "weapon_lightning")
    {
        // Start the animation
        self.think = weapon_prewar_animate_think;
        self.nextthink = time + random() * 0.5; // Stagger start times slightly
        self.alpha = 1.0; // Start fully visible
    }
};

//
//  W E A P O N  P R E W A R  C L E A N U P
//
//  Stops weapon animation and restores normal appearance.
//
void() weapon_prewar_cleanup =
{
    if (self.classname == "weapon_supershotgun" ||
        self.classname == "weapon_nailgun" ||
        self.classname == "weapon_supernailgun" ||
        self.classname == "weapon_grenadelauncher" ||
        self.classname == "weapon_rocketlauncher" ||
        self.classname == "weapon_lightning")
    {
        self.alpha = 1.0; // Restore full opacity
        self.think = SUB_regen; // Restore normal weapon think function
        self.nextthink = time + self.delay; // Restore normal respawn timing
    }
};