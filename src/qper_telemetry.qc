// QPER calibration telemetry: raw measures only, no new scoring terms.
// Exposure uses active time; item touches flush the old state before mutation.
void(entity p) qper_sample =
{
    local float active, dt;
    active = qper_active_secs(p);
    dt = max(0, active - p.qper_telemetry_mark);
    p.qper_telemetry_mark = active;
    if (!p.qper_stint_open || p.health <= 0 || (p.style & CLANRING_OBSERVER) || mode_is_arena()) return;
    if ((clanring_playmode & CLANRING_MATCH_MODE) && !(clanring_state & CLANRING_MATCH_STARTED)) return;
    if (clanring_playmode & CLANRING_PRACTICE_MODE) return;
    if (p.items & IT_ROCKET_LAUNCHER) p.qper_access_rl_secs += dt;
    if (p.items & IT_LIGHTNING) p.qper_access_lg_secs += dt;
    if (((p.items & IT_ROCKET_LAUNCHER) && p.ammo_rockets > 0)
        || ((p.items & IT_LIGHTNING) && p.ammo_cells > 0)) p.qper_armed_secs += dt;
    p.qper_quad_secs += min(dt, max(0, p.super_damage_finished - (time - dt)));
    p.qper_pent_secs += min(dt, max(0, p.invincible_finished - (time - dt)));
    p.qper_ring_secs += min(dt, max(0, p.invisible_finished - (time - dt)));
    if (p.player_flag & ITEM_RUNE1_FLAG) p.qper_resistance_secs += dt;
    if (p.player_flag & ITEM_RUNE2_FLAG) p.qper_strength_secs += dt;
    if (p.player_flag & ITEM_RUNE3_FLAG) p.qper_haste_secs += dt;
    if (p.player_flag & ITEM_RUNE4_FLAG) p.qper_regen_secs += dt;
};

void(entity p) qper_telemetry_reset =
{
    p.qper_team_damage = 0;
    p.qper_kill_pool_full = 0;
    p.qper_kill_pool_awarded = 0;
    p.qper_spawn_exempt = 0;
    p.qper_spawn_lt1 = 0;
    p.qper_spawn_1to2 = 0;
    p.qper_spawn_2to4 = 0;
    p.qper_spawn_ge4 = 0;
    p.qper_spawn_deaths_lt1 = 0;
    p.qper_spawn_deaths_1to2 = 0;
    p.qper_spawn_deaths_2to4 = 0;
    p.qper_spawn_deaths_ge4 = 0;
    p.qper_weapon_donations = 0;
    p.qper_weapon_donations_received = 0;
    p.qper_pack_recoveries = 0;
    p.qper_pack_concessions = 0;
    p.qper_access_rl_secs = 0;
    p.qper_access_lg_secs = 0;
    p.qper_armed_secs = 0;
    p.qper_acquire_world = 0;
    p.qper_acquire_pack = 0;
    p.qper_acquire_donation = 0;
    p.qper_ammo_supplied_shells = 0;
    p.qper_ammo_supplied_nails = 0;
    p.qper_ammo_supplied_rockets = 0;
    p.qper_ammo_supplied_cells = 0;
    p.qper_enemy_axe = 0;
    p.qper_enemy_sg = 0;
    p.qper_enemy_ssg = 0;
    p.qper_enemy_ng = 0;
    p.qper_enemy_sng = 0;
    p.qper_enemy_gl = 0;
    p.qper_enemy_rl = 0;
    p.qper_enemy_lg = 0;
    p.qper_enemy_other = 0;
    p.qper_team_axe = 0;
    p.qper_team_sg = 0;
    p.qper_team_ssg = 0;
    p.qper_team_ng = 0;
    p.qper_team_sng = 0;
    p.qper_team_gl = 0;
    p.qper_team_rl = 0;
    p.qper_team_lg = 0;
    p.qper_team_other = 0;
    p.qper_quad_secs = 0;
    p.qper_quad_damage = 0;
    p.qper_pent_secs = 0;
    p.qper_pent_damage = 0;
    p.qper_ring_secs = 0;
    p.qper_ring_damage = 0;
    p.qper_resistance_secs = 0;
    p.qper_resistance_damage = 0;
    p.qper_strength_secs = 0;
    p.qper_strength_damage = 0;
    p.qper_haste_secs = 0;
    p.qper_haste_damage = 0;
    p.qper_regen_secs = 0;
    p.qper_regen_damage = 0;
    p.qper_telemetry_mark = 0;
};

void(entity from, entity to) qper_telemetry_copy =
{
    to.qper_team_damage = from.qper_team_damage;
    to.qper_kill_pool_full = from.qper_kill_pool_full;
    to.qper_kill_pool_awarded = from.qper_kill_pool_awarded;
    to.qper_spawn_exempt = from.qper_spawn_exempt;
    to.qper_spawn_lt1 = from.qper_spawn_lt1;
    to.qper_spawn_1to2 = from.qper_spawn_1to2;
    to.qper_spawn_2to4 = from.qper_spawn_2to4;
    to.qper_spawn_ge4 = from.qper_spawn_ge4;
    to.qper_spawn_deaths_lt1 = from.qper_spawn_deaths_lt1;
    to.qper_spawn_deaths_1to2 = from.qper_spawn_deaths_1to2;
    to.qper_spawn_deaths_2to4 = from.qper_spawn_deaths_2to4;
    to.qper_spawn_deaths_ge4 = from.qper_spawn_deaths_ge4;
    to.qper_weapon_donations = from.qper_weapon_donations;
    to.qper_weapon_donations_received = from.qper_weapon_donations_received;
    to.qper_pack_recoveries = from.qper_pack_recoveries;
    to.qper_pack_concessions = from.qper_pack_concessions;
    to.qper_access_rl_secs = from.qper_access_rl_secs;
    to.qper_access_lg_secs = from.qper_access_lg_secs;
    to.qper_armed_secs = from.qper_armed_secs;
    to.qper_acquire_world = from.qper_acquire_world;
    to.qper_acquire_pack = from.qper_acquire_pack;
    to.qper_acquire_donation = from.qper_acquire_donation;
    to.qper_ammo_supplied_shells = from.qper_ammo_supplied_shells;
    to.qper_ammo_supplied_nails = from.qper_ammo_supplied_nails;
    to.qper_ammo_supplied_rockets = from.qper_ammo_supplied_rockets;
    to.qper_ammo_supplied_cells = from.qper_ammo_supplied_cells;
    to.qper_enemy_axe = from.qper_enemy_axe;
    to.qper_enemy_sg = from.qper_enemy_sg;
    to.qper_enemy_ssg = from.qper_enemy_ssg;
    to.qper_enemy_ng = from.qper_enemy_ng;
    to.qper_enemy_sng = from.qper_enemy_sng;
    to.qper_enemy_gl = from.qper_enemy_gl;
    to.qper_enemy_rl = from.qper_enemy_rl;
    to.qper_enemy_lg = from.qper_enemy_lg;
    to.qper_enemy_other = from.qper_enemy_other;
    to.qper_team_axe = from.qper_team_axe;
    to.qper_team_sg = from.qper_team_sg;
    to.qper_team_ssg = from.qper_team_ssg;
    to.qper_team_ng = from.qper_team_ng;
    to.qper_team_sng = from.qper_team_sng;
    to.qper_team_gl = from.qper_team_gl;
    to.qper_team_rl = from.qper_team_rl;
    to.qper_team_lg = from.qper_team_lg;
    to.qper_team_other = from.qper_team_other;
    to.qper_quad_secs = from.qper_quad_secs;
    to.qper_quad_damage = from.qper_quad_damage;
    to.qper_pent_secs = from.qper_pent_secs;
    to.qper_pent_damage = from.qper_pent_damage;
    to.qper_ring_secs = from.qper_ring_secs;
    to.qper_ring_damage = from.qper_ring_damage;
    to.qper_resistance_secs = from.qper_resistance_secs;
    to.qper_resistance_damage = from.qper_resistance_damage;
    to.qper_strength_secs = from.qper_strength_secs;
    to.qper_strength_damage = from.qper_strength_damage;
    to.qper_haste_secs = from.qper_haste_secs;
    to.qper_haste_damage = from.qper_haste_damage;
    to.qper_regen_secs = from.qper_regen_secs;
    to.qper_regen_damage = from.qper_regen_damage;
};

void(entity p, float duration) qper_unpause_player =
{
    p.qper_l_time += duration;
    p.qper_spawn_time += duration;
    if (p.qper_poss_since) p.qper_poss_since += duration;
    p.last_returned_flag += duration;
    p.last_fragged_carrier += duration;
    // Pending carrier-defense credit is meaningful even while dead.
    p.last_hurt_carrier += duration;
};

// Only newly acquired RL/LG inventory is an access event.
void(entity p, float weapon, float source) qper_acquire =
{
    if (!(weapon & (IT_ROCKET_LAUNCHER | IT_LIGHTNING)) || (p.items & weapon)) return;
    if (source == 0) p.qper_acquire_world++;
    else if (source == 1) p.qper_acquire_pack++;
    else p.qper_acquire_donation++;
};

void(entity item, entity donor, float voluntary) qper_drop_origin =
{
    item.qper_drop_id = donor.qper_conn_id;
    item.qper_drop_team = donor.team;
    item.qper_drop_voluntary = voluntary;
};

void(entity item, entity recipient, float weapon, float old_items, vector old_ammo, float old_cells) qper_transfer =
{
    local entity donor;
    local float valid, equips;
    // HH head-only leftovers have no weapon/ammo provenance on later touches.
    if (!item.qper_drop_id) return;
    donor = item.owner;
    valid = TRUE;
    if (donor.classname != "player") valid = FALSE;
    if (donor.qper_conn_id != item.qper_drop_id) valid = FALSE;
    equips = (weapon & (IT_ROCKET_LAUNCHER | IT_LIGHTNING)) && !(old_items & weapon);
    if (equips)
    {
        if (item.qper_drop_voluntary) recipient.qper_acquire_donation++;
        else recipient.qper_acquire_pack++;
    }
    // Team identity belongs to the drop, not a potentially recycled owner slot.
    if (!teamplay || !item.qper_drop_team || (valid && (donor == recipient))) return;
    if (recipient.team == item.qper_drop_team)
    {
        if (qper_weapon_control() && equips)
        {
            if (item.qper_drop_voluntary)
            {
                recipient.qper_weapon_donations_received++;
                if (valid) donor.qper_weapon_donations++;
            }
            else recipient.qper_pack_recoveries++;
        }
        if (valid && item.qper_drop_voluntary)
        {
            donor.qper_ammo_supplied_shells += max(0, recipient.ammo_shells - old_ammo_x);
            donor.qper_ammo_supplied_nails += max(0, recipient.ammo_nails - old_ammo_y);
            donor.qper_ammo_supplied_rockets += max(0, recipient.ammo_rockets - old_ammo_z);
            donor.qper_ammo_supplied_cells += max(0, recipient.ammo_cells - old_cells);
        }
    }
    else if (qper_weapon_control() && equips && valid) donor.qper_pack_concessions++;
};

// Classify projectiles before considering the attacker's currently held weapon.
float(entity v, entity inflictor, entity attacker) qper_damage_weapon =
{
    if (inflictor.classname == "missile") return IT_ROCKET_LAUNCHER;
    if (inflictor.classname == "grenade") return IT_GRENADE_LAUNCHER;
    if (inflictor.classname == "spike") return v.deathtype == "supernail" ? IT_SUPER_NAILGUN : IT_NAILGUN;
    if (inflictor.classname == "superspike") return IT_SUPER_NAILGUN;
    if ((inflictor == attacker) && (inflictor.classname == "player")) return attacker.weapon;
    // Discharges pass the water/weapon owner through radius damage.
    if (v.deathtype == "discharge") return IT_LIGHTNING;
    return 0; // hook, telefrag, door and other non-weapon damage
};

void(entity victim, entity inflictor, entity attacker, float amount) qper_applied_damage =
{
    local float weapon, enemy;
    if (victim.classname != "player" || attacker.classname != "player" || victim == attacker || amount <= 0) return;
    if (mode_is_arena() || (clanring_playmode & CLANRING_PRACTICE_MODE)) return;
    weapon = qper_damage_weapon(victim, inflictor, attacker);
    enemy = qper_enemies(victim, attacker);
    if (!enemy) attacker.qper_team_damage += amount;
    if (enemy)
    {
        if (weapon == IT_AXE) attacker.qper_enemy_axe += amount;
        else if (weapon == IT_SHOTGUN) attacker.qper_enemy_sg += amount;
        else if (weapon == IT_SUPER_SHOTGUN) attacker.qper_enemy_ssg += amount;
        else if (weapon == IT_NAILGUN) attacker.qper_enemy_ng += amount;
        else if (weapon == IT_SUPER_NAILGUN) attacker.qper_enemy_sng += amount;
        else if (weapon == IT_GRENADE_LAUNCHER) attacker.qper_enemy_gl += amount;
        else if (weapon == IT_ROCKET_LAUNCHER) attacker.qper_enemy_rl += amount;
        else if (weapon == IT_LIGHTNING) attacker.qper_enemy_lg += amount;
        else attacker.qper_enemy_other += amount;
    }
    if (!enemy)
    {
        if (weapon == IT_AXE) attacker.qper_team_axe += amount;
        else if (weapon == IT_SHOTGUN) attacker.qper_team_sg += amount;
        else if (weapon == IT_SUPER_SHOTGUN) attacker.qper_team_ssg += amount;
        else if (weapon == IT_NAILGUN) attacker.qper_team_ng += amount;
        else if (weapon == IT_SUPER_NAILGUN) attacker.qper_team_sng += amount;
        else if (weapon == IT_GRENADE_LAUNCHER) attacker.qper_team_gl += amount;
        else if (weapon == IT_ROCKET_LAUNCHER) attacker.qper_team_rl += amount;
        else if (weapon == IT_LIGHTNING) attacker.qper_team_lg += amount;
        else attacker.qper_team_other += amount;
    }
    if (!enemy) return;
    if (attacker.super_damage_finished > time) attacker.qper_quad_damage += amount;
    if (attacker.invincible_finished > time) attacker.qper_pent_damage += amount;
    if (attacker.invisible_finished > time) attacker.qper_ring_damage += amount;
    if (attacker.player_flag & ITEM_RUNE1_FLAG) attacker.qper_resistance_damage += amount;
    if (attacker.player_flag & ITEM_RUNE2_FLAG) attacker.qper_strength_damage += amount;
    if (attacker.player_flag & ITEM_RUNE3_FLAG) attacker.qper_haste_damage += amount;
    if (attacker.player_flag & ITEM_RUNE4_FLAG) attacker.qper_regen_damage += amount;
};
