float qper_checks;

void(float passed, string description) qper_assert =
{
    if (!passed) error(strcat("QPER TEST FAILED: ", description));
    qper_checks++;
};

float(float a, float b) qper_near =
{
    return fabs(a - b) < 0.001;
};

entity(float team_id) qper_test_player =
{
    entity e = spawn();
    e.classname = "player";
    e.team = team_id;
    e.last_returned_flag = -100;
    e.last_fragged_carrier = -100;
    qper_on_connect(e);
    qper_on_spawn(e);
    e.qper_spawn_time = time - 10;
    qper_reset_player(e);
    return e;
};

void() qper_test_kills =
{
    entity a = qper_test_player(RED), b = qper_test_player(RED), v = qper_test_player(BLUE);
    entity c, d;
    float i;

    // Fixed pool: finisher reserve plus damage share; the total never grows.
    qper_ledger_add(v, a, 100);
    qper_ledger_add(v, b, 300);
    qper_credit_kill(v, b);
    qper_assert(qper_near(b.qper_kill_credit, 0.6 * 0.35 + 0.6 * 0.65 * 0.75), "finisher gets reserve plus damage share");
    qper_assert(qper_near(a.qper_kill_credit, 0.6 * 0.65 * 0.25), "assistant gets damage share");
    qper_assert(qper_near(a.qper_assist_credit, a.qper_kill_credit), "assist credit tracked separately");
    qper_assert(qper_near(a.qper_kill_credit + b.qper_kill_credit, 0.6), "kill pool is fixed");

    // Damage decays: 200 dealt one half-life ago equals 100 now.
    a = qper_test_player(RED); b = qper_test_player(RED); v = qper_test_player(BLUE);
    qper_ledger_add(v, a, 200);
    v.qper_l_time = time - 3;
    qper_ledger_add(v, b, 100);
    qper_credit_kill(v, b);
    qper_assert(qper_near(a.qper_kill_credit, 0.6 * 0.65 * 0.5), "old damage decays by half-life");

    // A small follow-up hit only adds itself; it doesn't revive old damage.
    a = qper_test_player(RED); b = qper_test_player(RED); v = qper_test_player(BLUE);
    qper_ledger_add(v, a, 300);
    v.qper_l_time = time - 9;
    qper_ledger_add(v, a, 1);
    qper_ledger_add(v, b, 100);
    qper_credit_kill(v, b);
    qper_assert(qper_near(a.qper_kill_credit, 0.6 * 0.65 * 38.5 / 138.5), "follow-up hit does not refresh old damage");

    // A reused client slot can't collect the previous occupant's damage.
    a = qper_test_player(RED); b = qper_test_player(RED); v = qper_test_player(BLUE);
    qper_ledger_add(v, a, 100);
    qper_on_connect(a);
    qper_credit_kill(v, b);
    qper_assert(qper_near(b.qper_kill_credit, 0.6), "stale connection is ignored");
    qper_assert(a.qper_kill_credit == 0, "stale connection gets nothing");

    // Respawning clears the ledger.
    a = qper_test_player(RED); b = qper_test_player(RED); v = qper_test_player(BLUE);
    qper_ledger_add(v, a, 100);
    qper_on_spawn(v);
    v.qper_spawn_time = time - 10;
    qper_credit_kill(v, b);
    qper_assert(a.qper_kill_credit == 0, "damage from a previous life is dropped");

    // Teammates earn nothing.
    a = qper_test_player(BLUE); v = qper_test_player(BLUE);
    qper_credit_kill(v, a);
    qper_assert(a.qper_kill_credit == 0, "teamkill earns no kill credit");

    // Spawn ramp is smooth, with exemptions.
    b = qper_test_player(RED); v = qper_test_player(BLUE);
    v.qper_spawn_time = time;
    qper_assert(qper_near(qper_kill_pool(v), 0.6 * 0.4), "fresh spawn pool at floor");
    v.qper_spawn_time = time - 2;
    qper_assert(qper_near(qper_kill_pool(v), 0.6 * 0.7), "spawn ramp halfway");
    v.qper_spawn_time = time;
    v.super_damage_finished = time + 10;
    qper_assert(qper_near(qper_kill_pool(v), 0.9), "quad holder exempt and bonused");
    v.super_damage_finished = 0;

    // dmm3: weapon carriers are ordinary; dmm1: exempt and bonused.
    v.items = IT_ROCKET_LAUNCHER;
    deathmatch = 3;
    qper_assert(qper_near(qper_kill_pool(v), 0.6 * 0.4), "dmm3 RL carrier is not special");
    deathmatch = 1;
    qper_assert(qper_near(qper_kill_pool(v), 0.9), "dmm1 RL carrier exempt and bonused");
    deathmatch = 3;
    v.items = 0;

    // Seven attackers on six slots: the smallest recent damage is replaced.
    v = qper_test_player(BLUE);
    for (i = 0; i < 6; i++)
        qper_ledger_add(v, qper_test_player(RED), 50 + i * 10);
    c = qper_test_player(RED);
    qper_ledger_add(v, c, 200);
    d = qper_test_player(RED);
    qper_credit_kill(v, d);
    qper_assert(qper_near(c.qper_kill_credit, 0.6 * 0.65 * 200 / (60 + 70 + 80 + 90 + 100 + 200)), "eviction keeps larger contributors");
};

void() qper_test_costs =
{
    entity p = qper_test_player(RED);

    p.mangle_z = 2;            // killed by enemies
    p.mangle_x = 1;            // a lava death
    p.clanring_badstats2_x = 1;
    p.clanring_badstats_x = 1; // RL pack taken by an enemy
    deathmatch = 3;
    qper_assert(qper_near(qper_contribution(p), -0.8 - 1.0), "lava death charged once; dmm3 pack loss free");
    deathmatch = 1;
    qper_assert(qper_near(qper_contribution(p), -0.8 - 1.0 - 0.6), "dmm1 charges the pack loss");
    deathmatch = 3;
};

void() qper_test_ctf =
{
    entity r1 = qper_test_player(RED), r2 = qper_test_player(RED), r3 = qper_test_player(RED);
    entity b1 = qper_test_player(BLUE);
    entity blue_flag = spawn(), red_flag = spawn();

    clanring_playmode = CLANRING_MATCH_MODE | CLANRING_CAPTURE_THE_FLAG;
    clanring_state = CLANRING_MATCH_STARTED;
    red_flag.classname = "item_flag_team1"; red_flag.team = RED;
    blue_flag.classname = "item_flag_team2"; blue_flag.team = BLUE;

    // r1 steals and carries 10s, drops; r2 recovers, carries 5s and caps; r3 returned our flag.
    qper_flag_pickup(blue_flag, r1, TRUE);
    blue_flag.owner = r1;
    r1.qper_poss_since = time - 10;
    qper_flag_drop(blue_flag, r1);
    blue_flag.owner = world;
    qper_flag_pickup(blue_flag, r2, FALSE);
    blue_flag.owner = r2;
    r2.qper_poss_since = time - 5;
    r3.last_returned_flag = time;
    qper_flag_capture(r2);

    qper_assert(qper_near(r3.qper_cap_credit, 0.6), "assist share of capture pool");
    qper_assert(qper_near(r1.qper_cap_credit, 0.6 + 1.2 * 10 / 15), "stealer gets steal share and carry share");
    qper_assert(qper_near(r2.qper_cap_credit, 0.6 + 1.2 * 5 / 15), "capper gets capper share and carry share");
    qper_assert(qper_near(r1.qper_cap_credit + r2.qper_cap_credit + r3.qper_cap_credit, 3.0), "capture pool is fixed");
    qper_assert(blue_flag.qper_poss_id == 0, "capture closes the possession");

    // A failed possession pays only the small steal credit, once.
    qper_flag_pickup(red_flag, b1, TRUE);
    red_flag.owner = b1;
    qper_flag_drop(red_flag, b1);
    red_flag.owner = world;
    qper_flag_reset(red_flag);
    qper_flag_reset(red_flag);
    qper_assert(qper_near(b1.qper_steal_credit, 0.2), "failed steal credited once");
    qper_assert(b1.qper_cap_credit == 0, "failed steal gets no capture credit");

    // CTF terms switch off outside CTF.
    clanring_playmode = CLANRING_MATCH_MODE;
    qper_assert(qper_term(r1, QPER_T_CAPTURES) == 0, "capture credit only counts in CTF");
    clanring_playmode = CLANRING_MATCH_MODE | CLANRING_CAPTURE_THE_FLAG;
};

void() qper_test_time_and_rating =
{
    entity p = qper_test_player(RED);

    clanring_playmode = CLANRING_MATCH_MODE;
    clanring_state = CLANRING_MATCH_STARTED;
    teamplay = 1;
    deathmatch = 3;
    stats_matchtype = 4;

    // 20 minutes joined with one finished 60s pause and one ongoing 30s pause.
    p.qper_stint_start = time - 1200;
    p.qper_stint_pause_mark = qper_pause_total;
    qper_pause_total = qper_pause_total + 60;
    clanring_state = clanring_state | CLANRING_MATCH_PAUSED;
    clanring_match_pause_time = time - 30;
    qper_assert(qper_near(qper_active_secs(p), 1110), "pauses are excluded");
    qper_stint_end(p);
    clanring_match_pause_time = time - 90;
    qper_assert(qper_near(qper_active_secs(p), 1110), "stint frozen once ended");
    clanring_state = CLANRING_MATCH_STARTED;

    // Reference-average play rates 15; rating is the blend of own rate and reference.
    p.qper_active_bank = 1200;
    qper_assert(qper_cohort_key() == "tdm_dmm3_4", "cohort key includes mode, dmm and team size");
    qper_assert(qper_near(qper_reference_rate(), 1.8), "prior used with no data");
    p.dmg_given = 1.8 * 20 * 200;  // exactly the reference rate in damage
    qper_assert(qper_near(qper_rating(p), 15), "average contribution rates 15");
    p.dmg_given = 2 * 1.8 * 20 * 200;
    qper_assert(qper_near(qper_rating(p), 15 + 15 * 20 / 23), "short-stint blend toward reference");
    // Explanation: top contributions and the largest cost, and the points add up to the rating.
    p.mangle_z = 10;
    p.qper_kill_credit = 6;
    qper_find_top_terms(p);
    qper_assert(qper_top_id1 == QPER_T_DAMAGE && qper_top_id2 == QPER_T_KILLS && qper_top_id3 == -1, "top contributions ordered");
    qper_assert(qper_cost_id == QPER_T_DEATHS && qper_near(qper_cost_v, qper_points(p, -4)), "largest cost reported");
    qper_assert(qper_near(qper_rating(p), 15 * 3 / 23 + qper_top_v1 + qper_top_v2 + qper_cost_v), "reason points sum to the rating");
    p.mangle_z = 0;
    p.qper_kill_credit = 0;

    p.dmg_given = 0;
    p.qper_active_bank = 60;
    qper_assert(qper_is_provisional(p), "under five minutes is provisional");

    // Reference update is persisted and reloaded.
    qper_ref_update(2.4 * 300, 300);
    qper_ref_loaded = FALSE;
    qper_ref_count = 0;
    qper_assert(qper_near(qper_reference_rate(), (2.4 * 300 + 1.8 * 30) / 330), "reference reloads from file and blends with prior");
    qper_assert(qper_near(qper_reference_mins(), 300), "reference minutes persisted");
};

void() worldspawn =
{
    teamplay = 1;
    deathmatch = 3;
    clanring_playmode = CLANRING_MATCH_MODE;
    clanring_state = CLANRING_MATCH_STARTED;

    qper_test_kills();
    qper_test_costs();
    qper_test_ctf();
    qper_test_time_and_rating();

    print(sprintf("QPER TEST PASSED: %g checks\n", qper_checks));
    localcmd("quit\n");
};
