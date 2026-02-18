/*
    frogbot_ctf.qc

    CTF-focused extension surface for Frogbot.
    Keep CTF-only decision logic and state helpers here so frogbot.qc
    can stay mode-agnostic.
*/

float(entity e) frogbot_is_bot_client;
float(entity marker) frogbot_is_marker_entity;
entity(entity from_marker, entity to_marker, float allow_rj) frogbot_zone_next_marker;
float(entity bot, string msg) frogbot_team_say;

entity frogbot_ctf_red_base_marker;
entity frogbot_ctf_blue_base_marker;
entity frogbot_ctf_red_drop_marker;
entity frogbot_ctf_blue_drop_marker;
float frogbot_ctf_last_red_state;
float frogbot_ctf_last_blue_state;
float frogbot_ctf_next_anchor_refresh;
float(entity bot) frogbot_ctf_team_bot_count;
float(entity bot, entity anchor_marker) frogbot_ctf_marker_hops_to_anchor;
entity(entity bot) frogbot_ctf_escort_anchor_marker;
float(entity bot, entity anchor_marker, float quota, float ignore_carrier_bots) frogbot_ctf_is_priority_responder;
void(entity bot, float own_state, float enemy_state, entity own_flag, entity enemy_flag, entity enemy_carrier, entity friendly_carrier) frogbot_ctf_process_state_comms;
float(entity p) frogbot_ctf_player_strength;
entity(entity bot, entity friendly_carrier, entity enemy_carrier) frogbot_ctf_pick_escort_target;

entity(vector org, float max_dist) frogbot_ctf_find_nearest_marker_to_origin =
{
    local float i;
    local float dist;
    local float best_dist;
    local entity marker;
    local entity best;

    best = world;
    best_dist = 99999999;
    if (max_dist <= 0)
        max_dist = 99999999;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker) && !(marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE))
        {
            dist = vlen(marker.origin - org);
            if (dist <= max_dist && dist < best_dist)
            {
                best = marker;
                best_dist = dist;
            }
        }
        i = i + 1;
    }

    if (best != world)
        return best;

    i = 0;
    best_dist = 99999999;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker))
        {
            dist = vlen(marker.origin - org);
            if (dist < best_dist)
            {
                best = marker;
                best_dist = dist;
            }
        }
        i = i + 1;
    }

    return best;
};

float(entity bot) frogbot_ctf_team =
{
    if (bot == world)
        return 0;
    if (bot.team == RED || bot.team == BLUE)
        return bot.team;
    if (bot.style & CLANRING_RED_TEAM)
        return RED;
    if (bot.style & CLANRING_BLUE_TEAM)
        return BLUE;
    return 0;
};

float(entity a, entity b) frogbot_ctf_same_team =
{
    local float team_a;
    local float team_b;

    team_a = frogbot_ctf_team(a);
    team_b = frogbot_ctf_team(b);
    if (team_a <= 0 || team_b <= 0)
        return FALSE;
    return (team_a == team_b);
};

float() frogbot_ctf_mode_active =
{
    return (clanring_playmode & CLANRING_CAPTURE_THE_FLAG);
};

float() frogbot_ctf_flags_active =
{
    if (!frogbot_ctf_mode_active())
        return FALSE;
    if (clanring_playmode & CLANRING_PRACTICE_MODE)
        return FALSE;
    if (clanring_state & (CLANRING_NULL_FLAG | CLANRING_MATCH_PAUSED))
        return FALSE;
    return TRUE;
};

entity(float my_team) frogbot_ctf_get_own_flag =
{
    if (!frogbot_ctf_mode_active())
        return world;
    if (my_team == RED)
        return find(world, classname, "item_flag_team1");
    if (my_team == BLUE)
        return find(world, classname, "item_flag_team2");
    return world;
};

entity(float my_team) frogbot_ctf_get_enemy_flag =
{
    if (!frogbot_ctf_mode_active())
        return world;
    if (my_team == RED)
        return find(world, classname, "item_flag_team2");
    if (my_team == BLUE)
        return find(world, classname, "item_flag_team1");
    return world;
};

float(entity flag_ent) frogbot_ctf_flag_state =
{
    if (!frogbot_ctf_flags_active() || flag_ent == world)
        return FLAG_AT_BASE;
    if (flag_ent.cnt == FLAG_CARRIED)
        return FLAG_CARRIED;
    if (flag_ent.cnt == FLAG_DROPPED)
        return FLAG_DROPPED;
    return FLAG_AT_BASE;
};

float(entity flag_ent) frogbot_ctf_flag_key_bit =
{
    if (flag_ent == world)
        return 0;
    if (flag_ent.classname == "item_flag_team1")
        return IT_KEY2;
    if (flag_ent.classname == "item_flag_team2")
        return IT_KEY1;
    return (flag_ent.items & (IT_KEY1 | IT_KEY2));
};

entity(entity flag_ent) frogbot_ctf_flag_carrier =
{
    local entity carrier;
    local entity p;
    local float key_bit;

    if (!frogbot_ctf_flags_active() || flag_ent == world)
        return world;
    if (frogbot_ctf_flag_state(flag_ent) != FLAG_CARRIED)
        return world;

    key_bit = frogbot_ctf_flag_key_bit(flag_ent);
    carrier = flag_ent.owner;
    if (carrier != world
        && carrier.classname == "player"
        && (carrier.style & CLANRING_CONNECTED)
        && !(carrier.style & CLANRING_OBSERVER)
        && carrier.deadflag == DEAD_NO
        && carrier.health > 0)
    {
        if (carrier.flag_carrier || key_bit <= 0 || (carrier.items & key_bit))
            return carrier;
    }

    p = nextent(world);
    while (p != world)
    {
        if (p.classname == "player"
            && (p.style & CLANRING_CONNECTED)
            && !(p.style & CLANRING_OBSERVER)
            && p.deadflag == DEAD_NO
            && p.health > 0
            && p.flag_carrier)
        {
            if (key_bit <= 0 || (p.items & key_bit))
                return p;
        }
        p = nextent(p);
    }

    return world;
};

float(entity bot) frogbot_ctf_bot_has_enemy_flag =
{
    local float team;
    local float enemy_key;
    local entity enemy_flag;

    if (bot == world || !frogbot_ctf_flags_active())
        return FALSE;

    team = frogbot_ctf_team(bot);
    if (team <= 0)
        return FALSE;

    enemy_flag = frogbot_ctf_get_enemy_flag(team);
    if (frogbot_ctf_flag_carrier(enemy_flag) == bot)
        return TRUE;

    enemy_key = (team == RED) ? IT_KEY1 : IT_KEY2;
    if (bot.items & enemy_key)
        return TRUE;
    return FALSE;
};

float() frogbot_ctf_state_signature =
{
    local entity red_flag;
    local entity blue_flag;
    local entity carrier;
    local float red_state;
    local float blue_state;
    local float red_carrier_num;
    local float blue_carrier_num;
    local float sig;

    if (!frogbot_ctf_flags_active())
        return 0;

    red_flag = find(world, classname, "item_flag_team1");
    blue_flag = find(world, classname, "item_flag_team2");
    if (red_flag == world && blue_flag == world)
        return 0;

    red_state = frogbot_ctf_flag_state(red_flag);
    blue_state = frogbot_ctf_flag_state(blue_flag);

    carrier = frogbot_ctf_flag_carrier(red_flag);
    if (carrier == world)
        red_carrier_num = 0;
    else
        red_carrier_num = (num_for_edict(carrier) % 251);

    carrier = frogbot_ctf_flag_carrier(blue_flag);
    if (carrier == world)
        blue_carrier_num = 0;
    else
        blue_carrier_num = (num_for_edict(carrier) % 251);

    sig = 1;
    sig = sig * 7 + red_state;
    sig = sig * 7 + blue_state;
    sig = sig * 257 + red_carrier_num;
    sig = sig * 257 + blue_carrier_num;
    return sig;
};

void() frogbot_ctf_clear_route_cache =
{
    frogbot_ctf_red_base_marker = world;
    frogbot_ctf_blue_base_marker = world;
    frogbot_ctf_red_drop_marker = world;
    frogbot_ctf_blue_drop_marker = world;
    frogbot_ctf_last_red_state = FLAG_AT_BASE;
    frogbot_ctf_last_blue_state = FLAG_AT_BASE;
    frogbot_ctf_next_anchor_refresh = 0;
};

entity(entity flag_ent) frogbot_ctf_flag_base_marker =
{
    if (flag_ent == world)
        return world;
    if (flag_ent.classname == "item_flag_team1")
        return frogbot_ctf_red_base_marker;
    if (flag_ent.classname == "item_flag_team2")
        return frogbot_ctf_blue_base_marker;
    return world;
};

entity(entity flag_ent) frogbot_ctf_flag_drop_marker =
{
    if (flag_ent == world)
        return world;
    if (flag_ent.classname == "item_flag_team1")
        return frogbot_ctf_red_drop_marker;
    if (flag_ent.classname == "item_flag_team2")
        return frogbot_ctf_blue_drop_marker;
    return world;
};

void() frogbot_ctf_refresh_base_markers =
{
    local entity red_flag;
    local entity blue_flag;
    local vector base_org;

    if (!frogbot_routes_loaded || frogbot_marker_count <= 0)
        return;

    red_flag = find(world, classname, "item_flag_team1");
    blue_flag = find(world, classname, "item_flag_team2");

    if (red_flag != world && !frogbot_is_marker_entity(frogbot_ctf_red_base_marker))
    {
        base_org = red_flag.oldorigin;
        if (vlen(base_org - red_flag.origin) > 4096)
            base_org = red_flag.origin;
        frogbot_ctf_red_base_marker = frogbot_ctf_find_nearest_marker_to_origin(base_org, 640);
        if (!frogbot_is_marker_entity(frogbot_ctf_red_base_marker))
            frogbot_ctf_red_base_marker = frogbot_ctf_find_nearest_marker_to_origin(base_org, 0);
    }

    if (blue_flag != world && !frogbot_is_marker_entity(frogbot_ctf_blue_base_marker))
    {
        base_org = blue_flag.oldorigin;
        if (vlen(base_org - blue_flag.origin) > 4096)
            base_org = blue_flag.origin;
        frogbot_ctf_blue_base_marker = frogbot_ctf_find_nearest_marker_to_origin(base_org, 640);
        if (!frogbot_is_marker_entity(frogbot_ctf_blue_base_marker))
            frogbot_ctf_blue_base_marker = frogbot_ctf_find_nearest_marker_to_origin(base_org, 0);
    }
};

void() frogbot_ctf_refresh_drop_markers =
{
    local entity red_flag;
    local entity blue_flag;
    local float red_state;
    local float blue_state;
    local float red_need_refresh;
    local float blue_need_refresh;

    if (!frogbot_routes_loaded || frogbot_marker_count <= 0)
        return;

    red_flag = find(world, classname, "item_flag_team1");
    blue_flag = find(world, classname, "item_flag_team2");
    red_state = frogbot_ctf_flag_state(red_flag);
    blue_state = frogbot_ctf_flag_state(blue_flag);

    if (red_state == FLAG_DROPPED && red_flag != world)
    {
        red_need_refresh = (frogbot_ctf_last_red_state != FLAG_DROPPED || !frogbot_is_marker_entity(frogbot_ctf_red_drop_marker));
        if (!red_need_refresh && vlen(frogbot_ctf_red_drop_marker.origin - red_flag.origin) > 72)
            red_need_refresh = TRUE;
        if (red_need_refresh)
        {
            frogbot_ctf_red_drop_marker = frogbot_ctf_find_nearest_marker_to_origin(red_flag.origin, 256);
            if (!frogbot_is_marker_entity(frogbot_ctf_red_drop_marker))
                frogbot_ctf_red_drop_marker = frogbot_ctf_find_nearest_marker_to_origin(red_flag.origin, 0);
        }
    }
    else
    {
        frogbot_ctf_red_drop_marker = world;
    }

    if (blue_state == FLAG_DROPPED && blue_flag != world)
    {
        blue_need_refresh = (frogbot_ctf_last_blue_state != FLAG_DROPPED || !frogbot_is_marker_entity(frogbot_ctf_blue_drop_marker));
        if (!blue_need_refresh && vlen(frogbot_ctf_blue_drop_marker.origin - blue_flag.origin) > 72)
            blue_need_refresh = TRUE;
        if (blue_need_refresh)
        {
            frogbot_ctf_blue_drop_marker = frogbot_ctf_find_nearest_marker_to_origin(blue_flag.origin, 256);
            if (!frogbot_is_marker_entity(frogbot_ctf_blue_drop_marker))
                frogbot_ctf_blue_drop_marker = frogbot_ctf_find_nearest_marker_to_origin(blue_flag.origin, 0);
        }
    }
    else
    {
        frogbot_ctf_blue_drop_marker = world;
    }

    frogbot_ctf_last_red_state = red_state;
    frogbot_ctf_last_blue_state = blue_state;
};

void() frogbot_ctf_refresh_anchor_cache =
{
    if (!frogbot_ctf_flags_active())
        return;
    if (!frogbot_routes_loaded || frogbot_marker_count <= 0)
        return;
    if (frogbot_ctf_next_anchor_refresh > time)
        return;

    frogbot_ctf_next_anchor_refresh = time + 0.4;
    frogbot_ctf_refresh_base_markers();
    frogbot_ctf_refresh_drop_markers();
};

float(entity p) frogbot_rune_scale_res =
{
    local float value;

    if (p == world)
        return 1;
    if (!(p.player_flag & ITEM_RUNE1_FLAG))
        return 1;

    value = cvar("k_ctf_rune_power_res");
    if (value <= 0)
        value = 2;

    return max(0.1, (value / 2) + 1);
};

float(entity p) frogbot_rune_scale_str =
{
    local float value;

    if (p == world)
        return 1;
    if (!(p.player_flag & ITEM_RUNE2_FLAG))
        return 1;

    value = cvar("k_ctf_rune_power_str");
    if (value <= 0)
        value = 2;

    return max(0.1, (value / 2) + 1);
};

float(entity p) frogbot_rune_scale_hst =
{
    local float value;

    if (p == world)
        return 1;
    if (!(p.player_flag & ITEM_RUNE3_FLAG))
        return 1;

    value = cvar("k_ctf_rune_power_hst");
    if (value <= 0)
        value = 2;

    return max(0.1, (value / 2) + 1);
};

float(entity bot) frogbot_ctf_objectives_enabled =
{
    if (cvar("frogbot_ctf_objectives") <= 0)
        return FALSE;
    if (!frogbot_ctf_flags_active())
        return FALSE;
    if (!teamplay)
        return FALSE;
    if (bot == world)
        return TRUE;
    if (!frogbot_is_bot_client(bot))
        return FALSE;
    if (!(bot.style & CLANRING_CONNECTED))
        return FALSE;
    if (bot.style & CLANRING_OBSERVER)
        return FALSE;
    if (bot.deadflag != DEAD_NO || bot.health <= 0)
        return FALSE;
    return TRUE;
};

float() frogbot_ctf_disable_camp_mode =
{
    return frogbot_ctf_mode_active();
};

float(float base_range) frogbot_ctf_adjust_combat_range =
{
    if (!frogbot_ctf_mode_active())
        return base_range;
    return base_range * 1.15;
};

float(float arena_mode) frogbot_ctf_prefer_close_non_projectile_dist =
{
    if (frogbot_ctf_mode_active())
        return 280;
    if (arena_mode)
        return 300;
    return 340;
};

float(float arena_mode) frogbot_ctf_shotgun_far_switch_dist =
{
    if (frogbot_ctf_mode_active())
        return 620;
    if (arena_mode)
        return 680;
    return 750;
};

float(float weapon, float default_range) frogbot_ctf_adjust_weapon_max_range =
{
    if (!frogbot_ctf_mode_active())
        return default_range;
    if (weapon == IT_SHOTGUN)
        return 460;
    if (weapon == IT_SUPER_SHOTGUN)
        return 380;
    if (weapon == IT_LIGHTNING)
        return 950;
    return default_range;
};

float(entity p) frogbot_ctf_player_strength =
{
    local float strength;

    if (p == world || p.health <= 0)
        return 0;

    strength = p.health + max(0, p.armorvalue) * bound(0, p.armortype, 1);
    strength = max(strength, p.health);
    return strength * frogbot_rune_scale_res(p);
};

entity(entity bot, entity friendly_carrier, entity enemy_carrier) frogbot_ctf_pick_escort_target =
{
    local entity p;
    local entity best_outmatched;
    local entity best_attacker;
    local float best_outmatched_dist;
    local float best_attacker_dist;
    local float bot_to_p_dist;
    local float enemy_dist;
    local float p_strength;
    local float enemy_strength;
    local float under_pressure;

    if (friendly_carrier != world
        && friendly_carrier != bot
        && friendly_carrier.deadflag == DEAD_NO
        && friendly_carrier.health > 0)
    {
        return friendly_carrier;
    }

    best_outmatched = world;
    best_attacker = world;
    best_outmatched_dist = 999999;
    best_attacker_dist = 999999;
    enemy_strength = frogbot_ctf_player_strength(enemy_carrier);

    p = nextent(world);
    while (p != world)
    {
        if (p != bot
            && frogbot_is_bot_client(p)
            && (p.style & CLANRING_CONNECTED)
            && !(p.style & CLANRING_OBSERVER)
            && p.deadflag == DEAD_NO
            && p.health > 0
            && frogbot_ctf_same_team(bot, p))
        {
            bot_to_p_dist = vlen(bot.origin - p.origin);

            // Priority 2: teammate contesting enemy carrier while outmatched.
            if (enemy_carrier != world && enemy_strength > 0)
            {
                enemy_dist = vlen(p.origin - enemy_carrier.origin);
                if (p.fb_enemy_target == enemy_carrier || enemy_dist <= 320)
                {
                    p_strength = frogbot_ctf_player_strength(p);
                    if (p_strength + 35 < enemy_strength
                        && bot_to_p_dist < best_outmatched_dist)
                    {
                        best_outmatched = p;
                        best_outmatched_dist = bot_to_p_dist;
                    }
                }
            }

            // Priority 3: nearby attacker under pressure.
            if (p.fb_ctf_role == FROGBOT_CTF_ROLE_ATTACK)
            {
                under_pressure = FALSE;
                if (p.fb_enemy_target != world)
                    under_pressure = TRUE;
                if (p.health + p.armorvalue * p.armortype < 120)
                    under_pressure = TRUE;

                if (under_pressure && bot_to_p_dist < best_attacker_dist)
                {
                    best_attacker = p;
                    best_attacker_dist = bot_to_p_dist;
                }
            }
        }
        p = nextent(p);
    }

    if (best_outmatched != world)
        return best_outmatched;
    if (best_attacker != world)
        return best_attacker;
    return world;
};

float(entity bot, entity combat_target, float combat_has_los, float combat_dist, vector route_delta, float route_dist) frogbot_ctf_apply_hook_transit =
{
    local float in_close_duel;
    local float has_enemy_flag;
    local float carrier_escape;
    local float should_hook;
    local float burst_duration;
    local float burst_gap;
    local vector aim;

    if (!frogbot_ctf_objectives_enabled(bot))
        return FALSE;
    if (cvar("frogbot_ctf_hook_transit") <= 0)
        return FALSE;
    if (clanring_playmode & CLANRING_NO_HOOK)
        return FALSE;
    if (!(bot.items & IT_HOOK))
        return FALSE;
    if (bot.waterlevel > 1)
        return FALSE;
    if (bot.fb_rj_pending)
        return FALSE;
    if (bot.flags & FL_WATERJUMP)
        return FALSE;
    if (route_dist < 140 || vlen(route_delta) <= 1)
        return FALSE;

    in_close_duel = (combat_target != world && combat_has_los && combat_dist <= 360);
    if (in_close_duel)
    {
        bot.fb_ctf_hook_burst_until = 0;
        bot.fb_ctf_next_hook_burst_time = time + 0.35 + random() * 0.35;
        if (bot.weapon == IT_HOOK)
            bot.button0 = 0;
        return FALSE;
    }

    has_enemy_flag = frogbot_ctf_bot_has_enemy_flag(bot);
    carrier_escape = FALSE;
    if (has_enemy_flag)
    {
        if (bot.fb_combat_escape_until > time)
            carrier_escape = TRUE;
        else if (combat_target == world || !combat_has_los || combat_dist > 460)
            carrier_escape = TRUE;
    }

    should_hook = FALSE;
    if (combat_target == world && route_dist >= 300)
        should_hook = TRUE;
    if (carrier_escape && route_dist >= 170)
        should_hook = TRUE;

    if (!should_hook)
    {
        bot.fb_ctf_hook_burst_until = 0;
        return FALSE;
    }

    if (bot.fb_ctf_hook_burst_until <= time)
    {
        if (bot.fb_ctf_next_hook_burst_time > time)
            return FALSE;

        if (carrier_escape)
        {
            burst_duration = 0.6 + random() * 0.4;
            burst_gap = 0.2 + random() * 0.25;
        }
        else
        {
            burst_duration = 0.35 + random() * 0.3;
            burst_gap = 0.8 + random() * 0.6;
        }
        bot.fb_ctf_hook_burst_until = time + burst_duration;
        bot.fb_ctf_next_hook_burst_time = time + burst_gap;
    }

    aim = vectoangles(route_delta);
    bot.v_angle = aim;
    bot.angles = aim;
    bot.fixangle = TRUE;

    if (bot.weapon != IT_HOOK)
    {
        bot.weapon = IT_HOOK;
        W_SetCurrentAmmo();
    }

    bot.button0 = 1;
    bot.movement_x = max(180, bot.movement_x);
    return TRUE;
};

void(entity bot) frogbot_ctf_set_role_focus =
{
    local float team;
    local entity own_flag;
    local entity enemy_flag;
    local entity enemy_carrier;
    local entity friendly_carrier;

    team = frogbot_ctf_team(bot);
    own_flag = frogbot_ctf_get_own_flag(team);
    enemy_flag = frogbot_ctf_get_enemy_flag(team);
    enemy_carrier = frogbot_ctf_flag_carrier(own_flag);
    friendly_carrier = frogbot_ctf_flag_carrier(enemy_flag);

    bot.fb_ctf_focus_ent = world;
    bot.fb_ctf_escort_target = world;
    if (enemy_carrier != world && frogbot_is_marker_entity(enemy_carrier.fb_current_marker))
        bot.fb_ctf_last_enemy_carrier_marker = enemy_carrier.fb_current_marker;

    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ESCORT)
    {
        bot.fb_ctf_escort_target = frogbot_ctf_pick_escort_target(bot, friendly_carrier, enemy_carrier);
        if (bot.fb_ctf_escort_target != world)
        {
            bot.fb_ctf_focus_ent = bot.fb_ctf_escort_target;
            return;
        }
    }

    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND)
    {
        if (enemy_carrier != world)
            bot.fb_ctf_focus_ent = enemy_carrier;
        else
            bot.fb_ctf_focus_ent = own_flag;
        return;
    }

    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ATTACK)
    {
        if (frogbot_ctf_bot_has_enemy_flag(bot))
            bot.fb_ctf_focus_ent = own_flag;
        else
            bot.fb_ctf_focus_ent = enemy_flag;
    }
};

void(entity bot) frogbot_ctf_assign_role =
{
    local entity p;
    local float team;
    local float bot_count;
    local float count_attack;
    local float count_defend;
    local float count_escort;
    local float attack_target;
    local float defend_target;
    local float escort_target;
    local float own_state;
    local float enemy_state;
    local entity own_flag;
    local entity enemy_flag;
    local entity enemy_carrier;
    local entity friendly_carrier;
    local float need_attack;
    local float need_defend;
    local float need_escort;
    local float new_role;
    local float old_role;
    local float interval;
    local float jitter;
    local float hold_time;
    local float total_targets;
    local float best_need;

    team = frogbot_ctf_team(bot);
    interval = cvar("frogbot_ctf_role_interval");
    if (interval <= 0)
        interval = 5;
    jitter = cvar("frogbot_ctf_role_jitter");
    if (jitter < 0)
        jitter = 0;
    bot.fb_ctf_next_role_eval = time + interval + random() * jitter;

    if (team <= 0 || !frogbot_ctf_objectives_enabled(bot))
    {
        bot.fb_ctf_role = FROGBOT_CTF_ROLE_ROAM;
        bot.fb_ctf_role_until = time + 2;
        bot.fb_ctf_focus_ent = world;
        bot.fb_ctf_escort_target = world;
        return;
    }

    own_flag = frogbot_ctf_get_own_flag(team);
    enemy_flag = frogbot_ctf_get_enemy_flag(team);
    own_state = frogbot_ctf_flag_state(own_flag);
    enemy_state = frogbot_ctf_flag_state(enemy_flag);
    enemy_carrier = frogbot_ctf_flag_carrier(own_flag);
    friendly_carrier = frogbot_ctf_flag_carrier(enemy_flag);

    if (friendly_carrier == bot)
    {
        bot.fb_ctf_role = FROGBOT_CTF_ROLE_ATTACK;
        bot.fb_ctf_role_until = time + max(2, interval * 0.8);
        frogbot_ctf_set_role_focus(bot);
        return;
    }

    bot_count = 0;
    count_attack = 0;
    count_defend = 0;
    count_escort = 0;
    p = nextent(world);
    while (p != world)
    {
        if (frogbot_is_bot_client(p)
            && (p.style & CLANRING_CONNECTED)
            && !(p.style & CLANRING_OBSERVER)
            && p.deadflag == DEAD_NO
            && p.health > 0
            && frogbot_ctf_same_team(bot, p))
        {
            bot_count = bot_count + 1;
            if (p != bot)
            {
                if (p.fb_ctf_role == FROGBOT_CTF_ROLE_ATTACK)
                    count_attack = count_attack + 1;
                else if (p.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND)
                    count_defend = count_defend + 1;
                else if (p.fb_ctf_role == FROGBOT_CTF_ROLE_ESCORT)
                    count_escort = count_escort + 1;
            }
        }
        p = nextent(p);
    }
    if (bot_count < 1)
        bot_count = 1;

    attack_target = 1;
    defend_target = (bot_count >= 2) ? 1 : 0;
    escort_target = 0;

    if (friendly_carrier != world && friendly_carrier != bot && bot_count >= 2)
        escort_target = 1;

    if (own_state == FLAG_DROPPED || own_state == FLAG_CARRIED || enemy_carrier != world)
        defend_target = min(bot_count, max(defend_target, 2));

    if (enemy_state == FLAG_DROPPED && friendly_carrier == world && bot_count >= 3)
        attack_target = max(attack_target, 2);

    if (own_state == FLAG_CARRIED && enemy_state == FLAG_CARRIED)
    {
        if (friendly_carrier != world && friendly_carrier != bot && bot_count >= 2)
            escort_target = max(escort_target, 1);
        defend_target = max(defend_target, 1);
        if (bot_count >= 4)
            attack_target = max(attack_target, 1);
    }

    total_targets = attack_target + defend_target + escort_target;
    while (total_targets > bot_count)
    {
        if (attack_target > 1)
            attack_target = attack_target - 1;
        else if (defend_target > 1)
            defend_target = defend_target - 1;
        else if (escort_target > 0)
            escort_target = escort_target - 1;
        else
            break;
        total_targets = attack_target + defend_target + escort_target;
    }

    need_attack = attack_target - count_attack;
    need_defend = defend_target - count_defend;
    need_escort = escort_target - count_escort;

    new_role = FROGBOT_CTF_ROLE_ROAM;
    if (friendly_carrier != world && friendly_carrier != bot && need_escort > 0)
    {
        new_role = FROGBOT_CTF_ROLE_ESCORT;
    }
    else
    {
        best_need = 0;
        if (need_defend > best_need)
        {
            best_need = need_defend;
            new_role = FROGBOT_CTF_ROLE_DEFEND;
        }
        if (need_attack > best_need)
        {
            best_need = need_attack;
            new_role = FROGBOT_CTF_ROLE_ATTACK;
        }
        if (need_escort > best_need)
        {
            best_need = need_escort;
            new_role = FROGBOT_CTF_ROLE_ESCORT;
        }
        if (best_need <= 0)
        {
            if (enemy_carrier != world || own_state != FLAG_AT_BASE)
                new_role = FROGBOT_CTF_ROLE_DEFEND;
            else
                new_role = FROGBOT_CTF_ROLE_ATTACK;
        }
    }

    old_role = bot.fb_ctf_role;
    if (old_role <= 0)
        old_role = FROGBOT_CTF_ROLE_ROAM;
    if (bot.fb_ctf_role_until > time && new_role != old_role)
        new_role = old_role;
    if (new_role <= 0)
        new_role = FROGBOT_CTF_ROLE_ROAM;

    bot.fb_ctf_role = new_role;
    hold_time = max(2, interval * 0.8);
    bot.fb_ctf_role_until = time + hold_time;
    frogbot_ctf_set_role_focus(bot);
};

float(entity bot) frogbot_ctf_comms_enabled =
{
    if (!frogbot_ctf_objectives_enabled(bot))
        return FALSE;
    if (cvar("frogbot_ctf_comms") <= 0)
        return FALSE;
    return TRUE;
};

float(entity bot, string msg) frogbot_ctf_team_msg =
{
    local float cooldown;

    if (!frogbot_ctf_comms_enabled(bot))
        return FALSE;
    if (msg == "")
        return FALSE;
    if (bot.fb_ctf_next_msg_time > time)
        return FALSE;

    cooldown = cvar("frogbot_ctf_comms_cooldown");
    if (cooldown <= 0)
        cooldown = 10;
    if (!frogbot_team_say(bot, msg))
        return FALSE;

    bot.fb_ctf_next_msg_time = time + cooldown;
    return TRUE;
};

void(entity bot, float own_state, float enemy_state, entity own_flag, entity enemy_flag, entity enemy_carrier, entity friendly_carrier) frogbot_ctf_process_state_comms =
{
    local float prev_own_state;
    local float prev_enemy_state;
    local entity prev_enemy_carrier;
    local entity prev_friendly_carrier;
    local entity own_base_marker;
    local entity own_drop_marker;
    local entity carrier_marker;
    local float team_bots;
    local float drop_quota;
    local float carrier_quota;
    local float should_call;
    local float sent;

    if (bot == world)
        return;

    prev_own_state = bot.fb_ctf_prev_own_state;
    prev_enemy_state = bot.fb_ctf_prev_enemy_state;
    prev_enemy_carrier = bot.fb_ctf_prev_enemy_carrier;
    prev_friendly_carrier = bot.fb_ctf_prev_friendly_carrier;
    own_base_marker = frogbot_ctf_flag_base_marker(own_flag);
    own_drop_marker = frogbot_ctf_flag_drop_marker(own_flag);
    sent = FALSE;

    if (frogbot_ctf_comms_enabled(bot) && prev_own_state >= 0 && prev_enemy_state >= 0)
    {
        team_bots = frogbot_ctf_team_bot_count(bot);
        drop_quota = (team_bots <= 4) ? 1 : 2;
        carrier_quota = (team_bots <= 3) ? 1 : ((team_bots <= 6) ? 2 : 3);

        // Carrier asks for cover exactly on transition to carrying.
        if (!sent && friendly_carrier == bot && prev_friendly_carrier != bot)
            sent = frogbot_ctf_team_msg(bot, "cover me");

        // Return call when own flag just dropped.
        if (!sent && own_state == FLAG_DROPPED && prev_own_state != FLAG_DROPPED)
        {
            should_call = (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND);
            if (!should_call)
                should_call = frogbot_ctf_is_priority_responder(bot, own_drop_marker, drop_quota, TRUE);
            if (should_call)
                sent = frogbot_ctf_team_msg(bot, "return our flag");
        }

        // Enemy carrier call on new carrier acquisition.
        if (!sent && enemy_carrier != world && prev_enemy_carrier != enemy_carrier)
        {
            carrier_marker = world;
            if (frogbot_is_marker_entity(enemy_carrier.fb_current_marker))
                carrier_marker = enemy_carrier.fb_current_marker;
            else if (frogbot_is_marker_entity(bot.fb_ctf_last_enemy_carrier_marker))
                carrier_marker = bot.fb_ctf_last_enemy_carrier_marker;

            should_call = (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND || bot.fb_ctf_role == FROGBOT_CTF_ROLE_ROAM);
            if (!should_call)
                should_call = frogbot_ctf_is_priority_responder(bot, carrier_marker, carrier_quota, FALSE);
            if (should_call)
                sent = frogbot_ctf_team_msg(bot, "enemy carrier");
        }

        // Secure call when our flag returns to base.
        if (!sent && own_state == FLAG_AT_BASE && prev_own_state != FLAG_AT_BASE)
        {
            should_call = (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND);
            if (!should_call)
                should_call = frogbot_ctf_is_priority_responder(bot, own_base_marker, 1, TRUE);
            if (should_call)
                sent = frogbot_ctf_team_msg(bot, "flag secure");
        }
    }

    bot.fb_ctf_prev_own_state = own_state;
    bot.fb_ctf_prev_enemy_state = enemy_state;
    bot.fb_ctf_prev_enemy_carrier = enemy_carrier;
    bot.fb_ctf_prev_friendly_carrier = friendly_carrier;
};

void(entity bot) frogbot_ctf_update_runtime =
{
    local float state_sig;
    local float team;
    local float own_state;
    local float enemy_state;
    local entity escort_anchor;
    local entity own_flag;
    local entity enemy_flag;
    local entity enemy_carrier;
    local entity friendly_carrier;
    local float support_hops;
    local float escort_hops;
    local float hold_time;
    local float has_contact;

    if (bot == world || !frogbot_is_bot_client(bot))
        return;

    if (!frogbot_ctf_objectives_enabled(bot))
    {
        bot.fb_ctf_role = FROGBOT_CTF_ROLE_ROAM;
        bot.fb_ctf_role_until = 0;
        bot.fb_ctf_last_state_sig = 0;
        bot.fb_ctf_focus_ent = world;
        bot.fb_ctf_escort_target = world;
        bot.fb_ctf_last_enemy_carrier_marker = world;
        bot.fb_ctf_prev_own_state = -1;
        bot.fb_ctf_prev_enemy_state = -1;
        bot.fb_ctf_prev_enemy_carrier = world;
        bot.fb_ctf_prev_friendly_carrier = world;
        bot.fb_ctf_hook_burst_until = 0;
        bot.fb_ctf_next_hook_burst_time = 0;
        if (bot.fb_ctf_next_role_eval <= time)
            bot.fb_ctf_next_role_eval = time + 2 + random() * 2;
        return;
    }

    team = frogbot_ctf_team(bot);
    own_flag = frogbot_ctf_get_own_flag(team);
    enemy_flag = frogbot_ctf_get_enemy_flag(team);
    own_state = frogbot_ctf_flag_state(own_flag);
    enemy_state = frogbot_ctf_flag_state(enemy_flag);
    enemy_carrier = frogbot_ctf_flag_carrier(own_flag);
    friendly_carrier = frogbot_ctf_flag_carrier(enemy_flag);

    if (bot.fb_ctf_next_objective_refresh <= time)
    {
        bot.fb_ctf_next_objective_refresh = time + 0.35 + random() * 0.2;
        frogbot_ctf_refresh_anchor_cache();
    }

    state_sig = frogbot_ctf_state_signature();
    if (bot.fb_ctf_last_state_sig != state_sig)
    {
        bot.fb_ctf_last_state_sig = state_sig;
        bot.fb_ctf_next_role_eval = time;
        bot.fb_ctf_role_until = time;
        bot.fb_ctf_next_objective_refresh = time;
    }

    if (bot.fb_ctf_next_role_eval <= time || bot.fb_ctf_role <= 0)
        frogbot_ctf_assign_role(bot);

    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ESCORT)
    {
        if (bot.fb_ctf_escort_target == world
            || bot.fb_ctf_escort_target.deadflag != DEAD_NO
            || bot.fb_ctf_escort_target.health <= 0)
        {
            frogbot_ctf_set_role_focus(bot);
        }

        escort_anchor = frogbot_ctf_escort_anchor_marker(bot);
        support_hops = cvar("frogbot_ctf_escort_support_hops");
        if (support_hops <= 0)
            support_hops = 2;

        if (frogbot_is_marker_entity(escort_anchor))
        {
            escort_hops = frogbot_ctf_marker_hops_to_anchor(bot, escort_anchor);
            has_contact = (bot.fb_enemy_target != world
                           || bot.fb_team_has_contact > 0
                           || (bot.fb_last_enemy_seen_time > 0 && bot.fb_last_enemy_seen_time + 1.2 > time));
            if (!has_contact && escort_hops <= max(1, support_hops - 1))
            {
                if (bot.fb_ctf_escort_hold_until <= time)
                {
                    hold_time = cvar("frogbot_ctf_escort_hold_time");
                    if (hold_time <= 0)
                        hold_time = 1.5;
                    bot.fb_ctf_escort_hold_until = time + hold_time * (0.7 + random() * 0.6);
                }
            }
            else if (has_contact || escort_hops > support_hops + 1)
            {
                bot.fb_ctf_escort_hold_until = 0;
            }
        }
        else
        {
            bot.fb_ctf_escort_hold_until = 0;
        }
    }
    else
    {
        bot.fb_ctf_escort_hold_until = 0;
    }

    frogbot_ctf_process_state_comms(bot, own_state, enemy_state, own_flag, enemy_flag, enemy_carrier, friendly_carrier);
};

float(entity bot) frogbot_ctf_team_bot_count =
{
    local entity p;
    local float count;

    count = 0;
    p = nextent(world);
    while (p != world)
    {
        if (frogbot_is_bot_client(p)
            && (p.style & CLANRING_CONNECTED)
            && !(p.style & CLANRING_OBSERVER)
            && p.deadflag == DEAD_NO
            && p.health > 0
            && frogbot_ctf_same_team(bot, p))
        {
            count = count + 1;
        }
        p = nextent(p);
    }

    if (count < 1)
        count = 1;
    return count;
};

float(entity bot, entity anchor_marker) frogbot_ctf_marker_hops_to_anchor =
{
    local entity step_marker;
    local float hops;
    local float max_hops;

    if (bot == world)
        return 999;
    if (!frogbot_is_marker_entity(bot.fb_current_marker) || !frogbot_is_marker_entity(anchor_marker))
        return 999;
    if (bot.fb_current_marker == anchor_marker)
        return 0;

    step_marker = bot.fb_current_marker;
    max_hops = 24;
    hops = 1;
    while (hops <= max_hops)
    {
        step_marker = frogbot_zone_next_marker(step_marker, anchor_marker, FALSE);
        if (!frogbot_is_marker_entity(step_marker))
            break;
        if (step_marker == anchor_marker)
            return hops;
        hops = hops + 1;
    }

    return 999;
};

entity(entity bot) frogbot_ctf_escort_anchor_marker =
{
    if (bot == world)
        return world;
    if (bot.fb_ctf_role != FROGBOT_CTF_ROLE_ESCORT)
        return world;
    if (bot.fb_ctf_escort_target == world)
        return world;
    if (bot.fb_ctf_escort_target.deadflag != DEAD_NO || bot.fb_ctf_escort_target.health <= 0)
        return world;
    if (frogbot_is_marker_entity(bot.fb_ctf_escort_target.fb_current_marker))
        return bot.fb_ctf_escort_target.fb_current_marker;
    return world;
};

float(entity bot, entity anchor_marker, float quota, float ignore_carrier_bots) frogbot_ctf_is_priority_responder =
{
    local entity p;
    local float bot_dist;
    local float other_dist;
    local float rank;

    if (bot == world || !frogbot_is_marker_entity(anchor_marker))
        return FALSE;
    if (quota < 1)
        quota = 1;
    if (ignore_carrier_bots && frogbot_ctf_bot_has_enemy_flag(bot))
        return FALSE;

    bot_dist = vlen(bot.origin - anchor_marker.origin);
    rank = 0;

    p = nextent(world);
    while (p != world)
    {
        if (p != bot
            && frogbot_is_bot_client(p)
            && (p.style & CLANRING_CONNECTED)
            && !(p.style & CLANRING_OBSERVER)
            && p.deadflag == DEAD_NO
            && p.health > 0
            && frogbot_ctf_same_team(bot, p))
        {
            if (!(ignore_carrier_bots && frogbot_ctf_bot_has_enemy_flag(p)))
            {
                other_dist = vlen(p.origin - anchor_marker.origin);
                if (other_dist + 48 < bot_dist)
                    rank = rank + 1;
            }
        }
        p = nextent(p);
    }

    return (rank < quota);
};

entity(entity bot) frogbot_ctf_route_anchor =
{
    local float team;
    local float own_state;
    local float enemy_state;
    local entity own_flag;
    local entity enemy_flag;
    local entity enemy_carrier;
    local entity friendly_carrier;
    local entity own_base_marker;
    local entity enemy_base_marker;
    local entity own_drop_marker;
    local entity enemy_drop_marker;
    local float team_bot_count;
    local float drop_quota;
    local float intercept_quota;
    local float drop_priority;
    local float intercept_priority;
    local float chase_enemy_carrier;
    local entity escort_anchor;

    if (!frogbot_ctf_objectives_enabled(bot))
        return world;

    frogbot_ctf_refresh_anchor_cache();
    team = frogbot_ctf_team(bot);
    if (team <= 0)
        return world;

    own_flag = frogbot_ctf_get_own_flag(team);
    enemy_flag = frogbot_ctf_get_enemy_flag(team);
    own_state = frogbot_ctf_flag_state(own_flag);
    enemy_state = frogbot_ctf_flag_state(enemy_flag);
    enemy_carrier = frogbot_ctf_flag_carrier(own_flag);
    friendly_carrier = frogbot_ctf_flag_carrier(enemy_flag);
    own_base_marker = frogbot_ctf_flag_base_marker(own_flag);
    enemy_base_marker = frogbot_ctf_flag_base_marker(enemy_flag);
    own_drop_marker = frogbot_ctf_flag_drop_marker(own_flag);
    enemy_drop_marker = frogbot_ctf_flag_drop_marker(enemy_flag);
    team_bot_count = frogbot_ctf_team_bot_count(bot);
    drop_quota = (team_bot_count <= 4) ? 1 : 2;
    intercept_quota = (team_bot_count <= 3) ? 1 : ((team_bot_count <= 6) ? 2 : 3);
    drop_priority = frogbot_ctf_is_priority_responder(bot, own_drop_marker, drop_quota, TRUE);
    intercept_priority = frogbot_ctf_is_priority_responder(bot, bot.fb_ctf_last_enemy_carrier_marker, intercept_quota, FALSE);
    if (enemy_carrier != world && frogbot_is_marker_entity(enemy_carrier.fb_current_marker))
        intercept_priority = frogbot_ctf_is_priority_responder(bot, enemy_carrier.fb_current_marker, intercept_quota, FALSE);
    chase_enemy_carrier = (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND || bot.fb_ctf_role == FROGBOT_CTF_ROLE_ROAM);
    if (friendly_carrier == world)
        chase_enemy_carrier = TRUE;
    if (intercept_priority)
        chase_enemy_carrier = TRUE;

    if (frogbot_ctf_bot_has_enemy_flag(bot))
    {
        if (frogbot_is_marker_entity(own_base_marker))
            return own_base_marker;
    }

    if (own_state == FLAG_DROPPED)
    {
        if ((drop_priority || bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND)
            && frogbot_is_marker_entity(own_drop_marker))
            return own_drop_marker;
        if ((drop_priority || bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND || bot.fb_ctf_role == FROGBOT_CTF_ROLE_ROAM)
            && frogbot_is_marker_entity(own_base_marker))
            return own_base_marker;
    }

    if (enemy_carrier != world && chase_enemy_carrier)
    {
        if (frogbot_is_marker_entity(enemy_carrier.fb_current_marker))
            return enemy_carrier.fb_current_marker;
        if (frogbot_is_marker_entity(bot.fb_ctf_last_enemy_carrier_marker))
            return bot.fb_ctf_last_enemy_carrier_marker;
        if (frogbot_is_marker_entity(own_base_marker))
            return own_base_marker;
    }

    if (own_state == FLAG_CARRIED)
    {
        if (chase_enemy_carrier && frogbot_is_marker_entity(bot.fb_ctf_last_enemy_carrier_marker))
            return bot.fb_ctf_last_enemy_carrier_marker;
        if (chase_enemy_carrier && frogbot_is_marker_entity(own_base_marker))
            return own_base_marker;
    }

    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ESCORT)
    {
        if (bot.fb_ctf_escort_hold_until > time && frogbot_is_marker_entity(bot.fb_current_marker))
            return bot.fb_current_marker;

        escort_anchor = frogbot_ctf_escort_anchor_marker(bot);
        if (frogbot_is_marker_entity(escort_anchor))
            return escort_anchor;

        if (friendly_carrier != world && friendly_carrier != bot
            && frogbot_is_marker_entity(friendly_carrier.fb_current_marker))
            return friendly_carrier.fb_current_marker;
    }

    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND)
    {
        if (frogbot_is_marker_entity(own_base_marker))
            return own_base_marker;
        if (frogbot_is_marker_entity(own_drop_marker))
            return own_drop_marker;
    }

    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ATTACK)
    {
        if (enemy_state == FLAG_DROPPED && frogbot_is_marker_entity(enemy_drop_marker))
            return enemy_drop_marker;
        if (frogbot_is_marker_entity(enemy_base_marker))
            return enemy_base_marker;
    }

    if (frogbot_is_marker_entity(enemy_base_marker))
        return enemy_base_marker;
    if (frogbot_is_marker_entity(own_base_marker))
        return own_base_marker;

    if (enemy_carrier != world && chase_enemy_carrier && frogbot_is_marker_entity(bot.fb_ctf_last_enemy_carrier_marker))
        return bot.fb_ctf_last_enemy_carrier_marker;
    return world;
};

float(entity bot, entity source, string dynamic_classname, float raw_desire) frogbot_ctf_goal_desire_bonus =
{
    local float team;
    local string own_class;
    local string enemy_class;
    local float carrying_enemy_flag;
    local entity own_flag;
    local entity enemy_flag;
    local float own_state;
    local float enemy_state;
    local float urgency;
    local entity own_drop_marker;
    local float drop_priority;
    local float drop_quota;
    local float team_bot_count;
    local float microloot_radius;
    local float microloot_keep;
    local float source_dist;

    if (!frogbot_ctf_objectives_enabled(bot))
        return 0;

    team = frogbot_ctf_team(bot);
    if (team <= 0)
        return 0;

    if (team == RED)
    {
        own_class = "item_flag_team1";
        enemy_class = "item_flag_team2";
    }
    else
    {
        own_class = "item_flag_team2";
        enemy_class = "item_flag_team1";
    }

    carrying_enemy_flag = frogbot_ctf_bot_has_enemy_flag(bot);

    if (carrying_enemy_flag && dynamic_classname != own_class && dynamic_classname != enemy_class)
    {
        microloot_radius = cvar("frogbot_ctf_microloot_radius");
        if (microloot_radius < 0)
            microloot_radius = 0;
        microloot_keep = 0;

        if (microloot_radius > 0 && source != world)
        {
            source_dist = vlen(source.origin - bot.origin);
            if (source_dist <= microloot_radius)
            {
                if (dynamic_classname == "item_health")
                {
                    if (bot.health < 55)
                        microloot_keep = max(microloot_keep, raw_desire * 0.55);
                    else if (bot.health < 85)
                        microloot_keep = max(microloot_keep, raw_desire * 0.25);
                }
                else if (dynamic_classname == "item_armor1"
                         || dynamic_classname == "item_armor2"
                         || dynamic_classname == "item_armorInv")
                {
                    if (bot.armorvalue < 80)
                        microloot_keep = max(microloot_keep, raw_desire * 0.2);
                }
                else if (dynamic_classname == "item_rockets")
                {
                    if (bot.ammo_rockets < 10)
                        microloot_keep = max(microloot_keep, raw_desire * 0.2);
                }
                else if (dynamic_classname == "item_cells")
                {
                    if (bot.ammo_cells < 24)
                        microloot_keep = max(microloot_keep, raw_desire * 0.2);
                }
                else if (dynamic_classname == "item_backpack")
                {
                    microloot_keep = max(microloot_keep, raw_desire * 0.15);
                }
            }
        }

        return -raw_desire + microloot_keep;
    }

    if (dynamic_classname != own_class && dynamic_classname != enemy_class)
        return 0;

    own_flag = frogbot_ctf_get_own_flag(team);
    enemy_flag = frogbot_ctf_get_enemy_flag(team);
    own_state = frogbot_ctf_flag_state(own_flag);
    enemy_state = frogbot_ctf_flag_state(enemy_flag);
    own_drop_marker = frogbot_ctf_flag_drop_marker(own_flag);
    team_bot_count = frogbot_ctf_team_bot_count(bot);
    drop_quota = (team_bot_count <= 4) ? 1 : 2;
    drop_priority = frogbot_ctf_is_priority_responder(bot, own_drop_marker, drop_quota, TRUE);

    if (dynamic_classname == enemy_class)
    {
        if (carrying_enemy_flag)
            return -max(40, raw_desire);
        if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND)
            return 50;
        if (enemy_state == FLAG_DROPPED)
            return 210;
        if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ATTACK)
            return 190;
        return 120;
    }

    urgency = cvar("frogbot_ctf_return_urgency");
    if (urgency <= 0)
        urgency = 1.2;
    if (carrying_enemy_flag && own_state == FLAG_AT_BASE)
        return (260 * urgency);
    if (own_state == FLAG_DROPPED)
    {
        if (drop_priority || bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND)
            return (220 * urgency);
        if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ROAM)
            return (80 * urgency);
        return (-50 * urgency);
    }
    if (own_state == FLAG_CARRIED)
        return (170 * urgency);
    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND)
        return 35;
    return -20;
};

float(entity bot, entity marker, entity next_marker, float path_flags, float current_bonus) frogbot_ctf_route_score_bonus =
{
    local float team;
    local float carrying_enemy_flag;
    local entity anchor;
    local float current_dist;
    local float next_dist;
    local float delta;
    local float bonus;
    local float max_bonus;
    local entity own_flag;
    local entity own_base_marker;
    local entity enemy_carrier;
    local float own_state;
    local float current_base_dist;
    local float next_base_dist;
    local entity escort_anchor;
    local float support_hops;
    local float escort_hops;
    local float escort_close_hops;

    if (!frogbot_ctf_objectives_enabled(bot))
        return 0;
    if (!frogbot_is_marker_entity(marker) || !frogbot_is_marker_entity(next_marker))
        return 0;

    anchor = frogbot_ctf_route_anchor(bot);
    if (anchor == world)
        return 0;
    team = frogbot_ctf_team(bot);
    carrying_enemy_flag = frogbot_ctf_bot_has_enemy_flag(bot);
    own_flag = frogbot_ctf_get_own_flag(team);
    own_state = frogbot_ctf_flag_state(own_flag);
    own_base_marker = frogbot_ctf_flag_base_marker(own_flag);
    enemy_carrier = frogbot_ctf_flag_carrier(own_flag);

    current_dist = vlen(marker.origin - anchor.origin);
    next_dist = vlen(next_marker.origin - anchor.origin);
    delta = current_dist - next_dist;
    if (delta == 0)
        return 0;

    if (delta > 0)
        bonus = delta / 96;
    else
        bonus = delta / 160;

    if (carrying_enemy_flag)
        bonus = bonus * 1.2;
    else if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND)
        bonus = bonus * 1.1;
    else if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ESCORT)
        bonus = bonus * 1.05;

    if (carrying_enemy_flag)
    {
        if (delta > 0)
            bonus = bonus + 3.2;
        else
            bonus = bonus - 2.1;
    }

    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND && frogbot_is_marker_entity(own_base_marker))
    {
        current_base_dist = vlen(marker.origin - own_base_marker.origin);
        next_base_dist = vlen(next_marker.origin - own_base_marker.origin);

        if (own_state == FLAG_AT_BASE && enemy_carrier == world)
        {
            if (next_base_dist > 480)
                bonus = bonus - min(2, (next_base_dist - 480) / 180);
            else if (next_base_dist < current_base_dist)
                bonus = bonus + 0.35;
        }
        else if (next_base_dist < current_base_dist)
        {
            bonus = bonus + 0.2;
        }
    }

    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ESCORT)
    {
        escort_anchor = frogbot_ctf_escort_anchor_marker(bot);
        if (frogbot_is_marker_entity(escort_anchor))
        {
            support_hops = cvar("frogbot_ctf_escort_support_hops");
            if (support_hops <= 0)
                support_hops = 2;
            escort_hops = frogbot_ctf_marker_hops_to_anchor(bot, escort_anchor);
            escort_close_hops = max(1, support_hops - 1);

            if (escort_hops <= escort_close_hops)
            {
                if (delta > 0)
                    bonus = bonus - (1.05 + (escort_close_hops - escort_hops) * 0.45);
                else
                    bonus = bonus + 0.25;
            }
            else if (escort_hops > support_hops && delta > 0)
            {
                bonus = bonus + 0.45;
            }
        }
    }

    max_bonus = carrying_enemy_flag ? 9 : 4;
    return bound(-max_bonus, bonus, max_bonus);
};

float(entity bot, entity target, float score, float has_los) frogbot_ctf_target_score_adjust =
{
    local float team;
    local float bonus;
    local float carrier_bonus;
    local float own_state;
    local float chase_bonus;
    local entity own_flag;
    local entity enemy_carrier;

    if (!frogbot_ctf_objectives_enabled(bot))
        return 0;
    if (target == world)
        return 0;

    team = frogbot_ctf_team(bot);
    if (team <= 0)
        return 0;

    own_flag = frogbot_ctf_get_own_flag(team);
    own_state = frogbot_ctf_flag_state(own_flag);
    enemy_carrier = frogbot_ctf_flag_carrier(own_flag);

    bonus = 0;
    carrier_bonus = cvar("frogbot_ctf_carrier_target_bonus");
    if (carrier_bonus <= 0)
        carrier_bonus = 500;

    if (enemy_carrier != world && target == enemy_carrier)
    {
        if (has_los && frogbot_is_marker_entity(target.fb_current_marker))
            bot.fb_ctf_last_enemy_carrier_marker = target.fb_current_marker;

        chase_bonus = has_los ? carrier_bonus : (carrier_bonus * 0.6);
        if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND || bot.fb_ctf_role == FROGBOT_CTF_ROLE_ROAM)
            chase_bonus = chase_bonus * 1.15;
        bonus = bonus + chase_bonus;
    }

    if (frogbot_ctf_bot_has_enemy_flag(bot) && target != enemy_carrier)
        bonus = bonus - 120;

    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND && own_flag != world)
    {
        if (vlen(target.origin - own_flag.origin) < 600)
            bonus = bonus + 90;
        if (!has_los)
            bonus = bonus - 40;
    }

    if (own_state == FLAG_CARRIED && enemy_carrier == world)
    {
        if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ATTACK)
            bonus = bonus - 70;
        else if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND || bot.fb_ctf_role == FROGBOT_CTF_ROLE_ROAM)
            bonus = bonus + 40;
    }

    return bonus;
};

void(entity bot) frogbot_ctf_reset_runtime_state =
{
    bot.fb_ctf_role = FROGBOT_CTF_ROLE_ROAM;
    bot.fb_ctf_role_until = 0;
    bot.fb_ctf_next_role_eval = time + random();
    bot.fb_ctf_last_state_sig = 0;
    bot.fb_ctf_focus_ent = world;
    bot.fb_ctf_escort_target = world;
    bot.fb_ctf_last_enemy_carrier_marker = world;
    bot.fb_ctf_prev_own_state = -1;
    bot.fb_ctf_prev_enemy_state = -1;
    bot.fb_ctf_prev_enemy_carrier = world;
    bot.fb_ctf_prev_friendly_carrier = world;
    bot.fb_ctf_hook_burst_until = 0;
    bot.fb_ctf_next_hook_burst_time = time + random() * 0.5;
    bot.fb_ctf_next_msg_time = time + random() * 2;
    bot.fb_ctf_next_objective_refresh = time + random() * 0.2;
    bot.fb_ctf_escort_hold_until = 0;
};

void() frogbot_ctf_init_world =
{
    frogbot_ctf_clear_route_cache();
    registercvar("frogbot_ctf_objectives", "1");
    registercvar("frogbot_ctf_role_interval", "5");
    registercvar("frogbot_ctf_role_jitter", "2");
    registercvar("frogbot_ctf_escort_support_hops", "2");
    registercvar("frogbot_ctf_escort_hold_time", "1.5");
    registercvar("frogbot_ctf_microloot_radius", "160");
    registercvar("frogbot_ctf_carrier_target_bonus", "500");
    registercvar("frogbot_ctf_return_urgency", "1.2");
    registercvar("frogbot_ctf_comms", "1");
    registercvar("frogbot_ctf_comms_cooldown", "10");
    registercvar("frogbot_ctf_hook_transit", "0");
};
