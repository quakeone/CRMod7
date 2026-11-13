// Regression checks for match pause/unpause timer handling.
float pause_checks;

void(float ok, string what) pause_check =
{
    if (!ok)
        error(strcat("PAUSE TEST FAILED: ", what));
    pause_checks++;
};

void() pause_test_think = {};

void() worldspawn =
{
    local entity e, oldself, team, other_team, countdown;
    local float t0;

    t0 = time;
    clanring_sentinel = spawn();

    // An idle item (think already ran, nextthink zeroed by the engine) must
    // stay idle across a pause, or unpause re-runs SUB_regen/PlaceItem.
    e = spawn();
    e.think = pause_test_think;
    e.nextthink = 0;
    e.velocity = '0 0 50';
    oldself = self; self = e;
    clanring_match_pause_time = t0;
    match_pause_item();
    pause_check(e.nextthink == 0, "idle item offset at pause");
    pause_check(e.velocity == '0 0 0', "idle item velocity not frozen");
    clanring_match_pause_time = 30;   // pause duration, as match_unpause sets it
    match_unpause_item();
    pause_check(e.nextthink == 0, "idle item re-scheduled at unpause");
    pause_check(e.velocity == '0 0 50', "idle item velocity not restored");

    // A pending think keeps its remaining time.
    e.nextthink = t0 + 5;
    clanring_match_pause_time = t0;
    match_pause_item();
    pause_check(e.nextthink >= 1000000, "pending think not frozen");
    clanring_match_pause_time = 30;
    match_unpause_item();
    pause_check(e.nextthink == t0 + 35, "pending think not shifted by pause");

    // -1 stays untouched.
    e.nextthink = -1;
    match_pause_item();
    pause_check(e.nextthink == -1, "nextthink -1 changed");
    self = oldself;

    // An entity created mid-pause with no think stays idle.
    clanring_state = clanring_state | CLANRING_MATCH_PAUSED;
    clanring_match_pause_time = t0;
    e.nextthink = 0;
    match_pause_new_item(e, t0);
    pause_check(e.nextthink == 0, "new idle item offset");
    clanring_state = clanring_state - (clanring_state & CLANRING_MATCH_PAUSED);

    // Unpause shifts refire, rot and combo clocks along with powerups.
    e = spawn();
    e.classname = "player";
    e.deadflag = DEAD_DEAD;
    e.attack_finished = t0 + 0.5;
    e.rotthink = t0 + 1;
    e.combo_time = t0 + 0.2;
    e.super_damage_finished = t0 + 10;
    e.killstreak = 4;
    oldself = self; self = e;
    clanring_match_pause_time = 30;
    match_unpause_player();
    pause_check(e.attack_finished == t0 + 30.5, "attack_finished not shifted");
    pause_check(e.rotthink == t0 + 31, "rotthink not shifted");
    pause_check(e.combo_time == t0 + 30.2, "combo_time not shifted");
    pause_check(e.super_damage_finished == t0 + 40, "quad not shifted");

    // Arena unpause keeps powerups and round stats.
    e.invisible_finished = t0 + 5;
    e.combo_time = t0 + 0.2;
    arena_unpause_player();
    pause_check(e.invisible_finished == t0 + 35, "arena ring not shifted");
    pause_check(e.combo_time == t0 + 30.2, "arena combo_time not shifted");
    pause_check(e.killstreak == 4, "arena killstreak touched");
    self = oldself;

    // Free-pause countdown whose team left the chain: no world write.
    team = spawn();
    team.pausetime = TRUE;
    countdown = spawn();
    countdown.enemy = team;
    countdown.count = 3;
    oldself = self; self = countdown;
    match_countdown_pause();
    self = oldself;
    pause_check(wasfreed(countdown), "orphaned countdown not removed");
    pause_check(world.pausetime == 0, "countdown wrote to world");
    pause_check(team.pausetime == TRUE, "orphaned countdown refunded");

    // Countdown for a live team when the match is already paused: refund.
    other_team = spawn();
    clanring_sentinel.next_team = team;
    team.next_team = other_team;
    team.netname = "red team";
    other_team.netname = "blue team";
    clanring_state = clanring_state | CLANRING_MATCH_STARTED | CLANRING_MATCH_PAUSED;
    countdown = spawn();
    countdown.enemy = other_team;
    countdown.count = 2;
    other_team.pausetime = TRUE;
    oldself = self; self = countdown;
    match_countdown_pause();
    self = oldself;
    pause_check(wasfreed(countdown), "countdown not removed when already paused");
    pause_check(other_team.pausetime == FALSE, "free pause not refunded");

    // Match over during the countdown: refund too.
    clanring_state = clanring_state - (clanring_state & (CLANRING_MATCH_STARTED | CLANRING_MATCH_PAUSED));
    team.pausetime = TRUE;
    countdown = spawn();
    countdown.enemy = team;
    countdown.count = 1;
    oldself = self; self = countdown;
    match_countdown_pause();
    self = oldself;
    pause_check(wasfreed(countdown), "countdown not removed after match end");
    pause_check(team.pausetime == FALSE, "free pause not refunded after match end");

    print(sprintf("PAUSE TEST PASSED: %g checks\n", pause_checks));
    localcmd("quit\n");
};
