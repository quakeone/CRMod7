//
// quaketag.qc
//
// This file contains code for the Quake Tag egg :)
//

void() respawn;
void() GibPlayer;
void() BecomeExplosion;

entity crmod_qtag_it;
// --- Tag callouts: per-player fields (live only in this QC) ---
.float qtag_became_at;     // when player became "it"
.float qtag_last_hold;     // how long they held "it" before tagging
.float qtag_ct_light;      // count of LIGHTNING TAGs (<3.0s)
.float qtag_ct_quick;      // count of Quick Tags (<5.0s)
.float qtag_streak_light;  // consecutive LIGHTNING TAGs
.float qtag_best_hold;     // personal best (lowest) hold time
.float qtag_ritual_started;     // time when 6𡑮 hold began (0 = not holding)
.float qtag_ritual_used;        // once per player per Tag game
.float qtag_ritual_surge_until; // if > time, "it" gets dimlight glow (EF_DIMLIGHT)
.float qtag_ct_snail;      // count of SNAIL TAGs (>= 60.0s)
.float qtag_tagged_count;  // times this player was tagged this round (for "Most Tagged")
// q14ever prop helpers
void(entity player_owner) q14ever_spawn_penis;
void() q14ever_penis_think;
void (vector org) spawn_tfog; // debug: visible marker
// q14ever state helpers
float() Q14ever_AnyProps;
void() Q14ever_SyncFlag;
void() Q14ever_RemoveAllProps;

// QuakeTag scoring (no cvars)
// Tunables: change these numbers and recompile.
// Reward the tagger, penalize the tagged.
float QTAG_REWARD = 2;   // frags awarded to tagger per successful tag
float QTAG_PENALTY = 1;  // frags removed from player who gets tagged

// Mini-leaderboard cadence (every N tags)
float QTAG_LEADER_EVERY = 5;
// Global tag counter this round
float qtag_global_tags;
float QTAG_SNAIL_SEC = 60; // threshold for SNAIL TAG callout
// 6𡑮 Lock (no cvars)
float QTAG_RITUAL_HOLD   = 6.66; // seconds you must hold |pitch|?66 & |yaw|?66
float QTAG_RITUAL_EPS    = 6;    // � degrees window for both pitch and yaw
float QTAG_RITUAL_SURGE  = 66.6; // surge duration (s)
float QTAG_RITUAL_ADD    = 32;   // surge adds this many units to tag radius
// Secret surge movement boost
float QTAG_RITUAL_SPEED_MULT = 1.00666; // +0.666% horizontal speed during surge

//
//  I N I T  W O R L D
//
void() quaketag_init_world =
{
	crmod_qtag_it = world;
};

//
//  I N I T
//
void() quaketag_init =
{
	// Must be in match mode + teamplay
	if (!(clanring_playmode & CLANRING_MATCH_MODE))
	{
		centerprint(self, "QuakeTag works only in MATCH mode.\n");
		return;
	}
	if (!teamplay)
	{
		centerprint(self, "QuakeTag requires teamplay 1.\n");
		return;
	}
	if (clanring_sentinel.next_player == world)
	{
		centerprint(self, "No players available to tag.\n");
		return;
	}
	// q14ever path: only spawn/keep the prop on the starter; NO Tag, NO glow.
	if (self.finaldest_z == 14)
	{
		if (!clanring_allow_q14ever) { centerprint(self, "q14ever is disabled on this server.\n"); return; }
		if (self.style & CLANRING_OBSERVER) { centerprint(self, "Observers cannot start q14ever.\n"); return; }

		// prevent duplicates on the same starter
		local entity pe = find(world, classname, "penis");
		while (pe)
		{
			if (pe.owner == self) { sprint(self, "q14ever already active.\n"); return; }
			pe = find(pe, classname, "penis");
		}

		bprint(self.netname, " \bhas a hard-on for quake\b\n");
		q14ever_spawn_penis(self);
		// Play dog sound for q14ever activation on a different channel to avoid Tag SFX collisions
		sound(self, CHAN_ITEM, "dog/dsight.wav", 1, ATTN_NONE);
		return;  // <- no Tag, no "it", no glow
	}

	// If we're actually starting Tag (not q14ever), block if already running
	if (crmod_qtag_it != world)
	{
		centerprint(self, "QuakeTag already running.\n");
		return;
	}

	// Regular Tag (qwsucks / finaldest_z == 15) proceeds as before:
	if (!clanring_allow_qwsucks) { centerprint(self, "qwsucks is disabled on this server.\n"); return; }

	self.use = SUB_Null;

	if (self.style & CLANRING_OBSERVER) crmod_qtag_it = clanring_sentinel.next_player;
	else                                 crmod_qtag_it = self;
	// Initial announcement happens exactly once, at Tag start:
	bprint(crmod_qtag_it.netname, " is it\n");
	crmod_qtag_it.effects = crmod_qtag_it.effects | EF_BRIGHTFIELD;
	// Force the classic qwsucks start sound (distinct from q14ever's)
	sound(self, CHAN_AUTO, "soldier/sight1.wav", 1, ATTN_NONE);
	// Seed timing for callouts
	crmod_qtag_it.qtag_became_at   = time;
	crmod_qtag_it.qtag_streak_light = 0;
	// Reset round tag counter at start
	qtag_global_tags = 0;

	// Safety: drop any leftover glow at game start
	local entity rp;
	rp = find(world, classname, "player");
	while (rp)
	{
		if (rp.style & CLANRING_CONNECTED)
		{
			// Clean up our surge-only glow, preserving real powerups
			if (!((rp.items & IT_INVULNERABILITY) || (rp.items & IT_QUAD)))
				rp.effects = rp.effects - (rp.effects & EF_DIMLIGHT);
			rp.qtag_ritual_surge_until = 0;
		}
		rp = find(rp, classname, "player");
	}
};

// Start regular Tag from server context: pick first connected non-observer player
void() quaketag_start_regular_auto =
{
    local entity starter, oldself;
    if (!clanring_allow_qwsucks) return;
    // If Tag is running in any mode, clear first
    if (crmod_qtag_it != world) quaketag_clear();
    starter = find(world, classname, "player");
    while (starter)
    {
        if ((starter.style & CLANRING_CONNECTED) && !(starter.style & CLANRING_OBSERVER))
        {
            oldself = self;
            self = starter;
            self.finaldest_z = 15;
            quaketag_init();
            self = oldself;
            return;
        }
        starter = find(starter, classname, "player");
    }
};

// Start 14-mode Tag from server context: pick first connected non-observer player
void() quaketag_start_q14ever_auto =
{
    // Overlay semantics: never clear/stop Tag. Attach to a valid player.
    local entity target, p, keepself;
    if (!clanring_allow_q14ever) return;
    target = ((self != world) && (self.style & CLANRING_CONNECTED) && !(self.style & CLANRING_OBSERVER)) ? self : world;
    if (target == world)
    {
        // Prefer current "it" if Tag is running
        if (crmod_qtag_it != world) target = crmod_qtag_it;
    }
    if (target == world)
    {
        // Fallback: first active non-observer
        p = find(world, classname, "player");
        while (p)
        {
            if ((p.style & CLANRING_CONNECTED) && !(p.style & CLANRING_OBSERVER)) { target = p; break; }
            p = find(p, classname, "player");
        }
    }
    if (target == world) return;
    keepself = self; self = target;
    Q14ever_RemoveAllProps();
    q14ever_spawn_penis(self);
    // Use a non-AUTO channel to avoid masking Tag start SFX
    sound(self, CHAN_ITEM, "dog/dsight.wav", 1, ATTN_NONE);
    self = keepself;
};

// ?????????????????????????????????????????????????????????????
// QuakeTag end-of-round awards (no cvars)
// Uses fields added by the callouts patch:
//   .qtag_ct_light, .qtag_ct_quick, .qtag_best_hold, etc.
// ?????????????????????????????????????????????????????????????
// Format float to exactly 2 decimal places (rounded, zero-padded)
string(float val) ftos2dp =
{
	local float neg, v, scaled, whole, frac;
	local string s, fs;
	neg = (val < 0);
	v = neg ? -val : val;
	scaled = floor(v * 100 + 0.5);   // rounded to centiseconds
	whole  = floor(scaled / 100);
	frac   = scaled - whole * 100;   // 0..99
	s  = ftos(whole);
	fs = ftos(frac);
	if (frac < 10) fs = strcat("0", fs);
	s = strcat(s, ".", fs);
	if (neg) s = strcat("-", s);
	return s;
};

// Format a duration in whole seconds; if >= 60s, show "M min, S sec", else "S sec"
string(float secs) qtag_fmt_whole_time =
{
	local float t, rounded, m, s;
	local string out;
	t = secs; if (t < 0) t = 0;
	// Round to nearest whole second
	rounded = floor(t + 0.5);
	m = floor(rounded / 60);
	s = rounded - m * 60;
	if (m >= 1)
		out = strcat(ftos(m), " min, ", ftos(s), " sec");
	else
		out = strcat(ftos(s), " sec");
	return out;
};
// Print only real awards; keep Top Tag Score separate; no stray blank lines.
void() quaketag_print_awards =
{
    local entity p;
    local float maxLight, maxQuick, minHold, maxTagged, maxSnail;
    local float topScore, sawPlayers, anyAwards;

    maxLight = 0; maxQuick = 0; minHold = 999999;
    maxTagged = 0; maxSnail = 0;
    topScore = -999999; sawPlayers = 0;

    // scan players once
    p = find(world, classname, "player");
    while (p)
    {
        if ((p.style & CLANRING_CONNECTED) && !(p.style & CLANRING_OBSERVER))
        {
            if (p.qtag_ct_light > maxLight) maxLight = p.qtag_ct_light;
            if (p.qtag_ct_quick > maxQuick) maxQuick = p.qtag_ct_quick;
            if (p.qtag_ct_snail > maxSnail) maxSnail = p.qtag_ct_snail;
            if (p.qtag_best_hold > 0 && p.qtag_best_hold < minHold) minHold = p.qtag_best_hold;
            if (p.qtag_tagged_count > maxTagged) maxTagged = p.qtag_tagged_count;
            if (!sawPlayers || p.frags > topScore) topScore = p.frags;
            sawPlayers = 1;
        }
        p = find(p, classname, "player");
    }

    // header only if at least one award exists (not counting "Top Tag Score")
    anyAwards = (maxLight > 0) || (maxQuick > 0) || (maxSnail > 0) || (minHold < 999999) || (maxTagged > 0);
    if (anyAwards)
        bprint("== QuakeTag Awards ==\n\n");

    if (maxLight > 0)
    {
        bprint("Most \bLIGHTNING TAGS\b (", ftos(maxLight), "):\n");
        p = find(world, classname, "player");
        while (p)
        {
            if ((p.style & CLANRING_CONNECTED) && !(p.style & CLANRING_OBSERVER) && p.qtag_ct_light == maxLight)
                bprint(p.netname, "\n");
            p = find(p, classname, "player");
        }
        bprint("\n");
    }

    if (maxQuick > 0)
    {
        bprint("Most Quick Tags (", ftos(maxQuick), "):\n");
        p = find(world, classname, "player");
        while (p)
        {
            if ((p.style & CLANRING_CONNECTED) && !(p.style & CLANRING_OBSERVER) && p.qtag_ct_quick == maxQuick)
                bprint(p.netname, "\n");
            p = find(p, classname, "player");
        }
        bprint("\n");
    }

    if (minHold < 999999)
    {
        bprint("Fastest Tag (", ftos2dp(minHold), "s):\n");
        p = find(world, classname, "player");
        while (p)
        {
            if ((p.style & CLANRING_CONNECTED) && !(p.style & CLANRING_OBSERVER)
             && p.qtag_best_hold > 0 && p.qtag_best_hold == minHold)
                bprint(p.netname, "\n");
            p = find(p, classname, "player");
        }
        bprint("\n");
    }

    if (maxTagged > 0)
    {
        bprint("Most Tagged (", ftos(maxTagged), "):\n");
        p = find(world, classname, "player");
        while (p)
        {
            if ((p.style & CLANRING_CONNECTED) && !(p.style & CLANRING_OBSERVER) && p.qtag_tagged_count == maxTagged)
                bprint(p.netname, "\n");
            p = find(p, classname, "player");
        }
        bprint("\n");
    }

    if (maxSnail > 0)
    {
        bprint("Most \bSNAIL TAGS\b (", ftos(maxSnail), "):\n");
        p = find(world, classname, "player");
        while (p)
        {
            if ((p.style & CLANRING_CONNECTED) && !(p.style & CLANRING_OBSERVER) && p.qtag_ct_snail == maxSnail)
                bprint(p.netname, "\n");
            p = find(p, classname, "player");
        }
        bprint("\n");
    }

    // Only show Top Tag Score if at least one tag happened this round
    if (sawPlayers && qtag_global_tags > 0)
    {
        bprint("Top Tag Score (", ftos(topScore), "):\n");
        p = find(world, classname, "player");
        while (p)
        {
            if ((p.style & CLANRING_CONNECTED) && !(p.style & CLANRING_OBSERVER) && p.frags == topScore)
                bprint(p.netname, "\n");
            p = find(p, classname, "player");
        }
    }

    // Reset counters for next round
    p = find(world, classname, "player");
    while (p)
    {
        if ((p.style & CLANRING_CONNECTED))
        {
            p.qtag_ct_light = 0;
            p.qtag_ct_quick = 0;
            p.qtag_ct_snail = 0;
            p.qtag_best_hold = 0;
            p.qtag_last_hold = 0;
            p.qtag_streak_light = 0;
            p.qtag_became_at = 0;
            p.qtag_tagged_count = 0;
        }
        p = find(p, classname, "player");
    }
};

// Mid-round mini-leaderboard: top 3 by tag score (frags)
void() quaketag_print_leaderburst =
{
    local entity p, t1, t2, t3;
    local float s1, s2, s3;
    s1 = -99999; s2 = -99999; s3 = -99999; t1 = world; t2 = world; t3 = world;
    p = find(world, classname, "player");
    while (p)
    {
        if ((p.style & CLANRING_CONNECTED) && !(p.style & CLANRING_OBSERVER))
        {
            if (p.frags > s1)      { s3 = s2; t3 = t2; s2 = s1; t2 = t1; s1 = p.frags; t1 = p; }
            else if (p.frags > s2) { s3 = s2; t3 = t2; s2 = p.frags; t2 = p; }
            else if (p.frags > s3) { s3 = p.frags; t3 = p; }
        }
        p = find(p, classname, "player");
    }

    // Leaderboard (no extra "is it" prints here; we only announce once at start)
    bprint("\n\bTag Leaderboard\b -- ");
    if (t1) bprint("1. ", t1.netname, "  ");
    if (t2) bprint("2. ", t2.netname, "  ");
    if (t3) bprint("3. ", t3.netname, "");
    bprint("\n\n");

    // (Intentionally no "is it" echo here.)
};

//
//  C L E A R
//
void() quaketag_clear =
{
	// Always remove any q14ever props, even if Tag isn't running
	local entity e, p;
	e = find(world, classname, "penis");            while (e) { remove(e); e = find(e, classname, "penis"); }
	e = find(world, classname, "q14ever_penis");    while (e) { remove(e); e = find(e, classname, "q14ever_penis"); }
	// If last prop is gone, ensure the toggle reflects "disabled"
	Q14ever_SyncFlag();

	if (crmod_qtag_it)
	{
		crmod_qtag_it.effects = crmod_qtag_it.effects - (crmod_qtag_it.effects & EF_BRIGHTFIELD);
		// Clean up our surge glow on round end, preserving real powerups
		if (!((crmod_qtag_it.items & IT_INVULNERABILITY) || (crmod_qtag_it.items & IT_QUAD)))
			crmod_qtag_it.effects = crmod_qtag_it.effects - (crmod_qtag_it.effects & EF_DIMLIGHT);
		bprint("QuakeTag Over!\n\n");
		// Print end-of-round awards (based on live counters), then reset them
		quaketag_print_awards();

		        // Reset scoreboard for next round: zero frags for all connected players
        p = find(world, classname, "player");
        while (p)
        {
            if (p.style & CLANRING_CONNECTED)
            {
                p.frags = 0;
                // Clear ritual for a fresh next game
                p.qtag_ritual_started = 0;
                p.qtag_ritual_used = 0;
                p.qtag_ritual_surge_until = 0;
                // Clean up our surge glow, preserving real powerups
                if (!((p.items & IT_INVULNERABILITY) || (p.items & IT_QUAD)))
                    p.effects = p.effects - (p.effects & EF_DIMLIGHT);
            }
            p = find(p, classname, "player");
        }
        // Reset global tag counter
        qtag_global_tags = 0;
	}
	crmod_qtag_it = world;
};

//
//  D I S C O N N E C T  N O T I F Y 
//
void(entity player) quaketag_disconnect_notify =
{
	// Clean up any attached props from the leaver
	local entity p = find(world, classname, "penis");
	while (p) { if (p.owner == player) remove(p); p = find(p, classname, "penis"); }
	p = find(world, classname, "q14ever_penis");
	while (p) { if (p.owner == player) remove(p); p = find(p, classname, "q14ever_penis"); }
	if (crmod_qtag_it == player)
		quaketag_clear();
	else
		Q14ever_SyncFlag(); // player left may have been the last prop owner
};

//
//  R E S P A W N
//
void() quaketag_respawn =
{
	local float ready;

	ready = self.style & CLANRING_READY;
	self.style = self.style | CLANRING_READY;
	respawn();
	self.style = (self.style - CLANRING_READY) | ready;
	self.effects = self.effects | EF_BRIGHTFIELD;
};

//
//  S T A R T  F R A M E
//
void() quaketag_start_frame =
{
    local entity oself;

    if (crmod_qtag_it == world) return;
    if (crmod_qtag_it.deadflag) return;

    // --- Secret 6𡑮 Lock: hold |pitch|?66 and |yaw|?66 for >6.66s (only when you're "it")
    if (!crmod_qtag_it.qtag_ritual_used)
    {
        // Normalize to signed angles
        local float py, yy, ay, ap, dy, dp;
        py = crmod_qtag_it.v_angle_x; while (py > 180) py -= 360; while (py < -180) py += 360;
        yy = crmod_qtag_it.v_angle_y; while (yy > 180) yy -= 360; while (yy < -180) yy += 360;
        ay = yy; if (ay < 0) ay = -ay;        // |yaw|
        ap = py; if (ap < 0) ap = -ap;        // |pitch|
        dy = ay - 66; if (dy < 0) dy = -dy;   // | |yaw|-66 |
        dp = ap - 66; if (dp < 0) dp = -dp;   // | |pitch|-66 |

        if (dy <= QTAG_RITUAL_EPS && dp <= QTAG_RITUAL_EPS)
        {
            if (!crmod_qtag_it.qtag_ritual_started)
                crmod_qtag_it.qtag_ritual_started = time;
            else if (time - crmod_qtag_it.qtag_ritual_started > QTAG_RITUAL_HOLD)
            {
                // Ritual complete: arm one-time surge (once per player per game)
                crmod_qtag_it.qtag_ritual_used = 1;
                crmod_qtag_it.qtag_ritual_started = 0;
                crmod_qtag_it.qtag_ritual_surge_until = time + QTAG_RITUAL_SURGE;
                sprint(crmod_qtag_it, strcat("\bThe SixSixSix Stirs...\b  (+", ftos2dp(QTAG_RITUAL_SURGE), "s reach, +.666% speed)\n"));
                sound(crmod_qtag_it, CHAN_AUTO, "items/protect.wav", 1, ATTN_NONE);
            }
        }
        else
        {
            crmod_qtag_it.qtag_ritual_started = 0;
        }
    }


    // Apply/expire glow for the current "it" based on surge window
    {
        local float has_quad, has_pent;
        has_quad = (crmod_qtag_it.items & IT_QUAD);
        has_pent = (crmod_qtag_it.items & IT_INVULNERABILITY);
        if (crmod_qtag_it.qtag_ritual_surge_until > time)
        {
            // Force dimlight glow during surge regardless of current powerups
            crmod_qtag_it.effects = crmod_qtag_it.effects | EF_DIMLIGHT;
        }
        else
        {
            // Only remove the bits we "own"; keep real powerup effects
            if (!(has_quad || has_pent))
                crmod_qtag_it.effects = crmod_qtag_it.effects - (crmod_qtag_it.effects & EF_DIMLIGHT);
        }
    }

    // During surge: +66% horizontal speed, capped at 666 u/s (don't touch vertical)
    if (crmod_qtag_it.qtag_ritual_surge_until > time)
    {
        // extra sanity: ignore observers or dead states (already early-returned above for deadflag)
        if (!(crmod_qtag_it.style & CLANRING_OBSERVER))
        {
            local vector v, h;
            local float s2d, target, scale;
            v = crmod_qtag_it.velocity;
            h = v; h_z = 0;                // horizontal slice only
            s2d = vlen(h);
            if (s2d > 0)
            {
                target = s2d * QTAG_RITUAL_SPEED_MULT;
                scale = target / s2d;
                v_x = v_x * scale;
                v_y = v_y * scale;
                // keep v_z unchanged so jumps/knockback feel natural
                crmod_qtag_it.velocity = v;
            }
        }
    }

	other = find(world, classname, "player");
	while (other)
	{
		if (!(other.style & CLANRING_OBSERVER) && (other.style & CLANRING_CONNECTED))
		{
			if (other != crmod_qtag_it)
			{
				local vector tag_vector;
				tag_vector = other.origin - crmod_qtag_it.origin;
				// Base tag radius 64u; surge briefly adds +32u after the ritual
				local float tag_radius; tag_radius = 64;
				if (crmod_qtag_it.qtag_ritual_surge_until > time)
					tag_radius = tag_radius + QTAG_RITUAL_ADD;
				if (vlen(tag_vector) < tag_radius)
				{
					// --- STYLE CALLOUTS (classify the *old* "it" before switching) ---
					local entity tagger;
					local float hold;
					tagger = crmod_qtag_it;                  // old "it"
					hold   = time - tagger.qtag_became_at;   // how long they held it
					if (hold < 0) hold = 0;
					tagger.qtag_last_hold = hold;
					if (tagger.qtag_best_hold == 0 || hold < tagger.qtag_best_hold)
						tagger.qtag_best_hold = hold;

					// <3.0s -> LIGHTNING TAG!, <5.0s -> Quick Tag
					if (hold < 3)
					{
						tagger.qtag_ct_light = tagger.qtag_ct_light + 1;
						tagger.qtag_streak_light = tagger.qtag_streak_light + 1;
						bprint(tagger.netname, " \bLIGHTNING TAG!\b (", ftos2dp(hold), "s)\n");
						sound(tagger, CHAN_ITEM, "ambience/buzz1.wav", 1, ATTN_NONE);
						// Small streak shout at 3+ in a row
						if (tagger.qtag_streak_light >= 3)
						{
							bprint("  ", tagger.netname, " is on a \bLIGHTNING STREAK x", ftos(tagger.qtag_streak_light), "\b!\n");
							sound(tagger, CHAN_AUTO, "ambience/buzz1.wav", 1, ATTN_NONE);
						}
					}
					else if (hold < 5)
					{
						tagger.qtag_ct_quick = tagger.qtag_ct_quick + 1;
						tagger.qtag_streak_light = 0; // streak only counts LIGHTNINGs
						bprint(tagger.netname, " Quick Tag (", ftos2dp(hold), "s)\n");
						sound(tagger, CHAN_ITEM, "items/armor1.wav", 0.9, ATTN_NONE);
					}
					else if (hold >= QTAG_SNAIL_SEC)
					{
						tagger.qtag_ct_snail = tagger.qtag_ct_snail + 1;
						tagger.qtag_streak_light = 0;
						// SNAIL TAG prints use whole seconds; if >=60s, show "M min, S sec"
						bprint(tagger.netname, " \bSNAIL TAG\b (", qtag_fmt_whole_time(hold), ")\n");
						// (Optional SFX: reuse a safe item sound)
						sound(tagger, CHAN_ITEM, "items/armor1.wav", 0.8, ATTN_NONE);
					}
					else
					{
						tagger.qtag_streak_light = 0;
					}

					                    // --- Award the tagger & update counters BEFORE the handoff ---
                    // Tagger is the old "it" (stored in 'tagger' above).
                    tagger.frags = tagger.frags + QTAG_REWARD;
                    // Count that the victim (other) got tagged
                    other.qtag_tagged_count = other.qtag_tagged_count + 1;
                    // Global tag counter + mini-leaderboard every N tags
                    qtag_global_tags = qtag_global_tags + 1;
                    if (floor(qtag_global_tags / QTAG_LEADER_EVERY) == (qtag_global_tags / QTAG_LEADER_EVERY))
                        quaketag_print_leaderburst();

					// --- proceed with your existing handoff ---
					oself = self;
					self = other;
					crmod_qtag_it.effects = crmod_qtag_it.effects - (crmod_qtag_it.effects & EF_BRIGHTFIELD);
					// Also drop our surge glow from the old "it" (but don't stomp real powerups)
					if (!((crmod_qtag_it.items & IT_INVULNERABILITY) || (crmod_qtag_it.items & IT_QUAD)))
						crmod_qtag_it.effects = crmod_qtag_it.effects - (crmod_qtag_it.effects & EF_DIMLIGHT);
					crmod_qtag_it = self;
					// Tag handoff strips any q14ever prop(s) from the NEW "it"
					local entity penis;
					penis = find(world, classname, "penis");
					while (penis)
					{
						if (penis.owner == self)
							remove(penis);
						penis = find(penis, classname, "penis");
					}
					// Back-compat: older builds used "q14ever_penis"
					penis = find(world, classname, "q14ever_penis");
					while (penis)
					{
						if (penis.owner == self)
							remove(penis);
						penis = find(penis, classname, "q14ever_penis");
					}
					// Keep the on/off flag honest if that was the last prop
					Q14ever_SyncFlag();

					// --- Tag penalty: being tagged costs you frags ---
					// (self == the player who was just tagged and will be gibbed)
					self.frags = self.frags - QTAG_PENALTY;

			        self.health = -99;

					local float gibs;
					gibs = clanring_playmode & (CLANRING_NO_GIBS | CLANRING_LOW_GIBS);
					clanring_playmode = clanring_playmode - gibs;
					GibPlayer();
					clanring_playmode = clanring_playmode | gibs;

					self.deadflag = DEAD_DYING;
					self.think = quaketag_respawn;
					self.nextthink = time + 1;
					// Handoff announcement: "<old-it> tagged <victim>, <victim> is now it"
					// 'tagger' = old it; 'other' = victim/new it (still valid ref)
					bprint(tagger.netname, " tagged ", other.netname, ", ", other.netname, " is now it\n");
					// Stamp new "it" start time (fresh timer / streak)
					crmod_qtag_it.qtag_became_at    = time;
					crmod_qtag_it.qtag_streak_light = 0;
					// On handoff: keep 'used' so it stays once-per-game; clear transient state + glow
					crmod_qtag_it.qtag_ritual_started = 0;
					crmod_qtag_it.qtag_ritual_surge_until = 0;
					self = oself;
					return;
				}
			}
		}
		other = find(other, classname, "player");
	}
};

// -----------------------------
// q14ever missile follow effect � FULL legacy gag
// -----------------------------
void() q14ever_penis_think =
{
	local vector tip, desired;
	local entity player;
	local float da, r, tick;

	if (!self.owner || self.owner.health <= 0) { remove(self); return; }

	// --- mirror CTF timing: reschedule on server tick ---
	tick = sys_ticrate; if (tick <= 0) tick = 0.05; if (tick < 0.001) tick = 0.001;
	self.nextthink = time + tick;

	// --- mirror CTF orientation: use model angles, not v_angle ---
	makevectors(self.owner.angles);
	// keep your *current* placement (no flag-style offsets)
	// but predict ahead by one tick to kill the "trailing" look
	desired = self.owner.origin + (self.owner.velocity * tick);
	setorigin(self, desired);
	self.angles = vectoangles(v_forward);
	if (self.alpha <= 0) self.alpha = 1;

	// legacy interaction logic (rate-limited by attack_finished)
	if (time < self.attack_finished) return;

	tip = self.owner.origin + 32 * v_forward;
	player = find(world, classname, "player");
	while (player)
	{
		if ((player != self.owner)
		 && (player.health > 0)
		 && (player.style & CLANRING_CONNECTED)
		 && !(player.style & CLANRING_OBSERVER))
		{
			if (vlen(tip - player.origin) < 16)
			{
				// yaw delta in [-180, 180]
				da = self.owner.v_angle_y - player.v_angle_y;
				if (da > 180)  da -= 360;
				if (da < -180) da += 360;

				if (da > -30 && da < 15)
				{
					r = random();
					self.count = self.count + 1;

					if (self.count == 7)
					{
						if (r < 0.33)       sound(self, CHAN_VOICE, "player/death1.wav", 1, ATTN_NORM);
						else if (r < 0.66)  sound(self, CHAN_VOICE, "player/death2.wav", 1, ATTN_NORM);
						else                sound(self, CHAN_VOICE, "player/death3.wav", 1, ATTN_NORM);

						BecomeExplosion();          // will remove shortly
						self.classname = "dead_penis";
						// Prop is gone -> reflect disabled so future votes propose Enable
						Q14ever_SyncFlag();
						return;
					}
					else
					{
						if (r < 0.5) sound(self, CHAN_VOICE, "player/pain2.wav", 1, ATTN_NORM);
						else         sound(self, CHAN_VOICE, "player/pain4.wav", 1, ATTN_NORM);
					}

					self.attack_finished = time + 0.4;
					return;
				}
			}
		}
		player = find(player, classname, "player");
	}

	if (self.count)
	{
		self.count = 0;
		sound(self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
	}
};

void(entity player_owner) q14ever_spawn_penis =
{
	local entity p;
	p = spawn();
	// Use the original classname so legacy cleanup paths see it.
	p.classname = "penis";
	p.owner = player_owner;
	setmodel(p, "progs/missile.mdl");
	setsize(p, '0 0 0', '0 0 0');
	setorigin(p, player_owner.origin);
	// Mirror CTF carried flag: no server physics nudge, smoother follow
	p.movetype = MOVETYPE_NOCLIP;
	p.solid    = SOLID_BBOX;
	p.effects  = p.effects | EF_DIMLIGHT; // no EF_BRIGHTFIELD for q14ever
	p.alpha    = 1; // visible on QSS/FTE
	// Legacy uses these two for timing / "interaction" logic later.
	p.attack_finished = time;
	p.count = 0;
	p.think = q14ever_penis_think;
	p.nextthink = time + ((sys_ticrate > 0) ? sys_ticrate : 0.05);

	// OPTIONAL (if your engine supports it) � true attachment for zero lag:
	// p.movetype = MOVETYPE_FOLLOW; p.aiment = player_owner;
	// (Keeps same visual; origin treated as offset on most engines.)
};

// -----------------------------
// q14ever helpers: presence -> flag sync
// -----------------------------
float() Q14ever_AnyProps =
{
	local entity e;
	e = find(world, classname, "penis");
	if (e) return TRUE;
	e = find(world, classname, "q14ever_penis");
	if (e) return TRUE;
	return FALSE;
};

void() Q14ever_SyncFlag =
{
	if (clanring_allow_q14ever && !Q14ever_AnyProps())
	{
		// Silent sync to runtime flag only; do not touch server cvars.
		clanring_allow_q14ever = 0;
	}
};

// Remove any q14ever props immediately and resync the toggle
void() Q14ever_RemoveAllProps =
{
	local entity e;
	e = find(world, classname, "penis");
	while (e) { remove(e); e = find(e, classname, "penis"); }
	e = find(world, classname, "q14ever_penis");
	while (e) { remove(e); e = find(e, classname, "q14ever_penis"); }
	Q14ever_SyncFlag();
};