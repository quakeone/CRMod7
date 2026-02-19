/*
    frogbot.qc

    Minimal Frogbot integration layer:
    - spawn/remove dummy bot clients
    - load KTX-style map routing .bot files
    - expose admin commands for bot and route management
*/

/*
    ----------------------------------------------------------------------------
    KTX Parity Tracker (CRMod7 Frogbot)
    Last updated: 2026-02-18

    Maintenance note:
    - Update this block whenever a KTX-parity feature is implemented or changed.
    - Status legend: [x] implemented, [~] partial, [ ] missing.

    Already implemented in CRMod7:
    - [x] Navigation: markers, route loading from .bot files, path flags, goal routing
    - [x] Combat: enemy targeting, distance-based weapon choice, aim volatility
    - [x] Skill system: level 0-20 scaling
    - [x] Movement: water handling, stuck recovery, rocket-jump prep/execution
    - [x] Item goals: dynamic markers, item desire calculations, respawn estimation
    - [x] Game mode awareness: DM/CTF/Arena tuning
    - [x] CTF module split: dedicated `frogbot_ctf.qc` for CTF-only bot logic
    - [x] Admin + control: botadd/botkick (admin direct + player vote; botadd gated in Airshot), route reload, debug logging

    High impact parity items:
    - [x] Missile dodging
    - [x] Combat jumping and evasion (dodge/rj + threat-driven escape logic)
    - [~] Teamplay comms (say_team spot/help/lost with anti-spam throttle + .loc location reports)
    - [x] Item desire logic
    - [x] Fire safety checks (splash self-damage avoidance)

    Medium impact parity items:
    - [x] Zone system for smarter routing (zone cache + eta + next-hop + virtual-goal propagation + runtime validation)
    - [x] Camp logic (DM3/DM4/DM6 map-aware anchor selection + hold windows)
    - [x] Powerup awareness (enemy Quad/Pent tracking + aggression/escape bias)
    - [x] Advanced visibility checks (front/360/multi-entity)
    - [x] Skill attributes expansion (dodge amount/time + lookahead/prediction error)
    - [~] CTF objective system (roles/escort/carrier/comms + optional hook transit in; rollout validation/polish pending)

    Lower priority parity items:
    - [ ] DM6 door-specific logic parity
    - [ ] Path debug/editor tooling parity
    - [ ] Physics prediction parity
    - [ ] Bot command queue parity
    - [x] CTF rune system parity (STR/RES/HST-aware bot durability, firepower, splash safety, and nail lead)
    ----------------------------------------------------------------------------
*/

float FROGBOT_MAX_MARKERS = 300;
float FROGBOT_MAX_PATHS = 8;
float FROGBOT_DEFAULT_MAP_DEATH_HEIGHT = -9999999;
string FROGBOT_BUILD_TAG = "frogbot-mswitch-debug-20260211b";

float FROGBOT_PATH_WATERJUMP = (1 << 1);
float FROGBOT_PATH_DM6_DOOR = (1 << 8);
float FROGBOT_PATH_ROCKET_JUMP = (1 << 9);
float FROGBOT_PATH_JUMP_LEDGE = (1 << 10);
float FROGBOT_PATH_VERTICAL_PLATFORM = (1 << 11);
float FROGBOT_PATH_CURLJUMP_HINT = (1 << 23);

float FROGBOT_MARKER_UNREACHABLE = 1;
float FROGBOT_MARKER_IS_DM6_DOOR = 8;
float FROGBOT_MARKER_BLOCKED_ON_STATE_TOP = 16;
float FROGBOT_MARKER_FIRE_ON_MATCH_START = 32;
float FROGBOT_MARKER_DOOR_TOUCHABLE = 64;
float FROGBOT_MARKER_ESCAPE_ROUTE = 128;
float FROGBOT_MARKER_EXPLICIT_VIEWOFFSET = 512;
float FROGBOT_MARKER_NOTOUCH = 1024;

float FROGBOT_REACH_RADIUS = 72;
float FROGBOT_STUCK_TIMEOUT = 2.5;
float FROGBOT_MOVE_SPEED = 300;
float FROGBOT_MOVE_SPEED_CLOSE = 180;
float FROGBOT_MAX_UNFLAGGED_ASCENT = 72;
float FROGBOT_COMBAT_TRACK_TIMEOUT = 0.8;
float FROGBOT_COMBAT_MIN_SCAN_INTERVAL = 0.05;
float FROGBOT_RJ_DEFAULT_PITCH = 78.25;
float FROGBOT_RJ_MIN_START_DIST = 10;
float FROGBOT_RJ_MAX_START_DIST = 120;
float FROGBOT_ROUTE_COST_INF = 999999;
float FROGBOT_ZONE_COUNT = 24;
float FROGBOT_SUBZONE_COUNT = 32;
float FROGBOT_ZONE_INF = 1000000;
float FROGBOT_HEALTYPE_MEGA = 2;
float FROGBOT_ITEM_WEAPON_SHOTGUN = 1;
float FROGBOT_ITEM_WEAPON_ROCKET = 2;
float FROGBOT_ITEM_WEAPON_SPIKES = 4;
float FROGBOT_ENEMY_POWER_QUAD = 1;
float FROGBOT_ENEMY_POWER_PENT = 2;
float FROGBOT_CTF_ROLE_ATTACK = 1;
float FROGBOT_CTF_ROLE_DEFEND = 2;
float FROGBOT_CTF_ROLE_ESCORT = 3;
float FROGBOT_CTF_ROLE_ROAM = 4;

float frogbot_routes_loaded;
float frogbot_route_load_errors;
float frogbot_marker_count;
float frogbot_path_link_count;
float frogbot_map_death_height;
float frogbot_route_potential_ready;
float frogbot_route_relax_iterations;
float frogbot_route_goal_count;
string frogbot_route_source;
float frogbot_next_teammsg_global_time;
float frogbot_vote_add_count;
float frogbot_vote_add_skill;
float frogbot_vote_add_has_custom_skill;
float frogbot_vote_add_color;
float frogbot_vote_kick_mode;
float frogbot_vote_kick_index;
float frogbot_zone_cache_ready;
float frogbot_zone_relax_iterations;
float frogbot_zone_unresolved;
float frogbot_zone_overflow_count;
float frogbot_zone_assigned_markers;
float frogbot_zone_max_subzones;
float frogbot_zone_used_count;
float frogbot_zone_validation_checks;
float frogbot_zone_validation_failures;
float frogbot_zone_validation_ratio;
entity frogbot_zone_heads[24];
entity frogbot_zone_tails[24];
float frogbot_zone_marker_counts[24];
float frogbot_zone_subzone_counts[24];
float frogbot_zone_time_cache[7200];
float frogbot_zone_rj_time_cache[7200];
entity frogbot_zone_next_cache[7200];
entity frogbot_zone_next_rj_cache[7200];
float frogbot_subzone_time_cache[9600];
float frogbot_subzone_rj_time_cache[9600];
entity frogbot_subzone_next_cache[9600];
entity frogbot_subzone_next_rj_cache[9600];
float frogbot_zone_goal_eta[300];
float frogbot_zone_goal_eta_rj[300];
entity frogbot_zone_goal_marker[300];
entity frogbot_zone_goal_marker_rj[300];
entity frogbot_markers[300];

// Location system
float LOC_MAX = 64;
float loc_count;
float loc_is_nq;         // TRUE = NQ bounding box, FALSE = QW point
vector loc_mins[64];
vector loc_maxs[64];      // NQ: box maxs. QW: unused (same as mins)
string loc_names[64];
float loc_sums[64];       // NQ: sum of box dimensions for distance calc

void() Teamplay_Select_Team;
void() teamplay_ready_player;
void() match_ready;
float() match_in_progress;
float() mode_is_arena;
float() options_get_mode;
entity (void() think_function, float think_time) utils_make_scheduled_event;
void() ClientConnect;
void() PutClientInServer;
void() respawn;
void(entity ent, string c_name) updatename;
float (string captiona, string captionb, void() passfunc, string pollname = "") vote_init;
void() vote_yes;
void(entity bot) frogbot_reset_runtime_state;
void() frogbot_ctf_init_world;
void(entity bot) frogbot_ctf_reset_runtime_state;
void() frogbot_ctf_clear_route_cache;
float() frogbot_ctf_mode_active;
float() frogbot_ctf_flags_active;
entity(float my_team) frogbot_ctf_get_own_flag;
entity(float my_team) frogbot_ctf_get_enemy_flag;
float(entity flag_ent) frogbot_ctf_flag_state;
entity(entity flag_ent) frogbot_ctf_flag_carrier;
float(entity bot) frogbot_ctf_bot_has_enemy_flag;
float() frogbot_ctf_state_signature;
void(entity bot) frogbot_ctf_update_runtime;
float() frogbot_ctf_disable_camp_mode;
float(float base_range) frogbot_ctf_adjust_combat_range;
float(float arena_mode) frogbot_ctf_prefer_close_non_projectile_dist;
float(float arena_mode) frogbot_ctf_shotgun_far_switch_dist;
float(float weapon, float default_range) frogbot_ctf_adjust_weapon_max_range;
float(entity bot, entity source, string dynamic_classname, float raw_desire) frogbot_ctf_goal_desire_bonus;
float(entity bot, entity marker, entity next_marker, float path_flags, float current_bonus) frogbot_ctf_route_score_bonus;
float(entity bot, entity target, float score, float has_los) frogbot_ctf_target_score_adjust;
float(entity bot, entity combat_target, float combat_has_los, float combat_dist, vector route_delta, float route_dist) frogbot_ctf_apply_hook_transit;
float(entity bot) frogbot_can_hook_climb;
void(entity bot) frogbot_hook_climb_abort;
float(entity bot, entity combat_target, float combat_has_los, float combat_dist, vector route_delta, float route_dist, float path_flags) frogbot_ctf_apply_hook_climb;
float(float health, float armor_value, float armor_type) frogbot_total_strength;
float(entity bot, entity target) frogbot_is_enemy_client;
float(entity p) frogbot_rune_scale_res;
float(entity p) frogbot_rune_scale_str;
float(entity p) frogbot_rune_scale_hst;
float() W_BestWeapon;
void() W_SetCurrentAmmo;
void() SUB_Null;
float(entity marker) frogbot_marker_hazard_level;
float(entity marker) frogbot_is_marker_entity;
entity(entity bot) frogbot_find_nearest_marker;
entity(entity bot) frogbot_find_nearest_visible_marker;
entity(entity bot) frogbot_find_nearest_route_marker;
entity(entity bot) frogbot_find_nearest_visible_route_marker;
float(entity bot, entity marker, entity next_marker) frogbot_camp_route_bonus;

float(entity e) frogbot_is_bot_client =
{
    local float ctype;

    if (e == world)
        return FALSE;

    ctype = clienttype(e);
    if (ctype == CLIENTTYPE_BOT)
        return TRUE;
    if (e.fb_is_bot_client)
        return TRUE;
    if (e.fb_bot_name != "")
        return TRUE;
    if (ctype == CLIENTTYPE_REAL || ctype == CLIENTTYPE_NOTACLIENT)
        return FALSE;
    if (ctype == CLIENTTYPE_DISCONNECTED && e.classname == "player" && e.netname == "unconnected")
        return TRUE;
    return FALSE;
};

float() frogbot_count_bots =
{
    local entity p;
    local float count;

    count = 0;
    p = nextent(world);
    while (p != world)
    {
        if (frogbot_is_bot_client(p))
            count = count + 1;
        p = nextent(p);
    }

    return count;
};

float() frogbot_count_power_tracking_bots =
{
    local entity p;
    local float count;
    local float memory_window;

    count = 0;
    memory_window = cvar("frogbot_powerup_memory");
    if (memory_window <= 0)
        memory_window = 2.5;

    p = nextent(world);
    while (p != world)
    {
        if (frogbot_is_bot_client(p)
            && (p.fb_enemy_quad_until > time
                || p.fb_enemy_pent_until > time
                || (p.fb_enemy_power_flags > 0
                    && p.fb_enemy_power_seen_time + memory_window > time)))
        {
            count = count + 1;
        }
        p = nextent(p);
    }

    return count;
};

void(entity target, string msg) frogbot_notify =
{
    if (target == world)
        print(msg);
    else
        sprint(target, msg);
};

float() frogbot_debug_enabled =
{
    return (cvar("frogbot_debug") > 0);
};

float() frogbot_debug_trace_enabled =
{
    return (frogbot_debug_enabled() && cvar("frogbot_debug_trace") > 0);
};

void(string msg) frogbot_debug_log =
{
    if (!frogbot_debug_enabled())
        return;
    if (msg == "")
        return;

    print(sprintf("Frogbot debug: %s\n", msg));
    if (cvar("frogbot_debug") >= 2)
        bprint(sprintf("Frogbot debug: %s\n", msg));
};

float(entity bot) frogbot_team_comms_enabled =
{
    if (bot == world)
        return FALSE;
    if (!frogbot_is_bot_client(bot))
        return FALSE;
    if (!(bot.style & CLANRING_CONNECTED))
        return FALSE;
    if (bot.style & CLANRING_OBSERVER)
        return FALSE;
    if (bot.deadflag != DEAD_NO || bot.health <= 0)
        return FALSE;
    if (!teamplay)
        return FALSE;
    if (cvar("frogbot_team_comms") <= 0)
        return FALSE;
    return TRUE;
};

float(entity bot, string msg) frogbot_team_say =
{
    local float cooldown;
    local float global_cooldown;

    if (!frogbot_team_comms_enabled(bot))
        return FALSE;
    if (msg == "")
        return FALSE;

    cooldown = cvar("frogbot_team_comms_cooldown");
    if (cooldown <= 0)
        cooldown = 8;
    if (bot.fb_next_teammsg_time > time)
        return FALSE;

    global_cooldown = bound(1.5, cooldown * 0.45, 5);
    if (frogbot_next_teammsg_global_time > time)
        return FALSE;

    stuffcmd(bot, sprintf("say_team %s\n", msg));
    bot.fb_next_teammsg_time = time + cooldown;
    frogbot_next_teammsg_global_time = time + global_cooldown;
    return TRUE;
};

// ---------------------------------------------------------------------------
// Location system — load .loc files and look up position names
// ---------------------------------------------------------------------------

void() frogbot_clear_locations =
{
    local float i;

    i = 0;
    while (i < loc_count)
    {
        if (loc_names[i] != "")
            strunzone(loc_names[i]);
        loc_names[i] = "";
        i = i + 1;
    }
    loc_count = 0;
};

// Apply QW name transforms: strip $loc_name_ prefix, $loc_name_separator → "-", $. → "-"
string(string raw) frogbot_loc_qw_fixname =
{
    local float len;
    local float i;
    local string ch;
    local string out;
    local string prefix;

    // Strip $loc_name_ prefix if present
    prefix = "$loc_name_";
    len = strlen(raw);
    if (len > 10 && substring(raw, 0, 10) == prefix)
        raw = substring(raw, 10, len - 10);

    // Replace $loc_name_separator and $. with "-"
    out = "";
    len = strlen(raw);
    i = 0;
    while (i < len)
    {
        if (i + 1 < len && substring(raw, i, 2) == "$.")
        {
            out = strcat(out, "-");
            i = i + 2;
            continue;
        }
        if (i + 20 < len && substring(raw, i, 20) == "$loc_name_separator")
        {
            out = strcat(out, "-");
            i = i + 20;
            continue;
        }
        ch = substring(raw, i, 1);
        out = strcat(out, ch);
        i = i + 1;
    }

    return out;
};

// Parse a single NQ line: x1, y1, z1, x2, y2, z2, "Name"
float(string line) frogbot_loc_parse_nq =
{
    local float argc;
    local float i;
    local float vals[6];
    local string name_part;
    local float tmp;
    local vector mins;
    local vector maxs;

    // tokenize_console handles quoted strings
    argc = tokenize_console(line);
    if (argc < 7)
        return FALSE;

    // First 6 tokens should be numbers (with commas stripped)
    // NQ format: x1, y1, z1, x2, y2, z2, "Name"
    // tokenize_console splits on commas, so tokens may have trailing commas
    i = 0;
    while (i < 6)
    {
        vals[i] = stof(argv(i));
        i = i + 1;
    }

    // Remaining tokens form the name
    name_part = argv(6);
    i = 7;
    while (i < argc)
    {
        name_part = strcat(name_part, " ", argv(i));
        i = i + 1;
    }

    if (name_part == "")
        return FALSE;

    mins_x = vals[0];
    mins_y = vals[1];
    mins_z = vals[2];
    maxs_x = vals[3];
    maxs_y = vals[4];
    maxs_z = vals[5];

    // Swap if needed so mins < maxs
    if (mins_x > maxs_x)
    { tmp = mins_x; mins_x = maxs_x; maxs_x = tmp; }
    if (mins_y > maxs_y)
    { tmp = mins_y; mins_y = maxs_y; maxs_y = tmp; }
    if (mins_z > maxs_z)
    { tmp = mins_z; mins_z = maxs_z; maxs_z = tmp; }

    // Extend Z by +/- 32 like the engine does
    mins_z = mins_z - 32;
    maxs_z = maxs_z + 32;

    if (loc_count >= LOC_MAX)
        return FALSE;

    loc_mins[loc_count] = mins;
    loc_maxs[loc_count] = maxs;
    loc_names[loc_count] = strzone(name_part);
    loc_sums[loc_count] = (maxs_x - mins_x) + (maxs_y - mins_y) + (maxs_z - mins_z);
    loc_count = loc_count + 1;
    return TRUE;
};

// Parse a single QW line: x y z location-name (coords at 8x scale)
float(string line) frogbot_loc_parse_qw =
{
    local float argc;
    local vector pt;
    local string name_part;
    local float i;

    argc = tokenize(line);
    if (argc < 4)
        return FALSE;

    pt_x = stof(argv(0)) / 8;
    pt_y = stof(argv(1)) / 8;
    pt_z = stof(argv(2)) / 8;

    // Remaining tokens form the name
    name_part = argv(3);
    i = 4;
    while (i < argc)
    {
        name_part = strcat(name_part, " ", argv(i));
        i = i + 1;
    }

    name_part = frogbot_loc_qw_fixname(name_part);

    if (name_part == "")
        return FALSE;

    if (loc_count >= LOC_MAX)
        return FALSE;

    loc_mins[loc_count] = pt;
    loc_maxs[loc_count] = pt;
    loc_names[loc_count] = strzone(name_part);
    loc_sums[loc_count] = 0;
    loc_count = loc_count + 1;
    return TRUE;
};

void() frogbot_load_locations =
{
    local string path;
    local filestream f;
    local string line;
    local float format_detected;
    local float parsed;

    frogbot_clear_locations();

    path = strcat("locs/", mapname, ".loc");
    f = fopen(path, FILE_READ);
    if (f < 0)
    {
        if (cvar("frogbot_debug") >= 2)
            print(sprintf("Frogbot locs: no file %s\n", path));
        return;
    }

    format_detected = FALSE;

    while ((line = fgets(f)))
    {
        // Skip empty lines and comments
        if (line == "")
            continue;
        if (substring(line, 0, 2) == "//")
            continue;

        // Auto-detect format on first data line
        if (!format_detected)
        {
            if (strstrofs(line, ",", 0) >= 0)
                loc_is_nq = TRUE;
            else
                loc_is_nq = FALSE;
            format_detected = TRUE;
        }

        if (loc_is_nq)
            parsed = frogbot_loc_parse_nq(line);
        else
            parsed = frogbot_loc_parse_qw(line);

        if (loc_count >= LOC_MAX)
            break;
    }

    fclose(f);

    if (loc_count > 0)
        print(sprintf("Frogbot locs: loaded %g locations from %s (%s format)\n",
                       loc_count, path, loc_is_nq ? "NQ" : "QW"));
};

string(vector pos) frogbot_get_location =
{
    local float i;
    local float best_dist;
    local float best_idx;
    local float dist;
    local vector d;

    if (loc_count <= 0)
        return "";

    best_dist = 999999999;
    best_idx = -1;

    if (loc_is_nq)
    {
        // NQ: Manhattan-like distance to bounding box
        local vector lmins;
        local vector lmaxs;
        i = 0;
        while (i < loc_count)
        {
            lmins = loc_mins[i];
            lmaxs = loc_maxs[i];
            dist = fabs(lmins_x - pos_x) + fabs(lmaxs_x - pos_x)
                 + fabs(lmins_y - pos_y) + fabs(lmaxs_y - pos_y)
                 + fabs(lmins_z - pos_z) + fabs(lmaxs_z - pos_z)
                 - loc_sums[i];
            if (dist < 0.01)
                return loc_names[i]; // inside the box
            if (dist < best_dist)
            {
                best_dist = dist;
                best_idx = i;
            }
            i = i + 1;
        }
    }
    else
    {
        // QW: squared Euclidean distance to point
        i = 0;
        while (i < loc_count)
        {
            d = pos - loc_mins[i];
            dist = d_x * d_x + d_y * d_y + d_z * d_z;
            if (dist < best_dist)
            {
                best_dist = dist;
                best_idx = i;
            }
            i = i + 1;
        }
    }

    if (best_idx >= 0)
        return loc_names[best_idx];
    return "";
};

string(entity bot) frogbot_get_role_desc =
{
    if (!frogbot_ctf_mode_active())
        return "";
    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ATTACK)
        return "attacking";
    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_DEFEND)
        return "defending";
    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ESCORT)
        return "escorting";
    if (bot.fb_ctf_role == FROGBOT_CTF_ROLE_ROAM)
        return "roaming";
    return "";
};

void(entity bot) frogbot_loc_periodic_report =
{
    local string loc;
    local string role;
    local string msg;

    if (!teamplay)
        return;
    if (loc_count <= 0)
        return;
    if (cvar("frogbot_loc_reports") <= 0)
        return;
    if (bot.fb_next_loc_report_time > time)
        return;

    loc = frogbot_get_location(bot.origin);
    if (loc == "")
        return;

    // Skip if still at the same location
    if (bot.fb_last_loc_name != "" && loc == bot.fb_last_loc_name)
    {
        // Push timer forward so we check again soon
        bot.fb_next_loc_report_time = time + 5;
        return;
    }

    role = frogbot_get_role_desc(bot);
    if (role != "")
        msg = sprintf("at %s, %s", loc, role);
    else
        msg = sprintf("at %s", loc);

    if (frogbot_team_say(bot, msg))
    {
        if (bot.fb_last_loc_name != "")
            strunzone(bot.fb_last_loc_name);
        bot.fb_last_loc_name = strzone(loc);
        bot.fb_next_loc_report_time = time + cvar("frogbot_loc_report_interval");
    }
};

float() frogbot_powerup_awareness_enabled =
{
    return (cvar("frogbot_powerup_awareness") > 0);
};

float() frogbot_powerup_memory_window =
{
    local float memory_window;

    memory_window = cvar("frogbot_powerup_memory");
    if (memory_window <= 0)
        memory_window = 2.5;
    return memory_window;
};

float(entity p) frogbot_has_quad =
{
    if (p == world)
        return FALSE;
    if (p.super_damage_finished > time)
        return TRUE;
    if (p.items & IT_QUAD)
        return TRUE;
    return FALSE;
};

float(entity p) frogbot_has_pent =
{
    if (p == world)
        return FALSE;
    if (p.invincible_finished > time)
        return TRUE;
    if (p.items & IT_INVULNERABILITY)
        return TRUE;
    return FALSE;
};

float(entity enemy) frogbot_enemy_power_flags =
{
    local float flags;

    if (enemy == world)
        return 0;

    flags = 0;
    if (frogbot_has_quad(enemy))
        flags = flags | FROGBOT_ENEMY_POWER_QUAD;
    if (frogbot_has_pent(enemy))
        flags = flags | FROGBOT_ENEMY_POWER_PENT;
    return flags;
};

float(entity bot, entity enemy) frogbot_enemy_power_threat =
{
    local float flags;
    local float threat;
    local float value;

    if (bot == world || enemy == world)
        return 1;
    if (!frogbot_powerup_awareness_enabled())
        return 1;

    flags = frogbot_enemy_power_flags(enemy);
    if (enemy == bot.fb_enemy_target && flags <= 0)
        flags = bot.fb_enemy_power_flags;

    threat = 1;
    if (flags & FROGBOT_ENEMY_POWER_QUAD)
    {
        value = cvar("frogbot_powerup_quad_threat");
        if (value <= 0)
            value = 1.6;
        threat = threat * value;
    }
    if (flags & FROGBOT_ENEMY_POWER_PENT)
    {
        value = cvar("frogbot_powerup_pent_threat");
        if (value <= 0)
            value = 2.4;
        threat = threat * value;
    }

    if (frogbot_has_quad(bot))
    {
        value = cvar("frogbot_powerup_self_quad_relief");
        if (value <= 0)
            value = 0.6;
        threat = threat * value;
    }
    if (frogbot_has_pent(bot))
    {
        value = cvar("frogbot_powerup_self_pent_relief");
        if (value <= 0)
            value = 0.3;
        threat = threat * value;
    }

    return bound(0.1, threat, 8);
};

void(entity bot) frogbot_prune_enemy_power_memory =
{
    local float flags;
    local float memory_window;

    if (bot == world)
        return;

    if (!frogbot_powerup_awareness_enabled())
    {
        bot.fb_enemy_power_flags = 0;
        bot.fb_enemy_power_seen_time = 0;
        bot.fb_enemy_quad_until = 0;
        bot.fb_enemy_pent_until = 0;
        bot.fb_enemy_power_threat = 0;
        return;
    }

    memory_window = frogbot_powerup_memory_window();
    flags = 0;
    if (bot.fb_enemy_quad_until > time)
        flags = flags | FROGBOT_ENEMY_POWER_QUAD;
    if (bot.fb_enemy_pent_until > time)
        flags = flags | FROGBOT_ENEMY_POWER_PENT;

    if (flags <= 0 && bot.fb_enemy_power_seen_time + memory_window > time)
        flags = bot.fb_enemy_power_flags;

    if (flags <= 0)
    {
        bot.fb_enemy_power_flags = 0;
        bot.fb_enemy_power_seen_time = 0;
        bot.fb_enemy_quad_until = 0;
        bot.fb_enemy_pent_until = 0;
        bot.fb_enemy_power_threat = 0;
        return;
    }

    bot.fb_enemy_power_flags = flags;
};

void(entity bot, entity enemy, float flags, float visible_now) frogbot_track_enemy_power =
{
    local float old_flags;
    local float new_flags;
    local float memory_window;
    local float changed;
    local float cooldown;
    local string msg;

    if (bot == world || enemy == world)
        return;
    if (!frogbot_powerup_awareness_enabled())
        return;
    if (flags <= 0)
        return;

    old_flags = bot.fb_enemy_power_flags;
    memory_window = frogbot_powerup_memory_window();
    changed = (flags != old_flags);
    new_flags = 0;
    if ((flags & FROGBOT_ENEMY_POWER_QUAD) && !(old_flags & FROGBOT_ENEMY_POWER_QUAD))
        new_flags = new_flags | FROGBOT_ENEMY_POWER_QUAD;
    if ((flags & FROGBOT_ENEMY_POWER_PENT) && !(old_flags & FROGBOT_ENEMY_POWER_PENT))
        new_flags = new_flags | FROGBOT_ENEMY_POWER_PENT;

    if (flags & FROGBOT_ENEMY_POWER_QUAD)
    {
        if (enemy.super_damage_finished > time)
            bot.fb_enemy_quad_until = max(bot.fb_enemy_quad_until, enemy.super_damage_finished);
        bot.fb_enemy_quad_until = max(bot.fb_enemy_quad_until, time + memory_window);
    }
    if (flags & FROGBOT_ENEMY_POWER_PENT)
    {
        if (enemy.invincible_finished > time)
            bot.fb_enemy_pent_until = max(bot.fb_enemy_pent_until, enemy.invincible_finished);
        bot.fb_enemy_pent_until = max(bot.fb_enemy_pent_until, time + memory_window);
    }

    bot.fb_enemy_power_flags = flags;
    bot.fb_enemy_power_seen_time = time;
    bot.fb_enemy_power_threat = frogbot_enemy_power_threat(bot, enemy);

    if (visible_now
        && new_flags > 0
        && cvar("frogbot_powerup_comms") > 0
        && bot.fb_next_powerup_call_time <= time)
    {
        cooldown = cvar("frogbot_powerup_comms_cooldown");
        if (cooldown <= 0)
            cooldown = 12;

        if ((new_flags & FROGBOT_ENEMY_POWER_QUAD) && (new_flags & FROGBOT_ENEMY_POWER_PENT))
            msg = "enemy quad+pent";
        else if (new_flags & FROGBOT_ENEMY_POWER_PENT)
            msg = "enemy pent";
        else if (new_flags & FROGBOT_ENEMY_POWER_QUAD)
            msg = "enemy quad";
        else
            msg = "";

        if (msg != "")
        {
            local string pw_loc;
            pw_loc = frogbot_get_location(enemy.origin);
            if (pw_loc != "")
                msg = sprintf("%s at %s", msg, pw_loc);
        }

        if (msg != "" && frogbot_team_say(bot, msg))
            bot.fb_next_powerup_call_time = time + cooldown;
    }

    if (visible_now && changed && cvar("frogbot_debug") >= 3)
    {
        frogbot_debug_log("");
    }
};

void(entity bot, string desired_name) frogbot_set_bot_name =
{
    local string fixed_name;
    local float needs_update;

    if (bot == world)
        return;

    fixed_name = desired_name;
    if (fixed_name == "" || fixed_name == "unconnected")
        fixed_name = "FrogBot";

    needs_update = FALSE;

    if (bot.fb_bot_name != "" && bot.fb_bot_name != fixed_name)
    {
        strunzone(bot.fb_bot_name);
        bot.fb_bot_name = "";
        needs_update = TRUE;
    }
    if (bot.fb_bot_name == "")
    {
        bot.fb_bot_name = strzone(fixed_name);
        needs_update = TRUE;
    }

    if (bot.netname != bot.fb_bot_name)
    {
        bot.netname = bot.fb_bot_name;
        needs_update = TRUE;
    }

    if (bot.oldname != bot.fb_bot_name)
    {
        if (bot.oldname)
            strunzone(bot.oldname);
        bot.oldname = strzone(bot.fb_bot_name);
        needs_update = TRUE;
    }

    if (needs_update)
        updatename(bot, bot.fb_bot_name);
};

float(string s) frogbot_is_uint =
{
    local float i;
    local string ch;

    if (s == "")
        return FALSE;

    i = 0;
    while (i < strlen(s))
    {
        ch = substring(s, i, 1);
        if (ch != "0" && ch != "1" && ch != "2" && ch != "3" && ch != "4"
            && ch != "5" && ch != "6" && ch != "7" && ch != "8" && ch != "9")
        {
            return FALSE;
        }
        i = i + 1;
    }

    return TRUE;
};

// Returns color number (1-13) if s is a color keyword, or -1 if not.
// Recognized: "red" (4), "blue" (13), "c1" through "c13".
float(string s) frogbot_parse_color_arg =
{
    local string lower;
    local string num_part;
    local float c;

    lower = strtolower(s);
    if (lower == "red") return COLOR_RED;
    if (lower == "blue") return COLOR_BLUE;

    if (strlen(lower) >= 2 && substring(lower, 0, 1) == "c")
    {
        num_part = substring(lower, 1, -1);
        if (frogbot_is_uint(num_part))
        {
            c = stof(num_part);
            if (c >= 1 && c <= 13)
                return c;
        }
    }

    return -1;
};

float(string token) frogbot_valid_map_token =
{
    if (token == "")
        return FALSE;
    if (strstrofs(token, "/", 0) >= 0)
        return FALSE;
    if (strstrofs(token, "\\", 0) >= 0)
        return FALSE;
    if (strstrofs(token, "..", 0) >= 0)
        return FALSE;
    return TRUE;
};

float(string path) frogbot_path_is_absolute =
{
    if (path == "")
        return FALSE;
    if (substring(path, 0, 1) == "/")
        return TRUE;
    if (strlen(path) >= 3 && substring(path, 1, 1) == ":" && (substring(path, 2, 1) == "/" || substring(path, 2, 1) == "\\"))
        return TRUE;
    return FALSE;
};

string() frogbot_get_route_dir =
{
    local string route_dir;

    route_dir = cvar_string("frogbot_route_dir");
    if (route_dir == "" || route_dir == "frogbot_route_dir")
        route_dir = "bots/maps";
    return route_dir;
};

void(string route_source) frogbot_set_route_source =
{
    if (frogbot_route_source != "")
    {
        strunzone(frogbot_route_source);
        frogbot_route_source = "";
    }

    if (route_source != "")
        frogbot_route_source = strzone(route_source);
};

float(string path, float verbose, entity notify_target) frogbot_try_open_route_file =
{
    local filestream f;

    if (path == "")
        return -1;

    f = fopen(path, FILE_READ);
    if (f >= 0)
    {
        frogbot_set_route_source(path);
        if (frogbot_debug_enabled())
            frogbot_debug_log("");
        return f;
    }

    if (verbose && cvar("frogbot_debug") >= 3)
        frogbot_notify(notify_target, sprintf("Frogbot debug: route probe miss source=%s\n", path));

    return -1;
};

float(string rel_path, string fs_gamedir, string fs_basedir, string fs_game, float verbose, entity notify_target) frogbot_try_open_route_relative =
{
    local filestream f;
    local string candidate;

    if (rel_path == "")
        return -1;

    f = frogbot_try_open_route_file(rel_path, verbose, notify_target);
    if (f >= 0 || frogbot_path_is_absolute(rel_path))
        return f;

    if (fs_gamedir != "")
    {
        candidate = sprintf("%s/%s", fs_gamedir, rel_path);
        f = frogbot_try_open_route_file(candidate, verbose, notify_target);
        if (f >= 0)
            return f;
    }

    if (fs_basedir != "" && fs_game != "")
    {
        candidate = sprintf("%s/%s/%s", fs_basedir, fs_game, rel_path);
        f = frogbot_try_open_route_file(candidate, verbose, notify_target);
        if (f >= 0)
            return f;
    }

    if (fs_game != "")
    {
        candidate = sprintf("%s/%s", fs_game, rel_path);
        f = frogbot_try_open_route_file(candidate, verbose, notify_target);
        if (f >= 0)
            return f;
    }

    return -1;
};

void() frogbot_clear_routes =
{
    local float i;
    local float z;
    local entity p;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        if (frogbot_markers[i] != world)
        {
            remove(frogbot_markers[i]);
            frogbot_markers[i] = world;
        }
        i = i + 1;
    }

    p = nextent(world);
    while (p != world)
    {
        if (frogbot_is_bot_client(p))
            frogbot_reset_runtime_state(p);
        p = nextent(p);
    }

    frogbot_marker_count = 0;
    frogbot_path_link_count = 0;
    frogbot_route_load_errors = 0;
    frogbot_routes_loaded = FALSE;
    frogbot_map_death_height = FROGBOT_DEFAULT_MAP_DEATH_HEIGHT;
    frogbot_route_potential_ready = FALSE;
    frogbot_route_relax_iterations = 0;
    frogbot_route_goal_count = 0;
    frogbot_zone_cache_ready = FALSE;
    frogbot_zone_relax_iterations = 0;
    frogbot_zone_unresolved = 0;
    frogbot_zone_overflow_count = 0;
    frogbot_zone_assigned_markers = 0;
    frogbot_zone_max_subzones = 0;
    frogbot_zone_used_count = 0;
    frogbot_zone_validation_checks = 0;
    frogbot_zone_validation_failures = 0;
    frogbot_zone_validation_ratio = 0;
    z = 0;
    while (z < FROGBOT_ZONE_COUNT)
    {
        frogbot_zone_heads[z] = world;
        frogbot_zone_tails[z] = world;
        frogbot_zone_marker_counts[z] = 0;
        frogbot_zone_subzone_counts[z] = 0;
        z = z + 1;
    }
    frogbot_ctf_clear_route_cache();
    frogbot_set_route_source("");
};

entity(float marker_number) frogbot_get_marker =
{
    local float index;

    index = marker_number - 1;
    if (index < 0 || index >= FROGBOT_MAX_MARKERS)
        return world;

    return frogbot_markers[index];
};

entity(float marker_number, vector org) frogbot_create_marker =
{
    local entity marker;
    local float index;

    index = marker_number - 1;
    if (index < 0 || index >= FROGBOT_MAX_MARKERS)
        return world;
    if (frogbot_markers[index] != world)
        return world;
    marker = spawn();
    marker.classname = "frogbot_marker";
    marker.movetype = MOVETYPE_NONE;
    marker.solid = SOLID_NOT;
    marker.takedamage = DAMAGE_NO;
    marker.origin_x = rint(org_x);
    marker.origin_y = rint(org_y);
    marker.origin_z = rint(org_z);
    marker.view_ofs = '80 80 24';
    setorigin(marker, marker.origin);

    frogbot_markers[index] = marker;
    frogbot_marker_count = frogbot_marker_count + 1;
    marker.fb_marker_index = marker_number;
    marker.fb_zone = 0;
    marker.fb_subzone = -1;
    marker.fb_zone_head = world;
    marker.fb_zone_next = world;
    marker.fb_dynsource = world;

    return marker;
};

float(string classname) frogbot_is_dynamic_marker_class =
{
    if (classname == "")
        return FALSE;

    // KTX bot_items.c itemSpawnFunctions[] list
    if (classname == "item_armor1")
        return TRUE;
    if (classname == "item_armor2")
        return TRUE;
    if (classname == "item_armorInv")
        return TRUE;
    if (classname == "item_artifact_invulnerability")
        return TRUE;
    if (classname == "item_artifact_envirosuit")
        return TRUE;
    if (classname == "item_artifact_invisibility")
        return TRUE;
    if (classname == "item_artifact_super_damage")
    {
        // KTX handles aerowalk quad as a special late marker.
        if (mapname == "aerowalk")
            return FALSE;
        return TRUE;
    }
    if (classname == "item_cells")
        return TRUE;
    if (classname == "item_health")
        return TRUE;
    if (classname == "item_rockets")
        return TRUE;
    if (classname == "item_shells")
        return TRUE;
    if (classname == "item_spikes")
        return TRUE;
    if (classname == "item_weapon")
        return TRUE;
    if (classname == "weapon_supershotgun")
        return TRUE;
    if (classname == "weapon_nailgun")
        return TRUE;
    if (classname == "weapon_supernailgun")
        return TRUE;
    if (classname == "weapon_grenadelauncher")
        return TRUE;
    if (classname == "weapon_rocketlauncher")
        return TRUE;
    if (classname == "weapon_lightning")
        return TRUE;

    // KTX bot_loadmap.c stdSpawnFunctions[] list
    if (classname == "func_button")
        return TRUE;
    if (classname == "door" || classname == "func_door" || classname == "func_door_secret")
        return TRUE;
    if (classname == "plat" || classname == "func_plat")
        return TRUE;
    if (classname == "train" || classname == "func_train")
        return TRUE;
    if (classname == "info_player_deathmatch")
        return TRUE;
    if (classname == "info_teleport_destination")
        return TRUE;
    if (classname == "trigger_changelevel")
        return TRUE;
    if (classname == "trigger_counter")
        return TRUE;
    if (classname == "trigger_hurt")
        return TRUE;
    if (classname == "trigger_multiple")
        return TRUE;
    if (classname == "trigger_once")
        return TRUE;
    if (classname == "trigger_onlyregistered")
        return TRUE;
    if (classname == "trigger_push")
        return TRUE;
    if (classname == "trigger_secret")
        return TRUE;
    if (classname == "trigger_setskill")
        return TRUE;
    if (classname == "trigger_teleport")
        return TRUE;

    return FALSE;
};

float(string classname) frogbot_is_dynamic_seed_fallback_class =
{
    if (classname == "")
        return FALSE;

    // Some map .bot packs reference team/start spawns in markerbase.
    if (classname == "info_player_team1")
        return TRUE;
    if (classname == "info_player_team2")
        return TRUE;
    if (classname == "info_player_team1_deathmatch")
        return TRUE;
    if (classname == "info_player_team2_deathmatch")
        return TRUE;
    if (classname == "info_player_start")
        return TRUE;
    if (classname == "info_player_start2")
        return TRUE;
    if (classname == "info_player_coop")
        return TRUE;

    return FALSE;
};

float(string classname) frogbot_is_dynamic_seed_backfill_class =
{
    if (classname == "")
        return FALSE;

    if (frogbot_is_dynamic_seed_fallback_class(classname))
        return TRUE;
    if (classname == "info_player_deathmatch")
        return TRUE;
    if (classname == "info_teleport_destination")
        return TRUE;
    if (classname == "trigger_teleport")
        return TRUE;
    if (classname == "trigger_push")
        return TRUE;
    if (classname == "door" || classname == "func_door" || classname == "func_door_secret")
        return TRUE;

    return FALSE;
};

string(entity ent) frogbot_dynamic_marker_classname =
{
    if (ent == world)
        return "";

    if (ent.classname == "frogbot_dynsource")
        return ent.noise1;

    return ent.classname;
};

float(entity source) frogbot_marker_has_dynsource =
{
    local float i;
    local entity marker;

    if (source == world)
        return FALSE;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker) && marker.fb_dynsource == source)
            return TRUE;
        i = i + 1;
    }

    return FALSE;
};

float(vector org, float radius) frogbot_marker_exists_near_origin =
{
    local float i;
    local entity marker;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker) && vlen(marker.origin - org) <= radius)
            return TRUE;
        i = i + 1;
    }

    return FALSE;
};

float(string cls_name) frogbot_count_classname_raw =
{
    local entity ent;
    local float count;

    if (cls_name == "")
        return 0;

    count = 0;
    ent = nextent(world);
    while (ent != world)
    {
        if (ent.classname == cls_name)
            count = count + 1;
        ent = nextent(ent);
    }

    return count;
};

float() frogbot_count_preserved_dynamic_sources =
{
    local entity ent;
    local float count;

    count = 0;
    ent = nextent(world);
    while (ent != world)
    {
        if (ent.classname == "frogbot_dynsource")
            count = count + 1;
        ent = nextent(ent);
    }

    return count;
};

entity(entity source) frogbot_dynamic_source_live_entity =
{
    local entity ent;
    local entity best;
    local float dist;
    local float best_dist;
    local float match_dist;
    local string source_classname;

    if (source == world)
        return world;
    if (source.classname != "frogbot_dynsource")
        return source;

    if (source.fb_dynlive != world && source.fb_dynlive.classname == source.noise1)
        return source.fb_dynlive;

    source_classname = source.noise1;
    if (source_classname == "")
        return world;

    best = world;
    best_dist = 99999999;
    ent = find(world, classname, source_classname);
    while (ent)
    {
        dist = vlen(ent.origin - source.origin);
        if (dist < best_dist)
        {
            best_dist = dist;
            best = ent;
        }
        ent = find(ent, classname, source_classname);
    }

    match_dist = cvar("frogbot_dynamic_source_match_dist");
    if (match_dist <= 0)
        match_dist = 128;

    if (best != world && best_dist <= match_dist)
    {
        source.fb_dynlive = best;
        return best;
    }

    source.fb_dynlive = world;
    return world;
};

entity(entity source) frogbot_dynamic_source_for_marker =
{
    local entity live_source;

    if (source == world)
        return world;
    if (source.classname != "frogbot_dynsource")
        return source;

    live_source = frogbot_dynamic_source_live_entity(source);
    if (live_source != world)
        return live_source;

    return source;
};

float(entity ent) frogbot_capture_dynamic_source =
{
    local entity source;
    local string source_classname;

    if (ent == world)
        return FALSE;

    source_classname = ent.classname;
    if (!frogbot_is_dynamic_marker_class(source_classname)
        && !frogbot_is_dynamic_seed_fallback_class(source_classname))
        return FALSE;

    // Snapshot dynamic entities into inert helper edicts so route seeding
    // remains stable even if gameplay code removes/reclasses originals.
    source = spawn();
    source.noise1 = source_classname;
    source.classname = "frogbot_dynsource";
    source.movetype = MOVETYPE_NONE;
    source.solid = SOLID_NOT;
    source.flags = 0;
    source.effects = 0;
    source.model = string_null;
    source.mdl = string_null;
    source.velocity = '0 0 0';
    source.touch = SUB_Null;
    source.think = SUB_Null;
    source.nextthink = -1;
    source.fb_dynlive = world;
    source.takedamage = DAMAGE_NO;
    source.origin = ent.origin;
    source.mins = ent.mins;
    source.maxs = ent.maxs;
    setorigin(source, source.origin);
    setsize(source, source.mins, source.maxs);

    if (cvar("frogbot_debug") >= 3)
    {
        frogbot_debug_log("");
    }

    return TRUE;
};

void() frogbot_clear_dynamic_sources =
{
    local entity ent;
    local entity nextent_saved;

    ent = nextent(world);
    while (ent != world)
    {
        nextent_saved = nextent(ent);
        if (ent.classname == "frogbot_dynsource")
            remove(ent);
        ent = nextent_saved;
    }
};

void() frogbot_preserve_dynamic_sources =
{
    local entity ent;
    local entity nextent_saved;
    local float already_preserved;
    local float preserved_count;

    already_preserved = FALSE;
    ent = nextent(world);
    while (ent != world)
    {
        if (ent.classname == "frogbot_dynsource")
        {
            already_preserved = TRUE;
            break;
        }
        ent = nextent(ent);
    }

    if (already_preserved)
        return;

    preserved_count = 0;
    ent = nextent(world);
    while (ent != world)
    {
        nextent_saved = nextent(ent);
        if (frogbot_capture_dynamic_source(ent))
            preserved_count = preserved_count + 1;
        ent = nextent_saved;
    }

    if (cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
    }
};

void() frogbot_rebuild_dynamic_sources =
{
    frogbot_clear_dynamic_sources();
    frogbot_preserve_dynamic_sources();
};

vector(entity ent) frogbot_dynamic_marker_origin =
{
    local vector org;
    local float span_x;
    local float span_y;
    local float span_z;

    org = ent.origin;
    span_x = ent.absmax_x - ent.absmin_x;
    span_y = ent.absmax_y - ent.absmin_y;
    span_z = ent.absmax_z - ent.absmin_z;

    if (span_x > 4 || span_y > 4 || span_z > 8)
    {
        org = (ent.absmin + ent.absmax) * 0.5;
        if (org_z < ent.absmin_z + 24)
            org_z = ent.absmin_z + 24;
    }

    return org;
};

float(float wanted_count) frogbot_seed_dynamic_markers =
{
    local entity ent;
    local entity nextent_saved;
    local entity created_marker;
    local float created;
    local float use_preserved_only;
    local vector org;
    local string dynamic_classname;
    local float fallback_created;
    local float backfill_created;
    local float preserved_count;
    local float live_extra_created;
    local float near_eps;
    local float force_created;
    local float jitter;
    local entity force_source;

    if (wanted_count <= 0)
        return 0;

    near_eps = cvar("frogbot_dynamic_seed_origin_eps");
    if (near_eps <= 0)
        near_eps = 16;

    use_preserved_only = FALSE;
    ent = nextent(world);
    while (ent != world)
    {
        if (ent.classname == "frogbot_dynsource")
        {
            use_preserved_only = TRUE;
            break;
        }
        ent = nextent(ent);
    }
    preserved_count = frogbot_count_preserved_dynamic_sources();

    created = 0;
    fallback_created = 0;
    backfill_created = 0;
    live_extra_created = 0;
    force_created = 0;
    ent = nextent(world);
    while (ent != world && created < wanted_count)
    {
        nextent_saved = nextent(ent);
        if (use_preserved_only && ent.classname != "frogbot_dynsource")
        {
            ent = nextent_saved;
            continue;
        }
        dynamic_classname = frogbot_dynamic_marker_classname(ent);
        if (frogbot_is_dynamic_marker_class(dynamic_classname))
        {
            org = frogbot_dynamic_marker_origin(ent);
            created_marker = frogbot_create_marker(created + 1, org);
            if (created_marker != world)
            {
                created_marker.fb_dynsource = frogbot_dynamic_source_for_marker(ent);
                if (cvar("frogbot_debug") >= 3)
                {
                    frogbot_debug_log("");
                }
                created = created + 1;
            }
        }
        ent = nextent_saved;
    }

    if (created < wanted_count)
    {
        ent = nextent(world);
        while (ent != world && created < wanted_count)
        {
            nextent_saved = nextent(ent);
            if (use_preserved_only && ent.classname != "frogbot_dynsource")
            {
                ent = nextent_saved;
                continue;
            }

            dynamic_classname = frogbot_dynamic_marker_classname(ent);
            if (!frogbot_is_dynamic_seed_fallback_class(dynamic_classname))
            {
                ent = nextent_saved;
                continue;
            }
            if (frogbot_marker_has_dynsource(ent))
            {
                ent = nextent_saved;
                continue;
            }

            org = frogbot_dynamic_marker_origin(ent);
            created_marker = frogbot_create_marker(created + 1, org);
            if (created_marker != world)
            {
                created_marker.fb_dynsource = frogbot_dynamic_source_for_marker(ent);
                fallback_created = fallback_created + 1;
                if (cvar("frogbot_debug") >= 3)
                {
                    frogbot_debug_log("");
                }
                created = created + 1;
            }

            ent = nextent_saved;
        }
    }

    if (fallback_created > 0 && cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
    }

    if (created < wanted_count && cvar("frogbot_dynamic_backfill") > 0)
    {
        ent = nextent(world);
        while (ent != world && created < wanted_count)
        {
            nextent_saved = nextent(ent);
            if (use_preserved_only && ent.classname != "frogbot_dynsource")
            {
                ent = nextent_saved;
                continue;
            }

            dynamic_classname = frogbot_dynamic_marker_classname(ent);
            if (!frogbot_is_dynamic_seed_backfill_class(dynamic_classname))
            {
                ent = nextent_saved;
                continue;
            }

            org = frogbot_dynamic_marker_origin(ent);
            created_marker = frogbot_create_marker(created + 1, org);
            if (created_marker != world)
            {
                created_marker.fb_dynsource = frogbot_dynamic_source_for_marker(ent);
                backfill_created = backfill_created + 1;
                if (cvar("frogbot_debug") >= 3)
                {
                    frogbot_debug_log("");
                }
                created = created + 1;
            }

            ent = nextent_saved;
        }
    }

    if (backfill_created > 0 && cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
    }

    if (created < wanted_count && cvar("frogbot_dynamic_seed_live_fallback") > 0
        && use_preserved_only && preserved_count < wanted_count)
    {
        ent = nextent(world);
        while (ent != world && created < wanted_count)
        {
            nextent_saved = nextent(ent);
            if (ent.classname == "frogbot_dynsource")
            {
                ent = nextent_saved;
                continue;
            }

            dynamic_classname = frogbot_dynamic_marker_classname(ent);
            if (!frogbot_is_dynamic_marker_class(dynamic_classname)
                && !frogbot_is_dynamic_seed_backfill_class(dynamic_classname))
            {
                ent = nextent_saved;
                continue;
            }

            org = frogbot_dynamic_marker_origin(ent);
            if (frogbot_marker_exists_near_origin(org, near_eps))
            {
                ent = nextent_saved;
                continue;
            }

            created_marker = frogbot_create_marker(created + 1, org);
            if (created_marker != world)
            {
                created_marker.fb_dynsource = frogbot_dynamic_source_for_marker(ent);
                live_extra_created = live_extra_created + 1;
                if (cvar("frogbot_debug") >= 3)
                {
                    frogbot_debug_log("");
                }
                created = created + 1;
            }

            ent = nextent_saved;
        }
    }

    if (live_extra_created > 0 && cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
    }

    // Final compatibility closure: if markerbase still underfilled, force-create
    // remaining dynamic ids by reusing known dynamic sources. This keeps
    // SetMarkerPath references valid on maps that expose fewer unique entities.
    if (created < wanted_count && cvar("frogbot_dynamic_force_fill") > 0)
    {
        force_source = world;
        ent = nextent(world);
        while (ent != world)
        {
            nextent_saved = nextent(ent);
            if (use_preserved_only && ent.classname != "frogbot_dynsource")
            {
                ent = nextent_saved;
                continue;
            }
            dynamic_classname = frogbot_dynamic_marker_classname(ent);
            if (frogbot_is_dynamic_marker_class(dynamic_classname)
                || frogbot_is_dynamic_seed_backfill_class(dynamic_classname)
                || frogbot_is_dynamic_seed_fallback_class(dynamic_classname))
            {
                force_source = ent;
                break;
            }
            ent = nextent_saved;
        }

        while (created < wanted_count)
        {
            if (force_source != world)
                org = frogbot_dynamic_marker_origin(force_source);
            else if (frogbot_is_marker_entity(frogbot_markers[0]))
                org = frogbot_markers[0].origin;
            else
                org = '0 0 0';

            // Deterministic small jitter avoids exact overlap clusters.
            jitter = (created % 3) - 1;
            org_x = org_x + (jitter * 12);
            jitter = floor(created / 3) % 3;
            org_y = org_y + ((jitter - 1) * 12);

            created_marker = frogbot_create_marker(created + 1, org);
            if (created_marker == world)
                break;
            if (force_source != world)
                created_marker.fb_dynsource = frogbot_dynamic_source_for_marker(force_source);
            force_created = force_created + 1;
            created = created + 1;
        }
    }

    if (force_created > 0 && cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
    }

    return created;
};

void(entity marker, float path_index, entity next_marker) frogbot_set_path_marker =
{
    switch (path_index)
    {
        case 0: marker.fb_path0 = next_marker; break;
        case 1: marker.fb_path1 = next_marker; break;
        case 2: marker.fb_path2 = next_marker; break;
        case 3: marker.fb_path3 = next_marker; break;
        case 4: marker.fb_path4 = next_marker; break;
        case 5: marker.fb_path5 = next_marker; break;
        case 6: marker.fb_path6 = next_marker; break;
        case 7: marker.fb_path7 = next_marker; break;
    }
};

void(entity marker, float path_index, float flags) frogbot_set_path_flags =
{
    switch (path_index)
    {
        case 0: marker.fb_pathflags0 = flags; break;
        case 1: marker.fb_pathflags1 = flags; break;
        case 2: marker.fb_pathflags2 = flags; break;
        case 3: marker.fb_pathflags3 = flags; break;
        case 4: marker.fb_pathflags4 = flags; break;
        case 5: marker.fb_pathflags5 = flags; break;
        case 6: marker.fb_pathflags6 = flags; break;
        case 7: marker.fb_pathflags7 = flags; break;
    }
};

float(entity marker, float path_index) frogbot_get_path_flags =
{
    switch (path_index)
    {
        case 0: return marker.fb_pathflags0;
        case 1: return marker.fb_pathflags1;
        case 2: return marker.fb_pathflags2;
        case 3: return marker.fb_pathflags3;
        case 4: return marker.fb_pathflags4;
        case 5: return marker.fb_pathflags5;
        case 6: return marker.fb_pathflags6;
        case 7: return marker.fb_pathflags7;
    }
    return 0;
};

void(entity marker, float path_index, float hint) frogbot_set_path_hint =
{
    switch (path_index)
    {
        case 0: marker.fb_pathhint0 = hint; break;
        case 1: marker.fb_pathhint1 = hint; break;
        case 2: marker.fb_pathhint2 = hint; break;
        case 3: marker.fb_pathhint3 = hint; break;
        case 4: marker.fb_pathhint4 = hint; break;
        case 5: marker.fb_pathhint5 = hint; break;
        case 6: marker.fb_pathhint6 = hint; break;
        case 7: marker.fb_pathhint7 = hint; break;
    }
};

float(entity marker, float path_index) frogbot_get_path_hint =
{
    switch (path_index)
    {
        case 0: return marker.fb_pathhint0;
        case 1: return marker.fb_pathhint1;
        case 2: return marker.fb_pathhint2;
        case 3: return marker.fb_pathhint3;
        case 4: return marker.fb_pathhint4;
        case 5: return marker.fb_pathhint5;
        case 6: return marker.fb_pathhint6;
        case 7: return marker.fb_pathhint7;
    }
    return 0;
};

void(entity marker, float path_index, float pitch, float yaw, float delay) frogbot_set_rj_fields =
{
    switch (path_index)
    {
        case 0:
            marker.fb_rj_pitch0 = pitch; marker.fb_rj_yaw0 = yaw; marker.fb_rj_delay0 = delay;
            break;
        case 1:
            marker.fb_rj_pitch1 = pitch; marker.fb_rj_yaw1 = yaw; marker.fb_rj_delay1 = delay;
            break;
        case 2:
            marker.fb_rj_pitch2 = pitch; marker.fb_rj_yaw2 = yaw; marker.fb_rj_delay2 = delay;
            break;
        case 3:
            marker.fb_rj_pitch3 = pitch; marker.fb_rj_yaw3 = yaw; marker.fb_rj_delay3 = delay;
            break;
        case 4:
            marker.fb_rj_pitch4 = pitch; marker.fb_rj_yaw4 = yaw; marker.fb_rj_delay4 = delay;
            break;
        case 5:
            marker.fb_rj_pitch5 = pitch; marker.fb_rj_yaw5 = yaw; marker.fb_rj_delay5 = delay;
            break;
        case 6:
            marker.fb_rj_pitch6 = pitch; marker.fb_rj_yaw6 = yaw; marker.fb_rj_delay6 = delay;
            break;
        case 7:
            marker.fb_rj_pitch7 = pitch; marker.fb_rj_yaw7 = yaw; marker.fb_rj_delay7 = delay;
            break;
    }
};

float(entity marker, float path_index) frogbot_get_rj_pitch =
{
    switch (path_index)
    {
        case 0: return marker.fb_rj_pitch0;
        case 1: return marker.fb_rj_pitch1;
        case 2: return marker.fb_rj_pitch2;
        case 3: return marker.fb_rj_pitch3;
        case 4: return marker.fb_rj_pitch4;
        case 5: return marker.fb_rj_pitch5;
        case 6: return marker.fb_rj_pitch6;
        case 7: return marker.fb_rj_pitch7;
    }
    return 0;
};

float(entity marker, float path_index) frogbot_get_rj_yaw =
{
    switch (path_index)
    {
        case 0: return marker.fb_rj_yaw0;
        case 1: return marker.fb_rj_yaw1;
        case 2: return marker.fb_rj_yaw2;
        case 3: return marker.fb_rj_yaw3;
        case 4: return marker.fb_rj_yaw4;
        case 5: return marker.fb_rj_yaw5;
        case 6: return marker.fb_rj_yaw6;
        case 7: return marker.fb_rj_yaw7;
    }
    return 0;
};

float(entity marker, float path_index) frogbot_get_rj_delay =
{
    switch (path_index)
    {
        case 0: return marker.fb_rj_delay0;
        case 1: return marker.fb_rj_delay1;
        case 2: return marker.fb_rj_delay2;
        case 3: return marker.fb_rj_delay3;
        case 4: return marker.fb_rj_delay4;
        case 5: return marker.fb_rj_delay5;
        case 6: return marker.fb_rj_delay6;
        case 7: return marker.fb_rj_delay7;
    }
    return 0;
};

float(entity marker) frogbot_is_marker_entity =
{
    return (marker != world && marker.classname == "frogbot_marker");
};

float(entity marker) frogbot_marker_is_transition =
{
    local entity source;
    local string dynamic_classname;

    if (!frogbot_is_marker_entity(marker))
        return FALSE;

    source = marker.fb_dynsource;
    if (source == world)
        return FALSE;

    dynamic_classname = frogbot_dynamic_marker_classname(source);
    if (dynamic_classname == "trigger_teleport")
        return TRUE;
    if (dynamic_classname == "info_teleport_destination")
        return TRUE;
    if (dynamic_classname == "trigger_push")
        return TRUE;

    return FALSE;
};

float(entity bot) frogbot_recent_teleport =
{
    local float grace;

    if (bot == world)
        return FALSE;

    grace = cvar("frogbot_desync_tp_grace");
    if (grace <= 0)
        grace = 0.8;

    return (bot.tp_time > 0 && bot.tp_time + grace >= time);
};

float(entity marker, entity source, float source_match_dist) frogbot_marker_matches_source =
{
    local entity marker_source;
    local string marker_classname;
    local string source_classname;

    if (!frogbot_is_marker_entity(marker) || source == world)
        return FALSE;

    marker_source = marker.fb_dynsource;
    if (marker_source == source)
        return TRUE;
    if (marker_source == world)
        return FALSE;

    marker_classname = frogbot_dynamic_marker_classname(marker_source);
    source_classname = source.classname;
    if (marker_classname == "" || source_classname == "")
        return FALSE;
    if (marker_classname != source_classname)
        return FALSE;

    if (source_match_dist <= 0)
        source_match_dist = 96;
    if (vlen(marker_source.origin - source.origin) <= source_match_dist)
        return TRUE;

    return FALSE;
};

entity(entity bot, entity source, float source_match_dist) frogbot_find_source_marker =
{
    local float i;
    local float dist;
    local float best_dist;
    local entity marker;
    local entity best;

    if (source == world)
        return world;

    best = world;
    best_dist = 99999999;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_marker_matches_source(marker, source, source_match_dist))
        {
            dist = vlen(marker.origin - bot.origin);
            if (dist < best_dist)
            {
                best_dist = dist;
                best = marker;
            }
        }
        i = i + 1;
    }

    return best;
};

void(entity bot, entity trigger_ent, entity destination_ent) frogbot_post_teleport_transition =
{
    local entity marker;
    local entity previous_marker;
    local entity source_marker;
    local float marker_dist;
    local float source_match_dist;
    local float snap_dist;
    local float snap_bind;
    local string bind_mode;

    if (!frogbot_is_bot_client(bot))
        return;
    if (!frogbot_routes_loaded || frogbot_marker_count <= 0)
        return;

    source_match_dist = cvar("frogbot_post_tp_source_match_dist");
    if (source_match_dist <= 0)
        source_match_dist = 96;

    source_marker = frogbot_find_source_marker(bot, destination_ent, source_match_dist);
    marker = source_marker;
    bind_mode = "dest-source";
    if (marker == world)
    {
        source_marker = frogbot_find_source_marker(bot, trigger_ent, source_match_dist);
        marker = source_marker;
        bind_mode = "trigger-source";
    }
    if (marker == world)
    {
        marker = frogbot_find_nearest_visible_route_marker(bot);
        bind_mode = "route-visible";
    }
    if (marker == world)
    {
        marker = frogbot_find_nearest_route_marker(bot);
        bind_mode = "route-fallback";
    }
    if (marker == world)
    {
        marker = frogbot_find_nearest_visible_marker(bot);
        bind_mode = "visible";
    }
    if (marker == world)
    {
        marker = frogbot_find_nearest_marker(bot);
        bind_mode = "fallback";
    }
    if (marker == world)
        return;

    marker_dist = vlen(marker.origin - bot.origin);
    snap_dist = cvar("frogbot_post_tp_bind_dist");
    if (snap_dist <= 0)
        snap_dist = 192;

    snap_bind = FALSE;
    if (bind_mode == "dest-source" || bind_mode == "trigger-source")
        snap_bind = TRUE;
    else if (marker_dist <= snap_dist)
        snap_bind = TRUE;

    previous_marker = bot.fb_current_marker;
    frogbot_reset_runtime_state(bot);
    bot.fb_prev_marker = previous_marker;
    bot.tp_time = time;

    if (snap_bind)
    {
        bot.fb_current_marker = marker;
        bot.fb_target_marker = world;
        bot.fb_last_target_distance = marker_dist;
    }
    else
    {
        bot.fb_target_marker = marker;
        bot.fb_last_target_distance = marker_dist;
    }
    bot.fb_last_progress_time = time;

    if (cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
        if (frogbot_debug_trace_enabled())
        {
            frogbot_debug_log("");
            frogbot_debug_log("");
        }
    }
};

float(entity bot) frogbot_detect_transition_warp =
{
    local float warp_dist;
    local vector step;

    if (bot == world)
        return FALSE;

    if (bot.oldorigin == '0 0 0')
        return FALSE;

    warp_dist = cvar("frogbot_transition_warp_dist");
    if (warp_dist <= 0)
        warp_dist = 320;

    step = bot.origin - bot.oldorigin;
    return (vlen(step) >= warp_dist);
};

float(entity bot, float radius) frogbot_near_transition_marker =
{
    local float i;
    local entity marker;

    if (bot == world || radius <= 0)
        return FALSE;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_marker_is_transition(marker) && vlen(marker.origin - bot.origin) <= radius)
            return TRUE;
        i = i + 1;
    }

    return FALSE;
};

float(entity bot) frogbot_desync_transition_guard =
{
    local float context_dist;

    if (bot == world)
        return FALSE;

    if (frogbot_recent_teleport(bot))
        return TRUE;

    if (frogbot_detect_transition_warp(bot))
        return TRUE;

    if (frogbot_marker_is_transition(bot.fb_current_marker))
        return TRUE;
    if (frogbot_marker_is_transition(bot.fb_target_marker))
        return TRUE;
    if (frogbot_marker_is_transition(bot.fb_prev_marker))
        return TRUE;

    context_dist = cvar("frogbot_transition_context_dist");
    if (context_dist <= 0)
        context_dist = 224;
    if (frogbot_near_transition_marker(bot, context_dist))
        return TRUE;

    return FALSE;
};

entity(entity marker, float path_index) frogbot_get_path_marker =
{
    switch (path_index)
    {
        case 0: return marker.fb_path0;
        case 1: return marker.fb_path1;
        case 2: return marker.fb_path2;
        case 3: return marker.fb_path3;
        case 4: return marker.fb_path4;
        case 5: return marker.fb_path5;
        case 6: return marker.fb_path6;
        case 7: return marker.fb_path7;
    }
    return world;
};

float(entity marker, entity next_marker, float path_flags) frogbot_route_edge_cost =
{
    local float base_cost;
    local float move_speed;
    local float rj_cost;

    if (!frogbot_is_marker_entity(marker) || !frogbot_is_marker_entity(next_marker))
        return FROGBOT_ROUTE_COST_INF;

    if (next_marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE)
        return FROGBOT_ROUTE_COST_INF;

    move_speed = FROGBOT_MOVE_SPEED;
    if (!(path_flags & (FROGBOT_PATH_ROCKET_JUMP | FROGBOT_PATH_JUMP_LEDGE | FROGBOT_PATH_CURLJUMP_HINT)))
        move_speed = FROGBOT_MOVE_SPEED_CLOSE;

    base_cost = vlen(next_marker.origin - marker.origin) / move_speed;
    if (base_cost < 0.05)
        base_cost = 0.05;

    if (path_flags & FROGBOT_PATH_DM6_DOOR)
        base_cost = base_cost + 0.45;
    if (path_flags & FROGBOT_PATH_WATERJUMP)
        base_cost = base_cost + 0.35;
    if (path_flags & FROGBOT_PATH_VERTICAL_PLATFORM)
        base_cost = base_cost + 0.9;
    if (path_flags & FROGBOT_PATH_JUMP_LEDGE)
        base_cost = base_cost + 0.25;
    if (path_flags & FROGBOT_PATH_CURLJUMP_HINT)
        base_cost = base_cost + 0.08;

    if (path_flags & FROGBOT_PATH_ROCKET_JUMP)
    {
        rj_cost = cvar("frogbot_route_rj_cost");
        if (rj_cost < 0)
            rj_cost = 0;
        base_cost = base_cost + rj_cost;
    }

    if (next_marker.fb_marker_flags & FROGBOT_MARKER_NOTOUCH)
        base_cost = base_cost + 0.35;

    return base_cost;
};

void() frogbot_reset_route_potential_cache =
{
    local float i;
    local entity marker;

    frogbot_route_goal_count = 0;
    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker))
        {
            marker.fb_route_goal_cost = FROGBOT_ROUTE_COST_INF;
            if (marker.fb_goal > 0 && !(marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE))
            {
                marker.fb_route_goal_cost = 0;
                frogbot_route_goal_count = frogbot_route_goal_count + 1;
            }
        }
        i = i + 1;
    }
};

float() frogbot_relax_route_potential_pass =
{
    local float changed;
    local float i;
    local float j;
    local float path_flags;
    local float edge_cost;
    local float old_cost;
    local float best_cost;
    local float candidate;
    local entity marker;
    local entity next_marker;

    changed = 0;
    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (!frogbot_is_marker_entity(marker) || (marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE))
        {
            i = i + 1;
            continue;
        }

        old_cost = marker.fb_route_goal_cost;
        best_cost = old_cost;

        j = 0;
        while (j < FROGBOT_MAX_PATHS)
        {
            next_marker = frogbot_get_path_marker(marker, j);
            if (frogbot_is_marker_entity(next_marker) && !(next_marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE))
            {
                path_flags = frogbot_get_path_flags(marker, j);
                edge_cost = frogbot_route_edge_cost(marker, next_marker, path_flags);
                if (edge_cost < FROGBOT_ROUTE_COST_INF && next_marker.fb_route_goal_cost < FROGBOT_ROUTE_COST_INF)
                {
                    candidate = next_marker.fb_route_goal_cost + edge_cost;
                    if (candidate + 0.001 < best_cost)
                        best_cost = candidate;
                }
            }
            j = j + 1;
        }

        if (best_cost + 0.001 < old_cost)
        {
            marker.fb_route_goal_cost = best_cost;
            changed = changed + 1;
        }

        i = i + 1;
    }

    return changed;
};

void() frogbot_rebuild_route_potential_cache =
{
    local float pass;
    local float max_passes;
    local float changed;
    local float unresolved;
    local float i;
    local entity marker;

    frogbot_reset_route_potential_cache();
    if (frogbot_route_goal_count <= 0)
    {
        frogbot_route_potential_ready = FALSE;
        frogbot_route_relax_iterations = 0;
        return;
    }

    max_passes = cvar("frogbot_route_relax_passes");
    if (max_passes <= 0)
        max_passes = frogbot_marker_count * 2;
    max_passes = bound(16, max_passes, 1024);

    pass = 0;
    while (pass < max_passes)
    {
        changed = frogbot_relax_route_potential_pass();
        pass = pass + 1;
        if (changed <= 0)
            break;
    }

    unresolved = 0;
    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker)
            && !(marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE)
            && marker.fb_route_goal_cost >= FROGBOT_ROUTE_COST_INF * 0.5)
        {
            unresolved = unresolved + 1;
        }
        i = i + 1;
    }

    frogbot_route_potential_ready = TRUE;
    frogbot_route_relax_iterations = pass;

    if (cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
    }
};

float(entity marker) frogbot_marker_slot =
{
    local float slot;

    if (!frogbot_is_marker_entity(marker))
        return -1;

    slot = marker.fb_marker_index - 1;
    if (slot < 0 || slot >= FROGBOT_MAX_MARKERS)
        return -1;

    return slot;
};

float(float marker_slot, float zone_slot) frogbot_zone_cache_index =
{
    return marker_slot * FROGBOT_ZONE_COUNT + zone_slot;
};

float(float marker_slot, float subzone_slot) frogbot_subzone_cache_index =
{
    return marker_slot * FROGBOT_SUBZONE_COUNT + subzone_slot;
};

void() frogbot_reset_zone_cache_tables =
{
    local float i;
    local entity marker;

    i = 0;
    while (i < FROGBOT_ZONE_COUNT)
    {
        frogbot_zone_heads[i] = world;
        frogbot_zone_tails[i] = world;
        frogbot_zone_marker_counts[i] = 0;
        frogbot_zone_subzone_counts[i] = 0;
        i = i + 1;
    }

    i = 0;
    while (i < 7200)
    {
        frogbot_zone_time_cache[i] = FROGBOT_ZONE_INF;
        frogbot_zone_rj_time_cache[i] = FROGBOT_ZONE_INF;
        frogbot_zone_next_cache[i] = world;
        frogbot_zone_next_rj_cache[i] = world;
        i = i + 1;
    }

    i = 0;
    while (i < 9600)
    {
        frogbot_subzone_time_cache[i] = FROGBOT_ZONE_INF;
        frogbot_subzone_rj_time_cache[i] = FROGBOT_ZONE_INF;
        frogbot_subzone_next_cache[i] = world;
        frogbot_subzone_next_rj_cache[i] = world;
        i = i + 1;
    }

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker))
        {
            marker.fb_subzone = -1;
            marker.fb_zone_head = world;
            marker.fb_zone_next = world;
        }

        frogbot_zone_goal_eta[i] = FROGBOT_ZONE_INF;
        frogbot_zone_goal_eta_rj[i] = FROGBOT_ZONE_INF;
        frogbot_zone_goal_marker[i] = world;
        frogbot_zone_goal_marker_rj[i] = world;
        i = i + 1;
    }

    frogbot_zone_cache_ready = FALSE;
    frogbot_zone_relax_iterations = 0;
    frogbot_zone_unresolved = 0;
    frogbot_zone_overflow_count = 0;
    frogbot_zone_assigned_markers = 0;
    frogbot_zone_max_subzones = 0;
    frogbot_zone_used_count = 0;
    frogbot_zone_validation_checks = 0;
    frogbot_zone_validation_failures = 0;
    frogbot_zone_validation_ratio = 0;
};

void() frogbot_build_zone_marker_lists =
{
    local float i;
    local float zone_slot;
    local float subzone_slot;
    local entity marker;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker))
        {
            marker.fb_subzone = -1;
            marker.fb_zone_head = world;
            marker.fb_zone_next = world;

            zone_slot = marker.fb_zone - 1;
            if (zone_slot >= 0 && zone_slot < FROGBOT_ZONE_COUNT)
            {
                subzone_slot = frogbot_zone_subzone_counts[zone_slot];
                if (subzone_slot >= FROGBOT_SUBZONE_COUNT)
                {
                    frogbot_zone_overflow_count = frogbot_zone_overflow_count + 1;
                    subzone_slot = FROGBOT_SUBZONE_COUNT - 1;
                }
                else
                {
                    frogbot_zone_subzone_counts[zone_slot] = subzone_slot + 1;
                    if (frogbot_zone_subzone_counts[zone_slot] > frogbot_zone_max_subzones)
                        frogbot_zone_max_subzones = frogbot_zone_subzone_counts[zone_slot];
                }

                marker.fb_subzone = subzone_slot;
                if (frogbot_zone_heads[zone_slot] == world)
                {
                    frogbot_zone_used_count = frogbot_zone_used_count + 1;
                    frogbot_zone_heads[zone_slot] = marker;
                    frogbot_zone_tails[zone_slot] = marker;
                }
                else
                {
                    if (frogbot_zone_tails[zone_slot] != world)
                        frogbot_zone_tails[zone_slot].fb_zone_next = marker;
                    frogbot_zone_tails[zone_slot] = marker;
                }

                frogbot_zone_marker_counts[zone_slot] = frogbot_zone_marker_counts[zone_slot] + 1;
                frogbot_zone_assigned_markers = frogbot_zone_assigned_markers + 1;
            }
            else
            {
                marker.fb_zone = 0;
            }
        }
        i = i + 1;
    }

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker) && marker.fb_zone > 0)
            marker.fb_zone_head = frogbot_zone_heads[marker.fb_zone - 1];
        i = i + 1;
    }
};

void() frogbot_seed_zone_cache_identity =
{
    local float i;
    local float marker_slot;
    local float zone_slot;
    local float subzone_slot;
    local float table_slot;
    local entity marker;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        marker_slot = frogbot_marker_slot(marker);
        if (marker_slot >= 0)
        {
            zone_slot = marker.fb_zone - 1;
            if (zone_slot >= 0 && zone_slot < FROGBOT_ZONE_COUNT)
            {
                table_slot = frogbot_zone_cache_index(marker_slot, zone_slot);
                frogbot_zone_time_cache[table_slot] = 0;
                frogbot_zone_rj_time_cache[table_slot] = 0;
                frogbot_zone_next_cache[table_slot] = marker;
                frogbot_zone_next_rj_cache[table_slot] = marker;
            }

            subzone_slot = marker.fb_subzone;
            if (subzone_slot >= 0 && subzone_slot < FROGBOT_SUBZONE_COUNT)
            {
                table_slot = frogbot_subzone_cache_index(marker_slot, subzone_slot);
                frogbot_subzone_time_cache[table_slot] = 0;
                frogbot_subzone_rj_time_cache[table_slot] = 0;
                frogbot_subzone_next_cache[table_slot] = marker;
                frogbot_subzone_next_rj_cache[table_slot] = marker;
            }
        }
        i = i + 1;
    }
};

float(entity marker, entity next_marker, float path_flags, float allow_rj) frogbot_route_travel_time =
{
    local float move_speed;
    local float cost;
    local float rj_cost;

    if (!frogbot_is_marker_entity(marker) || !frogbot_is_marker_entity(next_marker))
        return FROGBOT_ZONE_INF;
    if (next_marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE)
        return FROGBOT_ZONE_INF;

    if ((path_flags & FROGBOT_PATH_VERTICAL_PLATFORM) && cvar("frogbot_allow_vertical_paths") <= 0)
        return FROGBOT_ZONE_INF;
    if ((path_flags & FROGBOT_PATH_ROCKET_JUMP) && !allow_rj)
        return FROGBOT_ZONE_INF;

    move_speed = FROGBOT_MOVE_SPEED;
    if (move_speed <= 0)
        move_speed = 300;

    if (path_flags & FROGBOT_PATH_WATERJUMP)
        move_speed = move_speed * 0.78;
    if (path_flags & FROGBOT_PATH_VERTICAL_PLATFORM)
        move_speed = move_speed * 0.72;

    cost = vlen(next_marker.origin - marker.origin) / max(1, move_speed);
    if (cost < 0.02)
        cost = 0.02;

    if (path_flags & FROGBOT_PATH_JUMP_LEDGE)
        cost = cost * 1.2;
    if (path_flags & FROGBOT_PATH_CURLJUMP_HINT)
        cost = cost * 0.92;

    if (path_flags & FROGBOT_PATH_ROCKET_JUMP)
    {
        rj_cost = cvar("frogbot_route_rj_cost");
        if (rj_cost <= 0)
            rj_cost = 0.6;
        cost = cost * rj_cost;
    }

    if (next_marker.fb_marker_flags & FROGBOT_MARKER_NOTOUCH)
        cost = cost + 0.35;

    return bound(0.02, cost, FROGBOT_ZONE_INF * 0.5);
};

float() frogbot_relax_subzone_cache_pass =
{
    local float changed;
    local float i;
    local float j;
    local float s;
    local float marker_slot;
    local float next_slot;
    local float from_table;
    local float next_table;
    local float path_flags;
    local float edge_walk;
    local float edge_rj;
    local float candidate;
    local entity marker;
    local entity next_marker;

    changed = 0;
    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        marker_slot = frogbot_marker_slot(marker);
        if (marker_slot < 0 || marker.fb_zone <= 0)
        {
            i = i + 1;
            continue;
        }

        j = 0;
        while (j < FROGBOT_MAX_PATHS)
        {
            next_marker = frogbot_get_path_marker(marker, j);
            if (!frogbot_is_marker_entity(next_marker) || next_marker.fb_zone != marker.fb_zone)
            {
                j = j + 1;
                continue;
            }

            next_slot = frogbot_marker_slot(next_marker);
            if (next_slot < 0)
            {
                j = j + 1;
                continue;
            }

            path_flags = frogbot_get_path_flags(marker, j);
            edge_walk = frogbot_route_travel_time(marker, next_marker, path_flags, FALSE);
            edge_rj = frogbot_route_travel_time(marker, next_marker, path_flags, TRUE);
            if (edge_walk >= FROGBOT_ZONE_INF * 0.5 && edge_rj >= FROGBOT_ZONE_INF * 0.5)
            {
                j = j + 1;
                continue;
            }

            s = 0;
            while (s < FROGBOT_SUBZONE_COUNT)
            {
                from_table = frogbot_subzone_cache_index(marker_slot, s);
                next_table = frogbot_subzone_cache_index(next_slot, s);

                if (edge_walk < FROGBOT_ZONE_INF * 0.5 && frogbot_subzone_time_cache[next_table] < FROGBOT_ZONE_INF * 0.5)
                {
                    candidate = edge_walk + frogbot_subzone_time_cache[next_table];
                    if (candidate + 0.001 < frogbot_subzone_time_cache[from_table])
                    {
                        frogbot_subzone_time_cache[from_table] = candidate;
                        frogbot_subzone_next_cache[from_table] = next_marker;
                        changed = changed + 1;
                    }
                }

                if (edge_rj < FROGBOT_ZONE_INF * 0.5 && frogbot_subzone_rj_time_cache[next_table] < FROGBOT_ZONE_INF * 0.5)
                {
                    candidate = edge_rj + frogbot_subzone_rj_time_cache[next_table];
                    if (candidate + 0.001 < frogbot_subzone_rj_time_cache[from_table])
                    {
                        frogbot_subzone_rj_time_cache[from_table] = candidate;
                        frogbot_subzone_next_rj_cache[from_table] = next_marker;
                        changed = changed + 1;
                    }
                }

                if (frogbot_subzone_time_cache[from_table] + 0.001 < frogbot_subzone_rj_time_cache[from_table])
                {
                    frogbot_subzone_rj_time_cache[from_table] = frogbot_subzone_time_cache[from_table];
                    frogbot_subzone_next_rj_cache[from_table] = frogbot_subzone_next_cache[from_table];
                }

                s = s + 1;
            }

            j = j + 1;
        }

        i = i + 1;
    }

    return changed;
};

float() frogbot_relax_zone_cache_pass =
{
    local float changed;
    local float i;
    local float j;
    local float z;
    local float marker_slot;
    local float next_slot;
    local float from_table;
    local float next_table;
    local float path_flags;
    local float edge_walk;
    local float edge_rj;
    local float candidate;
    local entity marker;
    local entity next_marker;

    changed = 0;
    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        marker_slot = frogbot_marker_slot(marker);
        if (marker_slot < 0)
        {
            i = i + 1;
            continue;
        }

        j = 0;
        while (j < FROGBOT_MAX_PATHS)
        {
            next_marker = frogbot_get_path_marker(marker, j);
            next_slot = frogbot_marker_slot(next_marker);
            if (next_slot < 0)
            {
                j = j + 1;
                continue;
            }

            path_flags = frogbot_get_path_flags(marker, j);
            edge_walk = frogbot_route_travel_time(marker, next_marker, path_flags, FALSE);
            edge_rj = frogbot_route_travel_time(marker, next_marker, path_flags, TRUE);
            if (edge_walk >= FROGBOT_ZONE_INF * 0.5 && edge_rj >= FROGBOT_ZONE_INF * 0.5)
            {
                j = j + 1;
                continue;
            }

            z = 0;
            while (z < FROGBOT_ZONE_COUNT)
            {
                from_table = frogbot_zone_cache_index(marker_slot, z);
                next_table = frogbot_zone_cache_index(next_slot, z);

                if (edge_walk < FROGBOT_ZONE_INF * 0.5 && frogbot_zone_time_cache[next_table] < FROGBOT_ZONE_INF * 0.5)
                {
                    candidate = edge_walk + frogbot_zone_time_cache[next_table];
                    if (candidate + 0.001 < frogbot_zone_time_cache[from_table])
                    {
                        frogbot_zone_time_cache[from_table] = candidate;
                        frogbot_zone_next_cache[from_table] = next_marker;
                        changed = changed + 1;
                    }
                }

                if (edge_rj < FROGBOT_ZONE_INF * 0.5 && frogbot_zone_rj_time_cache[next_table] < FROGBOT_ZONE_INF * 0.5)
                {
                    candidate = edge_rj + frogbot_zone_rj_time_cache[next_table];
                    if (candidate + 0.001 < frogbot_zone_rj_time_cache[from_table])
                    {
                        frogbot_zone_rj_time_cache[from_table] = candidate;
                        frogbot_zone_next_rj_cache[from_table] = next_marker;
                        changed = changed + 1;
                    }
                }

                if (frogbot_zone_time_cache[from_table] + 0.001 < frogbot_zone_rj_time_cache[from_table])
                {
                    frogbot_zone_rj_time_cache[from_table] = frogbot_zone_time_cache[from_table];
                    frogbot_zone_next_rj_cache[from_table] = frogbot_zone_next_cache[from_table];
                }

                z = z + 1;
            }

            j = j + 1;
        }

        i = i + 1;
    }

    return changed;
};

float(entity from_marker, entity to_marker, float allow_rj) frogbot_subzone_arrival_time =
{
    local float from_slot;
    local float subzone_slot;
    local float table_slot;

    if (!frogbot_zone_cache_ready)
        return FROGBOT_ZONE_INF;
    if (!frogbot_is_marker_entity(from_marker) || !frogbot_is_marker_entity(to_marker))
        return FROGBOT_ZONE_INF;
    if (from_marker.fb_zone <= 0 || from_marker.fb_zone != to_marker.fb_zone)
        return FROGBOT_ZONE_INF;

    subzone_slot = to_marker.fb_subzone;
    if (subzone_slot < 0 || subzone_slot >= FROGBOT_SUBZONE_COUNT)
        return FROGBOT_ZONE_INF;

    from_slot = frogbot_marker_slot(from_marker);
    if (from_slot < 0)
        return FROGBOT_ZONE_INF;

    table_slot = frogbot_subzone_cache_index(from_slot, subzone_slot);
    if (allow_rj)
        return frogbot_subzone_rj_time_cache[table_slot];
    return frogbot_subzone_time_cache[table_slot];
};

entity(entity from_marker, entity to_marker, float allow_rj) frogbot_subzone_next_marker =
{
    local float from_slot;
    local float subzone_slot;
    local float table_slot;
    local entity next_marker;

    if (!frogbot_zone_cache_ready)
        return world;
    if (!frogbot_is_marker_entity(from_marker) || !frogbot_is_marker_entity(to_marker))
        return world;
    if (from_marker == to_marker)
        return to_marker;
    if (from_marker.fb_zone <= 0 || from_marker.fb_zone != to_marker.fb_zone)
        return world;

    subzone_slot = to_marker.fb_subzone;
    if (subzone_slot < 0 || subzone_slot >= FROGBOT_SUBZONE_COUNT)
        return world;

    from_slot = frogbot_marker_slot(from_marker);
    if (from_slot < 0)
        return world;

    table_slot = frogbot_subzone_cache_index(from_slot, subzone_slot);
    if (allow_rj)
        next_marker = frogbot_subzone_next_rj_cache[table_slot];
    else
        next_marker = frogbot_subzone_next_cache[table_slot];

    if (!frogbot_is_marker_entity(next_marker))
        return world;
    return next_marker;
};

float(entity from_marker, entity to_marker, float allow_rj) frogbot_zone_arrival_time =
{
    local float from_slot;
    local float zone_slot;
    local float table_slot;
    local float time_cost;

    if (!frogbot_zone_cache_ready)
        return FROGBOT_ZONE_INF;
    if (!frogbot_is_marker_entity(from_marker) || !frogbot_is_marker_entity(to_marker))
        return FROGBOT_ZONE_INF;
    if (from_marker == to_marker)
        return 0;

    time_cost = frogbot_subzone_arrival_time(from_marker, to_marker, allow_rj);
    if (time_cost < FROGBOT_ZONE_INF * 0.5)
        return time_cost;

    from_slot = frogbot_marker_slot(from_marker);
    if (from_slot < 0)
        return FROGBOT_ZONE_INF;

    zone_slot = to_marker.fb_zone - 1;
    if (zone_slot < 0 || zone_slot >= FROGBOT_ZONE_COUNT)
        return FROGBOT_ZONE_INF;

    table_slot = frogbot_zone_cache_index(from_slot, zone_slot);
    if (allow_rj)
        return frogbot_zone_rj_time_cache[table_slot];
    return frogbot_zone_time_cache[table_slot];
};

entity(entity from_marker, entity to_marker, float allow_rj) frogbot_zone_next_marker =
{
    local float from_slot;
    local float zone_slot;
    local float table_slot;
    local entity next_marker;

    if (!frogbot_zone_cache_ready)
        return world;
    if (!frogbot_is_marker_entity(from_marker) || !frogbot_is_marker_entity(to_marker))
        return world;
    if (from_marker == to_marker)
        return to_marker;

    next_marker = frogbot_subzone_next_marker(from_marker, to_marker, allow_rj);
    if (frogbot_is_marker_entity(next_marker))
        return next_marker;

    from_slot = frogbot_marker_slot(from_marker);
    if (from_slot < 0)
        return world;

    zone_slot = to_marker.fb_zone - 1;
    if (zone_slot < 0 || zone_slot >= FROGBOT_ZONE_COUNT)
        return world;

    table_slot = frogbot_zone_cache_index(from_slot, zone_slot);
    if (allow_rj)
        next_marker = frogbot_zone_next_rj_cache[table_slot];
    else
        next_marker = frogbot_zone_next_cache[table_slot];

    if (!frogbot_is_marker_entity(next_marker))
        return world;
    return next_marker;
};

void() frogbot_rebuild_zone_goal_eta =
{
    local float i;
    local float j;
    local float eta;
    local float eta_rj;
    local float travel;
    local float unresolved;
    local entity marker;
    local entity goal;
    local entity best_goal;
    local entity best_goal_rj;

    unresolved = 0;
    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        frogbot_zone_goal_eta[i] = FROGBOT_ZONE_INF;
        frogbot_zone_goal_eta_rj[i] = FROGBOT_ZONE_INF;
        frogbot_zone_goal_marker[i] = world;
        frogbot_zone_goal_marker_rj[i] = world;

        if (!frogbot_is_marker_entity(marker))
        {
            i = i + 1;
            continue;
        }
        if (marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE)
        {
            i = i + 1;
            continue;
        }

        if (marker.fb_goal > 0)
        {
            frogbot_zone_goal_eta[i] = 0;
            frogbot_zone_goal_eta_rj[i] = 0;
            frogbot_zone_goal_marker[i] = marker;
            frogbot_zone_goal_marker_rj[i] = marker;
            i = i + 1;
            continue;
        }

        eta = FROGBOT_ZONE_INF;
        eta_rj = FROGBOT_ZONE_INF;
        best_goal = world;
        best_goal_rj = world;
        j = 0;
        while (j < FROGBOT_MAX_MARKERS)
        {
            goal = frogbot_markers[j];
            if (frogbot_is_marker_entity(goal)
                && goal.fb_goal > 0
                && !(goal.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE))
            {
                travel = frogbot_zone_arrival_time(marker, goal, FALSE);
                if (travel < eta)
                {
                    eta = travel;
                    best_goal = goal;
                }

                travel = frogbot_zone_arrival_time(marker, goal, TRUE);
                if (travel < eta_rj)
                {
                    eta_rj = travel;
                    best_goal_rj = goal;
                }
            }
            j = j + 1;
        }

        frogbot_zone_goal_eta[i] = eta;
        frogbot_zone_goal_eta_rj[i] = eta_rj;
        frogbot_zone_goal_marker[i] = best_goal;
        frogbot_zone_goal_marker_rj[i] = best_goal_rj;
        if (marker.fb_zone > 0 && eta >= FROGBOT_ZONE_INF * 0.5)
            unresolved = unresolved + 1;

        i = i + 1;
    }

    frogbot_zone_unresolved = unresolved;
};

void() frogbot_validate_zone_cache =
{
    local float checks;
    local float failures;
    local float fail_ratio;

    frogbot_zone_validation_checks = 0;
    frogbot_zone_validation_failures = 0;
    frogbot_zone_validation_ratio = 0;

    if (!frogbot_zone_cache_ready)
        return;
    if (cvar("frogbot_zone_system") <= 0 || cvar("frogbot_zone_validate") <= 0)
        return;
    if (frogbot_route_goal_count <= 0)
        return;

    checks = max(1, frogbot_zone_assigned_markers);
    failures = frogbot_zone_unresolved + frogbot_zone_overflow_count;

    frogbot_zone_validation_checks = checks;
    frogbot_zone_validation_failures = failures;
    frogbot_zone_validation_ratio = failures / checks;

    fail_ratio = cvar("frogbot_zone_validate_fail_ratio");
    if (fail_ratio <= 0)
        fail_ratio = 0.45;

    if (frogbot_zone_validation_ratio > fail_ratio)
        frogbot_zone_cache_ready = FALSE;
};

void() frogbot_rebuild_zone_cache =
{
    local float max_passes;
    local float pass;
    local float changed_zone;
    local float changed_subzone;
    local float changed;

    frogbot_reset_zone_cache_tables();
    if (cvar("frogbot_zone_system") <= 0)
        return;

    frogbot_build_zone_marker_lists();
    if (frogbot_zone_assigned_markers <= 0)
        return;

    frogbot_seed_zone_cache_identity();

    max_passes = cvar("frogbot_zone_relax_passes");
    if (max_passes <= 0)
        max_passes = frogbot_marker_count * 3;
    max_passes = bound(16, max_passes, 2048);

    pass = 0;
    while (pass < max_passes)
    {
        changed_zone = frogbot_relax_zone_cache_pass();
        changed_subzone = frogbot_relax_subzone_cache_pass();
        changed = changed_zone + changed_subzone;
        pass = pass + 1;
        if (changed <= 0)
            break;
    }

    frogbot_zone_relax_iterations = pass;
    frogbot_zone_cache_ready = TRUE;
    frogbot_rebuild_zone_goal_eta();
    frogbot_validate_zone_cache();

    if (cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
    }
};

float(entity bot, vector delta, float trace_dist) frogbot_obstruction_ahead =
{
    local vector forward;
    local vector start;
    local vector finish;
    local vector ledge_start;
    local vector ledge_end;

    if (trace_dist <= 0)
        trace_dist = 54;

    forward = v_forward;
    if (vlen(forward) < 0.001 && vlen(delta) > 0.001)
        forward = normalize(delta);
    if (vlen(forward) < 0.001)
        return FALSE;

    start = bot.origin;
    start_z = start_z + 24;
    finish = start + forward * trace_dist;

    traceline(start, finish, TRUE, bot);
    if (trace_fraction < 0.82 && trace_ent != bot.fb_target_marker)
        return TRUE;

    // Detect sharp ledges in front of the bot and bias toward sidestep/jump recovery.
    ledge_start = bot.origin + forward * (trace_dist * 0.65);
    ledge_start_z = ledge_start_z + 8;
    ledge_end = ledge_start;
    ledge_end_z = ledge_end_z - 84;
    traceline(ledge_start, ledge_end, TRUE, bot);
    if (trace_fraction >= 1 && bot.waterlevel <= 1)
        return TRUE;

    return FALSE;
};

void(entity bot, vector delta, float move_speed, float in_combat) frogbot_apply_blocked_recovery =
{
    local float trace_dist;
    local float side_push;
    local float blocked;

    if (cvar("frogbot_blocked_avoid") <= 0)
        return;
    if (bot.fb_rj_pending)
        return;
    if (!(bot.flags & (FL_ONGROUND | FL_PARTIALGROUND)))
        return;
    if (bot.waterlevel > 1)
        return;

    trace_dist = cvar("frogbot_blocked_trace_dist");
    if (trace_dist <= 0)
        trace_dist = 54;
    if (vlen(delta) > 320)
        trace_dist = trace_dist + 18;

    blocked = frogbot_obstruction_ahead(bot, delta, trace_dist);
    if (!blocked)
        return;

    if (bot.fb_next_strafe_swap_time <= time)
    {
        bot.fb_strafe_dir = (random() < 0.5) ? -1 : 1;
        bot.fb_next_strafe_swap_time = time + 0.35 + random() * 0.6;
    }

    side_push = bot.fb_strafe_dir * bound(60, move_speed * 0.75, 180);
    bot.movement_y = bot.movement_y + side_push;

    if (vlen(delta) < 100)
        bot.movement_x = bot.movement_x - bound(45, move_speed * 0.4, 120);

    if (!in_combat && bot.fb_next_jump_time <= time)
    {
        bot.button2 = 1;
        bot.fb_next_jump_time = time + 0.33;
    }

    if (cvar("frogbot_debug") >= 3 && bot.fb_next_move_log_time <= time)
    {
        frogbot_debug_log("");
    }
};

float(entity bot, vector delta, float move_speed) frogbot_apply_water_movement =
{
    local float want_jump;
    local float up_bias;
    local float swim_z;

    want_jump = FALSE;
    if (bot.waterlevel <= 1)
        return FALSE;

    // Rocket-jump sequencing is invalid underwater.
    bot.fb_rj_pending = 0;
    bot.fb_rj_fire_time = 0;

    up_bias = cvar("frogbot_water_vertical_bias");
    if (up_bias <= 0)
        up_bias = 36;

    if (bot.air_finished < time + 1.1)
        want_jump = TRUE;

    swim_z = 18;
    if (delta_z > up_bias)
        swim_z = bound(110, move_speed * 0.62, 240);
    else if (delta_z < -up_bias)
        swim_z = -bound(90, move_speed * 0.55, 220);

    if (bot.watertype == CONTENT_LAVA || bot.watertype == CONTENT_SLIME)
    {
        swim_z = bound(170, move_speed, 280);
        want_jump = TRUE;
    }

    if (bot.fb_next_strafe_swap_time <= time)
    {
        bot.fb_strafe_dir = (random() < 0.5) ? -1 : 1;
        bot.fb_next_strafe_swap_time = time + 0.35 + random() * 0.6;
    }

    bot.movement_z = swim_z;
    bot.movement_y = bot.movement_y + (bot.fb_strafe_dir * bound(30, move_speed * 0.3, 80));

    return want_jump;
};

entity(entity bot, float max_dist) frogbot_find_hazard_escape_marker =
{
    local float i;
    local float dist;
    local float score;
    local float best_score;
    local float hazard_level;
    local vector trace_start;
    local vector trace_end;
    local entity marker;
    local entity best_marker;

    if (max_dist <= 0)
        max_dist = 512;

    best_marker = world;
    best_score = 999999;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker) && !(marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE))
        {
            dist = vlen(marker.origin - bot.origin);
            if (dist <= max_dist)
            {
                hazard_level = frogbot_marker_hazard_level(marker);
                if (hazard_level < 1 || (marker.fb_marker_flags & FROGBOT_MARKER_ESCAPE_ROUTE))
                {
                    trace_start = bot.origin;
                    trace_start_z = trace_start_z + 24;
                    trace_end = marker.origin;
                    trace_end_z = trace_end_z + 24;
                    traceline(trace_start, trace_end, TRUE, bot);
                    if (trace_fraction >= 0.92 || trace_ent == marker || trace_ent == world)
                    {
                        score = dist + (hazard_level * 220);
                        if (marker.fb_marker_flags & FROGBOT_MARKER_ESCAPE_ROUTE)
                            score = score - 120;
                        if (score < best_score)
                        {
                            best_score = score;
                            best_marker = marker;
                        }
                    }
                }
            }
        }
        i = i + 1;
    }

    return best_marker;
};

float(entity bot) frogbot_apply_hazard_escape =
{
    local float max_dist;
    local float current_hazard;
    local float target_hazard;
    local entity escape_marker;

    if (cvar("frogbot_hazard_escape") <= 0)
        return FALSE;
    if (!(bot.watertype == CONTENT_LAVA || bot.watertype == CONTENT_SLIME))
        return FALSE;

    current_hazard = 1;
    if (frogbot_is_marker_entity(bot.fb_current_marker))
        current_hazard = frogbot_marker_hazard_level(bot.fb_current_marker);

    target_hazard = 2;
    if (frogbot_is_marker_entity(bot.fb_target_marker))
        target_hazard = frogbot_marker_hazard_level(bot.fb_target_marker);

    if (frogbot_is_marker_entity(bot.fb_target_marker) && target_hazard < current_hazard && bot.fb_last_progress_time + 0.35 > time)
        return FALSE;

    max_dist = cvar("frogbot_hazard_escape_dist");
    if (max_dist <= 0)
        max_dist = 512;

    escape_marker = frogbot_find_hazard_escape_marker(bot, max_dist);
    if (escape_marker == world)
        return FALSE;
    if (bot.fb_target_marker == escape_marker && bot.fb_last_progress_time + 0.35 > time)
        return FALSE;

    bot.fb_target_marker = escape_marker;
    bot.fb_target_path_index = -1;
    bot.fb_target_path_flags = FROGBOT_PATH_WATERJUMP;
    bot.fb_target_path_hint = 0;
    bot.fb_target_rj_delay = 0;
    bot.fb_rj_pending = 0;
    bot.fb_rj_fire_time = 0;
    bot.fb_stuck_count = 0;
    bot.fb_last_target_distance = vlen(escape_marker.origin - bot.origin);
    bot.fb_last_progress_time = time;

    if (cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
    }

    return TRUE;
};

entity(entity bot, entity enemy, float max_dist) frogbot_find_combat_escape_marker =
{
    local float i;
    local float dist;
    local float enemy_dist;
    local float enemy_gain;
    local float score;
    local float best_score;
    local float current_enemy_dist;
    local float hazard_level;
    local vector trace_start;
    local vector trace_end;
    local entity marker;
    local entity best_marker;

    if (bot == world || enemy == world)
        return world;
    if (max_dist <= 0)
        max_dist = 900;

    best_marker = world;
    best_score = -999999;
    current_enemy_dist = vlen(bot.origin - enemy.origin);

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker)
            && !(marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE)
            && marker.fb_blocked_until <= time)
        {
            dist = vlen(marker.origin - bot.origin);
            if (dist >= 64 && dist <= max_dist)
            {
                enemy_dist = vlen(marker.origin - enemy.origin);
                enemy_gain = enemy_dist - current_enemy_dist;
                if (enemy_gain > 80)
                {
                    trace_start = bot.origin;
                    trace_start_z = trace_start_z + 24;
                    trace_end = marker.origin;
                    trace_end_z = trace_end_z + 24;
                    traceline(trace_start, trace_end, TRUE, bot);
                    if (trace_fraction >= 0.85 || trace_ent == marker || trace_ent == world)
                    {
                        hazard_level = frogbot_marker_hazard_level(marker);
                        score = enemy_gain * 1.6 - dist;
                        score = score - (hazard_level * 180);
                        if (marker.fb_marker_flags & FROGBOT_MARKER_ESCAPE_ROUTE)
                            score = score + 220;
                        if (marker == bot.fb_prev_marker)
                            score = score + 40;
                        if (score > best_score)
                        {
                            best_score = score;
                            best_marker = marker;
                        }
                    }
                }
            }
        }
        i = i + 1;
    }

    if (best_score <= 0)
        return world;

    return best_marker;
};

float(entity bot, entity enemy) frogbot_apply_combat_escape =
{
    local float enemy_dist;
    local float enemy_dist_gate;
    local float max_dist;
    local float strength_ratio;
    local float min_strength;
    local float hold_time;
    local float cooldown;
    local float bot_strength;
    local float enemy_strength;
    local float low_strength;
    local float outgunned;
    local float recently_hurt;
    local float should_escape;
    local float escape_active;
    local float enemy_power_flags;
    local float enemy_power_threat;
    local float carrier_escape_bias;
    local vector escape_state;
    local vector power_state;
    local entity escape_marker;

    if (cvar("frogbot_combat_escape") <= 0)
        return FALSE;
    if (bot == world || enemy == world)
        return FALSE;
    if (!frogbot_is_enemy_client(bot, enemy))
        return FALSE;
    if (bot.waterlevel > 1)
        return FALSE;

    enemy_dist_gate = cvar("frogbot_combat_escape_enemy_dist");
    if (enemy_dist_gate <= 0)
        enemy_dist_gate = 650;
    enemy_dist = vlen(enemy.origin - bot.origin);

    escape_active = (bot.fb_combat_escape_until > time);
    if (!escape_active && enemy_dist > enemy_dist_gate)
        return FALSE;

    strength_ratio = cvar("frogbot_combat_escape_ratio");
    if (strength_ratio <= 1)
        strength_ratio = 1.25;
    min_strength = cvar("frogbot_combat_escape_min_strength");
    if (min_strength <= 0)
        min_strength = 130;
    carrier_escape_bias = frogbot_ctf_bot_has_enemy_flag(bot);
    if (carrier_escape_bias)
    {
        enemy_dist_gate = enemy_dist_gate * 1.18;
        strength_ratio = min(strength_ratio, 1.1);
        if (min_strength < 175)
            min_strength = 175;
    }

    bot_strength = max(bot.fb_total_damage, frogbot_total_strength(bot.health, bot.armorvalue, bot.armortype) * frogbot_rune_scale_res(bot));
    enemy_strength = frogbot_total_strength(enemy.health, enemy.armorvalue, enemy.armortype) * frogbot_rune_scale_res(enemy);
    enemy_power_flags = 0;
    enemy_power_threat = 1;
    if (frogbot_powerup_awareness_enabled())
    {
        enemy_power_flags = frogbot_enemy_power_flags(enemy);
        if (enemy == bot.fb_enemy_target && enemy_power_flags <= 0)
            enemy_power_flags = bot.fb_enemy_power_flags;
        enemy_power_threat = frogbot_enemy_power_threat(bot, enemy);
        enemy_strength = enemy_strength * enemy_power_threat;
    }
    low_strength = (bot_strength < min_strength || bot.health < 45);
    outgunned = (enemy_strength > bot_strength * strength_ratio);
    recently_hurt = (bot.fb_last_hurt_time > 0 && (time - bot.fb_last_hurt_time) < 0.6);
    should_escape = (low_strength || outgunned || recently_hurt);
    if (carrier_escape_bias
        && enemy_dist <= enemy_dist_gate * 1.1
        && (bot.health < 120 || bot.armorvalue < 90))
    {
        should_escape = TRUE;
    }

    if (frogbot_powerup_awareness_enabled() && !frogbot_has_pent(bot))
    {
        if (enemy_power_flags & FROGBOT_ENEMY_POWER_PENT)
            should_escape = TRUE;
        else if ((enemy_power_flags & FROGBOT_ENEMY_POWER_QUAD) && bot_strength < min_strength * 1.25)
            should_escape = TRUE;
    }

    if (frogbot_has_pent(bot)
        && !(enemy_power_flags & FROGBOT_ENEMY_POWER_PENT)
        && enemy_dist <= enemy_dist_gate * 0.95
        && bot_strength + 20 >= enemy_strength * 0.75)
    {
        should_escape = FALSE;
    }

    if (!escape_active && !should_escape)
        return FALSE;
    if (escape_active && !should_escape && enemy_dist > enemy_dist_gate * 1.1)
    {
        bot.fb_combat_escape_until = 0;
        return FALSE;
    }

    cooldown = cvar("frogbot_combat_escape_cooldown");
    if (cooldown <= 0)
        cooldown = 0.85;
    if (!escape_active && bot.fb_next_combat_escape_time > time)
        return FALSE;

    max_dist = cvar("frogbot_combat_escape_max_dist");
    if (max_dist <= 0)
        max_dist = 900;

    escape_marker = frogbot_find_combat_escape_marker(bot, enemy, max_dist);
    if (escape_marker == world)
    {
        if (escape_active)
            return TRUE;
        return FALSE;
    }

    if (!(bot.fb_target_marker == escape_marker && bot.fb_last_progress_time + 0.25 > time))
    {
        bot.fb_target_marker = escape_marker;
        bot.fb_target_path_index = -1;
        bot.fb_target_path_flags = 0;
        bot.fb_target_path_hint = 0;
        bot.fb_target_rj_delay = 0;
        bot.fb_rj_pending = 0;
        bot.fb_rj_fire_time = 0;
        bot.fb_stuck_count = 0;
        bot.fb_last_target_distance = vlen(escape_marker.origin - bot.origin);
        bot.fb_last_progress_time = time;
    }

    hold_time = cvar("frogbot_combat_escape_hold");
    if (hold_time <= 0)
        hold_time = 1.25;
    if (carrier_escape_bias)
        hold_time = max(hold_time, 1.55);
    if (should_escape)
    {
        bot.fb_combat_escape_until = max(bot.fb_combat_escape_until, time + hold_time);
        bot.fb_next_combat_escape_time = time + cooldown;
        if (!escape_active)
        {
            local string help_loc;
            help_loc = frogbot_get_location(bot.origin);
            if (help_loc != "")
                frogbot_team_say(bot, sprintf("need help at %s, backing off", help_loc));
            else
                frogbot_team_say(bot, "need help, backing off");
        }
    }

    if (cvar("frogbot_debug") >= 2)
    {
        escape_state = '0 0 0';
        escape_state_x = low_strength;
        escape_state_y = outgunned;
        escape_state_z = recently_hurt;

        power_state = '0 0 0';
        power_state_x = enemy_power_flags;
        power_state_y = enemy_power_threat;

        frogbot_debug_log("");
    }

    return TRUE;
};

void(entity bot) frogbot_stop_movement =
{
    if (bot.fb_hook_climb_state > 0)
        frogbot_hook_climb_abort(bot);
    bot.movement = '0 0 0';
    bot.button0 = 0;
    bot.button1 = 0;
    bot.button2 = 0;
    bot.fb_rj_pending = 0;
    bot.fb_rj_fire_time = 0;
};

void(entity bot) frogbot_clear_runtime_targets =
{
    bot.fb_prev_marker = world;
    bot.fb_current_marker = world;
    bot.fb_target_marker = world;
    bot.fb_target_path_index = -1;
    bot.fb_target_path_flags = 0;
    bot.fb_failed_from_marker = world;
    bot.fb_failed_to_marker = world;
    bot.fb_failed_until = 0;
    bot.fb_last_progress_time = time;
    bot.fb_last_target_distance = 999999;
    bot.fb_stuck_count = 0;
    bot.fb_enemy_target = world;
    bot.fb_enemy_power_flags = 0;
    bot.fb_enemy_power_seen_time = 0;
    bot.fb_enemy_quad_until = 0;
    bot.fb_enemy_pent_until = 0;
    bot.fb_enemy_power_threat = 0;
    bot.fb_target_path_hint = 0;
    bot.fb_target_rj_delay = 0;
    bot.fb_rj_pending = 0;
    bot.fb_rj_fire_time = 0;
    bot.fb_rj_pitch = 0;
    bot.fb_rj_yaw = 0;
    bot.fb_hook_climb_state = 0;
    bot.fb_hook_climb_start_time = 0;
    bot.fb_hook_climb_target_z = 0;
    bot.fb_hook_climb_prev_weapon = 0;
    bot.fb_hook_climb_aim = '0 0 0';
    bot.fb_combat_escape_until = 0;
    bot.fb_next_combat_escape_time = 0;
    bot.fb_dodge_missile = world;
    bot.fb_team_has_contact = 0;
    bot.fb_camp_until = 0;
    bot.fb_next_camp_time = time;
    bot.fb_camp_marker = world;
};

void(entity bot) frogbot_reset_runtime_state =
{
    frogbot_clear_runtime_targets(bot);
    bot.fb_next_desire_refresh = 0;
    bot.fb_next_route_log_time = time;
    bot.fb_next_move_log_time = time;
    bot.fb_next_enemy_scan_time = time;
    bot.fb_last_enemy_seen_time = 0;
    bot.fb_next_teammsg_time = time + random() * 2;
    bot.fb_next_powerup_call_time = time + random() * 2;
    bot.fb_team_has_contact = 0;
    bot.fb_next_combat_log_time = time;
    bot.fb_strafe_dir = 1;
    bot.fb_next_strafe_swap_time = time;
    bot.fb_next_jump_time = time;
    bot.fb_aim_volatility = bot.fb_vol_initial;
    bot.fb_min_fire_time = 0;
    bot.fb_aim_rnd_pitch = 0;
    bot.fb_aim_rnd_yaw = 0;
    bot.fb_aim_rnd_time = 0;
    bot.fb_last_hurt_time = 0;
    bot.fb_prev_combat_target = world;
    bot.fb_prev_enemy_vel = '0 0 0';
    bot.fb_next_dodge_log_time = time;
    bot.fb_combat_escape_until = 0;
    bot.fb_next_combat_escape_time = 0;
    bot.fb_camp_until = 0;
    bot.fb_next_camp_time = time + 2 + random() * 2;
    bot.fb_camp_marker = world;
    frogbot_ctf_reset_runtime_state(bot);
};

entity(entity bot) frogbot_find_nearest_marker =
{
    local float i;
    local float dist;
    local float best_dist;
    local float blocked_best_dist;
    local entity marker;
    local entity best;
    local entity blocked_best;

    best = world;
    blocked_best = world;
    best_dist = 99999999;
    blocked_best_dist = 99999999;
    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker))
        {
            dist = vlen(marker.origin - bot.origin);
            if (marker.fb_blocked_until > time)
            {
                if (dist < blocked_best_dist)
                {
                    blocked_best_dist = dist;
                    blocked_best = marker;
                }
                i = i + 1;
                continue;
            }
            if (dist < best_dist)
            {
                best_dist = dist;
                best = marker;
            }
        }
        i = i + 1;
    }

    if (best != world)
        return best;
    return blocked_best;
};

float(entity bot, entity marker) frogbot_marker_visible =
{
    local vector start;
    local vector goal;

    if (!frogbot_is_marker_entity(marker))
        return FALSE;

    start = bot.origin;
    start_z = start_z + 24;
    goal = marker.origin;
    goal_z = goal_z + marker.view_ofs_z;
    traceline(start, goal, TRUE, bot);
    if (trace_fraction >= 1)
        return TRUE;
    if (trace_ent == marker)
        return TRUE;
    return FALSE;
};

entity(entity bot) frogbot_find_nearest_visible_marker =
{
    local float i;
    local float dist;
    local float best_dist;
    local float blocked_best_dist;
    local entity marker;
    local entity best;
    local entity blocked_best;

    best = world;
    blocked_best = world;
    best_dist = 99999999;
    blocked_best_dist = 99999999;
    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_is_marker_entity(marker) && frogbot_marker_visible(bot, marker))
        {
            dist = vlen(marker.origin - bot.origin);
            if (marker.fb_blocked_until > time)
            {
                if (dist < blocked_best_dist)
                {
                    blocked_best_dist = dist;
                    blocked_best = marker;
                }
                i = i + 1;
                continue;
            }
            if (dist < best_dist)
            {
                best_dist = dist;
                best = marker;
            }
        }
        i = i + 1;
    }

    if (best != world)
        return best;
    return blocked_best;
};

float(entity bot) frogbot_can_use_rocket_launcher =
{
    if (bot == world)
        return FALSE;
    if (!(bot.items & IT_ROCKET_LAUNCHER))
        return FALSE;
    if (bot.ammo_rockets < 1)
        return FALSE;
    return TRUE;
};

float(entity bot) frogbot_can_rj_now =
{
    local float hp_armor;
    local float min_hp_armor;

    if (cvar("frogbot_enable_rj") <= 0)
        return FALSE;
    if (bot == world)
        return FALSE;
    if (bot.waterlevel > 1)
        return FALSE;
    if (!frogbot_can_use_rocket_launcher(bot))
        return FALSE;

    if ((bot.items & IT_INVULNERABILITY) || (bot.items & IT_QUAD))
        return TRUE;

    hp_armor = bot.health + bot.armorvalue;
    min_hp_armor = cvar("frogbot_rj_min_hp_armor");
    if (min_hp_armor <= 0)
        min_hp_armor = 90;

    return (hp_armor >= min_hp_armor);
};

float(entity bot) frogbot_can_use_rj_paths =
{
    if (frogbot_can_rj_now(bot))
        return TRUE;
    if (frogbot_can_hook_climb(bot))
        return TRUE;
    return FALSE;
};

float(string classname) frogbot_is_item_goal_class =
{
    if (classname == "")
        return FALSE;

    if (substring(classname, 0, 5) == "item_")
        return TRUE;
    if (substring(classname, 0, 7) == "weapon_")
        return TRUE;
    if (classname == "item_weapon")
        return TRUE;
    if (classname == "item_backpack")
        return TRUE;

    return FALSE;
};

float(entity source) frogbot_dynamic_source_available =
{
    source = frogbot_dynamic_source_for_marker(source);
    if (source == world)
        return FALSE;
    if (source.solid != SOLID_TRIGGER)
        return FALSE;
    if (source.model == "" || source.model == string_null)
        return FALSE;
    return TRUE;
};

float(entity bot) frogbot_skill_lookahead_window =
{
    local float lookahead_time;

    if (bot == world)
        return 12;

    lookahead_time = bot.fb_skill_lookahead_time;
    if (lookahead_time <= 0)
        lookahead_time = 12;

    return lookahead_time;
};

float(entity bot, float eta) frogbot_skill_lookahead_scale =
{
    local float lookahead_time;

    if (eta <= 0)
        return 1;

    lookahead_time = frogbot_skill_lookahead_window(bot);
    if (eta >= lookahead_time)
        return 0;

    return bound(0.05, (lookahead_time - eta) / max(1, lookahead_time), 1);
};

float(entity bot, entity from_marker, entity to_marker) frogbot_skill_goal_eta =
{
    local float allow_rj;
    local float travel_eta;
    local float move_speed;

    if (!frogbot_is_marker_entity(from_marker) || !frogbot_is_marker_entity(to_marker))
        return 0;
    if (from_marker == to_marker)
        return 0;

    allow_rj = frogbot_can_use_rj_paths(bot);
    travel_eta = frogbot_zone_arrival_time(from_marker, to_marker, allow_rj);
    if (travel_eta < FROGBOT_ZONE_INF * 0.5)
        return max(0, travel_eta);

    move_speed = FROGBOT_MOVE_SPEED;
    if (move_speed <= 0)
        move_speed = 300;
    travel_eta = vlen(to_marker.origin - from_marker.origin) / max(1, move_speed);
    return max(0, travel_eta);
};

float(entity bot, entity source) frogbot_dynamic_source_respawn_eta =
{
    local float eta;
    local float err;
    local float phase;
    local float noise;

    source = frogbot_dynamic_source_for_marker(source);
    if (source == world)
        return 999999;
    if (source.solid == SOLID_TRIGGER && source.model != "" && source.model != string_null)
        return 0;
    if (source.nextthink > time && source.nextthink < time + 9999)
    {
        eta = source.nextthink - time;
        if (bot != world)
        {
            err = bound(0, bot.fb_skill_prediction_error, 1);
            if (err > 0.001)
            {
                phase = floor(time * 2);
                noise = sin((source.origin_x * 0.0091)
                            + (source.origin_y * 0.0113)
                            + (source.origin_z * 0.0137)
                            + phase);
                noise = (noise + 1) * 0.5;
                eta = eta + (eta * err * noise);
            }
        }
        return eta;
    }
    return 999999;
};

float(float health, float armor_value, float armor_type) frogbot_total_strength =
{
    local float denom;

    if (match_in_progress() < 2)
        return 1000;

    denom = 1 - armor_type;
    if (denom <= 0.01)
        denom = 0.01;

    return max(0, min(health / denom, health + armor_value));
};

void(entity bot) frogbot_set_health_armor_desire =
{
    local float new_health;

    if (bot == world)
        return;

    bot.fb_total_armor = bot.armortype * bot.armorvalue;
    bot.fb_total_damage = frogbot_total_strength(bot.health, bot.armorvalue, bot.armortype);

    bot.fb_desire_armor1 = 0;
    bot.fb_desire_armor2 = 0;
    bot.fb_desire_armorInv = 0;
    if (bot.fb_total_armor < 160)
    {
        bot.fb_desire_armorInv = max(0, frogbot_total_strength(bot.health, 200, 0.8) - bot.fb_total_damage);

        if (bot.fb_total_armor < 90)
        {
            bot.fb_desire_armor2 = max(0, frogbot_total_strength(bot.health, 150, 0.6) - bot.fb_total_damage);

            if (bot.fb_total_armor < 30)
            {
                bot.fb_desire_armor1 = max(0, 2 * (frogbot_total_strength(bot.health, 100, 0.3) - bot.fb_total_damage));
            }
        }
    }

    bot.fb_desire_health0 = 0;
    bot.fb_desire_mega_health = 0;
    if (bot.health < 250)
    {
        new_health = min(bot.health + 100, 250);
        bot.fb_desire_mega_health = frogbot_total_strength(new_health, bot.armorvalue, bot.armortype) - bot.fb_total_damage;

        if (bot.health < 100)
        {
            new_health = min(bot.health + 25, 100);
            bot.fb_desire_health0 = 2 * (frogbot_total_strength(new_health, bot.armorvalue, bot.armortype) - bot.fb_total_damage);
        }
    }

    // KTX parity: resistance rune increases effective durability for bot decisions.
    bot.fb_total_damage = bot.fb_total_damage * frogbot_rune_scale_res(bot);
};

void(entity bot) frogbot_set_firepower_desire =
{
    local float items_;
    local float firepower_;
    local float attackbonus;

    if (bot == world)
        return;

    items_ = bot.items;
    firepower_ = 100;
    attackbonus = 0;

    bot.fb_desire_supershotgun = 0;
    bot.fb_desire_nailgun = 0;
    bot.fb_desire_supernailgun = 0;
    bot.fb_desire_grenadelauncher = 0;
    bot.fb_desire_rocketlauncher = 0;
    bot.fb_desire_lightning = 0;
    bot.fb_desire_rockets = 0;
    bot.fb_desire_cells = 0;
    bot.fb_desire_nails = 0;
    bot.fb_desire_shells = 0;

    if (deathmatch != 4)
    {
        firepower_ = 0;
        if (items_ & IT_ROCKET_LAUNCHER)
        {
            firepower_ = bot.ammo_rockets * 8;
            if (bot.ammo_rockets > 0)
                attackbonus = 50;
        }
        else if (items_ & IT_GRENADE_LAUNCHER)
        {
            firepower_ = bot.ammo_rockets * 6;
            if (firepower_ > 50)
                firepower_ = 50;
        }

        if (items_ & IT_LIGHTNING)
        {
            firepower_ = firepower_ + bot.ammo_cells;
            if (bot.ammo_cells >= 10)
                attackbonus = attackbonus + 50;
        }

        if (items_ & (IT_NAILGUN | IT_SUPER_NAILGUN))
            firepower_ = firepower_ + (bot.ammo_nails * 0.1);

        if (items_ & IT_SUPER_SHOTGUN)
        {
            if (bot.ammo_shells >= 50)
                firepower_ = firepower_ + 20;
            else
                firepower_ = firepower_ + (bot.ammo_shells * 0.4);
        }
        else
        {
            if (bot.ammo_shells >= 25)
                firepower_ = firepower_ + 10;
            else
                firepower_ = firepower_ + (bot.ammo_shells * 0.4);
        }

        firepower_ = min(firepower_, 100);

        bot.fb_desire_rockets = max(5, 20 - bot.ammo_rockets);
        bot.fb_desire_cells = max(2.5, (50 - bot.ammo_cells) * 0.2);
        bot.fb_desire_rocketlauncher = max(100 - firepower_, bot.fb_desire_rockets);
        bot.fb_desire_lightning = max(bot.fb_desire_rocketlauncher, bot.fb_desire_cells);

        if (items_ & IT_ROCKET_LAUNCHER)
        {
            bot.fb_desire_rockets = bot.fb_desire_rocketlauncher;
            bot.fb_desire_grenadelauncher = bot.fb_desire_rocketlauncher;
        }
        else
        {
            bot.fb_desire_grenadelauncher = 0;
            if (firepower_ < 50)
                bot.fb_desire_grenadelauncher = 50 - firepower_;
            if (bot.fb_desire_grenadelauncher < bot.fb_desire_rockets)
                bot.fb_desire_grenadelauncher = bot.fb_desire_rockets;

            if (items_ & IT_GRENADE_LAUNCHER)
                bot.fb_desire_rockets = bot.fb_desire_grenadelauncher;
        }

        if (items_ & IT_LIGHTNING)
            bot.fb_desire_cells = bot.fb_desire_lightning;

        if (firepower_ < 20)
        {
            bot.fb_desire_nails = 2.5 - (bot.ammo_nails * 0.0125);
            if (bot.ammo_shells < 50)
                bot.fb_desire_shells = 2.5 - (bot.ammo_shells * 0.05);
        }

        bot.fb_desire_supershotgun = max(0, 20 - firepower_);
        bot.fb_desire_nailgun = max(bot.fb_desire_supershotgun, bot.fb_desire_nails);
        bot.fb_desire_supernailgun = bot.fb_desire_nailgun;
        bot.fb_desire_supershotgun = max(bot.fb_desire_supershotgun, bot.fb_desire_shells);

        if (items_ & (IT_NAILGUN | IT_SUPER_NAILGUN))
            bot.fb_desire_nails = bot.fb_desire_supernailgun;
        if (items_ & IT_SUPER_SHOTGUN)
            bot.fb_desire_shells = bot.fb_desire_supershotgun;

        firepower_ = bound(0, firepower_ + attackbonus, 100);
    }

    if (bot.super_damage_finished > time)
        firepower_ = firepower_ * (deathmatch == 4 ? 8 : 4);
    firepower_ = firepower_ * frogbot_rune_scale_str(bot);

    bot.fb_firepower = firepower_;
};

void(entity bot) frogbot_refresh_item_desire =
{
    local float refresh_interval;

    if (bot == world)
        return;
    if (bot.fb_next_desire_refresh > time)
        return;

    refresh_interval = cvar("frogbot_item_desire_refresh");
    if (refresh_interval <= 0)
        refresh_interval = 0.35;

    frogbot_set_health_armor_desire(bot);
    frogbot_set_firepower_desire(bot);
    bot.fb_next_desire_refresh = time + refresh_interval;
};

float(float raw_desire) frogbot_normalize_item_desire =
{
    local float desire_scale;
    local float small_scale;
    local float normalized;

    if (raw_desire <= 0)
        return 0;

    desire_scale = cvar("frogbot_item_desire_scale");
    if (desire_scale <= 0)
        desire_scale = 0.06;
    small_scale = cvar("frogbot_item_desire_small_scale");
    if (small_scale <= 0)
        small_scale = 0.35;

    if (raw_desire <= 5)
        normalized = raw_desire * small_scale;
    else
        normalized = raw_desire * desire_scale;

    return bound(0, normalized, 14);
};

float(entity bot, entity source, string dynamic_classname) frogbot_dynamic_class_desire =
{
    local float raw_desire;

    if (bot == world || dynamic_classname == "")
        return 0;

    if (mode_is_arena())
        return 0;

    source = frogbot_dynamic_source_for_marker(source);
    frogbot_refresh_item_desire(bot);

    raw_desire = 0;
    if (dynamic_classname == "item_armor1")
        raw_desire = bot.fb_desire_armor1;
    else if (dynamic_classname == "item_armor2")
        raw_desire = bot.fb_desire_armor2;
    else if (dynamic_classname == "item_armorInv")
        raw_desire = bot.fb_desire_armorInv;
    else if (dynamic_classname == "item_health")
    {
        if (source != world && source.healtype == FROGBOT_HEALTYPE_MEGA)
            raw_desire = bot.fb_desire_mega_health;
        else
            raw_desire = bot.fb_desire_health0;
    }
    else if (dynamic_classname == "weapon_supershotgun")
    {
        if (deathmatch == 1 || !(bot.items & IT_SUPER_SHOTGUN))
            raw_desire = bot.fb_desire_supershotgun;
    }
    else if (dynamic_classname == "weapon_nailgun")
    {
        if (deathmatch == 1 || !(bot.items & IT_NAILGUN))
            raw_desire = bot.fb_desire_nailgun;
    }
    else if (dynamic_classname == "weapon_supernailgun")
    {
        if (deathmatch == 1 || !(bot.items & IT_SUPER_NAILGUN))
            raw_desire = bot.fb_desire_supernailgun;
    }
    else if (dynamic_classname == "weapon_grenadelauncher")
    {
        if (deathmatch == 1 || !(bot.items & IT_GRENADE_LAUNCHER))
            raw_desire = bot.fb_desire_grenadelauncher;
    }
    else if (dynamic_classname == "weapon_rocketlauncher")
    {
        if (deathmatch == 1 || !(bot.items & IT_ROCKET_LAUNCHER))
            raw_desire = bot.fb_desire_rocketlauncher;
    }
    else if (dynamic_classname == "weapon_lightning")
    {
        if (deathmatch == 1 || !(bot.items & IT_LIGHTNING))
            raw_desire = bot.fb_desire_lightning;
    }
    else if (dynamic_classname == "item_shells")
    {
        if (bot.ammo_shells < 100)
            raw_desire = bot.fb_desire_shells;
    }
    else if (dynamic_classname == "item_spikes")
    {
        if (bot.ammo_nails < 200)
            raw_desire = bot.fb_desire_nails;
    }
    else if (dynamic_classname == "item_rockets")
    {
        if (bot.ammo_rockets < 100)
            raw_desire = bot.fb_desire_rockets;
    }
    else if (dynamic_classname == "item_cells")
    {
        if (bot.ammo_cells < 100)
            raw_desire = bot.fb_desire_cells;
    }
    else if (dynamic_classname == "item_weapon")
    {
        if (source != world && (source.spawnflags & FROGBOT_ITEM_WEAPON_SHOTGUN) && bot.ammo_shells < 100)
            raw_desire = bot.fb_desire_shells;
        else if (source != world && (source.spawnflags & FROGBOT_ITEM_WEAPON_SPIKES) && bot.ammo_nails < 200)
            raw_desire = bot.fb_desire_nails;
        else if (source != world && (source.spawnflags & FROGBOT_ITEM_WEAPON_ROCKET) && bot.ammo_rockets < 100)
            raw_desire = bot.fb_desire_rockets;
    }
    else if (dynamic_classname == "item_artifact_super_damage"
             || dynamic_classname == "item_artifact_invulnerability"
             || dynamic_classname == "item_artifact_invisibility")
    {
        raw_desire = 200 + bot.fb_total_damage;
    }
    else if (dynamic_classname == "item_backpack")
    {
        if (bot.super_damage_finished <= time && bot.invincible_finished <= time)
            raw_desire = 20;
    }

    raw_desire = raw_desire + frogbot_ctf_goal_desire_bonus(bot, source, dynamic_classname, raw_desire);
    return frogbot_normalize_item_desire(raw_desire);
};

float(entity bot, entity marker, entity from_marker) frogbot_virtual_goal_bonus =
{
    local entity source;
    local string dynamic_classname;
    local float base_desire;
    local float eta;
    local float wait_max;
    local float lookahead_window;
    local float travel_eta;
    local float lookahead_scale;
    local float bias;

    if (bot == world || !frogbot_is_marker_entity(marker))
        return 0;
    if (cvar("frogbot_virtual_goals") <= 0)
        return 0;
    if (!frogbot_is_marker_entity(from_marker))
        from_marker = bot.fb_current_marker;

    source = marker.fb_dynsource;
    if (source == world)
        return 0;

    dynamic_classname = frogbot_dynamic_marker_classname(source);
    if (!frogbot_is_item_goal_class(dynamic_classname))
        return 0;

    base_desire = frogbot_dynamic_class_desire(bot, source, dynamic_classname);
    if (base_desire <= 0)
        return 0;

    lookahead_scale = 1;
    if (frogbot_is_marker_entity(from_marker))
    {
        travel_eta = frogbot_skill_goal_eta(bot, from_marker, marker);
        lookahead_scale = frogbot_skill_lookahead_scale(bot, travel_eta);
        if (lookahead_scale <= 0)
            return 0;
    }

    bias = cvar("frogbot_virtual_goal_bias");
    if (bias <= 0)
        bias = 1;

    if (frogbot_dynamic_source_available(source))
        return base_desire * bias * lookahead_scale;

    wait_max = cvar("frogbot_goal_wait_max");
    if (wait_max <= 0)
        wait_max = 20;
    lookahead_window = frogbot_skill_lookahead_window(bot);
    wait_max = min(wait_max, lookahead_window);
    if (wait_max < 2)
        wait_max = 2;

    eta = frogbot_dynamic_source_respawn_eta(bot, source);
    if (eta <= 0.2)
        return base_desire * 0.55 * bias * lookahead_scale;
    if (eta < wait_max)
        return base_desire * (1 - eta / wait_max) * 0.75 * bias * lookahead_scale;

    return -base_desire * 0.6 * lookahead_scale;
};

entity(entity bot, entity from_marker) frogbot_zone_virtual_goal_anchor =
{
    local entity marker;
    local entity source;
    local entity best_unavailable;
    local entity best_equivalent;
    local string dynamic_classname;
    local string target_classname;
    local float score;
    local float best_unavailable_score;
    local float best_equivalent_score;
    local float available_bias;

    if (bot == world || !frogbot_is_marker_entity(from_marker))
        return world;
    if (from_marker.fb_zone <= 0)
        return world;
    if (cvar("frogbot_virtual_goals") <= 0 || cvar("frogbot_zone_virtual_goals") <= 0)
        return world;
    if (!frogbot_is_marker_entity(from_marker.fb_zone_head))
        return world;

    best_unavailable = world;
    best_unavailable_score = 0;
    target_classname = "";

    marker = from_marker.fb_zone_head;
    while (marker != world)
    {
        if (!frogbot_is_marker_entity(marker) || marker.fb_zone != from_marker.fb_zone)
        {
            marker = marker.fb_zone_next;
            continue;
        }

        source = marker.fb_dynsource;
        if (source != world)
        {
            dynamic_classname = frogbot_dynamic_marker_classname(source);
            if (frogbot_is_item_goal_class(dynamic_classname) && !frogbot_dynamic_source_available(source))
            {
                score = frogbot_virtual_goal_bonus(bot, marker, from_marker);
                if (score > best_unavailable_score)
                {
                    best_unavailable = marker;
                    best_unavailable_score = score;
                    target_classname = dynamic_classname;
                }
            }
        }

        marker = marker.fb_zone_next;
    }

    if (best_unavailable == world || best_unavailable_score <= 0 || target_classname == "")
        return world;

    best_equivalent = best_unavailable;
    best_equivalent_score = best_unavailable_score;
    available_bias = cvar("frogbot_zone_virtual_available_bias");
    if (available_bias <= 0)
        available_bias = 0.35;

    marker = from_marker.fb_zone_head;
    while (marker != world)
    {
        if (!frogbot_is_marker_entity(marker) || marker.fb_zone != from_marker.fb_zone)
        {
            marker = marker.fb_zone_next;
            continue;
        }

        source = marker.fb_dynsource;
        if (source != world)
        {
            dynamic_classname = frogbot_dynamic_marker_classname(source);
            if (dynamic_classname == target_classname)
            {
                score = frogbot_virtual_goal_bonus(bot, marker, from_marker);
                if (frogbot_dynamic_source_available(source))
                    score = score + available_bias;

                if (score > best_equivalent_score + 0.001)
                {
                    best_equivalent = marker;
                    best_equivalent_score = score;
                }
            }
        }

        marker = marker.fb_zone_next;
    }

    return best_equivalent;
};

float(entity marker) frogbot_marker_hazard_level =
{
    local float level;
    local float contents;
    local vector sample;
    local entity source;
    local string dynamic_classname;

    if (!frogbot_is_marker_entity(marker))
        return 0;

    level = 0;

    source = marker.fb_dynsource;
    if (source != world)
    {
        dynamic_classname = frogbot_dynamic_marker_classname(source);
        if (dynamic_classname == "trigger_hurt")
            level = level + 1;
    }

    sample = marker.origin;
    sample_z = sample_z + 20;
    contents = pointcontents(sample);
    if (contents == CONTENT_LAVA)
        level = level + 1;
    else if (contents == CONTENT_SLIME)
        level = level + 0.55;

    if (marker.fb_marker_flags & FROGBOT_MARKER_NOTOUCH)
        level = level + 0.35;

    return bound(0, level, 2);
};

float(entity bot, entity marker, entity next_marker, float path_flags) frogbot_route_hazard_cost =
{
    local float hazard_penalty;
    local float hazard_level;
    local float cost;

    if (cvar("frogbot_avoid_hazards") <= 0)
        return 0;

    hazard_penalty = cvar("frogbot_hazard_penalty");
    if (hazard_penalty <= 0)
        hazard_penalty = 2.4;

    hazard_level = frogbot_marker_hazard_level(next_marker);
    cost = hazard_level * hazard_penalty;

    if (path_flags & FROGBOT_PATH_ROCKET_JUMP)
    {
        if (!frogbot_can_use_rj_paths(bot))
            cost = cost + 4;
        else if (!frogbot_can_rj_now(bot))
            cost = cost + 0.8;
    }

    return cost;
};

float(entity bot, entity marker, entity next_marker, float path_flags) frogbot_path_is_walkable =
{
    local float dz;
    local float jump_flags;
    local float hazard_level;

    if (!frogbot_is_marker_entity(marker) || !frogbot_is_marker_entity(next_marker))
        return FALSE;

    if (cvar("frogbot_avoid_hazards") > 0)
    {
        hazard_level = frogbot_marker_hazard_level(next_marker);
        if (hazard_level >= 1 && !(next_marker.fb_marker_flags & FROGBOT_MARKER_ESCAPE_ROUTE))
            return FALSE;
    }

    if (path_flags & FROGBOT_PATH_VERTICAL_PLATFORM)
    {
        if (cvar("frogbot_allow_vertical_paths") <= 0)
            return FALSE;
    }

    if (path_flags & FROGBOT_PATH_ROCKET_JUMP)
    {
        if (!frogbot_can_use_rj_paths(bot))
            return FALSE;
    }

    dz = next_marker.origin_z - marker.origin_z;
    if (dz <= FROGBOT_MAX_UNFLAGGED_ASCENT)
        return TRUE;

    jump_flags = (FROGBOT_PATH_WATERJUMP | FROGBOT_PATH_JUMP_LEDGE);
    if (path_flags & FROGBOT_PATH_CURLJUMP_HINT)
        jump_flags = jump_flags | FROGBOT_PATH_CURLJUMP_HINT;
    if (path_flags & jump_flags)
        return TRUE;

    return FALSE;
};

float(entity bot, entity marker, entity next_marker, float path_flags, entity zone_virtual_anchor, float zone_virtual_anchor_score) frogbot_route_score_bonus =
{
    local float bonus;
    local float potential_bias;
    local float current_cost;
    local float next_cost;
    local float delta_cost;
    local float marker_slot;
    local float next_slot;
    local float zone_current_eta;
    local float zone_next_eta;
    local float zone_delta;
    local float zone_progress_bias;
    local float zone_detour_penalty;
    local float lookahead_scale;
    local float use_rj_eta;
    local float zone_next_bias;
    local float zone_virtual_bias;
    local float zone_virtual_scale;
    local entity zone_goal;
    local entity zone_next_hint;
    local entity zone_virtual_next;

    bonus = 0;

    if (next_marker.fb_goal > 0)
        bonus = bonus + cvar("frogbot_goal_bias");

    if (next_marker.fb_zone > 0 && frogbot_is_marker_entity(bot.fb_current_marker))
    {
        if (next_marker.fb_zone == bot.fb_current_marker.fb_zone)
            bonus = bonus + cvar("frogbot_zone_stickiness");
    }

    if (path_flags & FROGBOT_PATH_CURLJUMP_HINT)
        bonus = bonus + cvar("frogbot_path_hint_bias");

    bonus = bonus + frogbot_virtual_goal_bonus(bot, next_marker, marker);
    bonus = bonus - frogbot_route_hazard_cost(bot, marker, next_marker, path_flags);
    bonus = bonus + frogbot_camp_route_bonus(bot, marker, next_marker);
    bonus = bonus + frogbot_ctf_route_score_bonus(bot, marker, next_marker, path_flags, bonus);

    potential_bias = cvar("frogbot_route_potential_bias");
    if (potential_bias > 0 && frogbot_route_potential_ready)
    {
        current_cost = marker.fb_route_goal_cost;
        next_cost = next_marker.fb_route_goal_cost;
        if (current_cost < FROGBOT_ROUTE_COST_INF * 0.5 && next_cost < FROGBOT_ROUTE_COST_INF * 0.5)
        {
            delta_cost = current_cost - next_cost;
            lookahead_scale = frogbot_skill_lookahead_scale(bot, next_cost);
            if (delta_cost > 0)
                bonus = bonus + (delta_cost * potential_bias * lookahead_scale);
            else
                bonus = bonus + (delta_cost * potential_bias);
            if (delta_cost < -0.8)
                bonus = bonus + (delta_cost * potential_bias * 0.5);
        }
        else if (next_marker.fb_goal <= 0 && next_cost >= FROGBOT_ROUTE_COST_INF * 0.5)
        {
            bonus = bonus - (2 * potential_bias);
        }
    }

    if (cvar("frogbot_zone_system") > 0 && frogbot_zone_cache_ready)
    {
        marker_slot = frogbot_marker_slot(marker);
        next_slot = frogbot_marker_slot(next_marker);
        if (marker_slot >= 0 && next_slot >= 0)
        {
            use_rj_eta = frogbot_can_use_rj_paths(bot);
            if (use_rj_eta)
            {
                zone_current_eta = frogbot_zone_goal_eta_rj[marker_slot];
                zone_next_eta = frogbot_zone_goal_eta_rj[next_slot];
                zone_goal = frogbot_zone_goal_marker_rj[marker_slot];
                if (!frogbot_is_marker_entity(zone_goal))
                    zone_goal = frogbot_zone_goal_marker[marker_slot];
            }
            else
            {
                zone_current_eta = frogbot_zone_goal_eta[marker_slot];
                zone_next_eta = frogbot_zone_goal_eta[next_slot];
                zone_goal = frogbot_zone_goal_marker[marker_slot];
                if (!frogbot_is_marker_entity(zone_goal))
                    zone_goal = frogbot_zone_goal_marker_rj[marker_slot];
            }

            if (zone_current_eta < FROGBOT_ZONE_INF * 0.5 && zone_next_eta < FROGBOT_ZONE_INF * 0.5)
            {
                zone_delta = zone_current_eta - zone_next_eta;
                zone_progress_bias = cvar("frogbot_zone_progress_bias");
                if (zone_progress_bias <= 0)
                    zone_progress_bias = 0.8;
                zone_detour_penalty = cvar("frogbot_zone_detour_penalty");
                if (zone_detour_penalty <= 0)
                    zone_detour_penalty = 0.6;

                if (zone_delta > 0)
                    bonus = bonus + (zone_delta * zone_progress_bias);
                else if (zone_delta < -0.2)
                    bonus = bonus + (zone_delta * zone_detour_penalty);
            }

            if (frogbot_is_marker_entity(zone_goal))
            {
                zone_next_hint = frogbot_zone_next_marker(marker, zone_goal, use_rj_eta);
                if (zone_next_hint == next_marker)
                {
                    zone_next_bias = cvar("frogbot_zone_next_bias");
                    if (zone_next_bias <= 0)
                        zone_next_bias = 0.55;
                    bonus = bonus + zone_next_bias;
                }
            }
        }
    }

    if (cvar("frogbot_zone_virtual_goals") > 0
        && frogbot_zone_cache_ready
        && frogbot_is_marker_entity(zone_virtual_anchor)
        && zone_virtual_anchor_score > 0)
    {
        use_rj_eta = frogbot_can_use_rj_paths(bot);
        zone_virtual_next = frogbot_zone_next_marker(marker, zone_virtual_anchor, use_rj_eta);
        if (zone_virtual_next == next_marker)
        {
            zone_virtual_bias = cvar("frogbot_zone_virtual_bias");
            if (zone_virtual_bias <= 0)
                zone_virtual_bias = 0.32;

            zone_virtual_scale = min(zone_virtual_anchor_score, 6);
            bonus = bonus + (zone_virtual_scale * zone_virtual_bias);
        }
    }

    return bonus;
};

void(entity bot, entity marker, entity next_marker, entity zone_virtual_anchor, float zone_virtual_anchor_score, float route_bonus) frogbot_debug_zone_route_decision =
{
    local float marker_slot;
    local float next_slot;
    local float use_rj_eta;
    local float zone_current_eta;
    local float zone_next_eta;
    local float zone_delta;
    local float zone_progress_bias;
    local float zone_detour_penalty;
    local float zone_progress_bonus;
    local float zone_next_bias;
    local float zone_next_bonus;
    local float zone_virtual_bias;
    local float zone_virtual_scale;
    local float zone_virtual_bonus;
    local float zone_total_bonus;
    local vector zone_eta_vec;
    local vector zone_bonus_vec;
    local entity zone_goal;
    local entity zone_next_hint;
    local entity zone_virtual_next;

    if (cvar("frogbot_debug") < 3)
        return;
    if (!frogbot_is_marker_entity(marker) || !frogbot_is_marker_entity(next_marker))
        return;
    if (cvar("frogbot_zone_system") <= 0 || !frogbot_zone_cache_ready)
        return;

    marker_slot = frogbot_marker_slot(marker);
    next_slot = frogbot_marker_slot(next_marker);
    if (marker_slot < 0 || next_slot < 0)
        return;

    use_rj_eta = frogbot_can_use_rj_paths(bot);
    zone_current_eta = FROGBOT_ZONE_INF;
    zone_next_eta = FROGBOT_ZONE_INF;
    zone_delta = FROGBOT_ZONE_INF;
    zone_progress_bonus = 0;
    zone_next_bonus = 0;
    zone_virtual_bonus = 0;

    if (use_rj_eta)
    {
        zone_current_eta = frogbot_zone_goal_eta_rj[marker_slot];
        zone_next_eta = frogbot_zone_goal_eta_rj[next_slot];
        zone_goal = frogbot_zone_goal_marker_rj[marker_slot];
        if (!frogbot_is_marker_entity(zone_goal))
            zone_goal = frogbot_zone_goal_marker[marker_slot];
    }
    else
    {
        zone_current_eta = frogbot_zone_goal_eta[marker_slot];
        zone_next_eta = frogbot_zone_goal_eta[next_slot];
        zone_goal = frogbot_zone_goal_marker[marker_slot];
        if (!frogbot_is_marker_entity(zone_goal))
            zone_goal = frogbot_zone_goal_marker_rj[marker_slot];
    }

    if (zone_current_eta < FROGBOT_ZONE_INF * 0.5 && zone_next_eta < FROGBOT_ZONE_INF * 0.5)
    {
        zone_delta = zone_current_eta - zone_next_eta;
        zone_progress_bias = cvar("frogbot_zone_progress_bias");
        if (zone_progress_bias <= 0)
            zone_progress_bias = 0.8;
        zone_detour_penalty = cvar("frogbot_zone_detour_penalty");
        if (zone_detour_penalty <= 0)
            zone_detour_penalty = 0.6;

        if (zone_delta > 0)
            zone_progress_bonus = zone_delta * zone_progress_bias;
        else if (zone_delta < -0.2)
            zone_progress_bonus = zone_delta * zone_detour_penalty;
    }

    if (frogbot_is_marker_entity(zone_goal))
    {
        zone_next_hint = frogbot_zone_next_marker(marker, zone_goal, use_rj_eta);
        if (zone_next_hint == next_marker)
        {
            zone_next_bias = cvar("frogbot_zone_next_bias");
            if (zone_next_bias <= 0)
                zone_next_bias = 0.55;
            zone_next_bonus = zone_next_bias;
        }
    }

    if (cvar("frogbot_zone_virtual_goals") > 0
        && frogbot_is_marker_entity(zone_virtual_anchor)
        && zone_virtual_anchor_score > 0)
    {
        zone_virtual_next = frogbot_zone_next_marker(marker, zone_virtual_anchor, use_rj_eta);
        if (zone_virtual_next == next_marker)
        {
            zone_virtual_bias = cvar("frogbot_zone_virtual_bias");
            if (zone_virtual_bias <= 0)
                zone_virtual_bias = 0.32;

            zone_virtual_scale = min(zone_virtual_anchor_score, 6);
            zone_virtual_bonus = zone_virtual_scale * zone_virtual_bias;
        }
    }

    zone_total_bonus = zone_progress_bonus + zone_next_bonus + zone_virtual_bonus;

    if (zone_current_eta >= FROGBOT_ZONE_INF * 0.5)
        zone_current_eta = -1;
    if (zone_next_eta >= FROGBOT_ZONE_INF * 0.5)
        zone_next_eta = -1;
    if (zone_delta >= FROGBOT_ZONE_INF * 0.5)
        zone_delta = -1;

    zone_eta_vec = '0 0 0';
    zone_eta_vec_x = zone_current_eta;
    zone_eta_vec_y = zone_next_eta;
    zone_eta_vec_z = zone_delta;

    zone_bonus_vec = '0 0 0';
    zone_bonus_vec_x = zone_total_bonus;
    zone_bonus_vec_y = route_bonus;

    frogbot_debug_log("");
};

entity(entity bot, entity marker) frogbot_pick_next_target =
{
    local float i;
    local float score;
    local float path_flags;
    local float visit_age;
    local float route_bonus;
    local entity next_marker;
    local entity best_any_marker;
    local entity best_walk_marker;
    local float best_any_score;
    local float best_walk_score;
    local float best_any_route_bonus;
    local float best_walk_route_bonus;
    local float best_any_index;
    local float best_walk_index;
    local float best_any_flags;
    local float best_walk_flags;
    local entity zone_virtual_anchor;
    local float zone_virtual_anchor_score;

    best_any_marker = world;
    best_walk_marker = world;
    best_any_score = -999999;
    best_walk_score = -999999;
    best_any_route_bonus = 0;
    best_walk_route_bonus = 0;
    best_any_index = -1;
    best_walk_index = -1;
    best_any_flags = 0;
    best_walk_flags = 0;
    zone_virtual_anchor = frogbot_zone_virtual_goal_anchor(bot, marker);
    zone_virtual_anchor_score = frogbot_virtual_goal_bonus(bot, zone_virtual_anchor, marker);
    if (!frogbot_is_marker_entity(zone_virtual_anchor) || zone_virtual_anchor_score <= 0)
    {
        zone_virtual_anchor = world;
        zone_virtual_anchor_score = 0;
    }

    i = 0;
    while (i < FROGBOT_MAX_PATHS)
    {
        next_marker = frogbot_get_path_marker(marker, i);
        if (frogbot_is_marker_entity(next_marker) && !(next_marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE))
        {
            if (bot.fb_failed_until > time && marker == bot.fb_failed_from_marker && next_marker == bot.fb_failed_to_marker)
            {
                i = i + 1;
                continue;
            }

            path_flags = frogbot_get_path_flags(marker, i);

            if (next_marker.fb_blocked_until > time)
            {
                i = i + 1;
                continue;
            }

            score = random() * 0.25;
            if (next_marker == bot.fb_prev_marker)
                score = score - 2;
            else
                score = score + 2;

            visit_age = time - next_marker.fb_last_visit_time;
            if (visit_age < 0)
                visit_age = 0;
            if (next_marker.fb_last_visit_time <= 0)
                score = score + 6;
            else
                score = score + bound(0, visit_age / 3, 6);

            route_bonus = frogbot_route_score_bonus(bot, marker, next_marker, path_flags,
                                                    zone_virtual_anchor, zone_virtual_anchor_score);
            score = score + route_bonus;
            if (cvar("frogbot_debug") >= 4 && route_bonus)
            {
                frogbot_debug_log("");
            }

            if (score > best_any_score)
            {
                best_any_score = score;
                best_any_route_bonus = route_bonus;
                best_any_marker = next_marker;
                best_any_index = i;
                best_any_flags = path_flags;
            }

            if (frogbot_path_is_walkable(bot, marker, next_marker, path_flags) && score > best_walk_score)
            {
                best_walk_score = score;
                best_walk_route_bonus = route_bonus;
                best_walk_marker = next_marker;
                best_walk_index = i;
                best_walk_flags = path_flags;
            }
        }
        i = i + 1;
    }

    if (best_walk_marker != world)
    {
        bot.fb_target_path_index = best_walk_index;
        bot.fb_target_path_flags = best_walk_flags;
        bot.fb_target_path_hint = frogbot_get_path_hint(marker, best_walk_index);
        bot.fb_target_rj_delay = frogbot_get_rj_delay(marker, best_walk_index);
        frogbot_debug_zone_route_decision(bot, marker, best_walk_marker,
                                          zone_virtual_anchor, zone_virtual_anchor_score,
                                          best_walk_route_bonus);
        return best_walk_marker;
    }

    if (best_any_marker != world)
    {
        bot.fb_target_path_index = best_any_index;
        bot.fb_target_path_flags = best_any_flags;
        bot.fb_target_path_hint = frogbot_get_path_hint(marker, best_any_index);
        bot.fb_target_rj_delay = frogbot_get_rj_delay(marker, best_any_index);
        frogbot_debug_zone_route_decision(bot, marker, best_any_marker,
                                          zone_virtual_anchor, zone_virtual_anchor_score,
                                          best_any_route_bonus);
        return best_any_marker;
    }

    bot.fb_target_path_index = -1;
    bot.fb_target_path_flags = 0;
    bot.fb_target_path_hint = 0;
    bot.fb_target_rj_delay = 0;
    return world;
};

void(entity marker) frogbot_mark_marker_visited =
{
    if (!frogbot_is_marker_entity(marker))
        return;

    marker.fb_last_visit_time = time;
    marker.fb_blocked_until = 0;
    marker.fb_blocked_hits = 0;
};

float(entity bot, entity marker) frogbot_marker_has_route_exit =
{
    local float i;
    local entity next_marker;

    if (!frogbot_is_marker_entity(marker))
        return FALSE;
    if (marker.fb_blocked_until > time)
        return FALSE;

    i = 0;
    while (i < FROGBOT_MAX_PATHS)
    {
        next_marker = frogbot_get_path_marker(marker, i);
        if (frogbot_is_marker_entity(next_marker) && !(next_marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE))
        {
            if (next_marker.fb_blocked_until > time)
            {
                i = i + 1;
                continue;
            }
            if (!(bot.fb_failed_until > time && marker == bot.fb_failed_from_marker && next_marker == bot.fb_failed_to_marker))
                return TRUE;
        }
        i = i + 1;
    }

    return FALSE;
};

float() frogbot_camp_mode_enabled =
{
    if (cvar("frogbot_camp_logic") <= 0)
        return FALSE;
    if (mode_is_arena())
        return FALSE;
    if (frogbot_ctf_disable_camp_mode())
        return FALSE;
    if (clanring_playmode & (CLANRING_WIPEOUT_MODE
                             | CLANRING_AIRSHOT_MODE
                             | CLANRING_CA_MODE
                             | CLANRING_RA_MODE
                             | CLANRING_DMM4_MODE))
    {
        return FALSE;
    }

    return TRUE;
};

float() frogbot_camp_map_supported =
{
    local string map_token;

    map_token = strtolower(mapname);
    if (map_token == "dm3" || map_token == "dm4" || map_token == "dm6")
        return TRUE;
    return FALSE;
};

entity(entity bot, vector anchor_org, float anchor_radius) frogbot_find_anchor_marker =
{
    local float i;
    local float dist;
    local float best_dist;
    local entity marker;
    local entity best;

    best = world;
    best_dist = 99999999;
    if (anchor_radius <= 0)
        anchor_radius = 320;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_marker_has_route_exit(bot, marker) && !(marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE))
        {
            dist = vlen(marker.origin - anchor_org);
            if (dist <= anchor_radius && dist < best_dist)
            {
                best_dist = dist;
                best = marker;
            }
        }
        i = i + 1;
    }

    return best;
};

entity(entity bot, string item_class, float anchor_radius) frogbot_pick_camp_marker_for_itemclass =
{
    local entity item;
    local entity marker;
    local entity best;
    local float best_dist;
    local float item_dist;

    best = world;
    best_dist = 99999999;
    if (item_class == "")
        return world;

    item = find(world, classname, item_class);
    while (item)
    {
        marker = frogbot_find_anchor_marker(bot, item.origin, anchor_radius);
        if (marker != world)
        {
            item_dist = vlen(marker.origin - item.origin);
            if (item_dist < best_dist)
            {
                best_dist = item_dist;
                best = marker;
            }
        }
        item = find(item, classname, item_class);
    }

    return best;
};

entity(entity bot) frogbot_pick_map_camp_marker =
{
    local string map_token;
    local entity c1;
    local entity c2;
    local entity c3;
    local entity c4;
    local entity pick;
    local float count;

    map_token = strtolower(mapname);
    c1 = world;
    c2 = world;
    c3 = world;
    c4 = world;

    if (map_token == "dm3")
    {
        c1 = frogbot_pick_camp_marker_for_itemclass(bot, "item_armorInv", 300);
        c2 = frogbot_pick_camp_marker_for_itemclass(bot, "weapon_rocketlauncher", 320);
        c3 = frogbot_pick_camp_marker_for_itemclass(bot, "weapon_lightning", 320);
    }
    else if (map_token == "dm4")
    {
        c1 = frogbot_pick_camp_marker_for_itemclass(bot, "item_armorInv", 300);
        c2 = frogbot_pick_camp_marker_for_itemclass(bot, "weapon_rocketlauncher", 320);
        c3 = frogbot_pick_camp_marker_for_itemclass(bot, "item_artifact_super_damage", 340);
    }
    else if (map_token == "dm6")
    {
        c1 = frogbot_pick_camp_marker_for_itemclass(bot, "item_armorInv", 300);
        c2 = frogbot_pick_camp_marker_for_itemclass(bot, "weapon_lightning", 320);
        c3 = frogbot_pick_camp_marker_for_itemclass(bot, "weapon_rocketlauncher", 340);
        c4 = frogbot_pick_camp_marker_for_itemclass(bot, "item_artifact_super_damage", 360);
    }
    else
    {
        return world;
    }

    pick = world;
    count = 0;

    if (c1 != world)
    {
        count = count + 1;
        if (random() < (1 / count))
            pick = c1;
    }
    if (c2 != world && c2 != c1)
    {
        count = count + 1;
        if (random() < (1 / count))
            pick = c2;
    }
    if (c3 != world && c3 != c1 && c3 != c2)
    {
        count = count + 1;
        if (random() < (1 / count))
            pick = c3;
    }
    if (c4 != world && c4 != c1 && c4 != c2 && c4 != c3)
    {
        count = count + 1;
        if (random() < (1 / count))
            pick = c4;
    }

    return pick;
};

void(entity bot) frogbot_clear_camp_state =
{
    if (bot == world)
        return;

    bot.fb_camp_until = 0;
    bot.fb_camp_marker = world;
};

float(entity bot) frogbot_camp_active =
{
    if (bot == world)
        return FALSE;
    if (!frogbot_camp_mode_enabled() || !frogbot_camp_map_supported())
    {
        frogbot_clear_camp_state(bot);
        return FALSE;
    }
    if (bot.fb_camp_until <= time)
    {
        frogbot_clear_camp_state(bot);
        return FALSE;
    }
    if (!frogbot_is_marker_entity(bot.fb_camp_marker))
    {
        frogbot_clear_camp_state(bot);
        return FALSE;
    }
    if (bot.fb_camp_marker.fb_marker_flags & FROGBOT_MARKER_UNREACHABLE)
    {
        frogbot_clear_camp_state(bot);
        return FALSE;
    }
    if (bot.fb_camp_marker.fb_blocked_until > time)
    {
        frogbot_clear_camp_state(bot);
        return FALSE;
    }
    if (!frogbot_marker_has_route_exit(bot, bot.fb_camp_marker))
    {
        frogbot_clear_camp_state(bot);
        return FALSE;
    }

    return TRUE;
};

float(entity bot, entity combat_target) frogbot_update_camp_state =
{
    local float retry_time;
    local float chance;
    local float hold_min;
    local float hold_max;
    local float enemy_dist_gate;
    local float hp_armor;
    local entity camp_marker;

    if (bot == world)
        return FALSE;

    retry_time = cvar("frogbot_camp_retry");
    if (retry_time <= 0)
        retry_time = 4;

    if (!frogbot_camp_mode_enabled() || !frogbot_camp_map_supported())
    {
        frogbot_clear_camp_state(bot);
        bot.fb_next_camp_time = time + retry_time;
        return FALSE;
    }

    if (frogbot_camp_active(bot))
    {
        enemy_dist_gate = cvar("frogbot_camp_enemy_dist");
        if (enemy_dist_gate <= 0)
            enemy_dist_gate = 520;

        if (combat_target != world && vlen(combat_target.origin - bot.origin) <= enemy_dist_gate)
        {
            frogbot_clear_camp_state(bot);
            bot.fb_next_camp_time = time + retry_time * 0.75;
            return FALSE;
        }
        return TRUE;
    }

    if (bot.fb_next_camp_time > time)
        return FALSE;
    bot.fb_next_camp_time = time + retry_time;

    if (combat_target != world)
        return FALSE;
    if (bot.fb_combat_escape_until > time)
        return FALSE;

    hp_armor = bot.health + bot.armorvalue;
    if (hp_armor < 120 && bot.fb_total_damage < 160)
        return FALSE;

    chance = cvar("frogbot_camp_chance");
    if (chance <= 0)
        chance = 0.3;
    chance = bound(0, chance, 1);
    if (random() > chance)
        return FALSE;

    camp_marker = frogbot_pick_map_camp_marker(bot);
    if (camp_marker == world)
        return FALSE;

    hold_min = cvar("frogbot_camp_hold_min");
    hold_max = cvar("frogbot_camp_hold_max");
    if (hold_min <= 0)
        hold_min = 3;
    if (hold_max < hold_min)
        hold_max = hold_min + 2;

    bot.fb_camp_marker = camp_marker;
    bot.fb_camp_until = time + hold_min + random() * (hold_max - hold_min);
    bot.fb_next_camp_time = bot.fb_camp_until + retry_time + random() * retry_time;
    return TRUE;
};

float(entity bot, entity combat_target) frogbot_camp_should_hold =
{
    local float enemy_dist_gate;

    if (!frogbot_camp_active(bot))
        return FALSE;
    if (!frogbot_is_marker_entity(bot.fb_current_marker))
        return FALSE;
    if (bot.fb_current_marker != bot.fb_camp_marker)
        return FALSE;

    enemy_dist_gate = cvar("frogbot_camp_enemy_dist");
    if (enemy_dist_gate <= 0)
        enemy_dist_gate = 520;

    if (combat_target != world && vlen(combat_target.origin - bot.origin) <= enemy_dist_gate)
        return FALSE;

    return TRUE;
};

float(entity bot, entity marker, entity next_marker) frogbot_camp_route_bonus =
{
    local entity camp_marker;
    local float use_rj_eta;
    local float current_eta;
    local float next_eta;
    local float delta_eta;
    local float route_bias;
    local float goal_bias;
    local float current_dist;
    local float next_dist;

    if (!frogbot_camp_active(bot))
        return 0;
    if (!frogbot_is_marker_entity(marker) || !frogbot_is_marker_entity(next_marker))
        return 0;

    camp_marker = bot.fb_camp_marker;
    if (!frogbot_is_marker_entity(camp_marker))
        return 0;

    goal_bias = cvar("frogbot_camp_goal_bias");
    if (goal_bias <= 0)
        goal_bias = 2.2;
    route_bias = cvar("frogbot_camp_route_bias");
    if (route_bias <= 0)
        route_bias = 1.1;

    if (next_marker == camp_marker)
        return goal_bias;
    if (marker == camp_marker)
        return -0.65;

    use_rj_eta = frogbot_can_use_rj_paths(bot);
    current_eta = frogbot_zone_arrival_time(marker, camp_marker, use_rj_eta);
    next_eta = frogbot_zone_arrival_time(next_marker, camp_marker, use_rj_eta);
    if (current_eta < FROGBOT_ZONE_INF * 0.5 && next_eta < FROGBOT_ZONE_INF * 0.5)
    {
        delta_eta = current_eta - next_eta;
        if (delta_eta > 0)
            return min(6, delta_eta) * route_bias;
        if (delta_eta < -0.25)
            return delta_eta * 0.35;
        return 0;
    }

    current_dist = vlen(marker.origin - camp_marker.origin);
    next_dist = vlen(next_marker.origin - camp_marker.origin);
    return ((current_dist - next_dist) / 200) * route_bias * 0.5;
};

entity(entity bot) frogbot_find_nearest_recover_marker =
{
    local float i;
    local float dist;
    local float best_dist;
    local entity marker;
    local entity best_visible;
    local entity best_any;

    best_visible = world;
    best_any = world;
    best_dist = 99999999;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_marker_has_route_exit(bot, marker))
        {
            dist = vlen(marker.origin - bot.origin);
            if (dist < best_dist)
            {
                best_dist = dist;
                best_any = marker;
            }
        }
        i = i + 1;
    }

    if (best_any == world)
        return world;

    best_dist = 99999999;
    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_marker_has_route_exit(bot, marker) && frogbot_marker_visible(bot, marker))
        {
            dist = vlen(marker.origin - bot.origin);
            if (dist < best_dist)
            {
                best_dist = dist;
                best_visible = marker;
            }
        }
        i = i + 1;
    }

    if (best_visible != world)
        return best_visible;
    return best_any;
};

entity(entity bot) frogbot_find_nearest_route_marker =
{
    local float i;
    local float dist;
    local float best_dist;
    local entity marker;
    local entity best;

    best = world;
    best_dist = 99999999;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_marker_has_route_exit(bot, marker))
        {
            dist = vlen(marker.origin - bot.origin);
            if (dist < best_dist)
            {
                best_dist = dist;
                best = marker;
            }
        }
        i = i + 1;
    }

    return best;
};

entity(entity bot) frogbot_find_nearest_visible_route_marker =
{
    local float i;
    local float dist;
    local float best_dist;
    local entity marker;
    local entity best;

    best = world;
    best_dist = 99999999;

    i = 0;
    while (i < FROGBOT_MAX_MARKERS)
    {
        marker = frogbot_markers[i];
        if (frogbot_marker_has_route_exit(bot, marker) && frogbot_marker_visible(bot, marker))
        {
            dist = vlen(marker.origin - bot.origin);
            if (dist < best_dist)
            {
                best_dist = dist;
                best = marker;
            }
        }
        i = i + 1;
    }

    return best;
};

float(entity bot) frogbot_try_transition_reanchor =
{
    local entity nearest;
    local entity anchor;
    local float current_dist;
    local float target_dist;
    local float anchor_dist;
    local float transition_context;
    local float reanchor_dist;
    local float mismatch_dist;
    local float context_dist;
    local float warped;
    local float warp_reanchor_mult;
    local float max_anchor_dist;
    local float reanchor_target_dist;

    if (bot == world)
        return FALSE;
    if (cvar("frogbot_advanced_recovery") <= 0)
        return FALSE;
    if (!frogbot_is_marker_entity(bot.fb_current_marker) && !frogbot_is_marker_entity(bot.fb_target_marker))
        return FALSE;

    nearest = frogbot_find_nearest_visible_marker(bot);
    warped = frogbot_detect_transition_warp(bot);
    transition_context = FALSE;
    if (frogbot_recent_teleport(bot))
        transition_context = TRUE;
    else if (warped)
        transition_context = TRUE;
    else if (frogbot_marker_is_transition(bot.fb_current_marker))
        transition_context = TRUE;
    else if (frogbot_marker_is_transition(bot.fb_target_marker))
        transition_context = TRUE;
    else if (frogbot_marker_is_transition(bot.fb_prev_marker))
        transition_context = TRUE;
    else if (nearest != world && frogbot_marker_is_transition(nearest))
        transition_context = TRUE;
    else
    {
        context_dist = cvar("frogbot_transition_context_dist");
        if (context_dist <= 0)
            context_dist = 224;
        if (frogbot_near_transition_marker(bot, context_dist))
            transition_context = TRUE;
    }

    if (!transition_context)
        return FALSE;

    reanchor_dist = cvar("frogbot_transition_reanchor_dist");
    if (reanchor_dist <= 0)
        return FALSE;

    mismatch_dist = cvar("frogbot_transition_mismatch_dist");
    if (mismatch_dist <= 0)
        mismatch_dist = 320;

    anchor = frogbot_find_nearest_visible_route_marker(bot);
    if (anchor == world)
        anchor = frogbot_find_nearest_route_marker(bot);
    if (anchor == world)
        return FALSE;

    anchor_dist = vlen(anchor.origin - bot.origin);
    warp_reanchor_mult = cvar("frogbot_transition_reanchor_warp_mult");
    if (warp_reanchor_mult <= 0)
        warp_reanchor_mult = 4;
    max_anchor_dist = reanchor_dist;
    if (warped)
        max_anchor_dist = reanchor_dist * warp_reanchor_mult;
    if (anchor_dist > max_anchor_dist)
        return FALSE;

    // Avoid no-op reanchors that can thrash every frame near tele/transition nodes.
    if (!warped && frogbot_is_marker_entity(bot.fb_current_marker) && anchor == bot.fb_current_marker)
        return FALSE;

    current_dist = 0;
    if (frogbot_is_marker_entity(bot.fb_current_marker))
        current_dist = vlen(bot.fb_current_marker.origin - bot.origin);
    target_dist = 0;
    if (frogbot_is_marker_entity(bot.fb_target_marker))
        target_dist = vlen(bot.fb_target_marker.origin - bot.origin);

    reanchor_target_dist = cvar("frogbot_transition_reanchor_target_dist");
    if (reanchor_target_dist <= 0)
        reanchor_target_dist = 900;
    if (!warped && target_dist > 0 && target_dist < reanchor_target_dist)
        return FALSE;

    if (!warped && current_dist <= mismatch_dist && (target_dist <= mismatch_dist * 1.5 || target_dist <= 0))
        return FALSE;

    bot.fb_prev_marker = bot.fb_current_marker;
    bot.fb_current_marker = anchor;
    bot.fb_target_marker = world;
    bot.fb_target_path_index = -1;
    bot.fb_target_path_flags = 0;
    bot.fb_target_path_hint = 0;
    bot.fb_target_rj_delay = 0;
    bot.fb_rj_pending = 0;
    bot.fb_rj_fire_time = 0;
    bot.fb_stuck_count = 0;
    bot.fb_last_progress_time = time;
    bot.fb_last_target_distance = 999999;

    if (cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
    }

    return TRUE;
};

void(entity bot, string reason) frogbot_bind_nearest_marker =
{
    local entity nearest;
    local entity keep_failed_from;
    local entity keep_failed_to;
    local float keep_failed_until;
    local float use_recover_bind;
    local float preserve_failed;
    local float dist;
    local string bind_mode;
    local float snap_bind;
    local float snap_dist;
    local float recover_snap_dist;
    local float nearest_dist;
    local float warped;

    // "stuck" and "no-path" should both recover to markers with route exits.
    use_recover_bind = (reason == "stuck" || reason == "no-path");
    // Keep failed-edge memory only for immediate stuck recovery.
    // For "no-path" we still recover-bind, but clear failed-edge memory.
    preserve_failed = (reason == "stuck");
    snap_bind = FALSE;
    nearest_dist = 0;
    warped = FALSE;

    if (use_recover_bind)
    {
        nearest = frogbot_find_nearest_recover_marker(bot);
        bind_mode = "recover";
    }
    else if (reason == "transition" || reason == "desync")
    {
        nearest = frogbot_find_nearest_visible_route_marker(bot);
        bind_mode = "route-visible";
        if (nearest == world)
        {
            nearest = frogbot_find_nearest_route_marker(bot);
            bind_mode = "route-fallback";
        }
        if (nearest == world)
        {
            nearest = frogbot_find_nearest_recover_marker(bot);
            bind_mode = "recover-route";
        }
        if (nearest == world)
        {
            nearest = frogbot_find_nearest_visible_marker(bot);
            bind_mode = "visible";
            if (nearest == world)
            {
                nearest = frogbot_find_nearest_marker(bot);
                bind_mode = "fallback";
            }
        }
    }
    else
    {
        nearest = frogbot_find_nearest_visible_marker(bot);
        bind_mode = "visible";
        if (nearest == world)
        {
            nearest = frogbot_find_nearest_marker(bot);
            bind_mode = "fallback";
        }
    }

    if ((reason == "transition" || reason == "desync") && nearest != world)
    {
        nearest_dist = vlen(nearest.origin - bot.origin);
        snap_dist = cvar("frogbot_transition_snap_dist");
        if (snap_dist <= 0)
            snap_dist = 192;

        warped = frogbot_detect_transition_warp(bot);
        if (nearest_dist <= snap_dist || frogbot_recent_teleport(bot) || warped)
            snap_bind = TRUE;
    }
    else if (use_recover_bind && nearest != world)
    {
        if (nearest_dist <= 0)
            nearest_dist = vlen(nearest.origin - bot.origin);
        recover_snap_dist = cvar("frogbot_recover_snap_dist");
        if (recover_snap_dist <= 0)
            recover_snap_dist = 96;
        if (nearest_dist <= recover_snap_dist)
            snap_bind = TRUE;
    }

    if (preserve_failed)
    {
        keep_failed_from = bot.fb_failed_from_marker;
        keep_failed_to = bot.fb_failed_to_marker;
        keep_failed_until = bot.fb_failed_until;
    }

    frogbot_reset_runtime_state(bot);
    if (preserve_failed && keep_failed_from != world && keep_failed_to != world && keep_failed_until > time)
    {
        bot.fb_failed_from_marker = keep_failed_from;
        bot.fb_failed_to_marker = keep_failed_to;
        bot.fb_failed_until = keep_failed_until;
    }

    if (snap_bind && nearest != world)
    {
        bot.fb_current_marker = nearest;
        bot.fb_target_marker = world;
        bot.fb_last_progress_time = time;
        bot.fb_last_target_distance = nearest_dist;
        // Keep transition guard active briefly after teleport/desync snap.
        bot.tp_time = time;
    }
    else
    {
        bot.fb_target_marker = nearest;
        if (nearest != world)
        {
            if (nearest_dist <= 0)
                nearest_dist = vlen(nearest.origin - bot.origin);
            bot.fb_last_target_distance = nearest_dist;
        }
    }

    if (!frogbot_debug_enabled())
        return;

    if (nearest == world)
    {
        frogbot_debug_log("");
        return;
    }

    if (nearest_dist <= 0)
        nearest_dist = vlen(nearest.origin - bot.origin);
    dist = nearest_dist;
    frogbot_debug_log("");
    if (frogbot_debug_trace_enabled())
    {
        frogbot_debug_log("");
        frogbot_debug_log("");
    }
};

float(entity bot, entity target) frogbot_is_enemy_client =
{
    local float bot_has_team_style;
    local float target_has_team_style;

    if (target == world || target == bot)
        return FALSE;
    if (target.classname != "player")
        return FALSE;
    if (!(target.style & CLANRING_CONNECTED))
        return FALSE;
    if (target.style & CLANRING_OBSERVER)
        return FALSE;
    if (target.deadflag != DEAD_NO || target.health <= 0)
        return FALSE;
    // Match weapon rules: leave-me-alone only blocks targeting outside active play.
    if (target.leavemealone && !match_in_progress())
        return FALSE;

    // Only enforce team-friend filtering in actual teamplay modes.
    if (teamplay)
    {
        if (bot.team > 0 && target.team > 0 && bot.team == target.team)
            return FALSE;

        // Fallback for transitional states where style bits are present before team settles.
        bot_has_team_style = (bot.style & (CLANRING_RED_TEAM | CLANRING_BLUE_TEAM));
        target_has_team_style = (target.style & (CLANRING_RED_TEAM | CLANRING_BLUE_TEAM));
        if (bot_has_team_style && target_has_team_style)
        {
            if ((bot.style & CLANRING_RED_TEAM) && (target.style & CLANRING_RED_TEAM))
                return FALSE;
            if ((bot.style & CLANRING_BLUE_TEAM) && (target.style & CLANRING_BLUE_TEAM))
                return FALSE;
        }
    }

    if ((clanring_playmode & (CLANRING_CA_MODE | CLANRING_RA_MODE)) && target.ca_player_flag != PF_PLAYING)
        return FALSE;

    return TRUE;
};

float(entity bot, entity target) frogbot_visibility_front_dot =
{
    local vector start;
    local vector goal;
    local vector to_target;
    local vector view_fwd;

    if (bot == world || target == world)
        return -1;

    start = bot.origin;
    start_z = start_z + bot.view_ofs_z;
    goal = target.origin;
    goal_z = goal_z + target.view_ofs_z * 0.75;
    to_target = goal - start;
    if (vlen(to_target) <= 1)
        return 1;

    makevectors(bot.v_angle);
    view_fwd = v_forward;
    return normalize(to_target) * view_fwd;
};

float(entity bot, entity target, vector goal) frogbot_visibility_trace_point =
{
    local vector start;

    if (!frogbot_is_enemy_client(bot, target))
        return FALSE;

    start = bot.origin;
    start_z = start_z + bot.view_ofs_z;
    traceline(start, goal, TRUE, bot);
    if (trace_fraction >= 1)
        return TRUE;
    if (trace_ent == target)
        return TRUE;
    return FALSE;
};

float(entity bot, entity target) frogbot_target_visible =
{
    local vector goal;
    local float use_multi;
    local float allow_360;
    local float front_dot;
    local float front_min_dot;

    if (!frogbot_is_enemy_client(bot, target))
        return FALSE;

    goal = target.origin;
    goal_z = goal_z + target.view_ofs_z * 0.75;
    if (frogbot_visibility_trace_point(bot, target, goal))
        return TRUE;

    use_multi = (cvar("frogbot_visibility_multi") > 0);
    if (!use_multi)
        return FALSE;

    allow_360 = (cvar("frogbot_visibility_scan_360") > 0);
    front_min_dot = cvar("frogbot_visibility_front_min_dot");
    if (front_min_dot <= -1 || front_min_dot >= 1)
        front_min_dot = 0.2;
    front_dot = frogbot_visibility_front_dot(bot, target);
    if (!allow_360 && front_dot < front_min_dot)
        return FALSE;

    goal = target.origin;
    goal_z = goal_z + target.view_ofs_z;
    if (frogbot_visibility_trace_point(bot, target, goal))
        return TRUE;
    goal = target.origin;
    goal_z = goal_z + 24;
    if (frogbot_visibility_trace_point(bot, target, goal))
        return TRUE;
    goal = target.origin;
    goal_z = goal_z + 8;
    if (frogbot_visibility_trace_point(bot, target, goal))
        return TRUE;

    return FALSE;
};

float(entity a, entity b) frogbot_same_team =
{
    local float a_team_style;
    local float b_team_style;

    if (a == world || b == world || a == b)
        return FALSE;

    if (!teamplay)
        return FALSE;

    if (a.team > 0 && b.team > 0 && a.team == b.team)
        return TRUE;

    a_team_style = (a.style & (CLANRING_RED_TEAM | CLANRING_BLUE_TEAM));
    b_team_style = (b.style & (CLANRING_RED_TEAM | CLANRING_BLUE_TEAM));
    if (!a_team_style || !b_team_style)
        return FALSE;

    if ((a.style & CLANRING_RED_TEAM) && (b.style & CLANRING_RED_TEAM))
        return TRUE;
    if ((a.style & CLANRING_BLUE_TEAM) && (b.style & CLANRING_BLUE_TEAM))
        return TRUE;

    return FALSE;
};

float(entity bot, float max_dist, float min_dot) frogbot_teammate_in_firelane =
{
    local entity p;
    local vector diff;
    local vector dir;
    local float dist;

    if (max_dist <= 0)
        return FALSE;

    p = nextent(world);
    while (p != world)
    {
        if (p != bot
            && p.classname == "player"
            && (p.style & CLANRING_CONNECTED)
            && !(p.style & CLANRING_OBSERVER)
            && p.deadflag == DEAD_NO
            && p.health > 0
            && frogbot_same_team(bot, p))
        {
            diff = p.origin - bot.origin;
            diff_z = diff_z + p.view_ofs_z * 0.5;
            dist = vlen(diff);
            if (dist > 1 && dist <= max_dist)
            {
                dir = normalize(diff);
                if (dir * v_forward >= min_dot)
                    return TRUE;
            }
        }
        p = nextent(p);
    }

    return FALSE;
};

float(entity bot, float enemy_dist) frogbot_projectile_splash_estimate =
{
    local float splash_damage;

    if (bot == world)
        return 0;
    if (cvar("frogbot_splash_use_ktx_formula") <= 0)
        return 0;

    splash_damage = 80 - (0.25 * enemy_dist);
    if (splash_damage <= 0)
        return 0;

    // KTX parity: in these modes, don't apply splash self-risk gating.
    if (teamplay == 1 || teamplay == 5 || (clanring_playmode & CLANRING_AIRSHOT_MODE))
        return 0;

    if (bot.super_damage_finished > time)
    {
        if (deathmatch != 4)
            splash_damage = splash_damage * 4;
        else
            splash_damage = splash_damage * 8;
    }

    // Rune effects should always apply, with or without quad.
    if (bot.player_flag & ITEM_RUNE2_FLAG)
        splash_damage = splash_damage * frogbot_rune_scale_str(bot);
    else if (bot.player_flag & ITEM_RUNE1_FLAG)
        splash_damage = splash_damage / frogbot_rune_scale_res(bot);

    return max(0, splash_damage);
};

float(entity bot, float enemy_dist) frogbot_projectile_self_safe =
{
    local float splash_damage;
    local float total_damage;
    local float margin;
    local float projectile_safe_min_dist;

    if (bot == world)
        return TRUE;

    if (bot.invincible_finished > time || (bot.items & IT_INVULNERABILITY))
        return TRUE;

    if (cvar("frogbot_splash_use_ktx_formula") <= 0)
    {
        projectile_safe_min_dist = cvar("frogbot_projectile_min_dist");
        if (projectile_safe_min_dist <= 0)
            projectile_safe_min_dist = 180;
        return enemy_dist >= projectile_safe_min_dist;
    }

    splash_damage = frogbot_projectile_splash_estimate(bot, enemy_dist);
    if (splash_damage <= 0)
        return TRUE;

    total_damage = max(bot.fb_total_damage, frogbot_total_strength(bot.health, bot.armorvalue, bot.armortype) * frogbot_rune_scale_res(bot));
    margin = cvar("frogbot_splash_safety_margin");
    if (margin < 0)
        margin = 0;

    return total_damage > splash_damage + margin;
};

float(entity bot, vector aim, entity target) frogbot_projectile_bore_safe =
{
    local vector start;
    local vector stop;
    local float trace_dist;

    if (bot == world)
        return TRUE;

    trace_dist = cvar("frogbot_splash_trace_dist");
    if (trace_dist <= 0)
        trace_dist = 112;

    makevectors(aim);
    start = bot.origin + v_forward * 8 + '0 0 16';
    stop = start + v_forward * trace_dist;
    traceline(start, stop, TRUE, bot);

    if (trace_fraction >= 1)
        return TRUE;
    if (trace_ent == world)
        return FALSE;
    if (target != world && trace_ent == target)
        return TRUE;

    if (trace_ent.classname == "player" && !frogbot_same_team(bot, trace_ent))
        return TRUE;

    return FALSE;
};

vector(entity bot, entity target, float weapon, float enemy_dist) frogbot_compute_aim_delta =
{
    local vector aim_target;
    local float projectile_speed;
    local float lead_factor;
    local float lead_time;

    aim_target = target.origin;
    aim_target_z = aim_target_z + target.view_ofs_z * 0.75;

    projectile_speed = 0;
    if (weapon == IT_ROCKET_LAUNCHER)
        projectile_speed = 1000;
    else if (weapon == IT_GRENADE_LAUNCHER)
        projectile_speed = 700;
    else if (weapon == IT_NAILGUN || weapon == IT_SUPER_NAILGUN)
        projectile_speed = 1000;

    lead_factor = cvar("frogbot_combat_lead");
    if (projectile_speed > 1 && lead_factor > 0)
    {
        lead_time = enemy_dist / projectile_speed;
        if (weapon == IT_GRENADE_LAUNCHER)
            lead_time = enemy_dist / 600;
        if ((weapon == IT_NAILGUN || weapon == IT_SUPER_NAILGUN) && (bot.player_flag & ITEM_RUNE3_FLAG))
            lead_time = lead_time / frogbot_rune_scale_hst(bot);
        lead_time = bound(0, lead_time, 0.7);
        aim_target = aim_target + target.velocity * (lead_time * lead_factor);
    }

    return aim_target - bot.origin;
};

float() frogbot_arena_action_active =
{
    if (!mode_is_arena())
        return TRUE;

    if (boss == world)
        return FALSE;
    if (gameover)
        return FALSE;
    if (clanring_state & CLANRING_MATCH_PAUSED)
        return FALSE;
    if (boss.state != CA_MATCH_PLAYING)
        return FALSE;
    if (!boss.timetofight)
        return FALSE;

    return TRUE;
};

float(float base_range) frogbot_mode_combat_range =
{
    local float range_limit;

    range_limit = base_range;
    if (range_limit <= 0)
        range_limit = 1100;

    // Mode-aware tuning so one profile can run across DM/CTF/arena variants.
    if (frogbot_ctf_mode_active())
        range_limit = frogbot_ctf_adjust_combat_range(range_limit);
    else if (clanring_playmode & CLANRING_AIRSHOT_MODE)
        range_limit = range_limit * 1.2;
    else if (clanring_playmode & CLANRING_RA_MODE)
        range_limit = range_limit * 1.08;
    else if (clanring_playmode & CLANRING_CA_MODE)
        range_limit = range_limit * 0.95;
    else if (clanring_playmode & CLANRING_DMM4_MODE)
        range_limit = range_limit * 1.05;

    return bound(450, range_limit, 2600);
};

entity(entity bot) frogbot_find_enemy_target =
{
    local entity p;
    local entity best;
    local entity keep_target;
    local float dist;
    local float score;
    local float best_score;
    local float has_los;
    local float range_limit;
    local float scan_interval;
    local float enemy_total;
    local float enemy_in_range;
    local float enemy_los;
    local float enemy_keep_valid;
    local float had_contact;
    local float lost_delay;
    local float best_visible_now;
    local float keep_power_flags;
    local float best_power_flags;
    local float power_target_penalty;
    local float power_penalty;
    local float power_awareness;
    local float power_threat;
    local float allow_360;
    local float front_min_dot;
    local float back_penalty;
    local float front_dot;
    local float has_front;
    local float enemy_face_dot;
    local entity best_visible_target;
    local float best_visible_score;
    local float best_visible_power_flags;

    range_limit = frogbot_mode_combat_range(cvar("frogbot_combat_range"));
    enemy_total = 0;
    enemy_in_range = 0;
    enemy_los = 0;
    enemy_keep_valid = 0;
    had_contact = (bot.fb_team_has_contact > 0);
    keep_power_flags = 0;
    best_power_flags = 0;
    allow_360 = (cvar("frogbot_visibility_scan_360") > 0);
    front_min_dot = cvar("frogbot_visibility_front_min_dot");
    if (front_min_dot <= -1 || front_min_dot >= 1)
        front_min_dot = 0.2;
    back_penalty = cvar("frogbot_visibility_back_penalty");
    if (back_penalty <= 0)
        back_penalty = 180;
    best_visible_target = world;
    best_visible_score = -999999;
    best_visible_power_flags = 0;
    power_awareness = frogbot_powerup_awareness_enabled();
    if (power_awareness)
        frogbot_prune_enemy_power_memory(bot);

    keep_target = bot.fb_enemy_target;
    if (frogbot_is_enemy_client(bot, keep_target))
    {
        enemy_keep_valid = 1;
        dist = vlen(keep_target.origin - bot.origin);
        if (dist <= range_limit * 1.75)
        {
            if (frogbot_target_visible(bot, keep_target))
            {
                front_dot = frogbot_visibility_front_dot(bot, keep_target);
                if (allow_360 || front_dot >= front_min_dot)
                {
                    if (power_awareness)
                    {
                        keep_power_flags = frogbot_enemy_power_flags(keep_target);
                        if (keep_power_flags > 0)
                            frogbot_track_enemy_power(bot, keep_target, keep_power_flags, TRUE);
                    }
                    bot.fb_last_enemy_seen_time = time;
                    if (!had_contact)
                    {
                        local string spot_loc1;
                        spot_loc1 = frogbot_get_location(keep_target.origin);
                        if (spot_loc1 != "")
                            frogbot_team_say(bot, sprintf("enemy spotted at %s", spot_loc1));
                        else
                            frogbot_team_say(bot, "enemy spotted");
                    }
                    bot.fb_team_has_contact = 1;
                    return keep_target;
                }
            }

            if (bot.fb_last_enemy_seen_time + FROGBOT_COMBAT_TRACK_TIMEOUT > time)
            {
                if (!frogbot_ctf_bot_has_enemy_flag(bot)
                    || dist <= 260
                    || frogbot_target_visible(bot, keep_target))
                {
                    bot.fb_team_has_contact = 1;
                    return keep_target;
                }
            }
        }
    }

    scan_interval = cvar("frogbot_combat_scan_interval");
    if (scan_interval < FROGBOT_COMBAT_MIN_SCAN_INTERVAL)
        scan_interval = FROGBOT_COMBAT_MIN_SCAN_INTERVAL;
    if (bot.fb_next_enemy_scan_time > time)
    {
        if (frogbot_is_enemy_client(bot, keep_target))
        {
            if (!frogbot_ctf_bot_has_enemy_flag(bot)
                || frogbot_target_visible(bot, keep_target))
                return keep_target;
        }
        if (frogbot_debug_trace_enabled() && bot.fb_next_route_log_time <= time)
        {
            bot.fb_next_route_log_time = time + 0.75;
            frogbot_debug_log("");
        }
        return world;
    }
    bot.fb_next_enemy_scan_time = time + scan_interval;

    bot.fb_enemy_target = world;

    best = world;
    best_score = -999999;
    p = nextent(world);
    while (p != world)
    {
        if (frogbot_is_enemy_client(bot, p))
        {
            enemy_total = enemy_total + 1;
            dist = vlen(p.origin - bot.origin);
            if (dist <= range_limit * 1.75)
            {
                enemy_in_range = enemy_in_range + 1;
                keep_power_flags = 0;
                has_los = frogbot_target_visible(bot, p);
                front_dot = -1;
                has_front = FALSE;
                if (has_los)
                {
                    front_dot = frogbot_visibility_front_dot(bot, p);
                    has_front = (front_dot >= front_min_dot);
                    if (!allow_360 && !has_front)
                        has_los = FALSE;
                }
                if (has_los)
                    enemy_los = enemy_los + 1;
                score = (range_limit * 2) - dist;
                if (p == keep_target)
                    score = score + 200;
                if (has_los)
                {
                    score = score + 800;
                    if (has_front)
                        score = score + 120 + (120 * front_dot);
                    else
                        score = score - back_penalty;

                    enemy_face_dot = frogbot_visibility_front_dot(p, bot);
                    if (enemy_face_dot > 0.2)
                        score = score + (enemy_face_dot * 70);
                }
                else
                    score = score - 400;

                if (power_awareness && has_los)
                {
                    keep_power_flags = frogbot_enemy_power_flags(p);
                    if (keep_power_flags > 0)
                    {
                        frogbot_track_enemy_power(bot, p, keep_power_flags, TRUE);
                        power_target_penalty = cvar("frogbot_powerup_target_penalty");
                        if (power_target_penalty <= 0)
                            power_target_penalty = 350;
                        power_threat = frogbot_enemy_power_threat(bot, p);
                        power_penalty = 0;

                        if ((keep_power_flags & FROGBOT_ENEMY_POWER_PENT) && !frogbot_has_pent(bot))
                            power_penalty = power_penalty + (power_target_penalty * power_threat);
                        else if ((keep_power_flags & FROGBOT_ENEMY_POWER_QUAD) && !frogbot_has_quad(bot))
                            power_penalty = power_penalty + (power_target_penalty * 0.45 * power_threat);

                        if (dist < 260)
                            power_penalty = power_penalty * 0.35;
                        score = score - power_penalty;
                    }
                }
                score = score + frogbot_ctf_target_score_adjust(bot, p, score, has_los);

                if (score > best_score)
                {
                    best = p;
                    best_score = score;
                    best_power_flags = keep_power_flags;
                }
                if (has_los && score > best_visible_score)
                {
                    best_visible_target = p;
                    best_visible_score = score;
                    best_visible_power_flags = keep_power_flags;
                }
            }
        }
        p = nextent(p);
    }

    if (cvar("frogbot_visibility_multi_entity") > 0 && best_visible_target != world)
    {
        best = best_visible_target;
        best_power_flags = best_visible_power_flags;
    }

    bot.fb_enemy_target = best;
    if (best != world)
    {
        best_visible_now = frogbot_target_visible(bot, best);
        if (best_visible_now)
        {
            front_dot = frogbot_visibility_front_dot(bot, best);
            if (!allow_360 && front_dot < front_min_dot)
                best_visible_now = FALSE;
        }
        if (best_visible_now)
        {
            if (power_awareness)
            {
                if (best_power_flags <= 0)
                    best_power_flags = frogbot_enemy_power_flags(best);
                if (best_power_flags > 0)
                    frogbot_track_enemy_power(bot, best, best_power_flags, TRUE);
            }
            bot.fb_last_enemy_seen_time = time;
            if (!had_contact)
            {
                local string spot_loc2;
                spot_loc2 = frogbot_get_location(best.origin);
                if (spot_loc2 != "")
                    frogbot_team_say(bot, sprintf("enemy spotted at %s", spot_loc2));
                else
                    frogbot_team_say(bot, "enemy spotted");
            }
        }
        else if (power_awareness)
        {
            frogbot_prune_enemy_power_memory(bot);
        }
        bot.fb_team_has_contact = 1;
    }
    else
    {
        if (power_awareness)
            frogbot_prune_enemy_power_memory(bot);

        if (had_contact)
        {
            lost_delay = cvar("frogbot_team_comms_lost_delay");
            if (lost_delay <= 0)
                lost_delay = 10;
            if (bot.fb_last_enemy_seen_time <= 0
                || bot.fb_last_enemy_seen_time + lost_delay <= time)
            {
                {
                    local string lost_loc;
                    lost_loc = frogbot_get_location(bot.origin);
                    if (lost_loc != "")
                        frogbot_team_say(bot, sprintf("lost enemy at %s", lost_loc));
                    else
                        frogbot_team_say(bot, "lost enemy");
                }
                bot.fb_team_has_contact = 0;
            }
            else
            {
                bot.fb_team_has_contact = 1;
            }
        }
        else
        {
            bot.fb_team_has_contact = 0;
        }
    }

    if (best == world && frogbot_debug_trace_enabled() && bot.fb_next_route_log_time <= time)
    {
        bot.fb_next_route_log_time = time + 0.75;
        frogbot_debug_log("");
    }

    return best;
};

// ============================================================================
// Aim Skill / Volatility System
// ============================================================================

float(float skill_level, float at_zero, float at_twenty) frogbot_skill_range =
{
    return at_zero + (skill_level / 20.0) * (at_twenty - at_zero);
};

void(entity bot, float skill_level) frogbot_apply_skill_level =
{
    skill_level = bound(0, skill_level, 20);
    bot.fb_skill_level = skill_level;
    bot.fb_vol_min = frogbot_skill_range(skill_level, 1.0, 1.0);
    bot.fb_vol_max = frogbot_skill_range(skill_level, 4.0, 2.5);
    bot.fb_vol_initial = frogbot_skill_range(skill_level, 3.0, 1.4);
    bot.fb_vol_reduce = frogbot_skill_range(skill_level, 0.98, 0.96);
    bot.fb_vol_ownspeed_thresh = frogbot_skill_range(skill_level, 360, 450);
    bot.fb_vol_ownspeed = frogbot_skill_range(skill_level, 0.2, 0.1);
    bot.fb_vol_enemyspeed_thresh = frogbot_skill_range(skill_level, 360, 450);
    bot.fb_vol_enemyspeed = frogbot_skill_range(skill_level, 0.4, 0.2);
    bot.fb_vol_enemydir = frogbot_skill_range(skill_level, 0.6, 0.4);
    bot.fb_vol_pain = frogbot_skill_range(skill_level, 0.5, 0.1);
    bot.fb_vol_self_midair = frogbot_skill_range(skill_level, 1.0, 0.0);
    bot.fb_vol_opp_midair = frogbot_skill_range(skill_level, 1.0, 0.0);
    bot.fb_aim_pitch_scale = frogbot_skill_range(skill_level, 5.0, 2.0);
    bot.fb_aim_pitch_min = frogbot_skill_range(skill_level, 1.5, 1.0);
    bot.fb_aim_pitch_max = frogbot_skill_range(skill_level, 4.5, 3.0);
    bot.fb_aim_pitch_mult = frogbot_skill_range(skill_level, 4.0, 2.0);
    bot.fb_aim_yaw_scale = frogbot_skill_range(skill_level, 5.0, 2.0);
    bot.fb_aim_yaw_min = frogbot_skill_range(skill_level, 1.5, 1.0);
    bot.fb_aim_yaw_max = frogbot_skill_range(skill_level, 4.5, 3.0);
    bot.fb_aim_yaw_mult = frogbot_skill_range(skill_level, 4.0, 2.5);
    bot.fb_awareness_delay = frogbot_skill_range(skill_level, 0.75, 0.3);
    bot.fb_skill_lookahead_time = frogbot_skill_range(skill_level, 5.0, 30.0);
    bot.fb_skill_prediction_error = frogbot_skill_range(skill_level, 1.0, 0.0);
    bot.fb_dodge_react_time = frogbot_skill_range(skill_level, 1.0, 0.5);
    bot.fb_dodge_amount = frogbot_skill_range(skill_level, 0.3, 1.0);
    bot.fb_aim_volatility = bot.fb_vol_initial;
};

float(float minval, float maxval, float spread) frogbot_dist_random =
{
    local float sum;
    local float norm;
    local float range;

    sum = random() + random() + random() + random() + random() + random();
    // sum is in [0,6], normalize to [-1,1] with spread
    norm = (sum - 3.0) / 3.0;
    norm = norm * spread;
    norm = bound(-1, norm, 1);
    // scale to [minval, maxval]
    range = maxval - minval;
    return minval + (norm + 1.0) * 0.5 * range;
};

void(entity bot, entity target) frogbot_update_volatility =
{
    local float vol;
    local float hspeed;
    local float espeed;
    local vector evel;
    local vector prev_evel;
    local float dir_dot;

    // Target changed: reset volatility and set reaction delay
    if (target != bot.fb_prev_combat_target)
    {
        bot.fb_aim_volatility = bot.fb_vol_initial;
        bot.fb_min_fire_time = time + bot.fb_awareness_delay;
        bot.fb_aim_rnd_time = 0;
        bot.fb_prev_combat_target = target;
        bot.fb_prev_enemy_vel = target.velocity;
        return;
    }

    vol = bot.fb_aim_volatility;

    // Reduce volatility each frame (converge toward stable aim)
    vol = vol * bot.fb_vol_reduce;

    // Penalty: bot moving fast (horizontal speed)
    hspeed = vlen(bot.velocity - bot.velocity_z * '0 0 1');
    if (hspeed > bot.fb_vol_ownspeed_thresh)
        vol = vol + bot.fb_vol_ownspeed;

    // Penalty: enemy moving fast
    espeed = vlen(target.velocity - target.velocity_z * '0 0 1');
    if (espeed > bot.fb_vol_enemyspeed_thresh)
        vol = vol + bot.fb_vol_enemyspeed;

    // Penalty: enemy direction change
    evel = target.velocity;
    prev_evel = bot.fb_prev_enemy_vel;
    if (vlen(evel) > 1 && vlen(prev_evel) > 1)
    {
        dir_dot = normalize(evel) * normalize(prev_evel);
        vol = vol + bot.fb_vol_enemydir * (1.0 - dir_dot);
    }
    bot.fb_prev_enemy_vel = evel;

    // Penalty: bot recently took damage
    if (bot.fb_last_hurt_time > 0 && (time - bot.fb_last_hurt_time) < 1.0)
        vol = vol + bot.fb_vol_pain;

    // Penalty: bot is midair
    if (!(bot.flags & FL_ONGROUND))
        vol = vol + bot.fb_vol_self_midair;

    // Penalty: enemy is midair
    if (!(target.flags & FL_ONGROUND))
        vol = vol + bot.fb_vol_opp_midair;

    vol = bound(bot.fb_vol_min, vol, bot.fb_vol_max);
    bot.fb_aim_volatility = vol;
};

vector(entity bot, vector aim_angles, float weapon) frogbot_apply_aim_error =
{
    local float raw_pitch;
    local float raw_yaw;
    local float pitch_diff;
    local float yaw_diff;
    local float regen_interval;
    local float old_sign_p;
    local float old_sign_y;
    local vector result;

    raw_pitch = aim_angles_x - bot.v_angle_x;
    // normalize to [-180, 180]
    while (raw_pitch > 180) raw_pitch = raw_pitch - 360;
    while (raw_pitch < -180) raw_pitch = raw_pitch + 360;

    raw_yaw = aim_angles_y - bot.v_angle_y;
    while (raw_yaw > 180) raw_yaw = raw_yaw - 360;
    while (raw_yaw < -180) raw_yaw = raw_yaw + 360;

    pitch_diff = fabs(raw_pitch) * bot.fb_aim_pitch_scale;
    pitch_diff = bound(bot.fb_aim_pitch_min, pitch_diff, bot.fb_aim_pitch_max);

    yaw_diff = fabs(raw_yaw) * bot.fb_aim_yaw_scale;
    yaw_diff = bound(bot.fb_aim_yaw_min, yaw_diff, bot.fb_aim_yaw_max);

    // Regenerate random aim error periodically
    regen_interval = 0.3;
    if (weapon == IT_LIGHTNING)
        regen_interval = 0.1;

    if (bot.fb_aim_rnd_time == 0 || (time - bot.fb_aim_rnd_time) >= regen_interval)
    {
        old_sign_p = 0;
        old_sign_y = 0;
        if (fabs(bot.fb_aim_rnd_pitch) > 0.001)
            old_sign_p = (bot.fb_aim_rnd_pitch > 0) ? 1 : -1;
        if (fabs(bot.fb_aim_rnd_yaw) > 0.001)
            old_sign_y = (bot.fb_aim_rnd_yaw > 0) ? 1 : -1;

        bot.fb_aim_rnd_pitch = frogbot_dist_random(-pitch_diff, pitch_diff, bot.fb_aim_pitch_mult * bot.fb_aim_volatility);
        bot.fb_aim_rnd_yaw = frogbot_dist_random(-yaw_diff, yaw_diff, bot.fb_aim_yaw_mult * bot.fb_aim_volatility);

        // 80% chance to preserve sign from previous frame (sticky direction)
        if (old_sign_p != 0 && random() < 0.8)
            bot.fb_aim_rnd_pitch = fabs(bot.fb_aim_rnd_pitch) * old_sign_p;
        if (old_sign_y != 0 && random() < 0.8)
            bot.fb_aim_rnd_yaw = fabs(bot.fb_aim_rnd_yaw) * old_sign_y;

        bot.fb_aim_rnd_time = time;
    }

    result = aim_angles;
    result_x = result_x + bot.fb_aim_rnd_pitch;
    result_y = result_y + bot.fb_aim_rnd_yaw;
    result_x = bound(-70, result_x, 80);

    return result;
};

// ============================================================================
// End Aim Skill / Volatility System
// ============================================================================

// ============================================================================
// Missile Dodge System
// ============================================================================

entity(entity bot) frogbot_find_dodge_missile =
{
    local entity m;
    local entity best;
    local float best_dist;
    local float dist;
    local float dodge_max_dist;
    local float missile_age;
    local vector to_bot;
    local float dot;

    best = world;
    best_dist = 99999;
    dodge_max_dist = 1200;

    // Scan rockets
    m = find(world, classname, "missile");
    while (m)
    {
        if (m.owner == bot.fb_enemy_target)
        {
            dist = vlen(bot.origin - m.origin);
            if (dist <= dodge_max_dist
                && (time - m.fb_missile_spawntime) >= bot.fb_dodge_react_time)
            {
                to_bot = normalize(bot.origin - m.origin);
                dot = to_bot * m.fb_missile_forward;
                if (dot > 0.7071 && dist < best_dist)
                {
                    best_dist = dist;
                    best = m;
                }
            }
        }
        m = find(m, classname, "missile");
    }

    // Scan grenades
    m = find(world, classname, "grenade");
    while (m)
    {
        if (m.owner == bot.fb_enemy_target)
        {
            missile_age = time - m.fb_missile_spawntime;
            dist = vlen(bot.origin - m.origin);
            if (dist <= dodge_max_dist
                && missile_age >= bot.fb_dodge_react_time
                && missile_age <= 0.35
                && !(m.flags & FL_ONGROUND))
            {
                // Grenade dodge vectors become unreliable after bounces.
                to_bot = normalize(bot.origin - m.origin);
                dot = to_bot * m.fb_missile_forward;
                if (dot > 0.7071 && dist < best_dist)
                {
                    best_dist = dist;
                    best = m;
                }
            }
        }
        m = find(m, classname, "grenade");
    }

    return best;
};

float(entity bot, entity missile) frogbot_compute_dodge_factor =
{
    local vector rel;
    local float factor;

    rel = normalize(bot.origin - missile.origin);
    factor = rel * missile.fb_missile_right;

    // When centered on path, avoid deterministic single-side bias.
    if (fabs(factor) < 0.05)
        return (random() < 0.5) ? -1 : 1;

    // Normalize toward zero (KTX style: push away from missile path center)
    if (factor > 0)
        factor = factor - 1;
    else
        factor = factor + 1;

    return factor;
};

float(entity bot, entity target) frogbot_compute_player_dodge_factor =
{
    local vector to_bot;
    local vector fwd;
    local vector rt;
    local float approach_dot;
    local float factor;

    to_bot = normalize(bot.origin - target.origin);
    makevectors(target.v_angle);
    fwd = v_forward;
    rt = v_right;

    approach_dot = to_bot * fwd;
    if (approach_dot <= 0.5)
        return 0;

    factor = to_bot * rt;

    // Centerline fallback: avoid deterministic one-side bias.
    if (fabs(factor) < 0.05)
        return (random() < 0.5) ? -1 : 1;

    if (factor > 0)
        factor = factor - 1;
    else
        factor = factor + 1;

    return factor;
};

// ============================================================================
// End Missile Dodge System
// ============================================================================

void(entity bot, entity target, vector route_delta, float move_speed) frogbot_apply_combat_controls =
{
    local vector aim_delta;
    local vector aim;
    local vector route_dir;
    local vector target_dir;
    local float enemy_dist;
    local float fire_dot;
    local float fire_now;
    local float strafe_scale;
    local float combat_range;
    local float has_los;
    local float best_weapon;
    local float fire_min_dot;
    local float is_hitscan_like;
    local float is_spread_like;
    local float is_projectile_like;
    local float is_melee;
    local float weapon_max_range;
    local float can_lg;
    local float can_sng;
    local float can_ng;
    local float can_ssg;
    local float can_sg;
    local float can_rl;
    local float prefer_close_non_projectile_dist;
    local float shotgun_far_switch_dist;
    local float arena_mode;
    local float projectile_safe_min_dist;
    local float ff_dist;
    local float ff_cone;
    local float splash_safety_enabled;
    local float splash_damage;
    local float splash_total_damage;
    local float fallback_weapon;
    local float fallback_swapped;
    local float weapon_before;
    local float blocked_by_ff;
    local float blocked_by_self;
    local string fire_reason;
    local entity dodge_missile;
    local float dodge_factor;
    local float dodge_active;
    local float enemy_power_flags;
    local float enemy_power_threat;
    local float dodge_scale;
    local vector combat_state;

    combat_range = frogbot_mode_combat_range(cvar("frogbot_combat_range"));
    arena_mode = mode_is_arena();
    weapon_before = bot.weapon;
    blocked_by_ff = 0;
    blocked_by_self = 0;
    splash_safety_enabled = 0;
    splash_damage = 0;
    splash_total_damage = 0;
    fallback_swapped = FALSE;
    fire_reason = "hold:no-los";
    fire_min_dot = 0;
    weapon_max_range = combat_range;
    fire_dot = 0;
    enemy_power_flags = 0;
    enemy_power_threat = 1;

    aim_delta = target.origin - bot.origin;
    aim_delta_z = aim_delta_z + target.view_ofs_z * 0.75;
    aim = vectoangles(aim_delta);

    if (cvar("frogbot_aim_error") > 0)
        frogbot_update_volatility(bot, target);

    bot.v_angle = aim;
    bot.angles = aim;
    bot.fixangle = TRUE;

    makevectors(aim);

    route_dir = route_delta;
    if (vlen(route_dir) > 0.001)
        route_dir = normalize(route_dir);
    else
        route_dir = v_forward;

    bot.movement_x = move_speed * (route_dir * v_forward);
    bot.movement_y = move_speed * (route_dir * v_right);
    bot.movement_z = 0;
    bot.button1 = 0;

    enemy_dist = vlen(target.origin - bot.origin);
    has_los = frogbot_target_visible(bot, target);
    if (frogbot_powerup_awareness_enabled())
    {
        if (has_los)
            enemy_power_flags = frogbot_enemy_power_flags(target);
        if (enemy_power_flags <= 0 && target == bot.fb_enemy_target)
            enemy_power_flags = bot.fb_enemy_power_flags;
        if (enemy_power_flags > 0)
            enemy_power_threat = frogbot_enemy_power_threat(bot, target);
    }

    // Strafe only when actively dueling. Strafing blind through map geometry hurts route progress.
    dodge_active = FALSE;
    strafe_scale = bound(40, move_speed * 0.45, 140);
    if (cvar("frogbot_combat_strafe") > 0 && has_los && enemy_dist <= combat_range)
    {
        // Missile dodge: directional strafe away from incoming rocket/grenade path
        if (cvar("frogbot_missile_dodge") > 0
            && (bot.flags & FL_ONGROUND)
            && bot.waterlevel < 1
            && !bot.fb_rj_pending
            && !(bot.fb_target_path_flags & FROGBOT_PATH_JUMP_LEDGE))
        {
            dodge_missile = frogbot_find_dodge_missile(bot);
            if (dodge_missile != world)
            {
                dodge_factor = frogbot_compute_dodge_factor(bot, dodge_missile);
                bot.fb_dodge_missile = dodge_missile;
                dodge_active = TRUE;
            }
            else
            {
                dodge_factor = frogbot_compute_player_dodge_factor(bot, target);
                bot.fb_dodge_missile = world;
                if (dodge_factor != 0)
                    dodge_active = TRUE;
            }
        }

        if (dodge_active)
        {
            dodge_scale = bound(0.4, random(), 1.0);
            bot.movement_y = bot.movement_y + (dodge_scale * bot.fb_dodge_amount * dodge_factor * strafe_scale);

            if (cvar("frogbot_debug") >= 3 && bot.fb_next_dodge_log_time <= time)
            {
                bot.fb_next_dodge_log_time = time + 0.75;
                if (bot.fb_dodge_missile != world)
                    dprint(bot.netname, " dodge ent=", bot.fb_dodge_missile.classname, " factor=", ftos(dodge_factor), " amount=", ftos(bot.fb_dodge_amount), " missile=1\n");
                else
                    dprint(bot.netname, " dodge ent=player factor=", ftos(dodge_factor), " amount=", ftos(bot.fb_dodge_amount), " missile=0\n");
            }
        }
        else
        {
            // Original random strafe fallback
            if (bot.fb_next_strafe_swap_time <= time)
            {
                bot.fb_strafe_dir = (random() < 0.5) ? -1 : 1;
                bot.fb_next_strafe_swap_time = time + 0.5 + random();
            }
            bot.movement_y = bot.movement_y + (bot.fb_strafe_dir * strafe_scale);
        }

        // Restore bot view vectors (player dodge fallback calls makevectors on target)
        makevectors(aim);
    }

    if (enemy_dist < 140)
        bot.movement_x = bot.movement_x - 120;
    else if (enemy_dist > combat_range * 0.8)
        bot.movement_x = bot.movement_x + 60;

    if ((enemy_power_flags & FROGBOT_ENEMY_POWER_PENT) && !frogbot_has_pent(bot))
    {
        bot.movement_x = bot.movement_x - 90;
    }
    else if ((enemy_power_flags & FROGBOT_ENEMY_POWER_QUAD)
             && !frogbot_has_quad(bot)
             && bot.fb_total_damage < 180)
    {
        bot.movement_x = bot.movement_x - 50;
    }

    if ((frogbot_has_quad(bot) || frogbot_has_pent(bot))
        && !(enemy_power_flags & FROGBOT_ENEMY_POWER_PENT))
    {
        bot.movement_x = bot.movement_x + 35;
    }

    bot.movement_x = bound(-move_speed, bot.movement_x, move_speed);
    bot.movement_y = bound(-move_speed, bot.movement_y, move_speed);

    fire_now = FALSE;
    if (has_los && enemy_dist <= combat_range)
    {
        fire_reason = "hold:choose";
        can_lg = (bot.waterlevel <= 2 && bot.ammo_cells >= 1 && (bot.items & IT_LIGHTNING));
        can_sng = (bot.ammo_nails >= 2 && (bot.items & IT_SUPER_NAILGUN));
        can_ng = (bot.ammo_nails >= 1 && (bot.items & IT_NAILGUN));
        can_ssg = (bot.ammo_shells >= 2 && (bot.items & IT_SUPER_SHOTGUN));
        can_sg = (bot.ammo_shells >= 1 && (bot.items & IT_SHOTGUN));
        can_rl = (bot.ammo_rockets >= 1 && (bot.items & IT_ROCKET_LAUNCHER));

        prefer_close_non_projectile_dist = frogbot_ctf_prefer_close_non_projectile_dist(arena_mode);
        shotgun_far_switch_dist = frogbot_ctf_shotgun_far_switch_dist(arena_mode);

        best_weapon = W_BestWeapon();
        if (best_weapon != bot.weapon)
        {
            bot.weapon = best_weapon;
            W_SetCurrentAmmo();
        }

        // Prefer non-projectile weapons in close fights.
        if ((bot.weapon == IT_ROCKET_LAUNCHER || bot.weapon == IT_GRENADE_LAUNCHER) && enemy_dist < prefer_close_non_projectile_dist)
        {
            if (can_lg && enemy_dist <= 850)
                bot.weapon = IT_LIGHTNING;
            else if (can_sng)
                bot.weapon = IT_SUPER_NAILGUN;
            else if (can_ng)
                bot.weapon = IT_NAILGUN;
            else if (can_ssg)
                bot.weapon = IT_SUPER_SHOTGUN;
            else if (can_sg)
                bot.weapon = IT_SHOTGUN;
            W_SetCurrentAmmo();
        }
        else if ((bot.weapon == IT_SHOTGUN || bot.weapon == IT_SUPER_SHOTGUN) && enemy_dist > shotgun_far_switch_dist)
        {
            if (can_lg && enemy_dist <= 900)
                bot.weapon = IT_LIGHTNING;
            else if (can_sng)
                bot.weapon = IT_SUPER_NAILGUN;
            else if (can_ng)
                bot.weapon = IT_NAILGUN;
            else if (can_rl)
                bot.weapon = IT_ROCKET_LAUNCHER;
            W_SetCurrentAmmo();
        }
        else if (arena_mode && can_rl && enemy_dist >= 330 && enemy_dist <= 1000
                 && bot.weapon != IT_ROCKET_LAUNCHER && bot.weapon != IT_GRENADE_LAUNCHER)
        {
            // Arena-style modes generally reward stronger midrange projectile pressure.
            bot.weapon = IT_ROCKET_LAUNCHER;
            W_SetCurrentAmmo();
        }

        aim_delta = frogbot_compute_aim_delta(bot, target, bot.weapon, enemy_dist);
        aim = vectoangles(aim_delta);

        if (cvar("frogbot_aim_error") > 0)
            aim = frogbot_apply_aim_error(bot, aim, bot.weapon);

        bot.v_angle = aim;
        bot.angles = aim;
        bot.fixangle = TRUE;
        makevectors(aim);

        target_dir = target.origin - bot.origin;
        target_dir_z = target_dir_z + target.view_ofs_z * 0.75;
        if (vlen(target_dir) > 1)
            target_dir = normalize(target_dir);
        fire_dot = target_dir * v_forward;

        is_melee = (bot.weapon == IT_AXE);
        is_projectile_like = (bot.weapon == IT_ROCKET_LAUNCHER || bot.weapon == IT_GRENADE_LAUNCHER);
        is_hitscan_like = (bot.weapon == IT_LIGHTNING || bot.weapon == IT_NAILGUN || bot.weapon == IT_SUPER_NAILGUN);
        is_spread_like = (bot.weapon == IT_SHOTGUN || bot.weapon == IT_SUPER_SHOTGUN);

        weapon_max_range = combat_range;
        if (bot.weapon == IT_AXE)
            weapon_max_range = 92;
        else if (bot.weapon == IT_SHOTGUN)
            weapon_max_range = 520;
        else if (bot.weapon == IT_SUPER_SHOTGUN)
            weapon_max_range = 430;
        else if (bot.weapon == IT_NAILGUN)
            weapon_max_range = 1000;
        else if (bot.weapon == IT_SUPER_NAILGUN)
            weapon_max_range = arena_mode ? 1000 : 1150;
        else if (bot.weapon == IT_LIGHTNING)
            weapon_max_range = 850;
        else if (bot.weapon == IT_GRENADE_LAUNCHER)
            weapon_max_range = arena_mode ? 900 : 800;
        else if (bot.weapon == IT_ROCKET_LAUNCHER)
            weapon_max_range = arena_mode ? 1000 : 1200;
        weapon_max_range = frogbot_ctf_adjust_weapon_max_range(bot.weapon, weapon_max_range);
        weapon_max_range = bound(80, weapon_max_range, combat_range);

        fire_min_dot = 0.94;
        if (is_projectile_like)
        {
            fire_min_dot = 0.94;
            if (enemy_dist <= 500)
                fire_min_dot = 0.9;
        }
        else if (is_hitscan_like)
            fire_min_dot = 0.72;
        else if (is_spread_like)
        {
            fire_min_dot = 0.82;
            if (enemy_dist <= 320)
                fire_min_dot = 0.74;
            if (enemy_dist <= 180)
                fire_min_dot = 0.66;
        }
        else if (is_melee)
            fire_min_dot = 0.6;
        else if (enemy_dist <= 320)
            fire_min_dot = 0.84;

        if (enemy_dist <= 192)
            fire_min_dot = fire_min_dot - 0.1;
        if (enemy_dist <= 128)
            fire_min_dot = fire_min_dot - 0.08;

        fire_min_dot = bound(0.58, fire_min_dot, 0.97);
        if (is_melee)
        {
            // Avoid "air-axe" behavior at medium/long distances.
            if (enemy_dist <= 92 && fire_dot >= fire_min_dot)
            {
                fire_now = TRUE;
                fire_reason = "fire:axe";
            }
            else
            {
                fire_now = FALSE;
                fire_reason = "hold:axe-range-dot";
            }
        }
        else if (is_projectile_like)
        {
            if (enemy_dist <= weapon_max_range && fire_dot >= fire_min_dot)
            {
                fire_now = TRUE;
                fire_reason = "fire:proj";
            }
            else if (enemy_dist > weapon_max_range)
                fire_reason = "hold:proj-range";
            else
                fire_reason = "hold:proj-dot";
        }
        else if (enemy_dist <= weapon_max_range && fire_dot >= fire_min_dot)
        {
            fire_now = TRUE;
            fire_reason = "fire:hitscan";
        }
        else if (enemy_dist > weapon_max_range)
            fire_reason = "hold:weapon-range";
        else
            fire_reason = "hold:dot";

        if (fire_now
            && is_projectile_like
            && (enemy_power_flags & FROGBOT_ENEMY_POWER_PENT)
            && !frogbot_has_pent(bot)
            && enemy_dist <= 420)
        {
            fire_now = FALSE;
            fire_reason = "hold:enemy-pent";
        }

        if (fire_now && is_projectile_like)
        {
            splash_safety_enabled = (cvar("frogbot_splash_safety") > 0);
            splash_damage = 0;
            splash_total_damage = 0;
            if (splash_safety_enabled)
            {
                splash_damage = frogbot_projectile_splash_estimate(bot, enemy_dist);
                splash_total_damage = max(bot.fb_total_damage, frogbot_total_strength(bot.health, bot.armorvalue, bot.armortype) * frogbot_rune_scale_res(bot));

                if (!frogbot_projectile_self_safe(bot, enemy_dist))
                {
                    fire_now = FALSE;
                    blocked_by_self = 1;
                    fire_reason = "hold:proj-self-risk";
                }
                else if (!frogbot_projectile_bore_safe(bot, aim, target))
                {
                    fire_now = FALSE;
                    blocked_by_self = 1;
                    fire_reason = "hold:proj-bore";
                }

                // Helper uses makevectors, keep combat vectors aligned with current aim.
                makevectors(aim);
            }
            else
            {
                projectile_safe_min_dist = cvar("frogbot_projectile_min_dist");
                if (projectile_safe_min_dist <= 0)
                    projectile_safe_min_dist = 180;

                // Legacy (non-KTX) mode preserves historical quad bypass behavior.
                if (enemy_dist < projectile_safe_min_dist && !(bot.items & (IT_INVULNERABILITY | IT_QUAD)))
                {
                    fire_now = FALSE;
                    blocked_by_self = 1;
                    fire_reason = "hold:proj-self";
                }
            }

            if (!fire_now && blocked_by_self && splash_safety_enabled)
            {
                fallback_weapon = 0;
                if (can_lg && enemy_dist <= 900 && (bot.waterlevel <= 1 || (bot.items & IT_INVULNERABILITY)))
                    fallback_weapon = IT_LIGHTNING;
                else if (can_sng)
                    fallback_weapon = IT_SUPER_NAILGUN;
                else if (can_ng)
                    fallback_weapon = IT_NAILGUN;
                else if (can_ssg)
                    fallback_weapon = IT_SUPER_SHOTGUN;
                else if (can_sg)
                    fallback_weapon = IT_SHOTGUN;

                if (fallback_weapon > 0 && fallback_weapon != bot.weapon)
                {
                    bot.weapon = fallback_weapon;
                    W_SetCurrentAmmo();
                    fallback_swapped = TRUE;
                    fire_reason = "hold:proj-swap";
                }
            }

            if (fallback_swapped)
            {
                // Re-evaluate once so fallback weapon can fire in the same combat cycle.
                aim_delta = frogbot_compute_aim_delta(bot, target, bot.weapon, enemy_dist);
                aim = vectoangles(aim_delta);

                if (cvar("frogbot_aim_error") > 0)
                    aim = frogbot_apply_aim_error(bot, aim, bot.weapon);

                bot.v_angle = aim;
                bot.angles = aim;
                bot.fixangle = TRUE;
                makevectors(aim);

                target_dir = target.origin - bot.origin;
                target_dir_z = target_dir_z + target.view_ofs_z * 0.75;
                if (vlen(target_dir) > 1)
                    target_dir = normalize(target_dir);
                fire_dot = target_dir * v_forward;

                weapon_max_range = combat_range;
                if (bot.weapon == IT_SHOTGUN)
                    weapon_max_range = 520;
                else if (bot.weapon == IT_SUPER_SHOTGUN)
                    weapon_max_range = 430;
                else if (bot.weapon == IT_NAILGUN)
                    weapon_max_range = 1000;
                else if (bot.weapon == IT_SUPER_NAILGUN)
                    weapon_max_range = arena_mode ? 1000 : 1150;
                else if (bot.weapon == IT_LIGHTNING)
                    weapon_max_range = 850;
                weapon_max_range = frogbot_ctf_adjust_weapon_max_range(bot.weapon, weapon_max_range);
                weapon_max_range = bound(80, weapon_max_range, combat_range);

                fire_min_dot = 0.84;
                if (bot.weapon == IT_LIGHTNING || bot.weapon == IT_NAILGUN || bot.weapon == IT_SUPER_NAILGUN)
                {
                    fire_min_dot = 0.72;
                }
                else if (bot.weapon == IT_SHOTGUN || bot.weapon == IT_SUPER_SHOTGUN)
                {
                    fire_min_dot = 0.82;
                    if (enemy_dist <= 320)
                        fire_min_dot = 0.74;
                    if (enemy_dist <= 180)
                        fire_min_dot = 0.66;
                }
                if (enemy_dist <= 192)
                    fire_min_dot = fire_min_dot - 0.1;
                if (enemy_dist <= 128)
                    fire_min_dot = fire_min_dot - 0.08;
                fire_min_dot = bound(0.58, fire_min_dot, 0.97);

                if (enemy_dist <= weapon_max_range && fire_dot >= fire_min_dot)
                {
                    fire_now = TRUE;
                    fire_reason = "fire:proj-fallback";
                }
            }

            ff_dist = cvar("frogbot_ff_dist");
            if (ff_dist <= 0)
                ff_dist = 420;
            ff_cone = cvar("frogbot_ff_cone");
            if (ff_cone <= 0)
                ff_cone = 0.95;

            if (fire_now && frogbot_teammate_in_firelane(bot, ff_dist, ff_cone))
            {
                fire_now = FALSE;
                blocked_by_ff = 1;
                fire_reason = "hold:proj-ff";
            }
        }
    }
    else if (!has_los)
        fire_reason = "hold:no-los";
    else
        fire_reason = "hold:combat-range";

    // Reaction delay gate: don't fire until awareness delay has elapsed
    if (fire_now && cvar("frogbot_aim_error") > 0 && time < bot.fb_min_fire_time)
    {
        fire_now = FALSE;
        fire_reason = "hold:reaction";
    }

    bot.button0 = fire_now;

    if (cvar("frogbot_debug") >= 2 && bot.fb_next_combat_log_time <= time)
    {
        bot.fb_next_combat_log_time = time + 0.75;
        combat_state = '0 0 0';
        combat_state_x = fire_dot;
        combat_state_y = enemy_power_flags;
        combat_state_z = enemy_power_threat;
        frogbot_debug_log("");
        if (frogbot_debug_trace_enabled())
        {
            frogbot_debug_log("");
            frogbot_debug_log("");
            if (blocked_by_self && splash_safety_enabled)
            {
                frogbot_debug_log("");
            }
            frogbot_debug_log("");
        }
    }
};

void(entity bot) frogbot_apply_stationary_combat =
{
    local entity combat_target;

    if (cvar("frogbot_combat") <= 0)
        return;

    combat_target = frogbot_find_enemy_target(bot);
    if (combat_target == world)
        return;

    // During recover/no-path we still want the bot to duel instead of idling silently.
    frogbot_apply_combat_controls(bot, combat_target, '0 0 0', FROGBOT_MOVE_SPEED_CLOSE);
};

void() frogbot_client_frame =
{
    local vector delta;
    local vector aim;
    local vector jump_test_start;
    local vector jump_test_end;
    local float dist;
    local float move_speed;
    local float want_jump;
    local float jump_flags;
    local float should_step_jump;
    local float path_hint;
    local float try_rj;
    local float rj_delay;
    local float rj_pitch;
    local float rj_yaw;
    local float rj_speed_min;
    local float overhead_clear;
    local float desync_rebind_dist;
    local float in_hazard;
    local float used_hazard_escape;
    local float hazard_rebind_time;
    local entity combat_target;
    local float combat_enabled;
    local float combat_escape_enemy_dist;
    local float combat_enemy_dist;
    local float hook_combat_has_los;
    local float hook_combat_dist;
    local float water_jump;

    if (!frogbot_is_bot_client(self))
        return;

    if (!(self.style & CLANRING_CONNECTED) || self.classname != "player")
    {
        frogbot_stop_movement(self);
        if (self.fb_next_route_log_time <= time && cvar("frogbot_debug") >= 2)
        {
            self.fb_next_route_log_time = time + 2;
            frogbot_debug_log("");
        }
        return;
    }

    if (self.fb_bot_name != "")
        frogbot_set_bot_name(self, self.fb_bot_name);

    if (!frogbot_arena_action_active())
    {
        if (frogbot_is_marker_entity(self.fb_current_marker) || frogbot_is_marker_entity(self.fb_target_marker)
            || self.fb_enemy_target != world || self.fb_stuck_count > 0)
        {
            frogbot_clear_runtime_targets(self);
        }
        frogbot_stop_movement(self);
        if (self.fb_next_route_log_time <= time && cvar("frogbot_debug") >= 2)
        {
            self.fb_next_route_log_time = time + 3;
            frogbot_debug_log("");
        }
        return;
    }

    // Dead bots should not keep stale route/combat state between lives.
    if (self.deadflag != DEAD_NO || self.health <= 0)
    {
        if (frogbot_is_marker_entity(self.fb_current_marker) || frogbot_is_marker_entity(self.fb_target_marker)
            || self.fb_enemy_target != world || self.fb_stuck_count > 0
            || self.fb_failed_until > time)
        {
            frogbot_clear_runtime_targets(self);
        }
        frogbot_stop_movement(self);
        if (self.fb_next_route_log_time <= time && cvar("frogbot_debug") >= 2)
        {
            self.fb_next_route_log_time = time + 1.5;
            frogbot_debug_log("");
        }
        return;
    }

    if (!frogbot_routes_loaded || frogbot_marker_count <= 0)
    {
        frogbot_stop_movement(self);
        if (self.fb_next_route_log_time <= time)
        {
            self.fb_next_route_log_time = time + 5;
            frogbot_debug_log("");
        }
        return;
    }

    frogbot_ctf_update_runtime(self);
    frogbot_loc_periodic_report(self);
    frogbot_refresh_item_desire(self);

    if (self.origin_z < frogbot_map_death_height)
    {
        frogbot_debug_log("");
        frogbot_stop_movement(self);
        frogbot_reset_runtime_state(self);
        self.deadflag = DEAD_RESPAWNABLE;
        respawn();
        return;
    }

    if (frogbot_detect_transition_warp(self))
    {
        self.tp_time = time;
        if (cvar("frogbot_debug") >= 3)
        {
            frogbot_debug_log("");
        }
    }

    in_hazard = (self.watertype == CONTENT_LAVA || self.watertype == CONTENT_SLIME);
    if (cvar("frogbot_avoid_hazards") > 0 && in_hazard)
    {
        used_hazard_escape = frogbot_apply_hazard_escape(self);

        hazard_rebind_time = cvar("frogbot_hazard_rebind_time");
        if (hazard_rebind_time <= 0)
            hazard_rebind_time = 1.1;

        if (!used_hazard_escape && self.fb_last_progress_time + hazard_rebind_time <= time)
        {
            if (cvar("frogbot_debug") >= 2)
            {
                frogbot_debug_log("");
            }
            frogbot_bind_nearest_marker(self, "hazard");
            frogbot_stop_movement(self);
            return;
        }
    }

    combat_enabled = (cvar("frogbot_combat") > 0);
    combat_target = world;
    hook_combat_has_los = FALSE;
    hook_combat_dist = 99999;
    if (combat_enabled)
    {
        combat_target = frogbot_find_enemy_target(self);
        if (combat_target != world)
        {
            frogbot_apply_combat_escape(self, combat_target);
            hook_combat_dist = vlen(combat_target.origin - self.origin);
            hook_combat_has_los = frogbot_target_visible(self, combat_target);
        }
    }
    else
    {
        self.fb_enemy_target = world;
        self.fb_team_has_contact = 0;
    }

    frogbot_update_camp_state(self, combat_target);

    if (!frogbot_is_marker_entity(self.fb_current_marker) && !frogbot_is_marker_entity(self.fb_target_marker))
        frogbot_bind_nearest_marker(self, "initial");

    if (!frogbot_is_marker_entity(self.fb_target_marker) && !frogbot_is_marker_entity(self.fb_current_marker))
    {
        frogbot_stop_movement(self);
        return;
    }

    if (frogbot_try_transition_reanchor(self))
    {
        frogbot_stop_movement(self);
        return;
    }

    if (frogbot_camp_should_hold(self, combat_target))
    {
        frogbot_stop_movement(self);
        frogbot_apply_stationary_combat(self);
        self.fb_last_progress_time = time;
        return;
    }

    if (!frogbot_is_marker_entity(self.fb_target_marker))
    {
        self.fb_target_marker = frogbot_pick_next_target(self, self.fb_current_marker);
        self.fb_last_progress_time = time;
        if (frogbot_is_marker_entity(self.fb_target_marker))
            self.fb_last_target_distance = vlen(self.fb_target_marker.origin - self.origin);
        else
            self.fb_last_target_distance = 999999;

        if (!frogbot_is_marker_entity(self.fb_target_marker))
        {
            if (self.fb_failed_until > time
                && self.fb_failed_from_marker == self.fb_current_marker
                && self.fb_failed_to_marker != world)
            {
                if (cvar("frogbot_debug") >= 2)
                {
                    frogbot_debug_log("");
                }
                self.fb_failed_from_marker = world;
                self.fb_failed_to_marker = world;
                self.fb_failed_until = 0;

                self.fb_target_marker = frogbot_pick_next_target(self, self.fb_current_marker);
                if (frogbot_is_marker_entity(self.fb_target_marker))
                {
                    self.fb_stuck_count = 0;
                    self.fb_last_progress_time = time;
                    self.fb_last_target_distance = vlen(self.fb_target_marker.origin - self.origin);
                }
            }
        }

        if (!frogbot_is_marker_entity(self.fb_target_marker))
        {
            frogbot_stop_movement(self);
            frogbot_apply_stationary_combat(self);
            self.fb_stuck_count = self.fb_stuck_count + 1;
            if (cvar("frogbot_advanced_recovery") > 0
                && cvar("frogbot_transition_stuck_rebind") > 0
                && frogbot_desync_transition_guard(self))
            {
                if (cvar("frogbot_debug") >= 2)
                {
                    frogbot_debug_log("");
                }
                frogbot_bind_nearest_marker(self, "transition");
                return;
            }
            if (self.fb_stuck_count >= 2)
                frogbot_bind_nearest_marker(self, "no-path");
            if (self.fb_next_route_log_time <= time)
            {
                self.fb_next_route_log_time = time + 5;
                frogbot_debug_log("");
                if (frogbot_debug_trace_enabled())
                {
                    frogbot_debug_log("");
                }
            }
            return;
        }

        if (cvar("frogbot_debug") >= 3)
        {
            frogbot_debug_log("");
        }
    }

    delta = self.fb_target_marker.origin - self.origin;
    dist = vlen(delta);

    desync_rebind_dist = cvar("frogbot_desync_rebind_dist");
    if (desync_rebind_dist <= 0)
        desync_rebind_dist = 900;
    if (self.fb_last_target_distance > 0
        && self.fb_last_target_distance < 240
        && dist > desync_rebind_dist)
    {
        if (frogbot_desync_transition_guard(self))
        {
            if (cvar("frogbot_debug") >= 2)
            {
                frogbot_debug_log("");
            }
            frogbot_bind_nearest_marker(self, "transition");
            frogbot_stop_movement(self);
            return;
        }

        if (cvar("frogbot_debug") >= 2)
        {
            frogbot_debug_log("");
        }
        frogbot_bind_nearest_marker(self, "desync");
        frogbot_stop_movement(self);
        return;
    }

    if (dist <= FROGBOT_REACH_RADIUS)
    {
        self.fb_prev_marker = self.fb_current_marker;
        self.fb_current_marker = self.fb_target_marker;
        frogbot_mark_marker_visited(self.fb_current_marker);
        self.fb_target_marker = world;
        self.fb_target_path_index = -1;
        self.fb_target_path_flags = 0;
        self.fb_target_path_hint = 0;
        self.fb_target_rj_delay = 0;
        self.fb_rj_pending = 0;
        self.fb_last_progress_time = time;
        self.fb_last_target_distance = 999999;
        self.fb_stuck_count = 0;

        if (cvar("frogbot_debug") >= 3)
        {
            frogbot_debug_log("");
        }
        frogbot_stop_movement(self);
        return;
    }

    if (dist + 4 < self.fb_last_target_distance)
    {
        self.fb_last_target_distance = dist;
        self.fb_last_progress_time = time;
        self.fb_stuck_count = 0;
    }
    else if (self.fb_last_progress_time + FROGBOT_STUCK_TIMEOUT <= time)
    {
        local float soft_reach_dist;
        local float force_rebind_dist;
        local float force_rebind;
        local float force_rebind_hits;
        local float use_soft_reach;
        local float advanced_recovery;
        local float stuck_marker_snapshot;
        local float stuck_count_snapshot;
        local float best_dist_snapshot;
        local float marker_block_time;
        local float marker_block_scale;
        local float marker_block_max;
        local float marker_block_for;
        local float marker_hits;

        self.fb_stuck_count = self.fb_stuck_count + 1;
        self.fb_last_progress_time = time;

        advanced_recovery = (cvar("frogbot_advanced_recovery") > 0);

        soft_reach_dist = cvar("frogbot_soft_reach_dist");
        use_soft_reach = (advanced_recovery && soft_reach_dist > 0);
        if (use_soft_reach && soft_reach_dist < 112)
            soft_reach_dist = 112;
        if (use_soft_reach && dist <= soft_reach_dist && frogbot_is_marker_entity(self.fb_target_marker))
        {
            self.fb_prev_marker = self.fb_current_marker;
            self.fb_current_marker = self.fb_target_marker;
            frogbot_mark_marker_visited(self.fb_current_marker);
            self.fb_target_marker = world;
            self.fb_target_path_index = -1;
            self.fb_target_path_flags = 0;
            self.fb_target_path_hint = 0;
            self.fb_target_rj_delay = 0;
            self.fb_rj_pending = 0;
            self.fb_last_target_distance = 999999;
            self.fb_stuck_count = 0;
            if (cvar("frogbot_debug") >= 2)
            {
                frogbot_debug_log("");
            }
            frogbot_stop_movement(self);
            return;
        }

        stuck_marker_snapshot = (self.fb_current_marker != world) ? self.fb_current_marker.fb_marker_index : 0;
        stuck_count_snapshot = self.fb_stuck_count;
        best_dist_snapshot = self.fb_last_target_distance;

        force_rebind_dist = cvar("frogbot_force_rebind_dist");
        force_rebind = FALSE;
        if (advanced_recovery && force_rebind_dist > 0 && dist >= force_rebind_dist)
            force_rebind = TRUE;
        force_rebind_hits = cvar("frogbot_marker_force_rebind_hits");

        if (frogbot_is_marker_entity(self.fb_current_marker))
        {
            marker_hits = self.fb_current_marker.fb_blocked_hits + 1;
            self.fb_current_marker.fb_blocked_hits = marker_hits;

            marker_block_time = cvar("frogbot_marker_block_time");
            marker_block_scale = cvar("frogbot_marker_block_scale");
            marker_block_max = cvar("frogbot_marker_block_max");
            marker_block_for = marker_block_time + (marker_hits - 1) * marker_block_scale;
            if (marker_block_max > 0)
                marker_block_for = min(marker_block_for, marker_block_max);

            if (marker_block_for > 0)
                self.fb_current_marker.fb_blocked_until = time + marker_block_for;

            if (force_rebind_hits > 0 && marker_hits >= force_rebind_hits)
                force_rebind = TRUE;
        }

        self.fb_failed_from_marker = self.fb_current_marker;
        self.fb_failed_to_marker = self.fb_target_marker;
        self.fb_failed_until = time + 20;
        self.fb_prev_marker = self.fb_target_marker;
        self.fb_target_marker = world;
        self.fb_target_path_index = -1;
        self.fb_target_path_flags = 0;
        self.fb_target_path_hint = 0;
        self.fb_target_rj_delay = 0;
        self.fb_rj_pending = 0;
        if (advanced_recovery && cvar("frogbot_transition_stuck_rebind") > 0 && frogbot_desync_transition_guard(self))
        {
            if (cvar("frogbot_debug") >= 2)
            {
                frogbot_debug_log("");
            }
            frogbot_bind_nearest_marker(self, "transition");
        }
        else if (force_rebind || self.fb_stuck_count >= 2)
            frogbot_bind_nearest_marker(self, "stuck");
        if (cvar("frogbot_debug") >= 2)
        {
            frogbot_debug_log("");
            if (frogbot_debug_trace_enabled())
            {
                frogbot_debug_log("");
                frogbot_debug_log("");
                if (frogbot_is_marker_entity(self.fb_failed_from_marker))
                {
                    frogbot_debug_log("");
                }
            }
        }
        frogbot_stop_movement(self);
        frogbot_apply_stationary_combat(self);
        return;
    }

    move_speed = FROGBOT_MOVE_SPEED;
    if (dist < 160)
        move_speed = FROGBOT_MOVE_SPEED_CLOSE;
    self.button0 = 0;
    self.button1 = 0;

    if (!combat_enabled)
    {
        if (cvar("frogbot_debug") >= 2 && self.fb_next_combat_log_time <= time)
        {
            self.fb_next_combat_log_time = time + 2;
            frogbot_debug_log("");
        }
    }

    if (combat_target != world)
    {
        frogbot_apply_combat_controls(self, combat_target, delta, move_speed);
    }
    else
    {
        aim = vectoangles(delta);
        aim_x = 0;
        self.v_angle = aim;
        self.angles = aim;
        self.fixangle = TRUE;
        self.movement_x = move_speed;
        self.movement_y = 0;
        self.movement_z = 0;

        if (combat_enabled && cvar("frogbot_debug") >= 2 && self.fb_next_combat_log_time <= time)
        {
            self.fb_next_combat_log_time = time + 2;
            frogbot_debug_log("");
        }
    }

    if (frogbot_ctf_apply_hook_climb(self, combat_target, hook_combat_has_los,
                                      hook_combat_dist, delta, dist,
                                      self.fb_target_path_flags))
    {
        self.button2 = 0;
        return;
    }

    frogbot_ctf_apply_hook_transit(self, combat_target, hook_combat_has_los, hook_combat_dist, delta, dist);

    water_jump = frogbot_apply_water_movement(self, delta, move_speed);
    frogbot_apply_blocked_recovery(self, delta, move_speed, combat_target != world);
    if (self.button2)
        water_jump = TRUE;

    if (self.fb_rj_pending)
    {
        aim_x = self.fb_rj_pitch;
        aim_y = self.fb_rj_yaw;
        aim_z = 0;
        self.v_angle = aim;
        self.angles = aim;
        self.fixangle = TRUE;

        if (self.fb_rj_fire_time <= time)
        {
            self.button0 = 1;
            self.fb_rj_pending = 0;
            if (cvar("frogbot_debug") >= 3)
            {
                frogbot_debug_log("");
            }
        }
    }

    want_jump = water_jump;
    if (self.waterlevel <= 1 && (self.flags & (FL_ONGROUND | FL_PARTIALGROUND)))
    {
        jump_flags = self.fb_target_path_flags & (FROGBOT_PATH_WATERJUMP | FROGBOT_PATH_JUMP_LEDGE | FROGBOT_PATH_CURLJUMP_HINT);
        path_hint = self.fb_target_path_hint;

        try_rj = FALSE;
        if ((self.fb_target_path_flags & FROGBOT_PATH_ROCKET_JUMP) && frogbot_can_rj_now(self))
        {
            rj_speed_min = cvar("frogbot_rj_speed_min");
            if (rj_speed_min <= 0)
                rj_speed_min = 200;

            if (self.fb_next_jump_time <= time
                && dist >= FROGBOT_RJ_MIN_START_DIST
                && dist <= FROGBOT_RJ_MAX_START_DIST
                && vlen(self.velocity) >= rj_speed_min)
            {
                try_rj = TRUE;
            }
        }

        if (try_rj)
        {
            rj_pitch = frogbot_get_rj_pitch(self.fb_current_marker, self.fb_target_path_index);
            rj_yaw = frogbot_get_rj_yaw(self.fb_current_marker, self.fb_target_path_index);
            rj_delay = self.fb_target_rj_delay;
            if (rj_pitch <= 0)
                rj_pitch = FROGBOT_RJ_DEFAULT_PITCH;
            if (rj_yaw <= 0)
            {
                aim = vectoangles(delta);
                rj_yaw = aim_y;
            }

            self.fb_rj_pitch = rj_pitch;
            self.fb_rj_yaw = rj_yaw;

            aim_x = rj_pitch;
            aim_y = rj_yaw;
            aim_z = 0;
            self.v_angle = aim;
            self.angles = aim;
            self.fixangle = TRUE;

            if (self.weapon != IT_ROCKET_LAUNCHER)
            {
                self.weapon = IT_ROCKET_LAUNCHER;
                W_SetCurrentAmmo();
            }

            want_jump = TRUE;
            if (rj_delay <= 0)
            {
                self.button0 = 1;
                self.fb_rj_pending = 0;
                if (cvar("frogbot_debug") >= 3)
                {
                    frogbot_debug_log("");
                }
            }
            else
            {
                self.fb_rj_pending = 1;
                self.fb_rj_fire_time = time + bound(0, rj_delay, 20) * frametime;
                if (cvar("frogbot_debug") >= 3)
                {
                    frogbot_debug_log("");
                }
            }
            self.fb_next_jump_time = time + 0.45 + bound(0, rj_delay, 12) * frametime;
        }
        else
        {
            should_step_jump = (delta_z > 36 && delta_z < 128 && dist > 72 && dist < 260);
            if (path_hint || (self.fb_target_path_flags & FROGBOT_PATH_CURLJUMP_HINT))
            {
                if (delta_z > 8 && delta_z < 152 && dist > 60 && dist < 260)
                    should_step_jump = TRUE;
            }

            if (self.waterlevel > 1 || self.velocity_z > 80)
                should_step_jump = FALSE;
            if (combat_target != world && dist < 180)
                should_step_jump = FALSE;

            jump_test_start = self.origin;
            jump_test_start_z = jump_test_start_z + 24;
            jump_test_end = jump_test_start;
            jump_test_end_z = jump_test_end_z + 56;
            traceline(jump_test_start, jump_test_end, TRUE, self);
            overhead_clear = (trace_fraction >= 1 || trace_ent == world || trace_ent == self.fb_target_marker);
            if (!overhead_clear)
                should_step_jump = FALSE;

            // Prevent pogo behavior by requiring a brief cooldown between jump attempts.
            if (self.fb_next_jump_time <= time && (jump_flags || should_step_jump))
            {
                want_jump = TRUE;
                if (jump_flags || path_hint)
                    self.fb_next_jump_time = time + 0.42;
                else
                    self.fb_next_jump_time = time + 0.32;
            }
        }

        if (!want_jump
            && combat_target != world
            && self.fb_combat_escape_until > time
            && cvar("frogbot_combat_escape_jump") > 0
            && !self.fb_rj_pending)
        {
            combat_escape_enemy_dist = cvar("frogbot_combat_escape_enemy_dist");
            if (combat_escape_enemy_dist <= 0)
                combat_escape_enemy_dist = 650;
            combat_enemy_dist = vlen(combat_target.origin - self.origin);

            if (self.fb_next_jump_time <= time
                && combat_enemy_dist <= combat_escape_enemy_dist + 180
                && self.velocity_z <= 80)
            {
                jump_test_start = self.origin;
                jump_test_start_z = jump_test_start_z + 24;
                jump_test_end = jump_test_start;
                jump_test_end_z = jump_test_end_z + 56;
                traceline(jump_test_start, jump_test_end, TRUE, self);
                overhead_clear = (trace_fraction >= 1 || trace_ent == world || trace_ent == self.fb_target_marker);
                if (overhead_clear)
                {
                    want_jump = TRUE;
                    self.fb_next_jump_time = time + 0.34 + random() * 0.24;
                    if (cvar("frogbot_debug") >= 3)
                    {
                        frogbot_debug_log("");
                    }
                }
            }
        }
    }
    self.button2 = want_jump;

    if (cvar("frogbot_debug") >= 3 && self.fb_next_move_log_time <= time)
    {
        self.fb_next_move_log_time = time + 1;
        frogbot_debug_log("");
        frogbot_debug_log("");
    }
};

float(string s) frogbot_decode_marker_flags =
{
    local float i;
    local float marker_flags;
    local string ch;

    i = 0;
    marker_flags = 0;

    while (i < strlen(s))
    {
        ch = substring(s, i, 1);
        if (ch == "u") marker_flags = marker_flags | FROGBOT_MARKER_UNREACHABLE;
        else if (ch == "6") marker_flags = marker_flags | FROGBOT_MARKER_IS_DM6_DOOR;
        else if (ch == "f") marker_flags = marker_flags | FROGBOT_MARKER_FIRE_ON_MATCH_START;
        else if (ch == "b") marker_flags = marker_flags | FROGBOT_MARKER_BLOCKED_ON_STATE_TOP;
        else if (ch == "t") marker_flags = marker_flags | FROGBOT_MARKER_DOOR_TOUCHABLE;
        else if (ch == "e") marker_flags = marker_flags | FROGBOT_MARKER_ESCAPE_ROUTE;
        else if (ch == "n") marker_flags = marker_flags | FROGBOT_MARKER_NOTOUCH;
        i = i + 1;
    }

    return marker_flags;
};

float(string s) frogbot_decode_path_flags =
{
    local float i;
    local float path_flags;
    local string ch;

    i = 0;
    path_flags = 0;

    while (i < strlen(s))
    {
        ch = substring(s, i, 1);
        if (ch == "w") path_flags = path_flags | FROGBOT_PATH_WATERJUMP;
        else if (ch == "6") path_flags = path_flags | FROGBOT_PATH_DM6_DOOR;
        else if (ch == "r") path_flags = path_flags | FROGBOT_PATH_ROCKET_JUMP;
        else if (ch == "j") path_flags = path_flags | FROGBOT_PATH_JUMP_LEDGE;
        else if (ch == "v") path_flags = path_flags | FROGBOT_PATH_VERTICAL_PLATFORM;
        else if (ch == "a") path_flags = path_flags | FROGBOT_PATH_CURLJUMP_HINT;
        i = i + 1;
    }

    return path_flags;
};

float(string requested_map, float verbose, entity notify_target) frogbot_load_routes =
{
    local filestream f;
    local string map_token;
    local string entity_file;
    local string route_dir;
    local string fs_gamedir;
    local string fs_basedir;
    local string fs_game;
    local string line;
    local string cmd;
    local string flags_text;
    local float argc;
    local float marker_number;
    local float source_marker_number;
    local float path_number;
    local float next_marker_number;
    local float goal_number;
    local float zone_number;
    local float marker_flags;
    local float path_flags;
    local float hint;
    local float pitch;
    local float yaw;
    local float delay;
    local float parse_errors;
    local float create_count;
    local float max_marker_ref;
    local float marker_id_base;
    local float create_marker_serial;
    local float created_dynamic;
    local float forcepad_created;
    local float forcepad_next_id;
    local float forcepad_jitter;
    local vector dynamic_spawn_counts;
    local vector dynamic_start_counts;
    local vector forcepad_base_org;
    local vector org;
    local entity marker;
    local entity source_marker;
    local entity next_marker;
    local entity forcepad_anchor;
    local string msg;

    frogbot_clear_routes();

    map_token = strtolower(requested_map);
    if (map_token == "")
        map_token = mapname;

    if (!frogbot_valid_map_token(map_token))
    {
        if (verbose)
            frogbot_notify(notify_target, "Frogbot route load failed: invalid map token.\n");
        return FALSE;
    }

    f = -1;

    entity_file = cvar_string("k_entityfile");
    route_dir = frogbot_get_route_dir();
    fs_gamedir = cvar_string("fs_gamedir");
    fs_basedir = cvar_string("fs_basedir");
    fs_game = cvar_string("game");

    if (entity_file != "")
    {
        entity_file = strtolower(entity_file);
        if (frogbot_valid_map_token(entity_file))
        {
            if (route_dir != "")
                f = frogbot_try_open_route_relative(sprintf("%s/%s.bot", route_dir, entity_file),
                                                    fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
            if (f < 0)
                f = frogbot_try_open_route_relative(sprintf("maps/%s.bot", entity_file),
                                                    fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
            if (f < 0)
                f = frogbot_try_open_route_relative(sprintf("bots/maps/%s.bot", entity_file),
                                                    fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
            if (f < 0)
                f = frogbot_try_open_route_relative(sprintf("ktx/bots/maps/%s.bot", entity_file),
                                                    fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
            if (f < 0)
                f = frogbot_try_open_route_relative(sprintf("ktx/resources/example-configs/ktx/bots/maps/%s.bot", entity_file),
                                                    fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
            if (f < 0)
                f = frogbot_try_open_route_relative(sprintf("frogbot013/bots/maps/%s.bot", entity_file),
                                                    fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
            if (f < 0)
                f = frogbot_try_open_route_relative(sprintf("frogbot013/maps/%s.bot", entity_file),
                                                    fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
            if (f < 0)
                f = frogbot_try_open_route_relative(sprintf("%s.bot", entity_file),
                                                    fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
        }
    }

    if (f < 0 && route_dir != "")
        f = frogbot_try_open_route_relative(sprintf("%s/%s.bot", route_dir, map_token),
                                            fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
    if (f < 0)
        f = frogbot_try_open_route_relative(sprintf("maps/%s.bot", map_token),
                                            fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
    if (f < 0)
        f = frogbot_try_open_route_relative(sprintf("bots/maps/%s.bot", map_token),
                                            fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
    if (f < 0)
        f = frogbot_try_open_route_relative(sprintf("ktx/bots/maps/%s.bot", map_token),
                                            fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
    if (f < 0)
        f = frogbot_try_open_route_relative(sprintf("ktx/resources/example-configs/ktx/bots/maps/%s.bot", map_token),
                                            fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
    if (f < 0)
        f = frogbot_try_open_route_relative(sprintf("frogbot013/bots/maps/%s.bot", map_token),
                                            fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
    if (f < 0)
        f = frogbot_try_open_route_relative(sprintf("frogbot013/maps/%s.bot", map_token),
                                            fs_gamedir, fs_basedir, fs_game, verbose, notify_target);
    if (f < 0)
        f = frogbot_try_open_route_relative(sprintf("%s.bot", map_token),
                                            fs_gamedir, fs_basedir, fs_game, verbose, notify_target);

    if (f < 0)
    {
        if (verbose)
        {
            frogbot_notify(notify_target, sprintf("Frogbot routes not found for map '%s' (route_dir=%s).\n",
                                                  map_token, route_dir));
            if (frogbot_debug_enabled())
                frogbot_notify(notify_target, sprintf("Frogbot debug: fs_gamedir=%s fs_basedir=%s game=%s\n",
                                                      fs_gamedir, fs_basedir, fs_game));
        }
        return FALSE;
    }

    create_count = 0;
    max_marker_ref = 0;
    while ((line = fgets(f)))
    {
        argc = tokenize(line);
        if (argc < 1)
            continue;

        cmd = strtolower(argv(0));
        if (cmd == "" || substring(cmd, 0, 2) == "//")
            continue;

        if (cmd == "createmarker")
        {
            create_count = create_count + 1;
            continue;
        }

        if ((cmd == "setgoal" || cmd == "setzone" || cmd == "setmarkerflag" || cmd == "setmarkerviewofs") && argc >= 2)
        {
            marker_number = stof(argv(1));
            if (marker_number > max_marker_ref)
                max_marker_ref = marker_number;
            continue;
        }

        if (cmd == "setmarkerpath" && argc >= 4)
        {
            source_marker_number = stof(argv(1));
            next_marker_number = stof(argv(3));
            if (source_marker_number > max_marker_ref)
                max_marker_ref = source_marker_number;
            if (next_marker_number > max_marker_ref)
                max_marker_ref = next_marker_number;
            continue;
        }

        if ((cmd == "setmarkerpathflags" || cmd == "setmarkerpathanglehint" || cmd == "setrocketjumppathfields") && argc >= 2)
        {
            source_marker_number = stof(argv(1));
            if (source_marker_number > max_marker_ref)
                max_marker_ref = source_marker_number;
            continue;
        }
    }
    fclose(f);

    f = fopen(frogbot_route_source, FILE_READ);
    if (f < 0)
    {
        if (verbose)
            frogbot_notify(notify_target, sprintf("Frogbot routes load failed: cannot reopen %s.\n", frogbot_route_source));
        frogbot_clear_routes();
        return FALSE;
    }

    marker_id_base = 0;
    if (max_marker_ref > create_count)
        marker_id_base = max_marker_ref - create_count;
    if (marker_id_base < 0)
        marker_id_base = 0;

    if (cvar("frogbot_dynamic_source_refresh") > 0)
        frogbot_rebuild_dynamic_sources();

    if (cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
    }

    parse_errors = 0;
    created_dynamic = frogbot_seed_dynamic_markers(marker_id_base);
    forcepad_created = 0;
    if (created_dynamic < marker_id_base)
    {
        forcepad_anchor = world;
        if (created_dynamic > 0)
            forcepad_anchor = frogbot_get_marker(1);

        if (frogbot_is_marker_entity(forcepad_anchor))
            forcepad_base_org = forcepad_anchor.origin;
        else
            forcepad_base_org = '0 0 0';

        forcepad_next_id = created_dynamic + 1;
        while (forcepad_next_id <= marker_id_base)
        {
            org = forcepad_base_org;
            // Keep placeholder marker IDs valid even when dynamic source classes are missing.
            forcepad_jitter = (forcepad_next_id % 3) - 1;
            org_x = org_x + (forcepad_jitter * 12);
            forcepad_jitter = floor(forcepad_next_id / 3) % 3;
            org_y = org_y + ((forcepad_jitter - 1) * 12);

            marker = frogbot_create_marker(forcepad_next_id, org);
            if (marker == world)
                break;

            if (frogbot_is_marker_entity(forcepad_anchor))
                marker.fb_dynsource = frogbot_dynamic_source_for_marker(forcepad_anchor.fb_dynsource);
            forcepad_created = forcepad_created + 1;
            forcepad_next_id = forcepad_next_id + 1;
        }
        created_dynamic = created_dynamic + forcepad_created;
    }
    if (cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log("");
        if (forcepad_created > 0)
            frogbot_debug_log("");
    }
    if (created_dynamic < marker_id_base)
    {
        parse_errors = parse_errors + (marker_id_base - created_dynamic);
        if (verbose)
            frogbot_notify(notify_target, sprintf("Frogbot warning: seeded %g/%g dynamic markers; some links may be unavailable.\n",
                                                  created_dynamic, marker_id_base));
        if (cvar("frogbot_debug") >= 2)
        {
            dynamic_spawn_counts = '0 0 0';
            dynamic_spawn_counts_x = frogbot_count_classname_raw("info_player_deathmatch");
            dynamic_spawn_counts_y = frogbot_count_classname_raw("info_player_team1");
            dynamic_spawn_counts_z = frogbot_count_classname_raw("info_player_team2");

            dynamic_start_counts = '0 0 0';
            dynamic_start_counts_x = frogbot_count_classname_raw("info_player_team1_deathmatch");
            dynamic_start_counts_y = frogbot_count_classname_raw("info_player_team2_deathmatch");
            dynamic_start_counts_z = frogbot_count_classname_raw("info_player_start");

            frogbot_debug_log("");
        }
    }

    frogbot_map_death_height = FROGBOT_DEFAULT_MAP_DEATH_HEIGHT;
    create_marker_serial = 0;

    while ((line = fgets(f)))
    {
        argc = tokenize(line);
        if (argc < 1)
            continue;

        cmd = strtolower(argv(0));
        if (cmd == "" || substring(cmd, 0, 2) == "//")
            continue;

        if (cmd == "createmarker")
        {
            if (argc != 4)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            create_marker_serial = create_marker_serial + 1;
            org_x = stof(argv(1));
            org_y = stof(argv(2));
            org_z = stof(argv(3));
            if (frogbot_create_marker(marker_id_base + create_marker_serial, org) == world)
                parse_errors = parse_errors + 1;
            continue;
        }

        if (cmd == "setgoal")
        {
            if (argc != 3)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            marker_number = stof(argv(1));
            goal_number = stof(argv(2));
            marker = frogbot_get_marker(marker_number);
            if (marker == world)
            {
                parse_errors = parse_errors + 1;
                continue;
            }
            marker.fb_goal = goal_number;
            continue;
        }

        if (cmd == "setzone")
        {
            if (argc != 3)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            marker_number = stof(argv(1));
            zone_number = rint(stof(argv(2)));
            marker = frogbot_get_marker(marker_number);
            if (marker == world)
            {
                parse_errors = parse_errors + 1;
                continue;
            }
            marker.fb_zone = zone_number;
            continue;
        }

        if (cmd == "setmarkerpath")
        {
            if (argc != 4)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            source_marker_number = stof(argv(1));
            path_number = stof(argv(2));
            next_marker_number = stof(argv(3));
            source_marker = frogbot_get_marker(source_marker_number);
            next_marker = frogbot_get_marker(next_marker_number);
            if (source_marker == world || next_marker == world || path_number < 0 || path_number >= FROGBOT_MAX_PATHS)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            frogbot_set_path_marker(source_marker, path_number, next_marker);
            frogbot_path_link_count = frogbot_path_link_count + 1;
            continue;
        }

        if (cmd == "setmarkerpathflags")
        {
            if (argc != 4)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            source_marker_number = stof(argv(1));
            path_number = stof(argv(2));
            flags_text = argv(3);
            source_marker = frogbot_get_marker(source_marker_number);
            if (source_marker == world || path_number < 0 || path_number >= FROGBOT_MAX_PATHS)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            path_flags = frogbot_decode_path_flags(flags_text);
            frogbot_set_path_flags(source_marker, path_number, path_flags);
            continue;
        }

        if (cmd == "setmarkerflag")
        {
            if (argc != 3)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            marker_number = stof(argv(1));
            flags_text = argv(2);
            marker = frogbot_get_marker(marker_number);
            if (marker == world)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            marker_flags = frogbot_decode_marker_flags(flags_text);
            marker.fb_marker_flags = marker.fb_marker_flags | marker_flags;
            continue;
        }

        if (cmd == "setmarkerviewofs")
        {
            if (argc != 3)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            marker_number = stof(argv(1));
            marker = frogbot_get_marker(marker_number);
            if (marker == world)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            marker.view_ofs_z = stof(argv(2));
            marker.fb_marker_flags = marker.fb_marker_flags | FROGBOT_MARKER_EXPLICIT_VIEWOFFSET;
            continue;
        }

        if (cmd == "setmarkerpathanglehint")
        {
            if (argc != 4)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            source_marker_number = stof(argv(1));
            path_number = stof(argv(2));
            hint = stof(argv(3));
            source_marker = frogbot_get_marker(source_marker_number);
            if (source_marker == world || path_number < 0 || path_number >= FROGBOT_MAX_PATHS)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            frogbot_set_path_hint(source_marker, path_number, hint);
            path_flags = frogbot_get_path_flags(source_marker, path_number);
            if (hint)
                path_flags = path_flags | FROGBOT_PATH_CURLJUMP_HINT;
            else
                path_flags = path_flags - (path_flags & FROGBOT_PATH_CURLJUMP_HINT);
            frogbot_set_path_flags(source_marker, path_number, path_flags);
            continue;
        }

        if (cmd == "setmapdeathheight")
        {
            if (argc != 2)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            frogbot_map_death_height = stof(argv(1));
            if (frogbot_map_death_height < FROGBOT_DEFAULT_MAP_DEATH_HEIGHT)
                frogbot_map_death_height = FROGBOT_DEFAULT_MAP_DEATH_HEIGHT;
            continue;
        }

        if (cmd == "setrocketjumppathfields")
        {
            if (argc != 6)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            source_marker_number = stof(argv(1));
            path_number = stof(argv(2));
            pitch = stof(argv(3));
            yaw = stof(argv(4));
            delay = stof(argv(5));
            source_marker = frogbot_get_marker(source_marker_number);
            if (source_marker == world || path_number < 0 || path_number >= FROGBOT_MAX_PATHS)
            {
                parse_errors = parse_errors + 1;
                continue;
            }

            frogbot_set_rj_fields(source_marker, path_number, pitch, yaw, delay);
            continue;
        }
    }

    fclose(f);

    frogbot_routes_loaded = (frogbot_marker_count > 0);
    frogbot_route_load_errors = parse_errors;
    if (frogbot_routes_loaded)
    {
        frogbot_rebuild_route_potential_cache();
        frogbot_rebuild_zone_cache();
    }
    else
    {
        frogbot_route_potential_ready = FALSE;
        frogbot_zone_cache_ready = FALSE;
    }

    if (verbose)
    {
        if (frogbot_routes_loaded)
        {
            msg = sprintf("Frogbot routes loaded: %g markers, %g links, %g issues (%s)\n",
                          frogbot_marker_count, frogbot_path_link_count, frogbot_route_load_errors, frogbot_route_source);
            frogbot_notify(notify_target, msg);
        }
        else
        {
            msg = sprintf("Frogbot routes file parsed but no markers were created (%s)\n", frogbot_route_source);
            frogbot_notify(notify_target, msg);
        }
    }

    return frogbot_routes_loaded;
};

void(entity target) frogbot_print_status =
{
    local string route_state;
    local string source;
    local string route_dir;
    local vector route_counts;
    local vector route_metrics;
    local vector zone_metrics_a;
    local vector zone_metrics_b;
    local vector zone_validation;
    local vector power_metrics;
    local float power_awareness;
    local float power_memory;
    local float power_tracking;

    route_state = frogbot_routes_loaded ? "loaded" : "missing";
    source = frogbot_route_source;
    route_dir = frogbot_get_route_dir();
    if (source == "")
        source = "(none)";
    power_awareness = cvar("frogbot_powerup_awareness");
    power_memory = frogbot_powerup_memory_window();
    power_tracking = frogbot_count_power_tracking_bots();

    route_counts = '0 0 0';
    route_counts_x = frogbot_marker_count;
    route_counts_y = frogbot_path_link_count;
    route_counts_z = frogbot_route_load_errors;

    route_metrics = '0 0 0';
    route_metrics_x = frogbot_route_potential_ready;
    route_metrics_y = frogbot_route_goal_count;
    route_metrics_z = frogbot_route_relax_iterations;

    zone_metrics_a = '0 0 0';
    zone_metrics_a_x = frogbot_zone_cache_ready;
    zone_metrics_a_y = frogbot_zone_used_count;
    zone_metrics_a_z = frogbot_zone_relax_iterations;

    zone_metrics_b = '0 0 0';
    zone_metrics_b_x = frogbot_zone_assigned_markers;
    zone_metrics_b_y = frogbot_zone_max_subzones;
    zone_metrics_b_z = frogbot_zone_unresolved;

    zone_validation = '0 0 0';
    zone_validation_x = frogbot_zone_validation_checks;
    zone_validation_y = frogbot_zone_validation_failures;
    zone_validation_z = frogbot_zone_validation_ratio;

    power_metrics = '0 0 0';
    power_metrics_x = power_awareness;
    power_metrics_y = power_memory;
    power_metrics_z = power_tracking;

    frogbot_notify(target, sprintf("Frogbot status: b=%g r=%s mli=%v src=%s dir=%s rp=%v\n",
                                   frogbot_count_bots(),
                                   route_state,
                                   route_counts,
                                   source,
                                   route_dir,
                                   route_metrics));
    frogbot_notify(target, sprintf("Frogbot status: z1=%v z2=%v zovf=%g zv=%v p=%v\n",
                                   zone_metrics_a,
                                   zone_metrics_b,
                                   frogbot_zone_overflow_count,
                                   zone_validation,
                                   power_metrics));
};

void(entity target, string map_token_raw) frogbot_print_route_search =
{
    local string route_dir;
    local string fs_gamedir;
    local string fs_basedir;
    local string fs_game;
    local string map_token;

    map_token = strtolower(map_token_raw);
    if (map_token == "")
        map_token = mapname;

    route_dir = frogbot_get_route_dir();
    fs_gamedir = cvar_string("fs_gamedir");
    fs_basedir = cvar_string("fs_basedir");
    fs_game = cvar_string("game");

    frogbot_notify(target, sprintf("Frogbot route search: map=%s route_dir=%s\n", map_token, route_dir));
    frogbot_notify(target, sprintf("Frogbot route search: fs_gamedir=%s fs_basedir=%s game=%s\n",
                                   fs_gamedir, fs_basedir, fs_game));
    frogbot_notify(target, sprintf("Frogbot route search candidates: %s/%s.bot maps/%s.bot bots/maps/%s.bot ktx/bots/maps/%s.bot\n",
                                   route_dir, map_token, map_token, map_token, map_token));
};

float() frogbot_should_join_blue =
{
    local entity p;
    local float red_count;
    local float blue_count;

    red_count = 0;
    blue_count = 0;

    p = find(world, classname, "player");
    while (p)
    {
        if (p.style & CLANRING_CONNECTED)
        {
            if (p.style & CLANRING_RED_TEAM)
                red_count = red_count + 1;
            else if (p.style & CLANRING_BLUE_TEAM)
                blue_count = blue_count + 1;
        }
        p = find(p, classname, "player");
    }

    return (blue_count < red_count);
};

void() frogbot_assign_match_team_color =
{
    local float col;

    if (!teamplay)
    {
        col = self.fb_requested_color;
        if (col <= 0)
            col = 13;
        self.team = col;
        clientcommand(self, sprintf("color %g %g", col, col));
        return;
    }

    // Teamplay: honor requested color if red or blue
    if (self.fb_requested_color == COLOR_RED)
    {
        self.team = RED;
        self.style = (self.style | CLANRING_RED_TEAM);
        self.style = self.style - (self.style & CLANRING_BLUE_TEAM);
        clientcommand(self, "color 4 4");
    }
    else if (self.fb_requested_color == COLOR_BLUE)
    {
        self.team = BLUE;
        self.style = (self.style | CLANRING_BLUE_TEAM);
        self.style = self.style - (self.style & CLANRING_RED_TEAM);
        clientcommand(self, "color 13 13");
    }
    else
    {
        // Auto-balance (default or invalid color for teamplay)
        if (frogbot_should_join_blue())
        {
            self.team = BLUE;
            self.style = (self.style | CLANRING_BLUE_TEAM);
            self.style = self.style - (self.style & CLANRING_RED_TEAM);
            clientcommand(self, "color 13 13");
        }
        else
        {
            self.team = RED;
            self.style = (self.style | CLANRING_RED_TEAM);
            self.style = self.style - (self.style & CLANRING_BLUE_TEAM);
            clientcommand(self, "color 4 4");
        }
    }

    self.height = self.team - 1;
};

void(entity evt) frogbot_free_spawn_event =
{
    if (evt.noise1 != "")
    {
        strunzone(evt.noise1);
        evt.noise1 = "";
    }
    remove(evt);
};

void() frogbot_post_spawn_think =
{
    local entity evt;
    local entity bot;
    local float bot_entnum;

    evt = self;
    bot = evt.owner;

    if (bot == world || !frogbot_is_bot_client(bot))
    {
        frogbot_free_spawn_event(evt);
        return;
    }

    self = bot;
    bot_entnum = num_for_edict(self);
    self.colormap = bot_entnum;

    if (!(self.style & CLANRING_CONNECTED))
    {
        if (!self.fb_bot_bootstrap)
        {
            frogbot_debug_log("");
            self.fb_bot_bootstrap = TRUE;
            ClientConnect();
            PutClientInServer();
        }

        self = evt;
        if (evt.count < 40)
        {
            evt.count = evt.count + 1;
            evt.nextthink = time + 0.1;
            evt.think = frogbot_post_spawn_think;
            return;
        }

        frogbot_debug_log("");
        frogbot_free_spawn_event(evt);
        return;
    }

    if (evt.noise1 != "")
        frogbot_set_bot_name(self, evt.noise1);
    else if (self.fb_bot_name != "")
        frogbot_set_bot_name(self, self.fb_bot_name);

    self.fb_is_bot_client = TRUE;
    self.tp_time = time;
    self.afk_time = time;
    self.finaldest_x = time;
    self.packet_loss = 0;
    forceinfokey(self, "afk", "no");

    if (mode_is_arena())
    {
        self.impulse = 1;
        Teamplay_Select_Team();
        self.impulse = 0;
    }
    else if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        frogbot_assign_match_team_color();
        if (!(self.style & CLANRING_READY))
            match_ready();
    }
    else if (teamplay)
    {
        if (!(self.style & CLANRING_RED_TEAM) && !(self.style & CLANRING_BLUE_TEAM))
        {
            if (self.fb_requested_color == COLOR_RED)
                self.team = RED;
            else if (self.fb_requested_color == COLOR_BLUE)
                self.team = BLUE;
            teamplay_ready_player();
        }
    }

    frogbot_debug_log("");

    self = evt;
    frogbot_free_spawn_event(evt);
};

float(string name) frogbot_name_in_use =
{
    local entity p;
    local float ctype;

    p = nextent(world);
    while (p != world)
    {
        ctype = clienttype(p);
        if (ctype != CLIENTTYPE_NOTACLIENT && ctype != CLIENTTYPE_DISCONNECTED && p.netname == name)
            return TRUE;
        p = nextent(p);
    }
    return FALSE;
};

string(string base_name) frogbot_make_unique_name =
{
    local string base;
    local string candidate;
    local float i;

    base = base_name;
    if (base == "")
        base = "FrogBot";

    candidate = base;
    i = 1;
    while (frogbot_name_in_use(candidate) && i < 1000)
    {
        candidate = sprintf("%s%g", base, i);
        i = i + 1;
    }

    return candidate;
};

entity(string bot_name, float skill_level, float requested_color) frogbot_spawn_one =
{
    local entity bot;
    local entity evt;
    local string unique_name;
    local float bot_entnum;

    bot = spawnclient();
    if (bot == world)
        return world;

    bot_entnum = num_for_edict(bot);
    bot.fb_is_bot_client = TRUE;
    bot.fb_bot_bootstrap = FALSE;
    bot.fb_requested_color = requested_color;
    bot.colormap = bot_entnum;
    frogbot_reset_runtime_state(bot);
    frogbot_apply_skill_level(bot, skill_level);

    unique_name = frogbot_make_unique_name(bot_name);
    frogbot_set_bot_name(bot, unique_name);

    frogbot_debug_log("");

    evt = spawn();
    evt.classname = "frogbot_spawn_event";
    evt.owner = bot;
    evt.think = frogbot_post_spawn_think;
    evt.nextthink = time + 0.1;
    evt.count = 0;
    evt.noise1 = strzone(unique_name);

    return bot;
};

entity(float bot_number) frogbot_find_nth_bot =
{
    local entity p;
    local float i;

    p = nextent(world);
    i = 0;
    while (p != world)
    {
        if (frogbot_is_bot_client(p))
        {
            i = i + 1;
            if (i == bot_number)
                return p;
        }
        p = nextent(p);
    }

    return world;
};

entity(string bot_name) frogbot_find_bot_by_name =
{
    local entity p;

    p = nextent(world);
    while (p != world)
    {
        if (frogbot_is_bot_client(p) && p.netname == bot_name)
            return p;
        p = nextent(p);
    }

    return world;
};

float() frogbot_require_admin =
{
    if (self.style & CLANRING_ADMINISTRATOR)
        return TRUE;

    sprint(self, "Frogbot command denied: admin required.\n");
    return FALSE;
};

float() frogbot_mode_allows_botadd =
{
    if (clanring_playmode & CLANRING_AIRSHOT_MODE)
    {
        sprint(self, "Frogbot: botadd is disabled in Airshot mode.\n");
        return FALSE;
    }

    return TRUE;
};

void(string arg1, string arg2, float requested_color) frogbot_command_add =
{
    local float count;
    local float i;
    local float added;
    local float skill_level;
    local float using_custom_skill;
    local string base_name;
    local string bot_name;
    local string color_desc;
    local float had_name_arg;

    if (!frogbot_mode_allows_botadd())
        return;

    // Validate color for teamplay modes
    if (requested_color > 0 && teamplay)
    {
        if (requested_color != COLOR_RED && requested_color != COLOR_BLUE)
        {
            sprint(self, "Frogbot: only red/blue valid in team modes.\n");
            requested_color = 0;
        }
    }

    count = 1;
    base_name = "";
    skill_level = cvar("frogbot_skill");
    using_custom_skill = FALSE;
    had_name_arg = FALSE;

    if (arg1 != "")
    {
        if (frogbot_is_uint(arg1))
        {
            count = stof(arg1);
            if (arg2 != "")
            {
                if (frogbot_is_uint(arg2))
                {
                    skill_level = stof(arg2);
                    using_custom_skill = TRUE;
                }
                else
                {
                    base_name = arg2;
                    had_name_arg = TRUE;
                }
            }
        }
        else
        {
            base_name = arg1;
            had_name_arg = TRUE;
            if (arg2 != "" && frogbot_is_uint(arg2))
            {
                skill_level = stof(arg2);
                using_custom_skill = TRUE;
            }
        }
    }

    if (count < 1)
        count = 1;
    if (count > 16)
        count = 16;
    skill_level = bound(0, skill_level, 20);

    if (base_name == "")
        base_name = "FrogBot";

    if (!frogbot_routes_loaded)
    {
        frogbot_load_routes(mapname, TRUE, self);
        if (!frogbot_routes_loaded)
            sprint(self, "Frogbot warning: routes missing, bot movement will stay idle.\n");
    }

    i = 1;
    added = 0;
    while (i <= count)
    {
        if (count == 1 && had_name_arg)
            bot_name = base_name;
        else
            bot_name = sprintf("%s%g", base_name, i);

        if (frogbot_spawn_one(bot_name, skill_level, requested_color) == world)
            break;

        added = added + 1;
        i = i + 1;
    }

    frogbot_debug_log("");

    color_desc = "";
    if (requested_color > 0)
    {
        if (requested_color == COLOR_RED)
            color_desc = " (red)";
        else if (requested_color == COLOR_BLUE)
            color_desc = " (blue)";
        else
            color_desc = sprintf(" (color %g)", requested_color);
    }

    if (using_custom_skill)
        sprint(self, sprintf("Frogbot: added %g bot(s) at skill %g%s.\n", added, skill_level, color_desc));
    else
        sprint(self, sprintf("Frogbot: added %g bot(s)%s.\n", added, color_desc));
};

float() frogbot_remove_all_bots =
{
    local entity p;
    local entity nextp;
    local float kicked;

    kicked = 0;
    p = nextent(world);
    while (p != world)
    {
        nextp = nextent(p);
        if (frogbot_is_bot_client(p))
        {
            frogbot_debug_log("");
            dropclient(p);
            kicked = kicked + 1;
        }
        p = nextp;
    }

    return kicked;
};

float() frogbot_kick_all_for_mode_switch =
{
    local float kicked;

    kicked = frogbot_remove_all_bots();
    bprint(sprintf("Frogbot: removed %g bot(s) for mode switch.\n", kicked));
    return kicked;
};

void() frogbot_command_kick_all =
{
    local float kicked;

    kicked = frogbot_remove_all_bots();
    sprint(self, sprintf("Frogbot: removed %g bot(s).\n", kicked));
};

void(string selector) frogbot_command_kick =
{
    local entity target;
    local float bot_number;

    if (selector == "")
    {
        target = frogbot_find_nth_bot(1);
    }
    else if (strtolower(selector) == "all")
    {
        frogbot_command_kick_all();
        return;
    }
    else if (frogbot_is_uint(selector))
    {
        bot_number = stof(selector);
        if (bot_number < 1)
            bot_number = 1;
        target = frogbot_find_nth_bot(bot_number);
    }
    else
    {
        target = frogbot_find_bot_by_name(selector);
    }

    if (target == world)
    {
        sprint(self, "Frogbot: no matching bot found.\n");
        return;
    }

    dropclient(target);
    sprint(self, sprintf("Frogbot: removed %s.\n", target.netname));
};

entity() frogbot_vote_owner_or_self =
{
    if (clanring_request != world
        && clanring_request.owner != world
        && (clanring_request.owner.style & CLANRING_CONNECTED))
        return clanring_request.owner;

    return self;
};

void() frogbot_vote_add_pass =
{
    local entity saved_self;
    local string arg1;
    local string arg2;

    saved_self = self;
    self = frogbot_vote_owner_or_self();

    arg1 = "";
    arg2 = "";
    if (frogbot_vote_add_count != 1 || frogbot_vote_add_has_custom_skill)
    {
        arg1 = sprintf("%g", frogbot_vote_add_count);
        if (frogbot_vote_add_has_custom_skill)
            arg2 = sprintf("%g", frogbot_vote_add_skill);
    }

    frogbot_command_add(arg1, arg2, frogbot_vote_add_color);
    self = saved_self;
};

void() frogbot_vote_kick_pass =
{
    local entity saved_self;
    local string selector;

    saved_self = self;
    self = frogbot_vote_owner_or_self();

    selector = "";
    if (frogbot_vote_kick_mode == 1)
        selector = "all";
    else if (frogbot_vote_kick_mode == 2)
        selector = sprintf("%g", frogbot_vote_kick_index);

    frogbot_command_kick(selector);
    self = saved_self;
};

void(string arg1, string arg2) frogbot_request_add =
{
    local float count;
    local float skill_level;
    local float has_custom_skill;
    local float requested_color;
    local float c;
    local string details;
    local string color_desc;
    local string effective_arg1;
    local string effective_arg2;

    if (!frogbot_mode_allows_botadd())
        return;

    // Extract color keyword from either arg before further parsing
    requested_color = 0;
    effective_arg1 = arg1;
    effective_arg2 = arg2;

    if (arg1 != "")
    {
        c = frogbot_parse_color_arg(arg1);
        if (c > 0)
        {
            requested_color = c;
            effective_arg1 = arg2;
            effective_arg2 = "";
        }
    }
    if (requested_color == 0 && arg2 != "")
    {
        c = frogbot_parse_color_arg(arg2);
        if (c > 0)
        {
            requested_color = c;
            effective_arg2 = "";
        }
    }

    if (self.style & CLANRING_ADMINISTRATOR)
    {
        frogbot_command_add(effective_arg1, effective_arg2, requested_color);
        return;
    }

    // Non-admin vote path: only allow numeric count/skill (plus color keywords)
    count = 1;
    skill_level = cvar("frogbot_skill");
    has_custom_skill = FALSE;

    if (effective_arg1 != "")
    {
        if (!frogbot_is_uint(effective_arg1))
        {
            sprint(self, "Frogbot: non-admin botadd supports count/skill/color only.\n");
            return;
        }

        count = stof(effective_arg1);
        if (effective_arg2 != "")
        {
            if (!frogbot_is_uint(effective_arg2))
            {
                sprint(self, "Frogbot: non-admin botadd supports count/skill/color only.\n");
                return;
            }
            skill_level = stof(effective_arg2);
            has_custom_skill = TRUE;
        }
    }

    count = bound(1, count, 16);
    skill_level = bound(0, skill_level, 20);
    frogbot_vote_add_count = count;
    frogbot_vote_add_skill = skill_level;
    frogbot_vote_add_has_custom_skill = has_custom_skill;
    frogbot_vote_add_color = requested_color;

    color_desc = "";
    if (requested_color > 0)
    {
        if (requested_color == COLOR_RED)
            color_desc = " red";
        else if (requested_color == COLOR_BLUE)
            color_desc = " blue";
        else
            color_desc = sprintf(" color %g", requested_color);
    }

    if (has_custom_skill)
        details = sprintf("%g bot(s) at skill %g%s", count, skill_level, color_desc);
    else
        details = sprintf("%g bot(s)%s", count, color_desc);

    if (vote_init("add ", details, frogbot_vote_add_pass, "frogbot_add"))
        vote_yes();
};

void(string selector) frogbot_request_kick =
{
    local string details;

    if (self.style & CLANRING_ADMINISTRATOR)
    {
        frogbot_command_kick(selector);
        return;
    }

    frogbot_vote_kick_mode = 0;
    frogbot_vote_kick_index = 1;

    if (selector != "")
    {
        if (strtolower(selector) == "all")
        {
            frogbot_vote_kick_mode = 1;
        }
        else if (frogbot_is_uint(selector))
        {
            frogbot_vote_kick_mode = 2;
            frogbot_vote_kick_index = stof(selector);
            if (frogbot_vote_kick_index < 1)
                frogbot_vote_kick_index = 1;
        }
        else
        {
            sprint(self, "Frogbot: non-admin botkick supports index/all only.\n");
            return;
        }
    }

    if (frogbot_vote_kick_mode == 1)
        details = "all bots";
    else if (frogbot_vote_kick_mode == 2)
        details = sprintf("bot #%g", frogbot_vote_kick_index);
    else
        details = "one bot";

    if (vote_init("remove ", details, frogbot_vote_kick_pass, "frogbot_kick"))
        vote_yes();
};

void() frogbot_request_kick_all =
{
    if (self.style & CLANRING_ADMINISTRATOR)
    {
        frogbot_command_kick_all();
        return;
    }

    frogbot_vote_kick_mode = 1;
    frogbot_vote_kick_index = 0;
    if (vote_init("remove ", "all bots", frogbot_vote_kick_pass, "frogbot_kickall"))
        vote_yes();
};

void(string arg1) frogbot_command_routes =
{
    local string sub;

    sub = strtolower(arg1);
    if (sub == "")
    {
        if (self.style & CLANRING_ADMINISTRATOR)
        {
            frogbot_load_routes(mapname, TRUE, self);
            return;
        }

        frogbot_print_status(self);
        return;
    }

    if (sub == "status")
    {
        frogbot_print_status(self);
        return;
    }

    if (sub == "where")
    {
        frogbot_print_route_search(self, mapname);
        return;
    }

    if (!frogbot_require_admin())
        return;

    if (sub == "reload")
    {
        frogbot_load_routes(mapname, TRUE, self);
        return;
    }

    if (!frogbot_valid_map_token(sub))
    {
        sprint(self, "Frogbot: invalid map token for route load.\n");
        return;
    }

    frogbot_load_routes(sub, TRUE, self);
};

void() frogbot_command_ready =
{
    local entity p, oself;
    local float count;

    if (!(clanring_playmode & CLANRING_MATCH_MODE))
    {
        sprint(self, "Not in match mode\n");
        return;
    }

    count = 0;
    oself = self;
    p = find(world, classname, "player");
    while (p)
    {
        if (p.fb_is_bot_client && !(p.style & CLANRING_READY))
        {
            self = p;
            match_ready();
            count = count + 1;
        }
        p = find(p, classname, "player");
    }
    self = oself;

    if (count)
        sprint(self, sprintf("%g bot(s) readied up\n", count));
    else
        sprint(self, "All bots are already ready\n");
};

void() frogbot_print_help =
{
    sprint(self, "Frogbot commands:\n");
    sprint(self, " botadd [count] [name|skill] [red|blue|cN] - add bot(s)\n");
    sprint(self, " botkick [name|index|all]    - remove bot(s), vote for non-admin\n");
    sprint(self, " botroutes [status|reload|where|map] - route file status/load\n");
    sprint(self, " botver                       - print frogbot build tag\n");
    sprint(self, " bots                         - bot + route status\n");
    sprint(self, " ready                        - ready up all unready bots\n");
};

void(string arg0, string arg1, string arg2, string arg3) frogbot_handle_client_cmd =
{
    local string cmd;
    local string a1;
    local string a2;

    if (strtolower(arg0) == "frogbot")
    {
        cmd = strtolower(arg1);
        a1 = arg2;
        a2 = arg3;
    }
    else
    {
        cmd = strtolower(arg0);
        a1 = arg1;
        a2 = arg2;
    }

    if (cmd == "" || cmd == "help")
    {
        frogbot_print_help();
        return;
    }

    if (cmd == "bots" || cmd == "status")
    {
        frogbot_print_status(self);
        return;
    }

    if (cmd == "botver" || cmd == "version")
    {
        sprint(self, sprintf("Frogbot build: %s purge_next_map=%g\n", FROGBOT_BUILD_TAG, cvar("frogbot_purge_next_map")));
        return;
    }

    if (cmd == "botroutes" || cmd == "routes")
    {
        frogbot_command_routes(a1);
        return;
    }

    if (cmd == "botadd" || cmd == "add")
    {
        frogbot_request_add(a1, a2);
        return;
    }

    if (cmd == "botkickall" || cmd == "kickall")
    {
        frogbot_request_kick_all();
        return;
    }

    if (cmd == "botkick" || cmd == "kick")
    {
        frogbot_request_kick(a1);
        return;
    }

    if (cmd == "ready")
    {
        frogbot_command_ready();
        return;
    }

    sprint(self, "Unknown Frogbot command. Type 'cmd frogbot help'.\n");
};

void() frogbot_delayed_route_load =
{
    frogbot_load_routes(mapname, TRUE, world);
    remove(self);
};

void() frogbot_rebootstrap_surviving_bots =
{
    local entity p;
    local entity evt;
    local float reboot_count;

    reboot_count = 0;
    p = nextent(world);
    while (p != world)
    {
        if (frogbot_is_bot_client(p) && p.fb_bot_bootstrap)
        {
            p.fb_bot_bootstrap = FALSE;
            p.style = p.style - (p.style & CLANRING_CONNECTED);
            frogbot_apply_skill_level(p, cvar("frogbot_skill"));

            evt = spawn();
            evt.classname = "frogbot_spawn_event";
            evt.owner = p;
            evt.think = frogbot_post_spawn_think;
            evt.nextthink = time + 0.2;
            evt.count = 0;
            evt.noise1 = "";

            reboot_count = reboot_count + 1;
        }
        p = nextent(p);
    }

    if (reboot_count > 0)
        bprint(sprintf("Frogbot: re-bootstrapping %g surviving bot(s) for new map.\n", reboot_count));
};

void() frogbot_init_world =
{
    local float kicked_on_init;
    local float purge_latched;
    local float mode_prev;
    local float mode_prev_set;
    local float mode_now;

    purge_latched = cvar("frogbot_purge_next_map");
    mode_prev = cvar("frogbot_last_mode");
    mode_prev_set = cvar("frogbot_last_mode_set");
    frogbot_next_teammsg_global_time = 0;

    registercvar("frogbot_autoload_routes", "1");
    registercvar("frogbot_debug", "0");
    registercvar("frogbot_debug_trace", "0");
    registercvar("frogbot_route_dir", "bots/maps");
    registercvar("frogbot_purge_next_map", "0");
    registercvar("frogbot_last_mode", "-1");
    registercvar("frogbot_last_mode_set", "0");
    registercvar("frogbot_combat", "1");
    registercvar("frogbot_combat_range", "1100");
    registercvar("frogbot_combat_scan_interval", "0.2");
    registercvar("frogbot_visibility_scan_360", "1");
    registercvar("frogbot_visibility_front_min_dot", "0.2");
    registercvar("frogbot_visibility_multi", "1");
    registercvar("frogbot_visibility_multi_entity", "1");
    registercvar("frogbot_visibility_back_penalty", "180");
    registercvar("frogbot_combat_strafe", "1");
    registercvar("frogbot_combat_escape", "1");
    registercvar("frogbot_team_comms", "1");
    registercvar("frogbot_team_comms_cooldown", "8");
    registercvar("frogbot_team_comms_lost_delay", "10");
    registercvar("frogbot_powerup_awareness", "1");
    registercvar("frogbot_powerup_memory", "2.5");
    registercvar("frogbot_powerup_quad_threat", "1.6");
    registercvar("frogbot_powerup_pent_threat", "2.4");
    registercvar("frogbot_powerup_self_quad_relief", "0.6");
    registercvar("frogbot_powerup_self_pent_relief", "0.3");
    registercvar("frogbot_powerup_comms", "1");
    registercvar("frogbot_powerup_comms_cooldown", "12");
    registercvar("frogbot_powerup_target_penalty", "350");
    registercvar("frogbot_combat_escape_enemy_dist", "650");
    registercvar("frogbot_combat_escape_max_dist", "900");
    registercvar("frogbot_combat_escape_ratio", "1.25");
    registercvar("frogbot_combat_escape_min_strength", "130");
    registercvar("frogbot_combat_escape_hold", "1.25");
    registercvar("frogbot_combat_escape_cooldown", "0.85");
    registercvar("frogbot_combat_escape_jump", "1");
    registercvar("frogbot_missile_dodge", "1");
    registercvar("frogbot_combat_lead", "0.55");
    registercvar("frogbot_projectile_min_dist", "180");
    registercvar("frogbot_splash_safety", "1");
    registercvar("frogbot_splash_safety_margin", "0");
    registercvar("frogbot_splash_trace_dist", "112");
    registercvar("frogbot_splash_use_ktx_formula", "1");
    registercvar("frogbot_ff_dist", "420");
    registercvar("frogbot_ff_cone", "0.95");
    registercvar("frogbot_goal_bias", "1.1");
    registercvar("frogbot_camp_logic", "1");
    registercvar("frogbot_camp_chance", "0.3");
    registercvar("frogbot_camp_retry", "4");
    registercvar("frogbot_camp_hold_min", "3");
    registercvar("frogbot_camp_hold_max", "8");
    registercvar("frogbot_camp_enemy_dist", "520");
    registercvar("frogbot_camp_route_bias", "1.1");
    registercvar("frogbot_camp_goal_bias", "2.2");
    registercvar("frogbot_zone_system", "1");
    registercvar("frogbot_zone_stickiness", "0.45");
    registercvar("frogbot_zone_progress_bias", "0.8");
    registercvar("frogbot_zone_detour_penalty", "0.6");
    registercvar("frogbot_zone_next_bias", "0.55");
    registercvar("frogbot_zone_validate", "1");
    registercvar("frogbot_zone_validate_fail_ratio", "0.45");
    registercvar("frogbot_path_hint_bias", "0.65");
    registercvar("frogbot_virtual_goals", "1");
    registercvar("frogbot_virtual_goal_bias", "1.25");
    registercvar("frogbot_zone_virtual_goals", "1");
    registercvar("frogbot_zone_virtual_bias", "0.32");
    registercvar("frogbot_zone_virtual_available_bias", "0.35");
    registercvar("frogbot_goal_wait_max", "20");
    registercvar("frogbot_item_desire_refresh", "0.35");
    registercvar("frogbot_item_desire_scale", "0.06");
    registercvar("frogbot_item_desire_small_scale", "0.35");
    registercvar("frogbot_avoid_hazards", "1");
    registercvar("frogbot_hazard_penalty", "2.4");
    registercvar("frogbot_hazard_rebind_time", "1.1");
    registercvar("frogbot_hazard_escape", "1");
    registercvar("frogbot_hazard_escape_dist", "512");
    registercvar("frogbot_blocked_avoid", "1");
    registercvar("frogbot_blocked_trace_dist", "54");
    registercvar("frogbot_water_vertical_bias", "36");
    registercvar("frogbot_route_potential_bias", "0.7");
    registercvar("frogbot_route_relax_passes", "0");
    registercvar("frogbot_zone_relax_passes", "0");
    registercvar("frogbot_advanced_recovery", "1");
    registercvar("frogbot_route_rj_cost", "0.6");
    registercvar("frogbot_dynamic_backfill", "1");
    registercvar("frogbot_dynamic_source_refresh", "1");
    registercvar("frogbot_dynamic_source_match_dist", "128");
    registercvar("frogbot_dynamic_seed_live_fallback", "1");
    registercvar("frogbot_dynamic_seed_origin_eps", "16");
    registercvar("frogbot_dynamic_force_fill", "1");
    registercvar("frogbot_enable_rj", "1");
    registercvar("frogbot_rj_min_hp_armor", "95");
    registercvar("frogbot_rj_speed_min", "200");
    registercvar("frogbot_soft_reach_dist", "0");
    registercvar("frogbot_allow_vertical_paths", "0");
    registercvar("frogbot_desync_rebind_dist", "900");
    registercvar("frogbot_desync_tp_grace", "0.8");
    registercvar("frogbot_transition_reanchor_dist", "0");
    registercvar("frogbot_transition_reanchor_warp_mult", "4");
    registercvar("frogbot_transition_reanchor_target_dist", "900");
    registercvar("frogbot_transition_mismatch_dist", "320");
    registercvar("frogbot_transition_warp_dist", "320");
    registercvar("frogbot_transition_context_dist", "224");
    registercvar("frogbot_transition_snap_dist", "192");
    registercvar("frogbot_recover_snap_dist", "96");
    registercvar("frogbot_post_tp_source_match_dist", "96");
    registercvar("frogbot_post_tp_bind_dist", "192");
    registercvar("frogbot_transition_stuck_rebind", "1");
    registercvar("frogbot_hard_stuck_dist", "0");
    registercvar("frogbot_hard_stuck_delta", "0");
    registercvar("frogbot_force_rebind_dist", "0");
    registercvar("frogbot_force_rebind_min_dist", "0");
    registercvar("frogbot_force_rebind_delta", "0");
    registercvar("frogbot_marker_block_time", "2");
    registercvar("frogbot_marker_block_scale", "1");
    registercvar("frogbot_marker_block_max", "6");
    registercvar("frogbot_marker_force_rebind_hits", "2");
    registercvar("frogbot_skill", "10");
    registercvar("frogbot_aim_error", "1");
    registercvar("frogbot_loc_reports", "1");
    registercvar("frogbot_loc_report_interval", "20");
    frogbot_load_locations();
    frogbot_ctf_init_world();

    if (purge_latched > 0)
        cvar_set("frogbot_purge_next_map", "1");
    if (mode_prev_set > 0)
    {
        cvar_set("frogbot_last_mode_set", "1");
        cvar_set("frogbot_last_mode", ftos(mode_prev));
    }

    print(sprintf("Frogbot build active: %s\n", FROGBOT_BUILD_TAG));

    if (cvar("frogbot_purge_next_map") > 0)
    {
        kicked_on_init = frogbot_remove_all_bots();
        bprint(sprintf("Frogbot: startup purge removed %g bot(s).\n", kicked_on_init));
        cvar_set("frogbot_purge_next_map", "0");
    }

    mode_now = options_get_mode();
    if (frogbot_debug_enabled())
        print(sprintf("Frogbot debug: startup mode prev_set=%g prev=%g now=%g purge=%g\n",
                      mode_prev_set, mode_prev, mode_now, cvar("frogbot_purge_next_map")));
    if (mode_prev_set > 0 && mode_prev != mode_now)
    {
        kicked_on_init = frogbot_remove_all_bots();
        bprint(sprintf("Frogbot: mode-change startup purge removed %g bot(s) (prev=%g now=%g).\n",
                       kicked_on_init, mode_prev, mode_now));
    }
    cvar_set("frogbot_last_mode_set", "1");
    cvar_set("frogbot_last_mode", ftos(mode_now));

    frogbot_preserve_dynamic_sources();
    frogbot_clear_routes();

    // Re-bootstrap any bots that survived the map change.
    // Their fb_bot_bootstrap flag is still TRUE from the previous map,
    // so we reset it and create new spawn events to re-run ClientConnect
    // and PutClientInServer on the new map.
    frogbot_rebootstrap_surviving_bots();

    if (cvar("frogbot_autoload_routes") > 0)
        utils_make_scheduled_event(frogbot_delayed_route_load, 1.5);
};
