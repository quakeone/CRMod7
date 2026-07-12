void (float value) clanring_set_fraglimit;

/*
Virtual Rocket Arena submaps
----------------------------
configs/ra_submaps.cfg maps a public virtual name to a physical BSP and owns
the spawn coordinates used by that virtual arena:

    map    virtual_name  bsp_name
    spawn  virtual_name  x  y  z  yaw

Multiple spawn records may belong to one map. The virtual name is also the
spawn-group tag, so external entities can still supplement configured spawns:

    "cr_ra_submap" "virtual_name"

The selected virtual name is carried over the physical changelevel in a cvar
because ordinary Quake changelevel only accepts a real BSP name.
*/

void() ra_clear_submap_config =
{
	local float i;

	for (i = 0; i < ra_submap_count; i = i + 1)
	{
		if (ra_submaps[i].name != "")
			strunzone(ra_submaps[i].name);
		if (ra_submaps[i].bsp != "")
			strunzone(ra_submaps[i].bsp);

		ra_submaps[i].name = "";
		ra_submaps[i].bsp = "";
	}

	ra_submap_count = 0;
	ra_submap_spawn_count = 0;
};

float(string virtual_name) ra_find_submap =
{
	local float i;

	if (!virtual_name || virtual_name == "")
		return -1;

	for (i = 0; i < ra_submap_count; i = i + 1)
	{
		if (ra_submaps[i].name == virtual_name)
			return i;
	}

	return -1;
};

void() ra_load_submap_config =
{
	local filestream f;
	local string line;
	local string command;
	local float argc;
	local float duplicate;
	local float submap;

	ra_clear_submap_config();
	f = fopen("configs/ra_submaps.cfg", FILE_READ);
	if (f < 0)
		return;

	print("Loading ClanRing Configuration File: \"configs/ra_submaps.cfg\"\n");
	while ((line = fgets(f)))
	{
		argc = tokenize(line);
		if (!argc)
			continue;
		if (argv(0) == "//" || argv(0) == "#")
			continue;

		command = argv(0);
		if (command == "map")
		{
			if (argc != 3)
			{
				print(sprintf("[RA submaps] Expected: map virtual_name bsp_name: %s\n", line));
				continue;
			}
			if (ra_submap_count >= RA_SUBMAP_LIMIT)
			{
				print(sprintf("[RA submaps] Map limit of %s reached\n", ftos(RA_SUBMAP_LIMIT)));
				continue;
			}

			duplicate = ra_find_submap(argv(1));
			if (duplicate >= 0)
			{
				print(sprintf("[RA submaps] Duplicate virtual map ignored: %s\n", argv(1)));
				continue;
			}

			ra_submaps[ra_submap_count].name = strzone(argv(1));
			ra_submaps[ra_submap_count].bsp = strzone(argv(2));
			ra_submap_count = ra_submap_count + 1;
		}
		else if (command == "spawn")
		{
			if (argc != 6)
			{
				print(sprintf("[RA submaps] Expected: spawn virtual_name x y z yaw: %s\n", line));
				continue;
			}

			submap = ra_find_submap(argv(1));
			if (submap < 0)
			{
				print(sprintf("[RA submaps] Spawn references unknown virtual map: %s\n", argv(1)));
				continue;
			}
			if (ra_submap_spawn_count >= RA_SUBMAP_SPAWN_LIMIT)
			{
				print(sprintf("[RA submaps] Spawn limit of %s reached\n", ftos(RA_SUBMAP_SPAWN_LIMIT)));
				continue;
			}

			ra_submap_spawns[ra_submap_spawn_count].submap_index = submap;
			// Store scalar components independently. Some engines/compiler targets
			// only copy X when assigning a vector member inside a struct array.
			ra_submap_spawns[ra_submap_spawn_count].coord0 = stof(argv(2));
			ra_submap_spawns[ra_submap_spawn_count].coord1 = stof(argv(3));
			ra_submap_spawns[ra_submap_spawn_count].coord2 = stof(argv(4));
			ra_submap_spawns[ra_submap_spawn_count].yaw = stof(argv(5));
			ra_submap_spawn_count = ra_submap_spawn_count + 1;
		}
		else
		{
			print(sprintf("[RA submaps] Unknown directive: %s\n", line));
		}
	}

	fclose(f);
	print(sprintf("[RA submaps] Loaded %s virtual maps with %s configured spawns\n",
		ftos(ra_submap_count), ftos(ra_submap_spawn_count)));
};

void() ra_clear_active_submap =
{
	if (ra_active_submap_name != "")
		strunzone(ra_active_submap_name);
	if (ra_active_submap_bsp != "")
		strunzone(ra_active_submap_bsp);

	ra_active_submap_name = "";
	ra_active_submap_bsp = "";
};

void() ra_clear_submap_cvars =
{
	cvar_set("cr_ra_virtual_map", "");
	cvar_set("cr_ra_virtual_bsp", "");
};

void() ra_create_configured_spawns =
{
	local float submap;
	local float i;
	local float count;
	local entity spot;
	local vector configured_origin;

	if (ra_active_submap_name == "")
		return;

	submap = ra_find_submap(ra_active_submap_name);
	if (submap < 0)
	{
		print(sprintf("[RA submaps] Active virtual map is missing from config: %s\n",
			ra_active_submap_name));
		return;
	}

	for (i = 0; i < ra_submap_spawn_count; i = i + 1)
	{
		if (ra_submap_spawns[i].submap_index != submap)
			continue;

		spot = spawn();
		spot.classname = "info_player_deathmatch";
		spot.cr_ra_submap = ra_active_submap_name;
		spot.angles = '0 1 0' * ra_submap_spawns[i].yaw;
		// Match console_get_origin(), the established working vector-construction
		// pattern in console.qc: assign local components, then pass the vector.
		configured_origin_x = ra_submap_spawns[i].coord0;
		configured_origin_y = ra_submap_spawns[i].coord1;
		configured_origin_z = ra_submap_spawns[i].coord2;
		setorigin(spot, configured_origin);
		dm_num_spawns = dm_num_spawns + 1;
		count = count + 1;
	}

	print(sprintf("[RA submaps] Created %s configured spawns for %s\n",
		ftos(count), ra_active_submap_name));
};

void() ra_submap_init_world =
{
	local string virtual_name;
	local string virtual_bsp;

	registercvar("cr_ra_virtual_map", "");
	registercvar("cr_ra_virtual_bsp", "");
	ra_clear_active_submap();

	virtual_name = cvar_string("cr_ra_virtual_map");
	virtual_bsp = cvar_string("cr_ra_virtual_bsp");

	// A configured virtual alias owns its physical map placement regardless of
	// the mode active on the source map. This prevents its identity and spawns
	// from being discarded during a simultaneous mode/map change.
	if (virtual_name == "" || virtual_bsp != mapname)
	{
		ra_clear_submap_cvars();
		forceinfokey(world, "ra_submap", "");
		forceinfokey(world, "ra_bsp", "");
		return;
	}

	ra_active_submap_name = strzone(virtual_name);
	ra_active_submap_bsp = strzone(virtual_bsp);
	forceinfokey(world, "ra_submap", ra_active_submap_name);
	forceinfokey(world, "ra_bsp", ra_active_submap_bsp);
	print(sprintf("[RA submaps] Active map %s uses %s.bsp\n",
		ra_active_submap_name, ra_active_submap_bsp));
	ra_create_configured_spawns();
};

string() clanring_current_mapname =
{
	if (ra_active_submap_name != "")
		return ra_active_submap_name;

	return mapname;
};

void(string requested_map) clanring_changelevel =
{
	local float submap;
	local string physical_map;

	submap = ra_find_submap(requested_map);
	if (submap >= 0)
		physical_map = ra_submaps[submap].bsp;
	else
		physical_map = requested_map;

	if (submap >= 0)
	{
		// The caller owns the game mode; this layer only maps the public alias
		// to its physical BSP and carries the selected submap across changelevel.
		cvar_set("cr_ra_virtual_map", ra_submaps[submap].name);
		cvar_set("cr_ra_virtual_bsp", ra_submaps[submap].bsp);
	}
	else
	{
		ra_clear_submap_cvars();
	}

	changelevel(physical_map);
};

float(entity spot) ra_spawn_matches_submap =
{
	if (ra_active_submap_name == "")
		return TRUE;

	return (spot.cr_ra_submap == ra_active_submap_name);
};

float(vector org) ra_spawn_hull_clear =
{
	tracebox(org, VEC_HULL_MIN, VEC_HULL_MAX, org, MOVE_NORMAL, self);
	return !(trace_startsolid || trace_allsolid || (trace_fraction < 1));
};

vector(vector org) ra_resolve_spawn_origin =
{
	local vector candidate;
	local float z;
	local float radius;
	local float x;
	local float y;

	if (ra_spawn_hull_clear(org))
		return org;

	// First try lifting vertically; mapper/player origins that are slightly
	// embedded in a floor are the common case.
	for (z = 8; z <= 128; z = z + 8)
	{
		candidate = org + ('0 0 1' * z);
		if (ra_spawn_hull_clear(candidate))
		{
			print(sprintf("[RA submaps] Adjusted blocked spawn %s to %s\n",
				vtos(org), vtos(candidate)));
			return candidate;
		}
	}

	// If a wall or brush volume occupies the original point, search nearby in
	// expanding square rings while staying close to the configured arena.
	for (radius = 16; radius <= 128; radius = radius + 16)
	{
		for (x = 0 - radius; x <= radius; x = x + 16)
		{
			for (y = 0 - radius; y <= radius; y = y + 16)
			{
				if ((fabs(x) != radius) && (fabs(y) != radius))
					continue;

				for (z = 0; z <= 128; z = z + 16)
				{
					candidate = org + [x, y, z];
					if (ra_spawn_hull_clear(candidate))
					{
						print(sprintf("[RA submaps] Adjusted blocked spawn %s to %s\n",
							vtos(org), vtos(candidate)));
						return candidate;
					}
				}
			}
		}
	}

	bprint(sprintf("\bRA submap error:\b no clear player hull near configured spawn %s\n",
		vtos(org)));
	return org;
};

void() ra_validate_submap_spawns =
{
	local entity spot;
	local float count;

	if (ra_active_submap_name == "")
	{
		remove(self);
		return;
	}

	spot = find(world, classname, "info_teleport_destination");
	while (spot != world)
	{
		if (ra_spawn_matches_submap(spot))
			count = count + 1;
		spot = find(spot, classname, "info_teleport_destination");
	}

	spot = find(world, classname, "info_player_deathmatch");
	while (spot != world)
	{
		if (ra_spawn_matches_submap(spot))
			count = count + 1;
		spot = find(spot, classname, "info_player_deathmatch");
	}

	if (!count)
	{
		bprint(sprintf("\bRA submap error:\b %s has no spawns tagged cr_ra_submap=%s\n",
			ra_active_submap_name, ra_active_submap_name));
	}
	else
	{
		print(sprintf("[RA submaps] %s has %s eligible spawns\n",
			ra_active_submap_name, ftos(count)));
		if (count < 2)
			bprint(sprintf("\bRA submap warning:\b %s needs at least two distinct spawns\n",
				ra_active_submap_name));
	}

	remove(self);
};

/* RA worldspawn override key:
"cr_ra_gravity" "150"

Legacy fallback remains for bunmoo3/lowgrav until those maps ship a full
external .ent with the key on worldspawn.
*/
float() ra_worldspawn_gravity =
{
	if (world.cr_ra_gravity > 0)
		return world.cr_ra_gravity;

	if (mapname == "bunmoo3")	return 150;
	if (mapname == "lowgrav")	return 150;

	return 0;
};

void() ra_apply_worldspawn_gravity =
{
	local float gravity;

	if (!(clanring_playmode & CLANRING_RA_MODE))
		return;

	gravity = ra_worldspawn_gravity();
	if (gravity <= 0)
		return;

	cvar_set("sv_gravity", ftos(gravity));
};

void() ra_not_ready =
{
	sprint(self, "Rocket Arena is not ready yet. If this persists, restart the map.\n");
	self.impulse = 0;
};

void () rocket_arena_init_world =
{
	boss 				= spawn ();
	boss.max_rounds 	= 1;
	boss.round 			= 1;
	boss.count 			= 10;
	boss.max_players 	= 1;//R00k: changed v1.52
	boss.start_players	= 1;
 	boss.max_teams  	= 13;
	boss.state 			= CA_MATCH_WAITING;
	boss.wait 			= 0;
	boss.maprecycle		= 0;
		
    boss.items = ((((((((IT_SHOTGUN | IT_AXE) | IT_ROCKET_LAUNCHER) | IT_ARMOR3) | IT_SUPER_SHOTGUN) | IT_NAILGUN) | IT_GRENADE_LAUNCHER) | IT_LIGHTNING) | IT_SUPER_NAILGUN);

	boss.health      	= 100;
	boss.armorvalue  	= 200;
	boss.ammo_shells 	= 30;
	boss.ammo_nails  	= 80;
	boss.ammo_rockets	= 30;
	boss.ammo_cells  	= 30;

	boss.weapon      	= IT_ROCKET_LAUNCHER;
	boss.armortype   	= 80.001;
	boss.timetofight 	= FALSE;
	boss.next_team 		= world;
	boss.next_color		= COLOR_RED;

	boss.busy			= FALSE;
	boss.aborted 		= FALSE;

	ra_initial_rules_shown = FALSE;
	clanring_set_fraglimit(cvar("fraglimit"));
};

string() ra_get_next_map =
{		
	float rnmap = floor((random () * 46));
	switch(rnmap)
	{
		case 0:
			return "23ar-a";
		case 1:
			return "2pyramid";
		case 2:
			return "2towers";
		case 3:
			return "arenarg2";
		case 4:
			return "arenarg4";
		case 5:
			return "arenarg5";
		case 6:
			return "arenarg6";
		case 7:
			return "arenax";
		case 8:
			return "arenazap";
		case 9:
			return "arendm1a";
		case 10:
			return "arenrg3a";
		case 11:
			return "arma4";
		case 12:
			return "barena1";
		case 13:
			return "basarena";
		case 14:
			return "bbarena2";
		case 15:
			return "bunmoo3";
		case 16:
			return "bunski";
		case 17:
			return "chamber1";
		case 18:
			return "crandome";
		case 19:
			return "dm2arena";
		case 20:
			return "dom2_1ra";
		case 21:
			return "egyptra";
		case 22:
			return "football";
		case 23:
			return "gear8";
		case 24:
			return "gnurena";
		case 25:
			return "hill20";
		case 26:
			return "iarena2";
		case 27:
			return "id3";
		case 28:
			return "lowgrav";
		case 29:
			return "marena2";
		case 30:
			return "marena3";
		case 31:
			return "marena4";
		case 32:
			return "mayan1";
		case 33:
			return "nilsrar3";
		case 34:
			return "pen2";
		case 35:
			return "pitarena";
		case 36:
			return "ptucket";
		case 37:
			return "ra_funkf";
		case 38:
			return "rarena3";
		case 39:
			return "rgarden";
		case 40:
			return "soyarena";
		case 41:
			return "terrain2";
		case 42:
			return "uarena1";
		case 43:
			return "unholy";
		case 44:
			return "xarena3";
		default:
			return "yard1";
	}
};

float() ra_map =

{
	if (ra_active_submap_name != "")
		return TRUE;

	if (mapname == "23ar-a")	return TRUE;
	if (mapname == "2pyramid")  return TRUE;
	if (mapname == "2towers")  	return TRUE;
	if (mapname == "arenarg2")  return TRUE;
	if (mapname == "arenarg4")  return TRUE;
	if (mapname == "arenarg5")  return TRUE;
	if (mapname == "arenarg6")  return TRUE;
	if (mapname == "arenax")  	return TRUE;	
	if (mapname == "arenazap")  return TRUE;
	if (mapname == "arendm1a")  return TRUE;
	if (mapname == "arenrg3a")  return TRUE;
	if (mapname == "arma4")  	return TRUE;
	if (mapname == "barena1") 	return TRUE;	
	if (mapname == "basarena")	return TRUE;
	if (mapname == "bbarena2")	return TRUE;
	if (mapname == "bunmoo3")	return TRUE;
	if (mapname == "bunski")	return TRUE;
	if (mapname == "chamber1")	return TRUE;
	if (mapname == "crandome") 	return TRUE;
	if (mapname == "dm2arena")  return TRUE;
	if (mapname == "dom2_1ra")  return TRUE;
	if (mapname == "egyptra")  	return TRUE;
	if (mapname == "football")  return TRUE;
	if (mapname == "gear8")  	return TRUE;	
	if (mapname == "gnurena")  	return TRUE;
	if (mapname == "hill20")  	return TRUE;
	if (mapname == "iarena2")  	return TRUE;
	if (mapname == "id3")  		return TRUE;
	if (mapname == "lowgrav")  	return TRUE;
	if (mapname == "marena2")  	return TRUE;	
	if (mapname == "marena3")  	return TRUE;	
	if (mapname == "marena4")  	return TRUE;	
	if (mapname == "mayan1")  	return TRUE;
	if (mapname == "nilsrar3")  return TRUE;
	if (mapname == "pen2")  	return TRUE;
	if (mapname == "pitarena")  return TRUE;
	if (mapname == "ptucket")  	return TRUE;
	if (mapname == "ra_funkf")  return TRUE;
	if (mapname == "rarena3")  	return TRUE;
	if (mapname == "rgarden")  	return TRUE;	
	if (mapname == "soyarena")  return TRUE;
	if (mapname == "terrain2")  return TRUE;
	if (mapname == "uarena1")  	return TRUE;
	if (mapname == "unholy")  	return TRUE;
	if (mapname == "xarena3")  	return TRUE;
	if (mapname == "yard1")  	return TRUE;

	return FALSE;
};

//
//Sequential spawns, with telefrag scan.
//
entity(entity start, string spawn_classname) ra_find_submap_spawn =
{
	local entity spot;

	spot = find(start, classname, spawn_classname);
	while (spot != world)
	{
		if (ra_spawn_matches_submap(spot))
			return spot;
		spot = find(spot, classname, spawn_classname);
	}

	return world;
};

entity(string spawn_classname) ra_next_submap_spawn =
{
	local entity spot;

	if ((ra_lastspawn != world) && (ra_lastspawn.classname == spawn_classname))
		spot = ra_find_submap_spawn(ra_lastspawn, spawn_classname);

	if (spot == world)
		spot = ra_find_submap_spawn(world, spawn_classname);

	return spot;
};

entity() SelectRASpawnPoint =
{
	local entity spot;
	local vector safe_origin;
	//local entity thing;
	//local float	pcount;
	//local float	n;

	//loop_count = 64;
	
	//pcount = random() * (tele_num_spawns - 0.001);
	//pcount = floor(pcount);
	// Preserve the original RA selection exactly for ordinary, non-virtual maps.
	if (ra_active_submap_name == "")
	{
		spot = find(world, classname, "info_teleport_destination");
		if (spot == world)
		{
			spot = find(world, classname, "info_player_deathmatch");
			if (spot == ra_lastspawn)
				spot = find(spot, classname, "info_player_deathmatch");
			return spot;
		}

		if (spot == ra_lastspawn)
		{
			spot = find(spot, classname, "info_teleport_destination");
			if (spot == world)
			{
				spot = find(world, classname, "info_teleport_destination");
				spot.origin = spot.origin + '64 64 64';
			}
		}

		if (spot != world)
		{
			self.solid = SOLID_NOT;
			makevectors(self.v_angle);
			self.velocity = v_forward * 320;
		}

		ra_lastspawn = spot;
		return spot;
	}

	spot = ra_next_submap_spawn("info_teleport_destination");

	if (spot == world)
	{
		spot = ra_next_submap_spawn("info_player_deathmatch");
	}

	//Check for telefrag
	if (spot != world)
	{
		safe_origin = ra_resolve_spawn_origin(spot.origin);
		if (safe_origin != spot.origin)
		{
			spot.origin = safe_origin;
			setorigin(spot, safe_origin);
		}

		self.solid = SOLID_NOT;//this will unstick players at spawn
		makevectors(self.v_angle);
		self.velocity = v_forward * (320);//R00k:Nudge them forward
	}

	ra_lastspawn = spot;
	return spot;
};

void (entity pteam) ra_join_next_queue =
{
	pteam.next_queue = boss.next_queue;
	boss.next_queue = pteam;
};

void() ra_join_queue =
{
	local entity pteam;
	local string tmp;
	local float whichteam;

	if (boss == world)
	{
		ra_not_ready();
		return;
	}

	if ((boss.state == CA_MATCH_CLEANUP) || (boss.state == CA_MATCH_OVER))
	{
		sprint (self, "Try again in 5 seconds...\n");
		return;
	}

	if (self.next_team != world)
	{
		sprint(self,"\bYou have already commited.\n");
		return;//already on a team
	}

	if (self.lip > time) // Silent guard: avoid noisy message after a Leave->auto re-join bounce
		return;

	self.lip = time + 2; //R00k: two seconds between team choice will stop script spam

	whichteam = floor(random() * 11) + 1;
	if (whichteam == 4)
		{ whichteam = COLOR_YELLOW; }

	pteam = spawn();
	pteam.classname 	= "ra_team";
	pteam.team2			= whichteam;
	pteam.wins			= 0;
	pteam.losses 		= 0;
	pteam.armorvalue 	= 0;
	pteam.health		= 0;
	//pteam.netname 		= self.netname;

	pteam.next_player	= world;//init entity
	pteam.chain_gang 	= world;//init entity

	pteam.next_team   	= boss.next_team;
	boss.next_team    	= pteam;

	// Join message behavior:
	// - First two committed players -> "X has joined the match"
	// - Everyone after -> "X has joined the queue (Nth)"
	{
		local float teams_before, pos, last_two, last;
		local string ordsuffix, ordnum;
		local entity t;

		// Count how many teams existed BEFORE this insert:
		// (we just inserted at head, so the prior list starts at pteam.next_team)
		teams_before = 0;
		t = pteam.next_team;
		while (t != world)
		{
			teams_before = teams_before + 1;
			t = t.next_team;
		}

		if (teams_before < 2)
		{
			// First two players go straight into the match
			announce2 (self.netname, " has joined the match");
		}
		else
		{
			// Exclude the two players currently playing from the ordinal.
			// If 2 are playing and N are already queued, teams_before == 2 + N.
			// New joiner's queue position = (teams_before - 2) + 1.
			pos = (teams_before - 2) + 1;

			// Ordinal suffix (1st, 2nd, 3rd, 4th, with 11th/12th/13th exceptions)
			last_two = pos - (floor(pos / 100) * 100);
			if ((last_two >= 11) && (last_two <= 13))
				ordsuffix = "th";
			else
			{
				last = pos - (floor(pos / 10) * 10);
				if (last == 1)      ordsuffix = "st";
				else if (last == 2) ordsuffix = "nd";
				else if (last == 3) ordsuffix = "rd";
				else                ordsuffix = "th";
			}
			ordnum = ftos(pos);

			// Example: "woods has joined the queue (1st)"
			announce2 (strcat(self.netname, " has joined the queue ("), strcat(ordnum, ordsuffix, ")"));
		}
	}
	//pqc_new_team (pteam.team2);

	self.team2  	= whichteam;
	self.next_team 	= pteam;
	self.frags 		= 0;
	self.respawntime = 0;
	self.rounddeaths = 0;

	add_player_to_stat_list(pteam,self);
	add_player_to_chain(pteam,self);

	ra_join_next_queue(pteam);

	tmp = ftos(self.team2);

	setcolour(self,self.team2,0);

	stuffcmd(self, strcat(";color ", tmp, " 0;\n"));

	ready_name();

	motd_top5 = string_null;
	motd_top6 = string_null;
	stats_reset_player (); //BAM MOVED
};

void (entity pteam) ra_leave_next_queue =
{
	local entity plast;
	plast = boss;

	while (plast.next_queue)
	{
		if (plast.next_queue == pteam)
		{
			plast.next_queue = pteam.next_queue;
			break;
		}
		plast = plast.next_queue;
	}
};

void () ra_leave_queue =
{
	if (self.next_team == world)
	return;

	if (self.next_team == self)
	return;

	// If it's effectively a 1v1 (only two teams total), say "left the match".
	// Otherwise, keep "left the queue".
	// (We check before removing them so the count still includes this player.)
	if (number_teams() <= 2)
		bprint2 (self.netname, "\b has left the match\n");
	else
		bprint2 (self.netname, "\b has left the queue\n");

	// Anti-bounce: throttle immediate re-join attempts (reuses join's lip guard)
	self.lip = time + 1; // 1s is enough to avoid same-tick/menu re-join

	remove_player_from_chain(self.next_team, self);
	remove_player_from_stat_list(self.next_team, self);

	//pqc_erase_team(self.next_team.team2);
	ra_leave_next_queue(self.next_team);
	arena_remove_team(self.next_team);

	//reset player
	self.team2 	= TEAM_SPECTATOR;
	self.team 	= ((self.team2) + 1);//v1.1b fixed
	self.next_team 	= world;
	self.weaponlevel = 0;

	//This is fine dont change this!
	if (self.style & CLANRING_CONNECTED)
	{
		setcolour (self, 0, 0);
	}

	clear_name();

	self.ca_player_flag = PF_WAITING;
	self.movetarget 	= world;
	self.frags 			= -99;
};

void () ra_select_team =
{
	if (boss == world)
	{
		ra_not_ready();
		return;
	}

	if (boss.busy == TRUE)
	{
		sprint(self, "Try again in a few seconds...\n");
		return;
	}

	clear_afk_status(self);
		
	if (self.impulse == 1)
	{
		ra_join_queue ();
	}

	else if (self.impulse == 2)
	{
		if ((self.ca_player_flag == PF_WAITING) && (self.next_team != world))
		{
			ra_leave_queue ();

			if ((self.next_team == world) && (self.style & CLANRING_CONNECTED))
			{
				stuffcmd(self,";color 0;\n");
			}
		}
	}
	
	self.impulse = 0;
};

entity () ra_get_next_player =
{
	local entity e, p;

	if (boss.next_queue == world)
		return world;

	e = boss;
	p = boss.next_queue;

	while (p.next_queue != world)
	{
		e = p;
		p = p.next_queue;
	}

	e.next_queue = world;
	return p;
};

void (float nextcolor) ra_next_player_ready =
{
	local entity pteam, player;
	//local float player_ready = 0;

	pteam = ra_get_next_player ();
	if (pteam != world)
	{
		pteam.team2 = nextcolor;

		player = pteam.chain_gang;
		while (player != world)
		{
			if (player.style & CLANRING_CONNECTED)
			{
				player.ca_player_flag = PF_READY;
				player.team2 = nextcolor;
				//player_ready = 1;
				if (boss.round != 1)
				{
					// Only print next challenger when more than two non-observer players are connected
					local float connected_players;
					local entity cp;
					connected_players = 0;
					cp = find(world, classname, "player");
					while (cp)
					{
						if (cp.style & CLANRING_CONNECTED)
							connected_players = connected_players + 1;
						cp = find(cp, classname, "player");
					}
					if (connected_players > 2)
					{
						// Build: "woods, smith, riley are the next challengers"
						local string msg;
						local float count;
						local entity q, pl;

						msg = "";
						count = 0;

						// 1) The player we just marked READY (the immediate next challenger)
						msg = player.netname;
						count = 1;

						// 2) Peek up to two more teams from the remaining queue
						q = boss.next_queue;
						while (q != world && count < 3)
						{
							pl = q.chain_gang;
							while (pl != world)
							{
								if (pl.style & CLANRING_CONNECTED)
								{
									msg = strcat(msg, ", ", pl.netname);
									count = count + 1;
									break;
								}
								pl = pl.chain_gang;
							}
							q = q.next_queue;
						}

						// Singular vs plural
						if (count == 1)
							bprint2 (msg, " is the next challenger\n");
						else
							bprint2 (msg, " are the next challengers\n");
					}
				}
			}
			player = player.chain_gang;
		}
	}
	//return player_ready;
};

void () ra_spawn_players =
{
	local entity 	pteam, player, tmp;
	local string tmpc = "";

	pteam = boss.next_team;

	while (pteam != world)
	{
		player = pteam.chain_gang;
		while (player != world)
		{
			if (player.ca_player_flag == PF_READY)
			{
				if (player.style & CLANRING_OBSERVER)
				{
					tmp = self;
					self = player;
					observer_end ();
					self = tmp;
				}
				else
				{
					//if player hasn't been through observer_start yet (1v1) just respawn
					tmp = self;
					self = player;
					clear_afk_status(self);
					respawn();
					// Ensure team color is set (fallback to assigned RA colors if missing)
					if (self.team2 == 0)
					{
						if ((self.next_team != world) && (self.next_team.team2 != 0))
							self.team2 = self.next_team.team2;
						else if (self.next_team != world)
						{
							// Fallback: first ready is blue, second is red
							if (self.next_team == boss.next_team)
								self.team2 = COLOR_BLUE;
							else
								self.team2 = COLOR_RED;
						}
					}
					setcolour(self,self.team2,self.team2);
					tmpc = ftos(self.team2);
					stuffcmd(self, strcat(";color ", tmpc, ";\n"));
					self = tmp;
				}
				player.dmg_given_round = 0;
			}
			else if (player.ca_player_flag == PF_PLAYING)
			{
				player.health = boss.health;
				player.armorvalue = boss.armorvalue;
				player.armortype = (boss.armortype * 0.01);
				player.items = boss.items; // woods for ra showing in ra
				player.ammo_shells = boss.ammo_shells;
				player.ammo_nails = boss.ammo_nails;
				player.ammo_rockets = boss.ammo_rockets;
				player.ammo_cells = boss.ammo_cells;

				// --- Sync HUD ammo icon & count with selected weapon ---
				local float ammoMask;
				ammoMask = (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS);
				player.items = player.items - (player.items & ammoMask);
			
				if (player.weapon & (IT_ROCKET_LAUNCHER | IT_GRENADE_LAUNCHER))
				{
					player.items     = player.items | IT_ROCKETS;
					player.currentammo = player.ammo_rockets;
				}
				else if (player.weapon & IT_LIGHTNING)
				{
					player.items     = player.items | IT_CELLS;
					player.currentammo = player.ammo_cells;
				}
				else if (player.weapon & (IT_SUPER_NAILGUN | IT_NAILGUN))
				{
					player.items     = player.items | IT_NAILS;
					player.currentammo = player.ammo_nails;
				}
				else
				{
					// SG/SSG or fallback
					player.items     = player.items | IT_SHELLS;
					player.currentammo = player.ammo_shells;
				}


			}
			player = player.chain_gang;
		}

		pteam = pteam.next_team;
	}
};

void() ra_reset_draw_player =
{
	if (self.ca_player_flag == PF_DEAD)
	{
		self.ca_player_flag = PF_READY;
	}
};

float () ra_players_alive =
{
	local float n = 0;
	local entity e, p;

	e = boss.next_team;
	while (e != world)
	{
		p = e.chain_gang;
		while (p != world)
		{
			if ((p.deadflag == DEAD_NO) && (p.ca_player_flag == PF_PLAYING) && (p.style & CLANRING_CONNECTED))
				n = n + 1;
			p = p.chain_gang;
		}

		e = e.next_team;
	}

	return n;
};

float () ra_number_teams =
{
	local float n = 0.0;
	local entity e,p;

	e = boss.next_team;

	while (e)
	{
		p = e.chain_gang;
		while (p)
		{
			if (p.style & CLANRING_CONNECTED)
			{
				n = n + 1;
				break;
			}
			p = p.chain_gang;
		}
		e = e.next_team;
	}

	return n;
};

string (string msg) ra_countdown_message =
{
	local entity myteam, e, p, oppteam;
	local string line;

	// Spectators or no team: no opponent label
	if (self == world)
		return msg;

	// If observing but not in chase/camera, don't show opponent label
	if ((self.style & CLANRING_OBSERVER))
	{
		// Show plain countdown for fly/walk/other non-chase modes
		if (!(self.oflags & OBSERVER_CHASE) && !(self.oflags & OBSERVER_CAMERA))
			return msg;
	}

	myteam = self.next_team;
	if (myteam == world)
		return msg;

	// Find the other team that is actually active (PF_READY or PF_PLAYING)
	oppteam = world;
	e = boss.next_team;
	while (e != world)
	{
		if (e != myteam)
		{
			p = e.chain_gang;
			while (p != world)
			{
				if ((p.ca_player_flag == PF_READY) || (p.ca_player_flag == PF_PLAYING))
				{
					oppteam = e;
					break;
				}
				p = p.chain_gang;
			}
			if (oppteam != world)
				break;
		}
		e = e.next_team;
	}

	if (oppteam == world || oppteam.chain_gang == world)
		return msg;

	line = strcat(oppteam.chain_gang.netname, "\n\n");
	line = strcat(line, msg);
	return line;
};

void RA_CenterprintToAll (string msg)
{
    local entity pl, save;

    pl = nextent(world);          // first client entity
    while (pl != world)
    {
        if (pl.style & CLANRING_CONNECTED)
        {
            save = self;          // remember caller
            self = pl;            // personalise `self`

            msg_entity = pl;      // make sure engine sends to this client
            WriteByte  (MSG_ONE, SVC_CENTERPRINT);
            WriteString(MSG_ONE, ra_countdown_message(msg));

            self = save;          // restore for next loop
        }
        pl = nextent(pl);
    }
}

void () rocket_arena_main_loop =
{
	if ((clanring_state & CLANRING_MATCH_PAUSED) && (!boss.unpausing))
	{
		if (time > boss.pauseblink)
		{
			WriteByte (MSG_ALL, SVC_CENTERPRINT);
			WriteString (MSG_ALL, "\n\X90PAUSED\X91\n");
			boss.pauseblink = time + 1.5;
		}
		return;
	}

	if ((boss.busy) || (gameover))
		return;

	if (boss.state == CA_MATCH_PLAYING)
	{
		if (ra_number_teams () > 1)
		{
			if (ra_players_alive () < 2)
			{
				if (boss.wait == 0)
				{
					boss.timetofight = FALSE;
					boss.wait = (time + 4);//slight pause before end of round.					
					return;
				}

				if (time > boss.wait)
				{
					boss.wait = time + 99;//do round end and wait
					if (ra_players_alive () == 0)
					{
						boss.round = (boss.round - 1);// repeat round
						boss.draw = TRUE;
						announce ("round is a \bdraw\b!");
						utils_do_arena_players(ra_reset_draw_player);
						utils_make_scheduled_event(reset_round,0.5);//fixed v.0.94b
						return;
					}
					round_end();
				}
			}
		}
		else
		{
			gameover = TRUE;
			boss.aborted = TRUE;
			boss.state = CA_MATCH_OVER;
			arena_match_end ();
		}
	}
	else if ((boss.state == CA_MATCH_ROUNDSTART))
	{
		// removed unused local 'temp'
		
		motd_top5 = string_null;
		motd_top6 = string_null;

		if (number_teams () > 1)
		{
			boss.count = (boss.count) - 1;

			if (clanring_request.noise1 == "\bforce match start\b")	//cancel Vote to force
				Request_Poll_Cleanup();
			

			if (boss.count == 0)
            {
                Request_Poll_Cleanup();
				RA_CenterprintToAll("\bFIGHT!");
					clanring_play_compat_sound(world, CHAN_ITEM, "crx/fight.wav", "", 1, ATTN_NONE);
				utils_do_arena_players(arena_fight_and_shoot);
				boss.timetofight = TRUE;
				boss.state = CA_MATCH_PLAYING;
				// Clear leave-me-alone flags for all players
				utils_do_players(match_clear_leavemealone);
				if (boss.round == 1)
					announce("The match has begun!");
            }
            else if (boss.count == 1)
            {
                if ((boss.round > 1) || ra_initial_rules_shown) RA_CenterprintToAll("1");
					clanring_play_compat_sound(world, CHAN_ITEM, "crx/one.wav", "", 1, ATTN_NONE);
            }
            else if (boss.count == 2)
            {
                if ((boss.round > 1) || ra_initial_rules_shown) RA_CenterprintToAll("2");
					clanring_play_compat_sound(world, CHAN_ITEM, "crx/two.wav", "", 1, ATTN_NONE);
            }
            else if (boss.count == 3)
            {
                if ((boss.round > 1) || ra_initial_rules_shown) RA_CenterprintToAll("3");
					clanring_play_compat_sound(world, CHAN_ITEM, "crx/three.wav", "", 1, ATTN_NONE);
            }
			else if (boss.count == 4)
			{
				ra_spawn_players ();
				// Suppress round number print between rounds in Rocket Arena
				local string stmp;
				stmp = (report_winning_team());
				bprint2 (stmp, "\n");
			}
		}
		else
		{
			gameover = TRUE;
			boss.aborted = TRUE;
			boss.state = CA_MATCH_OVER;
			arena_match_end();
		}
	}	
	else if ((boss.state == CA_MATCH_WAITING))
	{
		if (number_teams () > 1)
		{
			if (boss.wait == 0)
			{
				// No need to force match.
				if (clanring_request.noise1 == "\bforce match start\b")
				Request_Poll_Cleanup();
				
				boss.wait = time + 5;
				sound (world, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NONE);
				announce("Match begins in \b10\b seconds.");//boss.wait (5) + countdowntimer (5) = 10 seconds...
			}

			if (time >= boss.wait)
			{
				boss.timetofight	= FALSE;
				boss.count 	= 5;
				boss.wait 	= 0;
				boss.draw = FALSE;
				boss.busy = FALSE;
				sound (world, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NONE);
				utils_do_players(reset_frags);
				Practice_Object_Remove();
				boss.state = CA_MATCH_ROUNDSTART;
				ra_initial_rules_shown = TRUE;
				ra_next_player_ready(COLOR_BLUE);
				ra_next_player_ready(COLOR_RED);
				//pqc_match_reset();
				//find_pqc_teamscore_teams();
				// Removed prepare to fight print between rounds for RA
			}
		}
		else if (number_teams () < 2)
		{
			if (boss.wait)
			{
				announce ("\bResetting \brally\b timer.");
				sound (world, CHAN_VOICE, "doors/drclos4.wav", 1, ATTN_NONE);
			}
			boss.wait = 0;
		}
	}
	else 
	{
		if (boss.state == CA_MATCH_CLEANUP)
		{
			if (boss.wait == 0)
			{
				boss.wait = time + 3;
			}
			if (time > boss.wait)
			{
				boss.wait = 0;
				boss.state = CA_MATCH_WAITING;
			}
		}
	}
};
