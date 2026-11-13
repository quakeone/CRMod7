// Builds synthetic matches and runs the real Discord stats builder.
// The Python driver parses the data/discord/stats_N.json files it writes.

entity dst_blue, dst_red;

entity(string name, entity tm) dst_player =
{
    entity e = spawn();
    e.classname = "player";
    e.netname = name;
    e.style = CLANRING_CONNECTED;
    e.th_die = SUB_Null;
    qper_on_connect(e);
    qper_on_spawn(e);
    qper_reset_player(e);
    e.join_time = time - 1200;
    e.qper_stint_open = FALSE;
    e.qper_active_bank = 1200;
    e.next_team = tm;
    if (tm != world)
    {
        e.team = tm.height + 1;
        e.height = tm.height;
    }
    return e;
};

// shots/hits: bullets, nails, LG, rockets
void(entity e, float fr, float ping, float k, float d, float bs, float bh, float ns, float nh,
     float ls, float lh, float rs, float rh) dst_core =
{
    e.frags = fr;
    e.ping_time = ping;
    e.true_kills = k;
    e.mangle_z = d;
    e.dest1_x = bs; e.dest2_x = bh;
    e.dest1_y = ns; e.dest2_y = nh;
    e.dest1_z = ls; e.dest2_z = lh;
    e.dest_x = rs;  e.dest_y = rh;
};

void(entity e, float rlk, float lgk, float given, float taken, float ew,
     float quads, float qtime, float qhits, float qshots, float qopp, float qself, float qtm) dst_fight =
{
    e.stats_rl_carrier_kills = rlk;
    e.stats_lg_carrier_kills = lgk;
    e.dmg_given = given;
    e.dmg_taken = taken;
    e.ewep = ew;
    e.clanring_qdwep_z = quads;
    e.totalquad = qtime;
    e.clanring_qdwep_x = qhits;
    e.clanring_qdwep_y = qshots;
    e.clanring_qdkill_x = qopp;
    e.clanring_qdkill_z = qself;
    e.clanring_qdkill_y = qtm;
};

void(entity e, float paks, float selfdmg, float teamdmg, float bore, float lava, float axe, float fall,
     float ra, float ya, float mg, float rl, float lg) dst_misc =
{
    e.clanring_badstats_x = paks;
    e.clanring_badstats_y = selfdmg;
    e.clanring_badstats_z = teamdmg;
    e.clanring_badstats_bores = bore;
    e.clanring_badstats2_x = lava;
    e.clanring_badstats2_y = axe;
    e.clanring_badstats2_z = fall;
    e.stats_item_redarmor = ra;
    e.stats_item_yellowarmor = ya;
    e.stats_item_mega = mg;
    e.stats_item_rl = rl;
    e.stats_item_lg = lg;
};

void(entity e, float cap, float rtn, float def, float cdef, float cfrg, float hold) dst_ctf =
{
    e.fcaptures = cap;
    e.freturns = rtn;
    e.fdefenses = def;
    e.fcdefenses = cdef;
    e.fcfrags = cfrg;
    e.fcarries_time = hold;
};

void() dst_clear_players =
{
    entity p = find(world, classname, "player");
    while (p)
    {
        p.classname = "retired";
        p = find(p, classname, "player");
    }
};

void(string tag) dst_run =
{
    entity ev = spawn();
    clanring_statsdiscordurl = "http://127.0.0.1:9/discord-test";
    webhook_stats_info(ev);
    print(sprintf("DISCORD TEST %s parts=%g\n", tag, wst_part));
};

// The 8:49 PM bastard match from the bug report (Blue 651 - 56 Red)
void() dst_ctf_match =
{
    entity p;

    teamplay = 1;
    deathmatch = 3;
    clanring_playmode = CLANRING_MATCH_MODE | CLANRING_CAPTURE_THE_FLAG;
    clanring_state = CLANRING_MATCH_STARTED;
    clanring_maxsize = 3;
    clanring_timelimit = 20;
    clanring_sentinel = spawn();
    clanring_sentinel.matchTime = time;
    dst_blue = spawn(); dst_blue.height = COLOR_BLUE; dst_blue.frags = 651;
    dst_red = spawn(); dst_red.height = COLOR_RED; dst_red.frags = 56;
    dst_red.next_team = dst_blue;
    clanring_sentinel.next_team = dst_red;   // list order != score order

    // Red first in entity order so the sort has work to do
    p = dst_player("woods", dst_red);
    dst_core(p, 45, 25, 29, 31, 100, 23, 100, 4, 400, 100, 200, 90);
    dst_fight(p, 12, 11, 8769, 8317, 6236, 2, 30, 28, 100, 6, 0, 0);
    dst_misc(p, 1, 60, 50, 1, 1, 0, 0, 4, 9, 2, 8, 5);
    dst_ctf(p, 0, 5, 0, 2, 6, 209);

    p = dst_player("r00k", dst_red);
    dst_core(p, 13, 27, 9, 26, 100, 10, 100, 17, 400, 80, 200, 46);
    dst_fight(p, 6, 2, 4520, 5289, 3436, 0, 0, 0, 0, 0, 0, 0);
    dst_misc(p, 2, 80, 120, 0, 2, 0, 0, 3, 5, 1, 6, 2);
    dst_ctf(p, 0, 3, 0, 0, 3, 339);

    p = dst_player("Faded", dst_red);
    dst_core(p, -2, 45, 0, 36, 100, 4, 100, 0, 400, 16, 200, 44);
    dst_fight(p, 0, 0, 898, 7421, 647, 0, 0, 0, 0, 0, 0, 0);
    dst_misc(p, 2, 120, 20, 1, 1, 0, 0, 1, 2, 0, 2, 1);
    dst_ctf(p, 0, 0, 0, 0, 0, 34);

    p = dst_player("penguin", dst_blue);
    dst_core(p, 182, 44, 12, 18, 100, 24, 0, 0, 400, 80, 200, 46);
    dst_fight(p, 1, 1, 3130, 4835, 1210, 0, 0, 0, 0, 0, 0, 0);
    dst_misc(p, 3, 140, 120, 1, 1, 0, 0, 2, 6, 1, 4, 3);
    dst_ctf(p, 5, 3, 0, 2, 3, 208);

    p = dst_player("new 2 quake", dst_blue);
    dst_core(p, 241, 38, 41, 11, 100, 16, 0, 0, 400, 80, 200, 58);
    dst_fight(p, 17, 12, 7538, 4105, 3770, 7, 90, 12, 100, 10, 1, 0);
    dst_misc(p, 1, 20, 50, 1, 1, 0, 0, 6, 3, 2, 7, 4);
    dst_ctf(p, 3, 7, 1, 9, 11, 122);

    p = dst_player("omicr0n", dst_blue);
    dst_core(p, 228, 47, 40, 9, 100, 30, 100, 12, 400, 68, 200, 70);
    dst_fight(p, 11, 6, 10359, 5247, 4954, 11, 210, 19, 100, 19, 0, 0);
    dst_misc(p, 1, 30, 80, 0, 1, 0, 0, 8, 4, 3, 9, 5);
    dst_ctf(p, 5, 10, 4, 1, 8, 559);

    // spectator who never played: must not appear anywhere
    p = dst_player("spec", world);
    p.style = CLANRING_CONNECTED | CLANRING_OBSERVER;
    p.join_time = 0;
    p.frags = 99;

    dst_run("ctf");
};

// FFA with names that stress JSON escaping, markdown and mentions
void() dst_ffa_match =
{
    entity p;

    dst_clear_players();
    teamplay = 0;
    deathmatch = 1;
    clanring_playmode = CLANRING_MATCH_MODE;
    clanring_maxsize = 0;
    clanring_sentinel = spawn();
    clanring_sentinel.matchTime = time;

    p = dst_player("q\"uote\\back", world);
    dst_core(p, 30, 20, 30, 10, 100, 20, 100, 10, 0, 0, 200, 60);
    dst_fight(p, 0, 0, 5000, 3000, 2000, 1, 30, 10, 50, 3, 0, 0);

    p = dst_player("@everyone", world);
    dst_core(p, 10, 30, 10, 25, 100, 15, 0, 0, 0, 0, 200, 40);
    dst_fight(p, 0, 0, 2000, 4000, 900, 0, 0, 0, 0, 0, 0, 0);

    p = dst_player("*bold*_x_", world);
    dst_core(p, 20, 40, 20, 15, 100, 25, 0, 0, 0, 0, 200, 50);
    dst_fight(p, 0, 0, 3500, 3500, 1500, 0, 0, 0, 0, 0, 0, 0);

    dst_run("ffa");
};

// server.cfg sets dst_case: 1 = CTF match twice in a row, 2 = FFA
void() worldspawn =
{
    time = 2000;
    if (cvar("dst_case") == 2)
        dst_ffa_match();
    else
    {
        dst_ctf_match();
        dst_clear_players();
        dst_ctf_match();
    }
    print("DISCORD TEST DONE\n");
    localcmd("quit\n");
};
