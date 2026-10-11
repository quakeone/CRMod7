float wipeout_checks;
entity wo_red, wo_blue, wo_a, wo_b, wo_c;

void(float passed, string description) wo_assert =
{
    if (!passed) error(strcat("WIPEOUT TEST FAILED: ", description));
    wipeout_checks++;
};

float(float a, float b) wo_near = { return fabs(a - b) < 0.001; };

entity(entity pteam, string name) wo_player =
{
    entity p = spawn();
    p.classname = "player";
    p.netname = name;
    p.client = "Test";
    p.team = p.team2 = pteam.team2;
    p.style = CLANRING_CONNECTED;
    p.ca_player_flag = PF_PLAYING;
    p.use = p.th_pain = SUB_Null;
    p.th_die = im_dead_now_what;
    p.nextthink = -1;
    p.movetype = MOVETYPE_WALK;
    p.health = 100;
    p.armorvalue = 200;
    p.armortype = 0.8;
    p.takedamage = DAMAGE_AIM;
    p.items = boss.items;
    p.weapon = IT_ROCKET_LAUNCHER;
    p.ammo_rockets = p.currentammo = 50;
    p.ammo_nails = 200;
    p.ammo_cells = 150;
    p.ammo_shells = 100;
    p.wipeout_ammo_grenades = 6;
    p.next_team = pteam;
    p.chain_gang = pteam.chain_gang;
    pteam.chain_gang = p;
    pteam.teamtotal++;
    pteam.teamalive++;
    return p;
};

void() wo_reset =
{
    entity e, next;
    self = world;
    e = nextent(world);
    while (e != world)
    {
        next = nextent(e);
        if (e.classname != "info_player_deathmatch") remove(e);
        e = next;
    }
    time = 1000;
    clanring_playmode = CLANRING_CA_MODE | CLANRING_WIPEOUT_MODE | CLANRING_NO_HOOK;
    clanring_state = 0;
    gameover = intermission_running = FALSE;
    teamplay = deathmatch = 1;
    clan_arena_init_world();
    boss.state = CA_MATCH_PLAYING;
    boss.timetofight = TRUE;
    cvar_set("cr_wipeout_max_respawns", "4");
    wo_red = spawn(); wo_red.classname = "ca_team"; wo_red.netname = "red"; wo_red.team2 = 4;
    wo_blue = spawn(); wo_blue.classname = "ca_team"; wo_blue.netname = "blue"; wo_blue.team2 = 13;
    boss.next_team = wo_red; wo_red.next_team = wo_blue;
    wo_a = wo_player(wo_red, "A");
    wo_b = wo_player(wo_red, "B");
    wo_c = wo_player(wo_blue, "C");
};

void(entity p) wo_die =
{
    self = p; p.health = 0; p.deadflag = DEAD_DEAD;
    im_dead_now_what();
};

void(entity p) wo_limbo =
{
    p.style |= CLANRING_OBSERVER;
    p.deadflag = DEAD_NO;
    p.ca_player_flag = PF_DEAD;
    p.health = 999;
    p.movetype = MOVETYPE_NOCLIP;
    p.oflags = OBSERVER_FLY;
};

void() wo_test_wipes =
{
    wo_reset();
    wo_die(wo_a);
    wo_assert(wo_red.teamalive == 1 && wo_a.respawntime == time + 3, "normal return is queued while teammate lives");
    wo_assert(wo_b.wipeout_test_cues == 1 && wo_a.wipeout_test_cues == 0 && wo_c.wipeout_test_cues == 0, "last-alive cue goes only to survivor");
    wipeout_update_last_alive(wo_red);
    wo_assert(wo_b.wipeout_test_cues == 1, "last-alive cue does not repeat");
    wo_die(wo_b);
    wo_assert(wo_red.teamalive == 0 && wo_a.respawntime == 0 && wo_b.respawntime == 0, "wipe cancels every pending return");
    arena_main_loop();
    wo_assert(boss.wait == time + 4 && !boss.timetofight, "wipe ends round and stops shooting immediately");

    wo_reset();
    wo_die(wo_c);
    arena_main_loop();
    wo_assert(wo_c.respawntime == time && boss.wait == 0, "solo free first death does not lose round");
    wo_limbo(wo_c); self = wo_c; observer_pre_think();
    wo_assert(!IS_CA_OBSERVER(wo_c) && wo_blue.teamalive == 1 && wo_c.rounddeaths == 1, "solo instant return preserves death count");
    wo_die(wo_c); arena_main_loop();
    wo_assert(wo_c.respawntime == 0 && boss.wait > time, "solo second death loses round");

    wo_reset();
    remove(wo_b); wo_red.chain_gang = wo_a; wo_a.chain_gang = world;
    wo_red.teamalive = wo_red.teamtotal = 1;
    wo_die(wo_a); wo_die(wo_c); arena_main_loop();
    wo_assert(boss.wait == 0 && wipeout_team_in_play(wo_red) && wipeout_team_in_play(wo_blue), "simultaneous solo first deaths are not a draw");

    wo_reset();
    wo_c.just_suicided = time;
    wo_die(wo_c); arena_main_loop();
    wo_assert(wo_c.respawntime == 0 && boss.wait > 0, "suicide cannot use solo free return");

    wo_reset();
    wo_die(wo_a); wo_limbo(wo_a); time += 5;
    self = wo_b; RemoveFromTeam(); arena_main_loop();
    wo_assert(wo_red.teamalive == 0 && wo_red.teamtotal == 1 && wo_a.respawntime == 0 && boss.wait > 0,
              "last living teammate leaving cannot turn a delayed return into a solo exception");

    wo_reset();
    wo_die(wo_a); wo_limbo(wo_a);
    self = wo_b; arena_client_disconnect(); arena_main_loop();
    wo_assert(wo_red.teamalive == 0 && wo_red.teamtotal == 1 && wo_a.respawntime == 0,
              "last living teammate disconnecting cancels queued returns once");
};

void() wo_test_limit =
{
    wo_reset();
    wo_red.teamtotal = 4;
    wo_assert(wipeout_get_respawn(wo_a, 1) == 5 && wipeout_get_respawn(wo_a, 2) == 10 &&
              wipeout_get_respawn(wo_a, 3) == 20 && wipeout_get_respawn(wo_a, 4) == 30, "default 4v4 schedule matches KTX");
    wo_assert(wipeout_get_respawn(wo_a, 5) == 999, "default return limit is four");
    wo_red.teamtotal = 2;
    cvar_set("cr_wipeout_max_respawns", "1");
    wo_die(wo_a);
    wo_assert(wo_a.respawntime == time + 3, "configured first return is available");
    wo_red.teamalive++; wo_a.health = 100; wo_a.deadflag = DEAD_NO;
    wo_die(wo_a);
    wo_assert(wo_a.respawntime == 0 && wipeout_get_respawn(wo_a, 1) == 999, "configured limit applies to death queue and delay");
    cvar_set("cr_wipeout_max_respawns", "6");
    wo_assert(wipeout_get_respawn(wo_b, 5) == 24, "limit can exceed four");
    cvar_set("cr_wipeout_max_respawns", "0");
    wo_die(wo_c);
    wo_assert(wo_c.respawntime == 0 && !wipeout_team_in_play(wo_blue), "zero disables even solo first return");
};

void() wo_test_pause =
{
    entity grenade;
    wo_reset();
    wo_die(wo_a); wo_limbo(wo_a);
    wo_c.health = 20; wo_c.wipeout_round_kills = 1; wo_c.wipeout_regen_time = time - 3;
    wo_b.spawn_protect_finished = time + 0.5;
    wo_b.wipeout_spawn_time = time - 2;
    wo_b.wipeout_escape_time = time - 0.1;
    wo_b.killstreak = 3;
    grenade = spawn(); grenade.classname = "grenade"; grenade.nextthink = time + 2;
    grenade.movetype = MOVETYPE_BOUNCE; grenade.velocity = '1 2 3';
    arena_pause(); time += 10;
    self = wo_a; observer_pre_think();
    wo_assert(IS_CA_OBSERVER(wo_a) && wo_red.teamalive == 1, "overdue return cannot spawn during pause");
    self = wo_c; WipeoutModePlayerUpdate();
    wo_assert(wo_c.health == 20 && wo_c.wipeout_regen_time > 0, "solo regeneration cannot complete during pause");
    arena_unpause();
    wo_assert(wo_near(clanring_match_pause_time, 10), "unpause calculates elapsed pause duration");
    wo_assert(wo_a.respawntime == time + 3 && wo_red.nextspawn == time + 3, "personal and team return timers retain remaining time");
    wo_assert(wo_near(time - wo_c.wipeout_regen_time, 3), "regen retains elapsed active time");
    wo_assert(wo_near(wo_b.spawn_protect_finished - time, 0.5), "spawn protection retains remaining time");
    wo_assert(wo_near(time - wo_b.wipeout_spawn_time, 2) && wo_near(time - wo_b.wipeout_escape_time, 0.1), "spawn context and escape grace exclude pause");
    wo_assert(wo_b.killstreak == 3, "unpause does not reset round statistics");
    wo_assert(grenade.nextthink == time + 2 && grenade.velocity == '1 2 3' && grenade.movetype == MOVETYPE_BOUNCE, "projectile fuse and velocity resume correctly");
    time += 2; self = wo_a; observer_pre_think();
    wo_assert(IS_CA_OBSERVER(wo_a), "return still waits after unpause");
    time += 1; wo_a.wipeout_regen_time = time - 3; wo_a.wipeout_escape_time = time - 0.1;
    observer_pre_think();
    wo_assert(!IS_CA_OBSERVER(wo_a) && wo_red.teamalive == 2, "return happens when remaining delay expires");
    wo_assert(wo_a.wipeout_regen_time == 0 && wo_a.wipeout_escape_time == 0, "real respawn clears previous-life state");
    wo_assert(wo_a.ammo_nails == 200 && wo_a.ammo_cells == 150 && wo_a.wipeout_ammo_grenades == 6, "real respawn uses KTX loadout");
    wo_assert(wo_a.spawn_protect_finished == time + 1, "return gets one second of protection");

    wo_reset(); wo_die(wo_a); wo_die(wo_b); arena_main_loop();
    arena_pause(); time += 10; arena_main_loop();
    wo_assert(boss.wait == time - 6 && !boss.busy, "round-end wait cannot expire while paused");
    boss.unpausing = TRUE; arena_main_loop();
    wo_assert(boss.wait == time - 6 && !boss.busy, "resume countdown cannot advance the paused round");
    arena_unpause();
    wo_assert(boss.wait == time + 4 && !boss.timetofight, "pause also freezes round-end grace without reopening combat");
};

void() wo_test_damage =
{
    wo_reset(); self = wo_c;
    wo_c.wipeout_regen_time = time - 2;
    wo_c.deathtype = "falling"; T_Damage(wo_c, world, world, 5);
    wo_c.deathtype = "drowning"; T_Damage(wo_c, world, world, 10);
    wo_assert(wo_c.health == 100 && wo_c.armorvalue == 200 && wo_c.wipeout_regen_time > 0, "falls/drowning do not damage armor/health or cancel regeneration");
    wo_c.deathtype = "rocket"; boss.wait = time + 4;
    T_Damage(wo_c, wo_a, wo_a, 50);
    wo_assert(wo_c.health == 100 && wo_c.armorvalue == 200 && wo_a.dmg_given == 0, "round-end wait blocks damage and statistics");
    boss.wait = 0;
    wo_c.spawn_protect_finished = time + 1;
    T_Damage(wo_c, wo_a, wo_a, 50);
    wo_assert(wo_c.health == 100 && wo_c.armorvalue == 200, "fresh return rejects enemy damage");
    wo_c.spawn_protect_finished = 0; wo_a.spawn_protect_finished = time + 1;
    T_Damage(wo_c, wo_a, wo_a, 50);
    wo_assert(wo_c.health == 100 && wo_c.armorvalue == 200, "fresh return cannot deal enemy damage");
    wo_a.spawn_protect_finished = 0;
    T_Damage(wo_c, wo_a, wo_a, 125);
    wo_assert(wo_c.health == 75 && wo_c.armorvalue == 100 && wo_a.frags == 1 && wo_a.dmg_cache == 25, "Wipeout awards one point per hundred actual damage");
    wo_assert(wo_c.wipeout_regen_time == 0, "real enemy damage cancels recovery after grace");
    T_Damage(wo_c, wo_a, wo_a, 75);
    wo_assert(wo_a.frags == 2 && wo_a.dmg_cache == 0, "damage scoring carries remainder across hits");
};

void() wo_test_regen =
{
    wo_reset(); self = wo_c;
    wo_c.health = 20; wo_c.armorvalue = 10; wo_c.ammo_rockets = wo_c.currentammo = 2;
    wo_c.wipeout_round_kills = 1; wo_c.wipeout_regen_time = time - 6;
    wo_c.weaponframe = 5; wo_c.think = player_rocket2; wo_c.nextthink = time + 0.1;
    wo_c.style |= CLANRING_SETTING_OPTIONS;
    WipeoutModePlayerUpdate();
    wo_assert(wo_c.health == 100 && wo_c.armorvalue == 200 && wo_c.currentammo == 50, "recovery replenishes inventory and selected ammo even with menu open");
    wo_assert(wo_c.weaponframe == 5 && wo_c.think == player_rocket2 && wo_near(wo_c.nextthink - time, 0.1), "recovery preserves weapon animation");
    wo_c.style &= ~CLANRING_SETTING_OPTIONS;
    wo_c.health = 20; wo_c.deadflag = DEAD_DYING; wo_c.wipeout_regen_time = time - 6;
    wipeout_check_solo_regen(wo_c);
    wo_assert(wo_c.health == 20, "recovery cannot heal a dying player");
    wo_c.deadflag = DEAD_NO; wo_die(wo_c);
    wo_assert(wo_c.wipeout_regen_time == 0, "death clears recovery even inside damage grace");
};

void() wo_test_grenades =
{
    float i;
    wo_reset(); self = wo_a;
    wo_a.ammo_rockets = 0; wo_a.impulse = 6; W_ChangeWeapon();
    wo_assert(wo_a.weapon == IT_GRENADE_LAUNCHER && wo_a.currentammo == 6, "grenades can be selected with zero rockets");
    wo_a.weapon = IT_SUPER_NAILGUN; CycleWeaponCommand();
    wo_assert(wo_a.weapon == IT_GRENADE_LAUNCHER, "forward cycle uses separate grenade ammunition");
    wo_a.weapon = IT_ROCKET_LAUNCHER; CycleWeaponReverseCommand();
    wo_assert(wo_a.weapon == IT_GRENADE_LAUNCHER, "reverse cycle uses separate grenade ammunition");
    wo_a.weapon = IT_ROCKET_LAUNCHER; wo_a.previous_weapon = IT_GRENADE_LAUNCHER; PreviousWeaponCommand();
    wo_assert(wo_a.weapon == IT_GRENADE_LAUNCHER, "previous weapon uses separate grenade ammunition");
    wo_a.ammo_rockets = 50; clanring_playmode |= CLANRING_NO_SPOOGE;
    for (i = 0; i < 6; i++) W_FireGrenade();
    wo_assert(wo_a.wipeout_ammo_grenades == 0 && wo_a.ammo_rockets == 50 && !(wo_a.items & IT_GRENADE_LAUNCHER), "six grenades consume no rockets and bypass legacy spam cap");
    wo_a.items |= IT_GRENADE_LAUNCHER; wo_a.weapon = IT_AXE; wo_a.impulse = 6; W_ChangeWeapon();
    wo_assert(wo_a.weapon == IT_AXE, "rockets cannot substitute for empty grenade allowance");
    self = wo_c; wo_c.health = 20; wo_c.weapon = IT_GRENADE_LAUNCHER;
    wo_c.items &= ~IT_GRENADE_LAUNCHER; wo_c.wipeout_ammo_grenades = wo_c.currentammo = 0;
    wo_c.wipeout_round_kills = 1; wo_c.wipeout_regen_time = time - 6;
    wipeout_check_solo_regen(wo_c);
    wo_assert(wo_c.wipeout_ammo_grenades == 6 && wo_c.currentammo == 6 && (wo_c.items & IT_GRENADE_LAUNCHER), "recovery restores exhausted grenade launcher and allowance");
};

void() wo_test_escape =
{
    wo_reset();
    wo_die(wo_b); wo_limbo(wo_b); wo_b.respawntime = time;
    wo_a.rounddeaths = 4;
    self = wo_b; observer_pre_think(); time += 0.1;
    wo_a.health = 0; wo_a.deathtype = "rocket";
    Killed(wo_a, wo_c);
    wo_assert(wo_a.rounddeaths == 4 && wo_near(wo_a.respawntime - time, 18), "escape bonus prevents life exhaustion before delay is chosen");
    wo_reset();
    wo_die(wo_b); wo_limbo(wo_b); wo_b.respawntime = time;
    self = wo_b; observer_pre_think(); time += 0.1;
    wo_a.health = 0; Killed(wo_a, wo_c);
    wo_assert(wo_a.rounddeaths == 0 && wo_a.respawntime == time, "escape on first life grants immediate return");
};

void() wo_test_other_rules =
{
    float i;
    wo_reset();
    for (i = 0; i < 512; i++) arena_main_loop();
    wo_assert(find(world, classname, "item_backpack") == world, "ordinary Wipeout play spawns no random backpacks");

    wo_reset(); clanring_playmode = CLANRING_CA_MODE | CLANRING_NO_HOOK;
    clan_arena_init_world(); boss.state = CA_MATCH_PLAYING; boss.timetofight = TRUE;
    wo_assert(boss.ammo_nails == 100 && boss.ammo_cells == 30, "ordinary CA retains its loadout");
    self = wo_c; T_Damage(wo_c, wo_a, wo_a, 125);
    wo_assert(wo_a.frags == 0 && wo_a.dmg_cache == 125, "ordinary CA retains its damage scoring");
    clanring_playmode = CLANRING_NORMAL_MODE; self = wo_a;
    wo_a.weapon = IT_GRENADE_LAUNCHER; wo_a.ammo_rockets = 5; wo_a.wipeout_ammo_grenades = 6;
    W_FireGrenade();
    wo_assert(wo_a.ammo_rockets == 4 && wo_a.wipeout_ammo_grenades == 6, "ordinary modes retain shared rocket ammunition");
};

void() worldspawn =
{
    entity spot;
    precache_model("progs/eyes.mdl"); precache_model("progs/h_player.mdl");
    precache_model("progs/player.mdl"); precache_model("progs/grenade.mdl");
    spot = spawn(); spot.classname = "info_player_deathmatch"; spot.origin = '512 512 128';
    dm_num_spawns = 1;
    registercvar("cr_wipeout_max_respawns", "4");
    wo_test_wipes();
    wo_test_limit();
    wo_test_pause();
    wo_test_damage();
    wo_test_regen();
    wo_test_grenades();
    wo_test_escape();
    wo_test_other_rules();
    print(sprintf("WIPEOUT TEST PASSED: %g checks\n", wipeout_checks));
    localcmd("quit\n");
};
