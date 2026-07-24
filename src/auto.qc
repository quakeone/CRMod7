//
// auto.qc
//
// This is the autocam handling code for CRMod++.
//
// All code by J.P. Grossman unless otherwise commented.  :p
//
// // Global variables used:
//
// entity crmod_best_chase_target;    // best chase target in terms of score alone
// entity crmod_current_chase_target; // current chase target 
// float crmod_chase_delay;           // delay before we can switch to best chasetarget
// entity crmod_best_camera;          // best camera in terms of score alone
// entity crmod_current_camera;       // current QUAKETV camera
// float crmod_camera_delay;          // delay before we can switch to best camera
//

// // Client fields used:
//
// .attack_finished				used to tell when a person last fired a weapon
// .super_damage_finished		findperson with quad
// .crmod_autotime				time change targets
//
// Prototypes:
void() observer_chase_start;
void() observer_camera_start;
void() observer_demo_start;

// CRMOD
// A U T O  S C O R E  C R M O D
//
//  Renamed and revamped by J.P. Grossman
//
//  Based on specified criteria, rates the player to see if they are the best player to watch.
//  Called once every second
//
float() auto_score_crmod =
{
	local float score, temp;

	// score starts off with health, armor, frags, last time they fired their gun, 
	// and last time they hurt someone.
	score = self.health + self.armorvalue + self.frags;
	temp = self.clanring_did_damage + 15 - time;
	if (temp > 0)
		score = score + temp * 40;

	temp = self.attack_finished + 10 - time;
	if (temp > 0)
		score = score + temp * 20;

	// weapon related stuff
	if (self.items & IT_GLRLLG)
	{
		// 200 + # of rockets if they have RL		
		if (self.items & IT_ROCKET_LAUNCHER)
		{
			score = score + 200 + self.ammo_rockets;
			// bonus if it's the only one on the team
			if (teamplay && (clanring_state & CLANRING_MATCH_STARTED))
			{
				if (self.next_team.ammo_rockets == 1)
					score = score + auto_parm1;
			}
		}
		// or just # of rockets if they have GL
		else if (self.items & IT_GRENADE_LAUNCHER)
				score = score + self.ammo_rockets;

		// and # of cells if they have LG
		if (self.items & IT_LIGHTNING)
			score = score + self.ammo_cells;
	}

	// powerups 300 ea. for quad or pent, 50 for eyes
	if (self.items & IT_QINVISINVUL)
	{
		if (self.items & IT_QUAD)
			score = score + 300;

		if (self.items & IT_INVULNERABILITY)
			score = score + 300;

		if (self.items & IT_INVISIBILITY)
			score = score + 50;
	}
	//R00k ADDED
	if (self.flag_carrier)
		score = score + 400;//(FIXME: lower this?)
	
	// powerup potential?
	if ((clanring_pent != world) && (time > clanring_pent.nextthink - 15))
		score = score + auto_parm2 * 300 / (vlen(self.origin - clanring_pent.origin) + 300);

	if ((clanring_quad != world) && (time > clanring_quad.nextthink - 10))
		score = score + auto_parm3 * 300 / (vlen(self.origin - clanring_quad.origin) + 300);

	return score;
};

// CRMOD
// A U T O  S C O R E  K T X
//
//  KTX's autotrack weighting (ktx/src/g_utils.c, CalculateBestPlayers).  Pure item
//  tiers plus frags - no health, armor, activity or proximity terms.  Each tier is
//  far enough above the one below it that a single item decides the pov outright:
//
//		Pentagram of Protection		99999
//		Quad Damage					 9000
//		any other Powerup			 4000
//		Rocket Launcher with ammo	 1500
//		Lightning Gun with ammo		  500
//		Flag carrier				  300
//		Grenade Launcher with ammo	  200
//		Super Nailgun with ammo		  100
//		Super Shotgun with ammo		   50
//
//  KTX has no concept of CTF and the flag carrier tier is ours, deliberately low:
//  running the flag is not in itself worth watching, so a carrier loses the pov to
//  anyone holding an LG, an RL or a powerup and only wins it against the small guns.
//
float() auto_score_ktx =
{
	local float score;

	score = 0;

	// Spawn protection in the arena modes hands out a real pent for a couple of
	// seconds.  KTX has nothing like it, and scoring it would snap the pov onto
	// whoever respawned last, so it doesn't count as a powerup here.
	if ((self.items & IT_INVULNERABILITY) && !(self.spawn_protect_finished > time))
		score = score + 99999;

	if (self.items & IT_QUAD)
		score = score + 9000;

	if ((self.items & IT_INVISIBILITY) || (self.items & IT_SUIT))
		score = score + 4000;

	if ((self.items & IT_ROCKET_LAUNCHER) && (self.ammo_rockets > 0))
		score = score + 1500;

	if ((self.items & IT_LIGHTNING) && (self.ammo_cells > 0))
		score = score + 500;

	if (self.flag_carrier)
		score = score + 300;

	if ((self.items & IT_GRENADE_LAUNCHER) && (self.ammo_rockets > 0))
		score = score + 200;

	if ((self.items & IT_SUPER_NAILGUN) && (self.ammo_nails > 0))
		score = score + 100;

	if ((self.items & IT_SUPER_SHOTGUN) && (self.ammo_shells > 0))
		score = score + 50;

	// Head hunters: a big stack of heads makes you the thing the whole server is
	// hunting, which is worth watching whatever you are holding.  Under four heads
	// each one is only a nudge; at four the carrier jumps into the powerup band and
	// keeps climbing with the count, so the bigger stack wins.
	//
	// Heads are uncapped in play, so the per head part has to be capped here or a
	// long enough run would climb past the quad tier - 4000 + 100 a head overtakes
	// 9000 at fifty heads, or thirty five with an RL in hand.  Twenty heads' worth
	// keeps the whole head contribution at 6000, under quad, which is where it
	// belongs: a quad hunting the carrier is the same fight from the better end.
	//
	// NB: hh_maxheads, the carry cap, is declared but never assigned anywhere in the
	// mod.  If a cap is ever wired up and set below four, this tier stops being
	// reachable and the threshold needs to clamp to it.
	if ((clanring_playmode & CLANRING_HH_MODE) && (self.ammo_heads > 0))
	{
		local float heads;

		heads = self.ammo_heads;
		if (heads > 20)
			heads = 20;

		score = score + (heads * 100);

		if (self.ammo_heads >= 4)
			score = score + 4000;
	}

	return score + self.frags;
};

// CRMOD
// A U T O  C O M P U T E  S C O R E
//
//  Scores 'self' with whichever formula cr_autotrack selects and files them as the
//  best chase target / camera subject if they beat the incumbent.
//  Called once every second for every live player.
//
void() auto_compute_score =
{
	local float score;

	if (clanring_autotrack_mode == CLANRING_AUTOTRACK_KTX)
		score = auto_score_ktx();
	else
		score = auto_score_crmod();

	// now store their score for later
	self.clanring_chase_score = score;

	if (score > clanring_best_chase_target.clanring_chase_score || clanring_best_chase_target == world)
		clanring_best_chase_target = self;

	if (score > clanring_best_camera.clanring_chase_score || clanring_best_camera == world)
		clanring_best_camera = self;
};

//
//  A U T O  D E A T H  H O L D
//
//  How long we stay on a player after they die, so the kill is actually seen.
//  KTX waits 2 seconds (or until respawn); CRMod's classic hold is 1.
//
float() auto_death_hold =
{
	if (clanring_autotrack_mode == CLANRING_AUTOTRACK_KTX)
		return 2;

	return 1;
};

//
//  A U T O  T R A C K A B L E
//
//  Is this entity somebody autotrack is allowed to put a spectator on?
//
float(entity e) auto_trackable =
{
	if (e == world)
		return FALSE;
	if (e.classname != "player")
		return FALSE;
	if (e.style & CLANRING_OBSERVER)
		return FALSE;
	if (!(e.style & CLANRING_CONNECTED))
		return FALSE;
	if (e.deadflag)
		return FALSE;

	return (e.health > 0);
};

//
//  A U T O  R E C O M P U T E  B E S T
//
//  Rescore every live player right now and pick the leader.  The per-second pass
//  only ever replaces the incumbent, which is fine when scores drift slowly, but
//  an event (a quad taken, the pov dying) needs an answer this frame.
//
void() auto_recompute_best =
{
	local entity player, oldself;
	local float score, best;

	oldself = self;
	best = CLANRING_NEGINF;
	clanring_best_chase_target = world;

	player = find(world, classname, "player");
	while (player)
	{
		if (auto_trackable(player))
		{
			self = player;
			if (clanring_autotrack_mode == CLANRING_AUTOTRACK_KTX)
				score = auto_score_ktx();
			else
				score = auto_score_crmod();
			self = oldself;

			player.clanring_chase_score = score;

			if (score > best)
			{
				best = score;
				clanring_best_chase_target = player;
			}
		}
		player = find(player, classname, "player");
	}
};

//
//  A U T O  R E C O M P U T E  T E A M  B E S T S
//
//  Same idea as auto_recompute_best, but per team.  The arena modes cam lock a
//  player who is out of the round to their own team, so autocam has to be able to
//  answer "best pov on this team" as well as "best pov on the map".  Reads the
//  scores the normal pass already stored, so it works in either formula.
//
void() auto_recompute_team_bests =
{
	local entity player;

	// Only the arena cam lock consumes these, and only arena modes lock anyone, so
	// there is nothing to compute in FFA, pub or CTF - and in FFA nobody even has a
	// .next_team for it to hang off.
	if (!mode_is_arena())
		return;

	player = find(world, classname, "player");
	while (player)
	{
		if (player.next_team != world)
		{
			player.next_team.autotrack_team_best = world;
			player.next_team.autotrack_team_score = CLANRING_NEGINF;
		}
		player = find(player, classname, "player");
	}

	player = find(world, classname, "player");
	while (player)
	{
		if ((player.next_team != world) && auto_trackable(player))
		{
			if ((player.next_team.autotrack_team_best == world)
				|| (player.clanring_chase_score > player.next_team.autotrack_team_score))
			{
				player.next_team.autotrack_team_best = player;
				player.next_team.autotrack_team_score = player.clanring_chase_score;
			}
		}
		player = find(player, classname, "player");
	}
};

//
//  A U T O  C A M  L O C K E D
//
//  In the arena modes a player who is in the current round - alive or waiting out
//  their death - may only watch their own team.  observer_arena_next_target already
//  enforces this when they cycle targets by hand; 'self' is the spectator.
//
float() auto_cam_locked =
{
	if (!mode_is_arena())
		return FALSE;
	if (self.next_team == world)
		return FALSE;		// a real spectator, not part of the round

	// Only while a round is actually live.  Between rounds there is nothing left to
	// give away, and holding the lock there would strand people in eyecam during
	// warmup instead of letting them fly the map like they always have.
	if ((boss.state != CA_MATCH_PLAYING) && (boss.state != CA_MATCH_ROUNDSTART))
		return FALSE;

	return ((self.ca_player_flag == PF_PLAYING) || (self.ca_player_flag == PF_DEAD));
};

//
//  A U T O  P O V  T A R G E T
//
//  Who the auto modes should put this spectator on.  Everyone shares the global
//  pov except cam locked arena players, who get the best of their own team.
//
entity() auto_pov_target =
{
	if (auto_cam_locked())
		return self.next_team.autotrack_team_best;

	return clanring_current_chase_target;
};

//
//  A U T O  T R A C K  E V E N T
//
//  ktpro's autotrack switches the pov on events rather than waiting for the next
//  poll: the first RL of the match, the tracked player dying, any powerup taken,
//  and a quad/pent about to spawn.  'hint' is who the event thinks we want to see
//  and may be world, in which case we just take the best player.
//
void(entity hint) auto_track_event =
{
	if (clanring_autotrack_mode != CLANRING_AUTOTRACK_KTX)
		return;		// classic CRMod autocam is poll driven only

	clanring_autotrack_event = TRUE;
	clanring_autotrack_hint = (auto_trackable(hint)) ? hint : world;
	clanring_chase_delay = 0;	// don't make the event wait out the switch delay
};

//
//  A U T O  T R A C K  F I R S T  R L
//
//  Called on every ground RL pickup; only the first of the match is an event.
//
void(entity player) auto_track_first_rl =
{
	if (clanring_autotrack_rl_taken)
		return;

	clanring_autotrack_rl_taken = TRUE;
	auto_track_event(world);	// ktpro deliberately ignores the taker here - a live
								// powerup elsewhere still outranks a fresh rocket launcher
};

//
//  A U T O  T R A C K  P R E D I C T  P O W E R U P
//
//  Move the pov to whoever is closest to a quad or pent shortly before it spawns,
//  so the pickup is on screen instead of being caught up with afterwards.  KTX's
//  rules: quad and pent only, players more than 500 units away don't count, the
//  powerup has to be visible to them, and the whole thing is skipped while someone
//  is already running a quad or pent.
//
void(entity powerup) auto_track_predict_powerup =
{
	local entity player, best;
	local float len, best_len;

	if (powerup == world)
		return;

	best = world;
	best_len = 1000000;

	player = find(world, classname, "player");
	while (player)
	{
		if (auto_trackable(player))
		{
			if (player.items & (IT_QUAD | IT_INVULNERABILITY))
			{
				if (!(player.spawn_protect_finished > time))
					return;		// someone is already poweruped, stay with them
			}

			len = vlen(player.origin - powerup.origin);
			if ((len <= 500) && (len < best_len))
			{
				if (utils_visible(powerup, player))
				{
					best_len = len;
					best = player;
				}
			}
		}
		player = find(player, classname, "player");
	}

	if (best != world)
		auto_track_event(best);
};

//
//  A U T O  C H E C K  P O W E R U P  S P A W N
//
//  KTX hangs the prediction off the powerup's own think, exactly once and exactly
//  AUTOTRACK_POWERUPS_PREDICT_TIME (2s) before it comes back.  CRMod's powerups are
//  plain SUB_regen items, so we poll the same window instead and remember which
//  respawn we already fired for, to keep it one shot per cycle like KTX.
//
void(entity powerup) auto_check_one_powerup_spawn =
{
	if (powerup == world)
		return;
	if (powerup.nextthink <= time)
		return;						// on the ground, or not due back
	if (powerup.nextthink - time > 2)
		return;						// still outside the predict window
	if (powerup.autotrack_predict_at == powerup.nextthink)
		return;						// already predicted for this respawn

	powerup.autotrack_predict_at = powerup.nextthink;
	auto_track_predict_powerup(powerup);
};

void() auto_check_powerup_spawn =
{
	local entity powerup;

	if (clanring_autotrack_mode != CLANRING_AUTOTRACK_KTX)
		return;

	// auto_chase_think can run every frame while an event waits out a death hold,
	// and this walks the edict list twice.  A quarter second is far finer than the
	// two second predict window needs.
	if (time < clanring_autotrack_predict_next)
		return;

	clanring_autotrack_predict_next = time + 0.25;

	// Every quad and pent on the map, not just the clanring_quad/clanring_pent
	// shortcuts - KTX predicts per powerup entity and some maps carry two.
	powerup = find(world, classname, "item_artifact_super_damage");
	while (powerup)
	{
		auto_check_one_powerup_spawn(powerup);
		powerup = find(powerup, classname, "item_artifact_super_damage");
	}

	powerup = find(world, classname, "item_artifact_invulnerability");
	while (powerup)
	{
		auto_check_one_powerup_spawn(powerup);
		powerup = find(powerup, classname, "item_artifact_invulnerability");
	}
};

// CRMOD
// A U T O  C A M E R A  T H I N K
//
// Called once every second for cameras that can see the best chase target
//
//   JP - added self.count to compute a 'visible player' score
//	 JP - got rid of 'best'; used self.movetarget throughout
//
void() auto_camera_think =
{
	local float score, seeable, temp;
	local entity player;
	local float check;//R00k, sometimes the linklist gets corrupted, this is here to contain the error :(

	self.movetarget = clanring_sentinel;
	score = 0;		// JP - added this
	self.count = 0;	// JP - added this
	player = clanring_sentinel.next_player;
	check = 1;
	
	while ((player != world) && (check < 17))//fixme set to sv_maxplayers
	{
		check = check + 1;
		seeable = utils_new_visible (self, player);
		if (seeable)
		{
			self.count = self.count + seeable;
			score = score + player.clanring_chase_score;

			if (seeable == 4)
			{
				// Bonus points for proximity
				temp = 600 - vlen(self.origin - player.origin);
				if (temp > 0)
					score = score + temp / 3;
				if (player.clanring_chase_score > self.movetarget.clanring_chase_score)
					self.movetarget = player;
			}
		}
		player = player.next_player;
	}

	self.clanring_cam_delay = time + 4;

	// now store their score for later
	self.clanring_chase_score = score;

	if (self.movetarget == clanring_sentinel)
	{
		self.movetarget = world;
		if (clanring_best_camera == self)
			clanring_best_camera = clanring_best_chase_target;
		if (clanring_current_camera == self)
		{
			clanring_current_camera = clanring_best_camera;
			clanring_camera_delay = time + 4;
		}
	}
	else if (self.count >= 8)
	{
		if (self.clanring_chase_score > clanring_best_camera.clanring_chase_score || clanring_best_camera == world)
			clanring_best_camera = self;
	}
};

//
//  C H E C K  C U R R E N T  C A M E R A
//
//  Each frame, make sure that the current camera has a movetarget.
//
void() auto_check_current_camera =
{
	local float seeable;
	local entity temp;

	if (clanring_current_camera.classname == "clanring_camera")
	{
		seeable = 0;
		if (clanring_current_camera.movetarget)
			seeable = utils_new_visible (clanring_current_camera, clanring_current_camera.movetarget);
		if (seeable < 4)
		{
			temp = self;
			self = clanring_current_camera;
			self.nextthink = -1;
			auto_camera_think ();
			self = temp;
		}
	}
};

//
//  S C H E D U L E  C A M E R A S
//
//  Any cameras that can see the best chase target should be allowed to think
//
void() auto_schedule_cameras =
{
	local entity camera;

	if (!clanring_best_chase_target)
		return;

	camera = clanring_sentinel.next_camera;
	while (camera)
	{
		if (utils_visible (camera, clanring_best_chase_target))
			camera.nextthink = (time + 0.1) + random ();//R00k added time + 0.1  (random can return 0)
		else if (camera == clanring_current_camera)
			camera.nextthink = (time + 0.1) + random ();//R00k added time + 0.1  (random can return 0)
		else
			camera.clanring_chase_score = -1;
		camera = camera.next_camera;
	}
};

// CRMOD
//  A U T O  C A M E R A  S T A R T
//    by Paul Baker
//
//  start autocamera from anywhere
//
void() auto_camera_start =
{
	self.oflags = self.oflags | OBSERVER_QUAKETV;//R00k added OBSERVER_QUAKETV
	self.oflags = self.oflags | OBSERVER_GO_AUTO;
	observer_camera_start ();
};

// CRMOD
//  A U T O  C H A S E  S T A R T
//    by Paul Baker
//
//  start autochase from anywhere
void() auto_chase_start =
{
	self.oflags = self.oflags | OBSERVER_QUAKETV;//R00k added OBSERVER_QUAKETV
	self.oflags = self.oflags | OBSERVER_GO_AUTO;
	observer_chase_start ();
};

// CRMOD
//  A U T O  P O V  S T A R T
//    not by Paul Baker
//
//  start autoeyecam from anywhere
void() auto_pov_start =
{
	self.oflags = self.oflags | OBSERVER_QUAKETV;//R00k added OBSERVER_QUAKETV
	self.oflags = self.oflags | OBSERVER_GO_AUTO;
	observer_demo_start ();
};

// CRMOD
// A U T O  C H A S E
//
//   checks if it's time to switch to a new target.
//   scheduled from elohim_start_frame
//
void() auto_chase_think =
{
	local entity inflictor;
	local float event, ktx;

	event = clanring_autotrack_event;
	ktx = (clanring_autotrack_mode == CLANRING_AUTOTRACK_KTX);

	// KTX generates the powerup prediction from the powerup's own think, so it is
	// completely independent of what the pov is doing.  Ours has to be polled, and
	// it has to happen before the death hold below returns: a 2 second hold sitting
	// over the 2 second predict window would otherwise swallow the prediction
	// entirely.  Arming an event during the hold is fine - it fires when the hold
	// expires, and auto_check_powerup_spawn is one shot per respawn.
	auto_check_powerup_spawn();

	// Hold on a dying pov long enough to see the kill.  This is not negotiable,
	// events included - it is the whole point of the delay.  A pending event is
	// deliberately left armed so it fires the instant the hold expires, the way
	// KTX keeps retrying its switch rather than dropping it.
	if (clanring_current_chase_target && (time < clanring_current_chase_target.clanring_cam_delay))
		return;

	// An event (powerup taken, pov died, first RL, powerup about to spawn) rescores
	// everyone now rather than waiting for the next once-a-second pass.
	if (event)
	{
		clanring_autotrack_event = FALSE;
		auto_recompute_best();

		if (auto_trackable(clanring_autotrack_hint))
			clanring_best_chase_target = clanring_autotrack_hint;

		clanring_autotrack_hint = world;
	}
	else
	{
		// KTX picks the leader from a clean sweep every time it is asked.  The
		// incremental pass in auto_compute_score only ever unseats the incumbent,
		// which lags by a second when the leader's own score drops (quad running
		// out, dropping the RL).
		if (ktx)
			auto_recompute_best();
	}

	// Keep the per team picks in step with the global one, in both formulas.
	auto_recompute_team_bests();

	if (clanring_current_chase_target == clanring_best_chase_target)
		return;
	if (!clanring_best_chase_target)
		return;
	if (!clanring_current_chase_target)
	{
		clanring_current_chase_target = clanring_best_chase_target;
		clanring_chase_delay = (ktx) ? time : (time + 4);
		return;
	}

	if (!event)
	{
		if (ktx)
		{
			// ktpro's autotrack is purely event driven - between its four events it
			// stays put no matter how the scores move, which is what stops the pov
			// wandering off mid fight.  Only a target that is gone forces our hand.
			if (auto_trackable(clanring_current_chase_target))
				return;
		}
		else
		{
			// JP - added mandantory delays
			if (time < clanring_chase_delay)
				return;
			if (time - clanring_current_chase_target.attack_finished < 2)
				return;
			inflictor = clanring_current_chase_target.dmg_inflictor;
			if (inflictor)
			{
				if (inflictor.clanring_inflicted == clanring_current_chase_target && time - inflictor.clanring_did_damage < 2)
					return;
			}

			if (clanring_best_chase_target.clanring_chase_score - clanring_current_chase_target.clanring_chase_score < 100)
				return;
		}
	}

	clanring_current_chase_target = clanring_best_chase_target;

	// KTX applies its switch and moves on; there is no post-switch cooldown, the
	// event rate is what keeps it calm.
	clanring_chase_delay = (ktx) ? time : (time + 4);
};

void() auto_chase =
{
	remove(self);// utils_make_scheduled_event's entity

	auto_chase_think();
};

// CRMOD
// A U T O  C A M E R A
//
// Runs autocam for observers
//
// Rewritten by J.P. Grossman
//
void() auto_camera =
{
	local entity inflictor;

	remove(self);

	if (!clanring_best_camera)
		return;

	if ((clanring_current_camera == clanring_best_camera))
		return;

	if (!clanring_current_camera)
	{
		clanring_current_camera = clanring_best_camera;
		clanring_camera_delay = time + 4;
		return;
	}

	if (clanring_current_camera.classname == "player") // chasecam mode
	{
		// mandantory delay
		if (time < clanring_camera_delay)
			return;

		if (clanring_best_camera.classname != "clanring_camera" || clanring_best_camera.movetarget != clanring_current_camera)
		{
			if (time - clanring_current_camera.attack_finished < 2)
				return;

			inflictor = clanring_current_camera.dmg_inflictor;
			if (inflictor)
			{
				if (inflictor.clanring_inflicted == clanring_current_camera && time - inflictor.clanring_did_damage < 2)
					return;
			}
			if (clanring_best_camera.clanring_chase_score - clanring_current_camera.clanring_chase_score < 100)
				return;
		}
	}
	else
	{
		local entity camera;

		camera = clanring_current_camera;

		// smaller mandantory delay
		if (time < clanring_camera_delay - 2)
			return;

		// switch if best camera has the same movetarget
		if (clanring_best_camera.classname != "clanring_camera" || clanring_best_camera.movetarget != camera.movetarget)
		{
			if (clanring_best_camera.clanring_chase_score - camera.clanring_chase_score < 100)
				return;
			if (time - camera.movetarget.attack_finished < 2)
				return;
		}
	}

	clanring_current_camera = clanring_best_camera;
	clanring_camera_delay = time + 4;
};
