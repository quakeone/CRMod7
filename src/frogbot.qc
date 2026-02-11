/*
    frogbot.qc

    Minimal Frogbot integration layer:
    - spawn/remove dummy bot clients
    - load KTX-style map routing .bot files
    - expose admin commands for bot and route management
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

float frogbot_routes_loaded;
float frogbot_route_load_errors;
float frogbot_marker_count;
float frogbot_path_link_count;
float frogbot_map_death_height;
float frogbot_route_potential_ready;
float frogbot_route_relax_iterations;
float frogbot_route_goal_count;
string frogbot_route_source;
entity frogbot_markers[300];

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
void(entity bot) frogbot_reset_runtime_state;
float() W_BestWeapon;
void() W_SetCurrentAmmo;
void() SUB_Null;
float(entity marker) frogbot_marker_hazard_level;
float(entity marker) frogbot_is_marker_entity;
entity(entity bot) frogbot_find_nearest_marker;
entity(entity bot) frogbot_find_nearest_visible_marker;
entity(entity bot) frogbot_find_nearest_route_marker;
entity(entity bot) frogbot_find_nearest_visible_route_marker;

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

    print(sprintf("Frogbot debug: %s\n", msg));
    if (cvar("frogbot_debug") >= 2)
        bprint(sprintf("Frogbot debug: %s\n", msg));
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
            frogbot_debug_log(sprintf("route probe hit source=%s", path));
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
    source.takedamage = DAMAGE_NO;
    source.origin = ent.origin;
    source.mins = ent.mins;
    source.maxs = ent.maxs;
    setorigin(source, source.origin);
    setsize(source, source.mins, source.maxs);

    if (cvar("frogbot_debug") >= 3)
    {
        frogbot_debug_log(sprintf("route dynamic source preserve class=%s org='%s'",
                                  source_classname, vtos(source.origin)));
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
        frogbot_debug_log(sprintf("route dynamic source count=%g", preserved_count));
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
                created_marker.fb_dynsource = ent;
                if (cvar("frogbot_debug") >= 3)
                {
                    frogbot_debug_log(sprintf("route dynamic seed marker=%g class=%s org='%s'",
                                              created + 1, dynamic_classname, vtos(org)));
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
                created_marker.fb_dynsource = ent;
                fallback_created = fallback_created + 1;
                if (cvar("frogbot_debug") >= 3)
                {
                    frogbot_debug_log(sprintf("route dynamic seed marker=%g class=%s org='%s' fallback=1",
                                              created + 1, dynamic_classname, vtos(org)));
                }
                created = created + 1;
            }

            ent = nextent_saved;
        }
    }

    if (fallback_created > 0 && cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log(sprintf("route dynamic fallback seeded=%g", fallback_created));
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
                created_marker.fb_dynsource = ent;
                backfill_created = backfill_created + 1;
                if (cvar("frogbot_debug") >= 3)
                {
                    frogbot_debug_log(sprintf("route dynamic seed marker=%g class=%s org='%s' backfill=1",
                                              created + 1, dynamic_classname, vtos(org)));
                }
                created = created + 1;
            }

            ent = nextent_saved;
        }
    }

    if (backfill_created > 0 && cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log(sprintf("route dynamic backfill seeded=%g", backfill_created));
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
                created_marker.fb_dynsource = ent;
                live_extra_created = live_extra_created + 1;
                if (cvar("frogbot_debug") >= 3)
                {
                    frogbot_debug_log(sprintf("route dynamic seed marker=%g class=%s org='%s' live=1",
                                              created + 1, dynamic_classname, vtos(org)));
                }
                created = created + 1;
            }

            ent = nextent_saved;
        }
    }

    if (live_extra_created > 0 && cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log(sprintf("route dynamic live fallback seeded=%g", live_extra_created));
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
                created_marker.fb_dynsource = force_source;
            force_created = force_created + 1;
            created = created + 1;
        }
    }

    if (force_created > 0 && cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log(sprintf("route dynamic force seeded=%g", force_created));
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
        frogbot_debug_log(sprintf("route post-teleport ent=%g marker=%g dist=%g mode=%s snap=%g",
                                  num_for_edict(bot),
                                  marker.fb_marker_index,
                                  marker_dist,
                                  bind_mode,
                                  snap_bind));
        if (frogbot_debug_trace_enabled())
        {
            frogbot_debug_log(sprintf("route post-teleport src ent=%g trigger=%s dest=%s",
                                      num_for_edict(bot),
                                      trigger_ent != world ? trigger_ent.classname : "",
                                      destination_ent != world ? destination_ent.classname : ""));
            frogbot_debug_log(sprintf("route post-teleport srcmatch ent=%g marker=%g matched=%g",
                                      num_for_edict(bot),
                                      marker.fb_marker_index,
                                      source_marker != world));
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
        frogbot_debug_log(sprintf("route potential goals=%g pass=%g unresolved=%g",
                                  frogbot_route_goal_count, frogbot_route_relax_iterations, unresolved));
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
        frogbot_debug_log(sprintf("route avoid ent=%g reason=blocked trace=%g side=%g",
                                  num_for_edict(bot), trace_dist, side_push));
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
        frogbot_debug_log(sprintf("route escape ent=%g marker=%g dist=%g",
                                  num_for_edict(bot),
                                  escape_marker.fb_marker_index,
                                  bot.fb_last_target_distance));
    }

    return TRUE;
};

void(entity bot) frogbot_stop_movement =
{
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
    bot.fb_target_path_hint = 0;
    bot.fb_target_rj_delay = 0;
    bot.fb_rj_pending = 0;
    bot.fb_rj_fire_time = 0;
    bot.fb_rj_pitch = 0;
    bot.fb_rj_yaw = 0;
};

void(entity bot) frogbot_reset_runtime_state =
{
    frogbot_clear_runtime_targets(bot);
    bot.fb_next_route_log_time = time;
    bot.fb_next_move_log_time = time;
    bot.fb_next_enemy_scan_time = time;
    bot.fb_last_enemy_seen_time = 0;
    bot.fb_next_combat_log_time = time;
    bot.fb_strafe_dir = 1;
    bot.fb_next_strafe_swap_time = time;
    bot.fb_next_jump_time = time;
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
    if (source == world)
        return FALSE;
    if (source.solid != SOLID_TRIGGER)
        return FALSE;
    if (source.model == "" || source.model == string_null)
        return FALSE;
    return TRUE;
};

float(entity source) frogbot_dynamic_source_respawn_eta =
{
    if (source == world)
        return 999999;
    if (frogbot_dynamic_source_available(source))
        return 0;
    if (source.nextthink > time && source.nextthink < time + 9999)
        return source.nextthink - time;
    return 999999;
};

float(entity bot, string dynamic_classname) frogbot_dynamic_class_desire =
{
    if (bot == world || dynamic_classname == "")
        return 0;

    if (mode_is_arena())
        return 0;

    if (dynamic_classname == "item_armorInv")
    {
        if (bot.armorvalue < 120) return 2.8;
        if (bot.armorvalue < 170) return 1.8;
        return 0.35;
    }

    if (dynamic_classname == "item_armor2")
    {
        if (bot.armorvalue < 90) return 2.0;
        if (bot.armorvalue < 130) return 1.0;
        return 0.2;
    }

    if (dynamic_classname == "item_armor1")
    {
        if (bot.armorvalue < 70) return 1.3;
        if (bot.armorvalue < 110) return 0.6;
        return 0.1;
    }

    if (dynamic_classname == "item_health")
    {
        if (bot.health < 50) return 2.2;
        if (bot.health < 90) return 1.35;
        if (bot.health < 125) return 0.55;
        return 0.12;
    }

    if (dynamic_classname == "item_artifact_super_damage" ||
        dynamic_classname == "item_artifact_invulnerability" ||
        dynamic_classname == "item_artifact_invisibility")
    {
        return 3.2;
    }

    if (dynamic_classname == "weapon_rocketlauncher")
    {
        if (!(bot.items & IT_ROCKET_LAUNCHER)) return 2.7;
        if (bot.ammo_rockets < 10) return 1.2;
        return 0.35;
    }

    if (dynamic_classname == "weapon_lightning")
    {
        if (!(bot.items & IT_LIGHTNING)) return 2.35;
        if (bot.ammo_cells < 18) return 1.0;
        return 0.3;
    }

    if (dynamic_classname == "weapon_grenadelauncher")
    {
        if (!(bot.items & IT_GRENADE_LAUNCHER)) return 1.6;
        return 0.25;
    }

    if (dynamic_classname == "weapon_supernailgun")
    {
        if (!(bot.items & IT_SUPER_NAILGUN)) return 1.45;
        return 0.22;
    }

    if (dynamic_classname == "weapon_nailgun")
    {
        if (!(bot.items & IT_NAILGUN)) return 1.1;
        return 0.16;
    }

    if (dynamic_classname == "weapon_supershotgun")
    {
        if (!(bot.items & IT_SUPER_SHOTGUN)) return 1.15;
        return 0.14;
    }

    if (dynamic_classname == "item_rockets")
    {
        if (bot.ammo_rockets < 20) return 1.8;
        if (bot.ammo_rockets < 45) return 0.9;
        return 0.08;
    }

    if (dynamic_classname == "item_cells")
    {
        if (bot.ammo_cells < 20) return 1.3;
        if (bot.ammo_cells < 50) return 0.75;
        return 0.08;
    }

    if (dynamic_classname == "item_spikes")
    {
        if (bot.ammo_nails < 70) return 0.9;
        if (bot.ammo_nails < 140) return 0.5;
        return 0.05;
    }

    if (dynamic_classname == "item_shells")
    {
        if (bot.ammo_shells < 35) return 0.7;
        if (bot.ammo_shells < 70) return 0.4;
        return 0.05;
    }

    if (dynamic_classname == "item_backpack")
        return 0.95;

    return 0;
};

float(entity bot, entity marker) frogbot_virtual_goal_bonus =
{
    local entity source;
    local string dynamic_classname;
    local float base_desire;
    local float eta;
    local float wait_max;
    local float bias;

    if (bot == world || !frogbot_is_marker_entity(marker))
        return 0;
    if (cvar("frogbot_virtual_goals") <= 0)
        return 0;

    source = marker.fb_dynsource;
    if (source == world)
        return 0;

    dynamic_classname = frogbot_dynamic_marker_classname(source);
    if (!frogbot_is_item_goal_class(dynamic_classname))
        return 0;

    base_desire = frogbot_dynamic_class_desire(bot, dynamic_classname);
    if (base_desire <= 0)
        return 0;

    bias = cvar("frogbot_virtual_goal_bias");
    if (bias <= 0)
        bias = 1;

    if (frogbot_dynamic_source_available(source))
        return base_desire * bias;

    wait_max = cvar("frogbot_goal_wait_max");
    if (wait_max <= 0)
        wait_max = 20;

    eta = frogbot_dynamic_source_respawn_eta(source);
    if (eta <= 0.2)
        return base_desire * 0.55 * bias;
    if (eta < wait_max)
        return base_desire * (1 - eta / wait_max) * 0.75 * bias;

    return -base_desire * 0.6;
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

    if ((path_flags & FROGBOT_PATH_ROCKET_JUMP) && !frogbot_can_rj_now(bot))
        cost = cost + 4;

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
        if (!frogbot_can_rj_now(bot))
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

float(entity bot, entity marker, entity next_marker, float path_flags) frogbot_route_score_bonus =
{
    local float bonus;
    local float potential_bias;
    local float current_cost;
    local float next_cost;
    local float delta_cost;

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

    bonus = bonus + frogbot_virtual_goal_bonus(bot, next_marker);
    bonus = bonus - frogbot_route_hazard_cost(bot, marker, next_marker, path_flags);

    potential_bias = cvar("frogbot_route_potential_bias");
    if (potential_bias > 0 && frogbot_route_potential_ready)
    {
        current_cost = marker.fb_route_goal_cost;
        next_cost = next_marker.fb_route_goal_cost;
        if (current_cost < FROGBOT_ROUTE_COST_INF * 0.5 && next_cost < FROGBOT_ROUTE_COST_INF * 0.5)
        {
            delta_cost = current_cost - next_cost;
            bonus = bonus + (delta_cost * potential_bias);
            if (delta_cost < -0.8)
                bonus = bonus + (delta_cost * potential_bias * 0.5);
        }
        else if (next_marker.fb_goal <= 0 && next_cost >= FROGBOT_ROUTE_COST_INF * 0.5)
        {
            bonus = bonus - (2 * potential_bias);
        }
    }

    return bonus;
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
    local float best_any_index;
    local float best_walk_index;
    local float best_any_flags;
    local float best_walk_flags;

    best_any_marker = world;
    best_walk_marker = world;
    best_any_score = -999999;
    best_walk_score = -999999;
    best_any_index = -1;
    best_walk_index = -1;
    best_any_flags = 0;
    best_walk_flags = 0;

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

            route_bonus = frogbot_route_score_bonus(bot, marker, next_marker, path_flags);
            score = score + route_bonus;
            if (cvar("frogbot_debug") >= 4 && route_bonus)
            {
                frogbot_debug_log(sprintf("route eval ent=%g from=%g to=%g path=%g flags=%g bonus=%g",
                                          num_for_edict(bot),
                                          marker.fb_marker_index,
                                          next_marker.fb_marker_index,
                                          i,
                                          path_flags,
                                          route_bonus));
            }

            if (score > best_any_score)
            {
                best_any_score = score;
                best_any_marker = next_marker;
                best_any_index = i;
                best_any_flags = path_flags;
            }

            if (frogbot_path_is_walkable(bot, marker, next_marker, path_flags) && score > best_walk_score)
            {
                best_walk_score = score;
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
        return best_walk_marker;
    }

    if (best_any_marker != world)
    {
        bot.fb_target_path_index = best_any_index;
        bot.fb_target_path_flags = best_any_flags;
        bot.fb_target_path_hint = frogbot_get_path_hint(marker, best_any_index);
        bot.fb_target_rj_delay = frogbot_get_rj_delay(marker, best_any_index);
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
        frogbot_debug_log(sprintf("route reanchor ent=%g marker=%g adist=%g cur=%g target=%g warped=%g",
                                  num_for_edict(bot),
                                  anchor.fb_marker_index,
                                  anchor_dist,
                                  current_dist,
                                  target_dist,
                                  warped));
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
        frogbot_debug_log(sprintf("route bind ent=%g reason=%s marker=none",
                                  num_for_edict(bot), reason));
        return;
    }

    if (nearest_dist <= 0)
        nearest_dist = vlen(nearest.origin - bot.origin);
    dist = nearest_dist;
    frogbot_debug_log(sprintf("route bind ent=%g reason=%s marker=%g dist=%g mode=%s snap=%g",
                              num_for_edict(bot), reason, nearest.fb_marker_index, dist, bind_mode, snap_bind));
    if (frogbot_debug_trace_enabled())
    {
        frogbot_debug_log(sprintf("route bind trace ent=%g cur=%g tgt=%g failed=%g",
                                  num_for_edict(bot),
                                  bot.fb_current_marker != world ? bot.fb_current_marker.fb_marker_index : 0,
                                  bot.fb_target_marker != world ? bot.fb_target_marker.fb_marker_index : 0,
                                  (bot.fb_failed_until > time)));
        frogbot_debug_log(sprintf("route bind trace2 ent=%g failed_from=%g failed_to=%g preserve=%g",
                                  num_for_edict(bot),
                                  bot.fb_failed_from_marker != world ? bot.fb_failed_from_marker.fb_marker_index : 0,
                                  bot.fb_failed_to_marker != world ? bot.fb_failed_to_marker.fb_marker_index : 0,
                                  preserve_failed));
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

float(entity bot, entity target) frogbot_target_visible =
{
    local vector start;
    local vector goal;

    if (!frogbot_is_enemy_client(bot, target))
        return FALSE;

    start = bot.origin;
    start_z = start_z + bot.view_ofs_z;
    goal = target.origin;
    goal_z = goal_z + target.view_ofs_z * 0.75;
    traceline(start, goal, TRUE, bot);
    if (trace_fraction >= 1)
        return TRUE;
    if (trace_ent == target)
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

    lead_factor = cvar("frogbot_combat_lead");
    if (projectile_speed > 1 && lead_factor > 0)
    {
        lead_time = enemy_dist / projectile_speed;
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
    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
        range_limit = range_limit * 1.15;
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

    range_limit = frogbot_mode_combat_range(cvar("frogbot_combat_range"));
    enemy_total = 0;
    enemy_in_range = 0;
    enemy_los = 0;
    enemy_keep_valid = 0;

    keep_target = bot.fb_enemy_target;
    if (frogbot_is_enemy_client(bot, keep_target))
    {
        enemy_keep_valid = 1;
        dist = vlen(keep_target.origin - bot.origin);
        if (dist <= range_limit * 1.75)
        {
            if (frogbot_target_visible(bot, keep_target))
            {
                bot.fb_last_enemy_seen_time = time;
                return keep_target;
            }

            if (bot.fb_last_enemy_seen_time + FROGBOT_COMBAT_TRACK_TIMEOUT > time)
                return keep_target;
        }
    }

    scan_interval = cvar("frogbot_combat_scan_interval");
    if (scan_interval < FROGBOT_COMBAT_MIN_SCAN_INTERVAL)
        scan_interval = FROGBOT_COMBAT_MIN_SCAN_INTERVAL;
    if (bot.fb_next_enemy_scan_time > time)
    {
        if (frogbot_is_enemy_client(bot, keep_target))
            return keep_target;
        if (frogbot_debug_trace_enabled() && bot.fb_next_route_log_time <= time)
        {
            bot.fb_next_route_log_time = time + 0.75;
            frogbot_debug_log(sprintf("combat scan ent=%g reason=scan-cooldown keep=%g",
                                      num_for_edict(bot), enemy_keep_valid));
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
                has_los = frogbot_target_visible(bot, p);
                if (has_los)
                    enemy_los = enemy_los + 1;
                score = (range_limit * 2) - dist;
                if (p == keep_target)
                    score = score + 200;
                if (has_los)
                    score = score + 800;
                else
                    score = score - 400;

                if (score > best_score)
                {
                    best = p;
                    best_score = score;
                }
            }
        }
        p = nextent(p);
    }

    bot.fb_enemy_target = best;
    if (best != world && frogbot_target_visible(bot, best))
        bot.fb_last_enemy_seen_time = time;
    else if (frogbot_debug_trace_enabled() && bot.fb_next_route_log_time <= time)
    {
        bot.fb_next_route_log_time = time + 0.75;
        frogbot_debug_log(sprintf("combat scan ent=%g reason=no-target total=%g inrange=%g los=%g",
                                  num_for_edict(bot), enemy_total, enemy_in_range, enemy_los));
    }

    return best;
};

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
    local float ctf_mode;
    local float projectile_safe_min_dist;
    local float ff_dist;
    local float ff_cone;
    local float weapon_before;
    local float blocked_by_ff;
    local float blocked_by_self;
    local string fire_reason;

    combat_range = frogbot_mode_combat_range(cvar("frogbot_combat_range"));
    arena_mode = mode_is_arena();
    ctf_mode = (clanring_playmode & CLANRING_CAPTURE_THE_FLAG);
    weapon_before = bot.weapon;
    blocked_by_ff = 0;
    blocked_by_self = 0;
    fire_reason = "hold:no-los";
    fire_min_dot = 0;
    weapon_max_range = combat_range;
    fire_dot = 0;

    aim_delta = target.origin - bot.origin;
    aim_delta_z = aim_delta_z + target.view_ofs_z * 0.75;
    aim = vectoangles(aim_delta);
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

    // Strafe only when actively dueling. Strafing blind through map geometry hurts route progress.
    if (cvar("frogbot_combat_strafe") > 0 && has_los && enemy_dist <= combat_range)
    {
        if (bot.fb_next_strafe_swap_time <= time)
        {
            bot.fb_strafe_dir = (random() < 0.5) ? -1 : 1;
            bot.fb_next_strafe_swap_time = time + 0.5 + random();
        }

        strafe_scale = bound(40, move_speed * 0.45, 140);
        bot.movement_y = bot.movement_y + (bot.fb_strafe_dir * strafe_scale);
    }

    if (enemy_dist < 140)
        bot.movement_x = bot.movement_x - 120;
    else if (enemy_dist > combat_range * 0.8)
        bot.movement_x = bot.movement_x + 60;

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

        prefer_close_non_projectile_dist = 340;
        if (ctf_mode)
            prefer_close_non_projectile_dist = 280;
        else if (arena_mode)
            prefer_close_non_projectile_dist = 300;

        shotgun_far_switch_dist = 750;
        if (ctf_mode)
            shotgun_far_switch_dist = 620;
        else if (arena_mode)
            shotgun_far_switch_dist = 680;

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
            weapon_max_range = ctf_mode ? 460 : 520;
        else if (bot.weapon == IT_SUPER_SHOTGUN)
            weapon_max_range = ctf_mode ? 380 : 430;
        else if (bot.weapon == IT_NAILGUN)
            weapon_max_range = 1000;
        else if (bot.weapon == IT_SUPER_NAILGUN)
            weapon_max_range = arena_mode ? 1000 : 1150;
        else if (bot.weapon == IT_LIGHTNING)
            weapon_max_range = ctf_mode ? 950 : 850;
        else if (bot.weapon == IT_GRENADE_LAUNCHER)
            weapon_max_range = arena_mode ? 900 : 800;
        else if (bot.weapon == IT_ROCKET_LAUNCHER)
            weapon_max_range = arena_mode ? 1000 : 1200;
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
            // Don't explode ourselves at point-blank.
            if (enemy_dist > 180 && enemy_dist <= weapon_max_range && fire_dot >= fire_min_dot)
            {
                fire_now = TRUE;
                fire_reason = "fire:proj";
            }
            else if (enemy_dist <= 180)
                fire_reason = "hold:proj-blank";
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

        if (fire_now && is_projectile_like)
        {
            projectile_safe_min_dist = cvar("frogbot_projectile_min_dist");
            if (projectile_safe_min_dist <= 0)
                projectile_safe_min_dist = 180;

            if (enemy_dist < projectile_safe_min_dist && !(bot.items & (IT_INVULNERABILITY | IT_QUAD)))
            {
                fire_now = FALSE;
                blocked_by_self = 1;
                fire_reason = "hold:proj-self";
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

    bot.button0 = fire_now;

    if (cvar("frogbot_debug") >= 2 && bot.fb_next_combat_log_time <= time)
    {
        bot.fb_next_combat_log_time = time + 0.75;
        frogbot_debug_log(sprintf("combat ent=%g target=%s dist=%g los=%g fire=%g wpn=%g dot=%g",
                                  num_for_edict(bot), target.netname, enemy_dist, has_los, fire_now, bot.weapon,
                                  fire_dot));
        if (frogbot_debug_trace_enabled())
        {
            frogbot_debug_log(sprintf("combat trace ent=%g reason=%s oldwpn=%g newwpn=%g",
                                      num_for_edict(bot), fire_reason, weapon_before, bot.weapon));
            frogbot_debug_log(sprintf("combat trace2 ent=%g min=%g max=%g self=%g ff=%g",
                                      num_for_edict(bot), fire_min_dot, weapon_max_range, blocked_by_self, blocked_by_ff));
            frogbot_debug_log(sprintf("combat move ent=%g mx=%g my=%g ms=%g",
                                      num_for_edict(bot), bot.movement_x, bot.movement_y, move_speed));
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
    local float water_jump;

    if (!frogbot_is_bot_client(self))
        return;

    if (!(self.style & CLANRING_CONNECTED) || self.classname != "player")
    {
        frogbot_stop_movement(self);
        if (self.fb_next_route_log_time <= time && cvar("frogbot_debug") >= 2)
        {
            self.fb_next_route_log_time = time + 2;
            frogbot_debug_log(sprintf("route idle ent=%g reason=not-ready class=%s style=%g",
                                      num_for_edict(self), self.classname, self.style));
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
            frogbot_debug_log(sprintf("route idle ent=%g reason=arena-wait state=%g fight=%g paused=%g",
                                      num_for_edict(self),
                                      boss != world ? boss.state : -1,
                                      boss != world ? boss.timetofight : 0,
                                      (clanring_state & CLANRING_MATCH_PAUSED) ? 1 : 0));
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
            frogbot_debug_log(sprintf("route idle ent=%g reason=dead deadflag=%g health=%g",
                                      num_for_edict(self), self.deadflag, self.health));
        }
        return;
    }

    if (!frogbot_routes_loaded || frogbot_marker_count <= 0)
    {
        frogbot_stop_movement(self);
        if (self.fb_next_route_log_time <= time)
        {
            self.fb_next_route_log_time = time + 5;
            frogbot_debug_log(sprintf("route idle ent=%g reason=no-routes", num_for_edict(self)));
        }
        return;
    }

    if (self.origin_z < frogbot_map_death_height)
    {
        frogbot_debug_log(sprintf("route recover ent=%g reason=deathheight z=%g limit=%g",
                                  num_for_edict(self), self.origin_z, frogbot_map_death_height));
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
            frogbot_debug_log(sprintf("route transition-warp ent=%g step=%g from=%s to=%s",
                                      num_for_edict(self),
                                      vlen(self.origin - self.oldorigin),
                                      vtos(self.oldorigin),
                                      vtos(self.origin)));
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
                frogbot_debug_log(sprintf("route rebind ent=%g reason=hazard watertype=%g marker=%g",
                                          num_for_edict(self),
                                          self.watertype,
                                          self.fb_current_marker != world ? self.fb_current_marker.fb_marker_index : 0));
            }
            frogbot_bind_nearest_marker(self, "hazard");
            frogbot_stop_movement(self);
            return;
        }
    }

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
                    frogbot_debug_log(sprintf("route retry ent=%g reason=no-path-clear marker=%g failed_to=%g",
                                              num_for_edict(self),
                                              self.fb_current_marker != world ? self.fb_current_marker.fb_marker_index : 0,
                                              self.fb_failed_to_marker != world ? self.fb_failed_to_marker.fb_marker_index : 0));
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
                    frogbot_debug_log(sprintf("route rebind ent=%g reason=transition-no-path marker=%g",
                                              num_for_edict(self),
                                              self.fb_current_marker != world ? self.fb_current_marker.fb_marker_index : 0));
                }
                frogbot_bind_nearest_marker(self, "transition");
                return;
            }
            if (self.fb_stuck_count >= 2)
                frogbot_bind_nearest_marker(self, "no-path");
            if (self.fb_next_route_log_time <= time)
            {
                self.fb_next_route_log_time = time + 5;
                frogbot_debug_log(sprintf("route idle ent=%g reason=no-path marker=%g",
                                          num_for_edict(self), self.fb_current_marker.fb_marker_index));
                if (frogbot_debug_trace_enabled())
                {
                    frogbot_debug_log(sprintf("route idle trace ent=%g failed_from=%g failed_to=%g",
                                              num_for_edict(self),
                                              self.fb_failed_from_marker != world ? self.fb_failed_from_marker.fb_marker_index : 0,
                                              self.fb_failed_to_marker != world ? self.fb_failed_to_marker.fb_marker_index : 0));
                }
            }
            return;
        }

        if (cvar("frogbot_debug") >= 3)
        {
            frogbot_debug_log(sprintf("route choose ent=%g from=%g to=%g path=%g flags=%g hint=%g rjdelay=%g",
                                      num_for_edict(self), self.fb_current_marker.fb_marker_index,
                                      self.fb_target_marker.fb_marker_index, self.fb_target_path_index, self.fb_target_path_flags,
                                      self.fb_target_path_hint, self.fb_target_rj_delay));
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
                frogbot_debug_log(sprintf("route rebind ent=%g reason=transition marker=%g dist=%g prev=%g",
                                          num_for_edict(self),
                                          self.fb_current_marker != world ? self.fb_current_marker.fb_marker_index : 0,
                                          dist, self.fb_last_target_distance));
            }
            frogbot_bind_nearest_marker(self, "transition");
            frogbot_stop_movement(self);
            return;
        }

        if (cvar("frogbot_debug") >= 2)
        {
            frogbot_debug_log(sprintf("route rebind ent=%g reason=desync marker=%g dist=%g prev=%g",
                                      num_for_edict(self),
                                      self.fb_current_marker != world ? self.fb_current_marker.fb_marker_index : 0,
                                      dist, self.fb_last_target_distance));
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
            frogbot_debug_log(sprintf("route reach ent=%g marker=%g",
                                      num_for_edict(self), self.fb_current_marker.fb_marker_index));
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
                frogbot_debug_log(sprintf("route soft-reach ent=%g marker=%g dist=%g",
                                          num_for_edict(self),
                                          self.fb_current_marker.fb_marker_index,
                                          dist));
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
                frogbot_debug_log(sprintf("route rebind ent=%g reason=transition-stuck marker=%g dist=%g",
                                          num_for_edict(self),
                                          self.fb_current_marker != world ? self.fb_current_marker.fb_marker_index : 0,
                                          dist));
            }
            frogbot_bind_nearest_marker(self, "transition");
        }
        else if (force_rebind || self.fb_stuck_count >= 2)
            frogbot_bind_nearest_marker(self, "stuck");
        if (cvar("frogbot_debug") >= 2)
        {
            frogbot_debug_log(sprintf("route stuck ent=%g marker=%g count=%g dist=%g best=%g force=%g",
                                      num_for_edict(self), stuck_marker_snapshot, stuck_count_snapshot,
                                      dist, best_dist_snapshot, force_rebind));
            if (frogbot_debug_trace_enabled())
            {
                frogbot_debug_log(sprintf("route stuck trace ent=%g from=%g to=%g fail_t=%g",
                                          num_for_edict(self),
                                          self.fb_failed_from_marker != world ? self.fb_failed_from_marker.fb_marker_index : 0,
                                          self.fb_failed_to_marker != world ? self.fb_failed_to_marker.fb_marker_index : 0,
                                          self.fb_failed_until));
                frogbot_debug_log(sprintf("route stuck trace2 ent=%g flags=%g hint=%g rj=%g",
                                          num_for_edict(self),
                                          self.fb_target_path_flags,
                                          self.fb_target_path_hint,
                                          self.fb_target_rj_delay));
                if (frogbot_is_marker_entity(self.fb_failed_from_marker))
                {
                    frogbot_debug_log(sprintf("route block ent=%g marker=%g hits=%g hold=%g",
                                              num_for_edict(self),
                                              self.fb_failed_from_marker.fb_marker_index,
                                              self.fb_failed_from_marker.fb_blocked_hits,
                                              max(0, self.fb_failed_from_marker.fb_blocked_until - time)));
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

    combat_enabled = (cvar("frogbot_combat") > 0);
    combat_target = world;
    if (combat_enabled)
        combat_target = frogbot_find_enemy_target(self);
    else
    {
        self.fb_enemy_target = world;
        if (cvar("frogbot_debug") >= 2 && self.fb_next_combat_log_time <= time)
        {
            self.fb_next_combat_log_time = time + 2;
            frogbot_debug_log(sprintf("combat idle ent=%g reason=disabled cvar=%g",
                                      num_for_edict(self), cvar("frogbot_combat")));
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
            frogbot_debug_log(sprintf("combat idle ent=%g reason=no-target range=%g",
                                      num_for_edict(self), cvar("frogbot_combat_range")));
        }
    }

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
                frogbot_debug_log(sprintf("route rj release ent=%g pitch=%g yaw=%g",
                                          num_for_edict(self), self.fb_rj_pitch, self.fb_rj_yaw));
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
                    frogbot_debug_log(sprintf("route rj fire ent=%g marker=%g path=%g pitch=%g yaw=%g delay=%g",
                                              num_for_edict(self),
                                              self.fb_current_marker != world ? self.fb_current_marker.fb_marker_index : 0,
                                              self.fb_target_path_index, rj_pitch, rj_yaw, rj_delay));
                }
            }
            else
            {
                self.fb_rj_pending = 1;
                self.fb_rj_fire_time = time + bound(0, rj_delay, 20) * frametime;
                if (cvar("frogbot_debug") >= 3)
                {
                    frogbot_debug_log(sprintf("route rj arm ent=%g marker=%g path=%g pitch=%g yaw=%g delay=%g fire_t=%g",
                                              num_for_edict(self),
                                              self.fb_current_marker != world ? self.fb_current_marker.fb_marker_index : 0,
                                              self.fb_target_path_index, rj_pitch, rj_yaw, rj_delay, self.fb_rj_fire_time));
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
    }
    self.button2 = want_jump;

    if (cvar("frogbot_debug") >= 3 && self.fb_next_move_log_time <= time)
    {
        self.fb_next_move_log_time = time + 1;
        frogbot_debug_log(sprintf("route move ent=%g cur=%g target=%g dist=%g speed=%g jump=%g",
                                  num_for_edict(self),
                                  self.fb_current_marker != world ? self.fb_current_marker.fb_marker_index : 0,
                                  self.fb_target_marker != world ? self.fb_target_marker.fb_marker_index : 0,
                                  dist,
                                  move_speed,
                                  want_jump));
        frogbot_debug_log(sprintf("route movepos ent=%g org=%s torg=%s",
                                  num_for_edict(self),
                                  vtos(self.origin),
                                  vtos(self.fb_target_marker.origin)));
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
        frogbot_debug_log(sprintf("route compat create=%g maxref=%g markerbase=%g",
                                  create_count, max_marker_ref, marker_id_base));
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
                marker.fb_dynsource = forcepad_anchor.fb_dynsource;
            forcepad_created = forcepad_created + 1;
            forcepad_next_id = forcepad_next_id + 1;
        }
        created_dynamic = created_dynamic + forcepad_created;
    }
    if (cvar("frogbot_debug") >= 2)
    {
        frogbot_debug_log(sprintf("route dynamic seeded=%g wanted=%g", created_dynamic, marker_id_base));
        if (forcepad_created > 0)
            frogbot_debug_log(sprintf("route dynamic forcepad=%g", forcepad_created));
    }
    if (created_dynamic < marker_id_base)
    {
        parse_errors = parse_errors + (marker_id_base - created_dynamic);
        if (verbose)
            frogbot_notify(notify_target, sprintf("Frogbot warning: seeded %g/%g dynamic markers; some links may be unavailable.\n",
                                                  created_dynamic, marker_id_base));
        if (cvar("frogbot_debug") >= 2)
        {
            frogbot_debug_log(sprintf("route dynamic suspects dm=%g team1=%g team2=%g team1dm=%g team2dm=%g start=%g start2=%g coop=%g",
                                      frogbot_count_classname_raw("info_player_deathmatch"),
                                      frogbot_count_classname_raw("info_player_team1"),
                                      frogbot_count_classname_raw("info_player_team2"),
                                      frogbot_count_classname_raw("info_player_team1_deathmatch"),
                                      frogbot_count_classname_raw("info_player_team2_deathmatch"),
                                      frogbot_count_classname_raw("info_player_start"),
                                      frogbot_count_classname_raw("info_player_start2"),
                                      frogbot_count_classname_raw("info_player_coop")));
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
            zone_number = stof(argv(2));
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
        frogbot_rebuild_route_potential_cache();
    else
        frogbot_route_potential_ready = FALSE;

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

    route_state = frogbot_routes_loaded ? "loaded" : "missing";
    source = frogbot_route_source;
    route_dir = frogbot_get_route_dir();
    if (source == "")
        source = "(none)";

    frogbot_notify(target, sprintf("Frogbot status: bots=%g routes=%s markers=%g links=%g issues=%g source=%s dir=%s potential=%g goals=%g passes=%g\n",
                                   frogbot_count_bots(),
                                   route_state,
                                   frogbot_marker_count,
                                   frogbot_path_link_count,
                                   frogbot_route_load_errors,
                                   source,
                                   route_dir,
                                   frogbot_route_potential_ready,
                                   frogbot_route_goal_count,
                                   frogbot_route_relax_iterations));
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
    if (!teamplay)
    {
        if (self.team <= 1)
        {
            self.team = 13;
            clientcommand(self, "color 13 13");
        }
        return;
    }

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
            frogbot_debug_log(sprintf("bootstrap ent=%g name=%s style=%g classname=%s",
                                      bot_entnum, evt.noise1, self.style, self.classname));
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

        frogbot_debug_log(sprintf("spawn timeout ent=%g name=%s style=%g classname=%s",
                                  bot_entnum, evt.noise1, self.style, self.classname));
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
            teamplay_ready_player();
    }

    frogbot_debug_log(sprintf("spawn ready ent=%g netname=%s botname=%s style=%g class=%s cmap=%g",
                              bot_entnum, self.netname, self.fb_bot_name, self.style, self.classname, self.colormap));

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

entity(string bot_name) frogbot_spawn_one =
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
    bot.colormap = bot_entnum;
    frogbot_reset_runtime_state(bot);

    unique_name = frogbot_make_unique_name(bot_name);
    frogbot_set_bot_name(bot, unique_name);

    frogbot_debug_log(sprintf("spawn request ent=%g requested=%s unique=%s style=%g cmap=%g botname=%s",
                              bot_entnum, bot_name, unique_name, bot.style, bot.colormap, bot.fb_bot_name));

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

void(string arg1, string arg2) frogbot_command_add =
{
    local float count;
    local float i;
    local float added;
    local string base_name;
    local string bot_name;

    count = 1;
    base_name = "";

    if (arg1 != "")
    {
        if (frogbot_is_uint(arg1))
        {
            count = stof(arg1);
            base_name = arg2;
        }
        else
        {
            base_name = arg1;
        }
    }

    if (count < 1)
        count = 1;
    if (count > 16)
        count = 16;

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
        if (count == 1 && !frogbot_is_uint(arg1))
            bot_name = base_name;
        else
            bot_name = sprintf("%s%g", base_name, i);

        if (frogbot_spawn_one(bot_name) == world)
            break;

        added = added + 1;
        i = i + 1;
    }

    frogbot_debug_log(sprintf("add command requested=%g added=%g base=%s", count, added, base_name));
    sprint(self, sprintf("Frogbot: added %g bot(s).\n", added));
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
            frogbot_debug_log(sprintf("kick ent=%g netname=%s", num_for_edict(p), p.netname));
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

void() frogbot_print_help =
{
    sprint(self, "Frogbot commands:\n");
    sprint(self, " botadd [count] [nameprefix] - add bot(s)\n");
    sprint(self, " botkick [name|index|all]    - remove bot(s)\n");
    sprint(self, " botroutes [status|reload|where|map] - route file status/load\n");
    sprint(self, " botver                       - print frogbot build tag\n");
    sprint(self, " bots                         - bot + route status\n");
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
        if (!frogbot_require_admin())
            return;
        frogbot_command_add(a1, a2);
        return;
    }

    if (cmd == "botkickall" || cmd == "kickall")
    {
        if (!frogbot_require_admin())
            return;
        frogbot_command_kick_all();
        return;
    }

    if (cmd == "botkick" || cmd == "kick")
    {
        if (!frogbot_require_admin())
            return;
        frogbot_command_kick(a1);
        return;
    }

    sprint(self, "Unknown Frogbot command. Type 'cmd frogbot help'.\n");
};

void() frogbot_delayed_route_load =
{
    frogbot_load_routes(mapname, TRUE, world);
    remove(self);
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
    registercvar("frogbot_combat_strafe", "1");
    registercvar("frogbot_combat_lead", "0.55");
    registercvar("frogbot_projectile_min_dist", "180");
    registercvar("frogbot_ff_dist", "420");
    registercvar("frogbot_ff_cone", "0.95");
    registercvar("frogbot_goal_bias", "1.1");
    registercvar("frogbot_zone_stickiness", "0.45");
    registercvar("frogbot_path_hint_bias", "0.65");
    registercvar("frogbot_virtual_goals", "1");
    registercvar("frogbot_virtual_goal_bias", "1.25");
    registercvar("frogbot_goal_wait_max", "20");
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
    registercvar("frogbot_advanced_recovery", "1");
    registercvar("frogbot_route_rj_cost", "0.6");
    registercvar("frogbot_dynamic_backfill", "1");
    registercvar("frogbot_dynamic_source_refresh", "1");
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

    if (cvar("frogbot_autoload_routes") > 0)
        utils_make_scheduled_event(frogbot_delayed_route_load, 1.5);
};
