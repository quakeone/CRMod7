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
void () observer_set_demo_position;
void(entity observer, entity target) observer_update_target_infokey;

// CRMOD
// A U T O  C O M P U T E  S C O R E
//
//  Renamed and revamped by J.P. Grossman
//
//  Based on specified criteria, rates the player to see if they are the best player to watch.
//  Called once every second
//
void() auto_compute_score =
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

	// now store their score for later
	self.clanring_chase_score = score;

	if (score > clanring_best_chase_target.clanring_chase_score || clanring_best_chase_target == world)
		clanring_best_chase_target = self;

	if (score > clanring_best_camera.clanring_chase_score || clanring_best_camera == world)
		clanring_best_camera = self;
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

// AUTOPOV2
//  A U T O  P O V 2  S T A R T
//
// Start an advanced auto POV system with prioritized selection logic
void() autopov2_start =
{
	self.oflags = self.oflags | OBSERVER_QUAKETV;
	self.oflags = self.oflags | OBSERVER_GO_AUTO2; // New flag for autopov2
	observer_demo_start();
};

// AUTOPOV2
// AUTPOV2 FIND TARGET
//
// This function determines the best player target using the auto_compute_score system with
// additional prioritization for powerup holders and killers of the current target.
entity() autopov2_find_target =
{
	local entity player, best_player, killer;
	local float best_score, score;
	local entity current_target;
	
	current_target = self.movetarget;
	
	// Make sure current_target is valid
	if (current_target != world && 
	    ((current_target.style & CLANRING_CONNECTED) == 0 || 
	     current_target.classname != "player"))
	{
		current_target = world;
	}
	
	// Powerup priority scan - these override normal scoring
	player = find(world, classname, "player");
	while (player)
	{
		if (player.deadflag == DEAD_NO && 
		    (player.style & CLANRING_CONNECTED) && 
		    !(player.style & CLANRING_OBSERVER))
		{
			// Check for powerups in priority order: pent, quad, ring/eyes
			if (player.items & IT_INVULNERABILITY)
			{
				// Only print message if it's a new target
				if (player != current_target)
					bprint(player.netname, " has pent - switching to them\n");
				return player; // Pentagram has highest priority
			}
			
			if (player.items & IT_QUAD)
			{
				// Only print message if it's a new target
				if (player != current_target)
					bprint(player.netname, " has quad - switching to them\n");
				return player; // Quad has second highest priority
			}
			
			if (player.items & IT_INVISIBILITY)
			{
				// Only print message if it's a new target
				if (player != current_target)
					bprint(player.netname, " has ring - switching to them\n");
				return player; // Ring/eyes has third priority
			}
		}
		player = find(player, classname, "player");
	}
	
	// If current target died, check for killer
	if (current_target != world && current_target.deadflag != DEAD_NO)
	{
		killer = current_target.dmg_inflictor;
		if (killer != world && 
		    killer.classname == "player" && 
		    killer.deadflag == DEAD_NO && 
		    (killer.style & CLANRING_CONNECTED) && 
		    !(killer.style & CLANRING_OBSERVER))
		{
			bprint(killer.netname, " killed current target - switching to them\n");
			return killer; // Player who killed current target gets priority
		}
	}
	
	// Use the existing auto_compute_score system for normal scoring
	best_player = world;
	best_score = -999999;
	
	player = find(world, classname, "player");
	while (player)
	{
		if (player.deadflag == DEAD_NO && 
		    (player.style & CLANRING_CONNECTED) && 
		    !(player.style & CLANRING_OBSERVER))
		{
			// Use their clanring_chase_score which is set by auto_compute_score
			score = player.clanring_chase_score;
			
			// Prioritize players with RL and LG
			if (player.items & IT_ROCKET_LAUNCHER)
				score += 200;
			if (player.items & IT_LIGHTNING)
				score += 150;
				
			// Prioritize armor types
			if (player.items & IT_ARMOR3)
				score += 100;
			else if (player.items & IT_ARMOR2)
				score += 50;
			else if (player.items & IT_ARMOR1)
				score += 25;
				
			if (score > best_score)
			{
				best_score = score;
				best_player = player;
			}
		}
		player = find(player, classname, "player");
	}
	
	return best_player;
};

// AUTOPOV2
// A U T O P O V 2
//
// Main function for autopov2 logic, called from elohim_start_frame
void() autopov2 =
{
	local entity target;
	local entity old_self;
	local entity current_player;
	
	// We need to remove the scheduled event entity
	remove(self);
	
	// Iterate through all players and find those with OBSERVER_AUTO2 flag
	current_player = find(world, classname, "player");
	while (current_player)
	{
		if ((current_player.style & CLANRING_OBSERVER) && (current_player.oflags & OBSERVER_AUTO2))
		{
			// Found an observer with autopov2 enabled
			old_self = self;
			self = current_player;
			
			// Find the best target for this observer
			target = autopov2_find_target();
			
			// More safety checks
			if (target != world && self.movetarget != target)
			{
				// Switch to the new target
				self.movetarget = target;
				
				// This is the critical part - ensure we properly set the viewport
				msg_entity = self;
				WriteByte(MSG_ONE, SVC_SETVIEWPORT);
				WriteEntity(MSG_ONE, target);
				
				// Also call observer_set_demo_position for proper positioning
				observer_set_demo_position();
				
				// Update the observing target infokey
				observer_update_target_infokey(self, target);
				
				// Display autopov2 message
				centerprint(self, sprintf("autopov2 \[%s\]", self.movetarget.netname));
			}
		}
		
		current_player = find(current_player, classname, "player");
	}
};

// AUTOPOV2 
// Event-based score update functions to optimize performance
// To be called when players pick up items, take damage, or kill someone
//
// INTEGRATION POINTS:
// - Add a call to autopov2_update_player_score when a player picks up a powerup in powerup_touch
// - Add a call to autopov2_update_player_score when a player gets a weapon in weapon_touch 
// - Add a call to autopov2_handle_kill in T_Damage when a player's health drops below 0
// - Add a call to autopov2_update_player_score when a player's state changes (respawn, etc)

// Call this when a player gets a powerup or important weapon/item
void(entity player) autopov2_update_player_score =
{
	// Update their score using the existing system
	local entity old_self = self;
	self = player;
	auto_compute_score();
	self = old_self;
};

// Call this when a player kills the current target
void(entity killer, entity victim) autopov2_handle_kill =
{
	// Boost the killer's score temporarily
	if (killer != world && killer.classname == "player")
	{
		// Give them a temporary score boost
		killer.clanring_chase_score += 400;
		
		// Create an event to reset the score boost after 5 seconds
		entity reset_event = spawn();
		reset_event.owner = killer;
		reset_event.think = autopov2_reset_kill_boost;
		reset_event.nextthink = time + 5;
	}
};

// Reset the kill score boost after a delay
void() autopov2_reset_kill_boost =
{
	if (self.owner != world)
	{
		self.owner.clanring_chase_score -= 400;
		
		// Recalculate their score to ensure it's correct
		entity old_self = self;
		self = self.owner;
		auto_compute_score();
		self = old_self;
	}
	
	remove(self);
};

// CRMOD
// A U T O  C H A S E
//
//   checks if it's time to switch to a new target.
//   scheduled from elohim_start_frame
//
void() auto_chase =
{
	//local float temp1, temp2;
	local entity inflictor;

	remove(self);// utils_make_scheduled_event's entity
	
	if (clanring_current_chase_target == clanring_best_chase_target)
		return;
	if (!clanring_best_chase_target)
		return;
	if (!clanring_current_chase_target)
	{
		clanring_current_chase_target = clanring_best_chase_target;
		clanring_chase_delay = time + 4;
		return;
	}
	// JP - added mandantory delays
	if (time < clanring_current_chase_target.clanring_cam_delay || time < clanring_chase_delay)
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

	clanring_current_chase_target = clanring_best_chase_target;
	clanring_chase_delay = (time + 4);
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
