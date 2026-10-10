//
//  Q P E R   v 2   ( P L A Y E R   E F F I C I E N C Y   R A T I N G )
//
//  Individual contribution per active minute, in frag equivalents (FE),
//  scaled so the reference average for comparable matches is 15.
//
//  contribution = effective enemy damage
//               + shared kill credit (fixed pool per kill, split by recent damage)
//               + objective credit (CTF: fixed pool per capture, split by possession)
//               + small resource/support credit
//               - costly mistakes (deaths, self/env deaths, teamkills, team damage,
//                 weapons conceded in dmm1)
//
//  Layers: the core applies everywhere, weapon control only when weapons don't
//  stay (dmm1), objectives only in CTF.  Reference averages are kept per
//  cohort (mode, deathmatch, team size) in stats/qper_ref.txt and updated
//  after every completed match.  The old PER (Q1_PER_Calc_Eff) is kept for
//  side-by-side comparison until the weights are calibrated.
//

#define QPER_VERSION            "qper2-provisional-1"

// core
#define QPER_W_DMG              0.5     // per 100 effective enemy damage
#define QPER_W_KILL             0.6     // base kill pool
#define QPER_FINISHER_SHARE     0.35    // of each kill pool; the rest follows recent damage
#define QPER_LEDGER_HALFLIFE    3       // seconds
#define QPER_KILL_FLAG_BONUS    1.0     // pool multiplier additions
#define QPER_KILL_POWERUP_BONUS 0.5
#define QPER_KILL_WEAPON_BONUS  0.5     // dmm1 RL/LG carriers
#define QPER_SPAWN_RAMP         4       // seconds for a fresh spawn's kill value to reach full
#define QPER_SPAWN_FLOOR        0.4
#define QPER_W_DEATH            0.4
#define QPER_W_SELF_DEATH       0.6     // added to the base death cost
#define QPER_W_TEAMKILL         1.0
#define QPER_W_QUAD_TEAMKILL    1.5     // added to the teamkill cost
#define QPER_W_TEAMDMG          0.15    // per 100 team damage

// weapon control (dmm1)
#define QPER_W_EWEP             0.15    // per 100 damage to RL/LG carriers, on top of QPER_W_DMG
#define QPER_W_WEAPON_LOSS      0.6     // RL/LG pack picked up by an enemy who lacked it
#define QPER_W_WEAPON_PICKUP    0.08

// resources and support
#define QPER_W_QUAD             0.4
#define QPER_W_PENT             0.6
#define QPER_W_RING             0.2
#define QPER_W_RA               0.15
#define QPER_W_YA               0.06
#define QPER_W_MEGA             0.08
#define QPER_W_QUAD_SUPPORT     0.1

// CTF
#define QPER_CAP_POOL           3.0
#define QPER_CAP_ASSIST_SHARE   0.2     // of the pool, when anyone assisted
#define QPER_CAP_STEAL_SHARE    0.25    // of the carrier part
#define QPER_CAP_CAPPER_SHARE   0.25    // of the carrier part; the rest follows carry time
#define QPER_W_STEAL            0.2     // steal whose possession was returned
#define QPER_W_RETURN           0.25
#define QPER_W_DEFENSE          0.3
#define QPER_W_CARRIER_DEFENSE  0.3

// rating
#define QPER_SHRINK_MINS        3       // short stints are blended toward the reference
#define QPER_PROVISIONAL_MINS   5
#define QPER_PRIOR_MINS         30      // weight of the built-in prior in player-minutes
#define QPER_REF_CAP_MINS       4000    // keeps the reference tracking recent play
#define QPER_REF_MIN_MINS       2       // shortest stint that updates the reference
#define QPER_REF_FILE           "stats/qper_ref.txt"
#define QPER_REF_MAX            32

#define QPER_TERMS              19
#define QPER_T_DAMAGE           0
#define QPER_T_EWEP             1
#define QPER_T_KILLS            2
#define QPER_T_CAPTURES         3
#define QPER_T_STEALS           4
#define QPER_T_RETURNS          5
#define QPER_T_DEFENSE          6
#define QPER_T_CARRIER_DEFENSE  7
#define QPER_T_QUAD             8
#define QPER_T_PENT             9
#define QPER_T_RING             10
#define QPER_T_ARMOR            11
#define QPER_T_WEAPONS          12
#define QPER_T_QUAD_SUPPORT     13
#define QPER_T_DEATHS           14
#define QPER_T_SELF_DEATHS      15
#define QPER_T_TEAMKILLS        16
#define QPER_T_TEAMDMG          17
#define QPER_T_WEAPON_LOSS      18

string qper_ref_key[QPER_REF_MAX];
float qper_ref_rate[QPER_REF_MAX];
float qper_ref_mins[QPER_REF_MAX];
float qper_ref_count;
float qper_ref_loaded;
float qper_cost_id, qper_cost_v;    // largest cost found by qper_find_top_terms

// ------------------------------------------------------------
// Mode layers
// ------------------------------------------------------------
float() qper_weapon_control =
{
	return stats_weapon_carrier_kills_enabled();
};

float() qper_is_ctf =
{
	return (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && !(clanring_playmode & CLANRING_PRACTICE_MODE);
};

float() qper_ctf_live =
{
	if (!qper_is_ctf())
		return FALSE;
	if (clanring_playmode & CLANRING_MATCH_MODE)
		return (clanring_state & CLANRING_MATCH_STARTED) ? TRUE : FALSE;
	return (clanring_playmode & CLANRING_NORMAL_MODE) ? TRUE : FALSE;
};

float(entity a, entity b) qper_enemies =
{
	if (a == b)
		return FALSE;
	if (teamplay && (a.team == b.team))
		return FALSE;
	return TRUE;
};

// ------------------------------------------------------------
// Active time: joined minus paused, frozen when participation ends
// ------------------------------------------------------------
float() qper_pause_now =
{
	if (clanring_state & CLANRING_MATCH_PAUSED)
		return qper_pause_total + (time - clanring_match_pause_time);
	return qper_pause_total;
};

float(entity p) qper_stint_secs =
{
	if (!p.qper_stint_open)
		return 0;
	return max(0, (time - p.qper_stint_start) - (qper_pause_now() - p.qper_stint_pause_mark));
};

void(entity p) qper_stint_begin =
{
	p.qper_stint_start = time;
	p.qper_stint_pause_mark = qper_pause_now();
	p.qper_stint_open = TRUE;
};

void(entity p) qper_stint_end =
{
	if (!p.qper_stint_open)
		return;
	p.qper_active_bank = p.qper_active_bank + qper_stint_secs(p);
	p.qper_stint_open = FALSE;
};

float(entity p) qper_active_secs =
{
	// No stint was ever started (e.g. carried over a map change without a stats reset).
	if (!p.qper_stint_open && p.qper_stint_start <= 0 && p.qper_active_bank <= 0 && p.join_time > 0)
		return max(0, time - p.join_time);
	return p.qper_active_bank + qper_stint_secs(p);
};

float(entity p) qper_active_mins =
{
	return qper_active_secs(p) / 60;
};

// ------------------------------------------------------------
// Player lifecycle
// ------------------------------------------------------------
void(entity v) qper_ledger_clear =
{
	v.qper_l_e1 = v.qper_l_e2 = v.qper_l_e3 = v.qper_l_e4 = v.qper_l_e5 = v.qper_l_e6 = world;
	v.qper_l_d1 = v.qper_l_d2 = v.qper_l_d3 = v.qper_l_d4 = v.qper_l_d5 = v.qper_l_d6 = 0;
	v.qper_l_id1 = v.qper_l_id2 = v.qper_l_id3 = v.qper_l_id4 = v.qper_l_id5 = v.qper_l_id6 = 0;
	v.qper_l_time = time;
};

void(entity p) qper_reset_player =
{
	p.qper_kill_credit = 0;
	p.qper_assist_credit = 0;
	p.qper_cap_credit = 0;
	p.qper_steal_credit = 0;
	p.fcassists_return = 0;
	p.fcassists_frag = 0;
	p.qper_poss_id = 0;
	p.qper_poss_hold = 0;
	p.qper_poss_since = 0;
	p.qper_final = 0;
	p.qper_final_valid = FALSE;
	p.qper_active_bank = 0;
	qper_stint_begin(p);
};

void(entity p) qper_on_connect =
{
	qper_conn_seq = qper_conn_seq + 1;
	p.qper_conn_id = qper_conn_seq;
	qper_ledger_clear(p);
};

void(entity p) qper_on_spawn =
{
	p.qper_spawn_time = time;
	qper_ledger_clear(p);
};

// ------------------------------------------------------------
// Recent-damage ledger (per victim life)
//
// Each slot holds damage decayed by a half-life, so an old fight fades out and
// a small follow-up hit only adds its own damage.
// ------------------------------------------------------------
entity(entity v, float i) qper_slot_ent =
{
	switch (i)
	{
		case 0: return v.qper_l_e1;
		case 1: return v.qper_l_e2;
		case 2: return v.qper_l_e3;
		case 3: return v.qper_l_e4;
		case 4: return v.qper_l_e5;
	}
	return v.qper_l_e6;
};

float(entity v, float i) qper_slot_id =
{
	switch (i)
	{
		case 0: return v.qper_l_id1;
		case 1: return v.qper_l_id2;
		case 2: return v.qper_l_id3;
		case 3: return v.qper_l_id4;
		case 4: return v.qper_l_id5;
	}
	return v.qper_l_id6;
};

float(entity v, float i) qper_slot_dmg =
{
	switch (i)
	{
		case 0: return v.qper_l_d1;
		case 1: return v.qper_l_d2;
		case 2: return v.qper_l_d3;
		case 3: return v.qper_l_d4;
		case 4: return v.qper_l_d5;
	}
	return v.qper_l_d6;
};

void(entity v, float i, entity e, float id, float d) qper_slot_set =
{
	switch (i)
	{
		case 0: v.qper_l_e1 = e; v.qper_l_id1 = id; v.qper_l_d1 = d; return;
		case 1: v.qper_l_e2 = e; v.qper_l_id2 = id; v.qper_l_d2 = d; return;
		case 2: v.qper_l_e3 = e; v.qper_l_id3 = id; v.qper_l_d3 = d; return;
		case 3: v.qper_l_e4 = e; v.qper_l_id4 = id; v.qper_l_d4 = d; return;
		case 4: v.qper_l_e5 = e; v.qper_l_id5 = id; v.qper_l_d5 = d; return;
	}
	v.qper_l_e6 = e; v.qper_l_id6 = id; v.qper_l_d6 = d;
};

void(entity v) qper_ledger_decay =
{
	local float k;

	if (time <= v.qper_l_time)
		return;
	k = pow(0.5, (time - v.qper_l_time) / QPER_LEDGER_HALFLIFE);
	v.qper_l_d1 = v.qper_l_d1 * k;
	v.qper_l_d2 = v.qper_l_d2 * k;
	v.qper_l_d3 = v.qper_l_d3 * k;
	v.qper_l_d4 = v.qper_l_d4 * k;
	v.qper_l_d5 = v.qper_l_d5 * k;
	v.qper_l_d6 = v.qper_l_d6 * k;
	v.qper_l_time = time;
};

// A slot still names the same connected enemy who did the damage.
float(entity v, float i) qper_slot_valid =
{
	local entity e;

	e = qper_slot_ent(v, i);
	if (e == world || e.classname != "player")
		return FALSE;
	if (e.qper_conn_id != qper_slot_id(v, i))
		return FALSE;
	if (!qper_enemies(e, v))
		return FALSE;
	return qper_slot_dmg(v, i) > 0;
};

void(entity victim, entity attacker, float amount) qper_ledger_add =
{
	local float i, slot, low;

	if (amount <= 0)
		return;
	if (victim.classname != "player" || attacker.classname != "player")
		return;

	qper_ledger_decay(victim);

	// existing slot for this connection
	for (i = 0; i < 6; i = i + 1)
	{
		if (qper_slot_ent(victim, i) == attacker && qper_slot_id(victim, i) == attacker.qper_conn_id)
		{
			qper_slot_set(victim, i, attacker, attacker.qper_conn_id, qper_slot_dmg(victim, i) + amount);
			return;
		}
	}

	// otherwise replace the slot holding the least recent damage
	slot = 0;
	low = 999999;
	for (i = 0; i < 6; i = i + 1)
	{
		if (!qper_slot_valid(victim, i))
		{
			slot = i;
			break;
		}
		if (qper_slot_dmg(victim, i) < low)
		{
			low = qper_slot_dmg(victim, i);
			slot = i;
		}
	}
	qper_slot_set(victim, slot, attacker, attacker.qper_conn_id, amount);
};

// ------------------------------------------------------------
// Shared kill credit
// ------------------------------------------------------------
float(entity v) qper_kill_pool =
{
	local float m, exempt, age, f;

	m = 1;
	exempt = FALSE;
	if (qper_is_ctf() && v.flag_carrier)
	{
		m = m + QPER_KILL_FLAG_BONUS;
		exempt = TRUE;
	}
	if ((v.super_damage_finished > time) || (v.invincible_finished > time))
	{
		m = m + QPER_KILL_POWERUP_BONUS;
		exempt = TRUE;
	}
	if (qper_weapon_control() && (v.items & (IT_ROCKET_LAUNCHER | IT_LIGHTNING)))
	{
		m = m + QPER_KILL_WEAPON_BONUS;
		exempt = TRUE;
	}

	// Fresh spawns are worth less, ramping up smoothly so delaying a kill gains little.
	f = 1;
	if (!exempt)
	{
		age = time - v.qper_spawn_time;
		if (age < QPER_SPAWN_RAMP)
			f = QPER_SPAWN_FLOOR + (1 - QPER_SPAWN_FLOOR) * max(0, age) / QPER_SPAWN_RAMP;
	}
	return QPER_W_KILL * m * f;
};

void(entity victim, entity killer) qper_credit_kill =
{
	local float pool, total, i, share;
	local entity e;

	if (victim.classname != "player" || killer.classname != "player")
		return;
	if (!qper_enemies(killer, victim))
		return;

	pool = qper_kill_pool(victim);
	qper_ledger_decay(victim);

	total = 0;
	for (i = 0; i < 6; i = i + 1)
	{
		if (qper_slot_valid(victim, i))
			total = total + qper_slot_dmg(victim, i);
	}

	if (total <= 0)
	{
		killer.qper_kill_credit = killer.qper_kill_credit + pool;
		return;
	}

	killer.qper_kill_credit = killer.qper_kill_credit + pool * QPER_FINISHER_SHARE;
	for (i = 0; i < 6; i = i + 1)
	{
		if (!qper_slot_valid(victim, i))
			continue;
		e = qper_slot_ent(victim, i);
		share = pool * (1 - QPER_FINISHER_SHARE) * qper_slot_dmg(victim, i) / total;
		e.qper_kill_credit = e.qper_kill_credit + share;
		if (e != killer)
			e.qper_assist_credit = e.qper_assist_credit + share;
	}
};

// ------------------------------------------------------------
// CTF possessions: from a steal at the enemy base until capture or return,
// across any changes of carrier.
// ------------------------------------------------------------
void(entity flg, entity carrier, float from_base) qper_flag_pickup =
{
	if (from_base || !flg.qper_poss_id)
	{
		qper_poss_seq = qper_poss_seq + 1;
		flg.qper_poss_id = qper_poss_seq;
		flg.qper_poss_live = qper_ctf_live();
		if (from_base)
		{
			flg.qper_poss_stealer = carrier;
			flg.qper_poss_stealer_id = carrier.qper_conn_id;
		}
		else
		{
			flg.qper_poss_stealer = world;
			flg.qper_poss_stealer_id = 0;
		}
	}

	if (carrier.qper_poss_id != flg.qper_poss_id)
	{
		carrier.qper_poss_id = flg.qper_poss_id;
		carrier.qper_poss_hold = 0;
	}
	carrier.qper_poss_since = time;
};

void(entity flg, entity carrier) qper_flag_drop =
{
	if (!flg.qper_poss_id || carrier.qper_poss_id != flg.qper_poss_id)
		return;
	carrier.qper_poss_hold = carrier.qper_poss_hold + max(0, time - carrier.qper_poss_since);
	carrier.qper_poss_since = 0;
};

float(entity flg, entity team_of) qper_flag_stealer_valid =
{
	local entity s;

	s = flg.qper_poss_stealer;
	if (s == world || s.classname != "player")
		return FALSE;
	if (s.qper_conn_id != flg.qper_poss_stealer_id)
		return FALSE;
	return (s.team == team_of.team);
};

// Flag went back to base (or was reset while carried) without a capture.
void(entity flg) qper_flag_reset =
{
	local entity s;

	if (!flg.qper_poss_id)
		return;
	s = flg.qper_poss_stealer;
	if (flg.qper_poss_live && qper_ctf_live() && s != world
		&& s.classname == "player" && s.qper_conn_id == flg.qper_poss_stealer_id)
		s.qper_steal_credit = s.qper_steal_credit + QPER_W_STEAL;
	flg.qper_poss_id = 0;
	flg.qper_poss_stealer = world;
	flg.qper_poss_stealer_id = 0;
};

void(entity carrier) qper_flag_capture =
{
	local entity flg, p;
	local float id, assists, pool, assist_pool, carrier_pool, hold_total, steal_part, capper_part, hold_part;

	flg = find(world, classname, "item_flag_team1");
	if (flg == world || flg.owner != carrier)
		flg = find(world, classname, "item_flag_team2");
	if (flg == world || flg.owner != carrier || !flg.qper_poss_id)
		return;

	id = flg.qper_poss_id;
	if (carrier.qper_poss_id == id)
		carrier.qper_poss_hold = carrier.qper_poss_hold + max(0, time - carrier.qper_poss_since);

	if (!flg.qper_poss_live || !qper_ctf_live())
	{
		flg.qper_poss_id = 0;
		return;
	}

	// Assists and carriers share one fixed pool: more contributors split it, never grow it.
	assists = 0;
	hold_total = 0;
	p = find(world, classname, "player");
	while (p != world)
	{
		if (p.team == carrier.team && !(p.style & CLANRING_OBSERVER))
		{
			if (p.last_returned_flag + TEAM_CAPTURE_RETURN_FLAG_ASSIST_TIMEOUT > time)
				assists = assists + 1;
			if (p.last_fragged_carrier + TEAM_CAPTURE_FRAG_CARRIER_ASSIST_TIMEOUT > time)
				assists = assists + 1;
			if (p.qper_poss_id == id)
				hold_total = hold_total + p.qper_poss_hold;
		}
		p = find(p, classname, "player");
	}

	pool = QPER_CAP_POOL;
	assist_pool = 0;
	if (assists > 0)
		assist_pool = pool * QPER_CAP_ASSIST_SHARE;
	carrier_pool = pool - assist_pool;

	steal_part = carrier_pool * QPER_CAP_STEAL_SHARE;
	capper_part = carrier_pool * QPER_CAP_CAPPER_SHARE;
	hold_part = carrier_pool - steal_part - capper_part;

	if (qper_flag_stealer_valid(flg, carrier))
		flg.qper_poss_stealer.qper_cap_credit = flg.qper_poss_stealer.qper_cap_credit + steal_part;
	else
		capper_part = capper_part + steal_part;
	if (hold_total <= 0)
	{
		capper_part = capper_part + hold_part;
		hold_part = 0;
	}
	carrier.qper_cap_credit = carrier.qper_cap_credit + capper_part;

	p = find(world, classname, "player");
	while (p != world)
	{
		if (p.team == carrier.team && !(p.style & CLANRING_OBSERVER))
		{
			if (hold_part > 0 && p.qper_poss_id == id)
				p.qper_cap_credit = p.qper_cap_credit + hold_part * p.qper_poss_hold / hold_total;
			if (p.last_returned_flag + TEAM_CAPTURE_RETURN_FLAG_ASSIST_TIMEOUT > time)
				p.qper_cap_credit = p.qper_cap_credit + assist_pool / assists;
			if (p.last_fragged_carrier + TEAM_CAPTURE_FRAG_CARRIER_ASSIST_TIMEOUT > time)
				p.qper_cap_credit = p.qper_cap_credit + assist_pool / assists;
		}
		if (p.qper_poss_id == id)
			p.qper_poss_id = 0;
		p = find(p, classname, "player");
	}

	flg.qper_poss_id = 0;
	flg.qper_poss_stealer = world;
	flg.qper_poss_stealer_id = 0;
};

// ------------------------------------------------------------
// Contribution terms (FE, signed).  The rating, its explanation, the JSON
// export and the reference update all read these.
// ------------------------------------------------------------
float(entity p, float id) qper_term =
{
	local float ctf, wc;

	ctf = qper_is_ctf();
	wc = qper_weapon_control();

	switch (id)
	{
		case QPER_T_DAMAGE:          return QPER_W_DMG * p.dmg_given / 100;
		case QPER_T_EWEP:            return wc ? QPER_W_EWEP * p.ewep / 100 : 0;
		case QPER_T_KILLS:           return p.qper_kill_credit;
		case QPER_T_CAPTURES:        return ctf ? p.qper_cap_credit : 0;
		case QPER_T_STEALS:          return ctf ? p.qper_steal_credit : 0;
		case QPER_T_RETURNS:         return ctf ? QPER_W_RETURN * p.freturns : 0;
		case QPER_T_DEFENSE:         return ctf ? QPER_W_DEFENSE * p.fdefenses : 0;
		case QPER_T_CARRIER_DEFENSE: return ctf ? QPER_W_CARRIER_DEFENSE * p.fcdefenses : 0;
		case QPER_T_QUAD:            return QPER_W_QUAD * p.clanring_qdwep_z;
		case QPER_T_PENT:            return QPER_W_PENT * p.clanring_ptwep_z;
		case QPER_T_RING:            return QPER_W_RING * p.stats_item_ring;
		case QPER_T_ARMOR:           return QPER_W_RA * p.stats_item_redarmor + QPER_W_YA * p.stats_item_yellowarmor + QPER_W_MEGA * p.stats_item_mega;
		case QPER_T_WEAPONS:         return wc ? QPER_W_WEAPON_PICKUP * (p.stats_item_rl + p.stats_item_lg) : 0;
		case QPER_T_QUAD_SUPPORT:    return QPER_W_QUAD_SUPPORT * p.stats_quad_secure;
		// mangle_z: killed by an enemy; mangle_x: every self/environment death (lava included)
		case QPER_T_DEATHS:          return -QPER_W_DEATH * p.mangle_z;
		case QPER_T_SELF_DEATHS:     return -(QPER_W_DEATH + QPER_W_SELF_DEATH) * p.mangle_x;
		case QPER_T_TEAMKILLS:       return -(QPER_W_TEAMKILL * p.mangle_y + QPER_W_QUAD_TEAMKILL * p.stats_teamkill_quad);
		case QPER_T_TEAMDMG:         return -QPER_W_TEAMDMG * p.clanring_badstats_z / 100;
		case QPER_T_WEAPON_LOSS:     return wc ? -QPER_W_WEAPON_LOSS * p.clanring_badstats_x : 0;
	}
	return 0;
};

float(entity p) qper_contribution =
{
	local float i, total;

	total = 0;
	for (i = 0; i < QPER_TERMS; i = i + 1)
		total = total + qper_term(p, i);
	return total;
};

string(entity p, float id) qper_term_label =
{
	switch (id)
	{
		case QPER_T_DAMAGE:          return sprintf("damage (%g)", p.dmg_given);
		case QPER_T_EWEP:            return sprintf("damage to RL/LG carriers (%g)", p.ewep);
		case QPER_T_KILLS:           return sprintf("kill credit (%g kills, %g from assists)", p.true_kills, floor(p.qper_assist_credit * 10 + 0.5) / 10);
		case QPER_T_CAPTURES:        return sprintf("capture credit (%g caps)", p.fcaptures);
		case QPER_T_STEALS:          return sprintf("flag steals (%g pickups)", p.fpickups);
		case QPER_T_RETURNS:         return sprintf("returns (%g)", p.freturns);
		case QPER_T_DEFENSE:         return sprintf("base defenses (%g)", p.fdefenses);
		case QPER_T_CARRIER_DEFENSE: return sprintf("carrier defenses (%g)", p.fcdefenses);
		case QPER_T_QUAD:            return sprintf("quads (%g)", p.clanring_qdwep_z);
		case QPER_T_PENT:            return sprintf("pents (%g)", p.clanring_ptwep_z);
		case QPER_T_RING:            return sprintf("rings (%g)", p.stats_item_ring);
		case QPER_T_ARMOR:           return sprintf("armor/mega (%g RA, %g YA, %g MH)", p.stats_item_redarmor, p.stats_item_yellowarmor, p.stats_item_mega);
		case QPER_T_WEAPONS:         return sprintf("RL/LG pickups (%g)", p.stats_item_rl + p.stats_item_lg);
		case QPER_T_QUAD_SUPPORT:    return sprintf("quad support (%g)", p.stats_quad_secure);
		case QPER_T_DEATHS:          return sprintf("deaths (%g)", p.mangle_z);
		case QPER_T_SELF_DEATHS:     return sprintf("self/env deaths (%g)", p.mangle_x);
		case QPER_T_TEAMKILLS:       return sprintf("teamkills (%g)", p.mangle_y);
		case QPER_T_TEAMDMG:         return sprintf("team damage (%g)", p.clanring_badstats_z);
		case QPER_T_WEAPON_LOSS:     return sprintf("weapons given away (%g)", p.clanring_badstats_x);
	}
	return "";
};

string(float id) qper_term_key =
{
	switch (id)
	{
		case QPER_T_DAMAGE:          return "damage";
		case QPER_T_EWEP:            return "carrier_damage";
		case QPER_T_KILLS:           return "kill_credit";
		case QPER_T_CAPTURES:        return "capture_credit";
		case QPER_T_STEALS:          return "steal_credit";
		case QPER_T_RETURNS:         return "returns";
		case QPER_T_DEFENSE:         return "defenses";
		case QPER_T_CARRIER_DEFENSE: return "carrier_defenses";
		case QPER_T_QUAD:            return "quads";
		case QPER_T_PENT:            return "pents";
		case QPER_T_RING:            return "rings";
		case QPER_T_ARMOR:           return "armor_mega";
		case QPER_T_WEAPONS:         return "weapon_pickups";
		case QPER_T_QUAD_SUPPORT:    return "quad_support";
		case QPER_T_DEATHS:          return "deaths";
		case QPER_T_SELF_DEATHS:     return "self_deaths";
		case QPER_T_TEAMKILLS:       return "teamkills";
		case QPER_T_TEAMDMG:         return "team_damage";
		case QPER_T_WEAPON_LOSS:     return "weapon_loss";
	}
	return "";
};

// ------------------------------------------------------------
// Reference averages per cohort
// ------------------------------------------------------------
string() qper_cohort_key =
{
	local string mode;
	local float size;

	if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
		mode = "ctf";
	else if (clanring_playmode & CLANRING_HH_MODE)
		mode = "hh";
	else if (teamplay)
		mode = "tdm";
	else
		mode = "ffa";

	size = 0;
	if (clanring_playmode & CLANRING_MATCH_MODE)
		size = stats_matchtype;
	return sprintf("%s_dmm%g_%g", mode, deathmatch, size);
};

// Rough contribution/min of an average player, used until real matches outweigh it.
float() qper_prior_rate =
{
	local float wc;

	wc = qper_weapon_control();
	if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
		return wc ? 1.6 : 1.8;
	if (teamplay)
		return wc ? 1.3 : 1.8;
	return 1.5;
};

void() qper_ref_load =
{
	local filestream f;
	local string line;

	qper_ref_loaded = TRUE;
	qper_ref_count = 0;

	f = fopen(QPER_REF_FILE, FILE_READ);
	if (f < 0)
		f = fopen(strcat("data/", QPER_REF_FILE), FILE_READ);
	if (f < 0)
		return;

	while ((line = fgets(f)) && (qper_ref_count < QPER_REF_MAX))
	{
		if (tokenize(line) < 3)
			continue;
		if (stof(argv(1)) <= 0)
			continue;
		qper_ref_key[qper_ref_count] = strzone(argv(0));
		qper_ref_rate[qper_ref_count] = stof(argv(1));
		qper_ref_mins[qper_ref_count] = stof(argv(2));
		qper_ref_count = qper_ref_count + 1;
	}
	fclose(f);
};

void() qper_ref_save =
{
	local filestream f;
	local float i;

	f = fopen(QPER_REF_FILE, FILE_WRITE);
	if (f < 0)
	{
		dprint("QPER: could not write ", QPER_REF_FILE, "\n");
		return;
	}
	for (i = 0; i < qper_ref_count; i = i + 1)
		fputs(f, sprintf("%s %.4f %.1f\n", qper_ref_key[i], qper_ref_rate[i], qper_ref_mins[i]));
	fclose(f);
};

float(string key) qper_ref_index =
{
	local float i;

	if (!qper_ref_loaded)
		qper_ref_load();
	for (i = 0; i < qper_ref_count; i = i + 1)
	{
		if (qper_ref_key[i] == key)
			return i;
	}
	return -1;
};

// Average contribution/min for this cohort, blended with the prior.
float() qper_reference_rate =
{
	local float i, prior, rate;

	prior = qper_prior_rate();
	i = qper_ref_index(qper_cohort_key());
	if (i < 0)
		return prior;
	rate = (qper_ref_rate[i] * qper_ref_mins[i] + prior * QPER_PRIOR_MINS) / (qper_ref_mins[i] + QPER_PRIOR_MINS);
	return max(0.2, rate);
};

float() qper_reference_mins =
{
	local float i;

	i = qper_ref_index(qper_cohort_key());
	if (i < 0)
		return 0;
	return qper_ref_mins[i];
};

void(float add_contrib, float add_mins) qper_ref_update =
{
	local string key;
	local float i;

	if (add_mins <= 0)
		return;
	key = qper_cohort_key();
	i = qper_ref_index(key);
	if (i < 0)
	{
		if (qper_ref_count >= QPER_REF_MAX)
			return;
		i = qper_ref_count;
		qper_ref_count = qper_ref_count + 1;
		qper_ref_key[i] = strzone(key);
		qper_ref_rate[i] = add_contrib / add_mins;
		qper_ref_mins[i] = min(add_mins, QPER_REF_CAP_MINS);
	}
	else
	{
		qper_ref_rate[i] = (qper_ref_rate[i] * qper_ref_mins[i] + add_contrib) / (qper_ref_mins[i] + add_mins);
		qper_ref_mins[i] = min(qper_ref_mins[i] + add_mins, QPER_REF_CAP_MINS);
	}
	qper_ref_save();
};

// ------------------------------------------------------------
// Rating
// ------------------------------------------------------------
// Weight of the player's own rate; the rest is the reference (worth 15).
float(entity p) qper_own_weight =
{
	local float mins;

	mins = qper_active_mins(p);
	return mins / (mins + QPER_SHRINK_MINS);
};

// QPER points contributed by a raw FE amount for this player.
float(entity p, float fe) qper_points =
{
	local float mins;

	mins = qper_active_mins(p);
	if (mins <= 0)
		return 0;
	return 15 * qper_own_weight(p) * (fe / mins) / qper_reference_rate();
};

float(entity p) qper_live_rating =
{
	return (1 - qper_own_weight(p)) * 15 + qper_points(p, qper_contribution(p));
};

float(entity p) qper_rating =
{
	if (p.qper_final_valid)
		return p.qper_final;
	return qper_live_rating(p);
};

float(entity p) qper_is_provisional =
{
	return qper_active_mins(p) < QPER_PROVISIONAL_MINS;
};

void(entity p) qper_find_top_terms =
{
	local float i, v;

	qper_top_id1 = qper_top_id2 = qper_top_id3 = -1;
	qper_top_v1 = qper_top_v2 = qper_top_v3 = 0;
	qper_cost_id = -1;
	qper_cost_v = 0;
	for (i = 0; i < QPER_TERMS; i = i + 1)
	{
		v = qper_points(p, qper_term(p, i));
		if (v <= -0.25 && v < qper_cost_v)
		{
			qper_cost_id = i;
			qper_cost_v = v;
		}
		if (v < 0.25)
			continue;
		if (v > qper_top_v1)
		{
			qper_top_id3 = qper_top_id2; qper_top_v3 = qper_top_v2;
			qper_top_id2 = qper_top_id1; qper_top_v2 = qper_top_v1;
			qper_top_id1 = i; qper_top_v1 = v;
		}
		else if (v > qper_top_v2)
		{
			qper_top_id3 = qper_top_id2; qper_top_v3 = qper_top_v2;
			qper_top_id2 = i; qper_top_v2 = v;
		}
		else if (v > qper_top_v3)
		{
			qper_top_id3 = i; qper_top_v3 = v;
		}
	}
};

// ------------------------------------------------------------
// Match end: freeze every rating, then fold the match into the reference.
// ------------------------------------------------------------
void(float aborted) qper_match_end =
{
	local entity p;
	local float mins, sum_contrib, sum_mins;

	p = find(world, classname, "player");
	while (p != world)
	{
		qper_stint_end(p);
		p = find(p, classname, "player");
	}

	sum_contrib = 0;
	sum_mins = 0;
	p = find(world, classname, "player");
	while (p != world)
	{
		if (p.join_time > 0 && stats_has_nontrivial_activity(p))
		{
			p.qper_final = qper_live_rating(p);
			p.qper_final_valid = TRUE;
			mins = qper_active_mins(p);
			if (mins >= QPER_REF_MIN_MINS)
			{
				sum_contrib = sum_contrib + qper_contribution(p);
				sum_mins = sum_mins + mins;
			}
		}
		p = find(p, classname, "player");
	}

	if (aborted || mode_is_arena() || (clanring_playmode & CLANRING_PRACTICE_MODE))
		return;
	qper_ref_update(sum_contrib, sum_mins);
};

// ------------------------------------------------------------
// In-game table (stats / per)
// ------------------------------------------------------------
// Top three contributions and the largest cost, in QPER points.
void(entity towhom, entity p, string heading) qper_print_reasons =
{
	qper_find_top_terms(p);
	if (qper_top_id1 < 0 && qper_cost_id < 0)
		return;
	sprint(towhom, heading);
	if (qper_top_id1 >= 0)
		sprint(towhom, sprintf("    1) %s (+%3.1f)\n", qper_term_label(p, qper_top_id1), qper_top_v1));
	if (qper_top_id2 >= 0)
		sprint(towhom, sprintf("    2) %s (+%3.1f)\n", qper_term_label(p, qper_top_id2), qper_top_v2));
	if (qper_top_id3 >= 0)
		sprint(towhom, sprintf("    3) %s (+%3.1f)\n", qper_term_label(p, qper_top_id3), qper_top_v3));
	if (qper_cost_id >= 0)
		sprint(towhom, sprintf("    biggest cost: %s (%3.1f)\n", qper_term_label(p, qper_cost_id), qper_cost_v));
	sprint(towhom, "\n");
};

void() stats_show_per =
{
	local entity p, bestp;
	local float mins, rating, old_per, best_rating, any_provisional;
	local string mark;

	sprint(self, "\bplayer efficiency rating (QPER)\b\n");
	sprint(self, "\n");
	sprint(self, "  QPER    old   mins  name\n");
	sprint(self, "\n\n");

	if (clanring_playmode & CLANRING_MATCH_MODE)
		p = clanring_sentinel.next_player;
	else
		p = find(world, classname, "player");

	bestp = world;
	best_rating = -9999;
	any_provisional = FALSE;

	while (p)
	{
		if (!(p.style & CLANRING_OBSERVER) && p.join_time > 0)
		{
			mins = qper_active_mins(p);
			rating = qper_rating(p);
			// old PER, unchanged, for side-by-side comparison
			old_per = Q1_PER_Calc_Eff(p) / max(1, (time - p.join_time) / 60);
			if (old_per < 0.1) old_per = 0.1;

			mark = " ";
			if (qper_is_provisional(p))
			{
				mark = "*";
				any_provisional = TRUE;
			}

			if (p == self)
				sprint(self, sprintf("\x90%5.1f\x91%s%5.1f %6.1f \xFC %s\n", rating, mark, old_per, mins, p.netname));
			else
				sprint(self, sprintf(" %5.1f %s%5.1f %6.1f \xFC %s\n", rating, mark, old_per, mins, p.netname));

			// Skip aborted 0:00/no-activity stints when choosing whose reasons to show.
			if ((mins >= 1 || stats_has_nontrivial_activity(p)) && rating > best_rating)
			{
				best_rating = rating;
				bestp = p;
			}
		}

		if (clanring_playmode & CLANRING_MATCH_MODE)
			p = p.next_player;
		else
			p = find(p, classname, "player");
	}
	sprint(self, "\n");
	if (any_provisional)
		sprint(self, sprintf("  * under %g active minutes, provisional\n\n", QPER_PROVISIONAL_MINS));

	if (bestp)
		qper_print_reasons(self, bestp, sprintf("  why %s led QPER:\n", bestp.netname));

	// Each viewer also gets their own breakdown.
	if (bestp != self && !(self.style & CLANRING_OBSERVER) && self.join_time > 0
		&& (qper_active_mins(self) >= 1 || stats_has_nontrivial_activity(self)))
		qper_print_reasons(self, self, sprintf("  your QPER (%3.1f):\n", qper_rating(self)));
};

void() stats_show_per_impulse =
{
	if (mode_is_arena())
	{
		sprint(self, "QPER is not tracked in arena modes\n");
		return;
	}
	sprint(self, "\n");
	stats_show_per();
};
