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
    e.style = CLANRING_CONNECTED;
    e.th_die = SUB_Null;
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

    deathmatch = 1;
    qper_assert(qper_cohort_key() == "tdm_dmm1_4", "dmm1 reference separated from dmm3");
    clanring_playmode |= CLANRING_CAPTURE_THE_FLAG;
    qper_assert(qper_cohort_key() == "ctf_dmm1_4", "CTF dmm1 retains both mode layers");
    deathmatch = 3;
    qper_assert(qper_cohort_key() == "ctf_dmm3_4", "CTF dmm3 reference kept separate");
    clanring_playmode = CLANRING_MATCH_MODE;
    // Reference update is persisted and reloaded.
    qper_ref_update(2.4 * 300, 300);
    qper_ref_loaded = FALSE;
    qper_ref_count = 0;
    qper_assert(qper_near(qper_reference_rate(), (2.4 * 300 + 1.8 * 30) / 330), "reference reloads from file and blends with prior");
    qper_assert(qper_near(qper_reference_mins(), 300), "reference minutes persisted");
};

void() qper_test_retire_players =
{
    entity e = find(world, classname, "player");
    while (e) { e.classname = "test_finished"; e = find(world, classname, "player"); }
    e = find(world, classname, "item_flag_team1");
    while (e) { e.classname = "test_finished"; e = find(world, classname, "item_flag_team1"); }
    e = find(world, classname, "item_flag_team2");
    while (e) { e.classname = "test_finished"; e = find(world, classname, "item_flag_team2"); }
};

void() qper_test_pause =
{
    entity a, b, v, dead, r1, r2, blue_flag, red_flag;
    float before;
    qper_test_retire_players();
    time = 1000;
    clanring_playmode = CLANRING_MATCH_MODE | CLANRING_CAPTURE_THE_FLAG;
    clanring_state = CLANRING_MATCH_STARTED | CLANRING_MATCH_PAUSED;
    clanring_match_pause_time = time - 60;
    clanring_match_timer = spawn();
    clanring_match_timer.cnt = time - 60;
    clanring_sentinel = spawn();
    clanring_first_place = clanring_second_place = clanring_sentinel;
    last_red_return_time = time - 61;
    last_blue_return_time = time - 62;
    a = qper_test_player(RED); b = qper_test_player(RED); v = qper_test_player(BLUE);
    dead = qper_test_player(RED); dead.deadflag = DEAD_DEAD;
    dead.last_returned_flag = time - 61; dead.last_fragged_carrier = time - 62;
    qper_ledger_add(v, a, 100);
    v.qper_l_time = time - 60;
    v.qper_spawn_time = time - 60;
    v.qper_stint_start = time - 70;
    v.qper_stint_pause_mark = qper_pause_total;
    r1 = qper_test_player(RED); r2 = qper_test_player(RED);
    red_flag = spawn(); red_flag.classname = "item_flag_team1"; red_flag.team = RED;
    blue_flag = spawn(); blue_flag.classname = "item_flag_team2"; blue_flag.team = BLUE;
    qper_flag_pickup(blue_flag, r1, TRUE); blue_flag.owner = r1;
    r1.qper_poss_since = time - 70;
    before = qper_active_secs(v);
    self = world;
    match_unpause(); // production path, including global CTF return clocks
    qper_assert(qper_near(qper_active_secs(v), before), "unpause preserves active seconds");
    qper_assert(qper_near(v.qper_spawn_time, time), "unpause preserves fresh-spawn age");
    qper_assert(qper_near(v.qper_l_time, time), "unpause shifts assist decay clock");
    qper_assert(qper_near(dead.last_returned_flag, time - 1), "dead player's return assist survives pause");
    qper_assert(qper_near(dead.last_fragged_carrier, time - 2), "dead player's carrier assist survives pause");
    qper_assert(qper_near(last_red_return_time, time - 1) && qper_near(last_blue_return_time, time - 2), "global return windows survive pause");
    v.qper_spawn_time = time - 10;
    qper_ledger_add(v, b, 100);
    qper_credit_kill(v, b);
    qper_assert(qper_near(a.qper_assist_credit, 0.195), "pause does not erase shared kill credit");
    qper_flag_drop(blue_flag, r1); blue_flag.owner = world;
    qper_flag_pickup(blue_flag, r2, FALSE); blue_flag.owner = r2;
    r2.qper_poss_since = time - 10;
    // dead returned our flag just before the pause, qualifying for the assist pool
    qper_flag_capture(r2);
    qper_assert(qper_near(dead.qper_cap_credit, 0.6), "paused return still assists capture");
    qper_assert(qper_near(r1.qper_cap_credit, 1.2) && qper_near(r2.qper_cap_credit, 1.2), "equal active carries split credit equally despite pause");
    remove(blue_flag); remove(red_flag);
    clanring_playmode = CLANRING_MATCH_MODE;
};

void() qper_test_damage =
{
    entity a = qper_test_player(RED), v = qper_test_player(RED), missile = spawn();
    float total;
    a.weapon = IT_SHOTGUN;
    v.takedamage = DAMAGE_AIM; v.health = 100; v.armorvalue = 100; v.armortype = 0.8;
    self = a;
    teamplay = 1;
    T_Damage(v, a, a, 40);
    qper_assert(v.health == 100 && v.armorvalue == 100 && a.qper_team_damage == 0, "friendly fire off charges no applied damage");
    qper_assert(a.clanring_badstats_z == 40, "legacy badstats retains attempted damage");
    qper_assert(qper_term(a, QPER_T_TEAMDMG) == 0, "attempted team damage is absent from rating");
    teamplay = 2;
    T_Damage(v, a, a, 40);
    qper_assert(a.qper_team_damage == 40 && v.health == 92 && v.armorvalue == 68, "applied damage includes absorbed armor and health");
    qper_assert(a.qper_team_sg == 40 && a.qper_enemy_sg == 0, "applied weapon split separates teams");
    qper_assert(qper_near(qper_term(a, QPER_T_TEAMDMG), -0.06), "team damage cost uses applied counter");
    a.super_damage_finished = time + 20;
    a.player_flag = ITEM_RUNE2_FLAG;
    v.team = BLUE; v.health = 1000; v.armorvalue = 0;
    missile.classname = "missile";
    T_Damage(v, missile, a, 10);
    qper_assert(a.qper_enemy_rl == 80 && a.qper_enemy_sg == 0, "in-flight rocket remains RL after weapon switch");
    qper_assert(a.qper_quad_damage == 80 && a.qper_strength_damage == 80, "quad and strength exposures record real output");
    qper_assert(a.dmg_given == 80 && v.qper_l_d1 == 80, "effective damage and assist ledger agree");
    a.super_damage_finished = 0; a.player_flag = 0;
    missile.classname = "grenade";
    T_Damage(v, missile, a, 10);
    qper_assert(a.qper_enemy_gl == 10, "grenade damage tracked separately");
    total = a.dmg_given;
    v.invincible_finished = time + 20;
    T_Damage(v, missile, a, 10);
    qper_assert(a.dmg_given == total && a.qper_enemy_gl == 10, "invulnerable target adds no applied damage");
    v.invincible_finished = 0; v.team = RED; v.health = 20; v.armorvalue = 10; v.armortype = 0.8;
    v.movetype = MOVETYPE_PUSH; // avoid obituary; test the actual overkill cap
    T_Damage(v, missile, a, 10000);
    qper_assert(a.qper_team_damage == 70 && a.qper_team_gl == 30, "team overkill capped at remaining armor and health");
    v = qper_test_player(BLUE); v.health = 1000; v.takedamage = DAMAGE_AIM;
    missile.classname = "spike"; v.deathtype = "supernail"; a.weapon = IT_AXE;
    T_Damage(v, missile, a, 18);
    qper_assert(a.qper_enemy_sng == 18 && a.qper_enemy_ng == 0, "supernail identity survives a weapon switch");
    v.deathtype = "nail"; T_Damage(v, missile, a, 9);
    qper_assert(a.qper_enemy_ng == 9, "ordinary nail remains separate from supernail");
    a.weapon = IT_LIGHTNING; v.deathtype = ""; T_Damage(v, a, a, 30);
    qper_assert(a.qper_enemy_lg == 30, "hitscan LG damage classified at impact");
    missile.classname = "hook"; v.deathtype = "hook"; T_Damage(v, missile, a, 15);
    qper_assert(a.qper_enemy_other == 15, "hook damage remains outside weapon buckets");
    qper_assert(qper_near(a.dmg_given, a.qper_enemy_rl + a.qper_enemy_gl + a.qper_enemy_ng + a.qper_enemy_sng + a.qper_enemy_lg + a.qper_enemy_other), "applied weapon totals reconcile with enemy damage");
    teamplay = 1;
};

void() qper_test_telemetry =
{
    entity p = qper_test_player(RED), donor = qper_test_player(RED), pack = spawn(), copy = spawn();
    float score;
    deathmatch = 1;
    p.health = 100; p.items = IT_ROCKET_LAUNCHER; p.ammo_rockets = 5;
    p.player_flag = ITEM_RUNE1_FLAG;
    p.super_damage_finished = time - 2; // expired two seconds ago
    p.qper_stint_open = FALSE; p.qper_active_bank = 10; p.qper_telemetry_mark = 0;
    // An ended stint never earns new exposure.
    qper_sample(p);
    qper_assert(p.qper_access_rl_secs == 0, "closed stint never accrues exposure");
    p.qper_stint_open = TRUE; p.qper_stint_start = time; p.qper_stint_pause_mark = qper_pause_total;
    p.qper_telemetry_mark = 0;
    qper_sample(p);
    qper_assert(p.qper_access_rl_secs == 10 && p.qper_armed_secs == 10, "weapon access and usable armed seconds tracked");
    qper_assert(p.qper_quad_secs == 8 && p.qper_resistance_secs == 10, "expiry truncates powerup exposure; rune exposure uses active time");
    clanring_state |= CLANRING_MATCH_PAUSED; clanring_match_pause_time = time - 60;
    qper_sample(p);
    qper_assert(p.qper_access_rl_secs == 10, "paused seconds do not inflate weapon access");
    clanring_state = CLANRING_MATCH_STARTED;
    p.items = 0;
    qper_acquire(p, IT_ROCKET_LAUNCHER, 0); p.items = IT_ROCKET_LAUNCHER;
    qper_acquire(p, IT_ROCKET_LAUNCHER, 0);
    qper_assert(p.qper_acquire_world == 1, "access counts only newly acquired world weapons");
    p.ammo_rockets = 100;
    qper_drop_origin(pack, donor, TRUE);
    pack.owner = donor;
    score = qper_contribution(donor);
    qper_transfer(pack, p, IT_LIGHTNING, p.items, '0 0 99', 0);
    qper_assert(donor.qper_weapon_donations == 1 && p.qper_weapon_donations_received == 1, "voluntary dmm1 drop equips teammate");
    qper_assert(donor.qper_ammo_supplied_rockets == 1, "ammo support measures actual gain after cap");
    qper_assert(qper_contribution(donor) == score, "new telemetry does not alter contribution");
    qper_drop_origin(pack, donor, FALSE);
    qper_transfer(pack, p, IT_LIGHTNING, p.items, '0 0 100', 0);
    qper_assert(p.qper_pack_recoveries == 1 && donor.qper_weapon_donations == 1, "recovering dead teammate pack earns no donation credit");
    p.team = BLUE;
    qper_transfer(pack, p, IT_LIGHTNING, p.items, '0 0 100', 0);
    qper_assert(donor.qper_pack_concessions == 1, "enemy weapon acquisition recorded separately");
    qper_on_connect(donor);
    qper_transfer(pack, p, IT_LIGHTNING, p.items, '0 0 100', 0);
    qper_assert(donor.qper_pack_concessions == 1, "reused donor connection cannot inherit pack concession");
    p.team = RED;
    qper_drop_origin(pack, donor, TRUE);
    deathmatch = 3;
    qper_transfer(pack, p, IT_LIGHTNING, p.items, '0 0 97', 0);
    qper_assert(donor.qper_weapon_donations == 1 && donor.qper_ammo_supplied_rockets == 4, "dmm3 weapon transfer records ammo without equipping credit");
    qper_telemetry_copy(donor, copy);
    qper_assert(copy.qper_ammo_supplied_rockets == 4 && copy.qper_weapon_donations == 1, "ghost copy preserves cumulative telemetry");
    qper_reset_player(copy);
    qper_assert(copy.qper_ammo_supplied_rockets == 0 && copy.qper_weapon_donations == 0, "new match resets cumulative telemetry");
};

void() qper_test_item_paths =
{
    entity recipient = qper_test_player(RED), donor = qper_test_player(RED), item;
    // Outbound UI is stubbed; the production item and damage hooks stay real.
    recipient.classname = "player"; recipient.style = CLANRING_CONNECTED;
    recipient.team = RED; recipient.health = 100; recipient.flags = FL_CLIENT;
    recipient.items = IT_AXE | IT_SHOTGUN; recipient.weapon = IT_SHOTGUN;
    qper_on_connect(recipient); qper_on_spawn(recipient); qper_reset_player(recipient);
    clanring_playmode = CLANRING_MATCH_MODE | CLANRING_CAPTURE_THE_FLAG;
    clanring_state = CLANRING_MATCH_STARTED;
    deathmatch = 1;
    donor.health = 100; donor.weapon = IT_ROCKET_LAUNCHER;
    donor.items = IT_AXE | IT_SHOTGUN | IT_ROCKET_LAUNCHER;
    donor.ammo_rockets = 5;
    self = donor;
    TossWeapon();
    item = find(world, classname, "weapon");
    qper_assert(item && item.qper_drop_voluntary, "production toss snapshots voluntary provenance");
    self = item; other = recipient;
    Team_weapon_touch();
    qper_assert(donor.qper_weapon_donations == 1 && recipient.qper_weapon_donations_received == 1, "production weapon touch records actual equipping");
    qper_assert(recipient.qper_acquire_donation == 1 && donor.qper_ammo_supplied_rockets == 5, "production donation records acquisition and actual ammo gain");
    recipient.items = IT_AXE | IT_SHOTGUN;
    donor.weapon = IT_ROCKET_LAUNCHER; donor.ammo_rockets = 5;
    self = donor;
    DropBackpack();
    item = find(world, classname, "item_backpack");
    qper_assert(item && !item.qper_drop_voluntary, "production death pack retains separate provenance");
    self = item; other = recipient;
    BackpackTouch();
    qper_assert(recipient.qper_pack_recoveries == 1 && donor.qper_weapon_donations == 1, "production death-pack recovery does not count as donation");
    qper_assert(recipient.qper_acquire_pack == 1, "production death-pack weapon source exported");
    donor.flags = FL_CLIENT; donor.weapon = IT_ROCKET_LAUNCHER;
    donor.ammo_rockets = 10; recipient.ammo_rockets = 98;
    deathmatch = 3;
    self = donor;
    TossAmmo();
    item = find(world, classname, "item_rockets");
    qper_assert(item && item.qper_drop_voluntary, "production ammo toss snapshots donor");
    self = item; other = recipient;
    Team_Ammo_Touch();
    qper_assert(recipient.ammo_rockets == 100 && donor.qper_ammo_supplied_rockets == 7, "production ammo support counts only room below cap");
    recipient.items = IT_AXE | IT_SHOTGUN;
    item = spawn(); item.classname = "weapon_rocketlauncher"; item.weapon = IT_ROCKET_LAUNCHER;
    self = item; other = recipient;
    weapon_touch();
    qper_assert(recipient.qper_acquire_world == 1, "production world weapon touch records access source");
    recipient.qper_stint_start = time - 10;
    recipient.qper_stint_pause_mark = qper_pause_total;
    recipient.qper_telemetry_mark = 0;
    qper_stint_end(recipient);
    qper_assert(recipient.qper_access_rl_secs == 10, "stint end flushes final living weapon exposure");
    clanring_playmode |= CLANRING_RUNES;
    json_export_match_to_file("stats/qper_ctf_metadata.json", FALSE);
    clanring_playmode = CLANRING_MATCH_MODE;
    recipient.classname = "test_finished";
};

void() qper_test_spawn_buckets =
{
    entity a = qper_test_player(RED), v = qper_test_player(BLUE);
    v.qper_spawn_time = time;
    qper_credit_kill(v, a);
    qper_assert(a.qper_spawn_lt1 == 1 && v.qper_spawn_deaths_lt1 == 1, "fresh kill age bucket recorded for both players");
    qper_assert(qper_near(a.qper_kill_pool_full, 0.6) && qper_near(a.qper_kill_pool_awarded, 0.24), "full and discounted kill pools exported separately");
    v.qper_spawn_time = time - 1; qper_credit_kill(v, a);
    v.qper_spawn_time = time - 2; qper_credit_kill(v, a);
    v.qper_spawn_time = time - 4; qper_credit_kill(v, a);
    qper_assert(a.qper_spawn_1to2 == 1 && a.qper_spawn_2to4 == 1 && a.qper_spawn_ge4 == 1, "spawn bucket boundaries are exact");
    v.qper_spawn_time = time; v.flag_carrier = TRUE;
    clanring_playmode |= CLANRING_CAPTURE_THE_FLAG;
    qper_credit_kill(v, a);
    qper_assert(a.qper_spawn_exempt == 1 && a.qper_spawn_lt1 == 2, "flag holder exemption remains visible in age bucket");
    clanring_playmode = CLANRING_MATCH_MODE;
};

void(float mode, float teams) qper_test_public_setup =
{
    qper_test_retire_players();
    time = time + 1000;
    clanring_playmode = CLANRING_NORMAL_MODE | mode;
    clanring_state = 0;
    teamplay = teams; deathmatch = 3;
    gameover = intermission_running = FALSE;
    clanring_gameconfig = 0;
    qper_pause_total = 0;
    qper_match_ref_valid = FALSE;
    qper_population_reset();
    qper_population_update();
};

void() qper_test_ffa_profile =
{
    entity a, b, v;
    qper_test_public_setup(0, 0);
    a = qper_test_player(RED); b = qper_test_player(RED); v = qper_test_player(RED);
    a.dmg_given = 100; a.mangle_z = 1; a.mangle_x = 1;
    a.clanring_badstats_x = 1;
    qper_assert(qper_is_ffa(), "normal non-team DM selects FFA profile");
    qper_assert(qper_near(qper_term(a, QPER_T_DAMAGE), 0.4), "FFA damage retains efficiency credit");
    qper_assert(qper_near(qper_term(a, QPER_T_DEATHS), -0.25), "FFA enemy death costs a quarter");
    qper_assert(qper_near(qper_term(a, QPER_T_SELF_DEATHS), -1), "FFA self death keeps full cost");
    qper_ledger_add(v, a, 90); qper_ledger_add(v, b, 10);
    qper_credit_kill(v, b);
    qper_assert(qper_near(b.qper_kill_credit, 0.584), "FFA finisher gets 70 percent plus damage share");
    qper_assert(qper_near(a.qper_assist_credit, 0.216), "FFA recent damage gets remaining skill credit");
    qper_assert(qper_near(a.qper_kill_credit + b.qper_kill_credit, 0.8), "FFA kill pool remains fixed");
    v.qper_spawn_time = time;
    qper_assert(qper_near(qper_kill_pool(v), 0.48), "FFA spawn floor is sixty percent");
    v.qper_spawn_time = time - 1;
    qper_assert(qper_near(qper_kill_pool(v), 0.64), "FFA spawn ramp halfway at one second");
    v.qper_spawn_time = time - 2;
    qper_assert(qper_near(qper_kill_pool(v), 0.8), "FFA spawn ramp complete at two seconds");
    deathmatch = 1; v.items = IT_ROCKET_LAUNCHER; v.qper_spawn_time = time;
    qper_assert(qper_term(a, QPER_T_WEAPON_LOSS) == 0, "FFA pack loss adds no second death cost");
    qper_assert(qper_near(qper_kill_pool(v), 1.2), "FFA dmm1 carrier kill keeps bonus and spawn exemption");
    teamplay = 1;
    qper_assert(qper_near(qper_term(a, QPER_T_WEAPON_LOSS), -0.6), "TDM retains weapon loss cost");
    qper_assert(qper_near(qper_term(a, QPER_T_DAMAGE), 0.5), "TDM retains damage weight");
    qper_assert(qper_near(qper_term(a, QPER_T_DEATHS), -0.4), "TDM retains death weight");
    teamplay = 0; deathmatch = 3; v.items = 0;
    clanring_playmode = CLANRING_MATCH_MODE; clanring_numteams = 2;
    qper_assert(!qper_is_ffa() && qper_near(qper_kill_pool(v), 0.24), "committed 1v1 match keeps existing core profile");
    qper_match_ffa_profile = qper_is_ffa(); qper_match_profile_valid = TRUE;
    clanring_numteams = 0;
    qper_assert(!qper_is_ffa() && qper_near(qper_term(a, QPER_T_DAMAGE), 0.5), "clearing duel roster cannot switch final profile");
    qper_match_profile_valid = FALSE; clanring_numteams = 3;
    qper_match_ffa_profile = qper_is_ffa(); qper_match_profile_valid = TRUE;
    clanring_numteams = 2;
    qper_assert(qper_is_ffa(), "FFA match keeps its initial profile after roster shrinks");
    clanring_playmode = CLANRING_NORMAL_MODE | CLANRING_HH_MODE;
    qper_assert(!qper_is_ffa(), "headhunters does not inherit FFA profile");
    clanring_playmode = CLANRING_NORMAL_MODE | CLANRING_CAPTURE_THE_FLAG;
    qper_assert(!qper_is_ffa(), "CTF does not inherit FFA profile");
};

void() qper_test_public_time =
{
    entity a, b, observer, c;
    qper_test_public_setup(0, 0);
    a = qper_test_player(RED); a.join_time = time;
    a.health = 100; a.items = IT_ROCKET_LAUNCHER; a.ammo_rockets = 10;
    time += 90; qper_population_update(); qper_sample(a);
    qper_assert(qper_active_secs(a) == 0 && a.qper_armed_secs == 0, "solo public time and exposure excluded");
    b = qper_test_player(RED); b.join_time = time;
    time += 60; qper_population_update(); qper_sample(a);
    qper_assert(qper_near(qper_active_secs(a), 60) && qper_near(a.qper_armed_secs, 60), "opponent arrival starts active time and exposure");
    b.health = 0; b.deadflag = DEAD_DEAD;
    time += 30; qper_population_update();
    qper_assert(qper_near(qper_active_secs(a), 90) && qper_population_players == 2, "dead opponents still count as participants");
    observer = qper_test_player(BLUE); observer.style |= CLANRING_OBSERVER;
    qper_population_update();
    time += 30; qper_population_update();
    qper_assert(qper_near(qper_average_players(), 2), "spectators do not affect population average");
    qper_stint_end(b); b.style |= CLANRING_OBSERVER;
    time += 45; qper_population_update();
    qper_assert(qper_near(qper_active_secs(a), 120), "opponent departure stops active time");
    c = qper_test_player(BLUE);
    time += 15; qper_population_update(); qper_stint_end(a);
    time += 30; qper_population_update();
    qper_assert(qper_near(qper_active_secs(a), 135), "ended public stint stays frozen");

    qper_test_public_setup(0, 1);
    a = qper_test_player(RED); b = qper_test_player(RED);
    time += 60; qper_population_update();
    qper_assert(qper_active_secs(a) == 0, "public teammates alone are not opposition");
    b.team = BLUE; qper_population_update();
    time += 30; qper_population_update();
    qper_assert(qper_near(qper_active_secs(a), 30), "public enemy team starts active clock");
    b.team = RED; qper_population_update();
    time += 30; qper_population_update();
    qper_assert(qper_near(qper_active_secs(a), 30), "public clock stops when last opposing team leaves");

    clanring_playmode = CLANRING_MATCH_MODE;
    clanring_state = CLANRING_MATCH_STARTED;
    qper_reset_player(a);
    time += 60;
    qper_assert(qper_near(qper_active_secs(a), 60), "match active time retains existing clock");
};

void() qper_test_population =
{
    entity a;
    float i;
    qper_test_public_setup(0, 0);
    qper_test_player(RED); qper_test_player(RED);
    time += 60; qper_population_update();
    qper_assert(qper_cohort_key() == "ffa_dmm3_pop2", "two-player public FFA has separate cohort");
    qper_test_player(RED); qper_test_player(RED);
    time += 60; qper_population_update();
    qper_assert(qper_near(qper_average_players(), 3) && qper_population_bucket() == "3-4", "FFA population averages changing rosters by time");
    for (i = 0; i < 4; i++) qper_test_player(RED);
    time += 120; qper_population_update();
    qper_assert(qper_near(qper_average_players(), 5.5) && qper_population_bucket() == "5-8", "medium FFA cohort uses average rather than final roster");
    deathmatch = 1;
    qper_assert(qper_cohort_key() == "ffa_dmm1_pop5-8", "FFA cohorts retain deathmatch separation");
    a = qper_test_player(RED); a.style |= CLANRING_OBSERVER; qper_population_update();
    time += 60; qper_population_update();
    qper_assert(qper_population_players == 8, "observer excluded from current population");
    for (i = 0; i < 4; i++) qper_test_player(RED);
    time += 600; qper_population_update();
    qper_assert(qper_population_bucket() == "9+" && qper_population_peak == 12, "large FFA population has its own cohort");
};

void() qper_test_match_population =
{
    qper_test_public_setup(0, 1);
    clanring_playmode = CLANRING_MATCH_MODE;
    qper_test_player(RED); qper_test_player(BLUE); qper_test_player(RED);
    time += 60; qper_population_update();
    qper_assert(qper_population_clock() == 0, "warmup does not count toward population sampling");
    clanring_state = CLANRING_MATCH_STARTED;
    qper_population_reset(); qper_population_update();
    time += 60; qper_population_update();
    qper_assert(qper_near(qper_population_clock(), 60) && qper_near(qper_average_players(), 3), "match population sampling starts with committed play");
    clanring_state |= CLANRING_MATCH_PAUSED;
    clanring_match_pause_time = time;
    time += 60; qper_population_update();
    qper_assert(qper_near(qper_population_clock(), 60), "match pause excluded from population duration");
    qper_pause_total += 60;
    clanring_state = CLANRING_MATCH_STARTED;
    qper_population_update();
    time += 30; qper_population_update();
    qper_assert(qper_near(qper_population_clock(), 90), "match population resumes without paused seconds");
    qper_match_end(TRUE);
    time += 20; qper_population_update();
    qper_assert(qper_population_players == 3 && qper_near(qper_population_clock(), 90), "match end freezes original population before closing stints");
};

void(float mode, float teams, string filename) qper_test_public_intermission =
{
    entity a, b, c, group;
    float rating, reference, learned;
    qper_test_public_setup(mode, teams);
    a = qper_test_player(RED); b = qper_test_player(BLUE); c = qper_test_player(RED);
    a.join_time = b.join_time = c.join_time = time;
    a.netname = "public a"; b.netname = "public b"; c.netname = "public c";
    a.health = b.health = c.health = 100;
    a.items = IT_ROCKET_LAUNCHER; a.ammo_rockets = 10;
    a.dmg_given = b.dmg_given = c.dmg_given = 1800;
    clanring_sentinel = spawn(); group = spawn(); group.height = RED; group.netname = "public";
    clanring_sentinel.next_team = group; clanring_sentinel.next_player = a;
    group.next_player = a; a.next_player = b; b.next_player = c;
    a.next_team = b.next_team = c.next_team = group;
    time += 180;
    rating = qper_rating(a); reference = qper_reference_rate();
    // The production map-end path must freeze before it clears player inventories.
    gameover = TRUE;
    execute_changelevel();
    qper_assert(a.qper_final_valid && qper_public_ended, "real public intermission freezes QPER");
    qper_assert(qper_near(qper_active_secs(a), 180), "public intermission closes active stint");
    qper_assert(qper_near(a.qper_access_rl_secs, 180) && a.items == 0, "intermission flushes exposure before clearing inventory");
    qper_assert(qper_near(qper_rating(a), rating) && qper_near(qper_display_reference(), reference), "public final rating and display keep scoring reference");
    qper_assert(qper_near(qper_reference_mins(), 9), "qualifying public game learns all player-minutes");
    learned = qper_reference_mins();
    time += 20; qper_population_update(); qper_public_end();
    qper_assert(qper_near(qper_reference_mins(), learned), "repeated intermission cannot learn twice");
    qper_assert(qper_near(qper_active_secs(a), 180) && qper_near(qper_live_rating(a), rating), "intermission wait does not age rating or explanations");
    qper_test_player(BLUE);
    qper_assert(qper_near(qper_display_reference(), reference) && qper_population_players == 3, "late intermission join keeps frozen reference and population");
    json_export_match_to_file(filename, FALSE);
};

void() qper_test_public_minimum =
{
    entity a;
    float before;
    qper_test_public_setup(0, 0);
    a = qper_test_player(RED); qper_test_player(BLUE);
    a.join_time = time; a.dmg_given = 1000;
    before = qper_reference_mins();
    time += 300; qper_public_end();
    qper_assert(a.qper_final_valid && qper_reference_mins() == before, "two-player public game freezes without learning");
    qper_test_public_setup(0, 0);
    a = qper_test_player(RED); qper_test_player(BLUE); qper_test_player(RED);
    a.join_time = time;
    before = qper_reference_mins();
    time += 179; qper_public_end();
    qper_assert(a.qper_final_valid && qper_reference_mins() == before, "short three-player public game cannot learn");
    qper_test_public_setup(0, 1);
    qper_test_player(RED); qper_test_player(RED); qper_test_player(RED);
    time += 300; qper_public_end();
    qper_assert(qper_population_three_secs == 0, "three teammates alone do not qualify public learning");
    qper_test_public_setup(CLANRING_PRACTICE_MODE, 0);
    a = qper_test_player(RED); qper_test_player(BLUE); qper_test_player(RED);
    time += 300; qper_public_end();
    qper_assert(!a.qper_final_valid && !qper_public_ended, "practice excluded from public finalization");
};

void() qper_test_frozen_export =
{
    entity p, redteam;
    float before, reference, f;
    qper_test_retire_players();
    time = 2000;
    clanring_playmode = CLANRING_MATCH_MODE;
    clanring_state = CLANRING_MATCH_STARTED;
    deathmatch = 3; teamplay = 1; stats_matchtype = 4;
    f = fopen(QPER_REF_FILE, FILE_WRITE);
    fputs(f, "tdm_dmm3_4 99 4000\nqper2-provisional-1 tdm_dmm3_4 99 4000\n");
    fclose(f); qper_ref_loaded = FALSE;
    qper_assert(qper_near(qper_reference_rate(), 1.8) && qper_reference_mins() == 0, "legacy and other formula versions ignored");
    p = qper_test_player(RED); p.join_time = time - 1200;
    p.qper_stint_open = FALSE; p.qper_active_bank = 1200;
    p.netname = "frozen rating"; p.team = p.height = RED;
    p.dmg_given = 14400; p.qper_team_damage = 42;
    p.qper_enemy_rl = 100; p.qper_spawn_lt1 = 2;
    before = qper_rating(p); reference = qper_reference_rate();
    qper_match_end(FALSE);
    qper_assert(qper_near(qper_rating(p), before), "final rating stays frozen after learning match");
    qper_assert(qper_reference_rate() != reference, "live reference learns the completed match");
    qper_assert(qper_near(qper_display_reference(), reference), "match export keeps original scoring reference");
    clanring_state = CLANRING_MATCH_OVER;
    qper_test_player(BLUE);
    qper_assert(qper_near(qper_display_reference(), reference), "late player reset cannot erase finished match reference");
    qper_assert(qper_near(qper_live_rating(p), before), "frozen explanation points use original reference");
    qper_assert(qper_reference_provisional(), "reference maturity reflects baseline used to score");
    qper_find_top_terms(p);
    qper_assert(qper_near(before, 15 * (1 - qper_own_weight(p)) + qper_top_v1 + qper_points(p, qper_term(p, QPER_T_TEAMDMG))), "final explanation reconstructs frozen score");
    redteam = spawn(); redteam.netname = "red"; redteam.height = RED; redteam.next_player = p;
    p.next_team = redteam; clanring_sentinel.next_team = redteam;
    clanring_sentinel.next_player = p;
    json_export_match_to_file("stats/qper_test.json", FALSE);
    // Final fixture preserves the exact reference file expected by the Python test.
    qper_ref_count = 0; qper_ref_loaded = TRUE;
    qper_ref_update(2.4 * 300, 300);
    qper_assert(qper_reference_mins() == 300 && qper_reference_provisional(), "newly mature live reference cannot change frozen maturity flag");
    qper_match_ref_valid = FALSE;
    qper_assert(!qper_reference_provisional(), "reference maturity separate from individual short stint");
    qper_assert(!qper_is_provisional(p), "long stint has no player provisional star");
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
    qper_test_pause();
    qper_test_damage();
    qper_test_telemetry();
    qper_test_item_paths();
    qper_test_spawn_buckets();
    qper_test_ffa_profile();
    qper_test_public_time();
    qper_test_population();
    qper_test_match_population();
    qper_test_public_minimum();
    qper_test_public_intermission(0, 0, "stats/qper_public_ffa.json");
    qper_test_public_intermission(0, 1, "stats/qper_public_tdm.json");
    qper_test_public_intermission(CLANRING_CAPTURE_THE_FLAG, 1, "stats/qper_public_ctf.json");
    qper_public_ended = FALSE;
    gameover = intermission_running = FALSE;
    qper_test_frozen_export();

    print(sprintf("QPER TEST PASSED: %g checks\n", qper_checks));
    localcmd("quit\n");
};
